#!/bin/bash
#
# Exit immediately if a command exits with a non-zero status
set -e

# Helper function to print text and sleep for 3 seconds
run_step() {
    echo "=== $1 ==="
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
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
    apt-get update
    apt-get install -y kubectl=1.30.* kubelet=1.30.* kubeadm=1.30.*
    apt-mark hold kubelet kubeadm kubectl
    systemctl enable --now kubelet
    log "kubelet, kubeadm & kubectl Installed"
fi
echo ""

run_step "12. Checking Versions"
log "Versions:"
echo "  - $(docker --version)"
echo "  - $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
echo "  - $(kubeadm version --client --short 2>/dev/null || kubeadm version --client)"
echo "  - $(kubelet version --client --short 2>/dev/null || kubelet version --client)"
echo ""

run_step "13. Enable kernel modules"
sudo modprobe br_netfilter
echo ""

run_step "14. Add some settings to sysctl"
sudo sysctl -w net.ipv4.ip_forward=1
echo ""

run_step "15. Initialize the Cluster (Run only on master)"
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
echo ""

run_step "16. Create a .kube directory in your home directory"
mkdir -p $HOME/.kube
echo ""

run_step "17. Copy the Kubernetes configuration file to your home directory"
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
echo ""

run_step "18. Change ownership of the file"
sudo chown $(id -u):$(id -g) $HOME/.kube/config
echo ""

run_step "19. Install Flannel (Run only on master)"
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
echo ""

run_step "20. Verify Installation"
kubectl get pods --all-namespaces
echo ""

run_step "21. Generate Worker Join Command"
JOIN_CMD=$(kubeadm token create --print-join-command)
echo "$JOIN_CMD" > "$HOME/kubeadm_join_command.sh"
chmod +x "$HOME/kubeadm_join_command.sh"
log "Join command saved to $HOME/kubeadm_join_command.sh"
echo ""

       echo "========================================================="
       echo " Installation Complete!"
       echo " Next steps:"
       echo " 1. Copy the join command below to each worker node and"
       echo "    run it with 'sudo kubeadm join ...' (or copy the"
       echo "    kubeadm_join_command.sh file and run it as root):"
       echo ""
       echo "    $JOIN_CMD"
       echo ""
       echo " 2. On the worker, run ks8_install_worker.sh <join-command>"
       echo "========================================================="
       echo "Restart The Terminal"
