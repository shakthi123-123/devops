# Setting Up CI/CD with CodePipeline in AWS — Complete Step-by-Step Guide

AWS CodePipeline orchestrates continuous integration and delivery by connecting a source repository, build/test stage, and deployment stage into an automated pipeline. This guide covers building a pipeline that pulls from GitHub, builds/tests with CodeBuild, and deploys to ECS (Fargate) — with notes for Lambda and EC2/CodeDeploy alternatives.

---

## Architecture Overview

```
   GitHub Push
        │
   ┌────▼─────┐
   │  Source    │  CodePipeline Stage 1
   │  (GitHub)  │
   └────┬─────┘
        │
   ┌────▼─────┐
   │  Build     │  CodePipeline Stage 2
   │ (CodeBuild)│  → run tests, build Docker image, push to ECR
   └────┬─────┘
        │
   ┌────▼─────┐
   │  Deploy    │  CodePipeline Stage 3
   │ (ECS/      │  → update ECS service, or deploy Lambda, or CodeDeploy to EC2
   │  CodeDeploy)│
   └──────────┘
```

---

## Prerequisites

- Active AWS account
- IAM user/role with `AWSCodePipeline_FullAccess`, `AWSCodeBuildAdminAccess`, and relevant deploy-target permissions
- Source code in a Git repository (GitHub, CodeCommit, Bitbucket, or GitLab)
- An existing deployment target — ECS service, Lambda function, or EC2 instances (see companion guides)

---

## Step 1: Sign In and Select Region

1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in with IAM credentials
3. Select your target **region** (e.g., `Asia Pacific (Mumbai) ap-south-1`)

---

## Step 2: Connect Your Source Repository

### For GitHub (via CodeStar Connections)

1. In the search bar, type `Developer Tools Settings` or navigate via **CodePipeline** → **Settings** → **Connections**
2. Click **Create connection**
3. Provider: **GitHub**
4. Connection name: `github-connection`
5. Click **Connect to GitHub** → authorize AWS Connector for GitHub in the popup
6. Select the repository access scope (all repos or specific ones)
7. Click **Connect**
8. Confirm the connection status shows **Available**

---

## Step 3: Create an ECR Repository (If Deploying Containers)

1. **ECR Console** → **Create repository**
2. Name: `orders-app` (skip if already created — see companion *AWS ECS Creation Guide*)
3. Enable **Scan on push**
4. Click **Create repository**

---

## Step 4: Create a CodeBuild Project

CodeBuild compiles code, runs tests, and (for containers) builds and pushes the Docker image.

1. In the search bar, type `CodeBuild` and select **CodeBuild**
2. Left sidebar → **Build projects** → **Create build project**
3. **Project configuration**:
   - Project name: `orders-app-build`
4. **Source**:
   - Source provider: **GitHub**
   - Repository: select via the connection from Step 2
   - Branch: `main`
5. **Environment**:

| Field | Value | Notes |
|---|---|---|
| Environment image | Managed image | AWS-maintained build environments |
| Operating system | Amazon Linux 2023 | |
| Runtime | Standard | |
| Image | `aws/codebuild/amazonlinux2-x86_64-standard:5.0` | Includes Docker, common languages |
| Privileged | **Enable** | Required if building Docker images inside CodeBuild |
| Service role | **New service role** | Auto-creates `codebuild-orders-app-build-service-role` |

6. **Buildspec**:
   - Select **Use a buildspec file** (recommended — keep it versioned with your code)
7. **Logs**: enable **CloudWatch Logs**, group name: `/aws/codebuild/orders-app-build`
8. Click **Create build project**

---

## Step 5: Add a `buildspec.yml` to Your Repository

Create this file at the root of your repo:

```yaml
version: 0.2

phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
      - REPOSITORY_URI=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/orders-app
      - IMAGE_TAG=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
  build:
    commands:
      - echo Running tests...
      - npm ci
      - npm test
      - echo Building the Docker image...
      - docker build -t $REPOSITORY_URI:$IMAGE_TAG -t $REPOSITORY_URI:latest .
  post_build:
    commands:
      - echo Pushing the Docker image...
      - docker push $REPOSITORY_URI:$IMAGE_TAG
      - docker push $REPOSITORY_URI:latest
      - echo Writing image definitions file...
      - printf '[{"name":"orders-app-container","imageUri":"%s"}]' $REPOSITORY_URI:$IMAGE_TAG > imagedefinitions.json

artifacts:
  files:
    - imagedefinitions.json
```

