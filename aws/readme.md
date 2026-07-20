# AWS Infrastructure & Application Deployment — Step-by-Step Guide

A detailed walkthrough of a typical AWS architecture and the procedure to build, deploy, and run a web application on it from scratch.

## Table of Contents
1. [Reference Architecture](#1-reference-architecture)
2. [Core AWS Services Used](#2-core-aws-services-used)
3. [Prerequisites](#3-prerequisites)
4. [Step 1 — Set Up AWS Account & CLI](#step-1--set-up-aws-account--cli)
5. [Step 2 — Design the Network (VPC)](#step-2--design-the-network-vpc)
6. [Step 3 — Set Up IAM Roles & Security](#step-3--set-up-iam-roles--security)
7. [Step 4 — Provision the Database (RDS)](#step-4--provision-the-database-rds)
8. [Step 5 — Containerize the Application](#step-5--containerize-the-application)
9. [Step 6 — Push Image to ECR](#step-6--push-image-to-ecr)
10. [Step 7 — Deploy Compute (ECS/Fargate or EC2)](#step-7--deploy-compute-ecsfargate-or-ec2)
11. [Step 8 — Set Up Load Balancing](#step-8--set-up-load-balancing)
12. [Step 9 — Configure DNS & HTTPS](#step-9--configure-dns--https)
13. [Step 10 — Set Up CI/CD Pipeline](#step-10--set-up-cicd-pipeline)
14. [Step 11 — Monitoring & Logging](#step-11--monitoring--logging)
15. [Step 12 — Scaling & Cost Optimization](#step-12--scaling--cost-optimization)
16. [Full Deployment Checklist](#16-full-deployment-checklist)

---

## 1. Reference Architecture

```
                                   ┌─────────────────┐
                                   │      Route 53     │  (DNS)
                                   └─────────┬────────┘
                                             │
                                   ┌─────────▼────────┐
                                   │   CloudFront CDN   │  (optional, static assets/caching)
                                   └─────────┬────────┘
                                             │
                                   ┌─────────▼────────┐
                                   │   ACM (SSL/TLS)    │
                                   └─────────┬────────┘
                                             │
┌───────────────────────────────── VPC ──────▼──────────────────────────────────────┐
│                                                                                     │
│   ┌─────────────────────────── Public Subnets (2 AZs) ─────────────────────────┐  │
│   │                                                                             │  │
│   │              ┌────────────────────────────┐                                │  │
│   │              │  Application Load Balancer │                                │  │
│   │              └─────────────┬──────────────┘                                │  │
│   │                            │                                                │  │
│   │              ┌─────────────┴──────────────┐                                │  │
│   │              │        NAT Gateway           │                              │  │
│   │              └────────────────────────────┘                                │  │
│   └────────────────────────────┬──────────────────────────────────────────────┘  │
│                                  │                                                 │
│   ┌────────────────────────── Private Subnets (2 AZs) ──────────────────────────┐│
│   │                                                                              ││
│   │     ┌───────────────┐   ┌───────────────┐        ┌────────────────────┐    ││
│   │     │  ECS/Fargate   │   │  ECS/Fargate   │        │   RDS (Multi-AZ)    │    ││
│   │     │  Task (AZ-1)   │   │  Task (AZ-2)   │───────▶│   PostgreSQL/MySQL  │    ││
│   │     └───────────────┘   └───────────────┘        └────────────────────┘    ││
│   │                                                                              ││
│   │     ┌───────────────┐        ┌───────────────┐                              ││
│   │     │  ElastiCache   │        │  S3 (via VPC   │                              ││
│   │     │  (Redis)       │        │  endpoint)     │                              ││
│   │     └───────────────┘        └───────────────┘                              ││
│   └──────────────────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────────────────┘

     Supporting services (outside VPC boundary, account-wide):
     ECR (image registry) │ IAM (access control) │ CloudWatch (logs/metrics)
     Secrets Manager (credentials) │ CodePipeline/CodeBuild (CI/CD)
```

---

## 2. Core AWS Services Used

| Service | Role in Architecture |
|---|---|
| VPC | Isolated network — subnets, routing, security boundary |
| IAM | Identity & access control for users, roles, services |
| EC2 / ECS / Fargate | Compute to run the application |
| ECR | Docker image registry |
| RDS | Managed relational database (Multi-AZ for HA) |
| ElastiCache | Managed Redis/Memcached for caching/sessions |
| S3 | Object storage — static assets, backups, logs |
| ALB (Application Load Balancer) | Distributes traffic across compute instances/tasks |
| Route 53 | DNS management |
| ACM | Free SSL/TLS certificates |
| CloudFront | CDN for global content delivery |
| CloudWatch | Metrics, logs, alarms |
| Secrets Manager / Parameter Store | Secure storage for credentials & config |
| CodePipeline / CodeBuild / CodeDeploy | Native AWS CI/CD |
| Auto Scaling Groups | Automatic compute scaling based on demand |

---

## 3. Prerequisites

- An AWS account with billing enabled
- AWS CLI installed locally
- Docker installed locally
- A domain name (optional, for Route 53 + HTTPS)
- Application source code with a working `Dockerfile`

---

## Step 1 — Set Up AWS Account & CLI

```bash
# Install AWS CLI (example: Linux)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure credentials
aws configure
# AWS Access Key ID: <your key>
# AWS Secret Access Key: <your secret>
# Default region: us-east-1
# Output format: json

# Verify
aws sts get-caller-identity
```

> Best practice: don't use your root account for daily work. Create an IAM user (or use IAM Identity Center/SSO) with least-privilege permissions, and enable MFA.

---

## Step 2 — Design the Network (VPC)

```bash
# Create a VPC
aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications \
  'ResourceType=vpc,Tags=[{Key=Name,Value=myapp-vpc}]'

# Create public and private subnets across 2 Availability Zones
aws ec2 create-subnet --vpc-id <vpc-id> --cidr-block 10.0.1.0/24 --availability-zone us-east-1a
aws ec2 create-subnet --vpc-id <vpc-id> --cidr-block 10.0.2.0/24 --availability-zone us-east-1b
aws ec2 create-subnet --vpc-id <vpc-id> --cidr-block 10.0.3.0/24 --availability-zone us-east-1a
aws ec2 create-subnet --vpc-id <vpc-id> --cidr-block 10.0.4.0/24 --availability-zone us-east-1b

# Create and attach an Internet Gateway (for public subnets)
aws ec2 create-internet-gateway
aws ec2 attach-internet-gateway --vpc-id <vpc-id> --internet-gateway-id <igw-id>

# Create a NAT Gateway (for private subnets to reach the internet)
aws ec2 allocate-address --domain vpc
aws ec2 create-nat-gateway --subnet-id <public-subnet-id> --allocation-id <eip-alloc-id>
```

> In practice, most teams do this via **Terraform** or **CloudFormation** rather than raw CLI calls — see the sample Terraform snippet in Step 12.

**Subnet layout:**

| Subnet | Type | Purpose |
|---|---|---|
| Public (AZ-1, AZ-2) | Public | ALB, NAT Gateway |
| Private-App (AZ-1, AZ-2) | Private | ECS/Fargate tasks or EC2 instances |
| Private-DB (AZ-1, AZ-2) | Private, isolated | RDS, ElastiCache |

---

## Step 3 — Set Up IAM Roles & Security

```bash
# Create an ECS task execution role
aws iam create-role --role-name ecsTaskExecutionRole \
  --assume-role-policy-document file://ecs-trust-policy.json

aws iam attach-role-policy --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

# Create security groups
aws ec2 create-security-group --group-name alb-sg --description "ALB SG" --vpc-id <vpc-id>
aws ec2 authorize-security-group-ingress --group-id <alb-sg-id> --protocol tcp --port 443 --cidr 0.0.0.0/0

aws ec2 create-security-group --group-name app-sg --description "App SG" --vpc-id <vpc-id>
aws ec2 authorize-security-group-ingress --group-id <app-sg-id> --protocol tcp --port 8080 --source-group <alb-sg-id>

aws ec2 create-security-group --group-name db-sg --description "DB SG" --vpc-id <vpc-id>
aws ec2 authorize-security-group-ingress --group-id <db-sg-id> --protocol tcp --port 5432 --source-group <app-sg-id>
```

**Security group chain:** Internet → ALB (443) → App (8080) → DB (5432), each layer only accepting traffic from the layer above it.

---

## Step 4 — Provision the Database (RDS)

```bash
aws rds create-db-subnet-group \
  --db-subnet-group-name myapp-db-subnet \
  --subnet-ids <private-db-subnet-1> <private-db-subnet-2>

aws rds create-db-instance \
  --db-instance-identifier myapp-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --master-username admin \
  --master-user-password '<use Secrets Manager instead of plaintext>' \
  --allocated-storage 20 \
  --vpc-security-group-ids <db-sg-id> \
  --db-subnet-group-name myapp-db-subnet \
  --multi-az \
  --no-publicly-accessible
```

Store the credentials in **Secrets Manager** instead of hardcoding them:
```bash
aws secretsmanager create-secret \
  --name myapp/db-credentials \
  --secret-string '{"username":"admin","password":"<generated>"}'
```

---

## Step 5 — Containerize the Application

```dockerfile
# Dockerfile
FROM node:20-slim
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY . .
EXPOSE 8080
CMD ["node", "server.js"]
```

```bash
# Build and test locally
docker build -t myapp:local .
docker run -p 8080:8080 myapp:local
curl http://localhost:8080/health
```

---

## Step 6 — Push Image to ECR

```bash
# Create the ECR repository
aws ecr create-repository --repository-name myapp

# Authenticate Docker to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Tag and push
docker tag myapp:local <account-id>.dkr.ecr.us-east-1.amazonaws.com/myapp:1.0
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/myapp:1.0
```

---

## Step 7 — Deploy Compute (ECS/Fargate or EC2)

**Option A — ECS Fargate (serverless containers, recommended for most apps):**
```bash
aws ecs create-cluster --cluster-name myapp-cluster

# Register a task definition (task-def.json defines container, CPU/mem, image URI, env vars)
aws ecs register-task-definition --cli-input-json file://task-def.json

# Create the service behind the ALB
aws ecs create-service \
  --cluster myapp-cluster \
  --service-name myapp-service \
  --task-definition myapp-task \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[<private-subnet-1>,<private-subnet-2>],securityGroups=[<app-sg-id>]}" \
  --load-balancers "targetGroupArn=<target-group-arn>,containerName=myapp,containerPort=8080"
```

**Option B — EC2 with Auto Scaling Group (more control, more management overhead):**
```bash
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name myapp-asg \
  --launch-template LaunchTemplateName=myapp-lt \
  --min-size 2 --max-size 6 --desired-capacity 2 \
  --vpc-zone-identifier "<private-subnet-1>,<private-subnet-2>" \
  --target-group-arns <target-group-arn>
```

| Compute Option | Best For |
|---|---|
| ECS Fargate | No server management, pay-per-task, simpler ops |
| ECS on EC2 | More control over instance type/cost, still container-native |
| EC2 (raw) | Full OS control, legacy apps, custom AMIs |
| Lambda | Event-driven/serverless functions, not long-running services |
| EKS | Kubernetes-native workloads, multi-cloud portability |

---

## Step 8 — Set Up Load Balancing

```bash
aws elbv2 create-load-balancer \
  --name myapp-alb \
  --subnets <public-subnet-1> <public-subnet-2> \
  --security-groups <alb-sg-id> \
  --scheme internet-facing --type application

aws elbv2 create-target-group \
  --name myapp-tg \
  --protocol HTTP --port 8080 \
  --vpc-id <vpc-id> \
  --target-type ip \
  --health-check-path /health

aws elbv2 create-listener \
  --load-balancer-arn <alb-arn> \
  --protocol HTTPS --port 443 \
  --certificates CertificateArn=<acm-cert-arn> \
  --default-actions Type=forward,TargetGroupArn=<target-group-arn>
```

---

## Step 9 — Configure DNS & HTTPS

```bash
# Request an SSL certificate (must validate via DNS or email)
aws acm request-certificate --domain-name myapp.example.com --validation-method DNS

# Point your domain at the ALB
aws route53 change-resource-record-sets \
  --hosted-zone-id <zone-id> \
  --change-batch '{
    "Changes": [{
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "myapp.example.com",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "<alb-hosted-zone-id>",
          "DNSName": "<alb-dns-name>",
          "EvaluateTargetHealth": true
        }
      }
    }]
  }'
```

---

## Step 10 — Set Up CI/CD Pipeline

```
GitHub/CodeCommit → CodePipeline → CodeBuild (build+test+push to ECR) → CodeDeploy/ECS deploy
```

```yaml
# buildspec.yml — used by CodeBuild
version: 0.2
phases:
  pre_build:
    commands:
      - aws ecr get-login-password | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
  build:
    commands:
      - docker build -t myapp:$CODEBUILD_RESOLVED_SOURCE_VERSION .
      - docker tag myapp:$CODEBUILD_RESOLVED_SOURCE_VERSION <account-id>.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
  post_build:
    commands:
      - docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
      - aws ecs update-service --cluster myapp-cluster --service myapp-service --force-new-deployment
```

Alternative: use **GitHub Actions** with the `aws-actions/amazon-ecs-deploy-task-definition` action instead of CodePipeline — many teams prefer this if source is already on GitHub.

---

## Step 11 — Monitoring & Logging

```bash
# Create a CloudWatch log group for the app
aws logs create-log-group --log-group-name /ecs/myapp

# Create an alarm for high CPU
aws cloudwatch put-metric-alarm \
  --alarm-name myapp-high-cpu \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --alarm-actions <sns-topic-arn>
```

| Tool | Purpose |
|---|---|
| CloudWatch Logs | Centralized application/container logs |
| CloudWatch Metrics & Alarms | Resource metrics, threshold-based alerting |
| CloudWatch Dashboards | Visualize key metrics |
| X-Ray | Distributed tracing |
| SNS | Alert notifications (email, SMS, Slack via integration) |
| AWS Config | Track resource configuration changes/compliance |

---

## Step 12 — Scaling & Cost Optimization

```bash
# Auto-scale ECS service based on CPU utilization
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --resource-id service/myapp-cluster/myapp-service \
  --scalable-dimension ecs:service:DesiredCount \
  --min-capacity 2 --max-capacity 10

aws application-autoscaling put-scaling-policy \
  --service-namespace ecs \
  --resource-id service/myapp-cluster/myapp-service \
  --scalable-dimension ecs:service:DesiredCount \
  --policy-name cpu-scale-policy \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration '{
    "TargetValue": 60.0,
    "PredefinedMetricSpecification": {"PredefinedMetricType": "ECSServiceAverageCPUUtilization"}
  }'
```

**Cost optimization tips:**
- Use **Fargate Spot** for non-critical/batch workloads (up to 70% cheaper)
- Use **Savings Plans/Reserved Instances** for predictable baseline load
- Set **S3 lifecycle policies** to auto-archive/delete old data
- Right-size RDS/EC2 instances using **CloudWatch + Compute Optimizer** recommendations
- Enable **AWS Budgets** and cost alerts

---

## 16. Full Deployment Checklist

- [ ] AWS account set up, IAM user (not root) configured with MFA
- [ ] VPC created with public + private subnets across 2+ AZs
- [ ] Internet Gateway + NAT Gateway configured
- [ ] Security groups scoped to least privilege (ALB → App → DB chain)
- [ ] RDS database provisioned, Multi-AZ enabled, credentials in Secrets Manager
- [ ] Application containerized with a working `Dockerfile`
- [ ] ECR repository created, image pushed
- [ ] ECS cluster + service (or EC2 ASG) deployed in private subnets
- [ ] ALB set up with HTTPS listener (ACM certificate attached)
- [ ] Route 53 DNS pointed at the ALB
- [ ] CI/CD pipeline automating build → test → push → deploy
- [ ] CloudWatch logging, metrics, and alarms configured
- [ ] Auto Scaling policies set for compute
- [ ] Budgets/cost alerts enabled
- [ ] Backups configured (RDS automated snapshots, S3 versioning)
