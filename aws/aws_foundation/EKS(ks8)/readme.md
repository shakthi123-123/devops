# Creating an EKS Cluster in AWS — Complete Step-by-Step Guide

Amazon EKS (Elastic Kubernetes Service) runs upstream, certified Kubernetes with AWS managing the control plane. This guide covers cluster creation, node groups (managed and Fargate), deploying a workload, exposing it via a load balancer, and IAM integration for pods.

---

## Architecture Overview

```
                    kubectl / CI-CD
                          │
              ┌──────────────────────┐
              │   EKS Control Plane    │  (AWS-managed, Multi-AZ)
              └───────────┬──────────┘
                          │
        ┌──────────────────┴───────────────────┐
        │              VPC (10.0.0.0/16)         │
        │                                        │
        │   Private Subnet A       Private Subnet B│
        │   ┌────────────┐         ┌────────────┐ │
        │   │ Managed Node│         │ Managed Node│ │
        │   │ Group        │         │ Group        │ │
        │   │ (EC2 workers)│         │ (EC2 workers)│ │
        │   │  Pod  Pod    │         │  Pod  Pod    │ │
        │   └────────────┘         └────────────┘ │
        │                                        │
        │   Public Subnets → ALB (via Ingress)      │
        └───────────────────────────────────────┘
```

---

## Prerequisites

- Active AWS account
- IAM user/role with `AmazonEKSClusterPolicy`-adjacent admin permissions for setup
- An existing VPC with public and private subnets across 2+ AZs, tagged appropriately for EKS/ELB discovery (see companion *AWS VPC Creation Guide*)
- Local tools installed: **AWS CLI**, **kubectl**, and **eksctl** (the recommended CLI for EKS; the console supports cluster creation too, but eksctl simplifies networking/IAM wiring)

```bash
# Verify tools
aws --version
kubectl version --client
eksctl version
```

### EKS Compute Options

| Option | Management | Best For |
|---|---|---|
| **Managed Node Groups** | AWS manages EC2 lifecycle, you choose instance types | Most general workloads |
| **Fargate Profiles** | Fully serverless, no EC2 to manage | Bursty/unpredictable workloads, simpler ops |
| **Self-managed nodes** | You manage the EC2 Auto Scaling group and AMI | Maximum customization (rare need today) |

This guide covers **Managed Node Groups** (most common) with a note on Fargate profiles.

---

## Step 1: Sign In and Select Region

1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in with IAM credentials
3. Select your target **region** (e.g., `Asia Pacific (Mumbai) ap-south-1`)
4. Configure the AWS CLI locally if not already done: `aws configure`

---

## Step 2: Tag Your VPC Subnets for EKS/ELB Discovery

Kubernetes' AWS Load Balancer Controller auto-discovers subnets using tags.

1. **VPC Console** → **Subnets** → select each **public** subnet → **Tags** → **Add tag**:
   ```
   kubernetes.io/role/elb = 1
   ```
2. Select each **private** subnet → add tag:
   ```
   kubernetes.io/role/internal-elb = 1
   ```
3. Add to **all** subnets used by the cluster (public + private):
   ```
   kubernetes.io/cluster/<cluster-name> = shared
   ```
   (this exact tag is also auto-added by eksctl when it creates the cluster, so manual tagging is mainly needed if reusing an existing VPC)

---

## Step 3: Create the Cluster with eksctl (Recommended)

1. Create a cluster config file `cluster.yaml`:
   ```yaml
   apiVersion: eksctl.io/v1alpha5
   kind: ClusterConfig

   metadata:
     name: orders-cluster
     region: ap-south-1
     version: "1.31"

   vpc:
     id: vpc-0123456789abcdef0
     subnets:
       private:
         ap-south-1a: { id: subnet-0111111111111111 }
         ap-south-1b: { id: subnet-0222222222222222 }
       public:
         ap-south-1a: { id: subnet-0333333333333333 }
         ap-south-1b: { id: subnet-0444444444444444 }

   iam:
     withOIDC: true

   managedNodeGroups:
     - name: default-ng
       instanceType: t3.medium
       minSize: 2
       desiredCapacity: 2
       maxSize: 5
       privateNetworking: true
       volumeSize: 20
       ssh:
         allow: false
   ```
2. Create the cluster:
   ```bash
   eksctl create cluster -f cluster.yaml
   ```
3. This takes **15–20 minutes** — eksctl provisions the control plane, node group Auto Scaling group, and configures `kubectl` access automatically
4. Confirm `kubectl` is configured:
   ```bash
   kubectl get nodes
   ```
   You should see your worker nodes in `Ready` state

### Alternative: Create via Console

1. **EKS Console** → **Clusters** → **Add cluster** → **Create**
2. Configure cluster name, Kubernetes version, and the **cluster IAM role** (create one first in IAM with `AmazonEKSClusterPolicy` attached)
3. **Networking**: select your VPC and subnets
4. **Cluster endpoint access**: **Public and private** (recommended default) or **Private only** for stricter environments
5. Click **Create** — then create a **Node group** separately under the cluster's **Compute** tab (requires a node IAM role with `AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, and `AmazonEC2ContainerRegistryReadOnly`)

