## Create A New NameSpace
```bash
apiVersion: v1
kind: Namespace
metadata:
  name: new-namespace
```
#### Apply the configuration file to your active cluster
```bash
kubectl apply -f namespace.yaml
```
#### List all namespaces in the cluster
```bash
kubectl get namespaces
```
#### Switch your current active terminal context permanently
```bash
kubectl config set-context --current --namespace=my-namespace
```
---

# Kubernetes Resource Reference

A reference of common Kubernetes object types, each shown with its frequently-used configuration options as commented YAML.

> Not meant to be applied all at once — pick and adapt the objects relevant to your setup. Some reference each other (e.g. `demo-secret`, `data-pvc`).

---

## Table of Contents

1. [Namespace](#namespace)
2. [Pod](#pod)
3. [Deployment](#deployment)
4. [StatefulSet](#statefulset)
5. [DaemonSet](#daemonset)
6. [Job](#job)
7. [CronJob](#cronjob)
8. [Service](#service)
9. [Ingress](#ingress)
10. [ConfigMap](#configmap)
11. [Secret](#secret)
12. [StorageClass & PersistentVolumeClaim](#storageclass--persistentvolumeclaim)
13. [HorizontalPodAutoscaler](#horizontalpodautoscaler)
14. [PodDisruptionBudget](#poddisruptionbudget)
15. [NetworkPolicy](#networkpolicy)
16. [RBAC (ServiceAccount / Role / ClusterRole)](#rbac)
17. [ResourceQuota & LimitRange](#resourcequota--limitrange)

---

## Namespace

Logical partition of a cluster — isolates resources between teams/environments.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: demo
  labels:
    environment: dev
    team: platform
```

---

## Pod

Smallest deployable unit. Shows scheduling controls, env injection, probes, and security context.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: demo-pod
  namespace: demo
  labels:
    app: demo
spec:
  restartPolicy: Always          # Always | OnFailure | Never
  terminationGracePeriodSeconds: 30
  nodeSelector:
    disktype: ssd
  tolerations:
    - key: "dedicated"
      operator: "Equal"
      value: "gpu"
      effect: "NoSchedule"       # NoSchedule | PreferNoSchedule | NoExecute
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: kubernetes.io/os
                operator: In
                values: ["linux"]
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            labelSelector:
              matchLabels: {app: demo}
            topologyKey: kubernetes.io/hostname
  containers:
    - name: app
      image: nginx:1.27
      imagePullPolicy: IfNotPresent   # Always | IfNotPresent | Never
      ports:
        - containerPort: 80
      env:
        - name: ENVIRONMENT
          value: "production"
        - name: SECRET_TOKEN
          valueFrom:
            secretKeyRef:
              name: demo-secret
              key: token
        - name: CONFIG_VALUE
          valueFrom:
            configMapKeyRef:
              name: demo-config
              key: app.mode
      resources:
        requests: {cpu: "100m", memory: "128Mi"}
        limits: {cpu: "500m", memory: "256Mi"}
      volumeMounts:
        - name: data
          mountPath: /data
        - name: config-vol
          mountPath: /etc/config
          readOnly: true
      livenessProbe:
        httpGet: {path: /healthz, port: 80}
        initialDelaySeconds: 10
        periodSeconds: 10
        failureThreshold: 3
      readinessProbe:
        tcpSocket: {port: 80}
        initialDelaySeconds: 5
        periodSeconds: 5
      startupProbe:
        exec:
          command: ["cat", "/tmp/ready"]
        failureThreshold: 30
        periodSeconds: 2
      lifecycle:
        preStop:
          exec:
            command: ["sh", "-c", "sleep 5"]
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        capabilities:
          drop: ["ALL"]
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: data-pvc
    - name: config-vol
      configMap:
        name: demo-config
  imagePullSecrets:
    - name: registry-credentials
```

| Field | Options |
|---|---|
| `restartPolicy` | `Always`, `OnFailure`, `Never` |
| `imagePullPolicy` | `Always`, `IfNotPresent`, `Never` |
| `toleration.effect` | `NoSchedule`, `PreferNoSchedule`, `NoExecute` |
| Probe types | `httpGet`, `tcpSocket`, `exec`, `grpc` |

---

## Deployment

Manages stateless apps via a ReplicaSet, with rolling updates.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-deployment
  namespace: demo
spec:
  replicas: 3
  revisionHistoryLimit: 5
  strategy:
    type: RollingUpdate            # RollingUpdate | Recreate
    rollingUpdate:
      maxSurge: 1                  # extra pods allowed during update
      maxUnavailable: 0            # pods that can be down during update
  selector:
    matchLabels:
      app: demo
  template:
    metadata:
      labels:
        app: demo
    spec:
      containers:
        - name: app
          image: myregistry/demo:1.4.0
          ports:
            - containerPort: 8080
```

---

## StatefulSet

For stateful apps needing stable network identity and per-replica persistent storage.

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: demo-statefulset
  namespace: demo
spec:
  serviceName: demo-headless        # must match a headless Service
  replicas: 3
  podManagementPolicy: OrderedReady # OrderedReady | Parallel
  updateStrategy:
    type: RollingUpdate             # RollingUpdate | OnDelete
  selector:
    matchLabels:
      app: demo-db
  template:
    metadata:
      labels:
        app: demo-db
    spec:
      containers:
        - name: db
          image: postgres:16
          ports:
            - containerPort: 5432
          volumeMounts:
            - name: pgdata
              mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:              # one PVC created per replica
    - metadata:
        name: pgdata
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: fast-ssd
        resources:
          requests:
            storage: 10Gi
```

---

## DaemonSet

Ensures a copy of a Pod runs on every (or selected) node — e.g. log collectors, CNI agents.

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: demo-agent
  namespace: demo
spec:
  selector:
    matchLabels:
      app: node-agent
  updateStrategy:
    type: RollingUpdate             # RollingUpdate | OnDelete
    rollingUpdate:
      maxUnavailable: 1
  template:
    metadata:
      labels:
        app: node-agent
    spec:
      tolerations:
        - operator: "Exists"        # run even on tainted nodes (e.g. control-plane)
      containers:
        - name: agent
          image: fluent/fluent-bit:3.0
          resources:
            requests: {cpu: "50m", memory: "64Mi"}
```

---

## Job

Run-to-completion batch task.

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: demo-job
  namespace: demo
spec:
  completions: 5                    # total successful completions needed
  parallelism: 2                    # how many run concurrently
  backoffLimit: 4                   # retries before marking failed
  activeDeadlineSeconds: 300
  ttlSecondsAfterFinished: 3600     # auto-cleanup after completion
  template:
    spec:
      restartPolicy: OnFailure      # OnFailure | Never (no Always for Jobs)
      containers:
        - name: worker
          image: myregistry/batch-worker:2.0
          args: ["--task=process"]
```

---

## CronJob

Scheduled Job, using standard cron syntax.

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: demo-cronjob
  namespace: demo
spec:
  schedule: "0 2 * * *"             # 2 AM daily
  concurrencyPolicy: Forbid         # Allow | Forbid | Replace
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  suspend: false
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
            - name: backup
              image: myregistry/backup-tool:1.0
```

---

## Service

Four common types, shown separately.

```yaml
# ClusterIP — default, internal-only virtual IP
apiVersion: v1
kind: Service
metadata:
  name: demo-clusterip
  namespace: demo
spec:
  type: ClusterIP
  selector:
    app: demo
  ports:
    - name: http
      port: 80
      targetPort: 8080
      protocol: TCP
---
# NodePort — exposes a static port on every node
apiVersion: v1
kind: Service
metadata:
  name: demo-nodeport
  namespace: demo
spec:
  type: NodePort
  selector:
    app: demo
  ports:
    - port: 80
      targetPort: 8080
      nodePort: 30080              # optional: 30000-32767 range
---
# LoadBalancer — provisions an external cloud load balancer
apiVersion: v1
kind: Service
metadata:
  name: demo-loadbalancer
  namespace: demo
spec:
  type: LoadBalancer
  selector:
    app: demo
  ports:
    - port: 443
      targetPort: 8443
  externalTrafficPolicy: Local     # Local (preserve client IP) | Cluster
---
# Headless — used by StatefulSets, returns Pod IPs directly (no VIP)
apiVersion: v1
kind: Service
metadata:
  name: demo-headless
  namespace: demo
spec:
  clusterIP: None
  selector:
    app: demo-db
  ports:
    - port: 5432
```

---

## Ingress

L7 HTTP/HTTPS routing with TLS termination.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-ingress
  namespace: demo
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  tls:
    - hosts: ["demo.example.com"]
      secretName: demo-tls
  rules:
    - host: demo.example.com
      http:
        paths:
          - path: /
            pathType: Prefix       # Prefix | Exact | ImplementationSpecific
            backend:
              service:
                name: demo-clusterip
                port:
                  number: 80
```

---

## ConfigMap

Non-sensitive configuration, injected as env vars or mounted files.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: demo-config
  namespace: demo
data:
  app.mode: "production"
  app.properties: |
    max_connections=100
    timeout=30s
```

---

## Secret

Two common types: generic key-value, and Docker registry credentials.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: demo-secret
  namespace: demo
type: Opaque                        # generic key-value secret
data:
  token: c3VwZXItc2VjcmV0LXRva2Vu   # base64-encoded value
---
apiVersion: v1
kind: Secret
metadata:
  name: registry-credentials
  namespace: demo
type: kubernetes.io/dockerconfigjson  # for imagePullSecrets
data:
  .dockerconfigjson: eyJhdXRocyI6IHt9fQ==
```

---

## StorageClass & PersistentVolumeClaim

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
reclaimPolicy: Delete               # Delete | Retain
volumeBindingMode: WaitForFirstConsumer  # Immediate | WaitForFirstConsumer
allowVolumeExpansion: true
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
  namespace: demo
spec:
  accessModes: ["ReadWriteOnce"]    # ReadWriteOnce | ReadOnlyMany | ReadWriteMany | ReadWriteOncePod
  storageClassName: fast-ssd
  resources:
    requests:
      storage: 20Gi
```

---

## HorizontalPodAutoscaler

Scales replica count based on CPU/memory/custom metrics.

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: demo-hpa
  namespace: demo
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: demo-deployment
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target: {type: Utilization, averageUtilization: 70}
    - type: Resource
      resource:
        name: memory
        target: {type: Utilization, averageUtilization: 80}
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
    scaleUp:
      stabilizationWindowSeconds: 0
```

---

## PodDisruptionBudget

Limits voluntary disruptions (e.g. node drains) during maintenance.

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: demo-pdb
  namespace: demo
spec:
  minAvailable: 2                   # or use maxUnavailable instead
  selector:
    matchLabels:
      app: demo
```

---

## NetworkPolicy

Pod-to-Pod firewall rules, enforced by a policy-aware CNI plugin.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: demo-netpol
  namespace: demo
spec:
  podSelector:
    matchLabels:
      app: demo-db
  policyTypes: ["Ingress", "Egress"]
  ingress:
    - from:
        - podSelector:
            matchLabels: {app: demo}
        - namespaceSelector:
            matchLabels: {environment: dev}
      ports:
        - protocol: TCP
          port: 5432
  egress:
    - to:
        - ipBlock:
            cidr: 0.0.0.0/0
            except: ["169.254.169.254/32"]
      ports:
        - protocol: TCP
          port: 443
```

---

## RBAC

`ServiceAccount` + namespace-scoped `Role`/`RoleBinding` + cluster-scoped `ClusterRole`/`ClusterRoleBinding`.

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: demo-sa
  namespace: demo
automountServiceAccountToken: true
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: demo
rules:
  - apiGroups: [""]
    resources: ["pods", "pods/log"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: demo-sa-pod-reader
  namespace: demo
subjects:
  - kind: ServiceAccount
    name: demo-sa
    namespace: demo
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: node-viewer
rules:
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: demo-sa-node-viewer
subjects:
  - kind: ServiceAccount
    name: demo-sa
    namespace: demo
roleRef:
  kind: ClusterRole
  name: node-viewer
  apiGroup: rbac.authorization.k8s.io
```

> RBAC is **additive only** — there's no explicit "deny" rule; access is the union of all matching bindings.

---

## ResourceQuota & LimitRange

Namespace-level governance over resource consumption.

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: demo-quota
  namespace: demo
spec:
  hard:
    pods: "20"
    requests.cpu: "10"
    requests.memory: 20Gi
    limits.cpu: "20"
    limits.memory: 40Gi
    persistentvolumeclaims: "10"
---
apiVersion: v1
kind: LimitRange
metadata:
  name: demo-limits
  namespace: demo
spec:
  limits:
    - type: Container
      default: {cpu: "500m", memory: "256Mi"}
      defaultRequest: {cpu: "100m", memory: "128Mi"}
      max: {cpu: "2", memory: "2Gi"}
      min: {cpu: "50m", memory: "64Mi"}
```

