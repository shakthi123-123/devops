# Docker Architecture — Detailed Overview

## 1. High-Level Architecture

Docker uses a **client-server architecture**. The Docker client talks to the Docker daemon, which does the heavy lifting of building, running, and distributing containers. The client and daemon can run on the same host, or the client can connect to a remote daemon over a network.

```
┌─────────────────────────────────────────────────────────────────────┐
│                          DOCKER HOST                                 │
│                                                                       │
│   ┌───────────────┐        REST API        ┌───────────────────┐    │
│   │ Docker Client │ ─────────────────────▶ │   Docker Daemon    │    │
│   │  (docker CLI) │  (over UNIX socket /   │     (dockerd)      │    │
│   └───────────────┘   TCP socket)          └─────────┬──────────┘    │
│                                                       │               │
│                     ┌─────────────────────────────────┼────────────┐│
│                     │                                 │            ││
│              ┌──────▼──────┐   ┌───────────────┐ ┌────▼────────┐  ││
│              │   Images    │   │  Containers    │ │  Networks   │  ││
│              └─────────────┘   └───────────────┘ └─────────────┘  ││
│                     │                                 │            ││
│              ┌──────▼──────┐                    ┌─────▼───────┐   ││
│              │   Volumes   │                    │ containerd   │   ││
│              └─────────────┘                    └──────┬───────┘   ││
│                                                          │           │
│                                                    ┌─────▼───────┐   │
│                                                    │  runc/OCI   │   │
│                                                    │  runtime    │   │
│                                                    └──────┬───────┘   │
│                                                           │           │
│                                                    ┌──────▼───────┐  │
│                                                    │  Linux Kernel │  │
│                                                    │ (namespaces,  │  │
│                                                    │  cgroups)     │  │
│                                                    └───────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                     │
                     ▼
          ┌─────────────────────┐
          │   Docker Registry    │
          │ (Docker Hub, ECR,    │
          │  GCR, private, etc.) │
          └─────────────────────┘
```

---

## 2. Core Components

### 2.1 Docker Client (`docker`)
- The primary way users interact with Docker.
- Sends commands (`docker build`, `docker run`, `docker pull`, etc.) to the daemon via the **Docker REST API**.
- Can communicate with a local daemon (via UNIX socket `/var/run/docker.sock`) or a remote daemon (via TCP + TLS).
- One client can talk to multiple daemons.

### 2.2 Docker Daemon (`dockerd`)
- Background service that manages Docker objects: images, containers, networks, volumes.
- Listens for API requests from the client.
- Delegates actual container lifecycle management to **containerd**.
- Handles image builds, networking setup, and volume management.

