#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

run_step() {
    echo "======== $1 ========"
    sleep 2
}

log()  { echo -e "\033[1;32m[+]\033[0m $*"; }
warn() { echo -e "\033[1;33m[!]\033[0m $*"; }
err()  { echo -e "\033[1;31m[x]\033[0m $*" >&2; }

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    err "This script must be run as root or with sudo"
    exit 1
fi

run_step "1. 🐳 Installing Docker Engine..."
if command -v docker &>/dev/null; then
    log "Docker already installed: $(docker --version)"
else
    log "Installing Docker..."
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt install util-linux-extra -y
    apt-get install docker.io -y
fi

run_step "2. Starting Docker"
systemctl start docker 
if systemctl is-active --quiet docker; then
    log "Docker daemon is running"
else
    err "Failed to start Docker daemon"
    exit 1
fi
echo ""

run_step "3. Create containerd configuration"
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml > /dev/null
echo ""

run_step "4. Edit /etc/containerd/config.toml"
sed -i -e 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
log "SystemdCgroup enabled"
echo ""

run_step "5. Restarting Docker"
systemctl restart docker && systemctl enable --now docker
if systemctl is-active --quiet docker; then
    log "Docker daemon restarted successfully"
else
    err "Failed to restart Docker daemon"
    exit 1
fi
echo ""

run_step "6. Check Docker Status"
systemctl status docker | cat

run_step "7. 👤 Adding current user to the Docker group..."

# Get the actual user (not root)
if [[ -n "${SUDO_USER:-}" ]]; then
    DOCKER_USER="$SUDO_USER"
else
    DOCKER_USER="root"
fi

if [[ "$DOCKER_USER" != "root" ]]; then
    usermod -aG docker "$DOCKER_USER"
    log "User '$DOCKER_USER' added to docker group"
    log "Please log out and log back in, or run: newgrp docker"
else
    warn "Running as root, skipping user group addition"
fi

echo ""
run_step "8. Testing Docker"
if docker run --rm hello-world &>/dev/null; then
    log "Docker test successful!"
else
    warn "Docker test failed. Permissions might need group refresh."
fi

log "✅ Docker installation complete!"
