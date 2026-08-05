# Setting Up CodeCommit & CodeDeploy in AWS — Complete Step-by-Step Guide

AWS CodeCommit is a managed private Git repository. AWS CodeDeploy automates application deployments to EC2, on-premises servers, Lambda, or ECS with built-in rollback on failure. This guide covers both individually and how they fit into the broader CI/CD pipeline from the companion *AWS CodePipeline Guide*.

> **Note:** As of recent AWS guidance, CodeCommit is in maintenance mode for new customers — AWS recommends GitHub, GitLab, or Bitbucket for new projects (as used in the companion CodePipeline guide). This chapter is included for completeness and for existing CodeCommit users.

---

## Architecture Overview

```
    Developer                CodeDeploy
        │                        │
   git push                Deployment Group
        │                        │
  ┌──────────┐          ┌────────────────┐
  │CodeCommit │─────────►│  EC2 / ASG /     │
  │Repository │  trigger │  Lambda / ECS     │
  └──────────┘          └────────────────┘
                          appspec.yml defines
                          deployment lifecycle hooks
```

---

## Prerequisites

- Active AWS account
- IAM user/role with `AWSCodeCommitFullAccess` and `AWSCodeDeployFullAccess`
- Git installed locally
- A deployment target: EC2 instances (with CodeDeploy agent), Lambda function, or ECS service

---

## Part A: CodeCommit

### Step A1: Create a Repository

1. **CodeCommit Console** → **Create repository**
2. Name: `orders-app`
3. Description: `Orders service source code`
4. Click **Create**

### Step A2: Configure Git Credentials

1. **IAM Console** → select your user → **Security credentials** tab
2. Scroll to **HTTPS Git credentials for AWS CodeCommit** → **Generate credentials**
3. Download the generated username/password
4. Alternatively, use the **AWS CLI credential helper** (recommended, no separate Git password needed):
   ```bash
   git config --global credential.helper '!aws codecommit credential-helper $@'
   git config --global credential.UseHttpPath true
   ```

### Step A3: Clone and Push

```bash
git clone https://git-codecommit.ap-south-1.amazonaws.com/v1/repos/orders-app
cd orders-app
git add .
git commit -m "Initial commit"
git push origin main
```

### Step A4: Set Up Branch Protection (Approval Rules)

1. Select the repository → **Settings** → **Approval rule templates** → **Create template**
2. Configure:
   - Number of approvals needed: `1`
   - Approval pool members: specific IAM users/roles, or `CodeCommitApprovers:*` (any repo contributor)
3. Associate the template with the repository and target branch (`main`)
4. Pull requests targeting `main` now require approval before merging

---

## Part B: CodeDeploy

### Step B1: Create a CodeDeploy Application

1. **CodeDeploy Console** → **Applications** → **Create application**
2. Name: `orders-app`
3. Compute platform: **EC2/On-premises**, **Lambda**, or **ECS** (choose based on target)
4. Click **Create application**

---

### Step B2 (EC2/On-Premises Path): Install the CodeDeploy Agent

On each target EC2 instance:
```bash
sudo yum install -y ruby wget
cd /home/ec2-user
wget https://aws-codedeploy-ap-south-1.s3.ap-south-1.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto
sudo systemctl status codedeploy-agent
```

Attach an IAM role to the instance with `AmazonEC2RoleforAWSCodeDeploy` (or a scoped equivalent granting S3 read access to the deployment artifact bucket).

---

### Step B3: Create a Deployment Group

1. Select the application → **Create deployment group**
2. Configure:
   - Deployment group name: `orders-app-prod`
   - Service role: create/select an IAM role with `AWSCodeDeployRole` trust policy
   - Deployment type:
     - **In-place** — updates instances directly, brief downtime per instance during update
     - **Blue/green** — provisions new instances, shifts traffic, terminates old ones — zero downtime
   - Environment configuration: **Amazon EC2 Auto Scaling groups**, or **EC2 instances** tagged (e.g., `Name=orders-app-prod`)
   - Deployment settings: **CodeDeployDefault.AllAtOnce**, **HalfAtATime**, or **OneAtATime** (controls rollout speed vs. risk)
   - Load balancer: attach an ALB target group for health-checked rollouts
3. Click **Create deployment group**

---

