# Creating an ECS Service in AWS — Complete Step-by-Step Guide

Amazon ECS (Elastic Container Service) runs and orchestrates Docker containers at scale. This guide covers building a container image, pushing it to ECR, and deploying it as a Fargate service (serverless containers — no EC2 management) behind a load balancer inside your VPC.

---

## Architecture Overview

```
                          Internet
                              │
                    Application Load Balancer
                       (public subnets)
                              │
                ┌─────────────────────────┐
                │        ECS Cluster        │
                │                           │
                │  Private Subnet A/B        │
                │  ┌─────────┐ ┌─────────┐  │
                │  │ Task 1   │ │ Task 2   │  │
                │  │ (Fargate)│ │ (Fargate)│  │
                │  │ Container│ │ Container│  │
                │  └─────────┘ └─────────┘  │
                │      ECS Service           │
                │   (desired count: 2)        │
                └─────────────────────────┘
                              │
                         Amazon ECR
                     (container image repo)
```

---

## Prerequisites

- Active AWS account
- IAM user/role with `AmazonECS_FullAccess` and `AmazonEC2ContainerRegistryFullAccess` (or scoped equivalents)
- An existing VPC with public and private subnets across 2+ AZs (see companion *AWS VPC Creation Guide*)
- Docker installed locally to build and push container images
- AWS CLI configured (`aws configure`)

### Fargate vs. EC2 Launch Type

| Feature | Fargate | EC2 |
|---|---|---|
| Server management | None — fully serverless | You manage the underlying EC2 instances |
| Billing | Per vCPU/memory per second while task runs | Per EC2 instance uptime, regardless of task usage |
| Best for | Most workloads, variable traffic, less ops overhead | Very high density, GPU workloads, deep host customization |

This guide uses **Fargate** (recommended default for most applications).

---

## Step 1: Sign In and Select Region

1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in with IAM credentials
3. Select your target **region** (e.g., `Asia Pacific (Mumbai) ap-south-1`)

---

## Step 2: Create an ECR Repository (Container Image Registry)

1. In the search bar, type `ECR` and select **Elastic Container Registry**
2. Click **Create repository**
3. Configure:
   - Visibility: **Private**
   - Repository name: `orders-app`
   - **Scan on push**: Enable (scans images for known vulnerabilities)
   - **Tag immutability**: Enable (prevents accidentally overwriting a deployed image tag)
4. Click **Create repository**
5. Note the **repository URI**, e.g.:
   ```
   123456789012.dkr.ecr.ap-south-1.amazonaws.com/orders-app
   ```

---

## Step 3: Build and Push the Container Image

1. Create a simple `Dockerfile` in your project, e.g. (Node.js example):
   ```dockerfile
   FROM node:20-alpine
   WORKDIR /app
   COPY package*.json ./
   RUN npm ci --production
   COPY . .
   EXPOSE 3000
   CMD ["node", "server.js"]
   ```
2. Authenticate Docker to ECR:
   ```bash
   aws ecr get-login-password --region ap-south-1 | \
     docker login --username AWS --password-stdin 123456789012.dkr.ecr.ap-south-1.amazonaws.com
   ```
3. Build the image:
   ```bash
   docker build -t orders-app .
   ```
4. Tag it for ECR:
   ```bash
   docker tag orders-app:latest 123456789012.dkr.ecr.ap-south-1.amazonaws.com/orders-app:v1
   ```
5. Push it:
   ```bash
   docker push 123456789012.dkr.ecr.ap-south-1.amazonaws.com/orders-app:v1
   ```
6. Confirm the image appears in the ECR console under **Repositories** → `orders-app` → **Images**

---

## Step 4: Create an ECS Cluster

1. In the search bar, type `ECS` and select **Elastic Container Service**
2. Left sidebar → **Clusters** → **Create cluster**
3. Configure:
   - Cluster name: `orders-cluster`
   - **Infrastructure**: check **AWS Fargate (serverless)**
   - (Leave EC2 Instances / External unchecked for a pure Fargate cluster)
4. Click **Create**

---

## Step 5: Create a Task Execution IAM Role

The task execution role lets ECS pull images from ECR and write logs to CloudWatch on your task's behalf (separate from the task role, which grants the *application* permissions).

1. **IAM Console** → **Roles** → **Create role**
2. Trusted entity: **AWS service** → Use case: **Elastic Container Service** → **Elastic Container Service Task**
3. Attach policy: `AmazonECSTaskExecutionRolePolicy`
4. Name: `ecsTaskExecutionRole`
5. Click **Create role**

   > If this is your first time creating a task definition in the console, AWS often offers to auto-create this role for you — either approach works.

