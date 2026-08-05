# Kubernetes — Complete Detailed Guide

A comprehensive reference covering Kubernetes architecture, core objects, YAML manifests, `kubectl` commands, networking, storage, scaling, and troubleshooting — from first cluster to production operations.

---

## Table of Contents

1. [Core Concepts & Architecture](#sec-1-core-concepts--architecture)
2. [Setting Up a Cluster](#sec-2-setting-up-a-cluster)
3. [kubectl Basics](#sec-3-kubectl-basics)
4. [Pods](#sec-4-pods)
5. [Deployments](#sec-5-deployments)
6. [Services](#sec-6-services)
7. [Namespaces](#sec-7-namespaces)
8. [ConfigMaps & Secrets](#sec-8-configmaps--secrets)
9. [Volumes & Persistent Storage](#sec-9-volumes--persistent-storage)
10. [Ingress](#sec-10-ingress)
11. [StatefulSets](#sec-11-statefulsets)
12. [DaemonSets](#sec-12-daemonsets)
13. [Jobs & CronJobs](#sec-13-jobs--cronjobs)
14. [Autoscaling](#sec-14-autoscaling)
15. [Health Checks (Probes)](#sec-15-health-checks-probes)
16. [Resource Requests & Limits](#sec-16-resource-requests--limits)
17. [RBAC (Role-Based Access Control)](#sec-17-rbac-role-based-access-control)
18. [Helm Package Manager](#sec-18-helm-package-manager)
19. [Monitoring & Logging](#sec-19-monitoring--logging)
20. [Troubleshooting](#sec-20-troubleshooting)
21. [Best Practices Checklist](#sec-21-best-practices-checklist)
22. [Quick Reference: kubectl Cheat Sheet](#sec-22-quick-reference-kubectl-cheat-sheet)
23. [Next Steps / Advanced Topics](#sec-23-next-steps--advanced-topics)

---

<a id="sec-1-core-concepts--architecture"></a>

## 1. Core Concepts & Architecture

```
                    Control Plane
     ┌─────────────────────────────────────┐
     │  API Server │ Scheduler │ Controller  │
     │            │            │  Manager     │
     │             etcd (cluster state)        │
     └─────────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
   Worker Node 1    Worker Node 2   Worker Node 3
   ┌──────────┐    ┌──────────┐    ┌──────────┐
   │  kubelet   │    │  kubelet   │    │  kubelet   │
   │ kube-proxy  │    │ kube-proxy  │    │ kube-proxy  │
   │  Pod  Pod   │    │  Pod  Pod   │    │  Pod  Pod   │
   └──────────┘    └──────────┘    └──────────┘
```

### Key Components

| Component | Role |
|---|---|
| **API Server** | Front door for all cluster operations — `kubectl` talks to this |
| **etcd** | Distributed key-value store holding all cluster state |
| **Scheduler** | Assigns new pods to nodes based on resource availability |
| **Controller Manager** | Runs control loops (ReplicaSet, Node, etc.) to reconcile desired vs. actual state |
| **kubelet** | Agent on each node ensuring containers described in pod specs are running |
| **kube-proxy** | Maintains network rules on nodes, enabling Service abstraction |
| **Container Runtime** | Actually runs containers (containerd, CRI-O) |

### Core Object Hierarchy

```
Deployment → ReplicaSet → Pod → Container(s)
StatefulSet → Pod (with stable identity)
DaemonSet → Pod (one per node)
Job/CronJob → Pod (run-to-completion)
```

---

<a id="sec-2-setting-up-a-cluster"></a>

## 2. Setting Up a Cluster

### Local Development Clusters

| Tool | Best For |
|---|---|
| **minikube** | Single-node local cluster, easy to start/stop |
| **kind** (Kubernetes in Docker) | Fast, lightweight, great for CI |
| **k3s** | Lightweight production-grade distribution, edge/IoT friendly |

Start a minikube cluster
```bash
minikube start --cpus=4 --memory=8192
```

Start a kind cluster
```bash
kind create cluster --name dev-cluster
```

### Managed Cloud Clusters

| Provider | Service |
|---|---|
| AWS | EKS (see companion *AWS EKS Creation Guide*) |
| Google Cloud | GKE |
| Azure | AKS |

### Verify Cluster Access

Check cluster info
```bash
kubectl cluster-info
```

List all nodes
```bash
kubectl get nodes -o wide
```

Check the current context
```bash
kubectl config current-context
```

List all available contexts
```bash
kubectl config get-contexts
```

Switch context
```bash
kubectl config use-context my-cluster
```

---

<a id="sec-3-kubectl-basics"></a>

## 3. kubectl Basics

### General Syntax

```
kubectl [command] [type] [name] [flags]
```

Get resources of a type
```bash
kubectl get pods
```

Get resources with more detail (wide output)
```bash
kubectl get pods -o wide
```

Get resources across all namespaces
```bash
kubectl get pods --all-namespaces
```

Get resources as raw YAML
```bash
kubectl get pod my-pod -o yaml
```

Describe a resource (detailed info + events)
```bash
kubectl describe pod my-pod
```

Apply a manifest file (create or update)
```bash
kubectl apply -f deployment.yaml
```

Apply all manifests in a directory
```bash
kubectl apply -f ./manifests/
```

Delete a resource defined in a file
```bash
kubectl delete -f deployment.yaml
```

Delete a resource by name
```bash
kubectl delete pod my-pod
```

Edit a resource live
```bash
kubectl edit deployment my-app
```

Watch resources for changes in real time
```bash
kubectl get pods --watch
```

View logs from a pod
```bash
kubectl logs my-pod
```

Follow logs in real time
```bash
kubectl logs -f my-pod
```

View logs from a specific container in a multi-container pod
```bash
kubectl logs my-pod -c my-container
```

Execute a command inside a running pod
```bash
kubectl exec -it my-pod -- /bin/bash
```

Copy files to/from a pod
```bash
kubectl cp my-pod:/app/logs.txt ./logs.txt
```

Port-forward a local port to a pod
```bash
kubectl port-forward pod/my-pod 8080:80
```

Port-forward to a service
```bash
kubectl port-forward svc/my-service 8080:80
```

Get the YAML/JSON explanation for a resource field
```bash
kubectl explain pod.spec.containers
```

---

<a id="sec-4-pods"></a>

## 4. Pods

The smallest deployable unit — one or more containers sharing network/storage.

### Basic Pod Manifest

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: orders-app-pod
  labels:
    app: orders-app
spec:
  containers:
    - name: orders-app
      image: myregistry/orders-app:v1
      ports:
        - containerPort: 3000
      env:
        - name: NODE_ENV
          value: "production"
```

Create the pod
```bash
kubectl apply -f pod.yaml
```

Get pod status
```bash
kubectl get pod orders-app-pod
```

### Multi-Container Pod (Sidecar Pattern)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-sidecar
spec:
  containers:
    - name: main-app
      image: myregistry/app:v1
      ports:
        - containerPort: 8080
    - name: log-shipper
      image: fluent/fluent-bit:latest
      volumeMounts:
        - name: shared-logs
          mountPath: /var/log/app
  volumes:
    - name: shared-logs
      emptyDir: {}
```

> **Note:** In production, pods are almost never created directly — they're managed by Deployments, StatefulSets, or Jobs, which handle restarts and scaling automatically.

---

<a id="sec-5-deployments"></a>

## 5. Deployments

Manages ReplicaSets and provides rolling updates, rollbacks, and self-healing.

### Deployment Manifest

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: orders-app
  labels:
    app: orders-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: orders-app
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: orders-app
    spec:
      containers:
        - name: orders-app
          image: myregistry/orders-app:v1
          ports:
            - containerPort: 3000
          resources:
            requests:
              cpu: "250m"
              memory: "256Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
```

Create/update the deployment
```bash
kubectl apply -f deployment.yaml
```

Check rollout status
```bash
kubectl rollout status deployment/orders-app
```

Scale the deployment manually
```bash
kubectl scale deployment orders-app --replicas=5
```

Update the image (triggers a rolling update)
```bash
kubectl set image deployment/orders-app orders-app=myregistry/orders-app:v2
```

View rollout history
```bash
kubectl rollout history deployment/orders-app
```

Roll back to the previous revision
```bash
kubectl rollout undo deployment/orders-app
```

Roll back to a specific revision
```bash
kubectl rollout undo deployment/orders-app --to-revision=2
```

Pause a rollout (to batch multiple changes)
```bash
kubectl rollout pause deployment/orders-app
```

Resume a paused rollout
```bash
kubectl rollout resume deployment/orders-app
```

### Deployment Strategies

| Strategy | Behavior |
|---|---|
| `RollingUpdate` (default) | Gradually replaces old pods with new ones, zero downtime |
| `Recreate` | Kills all old pods before creating new ones — brief downtime, useful when versions can't coexist |

---

<a id="sec-6-services"></a>

## 6. Services

Provides stable networking (a fixed name/IP) for a dynamic set of pods.

### ClusterIP (Internal Only — Default)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: orders-app-service
spec:
  type: ClusterIP
  selector:
    app: orders-app
  ports:
    - port: 80
      targetPort: 3000
```

### NodePort (Exposes on Each Node's IP)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: orders-app-nodeport
spec:
  type: NodePort
  selector:
    app: orders-app
  ports:
    - port: 80
      targetPort: 3000
      nodePort: 30080
```

### LoadBalancer (Cloud Provider Provisions an External LB)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: orders-app-lb
spec:
  type: LoadBalancer
  selector:
    app: orders-app
  ports:
    - port: 80
      targetPort: 3000
```

### Service Types Comparison

| Type | Accessible From | Use Case |
|---|---|---|
| `ClusterIP` | Inside the cluster only | Internal microservice communication |
| `NodePort` | External, via `<NodeIP>:<NodePort>` | Simple external access, dev/test |
| `LoadBalancer` | External, via cloud LB | Production external access (needs cloud integration) |
| `ExternalName` | Internal, maps to external DNS | Referencing an external service by internal name |

Get all services
```bash
kubectl get svc
```

Get the external IP of a LoadBalancer service
```bash
kubectl get svc orders-app-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Test a service from inside the cluster
```bash
kubectl run test-pod --image=busybox -it --rm -- wget -O- http://orders-app-service
```

---

<a id="sec-7-namespaces"></a>

## 7. Namespaces

Logical partitions within a cluster for isolating environments/teams.

Create a namespace
```bash
kubectl create namespace staging
```

List all namespaces
```bash
kubectl get namespaces
```

Get resources within a specific namespace
```bash
kubectl get pods -n staging
```

Set a default namespace for the current context
```bash
kubectl config set-context --current --namespace=staging
```

Delete a namespace (and everything in it)
```bash
kubectl delete namespace staging
```

### Namespace in a Manifest

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: staging
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: orders-app
  namespace: staging
spec:
  # ...
```

---

<a id="sec-8-configmaps--secrets"></a>

## 8. ConfigMaps & Secrets

### ConfigMap — Non-Sensitive Configuration

Create from literal values
```bash
kubectl create configmap app-config --from-literal=LOG_LEVEL=info --from-literal=API_TIMEOUT=30
```

Create from a file
```bash
kubectl create configmap app-config-file --from-file=config.properties
```

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  LOG_LEVEL: "info"
  API_TIMEOUT: "30"
```

### Secret — Sensitive Configuration (Base64-Encoded, Not Encrypted by Default)

Create from literal values
```bash
kubectl create secret generic db-credentials --from-literal=username=admin --from-literal=password=supersecret
```

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
type: Opaque
data:
  username: YWRtaW4=       # base64 encoded
  password: c3VwZXJzZWNyZXQ=
```

> **Security note:** Secrets are base64-encoded, not encrypted, by default. Enable **encryption at rest** for etcd, or use an external secrets manager (AWS Secrets Manager, HashiCorp Vault) with a Kubernetes integration like External Secrets Operator for production sensitive data.

### Consuming ConfigMaps/Secrets in a Pod

As environment variables:
```yaml
spec:
  containers:
    - name: orders-app
      envFrom:
        - configMapRef:
            name: app-config
        - secretRef:
            name: db-credentials
```

As mounted files:
```yaml
spec:
  containers:
    - name: orders-app
      volumeMounts:
        - name: config-volume
          mountPath: /etc/config
  volumes:
    - name: config-volume
      configMap:
        name: app-config
```

---

<a id="sec-9-volumes--persistent-storage"></a>

## 9. Volumes & Persistent Storage

### emptyDir (Ephemeral, Pod Lifetime Only)

```yaml
volumes:
  - name: cache-volume
    emptyDir: {}
```

### PersistentVolume (PV) and PersistentVolumeClaim (PVC)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: orders-data-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: gp3
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: orders-app
spec:
  template:
    spec:
      containers:
        - name: orders-app
          volumeMounts:
            - name: data
              mountPath: /app/data
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: orders-data-pvc
```

### Access Modes

| Mode | Meaning |
|---|---|
| `ReadWriteOnce` (RWO) | Mounted read-write by a single node |
| `ReadOnlyMany` (ROX) | Mounted read-only by many nodes |
| `ReadWriteMany` (RWX) | Mounted read-write by many nodes (needs NFS/EFS-backed storage) |

List persistent volume claims
```bash
kubectl get pvc
```

List persistent volumes
```bash
kubectl get pv
```

List available storage classes
```bash
kubectl get storageclass
```

---

<a id="sec-10-ingress"></a>

## 10. Ingress

Routes external HTTP(S) traffic to internal Services based on hostname/path — requires an Ingress Controller (e.g., NGINX, AWS Load Balancer Controller) to be installed in the cluster.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: orders-app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - host: orders.myapp.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: orders-app-service
                port:
                  number: 80
    - host: myapp.com
      http:
        paths:
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: api-service
                port:
                  number: 80
```

### TLS Termination

```yaml
spec:
  tls:
    - hosts:
        - orders.myapp.com
      secretName: orders-tls-cert
```

Get ingress resources and their addresses
```bash
kubectl get ingress
```

Describe an ingress for troubleshooting
```bash
kubectl describe ingress orders-app-ingress
```

---

<a id="sec-11-statefulsets"></a>

## 11. StatefulSets

For workloads needing stable network identity and persistent storage per replica (databases, message queues).

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres
  replicas: 3
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres
          image: postgres:16
          ports:
            - containerPort: 5432
          volumeMounts:
            - name: data
              mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 20Gi
```

### Key Differences from Deployment

| Feature | Deployment | StatefulSet |
|---|---|---|
| Pod naming | Random suffix | Predictable (`postgres-0`, `postgres-1`, ...) |
| Storage | Shared or none | Unique PVC per pod, retained across restarts |
| Scaling order | Any order, parallel | Sequential (0, 1, 2, ...) |
| Use case | Stateless web apps | Databases, Kafka, etcd |

---

<a id="sec-12-daemonsets"></a>

## 12. DaemonSets

Ensures exactly one pod runs on every (or selected) node — common for log collectors, monitoring agents, network plugins.

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: log-collector
spec:
  selector:
    matchLabels:
      app: log-collector
  template:
    metadata:
      labels:
        app: log-collector
    spec:
      containers:
        - name: fluent-bit
          image: fluent/fluent-bit:latest
          resources:
            limits:
              memory: 200Mi
```

Get all DaemonSets
```bash
kubectl get daemonset
```

---

<a id="sec-13-jobs--cronjobs"></a>

## 13. Jobs & CronJobs

### Job — Run to Completion

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: db-migration
spec:
  template:
    spec:
      containers:
        - name: migrate
          image: myregistry/orders-app:v1
          command: ["npm", "run", "migrate"]
      restartPolicy: OnFailure
  backoffLimit: 3
```

### CronJob — Scheduled Job

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: nightly-cleanup
spec:
  schedule: "0 2 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: cleanup
              image: myregistry/cleanup-tool:v1
          restartPolicy: OnFailure
```

Get all jobs
```bash
kubectl get jobs
```

Get all cronjobs
```bash
kubectl get cronjobs
```

Manually trigger a CronJob run
```bash
kubectl create job manual-run --from=cronjob/nightly-cleanup
```

---

<a id="sec-14-autoscaling"></a>

## 14. Autoscaling

### Horizontal Pod Autoscaler (HPA)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: orders-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: orders-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

Create an HPA via CLI
```bash
kubectl autoscale deployment orders-app --cpu-percent=70 --min=2 --max=10
```

Check HPA status
```bash
kubectl get hpa
```

> **Requires the Metrics Server** to be installed in the cluster for CPU/memory-based scaling.

### Vertical Pod Autoscaler (VPA)

Automatically adjusts CPU/memory **requests** for pods based on historical usage (separate add-on, not built-in).

### Cluster Autoscaler

Scales the number of **nodes** based on pending pod demand (cloud-provider specific — see companion *AWS EKS Creation Guide*, Step 9).

---

<a id="sec-15-health-checks-probes"></a>

## 15. Health Checks (Probes)

```yaml
spec:
  containers:
    - name: orders-app
      livenessProbe:
        httpGet:
          path: /healthz
          port: 3000
        initialDelaySeconds: 10
        periodSeconds: 15
        timeoutSeconds: 3
        failureThreshold: 3
      readinessProbe:
        httpGet:
          path: /ready
          port: 3000
        initialDelaySeconds: 5
        periodSeconds: 10
      startupProbe:
        httpGet:
          path: /healthz
          port: 3000
        failureThreshold: 30
        periodSeconds: 5
```

### Probe Types

| Probe | Purpose | Failure Consequence |
|---|---|---|
| `livenessProbe` | Is the container alive? | Kubernetes restarts the container |
| `readinessProbe` | Is the container ready for traffic? | Pod removed from Service endpoints (not restarted) |
| `startupProbe` | Has the app finished starting? | Delays liveness/readiness checks for slow-starting apps |

---

<a id="sec-16-resource-requests--limits"></a>

## 16. Resource Requests & Limits

```yaml
resources:
  requests:
    cpu: "250m"      # 0.25 vCPU — guaranteed
    memory: "256Mi"
  limits:
    cpu: "500m"       # 0.5 vCPU — hard cap
    memory: "512Mi"   # OOMKilled if exceeded
```

| Concept | Meaning |
|---|---|
| **Request** | Minimum guaranteed resources; used by the scheduler to place pods |
| **Limit** | Maximum allowed; CPU is throttled, memory over-limit triggers `OOMKilled` |

Always set both — no requests/limits means unpredictable scheduling and "noisy neighbor" risk; requests without limits risks one pod starving others.

---

<a id="sec-17-rbac-role-based-access-control"></a>

## 17. RBAC (Role-Based Access Control)

### Role (Namespace-Scoped) and RoleBinding

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: staging
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods-binding
  namespace: staging
subjects:
  - kind: User
    name: jane.doe
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### ClusterRole (Cluster-Wide) and ClusterRoleBinding

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: node-viewer
rules:
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: node-viewer-binding
subjects:
  - kind: Group
    name: sre-team
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: node-viewer
  apiGroup: rbac.authorization.k8s.io
```

Check if you can perform an action
```bash
kubectl auth can-i delete pods --namespace=staging
```

Check what a specific service account can do
```bash
kubectl auth can-i --list --as=system:serviceaccount:staging:orders-app-sa
```

---

<a id="sec-18-helm-package-manager"></a>

## 18. Helm Package Manager

Helm packages Kubernetes manifests into reusable, versioned **charts** with templating.

Add a chart repository
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
```

Update repository index
```bash
helm repo update
```

Search for a chart
```bash
helm search repo postgresql
```

Install a chart
```bash
helm install my-postgres bitnami/postgresql --set auth.password=secretpass
```

List installed releases
```bash
helm list
```

Upgrade a release
```bash
helm upgrade my-postgres bitnami/postgresql --set replicaCount=3
```

Roll back a release
```bash
helm rollback my-postgres 1
```

Uninstall a release
```bash
helm uninstall my-postgres
```

### Basic Chart Structure

```
my-chart/
├── Chart.yaml          # metadata
├── values.yaml          # default configuration values
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── _helpers.tpl
```

Create a new chart scaffold
```bash
helm create my-chart
```

Render templates locally without installing (dry run)
```bash
helm template my-chart ./my-chart
```

---

<a id="sec-19-monitoring--logging"></a>

## 19. Monitoring & Logging

### Built-In Resource Metrics (Requires Metrics Server)

Show resource usage per node
```bash
kubectl top nodes
```

Show resource usage per pod
```bash
kubectl top pods
```

### Common Observability Stack

| Tool | Purpose |
|---|---|
| **Prometheus** | Metrics collection and alerting |
| **Grafana** | Metrics visualization/dashboards |
| **Loki** or **EFK (Elasticsearch, Fluentd, Kibana)** | Log aggregation |
| **Jaeger** or **Tempo** | Distributed tracing |

Install Prometheus + Grafana via Helm (kube-prometheus-stack)
```bash
helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
```

---

<a id="sec-20-troubleshooting"></a>

## 20. Troubleshooting

Check pod status and recent events
```bash
kubectl describe pod my-pod
```

Get events sorted by time, cluster-wide
```bash
kubectl get events --sort-by='.lastTimestamp'
```

View logs of a crashed container (previous instance)
```bash
kubectl logs my-pod --previous
```

Check why a pod won't schedule
```bash
kubectl describe pod my-pod | grep -A 10 Events
```

Get all pods not in Running state
```bash
kubectl get pods --field-selector=status.phase!=Running
```

Debug with an ephemeral container (attach a debug shell to a running pod)
```bash
kubectl debug -it my-pod --image=busybox --target=my-container
```

Run a temporary debug pod
```bash
kubectl run debug-pod --image=busybox -it --rm -- sh
```

Check node conditions and capacity
```bash
kubectl describe node <node-name>
```

### Common Pod States and Causes

| State | Likely Cause |
|---|---|
| `Pending` | Insufficient cluster resources, unschedulable (taints/affinity), PVC not bound |
| `ImagePullBackOff` | Wrong image name/tag, missing registry credentials |
| `CrashLoopBackOff` | Application crashing on startup — check `kubectl logs --previous` |
| `OOMKilled` | Container exceeded its memory limit |
| `Evicted` | Node ran out of resources (disk/memory pressure) |

---

<a id="sec-21-best-practices-checklist"></a>

## 21. Best Practices Checklist

- [ ] Never deploy bare Pods in production — use Deployments/StatefulSets
- [ ] Always set resource `requests` and `limits`
- [ ] Configure liveness, readiness, and (for slow-starting apps) startup probes
- [ ] Use namespaces to separate environments (dev/staging/prod)
- [ ] Store secrets in a proper secrets manager, not plaintext ConfigMaps
- [ ] Apply RBAC with least-privilege roles — avoid `cluster-admin` for routine access
- [ ] Use `RollingUpdate` with `maxUnavailable: 0` for zero-downtime deploys
- [ ] Tag images with specific versions, never rely on `:latest` in production
- [ ] Set Pod Disruption Budgets for critical workloads to survive node maintenance
- [ ] Enable Horizontal Pod Autoscaler for variable-traffic workloads
- [ ] Run `kubectl apply --dry-run=client` before applying changes to production
- [ ] Version-control all manifests (GitOps with ArgoCD/Flux for larger teams)
- [ ] Regularly run `kubectl get events` and monitor `kubectl top` for early warning signs

---

<a id="sec-22-quick-reference-kubectl-cheat-sheet"></a>

## Quick Reference: kubectl Cheat Sheet

Get everything in the current namespace
```bash
kubectl get all
```

Get resources with labels shown
```bash
kubectl get pods --show-labels
```

Filter by label selector
```bash
kubectl get pods -l app=orders-app
```

Delete all pods matching a label
```bash
kubectl delete pods -l app=orders-app
```

Dry-run a manifest without applying it
```bash
kubectl apply -f deployment.yaml --dry-run=client -o yaml
```

Get the API resources available in the cluster
```bash
kubectl api-resources
```

Show cluster component statuses
```bash
kubectl get componentstatuses
```

Generate a Deployment manifest imperatively (then edit/save it)
```bash
kubectl create deployment orders-app --image=myregistry/orders-app:v1 --dry-run=client -o yaml > deployment.yaml
```

---

<a id="sec-23-next-steps--advanced-topics"></a>

## Next Steps / Advanced Topics

- **GitOps with ArgoCD or Flux** — declarative, Git-driven continuous deployment
- **Service Mesh (Istio, Linkerd)** — mTLS, traffic splitting, and observability between services
- **Network Policies** — fine-grained pod-to-pod traffic control (deny-by-default segmentation)
- **Custom Resource Definitions (CRDs) & Operators** — extend Kubernetes with domain-specific automation
- **Pod Security Standards** — enforce security baselines (restricted, baseline, privileged) per namespace
- **Kustomize** — template-free way to customize manifests per environment, built into `kubectl`
