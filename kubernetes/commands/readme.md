# Kubernetes: Complete Step-by-Step Commands Guide

## Table of Content
## [1. Initial Setup & Cluster Access][(1. Initial Setup & Cluster Access)]

## 1. Initial Setup & Cluster Access

```bash
# Check kubectl version (client + server)
kubectl version

# Check cluster info
kubectl cluster-info

# Built-in kubectl help
kubectl -h
kubectl <command> -h

# Check the kubelet service status on a node
systemctl status kubelet

# View current context
kubectl config current-context

# List all available contexts
kubectl config get-contexts

# Switch to a different context/cluster
kubectl config use-context <context-name>

# Create or update a context entry in kubeconfig
kubectl config set-context <name> --cluster=<cluster> --user=<user> --namespace=<namespace>

# View the full kubeconfig
kubectl config view

# List configured users in kubeconfig
kubectl config view -o jsonpath='{.users[*].name}'

# Delete a context from kubeconfig
kubectl config delete-context <context-name>

# Set a default namespace for the current context
kubectl config set-context --current --namespace=<namespace>

# Handy shell alias
echo 'alias k=kubectl' >> ~/.bashrc
```

## 2. Creating a Cluster (Local Dev Options)

```bash
# --- minikube ---
minikube start
minikube start --driver=docker --cpus=4 --memory=8192
minikube status
minikube stop
minikube delete

# Get the URL for a service exposed via minikube
minikube service -n <namespace> <service-name> --url

# --- kind (Kubernetes in Docker) ---
kind create cluster
kind create cluster --name my-cluster
kind get clusters
kind delete cluster --name my-cluster

# --- k3d (lightweight k3s in Docker) ---
k3d cluster create mycluster
k3d cluster list
k3d cluster delete mycluster
```

## 3. Creating a Managed Cluster (Amazon EKS)

```bash
# Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version

# Install kubectl (example for a pinned version)
curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.17.7/2020-07-08/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin
kubectl version --client

# Create an EKS cluster with a managed node group
eksctl create cluster \
  --name eks-cluster-demo \
  --version 1.29 \
  --region us-west-1 \
  --nodegroup-name eks-worker-nodes \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 2 \
  --nodes-max 4 \
  --ssh-access \
  --ssh-public-key mykey.pub \
  --managed

# Delete an EKS cluster
eksctl delete cluster --name eks-cluster-demo
```

## 4. Namespaces

```bash
# List all namespaces
kubectl get namespaces
kubectl get ns

# Create a namespace
kubectl create namespace my-namespace

# Create a namespace from a YAML file
kubectl apply -f namespace.yaml

# List a specific namespace
kubectl get namespace my-namespace

# Edit a namespace definition
kubectl edit namespace my-namespace

# Show which resource types are namespace-scoped vs cluster-scoped
kubectl api-resources --namespaced=true

# Run a command against a specific namespace
kubectl get pods -n my-namespace

# Describe a namespace
kubectl describe namespace my-namespace

# Delete a namespace (and everything inside it)
kubectl delete namespace my-namespace
```

## 5. Nodes

```bash
# List all nodes
kubectl get nodes

# List nodes with more detail (IP, OS, kubelet version)
kubectl get nodes -o wide

# Describe a specific node (capacity, conditions, pods running)
kubectl describe node <node-name>

# Find which pods are running on a specific node
kubectl get pods -o wide | grep <node-name>

# Mark a node as unschedulable (before maintenance)
kubectl cordon <node-name>

# Evict pods from a node and mark unschedulable
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Mark a node as schedulable again
kubectl uncordon <node-name>

# Label a node
kubectl label node <node-name> disktype=ssd

# Annotate a node
kubectl annotate node <node-name> maintenance-window="Sat 02:00 UTC"

# Edit a node's definition directly (e.g. labels/taints)
kubectl edit node <node-name>

# Apply a partial (JSON/YAML) patch to a node
kubectl patch node <node-name> -p '{"metadata":{"labels":{"env":"prod"}}}'

# Remove a node from the cluster
kubectl delete node <node-name>

# Show resource usage per node (requires metrics-server)
kubectl top nodes
kubectl top node <node-name>
```

## 6. Taints & Tolerations