---

## Step 6: Create a Task Definition

A task definition is the blueprint for your container(s) — image, CPU/memory, ports, environment variables, and logging.

1. Left sidebar → **Task definitions** → **Create new task definition**
2. **Task definition configuration**:

| Field | Value | Notes |
|---|---|---|
| Task definition family | `orders-app-task` | |
| Launch type | **AWS Fargate** | |
| Operating system/Architecture | Linux/X86_64 | Or ARM64 for Graviton (cheaper) |
| CPU | `0.5 vCPU` | Scale per workload |
| Memory | `1 GB` | Must pair with a valid CPU combination |
| Task role | (optional) select/create — grants the app permissions, e.g., S3/DynamoDB access | |
| Task execution role | `ecsTaskExecutionRole` (from Step 5) | |

3. **Container details**:
   - Name: `orders-app-container`
   - Image URI: `123456789012.dkr.ecr.ap-south-1.amazonaws.com/orders-app:v1`
   - Port mappings: Container port `3000`, protocol `TCP`, App protocol `HTTP`
4. **Environment variables** (if needed):
   - Key: `NODE_ENV`, Value: `production`
   - For secrets, use **ValueFrom** and reference a Secrets Manager ARN instead of plaintext
5. **Logging**:
   - Enable **Use log collection**
   - Log driver: `awslogs`
   - Log group: auto-creates `/ecs/orders-app-task`
6. Click **Create**

---

## Step 7: Set Up a Security Group for the Service

1. **VPC Console** → **Security Groups** → **Create security group**
2. Name: `ecs-service-sg`
3. VPC: your VPC
4. **Inbound rules**: allow traffic from the **ALB's security group** only (created next in Step 8), on container port `3000`
5. Click **Create security group**

---

## Step 8: Create an Application Load Balancer (ALB)

1. **EC2 Console** → **Load Balancers** → **Create load balancer** → **Application Load Balancer**
2. Configure:
   - Name: `orders-alb`
   - Scheme: **Internet-facing**
   - VPC: your VPC
   - Subnets: select your **public subnets** (2+ AZs)
   - Security group: create/select one allowing inbound `80`/`443` from `0.0.0.0/0`
3. **Listeners and routing**:
   - Listener: `HTTP:80`
   - Default action: **Create target group**
     - Target type: **IP addresses** (required for Fargate)
     - Name: `orders-tg`
     - Protocol/Port: `HTTP` / `3000`
     - Health check path: `/health` (or `/` if no dedicated endpoint)
4. Click **Create load balancer**
5. Update `ecs-service-sg` (Step 7) to allow inbound from the ALB's security group on port `3000`

---

## Step 9: Create the ECS Service

1. Go to **Clusters** → select `orders-cluster` → **Services** tab → **Create**
2. **Deployment configuration**:

| Field | Value | Notes |
|---|---|---|
| Application type | **Service** | |
| Task definition family | `orders-app-task` | Revision: latest |
| Service name | `orders-service` | |
| Desired tasks | `2` | Number of running container instances |

