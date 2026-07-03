# ☸️ Kubernetes Kubectl Command Cheat Sheet

A comprehensive, production-ready reference guide for managing Kubernetes clusters, nodes, pods, deployments, services, namespaces, and configurations.

---

## 1. 🖥️ Cluster Management

# Disable Swap Space **
Required on host machines before initializing or running a cluster
```bash
sudo swapoff -a
```

#Get Built-in Tool Help
```bash
kubectl -h
```

# Check Kubelet Service Status
```bash
systemctl status kubelet
```

# View Cluster Information
```bash
kubectl cluster-info
```

** View Kubernetes Version Details
```bash
kubectl version
```

** Inspect Merged Kubeconfig Configuration
```bash
kubectl config view
```

** Extract List of Users from Kubeconfig
```bash
kubectl config view -o jsonpath='{.users[*].name}'
```

** Display the Active Context Name
```bash
kubectl config current-context
```

** List All Available Contexts
```bash
kubectl config get-contexts
```

** Configure or Modify a Context Entry
```bash
kubectl config set-context "context_name"
```
** Switch Active Target Context
```bash
kubectl config use-context "cluster_name"
```

** List Supported API Resources
```bash
kubectl api-resources
```

** List Supported API Versions
```bash
kubectl api-versions
```

** List All Core Resources Across All Namespaces
```bash
kubectl get all --all-namespaces
```

---

##2. 🔌 Node Administration

** List All Cluster Nodes
```bash
kubectl get nodes
```

** List Nodes with IP and OS Details
```bash
kubectl get nodes -o wide
```

** View Detailed Node Metrics and Status
```bash
kubectl describe node "node_name"
```
** View Real-Time Node CPU/Memory Usage
```bash
kubectl top node "node_name"
```

** Find Pods Running on a Specific Node
```bash
kubectl get pods -o wide | grep "node_name"
```

** Add metadata Annotation to a Node
```bash
kubectl annotate node "node_name" comment="maintenance_pending"
```

** Apply a Label to a Node
```bash
kubectl label node "node_name" kubernetes.io/role=worker1
```

** Add a Taint to a Node
```bash
kubectl taint node "node_name" key=value:NoSchedule
```

** Cordon a Node (Mark as Unschedulable)
```bash
kubectl cordon node "node_name"
```

** Uncordon a Node (Mark as Schedulable)
```bash
kubectl uncordon node "node_name"
```

** Drain Node safely for Maintenance
```bash
kubectl drain node "node_name" --ignore-daemonsets --delete-emptydir-data
```

**Open Node Configuration in Default Editor
```bash
kubectl edit node "node_name"
```

**Apply Partial JSON/YAML Update to a Node
```bash
kubectl patch node "node_name" -p '{"spec":{"unschedulable":true}}'
```

**Delete a Node from the Cluster
```bash
kubectl delete node "node_name"
```

---

##3. 🚀 Deployment Controls

**Create Resources from a Directory or File
```bash
kubectl create -f deployment.yaml
```

**Apply/Update Resources from a Specific Manifest File
```bash
kubectl apply -f deployment.yaml
```

**List All Active Deployments
```bash
kubectl get deployments
```

**Stream Deployment State Changes in Real Time
```bash
kubectl get deployment "deployment_name" --watch
```

**View Detailed Deployment Operational Status
```bash
kubectl describe deployment "deployment_name"
```

**Scale Deployment Replicas Up or Down
```bash
kubectl scale deployment "deployment_name" --replicas=3
```

**Perform a Force Replace/Re-create Deployment
```bash
kubectl replace --force -f deployment.yaml
```

**Edit a Running Deployment Configuration Live
```bash
kubectl edit deployment "deployment_name"
```

**Trigger a Rolling Image Update
```bash
kubectl set image deployment/"deployment_name" "container_name"=nginx:1.25.3
```

**View Rolling Deployment Progress Status
```bash
kubectl rollout status deployment "deployment_name"
```

**View Rollout Version History
```bash
kubectl rollout history deployment "deployment_name"
```

**Roll Back to the Previous Deployment Version
```bash
kubectl rollout undo deployment "deployment_name"
```

**Delete a Deployment
```bash
kubectl delete deployment "deployment_name"
```

---

##4. 📦 Pod Management

**List Pods in Active Namespace
```bash
kubectl get pods
```