### 2.3 containerd
- A high-level container runtime, spun out of Docker as its own CNCF project.
- Manages the complete container lifecycle: image transfer/storage, container execution/supervision, and low-level storage/network attachments.
- Exposes a gRPC API used by `dockerd` (and other clients like Kubernetes' CRI).
- Delegates actual process execution to `runc` via `containerd-shim`.

### 2.4 containerd-shim
- A small process that sits between `containerd` and the actual container process.
- Allows containers to keep running even if `containerd` or `dockerd` restarts/crashes.
- Reports exit status back to `containerd`.

### 2.5 runc (OCI Runtime)
- A low-level CLI tool for spawning and running containers according to the **OCI (Open Container Initiative) runtime spec**.
- Directly interfaces with the Linux kernel to create the container process using namespaces and cgroups.
- Other OCI-compliant runtimes can be swapped in (e.g., `gVisor`/`runsc` for sandboxing, `kata-containers` for VM-based isolation).

### 2.6 Linux Kernel Primitives
Docker containers are not VMs — they are isolated processes on the host kernel, built on:
- **Namespaces** — isolate what a process can *see*:
  - `pid` — process IDs
  - `net` — network interfaces, routing tables
  - `mnt` — filesystem mount points
  - `uts` — hostname/domain name
  - `ipc` — inter-process communication
  - `user` — UID/GID mapping
- **cgroups (control groups)** — limit what a process can *use*:
  - CPU, memory, disk I/O, network bandwidth
- **Union filesystems** (overlay2, aufs, btrfs, zfs) — enable Docker's **layered image** model.

---

## 3. Docker Objects

### 3.1 Images
- Read-only templates used to create containers.
- Built from a `Dockerfile`, composed of stacked, cached **layers**.
- Each instruction in a Dockerfile (`RUN`, `COPY`, `ADD`, etc.) typically creates a new layer.
- Layers are content-addressable (SHA256) and shared across images to save space.

```
Image Layers (bottom → top):
┌────────────────────────────┐
│ App layer (COPY . /app)    │  ← topmost, unique per app
├────────────────────────────┤
│ Dependencies (pip install) │
├────────────────────────────┤
│ Runtime (python:3.12-slim) │
├────────────────────────────┤
│ Base OS (debian-slim)      │  ← bottom, most shared/cached
└────────────────────────────┘
```

### 3.2 Containers
- A runnable instance of an image.
- Adds a thin **writable layer** on top of the image's read-only layers (copy-on-write).
- Isolated via namespaces, resource-limited via cgroups.
- Can be started, stopped, moved, deleted via API/CLI.

### 3.3 Volumes
- Persistent data storage that lives outside a container's writable layer.
- Managed by Docker (`docker volume create`), stored under `/var/lib/docker/volumes/` on Linux hosts.
- Survive container deletion; can be shared between containers.
- Alternatives: **bind mounts** (map a host path directly) and **tmpfs mounts** (in-memory, non-persistent).

### 3.4 Networks
- Docker provides several network drivers:
  | Driver | Use Case |
  |---|---|
  | `bridge` | Default; isolated network on a single host |
  | `host` | Container shares host's network namespace directly |
  | `overlay` | Multi-host networking (Docker Swarm) |
  | `macvlan` | Assigns a MAC address, appears as physical device on network |
  | `none` | Disables networking |
- Docker manages a virtual bridge (`docker0`) and uses `iptables`/`nftables` for NAT and port mapping.

### 3.5 Registries
- Store and distribute images.
- **Docker Hub** is the default public registry; others include AWS ECR, GCP Artifact Registry, Azure ACR, Harbor (self-hosted), GitLab Registry.
- `docker push`/`docker pull` transfer image layers to/from a registry, only fetching layers not already cached locally.

---

## 4. Request Lifecycle: `docker run nginx`

1. **Client** sends a `run` request to the **daemon** via the REST API.
2. **Daemon** checks if the `nginx` image exists locally.
3. If not, daemon pulls the image from the configured **registry** (layer by layer, checking local cache).
4. Daemon asks **containerd** to create a container from the image.
5. **containerd** unpacks the image (via `containerd-snapshotter`, using overlay2) and hands off to **containerd-shim**.
6. **shim** invokes **runc**, which:
   - Creates namespaces (pid, net, mnt, etc.)
   - Sets up cgroups for resource limits
   - Sets up the root filesystem from image layers + a new writable layer
   - Executes the container's entrypoint process
7. `runc` exits after starting the process; **shim** stays alive to reparent and monitor the container process (this is why containers survive a `dockerd` restart).
8. Daemon configures networking (attaches to `docker0` bridge, sets up port mapping/NAT rules).
9. Container is now running; logs/stdout are streamed back through containerd → dockerd → client.

---

## 5. Multi-Host Orchestration (Optional Layer)

Docker's single-host architecture extends to multi-host clustering via:

- **Docker Swarm** (built-in orchestrator)
  - Manager nodes maintain cluster state (Raft consensus).
  - Worker nodes run tasks (containers) scheduled by managers.
  - Uses `overlay` networks for cross-host container communication.
- **Kubernetes** (external orchestrator, most common in production)
  - Doesn't use `dockerd` directly — talks to `containerd` (or `CRI-O`) via the **Container Runtime Interface (CRI)**.
  - This is why "Docker" and "Kubernetes" are often conflated, but Kubernetes only needs an OCI-compatible runtime, not Docker itself.

```
                     ┌────────────────────┐
                     │   Kubernetes API    │
                     │      Server         │
                     └──────────┬─────────┘
                                │ CRI (gRPC)
              ┌─────────────────┼─────────────────┐
              ▼                 ▼                 ▼
        ┌───────────┐    ┌───────────┐    ┌───────────┐
        │  kubelet  │    │  kubelet  │    │  kubelet  │
        │  + CRI    │    │  + CRI    │    │  + CRI    │
        │  shim     │    │  shim     │    │  shim     │
        └─────┬─────┘    └─────┬─────┘    └─────┬─────┘
              ▼                 ▼                 ▼
        containerd         containerd         containerd
```

---

## 6. Storage Drivers

Docker supports pluggable storage drivers that implement the union filesystem:

| Driver | Notes |
|---|---|
| `overlay2` | Default on modern Linux; fast, well-supported |
| `btrfs` | Snapshot-friendly, needs btrfs filesystem |
| `zfs` | Similar to btrfs, needs ZFS |
| `devicemapper` | Legacy, block-level (deprecated in most setups) |
| `vfs` | No copy-on-write; simplest but slowest, used in testing |

---

## 7. Security Boundaries

- **Namespaces + cgroups** provide process/resource isolation but share the host kernel (unlike VMs with separate kernels).
- **Capabilities** — Docker drops many Linux capabilities by default (`CAP_SYS_ADMIN`, etc.) to reduce attack surface.
- **Seccomp profiles** — filter which syscalls a container can make.
- **AppArmor / SELinux** — mandatory access control on top of standard permissions.
- **Rootless mode** — allows running the Docker daemon and containers without root privileges.
- **User namespaces** — remap container UID 0 (root) to an unprivileged UID on the host.

---

## 8. Summary Diagram: Full Stack

```
 docker CLI
     │  REST API (HTTP over unix socket / TCP+TLS)
     ▼
 dockerd  ──────────────► image build, network, volume mgmt
     │  gRPC
     ▼
 containerd ─────────────► image pull/unpack, lifecycle mgmt
     │
     ▼
 containerd-shim ────────► keeps container alive independent of daemon
     │
     ▼
 runc (OCI runtime) ─────► creates namespaces/cgroups, execs process
     │
     ▼
 Linux Kernel ───────────► namespaces, cgroups, overlayfs, seccomp
```