```bash
# Add a taint to a node (repels pods unless they tolerate it)
kubectl taint nodes <node-name> key=value:NoSchedule

# Add a taint that also evicts existing non-tolerating pods
kubectl taint nodes <node-name> key=value:NoExecute

# Remove a taint from a node
kubectl taint nodes <node-name> key=value:NoSchedule-

# View taints on a node
kubectl describe node <node-name> | grep Taints
```

## 7. Pods

```bash
# List pods in current namespace
kubectl get pods

# List pods in all namespaces
kubectl get pods --all-namespaces
kubectl get pods -A

# List pods with more detail (node, IP)
kubectl get pods -o wide

# Output pod info as JSON or YAML
kubectl get pods -o=json
kubectl get pods -o=yaml

# Watch pods in real time
kubectl get pods -w

# Sort pods by restart count (spot crash-looping pods fast)
kubectl get pods --sort-by='.status.containerStatuses[0].restartCount'

# Filter pods by a field, e.g. only Running pods
kubectl get pods --field-selector=status.phase=Running

# Describe a pod (events, status, container info)
kubectl describe pod <pod-name>

# Create a pod from a YAML file
kubectl apply -f pod.yaml

# Run a quick one-off pod
kubectl run my-pod --image=nginx --restart=Never

# Replace a pod using a modified YAML definition (common in CI/CD)
kubectl replace -f pod.yaml

# Force replace: delete and re-create the resource
kubectl replace --force -f pod.yaml

# Delete a pod
kubectl delete pod <pod-name>

# Delete a pod with a custom grace period
kubectl delete pod <pod-name> --grace-period=10

# Delete a pod immediately (skip graceful termination)
kubectl delete pod <pod-name> --grace-period=0 --force

# Get pod logs
kubectl logs <pod-name>

# Follow logs in real time
kubectl logs -f <pod-name>

# Get logs from a specific container in a multi-container pod
kubectl logs <pod-name> -c <container-name>

# Get logs from all containers in a pod
kubectl logs <pod-name> --all-containers=true

# Get logs from a previous (crashed) container instance
kubectl logs <pod-name> --previous

# Execute a command inside a running pod
kubectl exec -it <pod-name> -- /bin/bash
kubectl exec -it <pod-name> -- sh

# Execute in a specific container of a multi-container pod
kubectl exec -it <pod-name> -c <container-name> -- sh

# Copy files to/from a pod
kubectl cp <pod-name>:/path/in/pod ./local-path
kubectl cp ./local-path <pod-name>:/path/in/pod

# Show resource usage per pod (requires metrics-server)
kubectl top pods

# Show resource usage broken down by container
kubectl top pods --containers

# Add or update a pod's annotation
kubectl annotate pod <pod-name> description="handles checkout"

# Add or update a pod's label
kubectl label pods <pod-name> tier=frontend

# Show pods with their labels
kubectl get pods --show-labels

# Filter pods by label with -l
kubectl get pods -l tier=frontend

# Forward a local port to a pod
kubectl port-forward <pod-name> 8080:80

# Wait for a pod to reach a condition (e.g. in scripts/CI)
kubectl wait --for=condition=Ready pod/<pod-name> --timeout=60s
```

## 8. Deployments

```bash
# Create a deployment
kubectl create deployment my-app --image=nginx

# Apply a deployment from YAML
kubectl apply -f deployment.yaml

# Create resources from a file, directory, or URL (older alias of apply)
kubectl create -f ./deployment.yaml

# List deployments
kubectl get deployments
kubectl get deploy

# List deployments in a specific namespace
kubectl get deploy -n my-namespace

# Stream deployment changes in real time
kubectl get deployment my-app --watch

# Describe a deployment
kubectl describe deployment my-app

# Scale a deployment manually
kubectl scale deployment my-app --replicas=5

# Update the image of a running deployment
kubectl set image deployment/my-app my-app=nginx:1.25

# Check rollout status
kubectl rollout status deployment/my-app

# View rollout history
kubectl rollout history deployment/my-app

# Roll back to the previous revision
kubectl rollout undo deployment/my-app

# Roll back to a specific revision
kubectl rollout undo deployment/my-app --to-revision=2

# Pause/resume a rollout (useful for batching changes)
kubectl rollout pause deployment/my-app
kubectl rollout resume deployment/my-app

# Restart a deployment (rolling restart of all pods)
kubectl rollout restart deployment/my-app

# Edit a deployment definition directly
kubectl edit deployment my-app

# Force replace: delete and re-create from a config file
kubectl replace --force -f deployment.yaml

# Get a deleted deployment's last known YAML (from a backup/etcd context) to recreate it
kubectl get deployment <deleted-deploy-name> -o yaml

# Delete a deployment
kubectl delete deployment my-app
```

