#!/bin/bash
##Useful Commands for Cluster Management
# Exit immediately if a command exits with a non-zero status
set -e

if sudo chmod +x /home/pc/devops/kubernetes/minikube_install.sh
then 
    echo "Mode Changed"
else
    echo "Mode No Changed"
fi

run_step() {
             echo "======== $1 ========"
             sleep 2
}
log()  { echo -e "\033[1;32m[+]\033[0m $*"; }
warn() { echo -e "\033[1;33m[!]\033[0m $*"; }
err()  { echo -e "\033[1;31m[x]\033[0m $*" >&2; }

run_step "1. Sanity checks"
if [ "$(id -u)" -eq 0 ]; then
    err "Don't run this script as root/with sudo directly. Run as your normal user;"
    err "it will call sudo internally where needed."
    exit 1
fi

ARCH="$(uname -m)"
case "$ARCH" in
    x86_64)  MINIKUBE_ARCH="amd64" ;;
    aarch64) MINIKUBE_ARCH="arm64" ;;
    *) err "Unsupported architecture: $ARCH"; exit 1 ;;
esac

echo "Starting Minikube installation on Ubuntu..."

run_step "2. Disabling Swap (Required by Kubernetes)"
    sudo swapoff -a
    sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

if sudo chmod +x /home/pc/devops/docker/docker_install.sh
then 
  . /home/pc/devops/docker/docker_install.sh
else
    echo "Docker not Installed"
    exit 1
fi
echo ""

run_step "3. ☸️ Installing kubectl..."
if command -v kubectl &>/dev/null; then
    log "kubectl already installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
else
    log "Installing kubectl..."
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update
    sudo apt-get install -y kubectl=1.30.* kubelet=1.30.*
    sudo apt-mark hold kubectl kubelet
    log "kubectl installed: $(kubectl version --client)"  
fi    
echo ""
         
run_step "4. 🚀 Installing Minikube..."
if command -v minikube &>/dev/null; then
    log "minikube already installed: $(minikube version --short 2>/dev/null || minikube version)"
else
    log "Installing minikube..."
    sudo curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    sudo rm -f minikube-linux-amd64
    log "minikube installed: $(minikube version)"
fi
echo ""

run_step "5. Check Minikube..."
    minikube version
    echo ""
run_step "6. Start the Cluster Environment"
    minikube start --nodes=2 --driver=docker --kubernetes-version=v1.30.0
    kubectl label node minikube-m02 kubernetes.io/role=worker1
    echo ""

run_step "7. Verify and Interact with Your Cluster"
    log "Done. Cluster status:"
    minikube status
    echo ""
    kubectl get nodes
echo ""

echo "✅ Installation complete!"
echo ""
echo ""Start a New Cluster with Multiple Nodes""
echo "All set! Try: kubectl get pods -A"
echo "minikube start --nodes 2 -p multinode-demo (This sets up 1 control plane node and 1 worker node)."
echo "minikube node add  (Add a Worker Node to an Existing Cluster)."
echo "kubectl get nodes (LIST ONE OR MORE NODES)."
echo "kubectl label node 'node_name' kubernetes.io/role=worker1  but you can explicitly label a node to mark its specific worker."
echo "minikube ssh -n 'node_name' (Accessing the Worker Node)."
echo "minikube stop (Stop the cluster)"
echo "minikube pause (Pause operations)"
echo "minikube delete (Delete the cluster environment completely)"
