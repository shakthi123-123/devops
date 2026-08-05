# Kubernetes Resource Examples

## Table of Contents
1. [Namespace](#1-namespace)
2. [PersistentVolume](#2-persistentvolume)
3. [PersistentVolumeClaim](#3-persistentvolumeclaim)
4. [Deployment (Volumes & Ports)](#4-deployment-volumes--ports)
5. [Service (Ports)](#5-service-ports)
6. [ConfigMap](#6-configmap)
7. [Secret](#7-secret)
8. [Ingress](#8-ingress)
9. [NetworkPolicy](#9-networkpolicy)
10. [ResourceQuota](#10-resourcequota)
11. [LimitRange](#11-limitrange)
12. [ServiceAccount, Role & RoleBinding](#12-serviceaccount-role--rolebinding)
13. [HorizontalPodAutoscaler (HPA)](#13-horizontalpodautoscaler-hpa)
14. [StatefulSet](#14-statefulset)
15. [DaemonSet](#15-daemonset)
16. [Job](#16-job)
17. [CronJob](#17-cronjob)

---

## 1. Namespace

Creates an isolated logical partition within the cluster.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: my-app-namespace
  labels:
    env: dev
    team: platform
```

---

## 2. PersistentVolume

Represents an actual piece of storage in the cluster (provisioned by admin or dynamically).

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-app-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
  hostPath:                     # use hostPath only for local/dev testing
    path: /data/my-app-pv
```

---

## 3. PersistentVolumeClaim

A request for storage by a user/pod; binds to a matching PersistentVolume.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-pvc
  namespace: my-app-namespace
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: standard
```

---

## 4. Deployment (Volumes & Ports)

Manages a set of replica Pods, mounts the PVC as a volume, and exposes a container port.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app-deployment
  namespace: my-app-namespace
  labels:
    app: my-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
        - name: my-app-container
          image: nginx:latest
          ports:
            - containerPort: 80
              name: http
          volumeMounts:
            - name: app-storage
              mountPath: /usr/share/nginx/html
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "250m"
              memory: "256Mi"
      volumes:
        - name: app-storage
          persistentVolumeClaim:
            claimName: my-app-pvc
```

---

## 5. Service (Ports)

Exposes the Deployment's pods on a stable network endpoint, mapping service port -> container port.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app-service
  namespace: my-app-namespace
spec:
  type: ClusterIP        # other options: NodePort, LoadBalancer, ExternalName
  selector:
    app: my-app
  ports:
    - name: http
      protocol: TCP
      port: 80            # port the Service listens on
      targetPort: 80       # port on the container (matches containerPort above)
      # nodePort: 30080    # only used if type is NodePort (must be 30000-32767)
```

---

## 6. ConfigMap

Stores non-sensitive config data that can be mounted as env vars or files.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-app-config
  namespace: my-app-namespace
data:
  APP_ENV: "development"
  LOG_LEVEL: "debug"
  config.yaml: |
    server:
      port: 80
      timeout: 30s
```

---

## 7. Secret

Stores sensitive data (base64-encoded, NOT encrypted by default - use a vault/sealed-secrets for real secrets).

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-app-secret
  namespace: my-app-namespace
type: Opaque
data:
  # echo -n 'myusername' | base64
  DB_USERNAME: bXl1c2VybmFtZQ==
  # echo -n 'mypassword' | base64
  DB_PASSWORD: bXlwYXNzd29yZA==
```

---

## 8. Ingress

Routes external HTTP(S) traffic into Services based on host/path rules.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
  namespace: my-app-namespace
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - host: myapp.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-app-service
                port:
                  number: 80
  tls:
    - hosts:
        - myapp.example.com
      secretName: my-app-tls-secret
```

---

## 9. NetworkPolicy

Controls which pods/namespaces can send or receive traffic to/from this pod.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: my-app-network-policy
  namespace: my-app-namespace
spec:
  podSelector:
    matchLabels:
      app: my-app
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              role: frontend
      ports:
        - protocol: TCP
          port: 80
  egress:
    - to:
        - podSelector:
            matchLabels:
              role: database
      ports:
        - protocol: TCP
          port: 5432
```

---

## 10. ResourceQuota

Caps the total amount of CPU, memory, storage, or object count within a namespace.

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: my-app-quota
  namespace: my-app-namespace
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 4Gi
    limits.cpu: "8"
    limits.memory: 8Gi
    persistentvolumeclaims: "4"
    pods: "20"
```

---

## 11. LimitRange

Sets default, minimum, and maximum resource limits for pods/containers in a namespace.

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: my-app-limit-range
  namespace: my-app-namespace
spec:
  limits:
    - type: Container
      default:
        cpu: "250m"
        memory: "256Mi"
      defaultRequest:
        cpu: "100m"
        memory: "128Mi"
      max:
        cpu: "1"
        memory: "1Gi"
      min:
        cpu: "50m"
        memory: "64Mi"
```

---

## 12. ServiceAccount, Role & RoleBinding

Provides an identity for pods and grants scoped RBAC permissions within a namespace.

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app-sa
  namespace: my-app-namespace
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: my-app-role
  namespace: my-app-namespace
rules:
  - apiGroups: [""]
    resources: ["pods", "configmaps"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: my-app-role-binding
  namespace: my-app-namespace
subjects:
  - kind: ServiceAccount
    name: my-app-sa
    namespace: my-app-namespace
roleRef:
  kind: Role
  name: my-app-role
  apiGroup: rbac.authorization.k8s.io
```

---

## 13. HorizontalPodAutoscaler (HPA)

Automatically scales the number of pod replicas based on observed CPU/memory usage.

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: my-app-hpa
  namespace: my-app-namespace
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app-deployment
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
```

---

## 14. StatefulSet

Like a Deployment, but gives each pod a stable network identity and its own persistent storage — used for stateful apps (databases, queues).

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: my-app-statefulset
  namespace: my-app-namespace
spec:
  serviceName: my-app-headless-service
  replicas: 3
  selector:
    matchLabels:
      app: my-app-stateful
  template:
    metadata:
      labels:
        app: my-app-stateful
    spec:
      containers:
        - name: my-app-container
          image: postgres:16
          ports:
            - containerPort: 5432
              name: db
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
            storage: 10Gi
```

---

## 15. DaemonSet

Ensures one copy of a pod runs on every (or selected) node — commonly used for log collectors, monitoring agents, or networking components.

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: my-app-daemonset
  namespace: my-app-namespace
spec:
  selector:
    matchLabels:
      app: my-app-agent
  template:
    metadata:
      labels:
        app: my-app-agent
    spec:
      containers:
        - name: log-agent
          image: fluent/fluent-bit:latest
          resources:
            requests:
              cpu: "50m"
              memory: "64Mi"
          volumeMounts:
            - name: varlog
              mountPath: /var/log
      volumes:
        - name: varlog
          hostPath:
            path: /var/log
```

---

## 16. Job

Runs one or more pods to completion for a batch/one-off task, then stops.

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: my-app-job
  namespace: my-app-namespace
spec:
  completions: 1
  backoffLimit: 3
  template:
    spec:
      containers:
        - name: my-app-job-container
          image: my-app-migration:latest
          command: ["python", "run_migration.py"]
      restartPolicy: Never
```

---

## 17. CronJob

Runs a Job on a repeating schedule (like cron) — for backups, cleanup tasks, scheduled reports.

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: my-app-cronjob
  namespace: my-app-namespace
spec:
  schedule: "0 2 * * *"        # every day at 2:00 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: my-app-backup
              image: my-app-backup:latest
              command: ["/bin/sh", "-c", "backup.sh"]
          restartPolicy: OnFailure
```

---

## Apply Order

```bash
kubectl apply -f 01-namespace.yaml
kubectl apply -f 02-persistent-volume.yaml
kubectl apply -f 03-persistent-volume-claim.yaml
kubectl apply -f 04-resourcequota.yaml
kubectl apply -f 05-limitrange.yaml
kubectl apply -f 06-serviceaccount-rbac.yaml
kubectl apply -f 07-configmap.yaml
kubectl apply -f 08-secret.yaml
kubectl apply -f 09-deployment.yaml
kubectl apply -f 10-statefulset.yaml
kubectl apply -f 11-daemonset.yaml
kubectl apply -f 12-service.yaml
kubectl apply -f 13-ingress.yaml
kubectl apply -f 14-networkpolicy.yaml
kubectl apply -f 15-hpa.yaml
kubectl apply -f 16-job.yaml
kubectl apply -f 17-cronjob.yaml
```

> **Note on ordering:** Namespace must always go first. Quotas/limits/RBAC are good to set up early so nothing violates them. ConfigMaps/Secrets should exist before workloads that reference them. Everything else has few hard dependencies, but Services are commonly applied after the workloads they select.