3. **Networking**:
   - VPC: your VPC
   - Subnets: select **private subnets** (tasks don't need public IPs when behind an ALB)
   - Security group: `ecs-service-sg` (from Step 7)
   - Public IP: **Off** (traffic enters via the ALB, not directly)

4. **Load balancing**:
   - Load balancer type: **Application Load Balancer**
   - Select existing load balancer: `orders-alb`
   - Container to load balance: `orders-app-container:3000`
   - Target group: select the existing `orders-tg` (from Step 8), or let ECS create a new one

5. **Service auto scaling** (optional, recommended for production):
   - Enable **Service auto scaling**
   - Minimum tasks: `2`, Maximum tasks: `10`
   - Scaling policy: **Target tracking**
     - Metric: `ECSServiceAverageCPUUtilization`
     - Target value: `60%`

6. Click **Create**
7. Wait for the service status to show **Active** and tasks to reach **Running** state (can take a few minutes for Fargate to provision)

---

## Step 10: Verify the Deployment

1. **EC2 Console** → **Load Balancers** → select `orders-alb` → copy the **DNS name**
2. Test in browser or via curl:
   ```bash
   curl http://orders-alb-1234567890.ap-south-1.elb.amazonaws.com
   ```
3. Confirm the target group shows **healthy** targets: **Target Groups** → `orders-tg` → **Targets** tab
4. If unhealthy, check container logs (Step 11) and confirm the health check path returns a `200` response

---

## Step 11: View Logs and Monitor

1. **CloudWatch Console** → **Log groups** → `/ecs/orders-app-task`
2. Select a log stream (one per running task) to view application output
3. **ECS Console** → cluster → **Metrics** tab, or **CloudWatch** → `ECS` namespace for:
   - `CPUUtilization` / `MemoryUtilization`
   - Task count, running vs. desired
4. Set CloudWatch alarms on high CPU/memory or task count dropping below desired

---

## Step 12: Deploy a New Version (Rolling Update)

1. Build, tag, and push a new image version:
   ```bash
   docker build -t orders-app .
   docker tag orders-app:latest 123456789012.dkr.ecr.ap-south-1.amazonaws.com/orders-app:v2
   docker push 123456789012.dkr.ecr.ap-south-1.amazonaws.com/orders-app:v2
   ```
2. **Task definitions** → `orders-app-task` → **Create new revision**
3. Update the container image URI to `:v2` → **Create**
4. Go to the service → **Update service**
5. Select the new task definition revision → **Update**
6. ECS performs a **rolling deployment** by default — starts new tasks, waits for them to pass health checks, then drains and stops old tasks, keeping the service available throughout

---

## Step 13: Verification Checklist

- [ ] Container image builds and runs correctly locally before pushing to ECR
- [ ] ECR repository has scan-on-push and tag immutability enabled
- [ ] Task execution role has `AmazonECSTaskExecutionRolePolicy`; task role scoped to only what the app needs
- [ ] Tasks run in private subnets with no public IP; ALB handles public traffic
- [ ] Security groups scoped correctly: ALB accepts from internet, ECS tasks accept only from ALB
- [ ] Target group health checks passing (healthy targets shown)
- [ ] Desired task count and auto scaling limits set appropriately
- [ ] CloudWatch log group receiving container logs
- [ ] Successfully tested end-to-end via the ALB DNS name
- [ ] Rolling deployment tested with a second image version

---

## Cleanup (To Avoid Ongoing Charges)

1. Delete the service: **Clusters** → cluster → **Services** → select → **Delete** (set desired count to 0 first if prompted)
2. Delete the cluster: **Clusters** → select → **Delete cluster**
3. Delete the load balancer: **EC2 Console** → **Load Balancers** → select → **Delete**
4. Delete the target group: **Target Groups** → select → **Delete**
5. Deregister/delete old task definition revisions if no longer needed
6. Delete the ECR repository (and its images): **ECR** → select repository → **Delete**
7. Delete the CloudWatch log group `/ecs/orders-app-task`

> Fargate tasks bill per-second while running — deleting the service (not just scaling to 0) stops ongoing charges from the ALB and any idle target groups too.

---

## Quick Reference Summary

| Component | Purpose |
|---|---|
| ECR Repository | Stores container images |
| Cluster | Logical grouping of tasks/services |
| Task Definition | Blueprint: image, CPU/memory, ports, roles, logging |
| Task | A running instance of a task definition |
| Service | Maintains desired task count, integrates with load balancer |
| Task Execution Role | Permissions for ECS to pull images and write logs |
| Task Role | Permissions for the application code itself |
| Target Group | Routes ALB traffic to healthy tasks |

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| Task stuck in `PENDING` then stops | Cannot pull image (wrong URI, missing execution role permission) | Verify image URI and that execution role has ECR pull permissions |
| Target group shows unhealthy targets | Health check path wrong, app not listening on expected port, security group blocking ALB | Verify health check path returns 200; confirm SG allows ALB → task traffic |
| `CannotPullContainerError` | No internet/NAT route from private subnet task to ECR | Ensure private subnet route table has a NAT Gateway route, or use ECR VPC endpoints |
| Service stuck at desired vs. running count mismatch | Tasks continuously failing health checks and being replaced | Check CloudWatch logs for the container's startup errors |
| 502/504 from ALB | Backend task not responding on the configured port | Confirm container port mapping matches the app's listening port |

---

## Next Steps / Advanced Topics

- **ECS Exec** — shell into a running Fargate task for live debugging, without SSH
- **Blue/Green deployments (CodeDeploy)** — safer production rollouts with automatic rollback on failure
- **Service Connect** — simplified service-to-service discovery and communication within a cluster
- **Fargate Spot** — run non-critical tasks at a discount using spare capacity
- **Infrastructure as Code** — manage clusters, task definitions, and services via Terraform, AWS Copilot, or AWS CloudFormation
