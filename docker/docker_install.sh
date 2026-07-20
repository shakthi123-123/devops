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

run_step "01. 🐳 Installing Docker Engine..."
if command -v docker &>/dev/null; then
    log "Docker already installed: $(docker --version)"
else
    log "Installing Docker..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
echo ""
sudo apt install util-linux-extra -y
echo ""
sudo apt-get install docker.io -y
echo ""
fi

run_step "02. Starting Docker"
sudo systemctl start docker 
echo ""

run_step "03. Create containerd configuration"
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
echo ""

run_step "04. Edit /etc/containerd/config.toml"
sudo sed -i -e 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
echo ""

run_step "05. Restarting Docker"
sudo systemctl restart docker && sudo systemctl enable --now docker
echo ""

run_step "06. Check Docker Status"
sudo systemctl status docker | cat

run_step "07. 👤 Adding current user to the Docker group..."
#sudo usermod -aG docker $USER
#newgrp docker
#To ungroup use this cmd
#sudo deluser $USER docker
if ! getent group docker &>/dev/null; then
    log "Creating docker group..."
    sudo groupadd docker || true
fi

if ! groups "$USER" | grep -q '\bdocker\b'; then
    log "Adding $USER to docker group..."
    sudo usermod -aG docker "$USER"
    NEED_GROUP_REFRESH=1
else
    NEED_GROUP_REFRESH=0
fi

# Re-exec the rest of this script under the docker group so it works
# in this same session, without requiring a fresh login.
if [ "$NEED_GROUP_REFRESH" -eq 1 ] && [ "$(id -gn)" != "docker" ]; then
    if ! command -v sg &>/dev/null; then
        warn "'sg' command not found, attempting to install it..."
        sudo apt-get update -y && sudo apt-get install -y login || true
    fi

    if command -v sg &>/dev/null; then
        warn "Re-launching script under docker group (sg docker) to apply new membership..."
        SCRIPT_PATH="$(readlink -f "$0")"
        exec sg docker "$SCRIPT_PATH" "$@"
    else
        warn "'sg' is unavailable and could not be installed."
        warn "You were added to the docker group, but that only takes effect in a new session."
        warn "Please log out and back in (or run: newgrp docker), then re-run this script."
        exit 0
    fi
fi
