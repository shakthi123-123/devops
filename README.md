
# Docker Image Commands — Pull, Create, Push & Maintain

## Table of Contents
1. [Pulling Images](#1-pulling-images)
2. [Creating / Building Images](#2-creating--building-images)
3. [Pushing Images](#3-pushing-images)
4. [Maintaining & Managing Images](#4-maintaining--managing-images)
5. [Tagging Images](#5-tagging-images)
6. [Inspecting Images](#6-inspecting-images)
7. [Cleaning Up Images](#7-cleaning-up-images)
8. [Full Example Workflow](#8-full-example-workflow)

---

## 1. Pulling Images

| Command | Description | Example |
|---|---|---|
| `docker pull <image>` | Pull the latest image from a registry | `docker pull nginx` |
| `docker pull <image>:<tag>` | Pull a specific tagged version | `docker pull nginx:1.27` |
| `docker pull <registry>/<image>` | Pull from a specific/private registry | `docker pull myregistry.com/myapp:latest` |
| `docker pull --all-tags <image>` | Pull all tags of an image | `docker pull --all-tags nginx` |
| `docker pull --platform <os/arch> <image>` | Pull image for a specific platform | `docker pull --platform linux/arm64 nginx` |

---

## 2. Creating / Building Images

| Command | Description | Example |
|---|---|---|
| `docker build -t <name>:<tag> .` | Build an image from a Dockerfile in current dir | `docker build -t myapp:1.0 .` |
| `docker build -f <path> -t <name> .` | Build using a Dockerfile at a custom path | `docker build -f docker/Dockerfile.prod -t myapp .` |
| `docker build --no-cache -t <name> .` | Build without using cached layers | `docker build --no-cache -t myapp .` |
| `docker build --build-arg <KEY>=<VALUE> -t <name> .` | Pass build-time variables | `docker build --build-arg ENV=prod -t myapp .` |
| `docker commit <container> <image>:<tag>` | Create an image from a running/stopped container | `docker commit mycontainer myapp:snapshot` |
| `docker import <archive>` | Create an image from a tarball | `docker import backup.tar myapp:imported` |
| `docker buildx build --platform <list> -t <name> .` | Build multi-architecture images | `docker buildx build --platform linux/amd64,linux/arm64 -t myapp .` |

---

## 3. Pushing Images

| Command | Description | Example |
|---|---|---|
| `docker login` | Authenticate to a registry (Docker Hub by default) | `docker login` |
| `docker login <registry>` | Authenticate to a specific/private registry | `docker login myregistry.com` |
| `docker tag <local_image> <registry>/<repo>:<tag>` | Tag image for the target registry before pushing | `docker tag myapp myregistry.com/myapp:1.0` |
| `docker push <registry>/<repo>:<tag>` | Push a tagged image to a registry | `docker push myregistry.com/myapp:1.0` |
| `docker push --all-tags <repo>` | Push all local tags of a repo | `docker push --all-tags myregistry.com/myapp` |
| `docker logout` | Log out of a registry | `docker logout` |

---

## 4. Maintaining & Managing Images

| Command | Description | Example |
|---|---|---|
| `docker images` | List all local images | `docker images` |
| `docker images -a` | List all images, including intermediate layers | `docker images -a` |
| `docker images --filter "dangling=true"` | List untagged/dangling images | `docker images --filter "dangling=true"` |
| `docker history <image>` | Show the layer history of an image | `docker history myapp:1.0` |
| `docker save -o <file>.tar <image>` | Export an image to a tar archive | `docker save -o myapp.tar myapp:1.0` |
| `docker load -i <file>.tar` | Import an image from a tar archive | `docker load -i myapp.tar` |
| `docker rmi <image>` | Remove a local image | `docker rmi myapp:1.0` |
| `docker rmi -f <image>` | Force remove an image (even if in use) | `docker rmi -f myapp:1.0` |

---

## 5. Tagging Images

| Command | Description | Example |
|---|---|---|
| `docker tag <source> <target>` | Create a new tag pointing to an existing image | `docker tag myapp:1.0 myapp:latest` |
| `docker tag <image> <registry>/<repo>:<tag>` | Tag for a specific registry/namespace | `docker tag myapp registry.io/team/myapp:2.0` |

---

## 6. Inspecting Images

| Command | Description | Example |
|---|---|---|
| `docker inspect <image>` | Show detailed low-level info (JSON) | `docker inspect myapp:1.0` |
| `docker image ls --digests` | Show images with their content digests (SHA256) | `docker image ls --digests` |
| `docker manifest inspect <image>` | Inspect a multi-arch manifest on a registry | `docker manifest inspect nginx` |
| `docker scan <image>` | Scan image for known vulnerabilities (Docker Scout/Snyk-based) | `docker scan myapp:1.0` |
| `docker diff <container>` | Show filesystem changes vs. the image it's based on | `docker diff mycontainer` |

---

## 7. Cleaning Up Images

| Command | Description | Example |
|---|---|---|
| `docker image prune` | Remove dangling (untagged) images | `docker image prune` |
| `docker image prune -a` | Remove all unused images (not referenced by any container) | `docker image prune -a` |
| `docker image prune -a --filter "until=24h"` | Remove unused images older than a duration | `docker image prune -a --filter "until=24h"` |
| `docker system prune` | Remove unused containers, networks, images (dangling), build cache | `docker system prune` |
| `docker system prune -a --volumes` | Aggressive cleanup: all unused images + volumes too | `docker system prune -a --volumes` |
| `docker builder prune` | Clear the build cache | `docker builder prune` |

---

## 8. Full Example Workflow

```bash
# 1. Pull a base image
docker pull ubuntu:22.04

# 2. Build your own image from a Dockerfile
docker build -t myapp:1.0 .

# 3. Tag it for your registry
docker tag myapp:1.0 myregistry.com/myteam/myapp:1.0

# 4. Log in to the registry
docker login myregistry.com

# 5. Push the image
docker push myregistry.com/myteam/myapp:1.0

# 6. Verify it locally
docker images | grep myapp
docker inspect myregistry.com/myteam/myapp:1.0

# 7. Maintain — clean up old/dangling images periodically
docker image prune -a --filter "until=168h"   # remove images unused for 7+ days
```
