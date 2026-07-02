# ☸️ Kubernetes Kubectl Command Cheat Sheet

A comprehensive, production-ready reference guide for managing Kubernetes clusters, nodes, pods, deployments, services, namespaces, and configurations.

---

## 🖥️ Cluster Management

###Disable Swap Space
Required on host machines before initializing or running a cluster.
```bash
sudo swapoff -a
```

### Get Built-in Tool Help
```bash
kubectl -h
```

### Check Kubelet Service Status
```bash
systemctl status kubelet
```

### View Cluster Information
```bash
kubectl cluster-info
```

### View Kubernetes Version Details
```bash
kubectl version
```

### Inspect Merged Kubeconfig Configuration
```bash
kubectl config view
```

### Extract List of Users from Kubeconfig
```bash
kubectl config view -o jsonpath='{.users[*].name}'
```

### Display the Active Context Name
```bash
kubectl config current-context
```

### List All Available Contexts
```bash
kubectl config get-contexts
```

### Configure or Modify a Context Entry
```bash
kubectl config set-context "context_name"
```

### Switch Active Target Context
```bash
kubectl config use-context "cluster_name"
```

### List Supported API Resources
```bash
kubectl api-resources
```

### List Supported API Versions
```bash
kubectl api-versions
```

### List All Core Resources Across All Namespaces
```bash
kubectl get all --all-namespaces
```

---

## 🔌 Node Administration

### List All Cluster Nodes
```bash
kubectl get nodes
```

### List Nodes with IP and OS Details
```bash
kubectl get nodes -o wide
```

### View Detailed Node Metrics and Status
```bash
kubectl describe node "node_name"
```

### View Real-Time Node CPU/Memory Usage
```bash
kubectl top node "node_name"
```

### Find Pods Running on a Specific Node
```bash
kubectl get pods -o wide | grep "node_name"
```

### Add metadata Annotation to a Node
```bash
kubectl annotate node "node_name" comment="maintenance_pending"
```

### Apply a Label to a Node
```bash
kubectl label node "node_name" kubernetes.io/role=worker1
```

### Add a Taint to a Node
```bash
kubectl taint node "node_name" key=value:NoSchedule
```

### Cordon a Node (Mark as Unschedulable)
```bash
kubectl cordon node "node_name"
```

### Uncordon a Node (Mark as Schedulable)
```bash
kubectl uncordon node "node_name"
```

### Drain Node safely for Maintenance
```bash
kubectl drain node "node_name" --ignore-daemonsets --delete-emptydir-data
```

### Open Node Configuration in Default Editor
```bash
kubectl edit node "node_name"
```

### Apply Partial JSON/YAML Update to a Node
```bash
kubectl patch node "node_name" -p '{"spec":{"unschedulable":true}}'
```

### Delete a Node from the Cluster
```bash
kubectl delete node "node_name"
```

---

## 📦 Pod Management

### List Pods in Active Namespace
```bash
kubectl get pods
```

### List Pods with IP and Target Node Details
```bash
kubectl get pods -o wide
```

### Spin up a New Standalone Pod
```bash
kubectl run "pod_name" --image=nginx
```

### Output Pod Specifications in JSON Format
```bash
kubectl get pods -o json
```

### Output Pod Specifications in YAML Format
```bash
kubectl get pods -o yaml
```

### Filter List by Running Pods
```bash
kubectl get pods --field-selector=status.phase=Running
```

### List Pods and Display Assigned Labels
```bash
kubectl get pods --show-labels
```

### Sort Pods by Container Restart Count
```bash
kubectl get pods --sort-by='.status.containerStatuses[0].restartCount'
```

### View Detailed Pod Configuration and Events
```bash
kubectl describe pod "pod_name"
```

### View Real-Time Pod Performance Metrics
```bash
kubectl top pod
```

### Print Logs for a Specific Pod
```bash
kubectl logs "pod_name"
```

### Stream Pod Logs in Real Time
```bash
kubectl logs -f "pod_name"
```

### Open an Interactive Terminal Inside a Pod Container
```bash
kubectl exec -it "pod_name" -c "container_name" -- /bin/sh
```

### Run a Single Command Against a Container
```bash
kubectl exec "pod_name" -c "container_name" -- ls -la
```

### Forward Local Traffic Port to a Pod Port
```bash
kubectl port-forward pod/"pod_name" 8080:80
```

### Block Script Execution Until a Pod is Ready
```bash
kubectl wait --for=condition=Ready pod/"pod_name"
```

### Copy Files from Local Host to Pod Container
```bash
kubectl cp /local/path/file.txt "pod_name":/path/in/pod/file.txt
```

### Copy Files from Pod Container to Local Host
```bash
kubectl cp "pod_name":/path/in/pod/file.txt /local/path/file.txt
```

### Add or Update Pod Labels
```bash
kubectl label pods "pod_name" environment=production
```

### Add or Update Pod Annotations
```bash
kubectl annotate pod "pod_name" description="frontend_app"
```

### Replace/Update a Pod Manifest Declaratively
```bash
kubectl replace -f pod.yaml
```

### Delete a Pod Safely with Grace Period
```bash
kubectl delete pod "pod_name" --grace-period=10
```

### Force Delete a Pod Immediately
```bash
kubectl delete pod "pod_name" --grace-period=0 --force
```

---

## 🚀 Deployment Controls

### Create Resources from a Directory or File
```bash
kubectl create -f ./manifest_folder/
```

### Apply/Update Resources from a Specific Manifest File
```bash
kubectl apply -f deployment.yaml
```

### List All Active Deployments
```bash
kubectl get deployments
```

### Stream Deployment State Changes in Real Time
```bash
kubectl get deployment "deployment_name" --watch
```

### View Detailed Deployment Operational Status
```bash
kubectl describe deployment "deployment_name"
```

### Scale Deployment Replicas Up or Down
```bash
kubectl scale deployment "deployment_name" --replicas=3
```

### Perform a Force Replace/Re-create Deployment
```bash
kubectl replace --force -f deployment.yaml
```

### Edit a Running Deployment Configuration Live
```bash
kubectl edit deployment "deployment_name"
```

### Trigger a Rolling Image Update
```bash
kubectl set image deployment/"deployment_name" "container_name"=nginx:1.25.3
```

### View Rolling Deployment Progress Status
```bash
kubectl rollout status deployment "deployment_name"
```

### View Rollout Version History
```bash
kubectl rollout history deployment "deployment_name"
```

### Roll Back to the Previous Deployment Version
```bash
kubectl rollout undo deployment "deployment_name"
```

### Delete a Deployment
```bash
kubectl delete deployment "deployment_name"
```

---

## 🔌 Service Discovery & Networking

### List All Services
```bash
kubectl get services
```

### View Service Endpoints and Routing Rules
```bash
kubectl describe service "service_name"
```

### Expose a Deployment as a LoadBalancer Service
```bash
kubectl expose deployment "deployment_name" --type=LoadBalancer --port=80
```

### Delete a Service
```bash
kubectl delete service "service_name"
```

---

