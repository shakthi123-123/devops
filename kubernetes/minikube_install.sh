#!/bin/bash
##Useful Commands for Cluster Management
#
# minikube stop (Stop the cluster)
# minikube pause (Pause operations)
# minikube delete (Delete the cluster environment completely)

# Exit immediately if a command exits with a non-zero status
set -e

run_step() {
             echo "======== $1 ========"
             sleep 4
}

echo "Starting Minikube installation on Ubuntu..."

run_step "1. Disabling Swap (Required by Kubernetes)"
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
echo ""

run_step "2. Updating system package list..."
sudo apt-get update -y
sudo apt install util-linux-extra -y
echo ""

run_step "3. Installing prerequisite packages (curl, apt-transport-https)..."
sudo apt-get install -y curl apt-transport-https virtualbox-ext-pack
echo ""

run_step "4. 🐳 Installing Docker Engine..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker.io -y
echo ""

run_step "5. Starting Docker"
sudo systemctl start docker 
echo ""

run_step "6. Create containerd configuration"
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
echo ""

run_step "7. Edit /etc/containerd/config.toml"
sudo sed -i -e 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
echo ""

run_step "8. Restarting Docker"
sudo systemctl restart docker && sudo systemctl enable --now docker
echo ""

run_step "9. ☸️ Installing kubectl..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl kubelet
sudo apt-mark hold kubectl kubelet
echo ""

run_step "10. 🚀 Installing Minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64
echo ""

run_step "11. Check Minikube..."
minikube version
echo ""

run_step "12. Start the Cluster Environment"
minikube start --driver=docker
echo ""

run_step "13. Verify and Interact with Your Cluster"
minikube status
kubectl get nodes
sudo systemctl status docker | cat
echo ""

run_step "14. 👤 Adding current user to the Docker group..."
sudo usermod -aG docker $USER
newgrp docker <<EOF
echo "✅ Installation complete!"
echo "⚠️ IMPORTANT: Please log out and log back in, or run 'newgrp docker' to apply group changes."
echo "🎯 After that, start your cluster using: minikube start --driver=docker"
echo ""Start a New Cluster with Multiple Nodes""
echo ""
echo "minikube start --nodes 3 -p multinode-demo (This sets up 1 control plane node and 2 worker nodes)."
echo "minikube node add  (Add a Worker Node to an Existing Cluster)."
echo "kubectl get nodes (LIST ONE OR MORE NODES)."
echo "kubectl label node 'node_name' kubernetes.io/role=worker1  but you can explicitly label a node to mark its specific worker."
echo "minikube node list -p multinode-demo."
echo "minikube ssh -n 'node_name' (Accessing the Worker Node)."
echo "minikube status -p multinode-demo."
EOF