**List Pods with IP and Target Node Details
```bash
kubectl get pods -o wide
```

**Spin up a New Standalone Pod
```bash
kubectl run "pod_name" --image=nginx
```

**Output Pod Specifications in JSON Format
```bash
kubectl get pods -o json
```

**Output Pod Specifications in YAML Format
```bash
kubectl get pods -o yaml
```

**Filter List by Running Pods
```bash
kubectl get pods --field-selector=status.phase=Running
```

**List Pods and Display Assigned Labels
```bash
kubectl get pods --show-labels
```

**Sort Pods by Container Restart Count
```bash
kubectl get pods --sort-by='.status.containerStatuses[0].restartCount'
```

**View Detailed Pod Configuration and Events
```bash
kubectl describe pod "pod_name"
```

**View Real-Time Pod Performance Metrics
```bash
kubectl top pod
```

**Print Logs for a Specific Pod
```bash
kubectl logs "pod_name"
```

**Stream Pod Logs in Real Time
```bash
kubectl logs -f "pod_name"
```

**Open an Interactive Terminal Inside a Pod Container
```bash
kubectl exec -it "pod_name" -c "container_name" -- /bin/sh
```

**Run a Single Command Against a Container
```bash
kubectl exec "pod_name" -c "container_name" -- ls -la
```

**Forward Local Traffic Port to a Pod Port
```bash
kubectl port-forward pod/"pod_name" 8080:80
```

**Block Script Execution Until a Pod is Ready
```bash
kubectl wait --for=condition=Ready pod/"pod_name"
```

**Copy Files from Local Host to Pod Container
```bash
kubectl cp /local/path/file.txt "pod_name":/path/in/pod/file.txt
```

**Copy Files from Pod Container to Local Host
```bash
kubectl cp "pod_name":/path/in/pod/file.txt /local/path/file.txt
```

**Add or Update Pod Labels
```bash
kubectl label pods "pod_name" environment=production
```

**Add or Update Pod Annotations
```bash
kubectl annotate pod "pod_name" description="frontend_app"
```

**Replace/Update a Pod Manifest Declaratively
```bash
kubectl replace -f pod.yaml
```

**Delete a Pod Safely with Grace Period
```bash
kubectl delete pod "pod_name" --grace-period=10
```

**Force Delete a Pod Immediately
```bash
kubectl delete pod "pod_name" --grace-period=0 --force
```

##5. 🔌 Service Discovery & Networking

**List All Services
```bash
kubectl get services
```

**View Service Endpoints and Routing Rules
```bash
kubectl describe service "service_name"
```

**Expose a Deployment as a LoadBalancer Service
```bash
kubectl expose deployment "deployment_name" --type=LoadBalancer --port=80
```

**Delete a Service
```bash
kubectl delete service "service_name"
```

---

##6. 📂 Namespaces & Configuration

**Create a Namespace Layer
```bash
kubectl create namespace "namespace_name"
```

**Edit Namespace Configuration Live
```bash
kubectl edit namespace "namespace_name"
```

**View Specifications of a Specific Namespace
```bash
kubectl get namespace "namespace_name"
```

**View Resource Metrics Aggregated by Namespace
```bash
kubectl top namespace "namespace_name"
```

**Find Namespace-Scoped Resource Types
```bash
kubectl api-resources --namespaced=true
```

**List All Cluster Namespaces
```bash
kubectl get namespaces
```

**View Detailed Namespace Metadata and Quotas
```bash
kubectl describe namespace "namespace_name"
```

**Delete a Namespace (Drops all associated resources)
```bash
kubectl delete namespace "namespace_name"
```

**List Pods Scoped to a Specific Namespace
```bash
kubectl get pods -n "namespace_name"
```

---

##7. 🔐 Configuration Management (Secrets & ConfigMaps)

**Create a ConfigMap from a Local File
```bash
kubectl create configmap "configmap_name" --from-file=path/to/file
```

**Create a ConfigMap from a Literal Key-Value Pair
```bash
kubectl create configmap "configmap_name" --from-literal=key=value
```

**Create a Generic Secret from a Literal Key-Value Pair
```bash
kubectl create secret generic "secret_name" --from-literal=key=value
```

**Create a Generic Secret from a Local File
```bash
kubectl create secret generic "secret_name" --from-file=path/to/file
```