## 9. Replication Controllers

```bash
# List replication controllers (legacy predecessor to ReplicaSets)
kubectl get rc

# List replication controllers in a specific namespace
kubectl get rc --namespace=my-namespace
```

## 10. ReplicaSets & StatefulSets

```bash
# List ReplicaSets
kubectl get replicasets
kubectl get rs

# Describe a ReplicaSet
kubectl describe rs <rs-name>

# Scale a ReplicaSet directly
kubectl scale rs <rs-name> --replicas=4

# List StatefulSets
kubectl get statefulsets
kubectl get sts

# Describe a StatefulSet (inspect configuration and status)
kubectl describe statefulset <statefulset-name>

# Scale a StatefulSet
kubectl scale statefulset my-app --replicas=3

# Edit a StatefulSet in place
kubectl edit statefulset <statefulset-name>

# Force a rolling update by patching the pod template (e.g. bump an annotation)
kubectl patch statefulset <statefulset-name> -p \
  '{"spec":{"template":{"metadata":{"annotations":{"date":"'"$(date +%s)"'"}}}}}'

# View pods managed by a StatefulSet via its label selector
kubectl get pods -l app=<statefulset-label>

# Delete a StatefulSet but keep its pods running
kubectl delete statefulset my-app --cascade=orphan

# Delete a StatefulSet and its pods
kubectl delete statefulset my-app
```

## 11. DaemonSets

```bash
# Create a DaemonSet from YAML
kubectl apply -f daemonset.yaml

# List DaemonSets (one pod per matching node, e.g. log collectors, CNI agents)
kubectl get daemonsets
kubectl get ds

# List DaemonSets across all namespaces
kubectl get daemonsets --all-namespaces

# Get a DaemonSet's YAML (for backup or inspection)
kubectl get daemonset <daemonset-name> -o yaml

# Describe a DaemonSet within a namespace
kubectl describe ds <daemonset-name> -n <namespace>

# Edit a DaemonSet definition directly
kubectl edit daemonset <daemonset-name>

# Check the status of a DaemonSet rollout
kubectl rollout status daemonset/<daemonset-name>

# Delete a DaemonSet
kubectl delete daemonset <daemonset-name>
```

## 12. Autoscaling (HPA)

```bash
# Create a Horizontal Pod Autoscaler targeting CPU usage
kubectl autoscale deployment my-app --cpu-percent=50 --min=2 --max=10

# List HPAs
kubectl get hpa

# Describe an HPA (current/target metrics, events)
kubectl describe hpa my-app

# Apply an HPA from YAML (e.g. for custom/memory metrics)
kubectl apply -f hpa.yaml

# Delete an HPA
kubectl delete hpa my-app
```

## 13. Services

```bash
# List services
kubectl get services
kubectl get svc

# List services in a specific namespace
kubectl get svc -n my-namespace

# Describe a service (endpoints, ports, selector)
kubectl describe service my-service

# Expose a deployment as a service
kubectl expose deployment my-app --port=80 --target-port=8080 --type=ClusterIP

# Common service types
kubectl expose deployment my-app --type=NodePort --port=80
kubectl expose deployment my-app --type=LoadBalancer --port=80

# Apply a service from YAML
kubectl apply -f service.yaml

# Delete a service
kubectl delete service my-service

# List the endpoints backing a service (actual pod IPs)
kubectl get endpoints my-service

# Confirm a service resolves via cluster DNS
nslookup my-service

# Forward a local port to a pod/service for debugging
kubectl port-forward pod/<pod-name> 8080:80
kubectl port-forward service/my-service 8080:80

# Run a temporary proxy to the Kubernetes API server
kubectl proxy
kubectl proxy --port=8001
```

## 14. NetworkPolicies

```bash
# List network policies
kubectl get networkpolicies
kubectl get netpol

# Describe a network policy
kubectl describe networkpolicy my-policy

# Apply a network policy from YAML
kubectl apply -f network-policy.yaml

# Delete a network policy
kubectl delete networkpolicy my-policy
```

## 15. Ingress

