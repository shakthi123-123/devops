# 🐋 Docker Command Cheat Sheet

# Docker: Complete Step-by-Step Commands Guide

## Table of Content

1.  [Initial Setup](#1-initial-setup)
2.  [Working with Images](#2-working-with-images)
3.  [Building Images](#3-building-images)
4.  [Running Containers](#4-running-containers)
5.  [Logs & Debugging](#6-logs--debugging)
6.  [Logs & Debugging](#6-logs--debugging)
7.  [Volumes (Persistent Storage)](#7-volumes-persistent-storage)
8.  [Networks](#8-networks)
9.  [Docker Compose](#9-docker-compose)
10. [Additional Container & Image Commands](#10-additional-container--image-commands)
11. [Docker Context (Managing Multiple Docker Hosts)](#11-docker-context-managing-multiple-docker-hosts)
12. [Registry & Image Distribution](#12-registry--image-distribution)
13. [Docker Swarm (Native Orchestration)](#13-docker-swarm-native-orchestration)
14. [Cleaning Up](#14-cleaning-up)
15. [Typical Everyday Workflow (Putting It Together)](#15-typical-everyday-workflow-putting-it-together)

## Quick Reference Table

| Task | Command |
|---|---|
| Pull image | `docker pull <image>` |
| Build image | `docker build -t <name> .` |
| Run container | `docker run -d -p 8080:80 <image>` |
| List running containers | `docker ps` |
| List all containers | `docker ps -a` |
| Stop container | `docker stop <name>` |
| Remove container | `docker rm <name>` |
| Remove image | `docker rmi <image>` |
| View logs | `docker logs -f <name>` |
| Exec into container | `docker exec -it <name> sh` |
| List images | `docker images` |
| Compose up | `docker compose up -d` |
| Compose down | `docker compose down` |
| Commit container to image | `docker commit <container> <image>` |
| Update running container's resources | `docker update --memory="1g" <name>` |
| Deploy a swarm stack | `docker stack deploy -c compose.yml <stack>` |
| Clean up everything unused | `docker system prune` |


## 1. Initial Setup

```bash
# Check Docker version
docker -v
docker version
# Shows Docker Basic commands
docker 'double tab'

# Check Docker system info (containers, images, storage driver, etc.)
docker info

# Shows Docker Status
sudo systemctl status docker

# Test that Docker is working
docker run hello-world

# Log in to Docker Hub (or another registry)
docker login

# Log in to a specific registry
docker login myregistry.com

# Log out
docker logout

# Remove Unused data
sudo docker system prune

# Show Realtime Container Running
sudo docker stats

#Adding current user to the Docker group... without sudo user
sudo apt install util-linux-extra
sudo usermod -aG docker $USER
newgrp docker
```

## 2. Working with Images

```bash
# List local images
docker images
docker image ls

# Search Docker Hub for an image
docker search nginx

# Pull an image from a registry
docker pull nginx
docker pull nginx:1.25

# Pull from a specific registry
docker pull myregistry.com/myimage:latest

# Inspect an image's details (layers, config, env vars)
docker inspect nginx

# View image history (layer-by-layer build steps)
docker history nginx

# Tag an image
docker tag nginx:latest myrepo/nginx:v1

# Push an image to a registry
docker push myrepo/nginx:v1

# Remove an image
docker rmi nginx

# Remove an image forcefully (even if used by stopped containers)
docker rmi -f nginx

# Remove all unused images
docker image prune

# Remove all unused images, not just dangling ones
docker image prune -a

# Save an image to a tar file
docker save -o nginx.tar nginx:latest

# Load an image from a tar file
docker load -i nginx.tar
```

## 3. Building Images

```bash
# Create a Docker File
vim dockerfile

# Build an image from a Dockerfile in the current directory
docker build -t my-app:latest .

# Build with a specific Dockerfile path
docker build -f Dockerfile.prod -t my-app:prod .

# Build without using cache
docker build --no-cache -t my-app:latest .

# Build and pass build-time arguments
docker build --build-arg NODE_ENV=production -t my-app:latest .

# Build a multi-platform image (requires buildx)
docker buildx build --platform linux/amd64,linux/arm64 -t my-app:latest .

# View build cache usage
docker buildx du

# Tag the Docker imaage
sudo docker tag 'image:tag' 'username/image:tag'

# Push a Image To Docker Hub
sudo docker push 'username/image:tag'
```

## 4. Running Containers

```bash
# Run a container (foreground)
docker run nginx

# Run a container in detached mode (background)
docker run -d nginx

# Run with a custom name
docker run -d --name my-nginx nginx

# Run and map a port (host:container)
docker run -d -p 8080:80 nginx

# Run and map multiple ports
docker run -d -p 8080:80 -p 8443:443 nginx

# Run with environment variables
docker run -d -e "ENV=production" -e "DEBUG=false" nginx

# Run with an env file
docker run -d --env-file .env nginx

# Run and mount a volume
docker run -d -v my-volume:/data nginx

# Run and bind-mount a local directory
docker run -d -v $(pwd)/html:/usr/share/nginx/html nginx
docker run -d -it --name "container_name" -p 80:80 --mount source="volume_name",destination=/data "image_name"

# Run interactively with a terminal (e.g. for shells)
docker run -it ubuntu /bin/bash
docker exec -it "container_name" /bin/bash

# Run and automatically remove the container when it stops
docker run --rm -it ubuntu bash

# Run with a resource limit (CPU/memory)
docker run -d --memory="512m" --cpus="1.0" nginx

# Run with a restart policy
docker run -d --restart unless-stopped nginx

# Run attached to a specific network
docker run -d --network my-network nginx

# Override the container's default command
docker run ubuntu echo "hello world"

# Spin up a Container using a Direct Bind Mount (Host Directory to Target Location)
docker run -d -it --name "container_name" -p 80:80 -v /host/data:/container/destination "image_name"
```

## 5. Managing Containers

```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# List container IDs only
docker ps -q

# Stop a running container
docker stop <container-id-or-name>

# Start a stopped container
docker start <container-id-or-name>

# Restart a container
docker restart <container-id-or-name>

# Pause/unpause a container (freeze processes)
docker pause <container-id-or-name>
docker unpause <container-id-or-name>

# Kill a container immediately (no graceful shutdown)
docker kill <container-id-or-name>

# Remove a stopped container
docker rm <container-id-or-name>

# Force remove a running container
docker rm -f <container-id-or-name>

# Remove all stopped containers
docker container prune

# Rename a container
docker rename old-name new-name

# Inspect a container's full config (network, mounts, env)
docker inspect <container-id-or-name>

# Show container resource usage in real time (like top)
docker stats

# Show running processes inside a container
docker top <container-id-or-name>
```

## 6. Logs & Debugging

```bash
# View logs of a container
docker logs <container-id-or-name>

# Follow logs in real time
docker logs -f <container-id-or-name>

# Show only the last N lines
docker logs --tail 100 <container-id-or-name>

# Show logs since a specific time
docker logs --since 10m <container-id-or-name>

# Execute a command inside a running container
docker exec -it <container-id-or-name> bash
docker exec -it <container-id-or-name> sh

# Run a one-off command without an interactive shell
docker exec <container-id-or-name> ls /app

# Copy files between host and container
docker cp <container-id>:/path/in/container ./local-path
docker cp ./local-path <container-id>:/path/in/container

# View filesystem changes made in a container since it started
docker diff <container-id-or-name>

# Attach to a running container's main process (Ctrl+P, Ctrl+Q to detach)
docker attach <container-id-or-name>
```

## 7. Volumes (Persistent Storage)

```bash
# List volumes
docker volume ls

# Create a named volume
docker volume create my-volume

# Inspect a volume (mount point, driver)
docker volume inspect my-volume

# Remove a volume
docker volume rm my-volume

# Remove all unused volumes
docker volume prune

# Run a container with a named volume attached
docker run -d -v my-volume:/data nginx

# Run with a read-only bind mount
docker run -d -v $(pwd)/config:/app/config:ro nginx
```

## 8. Networks

```bash
# List networks
docker network ls

# Create a custom network
docker network create my-network

# Create a network with a specific driver/subnet
docker network create --driver bridge --subnet 172.20.0.0/16 my-network

# Inspect a network (connected containers, subnet)
docker network inspect my-network

# Connect a running container to a network
docker network connect my-network <container-id-or-name>

# Disconnect a container from a network
docker network disconnect my-network <container-id-or-name>

# Remove a network
docker network rm my-network

# Remove all unused networks
docker network prune
```

## 9. Docker Compose

```bash
# Start all services defined in docker-compose.yml
docker compose up

# Start in detached mode
docker compose up -d

# Rebuild images before starting
docker compose up --build

# Stop and remove containers, networks (keeps volumes)
docker compose down

# Stop and remove containers, networks, AND volumes
docker compose down -v

# List running compose services
docker compose ps

# View logs for all services
docker compose logs -f

# View logs for a specific service
docker compose logs -f web

# Execute a command in a running service
docker compose exec web bash

# Scale a specific service to N replicas
docker compose up -d --scale web=3

# Restart a specific service
docker compose restart web

# Validate and view the resolved compose config
docker compose config

# Pull images for all services
docker compose pull

# Use a specific compose file
docker compose -f docker-compose.prod.yml up -d
```

## 10. Additional Container & Image Commands

```bash
# Create a new image from a container's current state (including manual changes)
docker commit <container-id-or-name> my-app:snapshot

# Export a container's filesystem as a tar archive (no image history/layers)
docker export <container-id-or-name> -o container.tar

# Import a tar archive as a new image (flat, no layer history)
docker import container.tar my-app:imported

# Update resource limits on an already-running container
docker update --memory="1g" --cpus="2" <container-id-or-name>

# Show port mappings for a container
docker port <container-id-or-name>

# Stream real-time events from the Docker daemon (container/image/network changes)
docker events

# Filter events by type
docker events --filter type=container

# Block until a container stops, then print its exit code
docker wait <container-id-or-name>

# Show which processes are using the most resources across all containers once
docker stats --no-stream

# Check an image for known vulnerabilities (Docker Scout)
docker scout cves my-app:latest

# Quick summary comparison of an image against a base/tag
docker scout quickview my-app:latest
```

## 11. Docker Context (Managing Multiple Docker Hosts)

```bash
# List available contexts
docker context ls

# Create a new context (e.g. for a remote host)
docker context create remote-host --docker "host=ssh://user@remote-ip"

# Switch to a different context
docker context use remote-host

# Remove a context
docker context rm remote-host
```

## 12. Registry & Image Distribution

```bash
# Log in to a private registry
docker login myregistry.com

# Tag an image for a private registry
docker tag my-app:latest myregistry.com/my-app:latest

# Push to the private registry
docker push myregistry.com/my-app:latest

# Pull from the private registry
docker pull myregistry.com/my-app:latest

# Run a local registry (for testing)
docker run -d -p 5000:5000 --name registry registry:2
```

## 13. Docker Swarm (Native Orchestration)

```bash
# Initialize a swarm on the current node (becomes a manager)
docker swarm init

# Get the join command/token for adding a worker node
docker swarm join-token worker

# Get the join command/token for adding another manager node
docker swarm join-token manager

# Join an existing swarm (run on the new node)
docker swarm join --token <token> <manager-ip>:2377

# List nodes in the swarm
docker node ls

# Promote/demote a node
docker node promote <node-id>
docker node demote <node-id>

# Leave the swarm
docker swarm leave
docker swarm leave --force   # for a manager

# Deploy a stack from a compose file
docker stack deploy -c docker-compose.yml my-stack

# List stacks
docker stack ls

# List services in a stack
docker stack services my-stack

# List tasks (running instances) in a stack
docker stack ps my-stack

# Remove a stack
docker stack rm my-stack

# Create a standalone service
docker service create --name web --replicas 3 -p 8080:80 nginx

# List services
docker service ls

# Scale a service
docker service scale web=5

# Update a service's image
docker service update --image nginx:1.25 web

# Inspect a service
docker service inspect web

# Remove a service
docker service rm web

# Create a swarm secret
docker secret create my-secret ./secret.txt

# List secrets
docker secret ls

# Create a swarm config
docker config create my-config ./config.txt

# List configs
docker config ls
```

## 14. Cleaning Up

```bash
# Remove all stopped containers
docker container prune

# Remove all unused images
docker image prune -a

# Remove all unused volumes
docker volume prune

# Remove all unused networks
docker network prune

# Remove everything unused at once (containers, images, networks, cache)
docker system prune

# Remove everything unused INCLUDING volumes (destructive)
docker system prune -a --volumes

# Check disk space used by Docker
docker system df
```

## 15. Typical Everyday Workflow (Putting It Together)

```bash
# 1. Build the image
docker build -t my-app:latest .

# 2. Run it locally, mapping a port
docker run -d --name my-app -p 3000:3000 my-app:latest

# 3. Check it's running
docker ps

# 4. Check logs to confirm it started correctly
docker logs -f my-app

# 5. Exec in to debug if something looks wrong
docker exec -it my-app sh

# 6. Stop and remove the container when done
docker stop my-app
docker rm my-app

# 7. Tag and push to a registry for deployment
docker tag my-app:latest myregistry.com/my-app:v1
docker push myregistry.com/my-app:v1

# 8. Or, spin up a full multi-service stack with Compose
docker compose up -d
docker compose logs -f
docker compose down
```