**View Detailed Information About a ConfigMap
```bash
kubectl describe configmap "configmap_name"
```

**View Detailed Information About a Secret
```bash
kubectl describe secret "secret_name"
```

**List All ConfigMaps in the Active Namespace
```bash
kubectl get configmaps
```

**List All Secrets in the Active Namespace
```bash
kubectl get secrets
```

**Delete a Secret
```bash
kubectl delete secret "secret_name"
```

---

##8. 💾 Storage & Volume Management

**List All Persistent Volumes
```bash
kubectl get pv
```

**List All Persistent Volume Claims in Active Namespace
```bash
kubectl get pvc
```

**View Detailed Profile of a Persistent Volume
```bash
kubectl describe pv "pv_name"
```

**View Detailed Profile of a Persistent Volume Claim
```bash
kubectl describe pvc "pvc_name"
```

---

##9. 🏥 Container Health Checks
> **Note:** Readiness and Liveness probes are properties defined within a Pod's YAML manifest. They do not have unique top-level get commands.

**Inspect Container Probe Configuration, State, and Failures
```bash
kubectl describe pod "pod_name"
```

---

##10. 🚀 Advanced Operations

**Apply or Update Infrastructure from a Manifest File
```bash
kubectl apply -f "filename.yaml"
```

**Look Up Fields, Keys, and API Documentation for a Resource
```bash
kubectl explain pods.spec.containers
```

---

##11. 📄 Log Management

**Print Logs for a Single-Container Pod
```bash
kubectl logs "pod_name"
```

**Print Logs for a Target Container Inside a Multi-Container Pod
```bash
kubectl logs "pod_name" -c "container_name"
```

**Print Logs Generated within the Last 6 Hours
```bash
kubectl logs --since=6h "pod_name"
```

**Stream Only the Most Recent 50 Lines of Logs
```bash
kubectl logs --tail=50 "pod_name"
```

**Stream Pod Logs Interactively in Real Time
```bash
kubectl logs -f "pod_name"
```

**Output Pod Logs Directly into a Local Text File
```bash
kubectl logs "pod_name" > pod.log
```

**View Logs from a Previously Crashed Container Instance
```bash
kubectl logs --previous "pod_name"
```

**Include RFC3339 Micro-Timestamps in Log Outputs
```bash
kubectl logs --timestamps "pod_name"
```

**Fetch Merged Logs for All Pods Matching a Label
```bash
kubectl logs -l app="label_name"
```

---

##12. 👹 DaemonSets Administration

**Create or Update a DaemonSet Infrastructure Layer
```bash
kubectl apply -f daemonset.yaml
```

**List DaemonSets Active in the Current Namespace
```bash
kubectl get daemonset
```

**List Every DaemonSet Active Across All Namespaces
```bash
kubectl get daemonsets --all-namespaces
```

**Export Running DaemonSet State to a Clean YAML File
```bash
kubectl get daemonset "daemonset_name" -o yaml
```

**Edit a Live DaemonSet Specification Configuration File
```bash
kubectl edit daemonset "daemonset_name"
```

**Delete a DaemonSet Node Workload completely
```bash
kubectl delete daemonset "daemonset_name"
```

**View the Rolling Update Rollout History of a DaemonSet
```bash
kubectl rollout history daemonset "daemonset_name"
```

**View Deep Metadata and Node Placement Status for a DaemonSet
```bash
kubectl describe ds "daemonset_name" -n "namespace_name"
```

---

##13. 🔔 Event Monitoring & Troubleshooting

**List Recent Activity Logs and System Events for All Namespace Resources
```bash
kubectl get events
```

**Filter Event Feed to Show Warning Messages Only
```bash
kubectl get events --field-selector type=Warning
```

**Sort Active Cluster Event Feed by Creation Timestamp
```bash
kubectl get events --sort-by=.metadata.creationTimestamp
```

**Isolate Non-Pod Infrastructure Events
```bash
kubectl get events --field-selector involvedObject.kind!=Pod
```

**Isolate Event Signals Linked to a Target Node Instance
```bash
kubectl get events --field-selector involvedObject.kind=Node,involvedObject.name="node_name"
```

** Suppress Normal Event Types to Focus Solely on Cluster Errors
```bash
kubectl get events --field-selector type!=Normal
```