```bash
# List ingress resources
kubectl get ingress

# Describe an ingress (rules, backend, TLS)
kubectl describe ingress my-ingress

# Apply an ingress from YAML
kubectl apply -f ingress.yaml

# Install an ingress controller (e.g. ingress-nginx) from its official manifests
git clone https://github.com/kubernetes/ingress-nginx.git
kubectl apply -f ingress-nginx/deploy/static/provider/aws/deploy.yaml
kubectl -n ingress-nginx get pods -o wide
kubectl -n ingress-nginx get svc

# Delete an ingress
kubectl delete ingress my-ingress
```

## 16. ConfigMaps & Secrets

```bash
# Create a ConfigMap from literal values
kubectl create configmap my-config --from-literal=key1=value1 --from-literal=key2=value2

# Create a ConfigMap from a file
kubectl create configmap my-config --from-file=path/to/file

# List ConfigMaps
kubectl get configmaps
kubectl get cm

# View a ConfigMap's data
kubectl describe configmap my-config

# Base64-encode a value manually (useful when hand-writing a Secret manifest)
echo -n "myvalue" | base64

# Create a Secret from literal values
kubectl create secret generic my-secret --from-literal=key=value

# Create a Secret from a file
kubectl create secret generic my-secret --from-file=path/to/file

# Create a TLS secret
kubectl create secret tls my-tls-secret --cert=cert.crt --key=cert.key

# Create a Docker registry secret (for pulling private images)
kubectl create secret docker-registry my-registry-secret \
  --docker-server=myregistry.com \
  --docker-username=myuser \
  --docker-password=mypassword

# List Secrets
kubectl get secrets

# Show detailed info about all secrets
kubectl describe secrets

# View a Secret's decoded value
kubectl get secret my-secret -o jsonpath='{.data.password}' | base64 --decode

# Delete a ConfigMap or Secret
kubectl delete configmap my-config
kubectl delete secret my-secret
```

## 17. Persistent Volumes & Claims

```bash
# List local disk volumes on a host (outside Kubernetes, for context)
df -h

# List Persistent Volumes (cluster-wide storage)
kubectl get persistentvolumes
kubectl get pv

# List Persistent Volume Claims (namespace-scoped requests)
kubectl get persistentvolumeclaims
kubectl get pvc

# Describe a PV or PVC
kubectl describe pv <pv-name>
kubectl describe pvc <pvc-name>

# Apply a PVC from YAML
kubectl apply -f pvc.yaml

# List available storage classes
kubectl get storageclass
kubectl get sc

# Delete a PVC
kubectl delete pvc <pvc-name>
```

## 18. Health Checks (Readiness & Liveness Probes)

```bash
# Probes are defined in the pod/deployment spec, not queried directly —
# check their status through describe (Conditions/Events section)
kubectl describe pod <pod-name>

# Watch a pod's status transitions live to catch probe failures
kubectl get pods <pod-name> -w
```

## 19. Jobs & CronJobs

```bash
# Create a one-off Job from YAML
kubectl apply -f job.yaml

# List Jobs
kubectl get jobs

# Describe a Job
kubectl describe job my-job

# Delete a Job
kubectl delete job my-job

# Create a CronJob
kubectl create cronjob my-cronjob --image=busybox --schedule="*/5 * * * *" -- echo "hello"

# List CronJobs
kubectl get cronjobs
kubectl get cj

# Trigger a CronJob run manually
kubectl create job my-manual-run --from=cronjob/my-cronjob

# Suspend/resume a CronJob
kubectl patch cronjob my-cronjob -p '{"spec":{"suspend":true}}'
kubectl patch cronjob my-cronjob -p '{"spec":{"suspend":false}}'
```

## 20. Applying, Editing & Managing Manifests

```bash
# Apply a single manifest file
kubectl apply -f manifest.yaml

# Apply all manifests in a directory
kubectl apply -f ./k8s/

# Apply from a URL
kubectl apply -f https://example.com/manifest.yaml

# Preview changes without applying (dry run)
kubectl apply -f manifest.yaml --dry-run=client

# Show a diff between live state and manifest
kubectl diff -f manifest.yaml

# Edit a live resource directly
kubectl edit deployment my-app

# Patch a resource (merge specific fields)
kubectl patch deployment my-app -p '{"spec":{"replicas":3}}'

# Delete resources defined in a manifest file
kubectl delete -f manifest.yaml

# Generate a manifest as YAML without creating it (useful as a template)
kubectl create deployment my-app --image=nginx --dry-run=client -o yaml > deployment.yaml

# List every resource in a namespace at once
kubectl get all -n my-namespace

# List every resource across all namespaces
kubectl get all --all-namespaces
```