### Step B4: Create an `appspec.yml`

Place at the root of your application source (EC2 example):

```yaml
version: 0.0
os: linux
files:
  - source: /
    destination: /var/www/orders-app

hooks:
  BeforeInstall:
    - location: scripts/before_install.sh
      timeout: 300
  AfterInstall:
    - location: scripts/after_install.sh
      timeout: 300
  ApplicationStart:
    - location: scripts/start_server.sh
      timeout: 300
  ApplicationStop:
    - location: scripts/stop_server.sh
      timeout: 300
  ValidateService:
    - location: scripts/validate_service.sh
      timeout: 300
```

### Deployment Lifecycle Hooks Reference

| Hook | When It Runs |
|---|---|
| `ApplicationStop` | Before the new revision is downloaded (stop the old version) |
| `BeforeInstall` | Before new files are copied (e.g., back up current version) |
| `AfterInstall` | After files copied, before app starts (e.g., install dependencies) |
| `ApplicationStart` | Start the new application version |
| `ValidateService` | Confirm the deployment succeeded (e.g., curl a health endpoint) |

---

### Step B5: Package and Upload the Deployment Artifact

```bash
zip -r app.zip appspec.yml scripts/ src/
aws deploy push \
  --application-name orders-app \
  --s3-location s3://my-deployment-artifacts/orders-app/app.zip \
  --source app.zip
```

---

### Step B6: Create a Deployment

1. Select the application/deployment group → **Create deployment**
2. Revision location: the S3 URI from Step B5, or connect directly to CodeCommit/GitHub
3. Click **Create deployment**
4. Watch the deployment progress through each lifecycle hook per instance
5. On failure, CodeDeploy automatically rolls back (if configured) to the last known-good deployment

---

### Step B7 (Lambda Path): Configure Traffic Shifting

For Lambda deployments, `appspec.yml` looks different:

```yaml
version: 0.0
Resources:
  - orders-function:
      Type: AWS::Lambda::Function
      Properties:
        Name: process-order-events
        Alias: live
        CurrentVersion: "3"
        TargetVersion: "4"
```

Deployment configuration options:

| Config | Behavior |
|---|---|
| `CodeDeployDefault.LambdaAllAtOnce` | Instant full cutover |
| `CodeDeployDefault.LambdaLinear10PercentEvery1Minute` | Gradual, safer rollout |
| `CodeDeployDefault.LambdaCanary10Percent5Minutes` | Small canary, then full shift if healthy |

CloudWatch Alarms can be attached to automatically roll back if error rates spike during the shift.

---

## Verification Checklist

- [ ] CodeCommit repository created with Git credential helper configured
- [ ] Approval rule template enforces review before merging to main (if applicable)
- [ ] CodeDeploy agent installed and running on all target EC2 instances
- [ ] Deployment group configured with the correct deployment type (in-place vs. blue/green)
- [ ] `appspec.yml` lifecycle hooks tested — especially `ValidateService` actually checks application health
- [ ] Deployment successfully completes and rolls back automatically on a simulated failure
- [ ] (Lambda) Traffic-shifting deployment configuration and rollback alarms tested

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| Deployment stuck at `Install` | CodeDeploy agent not running, or IAM role missing S3 access | `sudo systemctl status codedeploy-agent`; verify instance role permissions |
| `ValidateService` hook always fails | Health check script has wrong path/port | Test the script manually via SSH/Session Manager first |
| Deployment succeeds but old code still running | `ApplicationStart` script doesn't actually restart the service | Confirm the start script correctly restarts (not just starts, if already running) the process |
| Rollback not triggering on failure | Rollback not enabled on the deployment group | Edit deployment group → enable automatic rollback on deployment failure |

---

## Next Steps / Advanced Topics

- **CodeArtifact** — private package repository for npm/pip/Maven, integrates into CodeBuild's build phase
- **Blue/Green with Auto Scaling Groups** — CodeDeploy provisions a full replacement ASG for true zero-downtime EC2 deployments
- **CodeDeploy + CodePipeline** — chain CodeCommit → CodeBuild → CodeDeploy into one automated pipeline (see companion *AWS CodePipeline Guide*)
- **Infrastructure as Code** — manage applications, deployment groups, and repositories via Terraform or CloudFormation