> **Note:** `eksctl` handles all the above IAM role creation and wiring automatically — it's significantly less manual work than the console path.

---

## Step 4: Verify OIDC Provider (For IAM Roles for Service Accounts)

`withOIDC: true` in Step 3 already enabled this. Confirm:
```bash
eksctl utils associate-iam-oidc-provider --cluster orders-cluster --approve
```

This allows Kubernetes ServiceAccounts to assume IAM roles (IRSA — IAM Roles for Service Accounts), avoiding broad node-level IAM permissions.

---

## Step 5: Install the AWS Load Balancer Controller

Required to expose services via ALB/NLB using Kubernetes Ingress/Service resources.

1. Create an IAM policy for the controller:
   ```bash
   curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.9.0/docs/install/iam_policy.json
   aws iam create-policy \
     --policy-name AWSLoadBalancerControllerIAMPolicy \
     --policy-document file://iam_policy.json
   ```
2. Create an IRSA service account bound to this policy:
   ```bash
   eksctl create iamserviceaccount \
     --cluster=orders-cluster \
     --namespace=kube-system \
     --name=aws-load-balancer-controller \
     --attach-policy-arn=arn:aws:iam::123456789012:policy/AWSLoadBalancerControllerIAMPolicy \
     --override-existing-serviceaccounts \
     --approve
   ```
3. Install the controller via Helm:
   ```bash
   helm repo add eks https://aws.github.io/eks-charts
   helm repo update
   helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
     -n kube-system \
     --set clusterName=orders-cluster \
     --set serviceAccount.create=false \
     --set serviceAccount.name=aws-load-balancer-controller
   ```
4. Verify:
   ```bash
   kubectl get deployment -n kube-system aws-load-balancer-controller
   ```

---

## Step 6: Deploy a Sample Application

1. Create `deployment.yaml`:
   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: orders-app
   spec:
     replicas: 3
     selector:
       matchLabels:
         app: orders-app
     template:
       metadata:
         labels:
           app: orders-app
       spec:
         containers:
           - name: orders-app
             image: 123456789012.dkr.ecr.ap-south-1.amazonaws.com/orders-app:v1
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
2. Apply it:
   ```bash
   kubectl apply -f deployment.yaml
   kubectl get pods
   ```
3. Confirm pods reach `Running` state

---

## Step 7: Expose the Application with a Service and Ingress

1. Create `service.yaml`:
   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: orders-app-service
   spec:
     selector:
       app: orders-app
     ports:
       - port: 80
         targetPort: 3000
     type: ClusterIP
   ```
2. Create `ingress.yaml`:
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: orders-app-ingress
     annotations:
       alb.ingress.kubernetes.io/scheme: internet-facing
       alb.ingress.kubernetes.io/target-type: ip
       alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
   spec:
     ingressClassName: alb
     rules:
       - http:
           paths:
             - path: /
               pathType: Prefix
               backend:
                 service:
                   name: orders-app-service
                   port:
                     number: 80
   ```
3. Apply both:
   ```bash
   kubectl apply -f service.yaml
   kubectl apply -f ingress.yaml
   ```
4. The AWS Load Balancer Controller automatically provisions an ALB. Get its address:
   ```bash
   kubectl get ingress orders-app-ingress
   ```
5. Test:
   ```bash
   curl http://<ALB-DNS-NAME-from-above>
   ```

---

## Step 8: Grant Pod-Level IAM Permissions with IRSA

Instead of giving broad permissions to worker nodes, scope IAM access to individual pods via ServiceAccounts.

1. Create an IAM policy scoped to what the app needs (e.g., S3 read access — see companion *AWS S3 Creation Guide*, Step 5, for policy JSON)
2. Create the IRSA service account:
   ```bash
   eksctl create iamserviceaccount \
     --cluster=orders-cluster \
     --namespace=default \
     --name=orders-app-sa \
     --attach-policy-arn=arn:aws:iam::123456789012:policy/S3ReadOnly-MyAppBucket \
     --approve
   ```
3. Reference this ServiceAccount in the pod spec:
   ```yaml
   spec:
     serviceAccountName: orders-app-sa
     containers:
       - name: orders-app
         image: ...
   ```
4. Apply the updated deployment — pods now assume the IAM role transparently via the injected OIDC token, with no static credentials

---

## Step 9: Set Up Cluster Autoscaler / Karpenter

Automatically scale worker nodes based on pending pod demand.

### Option A: Cluster Autoscaler (traditional, works with managed node groups)

```bash
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm install cluster-autoscaler autoscaler/cluster-autoscaler \
  -n kube-system \
  --set autoDiscovery.clusterName=orders-cluster \
  --set awsRegion=ap-south-1
```

### Option B: Karpenter (newer, faster, more flexible bin-packing)

Recommended for new clusters — provisions right-sized nodes on demand rather than scaling pre-defined node groups. Installation involves creating a `NodePool` and `EC2NodeClass` custom resource; see the official Karpenter documentation for the current Helm chart and CRDs.