## 21. Kustomize

```bash
# Build and view the final manifest from a kustomization directory
kubectl kustomize ./overlays/production

# Apply resources using kustomize (built into kubectl)
kubectl apply -k ./overlays/production

# Delete resources defined via a kustomization
kubectl delete -k ./overlays/production
```

## 22. Labels & Selectors

```bash
# Add a label to a resource
kubectl label pod <pod-name> env=production

# Remove a label
kubectl label pod <pod-name> env-

# List resources filtered by label
kubectl get pods -l env=production

# List resources with multiple label conditions
kubectl get pods -l 'env=production,tier=frontend'

# List resources filtered by a field (not just labels)
kubectl get pods --field-selector status.phase=Running

# Show all labels on resources
kubectl get pods --show-labels
```

## 23. Debugging & Troubleshooting

```bash
# Get events sorted by time (great for diagnosing issues)
kubectl get events --sort-by='.metadata.creationTimestamp'

# Get events for a specific namespace
kubectl get events -n my-namespace

# Filter events to only Warnings
kubectl get events --field-selector type=Warning

# Filter out Normal events (surface only unusual ones)
kubectl get events --field-selector type!=Normal

# Exclude Pod events (focus on other resource types)
kubectl get events --field-selector involvedObject.kind!=Pod

# Get events for one specific node
kubectl get events --field-selector involvedObject.kind=Node,involvedObject.name=<node-name>

# Describe any resource for detailed status/events
kubectl describe pod <pod-name>

# Check why a pod is pending/crashing
kubectl describe pod <pod-name> | grep -A 10 Events

# Run a temporary debug pod with a shell
kubectl run debug --image=busybox -it --rm -- sh

# Attach an ephemeral debug container to a running pod (K8s 1.23+)
kubectl debug <pod-name> -it --image=busybox --target=<container-name>

# Check API resources available in the cluster
kubectl api-resources

# Check API versions supported
kubectl api-versions

# Explain a resource's fields (like built-in docs)
kubectl explain pod.spec.containers

# Get raw resource output as YAML/JSON
kubectl get pod <pod-name> -o yaml
kubectl get pod <pod-name> -o json

# Extract a specific field with JSONPath
kubectl get pod <pod-name> -o jsonpath='{.status.podIP}'

# Check overall control plane component health
kubectl get componentstatuses
```

## 24. Log Management

```bash
# Print the logs for a pod (multi-container: add -c <container_name>)
kubectl logs <pod-name>

# Logs from the last 6 hours
kubectl logs --since=6h <pod-name>

# Most recent 50 lines only
kubectl logs --tail=50 <pod-name>

# Follow logs live
kubectl logs -f <pod-name>

# Logs for one container in a multi-container pod
kubectl logs -c <container-name> <pod-name>

# Save logs to a local file
kubectl logs <pod-name> > pod.log

# View logs from a previously crashed/restarted container
kubectl logs --previous <pod-name>

# Include timestamps with each log line
kubectl logs --timestamps <pod-name>

# Get logs from all pods matching a label
kubectl logs -l app=my-app
```

## 25. RBAC (Roles & Permissions)

```bash
# List roles in a namespace
kubectl get roles

# List cluster-wide roles
kubectl get clusterroles

# List role bindings
kubectl get rolebindings
kubectl get clusterrolebindings

# Create a role
kubectl create role pod-reader --verb=get,list,watch --resource=pods

# Bind a role to a user/service account
kubectl create rolebinding my-binding --role=pod-reader --user=jane

# Create a ClusterRoleBinding (e.g. grant cluster-admin to a service account)
kubectl create clusterrolebinding dashboard-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=default:dashboard

# Check if you can perform an action (useful for debugging permissions)
kubectl auth can-i delete pods
kubectl auth can-i delete pods --as=jane
```

## 26. Service Accounts