> `imagedefinitions.json` is the standard format CodePipeline's ECS deploy action expects — it maps the container name (from your ECS task definition) to the newly built image URI.

---

## Step 6: Grant CodeBuild Permissions to Push to ECR

1. **IAM Console** → **Roles** → find the auto-created `codebuild-orders-app-build-service-role`
2. **Add permissions** → **Attach policies** → attach `AmazonEC2ContainerRegistryPowerUser`
3. If deploying to ECS/other services later in the pipeline, also attach relevant permissions, or handle that via the pipeline's own deploy stage role instead

---

## Step 7: Create the Pipeline

1. **CodePipeline Console** → **Create pipeline**
2. **Pipeline settings**:
   - Pipeline name: `orders-app-pipeline`
   - Service role: **New service role** (auto-creates with required permissions)
   - Artifact store: **Default location** (auto-creates an S3 bucket for passing artifacts between stages)
3. Click **Next**

### Stage 1: Source

1. Source provider: **GitHub (via GitHub App)**
2. Connection: select `github-connection` (from Step 2)
3. Repository name: your repo
4. Branch name: `main`
5. **Change detection**: **CodePipeline** (webhook-based, triggers automatically on push) — recommended over polling
6. Click **Next**

### Stage 2: Build

1. Build provider: **AWS CodeBuild**
2. Region: your region
3. Project name: `orders-app-build` (from Step 4)
4. Click **Next**

### Stage 3: Deploy

Choose based on your target:

#### Option A: Deploy to ECS

1. Deploy provider: **Amazon ECS**
2. Cluster name: `orders-cluster`
3. Service name: `orders-service`
4. Image definitions file: `imagedefinitions.json` (matches the buildspec output)
5. Click **Next**

#### Option B: Deploy to Lambda

1. Deploy provider: **AWS CloudFormation** (deploy via SAM/CFN template) or a **Lambda** deploy action invoking a deployment function
2. Typically requires a `template.yaml` (SAM) committed to the repo defining the function and its update behavior

#### Option C: Deploy to EC2 (via CodeDeploy)

1. Deploy provider: **AWS CodeDeploy**
2. Requires a **CodeDeploy application** and **deployment group** pre-configured, targeting an Auto Scaling group or tagged EC2 instances
3. Requires an `appspec.yml` in the repo defining deployment hooks (`BeforeInstall`, `AfterInstall`, `ApplicationStart`, etc.)

4. Click **Next** → review → **Create pipeline**

---

## Step 8: Verify the Pipeline Runs

