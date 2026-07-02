#!/bin/bash
#
# Exit immediately if a command exits with a non-zero status
set -e

# Helper function to print text and sleep for 3 seconds
run_step() {
    echo "=== $1 ==="
    sleep 3
}

run_step "1. Disabling Swap (Required by Kubernetes)"
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
echo ""

run_step "2. Updating System Packages"
sudo apt update && sudo apt upgrade -y
echo ""

run_step "3. Installing Containerd Docker Runtime"
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker.io -y
echo ""

run_step "6. Starting Docker"
sudo systemctl start docker 
echo ""

run_step "4. Create containerd configuration"
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
echo ""

run_step "5. Edit /etc/containerd/config.toml"
sudo sed -i -e 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
echo ""

run_step "6. Restarting Docker"
sudo systemctl restart docker && sudo systemctl enable --now docker
echo ""

run_step "7. 👤 Adding current user to the Docker group..."
sudo apt install util-linux-extra
sudo usermod -aG docker $USER
newgrp docker
echo ""

run_step "8. Installing Kubernetes "
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet
echo ""

run_step "9. Enable kernel modules"
sudo modprobe br_netfilter
echo ""

run_step "10. Add some settings to sysctl"
sudo sysctl -w net.ipv4.ip_forward=1
echo ""

run_step "11. Initialize the Cluster (Run only on master)"
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
echo ""

run_step "12. Create a .kube directory in your home directory"
mkdir -p $HOME/.kube
echo ""

run_step "13. Copy the Kubernetes configuration file to your home directory"
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
echo ""

run_step "14. Change ownership of the file"
sudo chown $(id -u):$(id -g) $HOME/.kube/config
echo ""

run_step "15. Install Flannel (Run only on master)"
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
echo ""

run_step "16. Verify Installation"
kubectl get pods --all-namespaces
sudo systemctl status docker | cat

## Join Nodes
#To add nodes to the cluster, run the kubeadm join command with the appropriate arguments on each node. 
#The command will output a token that can be used to join the node to the cluster.


       echo "========================================================="
       echo " Installation Complete!"
       echo " Next steps:"
   
       echo " 1. If this is a Worker node, run the join command from the Master."
       echo "========================================================="