---

## Step 10: Add a Fargate Profile (Optional, for Serverless Pods)

Run specific namespaces/workloads without managing any EC2 nodes.

```bash
eksctl create fargateprofile \
  --cluster orders-cluster \
  --name fp-default \
  --namespace batch-jobs
```

Any pod scheduled into the `batch-jobs` namespace now runs on Fargate automatically — no node group capacity required.

---

## Step 11: Monitor with CloudWatch Container Insights

1. Enable Container Insights:
   ```bash
   aws eks update-cluster-config \
     --region ap-south-1 \
     --name orders-cluster \
     --logging '{"clusterLogging":[{"types":["api","audit","authenticator","controllerManager","scheduler"],"enabled":true}]}'
   ```
2. Install the CloudWatch agent + Fluent Bit for Container Insights via the official manifest (see AWS documentation for the current YAML for your cluster's OIDC provider)
3. **CloudWatch Console** → **Container Insights** → view cluster/pod/node CPU, memory, and network metrics
4. Set alarms on `pod_cpu_utilization`, `pod_memory_utilization`, or `cluster_failed_node_count`

---

## Step 12: Verification Checklist

- [ ] Cluster created and `kubectl get nodes` shows all nodes `Ready`
- [ ] OIDC provider associated for IRSA support
- [ ] AWS Load Balancer Controller installed and running
- [ ] Sample application deployed with resource requests/limits set (avoids noisy-neighbor issues)
- [ ] Ingress successfully provisions an ALB and serves traffic
- [ ] Pods use IRSA-scoped ServiceAccounts instead of broad node IAM permissions
- [ ] Cluster Autoscaler or Karpenter configured for dynamic scaling
- [ ] Container Insights enabled for observability
- [ ] Control plane logging enabled (api, audit, authenticator) for security auditing

---

## Cleanup (To Avoid Ongoing Charges)

1. Delete Kubernetes-created AWS resources first (ALBs are provisioned outside eksctl's awareness):
   ```bash
   kubectl delete ingress orders-app-ingress
   kubectl delete service orders-app-service
   kubectl delete deployment orders-app
   ```
2. Delete the cluster (this also removes the managed node group and control plane):
   ```bash
   eksctl delete cluster --name orders-cluster
   ```
3. Delete any Fargate profiles first if `eksctl delete cluster` doesn't remove them automatically:
   ```bash
   eksctl delete fargateprofile --cluster orders-cluster --name fp-default
   ```
4. Delete the IAM policies created for the Load Balancer Controller and IRSA roles if unused elsewhere
5. Remove subnet tags added in Step 2 if the VPC is being reused for non-EKS purposes

> EKS charges a flat hourly fee for the control plane **plus** the cost of worker node EC2 instances (or Fargate pod-seconds) — both continue billing until deleted, even with zero deployed workloads.

---

## Quick Reference Summary

| Component | Purpose |
|---|---|
| Control Plane | AWS-managed Kubernetes API server, etcd, scheduler (multi-AZ) |
| Node Group | EC2 instances (managed or self-managed) running your pods |
| Fargate Profile | Serverless pod execution, no EC2 to manage |
| OIDC Provider | Enables IRSA — fine-grained IAM permissions per pod |
| AWS Load Balancer Controller | Provisions ALB/NLB from Kubernetes Ingress/Service resources |
| Cluster Autoscaler / Karpenter | Automatically scales worker capacity based on pod demand |
| Container Insights | CloudWatch-based cluster/pod/node monitoring |

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| `kubectl` times out / unauthorized | Kubeconfig not updated, or IAM identity lacks cluster access | Run `aws eks update-kubeconfig --name orders-cluster --region ap-south-1`; verify IAM identity mapping in `aws-auth` ConfigMap |
| Pods stuck in `Pending` | Insufficient node capacity, or resource requests too high | Check `kubectl describe pod`; scale node group or reduce requests |
| Ingress created but no ALB provisioned | Load Balancer Controller not installed, or subnets missing required tags | Verify controller pods are running; confirm subnet tags from Step 2 |
| `ImagePullBackOff` | Wrong image URI, or node IAM role lacks ECR pull permission | Verify image URI; confirm node role has `AmazonEC2ContainerRegistryReadOnly` |
| IRSA pod still using node role instead of intended IAM role | ServiceAccount not annotated correctly, or pod spec missing `serviceAccountName` | Verify `eksctl create iamserviceaccount` completed; confirm pod spec references the correct ServiceAccount |

---

## Next Steps / Advanced Topics

- **GitOps with ArgoCD/Flux** — declarative, Git-driven continuous deployment into the cluster
- **Service Mesh (App Mesh / Istio)** — traffic management, mTLS, and observability between microservices
- **EKS Anywhere / Hybrid Nodes** — run EKS-consistent clusters on-premises or at the edge
- **Pod Security Standards** — enforce security baselines (restricted, baseline) across namespaces
- **Infrastructure as Code** — manage clusters and node groups via Terraform (`eks` module) or `eksctl` config files checked into version control
