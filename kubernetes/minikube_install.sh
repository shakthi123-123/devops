#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

run_step() {
    echo "======== $1 ========"
    sleep 3
}

log()  { echo -e "\033[1;32m[+]\033[0m $*"; }
warn() { echo -e "\033[1;33m[!]\033[0m $*"; }
err()  { echo -e "\033[1;31m[x]\033[0m $*" >&2; }

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    err "This script must be run as root or with sudo"
    exit 1
fi

echo "Starting Minikube installation on Ubuntu..."

run_step "0. Changing Docker to Execute Mode"
if sudo chmod +x /home/pc/devops/docker/docker_install.sh
then
    . /home/pc/devops/docker/docker_install.sh
fi

run_step "9. Checking Prerequisites"

# Check if Docker is installed and running
if ! command -v docker &>/dev/null; then
    err "Docker is not installed!"
    err "Please install Docker first using docker_install_fixed.sh"
    exit 1
else
    log "Docker found: $(docker --version)"
fi

if ! systemctl is-active --quiet docker; then
    warn "Docker daemon is not running. Starting it..."
    systemctl start docker
    sleep 2
fi

# Check user is in docker group
if [[ -n "${SUDO_USER:-}" ]]; then
    DOCKER_USER="$SUDO_USER"
else
    DOCKER_USER="$USER"
fi

if id -nG "$DOCKER_USER" | grep -qw docker; then
    log "User '$DOCKER_USER' is in docker group"
else
    warn "User '$DOCKER_USER' is NOT in docker group. Adding..."
    usermod -aG docker "$DOCKER_USER"
    log "Please log out and log back in for group changes to take effect"
fi

echo ""

run_step "10. Disabling Swap (Required by Kubernetes)"
if grep -q "swap" /etc/fstab; then
    swapoff -a
    sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
    log "Swap disabled"
else
    log "Swap already disabled"
fi

echo ""

run_step "11. Installing kubectl..."
if command -v kubectl &>/dev/null; then
    log "kubectl already installed: $(kubectl version --client --short 2>/dev/null || echo 'installed')"
else
    log "Installing kubectl..."
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
    apt-get update
    apt-get install -y kubectl=1.30.* kubelet=1.30.*
    apt-mark hold kubectl kubelet
    log "kubectl installed"
fi

echo ""

run_step "12. Installing Minikube..."
if command -v minikube &>/dev/null; then
    log "minikube already installed: $(minikube version 2>/dev/null || echo 'installed')"
else
    log "Installing minikube..."
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    install minikube-linux-amd64 /usr/local/bin/minikube
    rm -f minikube-linux-amd64
    log "minikube installed"
fi

echo ""

run_step "13. Checking Versions"
log "Versions:"
echo "  - $(docker --version)"
echo "  - $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
echo "  - $(minikube version)"

echo ""

run_step "14. Starting Minikube Cluster (2 nodes)"

# Get the actual user for minikube
if [[ -n "${SUDO_USER:-}" ]]; then
    ACTUAL_USER="$SUDO_USER"
else
    ACTUAL_USER="root"
fi

log "Starting minikube as user: $ACTUAL_USER"

# Start minikube with proper user context
if [[ "$ACTUAL_USER" != "root" ]]; then
    sudo -u "$ACTUAL_USER" minikube start \
        --nodes=2 \
        --driver=docker \
        --kubernetes-version=v1.30.0 \
        --addons=metrics-server,dashboard
else
    minikube start \
        --nodes=2 \
        --driver=docker \
        --kubernetes-version=v1.30.0 \
        --addons=metrics-server,dashboard
fi

echo ""

run_step "15. Configuring Worker Nodes"
if [[ "$ACTUAL_USER" != "root" ]]; then
    sudo -u "$ACTUAL_USER" kubectl label node minikube-m02 kubernetes.io/role=worker1 --overwrite
else
    kubectl label node minikube-m02 kubernetes.io/role=worker1 --overwrite
fi
log "Worker node labeled"

echo ""

run_step "16. Verifying Cluster"
if [[ "$ACTUAL_USER" != "root" ]]; then
    log "Cluster status:"
    sudo -u "$ACTUAL_USER" minikube status
    echo ""
    log "Nodes:"
    sudo -u "$ACTUAL_USER" kubectl get nodes
else
    log "Cluster status:"
    minikube status
    echo ""
    log "Nodes:"
    kubectl get nodes
fi

echo ""
log "✅ Minikube installation complete!"
echo ""
echo "  kubectl get pods -A                          # List all pods"
echo "  minikube dashboard                           # Open web dashboard"
echo "  minikube stop                                # Stop the cluster"
echo "  minikube delete                              # Delete the cluster"
echo "  kubectl apply -f <your-deployment>.yaml      # Deploy your app"
echo ""
echo "Restart the Terminal and Start Minikube"