1. The pipeline triggers automatically on creation (using the latest commit on the configured branch)
2. Watch each stage transition: **Source** → **Build** → **Deploy**, each showing **In progress** → **Succeeded**/**Failed**
3. Click into the **Build** stage → **Details** to view real-time CodeBuild logs if troubleshooting
4. Once **Deploy** succeeds, verify the change is live (e.g., check the ECS service's running task image tag, or test the application endpoint)

---

## Step 9: Add a Manual Approval Stage (Optional, for Production Gates)

1. Edit the pipeline → click **+ Add stage** between Build and Deploy (e.g., before a production deploy)
2. Stage name: `ApproveForProduction`
3. **+ Add action group** → Action provider: **Manual approval**
4. Configure:
   - SNS topic: select/create one to notify approvers
   - Comments: add context shown to the approver
5. Click **Done** → **Save**
6. Now the pipeline pauses at this stage until a designated person reviews and clicks **Approve** or **Reject** in the console (or via the emailed link)

---

## Step 10: Add Multiple Environments (Dev → Staging → Prod)

Common pattern: one pipeline (or chained pipelines) deploying progressively.

1. Duplicate the **Deploy** stage configuration for each environment, targeting different ECS clusters/services (e.g., `orders-cluster-staging`, `orders-cluster-prod`)
2. Insert a **Manual approval** action (Step 9) before the production deploy stage
3. Optionally add automated tests (a CodeBuild action running integration tests) against the staging environment before allowing promotion to production

---

## Step 11: Monitor Pipeline Executions

1. **CodePipeline Console** → select pipeline → **View history** — see all past executions, their status, and duration
2. Set up **EventBridge rules** to notify on pipeline state changes:
   - **EventBridge** → **Create rule**
   - Event source: **CodePipeline Pipeline Execution State Change**
   - Filter: `FAILED` state
   - Target: SNS topic → notify the team on failed deployments
3. **CloudWatch** → review CodeBuild's `Duration`, `SucceededBuilds`, `FailedBuilds` metrics for build health trends

---

## Step 12: Verification Checklist

- [ ] GitHub connection status shows **Available**
- [ ] `buildspec.yml` committed to the repository and correctly builds/tests/pushes the image
- [ ] CodeBuild service role has ECR push permissions
- [ ] Pipeline triggers automatically on push to the configured branch
- [ ] Build stage logs show tests passing before proceeding to deploy
- [ ] Deploy stage successfully updates the target (ECS service, Lambda, or EC2 via CodeDeploy)
- [ ] Manual approval gate configured before production deployments
- [ ] Failed pipeline executions trigger a notification (SNS/EventBridge)
- [ ] Rollback plan understood (see troubleshooting) in case a bad deploy reaches production

---

## Cleanup (To Avoid Ongoing Charges)

1. Delete the pipeline: **CodePipeline** → select → **Delete**
2. Delete the CodeBuild project: **CodeBuild** → select → **Delete build project**
3. Delete the GitHub connection if unused elsewhere: **Settings** → **Connections** → select → **Delete**
4. Empty and delete the auto-created S3 artifact bucket
5. Delete the auto-created IAM service roles (`codebuild-*-service-role`, pipeline service role) if not reused
6. Delete the CloudWatch log group for CodeBuild

> CodePipeline bills per active pipeline per month; CodeBuild bills per build minute — idle pipelines (no new commits) still incur the monthly pipeline charge until deleted.

---

## Quick Reference Summary

| Component | Purpose |
|---|---|
| Pipeline | Orchestrates the end-to-end flow across stages |
| Stage | A logical phase (Source, Build, Deploy, Approval) |
| Action | A specific task within a stage (e.g., a CodeBuild run) |
| CodeBuild Project | Defines the build environment and buildspec |
| buildspec.yml | Instructions for what CodeBuild runs at each phase |
| Artifact Store | S3 bucket passing build outputs between stages |
| Manual Approval | Pauses the pipeline pending human sign-off |

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| Pipeline doesn't trigger on push | Webhook/connection issue, or wrong branch configured | Verify connection status is **Available**; confirm branch name matches |
| Build fails with `docker: permission denied` | **Privileged mode** not enabled on the CodeBuild project | Edit project → Environment → enable **Privileged** |
| `AccessDenied` pushing to ECR | CodeBuild service role missing ECR permissions | Attach `AmazonEC2ContainerRegistryPowerUser` to the service role |
| ECS deploy stage fails | `imagedefinitions.json` container name doesn't match the task definition's container name | Ensure the name in the buildspec output exactly matches the task definition |
| Tests pass locally but fail in CodeBuild | Environment differences (missing env vars, different Node/language version) | Set required environment variables in the CodeBuild project; pin the runtime image version |

---

## Next Steps / Advanced Topics

- **CodePipeline + CodeDeploy Blue/Green** — zero-downtime deployments with automatic rollback on failed health checks
- **Cross-account pipelines** — deploy from a shared tooling account into separate dev/staging/prod AWS accounts
- **Parallel actions** — run multiple test suites or deploy to multiple regions simultaneously within one stage
- **AWS CodeStar Notifications** — richer Slack/Chatbot integration for pipeline status updates
- **Infrastructure as Code** — manage pipelines, build projects, and deployment groups via Terraform or AWS CloudFormation (including self-referential pipelines that deploy their own IaC changes)
