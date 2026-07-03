# 🐋 Docker Command Cheat Sheet

### Add Active User to the Docker Group
Enables running Docker engine calls without requiring root `sudo` elevation.
```bash
sudo apt install util-linux-extra
```
```bash
sudo usermod -aG docker $USER
```
```bash
newgrp docker
```

---

## 1. 📊 System Diagnostics & Resource Tuning

#### View Daemon Engine Version Information
```bash
docker -v
```
#### Check Host Service Process Daemon Status
```bash
sudo systemctl status docker
```
#### Show Comprehensive System-Wide Configuration
```bash
docker info
```
#### Display Real-Time Container Resource Statistics
```bash
docker stats
```
#### Display Storage Utilization Disk Footprint Summary
```bash
docker system df
```
#### Inspect the Real-Time Docker Daemon Event Stream
```bash
docker system events
```
#### Wipe Unused Data (Stopped Containers, Dangling Images, Cache)
```bash
docker system prune -a --volumes
```
#### Display Host Memory Usage Profile
```bash
free -m
```
#### Show Active Network Interconnect Interfaces and IPs
```bash
ip a
```

---

## 2. 📦 Container Lifecycle & Processing Controls

#### List All Active Containers Currently Running
```bash
docker ps
```
#### List All Containers Regardless of Current Runtime State
```bash
docker ps -a
```
#### Spin up an Isolated Background Container (Defined Port Mapping)
```bash
docker run -d -it --name "container_name" -p 80:80 "image_name"
```
#### Spin up a Container and Map Ports to Random Ephemeral Host Ports
```bash
docker run -d -it --name "container_name" -P "image_name"
```
#### Spin up an OS Core Environment Overriding the Entrypoint Bash Shell
```bash
docker run -d -it --name "container_name" -p 81:80 "image_name" /bin/bash
```
#### Spin up a Container Mounting a Named Managed Docker Volume
```bash
docker run -d -it --name "container_name" -p 80:80 --mount source="volume_name",destination=/data "image_name"
```
#### Spin up a Container using a Direct Bind Mount (Host Directory to Target Location)
```bash
docker run -d -it --name "container_name" -p 80:80 -v /host/data:/container/destination "image_name"
```
#### Open an Interactive Terminal Session Inside a Container Instance
```bash
docker exec -it "container_name" /bin/sh
```
#### Stream Runtime Activity Records and Output Logs
```bash
docker logs -f "container_name"
```
#### Display the Running Process Tree Layer of a Target Container
```bash
docker top "container_name"
```
#### Stop a Warm Running Container Instance
```bash
docker stop "container_name"
```
#### Wake a Pre-existing Stopped Container Instance
```bash
docker start "container_name"
```
#### Clean up and Delete a Defunct Stopped Container
```bash
docker rm "container_name"
```
#### Force Terminate and Instantly Evict a Running Container
```bash
docker rm -f "container_name"
```

---

## 3. 🖼️ Image Assembly, Management & Backup

#### Query Public Registries for Available Images
```bash
docker search "image_name"
```
#### Download a Remote Image Locally Into the Engine Engine Cache
```bash
docker pull "image_name"
```
#### List Locally Available Cached Engine Images
```bash
docker images
```
#### Extract Deep Low-Level Manifest Specifications for an Image Asset
```bash
docker inspect "image:tag"
```
#### Read the Layer Construction Metadata Record History of an Image
```bash
docker history "image:tag"
```
#### Purge and Delete a Local Cached Engine Image Reference
```bash
docker rmi "image_name"
```
#### Commit Runtime Changes on a Container into a New Local Image Asset
```bash
docker commit "container_id" "new_image_name:tag"
```
#### Export an Image layer to a Static Backup Compressed Archive File
```bash
docker save "image_id" > image_backup.tar
```
#### Secure Transfer Backup Archive to a Remote Server Host Node
```bash
scp image_backup.tar user@target_ip:/home/pc/
```
#### Unpack and Load a Backup Archive Asset into the Local Images Pool
```bash
docker load -i image_backup.tar
```

---

## 4. 🛠️ Image Compilation (Dockerfile Engine)

#### Create a Working Environment Directory Structure
```bash
mkdir new_project && cd new_project
touch Dockerfile
```
#### Compile and Tag a Local Image Asset from a Dockerfile Context
```bash
docker build -t "new_image_name" .
```
#### Core Dockerfile Instructions Reference

| Instruction | Operational Functional Objective |
| :--- | :--- |
| `FROM` | Declares the initial base execution layer stage image. |
| `ADD` | Transports local files or pulls remote internet download assets. |
| `COPY` | Transfers local directory files inside the workspace context. |
| `RUN` | Executes software setup installations inside the temporary image builds. |
| `CMD` | Establishes mutable baseline fallback arguments for running containers. |
| `ENTRYPOINT` | locks down immutable hardcoded execution parameters. |
| `ENV` | Binds continuous system configuration environment variables. |
| `ARG` | Handles configuration properties used strictly during image assembly time. |
| `EXPOSE` | Documents intended ingress communication network ports. |
| `USER` | Locks down target UID/GID context parameters to minimize root exploit scope. |
| `WORKDIR` | Standardizes default execution file locations. |
| `VOLUME` | Instantiates decoupled storage target markers. |
| `LABEL` | Inject metadata documentation parameters into an image layout block. |
| `HEALTHCHECK` | Configures monitoring loops to audit runtime container integrity states. |
| `SHELL` | Overrides native OS system execution prompt pathways. |

---

## 5. 💾 Storage Volume Management

#### Create an Isolated Persistent Data Volume Partition
```bash
docker volume create "volume_name"
```
#### List All Active Persistent Volumes Provisioned Locally
```bash
docker volume ls
```
#### Find the Storage Path and Inspect Volume Meta Configuration Profiles
```bash
docker volume inspect "volume_name"
```
#### Remove a Targeted Volume Layer
```bash
docker volume rm "volume_name"
```
#### Purge and Clear Out All Unattached Orphaned Storage Volumes
```bash
docker volume prune
```

---

## 6. ⚖️ Container Compute & Resource Scheduling Boundaries

#### Enforce Memory Request Reservations and Hard Runtime Ceilings
```bash
docker run --memory-reservation=256m -m 512m -d --name "container_name" "image_name"
```
#### Dedicate Explicit Proportional CPU Fractional Execution Quotas
```bash
docker run --cpus=1.2 -d --name "container_name" "image_name"
```
#### Regulate Relative Priority CPU Shares Weights for Execution Balancing
```bash
docker run --cpu-shares=1000 --cpus=1.2 -d --name "container_name" "image_name"
```

---

## 7. 🐙 Multi-Container App Coordination (Docker Compose)

#### Install the Docker Compose Plugin Utilities Dependency Engine
```bash
sudo apt-get install docker-compose-plugin
```
#### Spin up Multi-Container Infrastructure in Isolated Detached Mode
```bash
docker compose -f docker-compose.yml up -d
```
#### Stop Running Application Infrastructure Layers and Drop Custom Networks
```bash
docker compose -f docker-compose.yml down
```
#### Stream Application Service Cluster Execution Output Records and Logs
```bash
docker compose -f docker-compose.yml logs "service_name"
```
#### Validate Syntax Schema Compliance without Altering Current Infrastructures
```bash
docker compose -f docker-compose.yml config
```

---

## 8. 🕸️ Swarm Multi-Node Orchestration Platform

#### Initialize a Primary Swarm Manager Node Endpoint Interface
```bash
docker swarm init --advertise-addr "manager_interface_ip"
```
#### List Active Nodes Cooperating Inside the Swarm Setup
```bash
docker node ls
```