```bash
# List service accounts
kubectl get serviceaccounts
kubectl get sa

# Create a service account
kubectl create serviceaccount my-app-sa

# Describe a service account (shows mounted secrets/tokens)
kubectl describe sa my-app-sa
kubectl describe serviceaccounts

# Bind a role to a service account
kubectl create rolebinding my-app-binding --role=pod-reader --serviceaccount=my-namespace:my-app-sa

# Replace a service account definition
kubectl replace serviceaccount my-app-sa -f serviceaccount.yaml

# Retrieve a service account's token secret (older token-based auth)
kubectl get secret $(kubectl get serviceaccount my-app-sa -o jsonpath="{.secrets[0].name}") \
  -o jsonpath="{.data.token}" | base64 --decode

# Delete a service account
kubectl delete sa my-app-sa
```

## 27. Kubernetes Dashboard (Web UI)

```bash
# Deploy the official Kubernetes Dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml

# Access the API server (and Dashboard) through a local proxy
kubectl proxy

# Check/edit the Dashboard's service (e.g. to change its type)
kubectl -n kubernetes-dashboard get svc
kubectl -n kubernetes-dashboard edit svc kubernetes-dashboard

# Create an admin service account to log in with
kubectl create serviceaccount dashboard -n default
kubectl create clusterrolebinding dashboard-admin \
  -n default --clusterrole=cluster-admin --serviceaccount=default:dashboard

# Get the login token for that service account
kubectl get secret $(kubectl get serviceaccount dashboard -o jsonpath="{.secrets[0].name}") \
  -o jsonpath="{.data.token}" | base64 --decode
```

## 28. Helm (Package Manager for Kubernetes)

```bash
# Add a chart repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Search for a chart
helm search repo nginx

# Install a chart (creates a "release")
helm install my-release bitnami/nginx

# List installed releases
helm list

# Upgrade a release
helm upgrade my-release bitnami/nginx --set replicaCount=3

# Roll back a release to a previous revision
helm rollback my-release 1

# Uninstall a release
helm uninstall my-release

# Show values used in a chart
helm show values bitnami/nginx
```

## 29. Cleaning Up

```bash
# Delete all resources of a type in current namespace
kubectl delete pods --all
kubectl delete deployments --all

# Delete everything in a namespace
kubectl delete all --all -n my-namespace

# Delete a namespace (removes everything inside it)
kubectl delete namespace my-namespace
```

## 30. Typical Everyday Workflow (Putting It Together)

```bash
# 1. Check current context/cluster
kubectl config current-context

# 2. Create a namespace for the app
kubectl create namespace my-app-ns

# 3. Apply manifests (deployment + service + configmap)
kubectl apply -f ./k8s/ -n my-app-ns

# 4. Watch rollout status
kubectl rollout status deployment/my-app -n my-app-ns

# 5. Check pods are running
kubectl get pods -n my-app-ns -w

# 6. View logs if something looks off
kubectl logs -f deployment/my-app -n my-app-ns

# 7. Port-forward to test locally
kubectl port-forward service/my-app 8080:80 -n my-app-ns

# 8. Scale up for load
kubectl scale deployment my-app --replicas=5 -n my-app-ns

# 9. Roll out a new image version
kubectl set image deployment/my-app my-app=myrepo/my-app:v2 -n my-app-ns
kubectl rollout status deployment/my-app -n my-app-ns

# 10. Roll back if something breaks
kubectl rollout undo deployment/my-app -n my-app-ns
```

## Quick Reference Table

| Task | Command |
|---|---|
| Cluster info | `kubectl cluster-info` |
| List nodes | `kubectl get nodes` |
| List pods | `kubectl get pods` |
| Describe resource | `kubectl describe pod <name>` |
| View logs | `kubectl logs <pod-name>` |
| Exec into pod | `kubectl exec -it <pod-name> -- sh` |
| Apply manifest | `kubectl apply -f file.yaml` |
| Apply with kustomize | `kubectl apply -k ./overlay` |
| Delete resource | `kubectl delete -f file.yaml` |
| Scale deployment | `kubectl scale deployment <name> --replicas=N` |
| Autoscale deployment | `kubectl autoscale deployment <name> --cpu-percent=50 --min=2 --max=10` |
| Rolling restart | `kubectl rollout restart deployment/<name>` |
| Roll back deployment | `kubectl rollout undo deployment/<name>` |
| Port forward | `kubectl port-forward pod/<name> 8080:80` |
| Get events | `kubectl get events --sort-by='.metadata.creationTimestamp'` |
| Get everything in namespace | `kubectl get all -n <namespace>` |
| Decode a secret | `kubectl get secret <n> -o jsonpath='{.data.key}' \| base64 --decode` |
| Switch context | `kubectl config use-context <name>` |
