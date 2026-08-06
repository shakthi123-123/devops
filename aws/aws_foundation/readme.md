# AWS Foundations — Complete Setup Guide

A combined, ordered reference for provisioning a secure AWS environment from scratch: networking, identity, compute, storage, databases, serverless functions, APIs, monitoring, NoSQL, containers, DNS, CDN, messaging, security, secrets, CI/CD, Kubernetes, multi-VPC networking, multi-account governance, and core DevOps tooling (IaC, ops automation, source control/deployment, orchestration, and observability).

## Recommended Build Order

This document follows the sequence a real deployment typically uses — each chapter builds on resources created in the ones before it:

1. **[IAM](#chapter-1-iam)** — users, groups, roles, and least-privilege policies
2. **[VPC](#chapter-2-vpc)** — network foundation (subnets, routing, internet/NAT gateways)
3. **[EC2](#chapter-3-ec2)** — virtual servers in the VPC's public subnet
4. **[S3](#chapter-4-s3)** — object storage for assets, backups, and static content
5. **[RDS](#chapter-5-rds)** — managed relational database in the VPC's private subnets
6. **[Lambda](#chapter-6-lambda)** — serverless functions, often reading/writing S3 and RDS
7. **[API Gateway](#chapter-7-api-gateway)** — HTTP front door for Lambda and other backends
8. **[CloudWatch](#chapter-8-cloudwatch)** — dashboards, logs, alarms, and automated monitoring across every service above
9. **[DynamoDB](#chapter-9-dynamodb)** — serverless NoSQL database, often paired with Lambda and API Gateway
10. **[ECS (Fargate)](#chapter-10-ecs)** — containerized services as an alternative/complement to EC2 and Lambda
11. **[Route 53](#chapter-11-route53)** — DNS, domain registration, and health-check-driven failover
12. **[CloudFront](#chapter-12-cloudfront)** — global CDN in front of S3, ALB, or API Gateway origins
13. **[SNS & SQS](#chapter-13-sns-sqs)** — pub/sub notifications and durable message queuing between services
14. **[WAF](#chapter-14-waf)** — web application firewall protecting CloudFront/ALB/API Gateway
15. **[Secrets Manager](#chapter-15-secrets-manager)** — secure storage and rotation of credentials and API keys
16. **[CodePipeline (CI/CD)](#chapter-16-codepipeline)** — automated build, test, and deployment pipeline tying everything together
17. **[EKS (Kubernetes)](#chapter-17-eks)** — managed Kubernetes as an alternative to ECS for container orchestration
18. **[VPC Peering & Transit Gateway](#chapter-18-vpc-peering-tgw)** — connecting multiple VPCs, point-to-point or hub-and-spoke
19. **[Organizations, Cost Explorer & Budgets](#chapter-19-organizations-cost)** — multi-account governance and spend visibility/control
20. **[CloudFormation](#chapter-20-cloudformation)** — native Infrastructure as Code for repeatable, versioned deployments
21. **[Systems Manager (SSM)](#chapter-21-ssm)** — fleet management, secure shell access, patching, and parameter storage
22. **[CodeCommit & CodeDeploy](#chapter-22-codecommit-codedeploy)** — managed Git hosting and automated deployment with rollback
23. **[Step Functions & EventBridge](#chapter-23-stepfunctions-eventbridge)** — workflow orchestration and event-driven automation
24. **[CloudTrail & X-Ray](#chapter-24-cloudtrail-xray)** — API audit logging and distributed request tracing

Each chapter is self-contained with its own prerequisites, verification checklist, cleanup steps, and troubleshooting table, so you can also jump directly to the service you need.

---

<a id="chapter-1-iam"></a>

# Creating IAM Users, Groups, Roles & Policies in AWS — Complete Step-by-Step Guide

AWS Identity and Access Management (IAM) controls **who** can access your AWS account and **what** they can do. This guide covers creating users, groups, custom policies, and roles following security best practices.

---

## Architecture Overview

```
                    AWS Account (Root)
                          │
              ┌───────────┴───────────┐
              │                       │
          IAM Users                IAM Roles
              │                       │
        ┌─────┴─────┐          ┌──────┴──────┐
        │           │          │             │
   IAM Groups   Direct       EC2/Lambda   Cross-Account
        │      Policies      Service       Access
        │      (avoid)        Role
   IAM Policies
   (attached to
     groups)
```

**Key principle:** Users → Groups → Policies (never attach policies directly to users if avoidable). Roles are used by AWS services or for temporary cross-account/federated access — never by a permanent human login.

---

## Prerequisites

- Active AWS account (root user access for initial setup only)
- Understanding of least-privilege principle: grant only the permissions needed, nothing more

---

## Step 1: Secure the Root Account First

Before creating any IAM users, lock down the root account — it has unrestricted access and should never be used for daily tasks.

1. Sign in to [https://console.aws.amazon.com](https://console.aws.amazon.com) as **root**
2. Go to **IAM Dashboard** → **Security recommendations** panel
3. Enable **MFA (Multi-Factor Authentication)** on the root user:
   - Click **Add MFA** → choose **Authenticator app** (e.g., Google Authenticator, Authy) or a hardware security key
   - Scan the QR code and enter two consecutive MFA codes to confirm
4. Do **not** create access keys for the root user
5. After creating an admin IAM user (Step 4), stop using root for routine work

---

## Step 2: Open the IAM Dashboard

1. In the console search bar, type `IAM` and select **IAM**
2. Note: IAM is a **global service** — it is not tied to any specific region

---

## Step 3: Create an IAM Group

Groups let you assign permissions once and apply them to multiple users.

1. Left sidebar → **User groups** → **Create group**
2. Configure:
   - **User group name**: `Administrators` (or `Developers`, `ReadOnlyUsers`, etc.)
3. Under **Attach permissions policies**, search and select:
   - `AdministratorAccess` (for a full-admin group — use sparingly)
   - Or a scoped policy like `AmazonEC2FullAccess` for a specific team
4. Click **Create group**

> **Best practice:** Create separate groups per function — e.g., `Admins`, `Developers`, `Billing`, `ReadOnly` — rather than one broad group for everyone.

---

## Step 4: Create an IAM User

1. Left sidebar → **Users** → **Create user**
2. **Step 1 — User details**:
   - **User name**: `jane.doe`
   - Check **Provide user access to the AWS Management Console** (if this person needs console login)
     - Choose **I want to create an IAM user**
     - Console password: **Autogenerated** or **Custom password**
     - Check **Users must create a new password at next sign-in** (recommended)
3. **Step 2 — Permissions**:
   - Select **Add user to group**
   - Check the group created in Step 3 (`Administrators`)
   - Alternative options: **Copy permissions from existing user**, or **Attach policies directly** (avoid for maintainability)
4. **Step 3 — Review and create**:
   - Review name, group membership, and console access settings
   - Click **Create user**
5. **Retrieve credentials**:
   - Download the `.csv` file with the console sign-in URL and password, or copy them manually
   - This is the **only time** the auto-generated password is shown

---

## Step 5: Enable MFA for the New User

1. Go to **Users** → select `jane.doe`
2. **Security credentials** tab → **Multi-factor authentication (MFA)** → **Assign MFA device**
3. Choose device type:
   - **Authenticator app** (most common)
   - **Security key** (FIDO2/U2F, e.g., YubiKey)
   - **Hardware TOTP token**
4. Follow the on-screen QR/setup steps and confirm with two consecutive codes
5. Click **Add MFA**

> Enforce MFA account-wide using an IAM policy condition (`aws:MultiFactorAuthPresent`) that denies actions unless MFA is present.

---

## Step 6: Create a Custom IAM Policy (Least Privilege)

Instead of using broad AWS-managed policies, create a custom policy scoped to exact needs.

1. Left sidebar → **Policies** → **Create policy**
2. Choose the **JSON** tab and enter a policy, for example — read-only S3 access to one specific bucket:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "ListBucket",
         "Effect": "Allow",
         "Action": ["s3:ListBucket"],
         "Resource": "arn:aws:s3:::my-app-bucket"
       },
       {
         "Sid": "ReadObjects",
         "Effect": "Allow",
         "Action": ["s3:GetObject"],
         "Resource": "arn:aws:s3:::my-app-bucket/*"
       }
     ]
   }
   ```
3. Click **Next**
4. Name: `S3ReadOnly-MyAppBucket`
5. Description: `Read-only access to my-app-bucket for the reporting team`
6. Click **Create policy**
7. Attach this policy to the relevant group (repeat Step 3's "attach policy" action) or directly to a role (see Step 7)

### Policy Structure Reference

| Element | Purpose |
|---|---|
| `Version` | Policy language version — always `"2012-10-17"` |
| `Effect` | `Allow` or `Deny` |
| `Action` | The API action(s) permitted/denied |
| `Resource` | The ARN(s) the action applies to |
| `Condition` | (Optional) Restricts when the rule applies, e.g., IP range, MFA presence |

---

## Step 7: Create an IAM Role (For AWS Services)

Roles provide temporary credentials — used by EC2, Lambda, or other AWS services, or for cross-account access. Never use long-term access keys for service-to-service access when a role will work.

1. Left sidebar → **Roles** → **Create role**
2. **Select trusted entity type**:
   - **AWS service** (e.g., EC2, Lambda) — for a service to assume the role
   - **AWS account** — for cross-account access
   - **Web identity** — for federated login (Google, Cognito, etc.)
   - **SAML 2.0 federation** — for corporate SSO
3. For an EC2 role example:
   - Select **AWS service** → **EC2** → **Next**
4. **Add permissions**:
   - Search and attach a policy, e.g., `AmazonS3ReadOnlyAccess` or your custom policy from Step 6
5. **Name, review, and create**:
   - Role name: `EC2-S3ReadOnly-Role`
   - Description: `Allows EC2 instances to read from S3 buckets`
   - Click **Create role**
6. To attach this role to a running EC2 instance:
   - EC2 Console → select instance → **Actions** → **Security** → **Modify IAM role** → select `EC2-S3ReadOnly-Role` → **Update IAM role**

---

## Step 8: Set Up an Account-Wide Password Policy

1. IAM Dashboard → **Account settings** (left sidebar)
2. Under **Password policy**, click **Edit**
3. Recommended settings:

| Setting | Recommended Value |
|---|---|
| Minimum password length | 14 |
| Require uppercase letters | Yes |
| Require lowercase letters | Yes |
| Require numbers | Yes |
| Require non-alphanumeric characters | Yes |
| Enable password expiration | 90 days |
| Prevent password reuse | Last 5 passwords |
| Allow users to change their own password | Yes |

4. Click **Save changes**

---

## Step 9: Create Access Keys (Only If Programmatic Access Is Needed)

Avoid long-lived access keys where possible — prefer IAM roles (Step 7) for applications, and short-term credentials via AWS CLI/SSO for humans.

1. **Users** → select the user → **Security credentials** tab
2. Under **Access keys**, click **Create access key**
3. Select the use case (e.g., **Command Line Interface (CLI)**)
4. Acknowledge the recommendation to use IAM roles instead, if applicable
5. Click **Create access key**
6. **Download the .csv** file — the secret key is shown **only once**
7. Configure locally:
   ```bash
   aws configure
   # AWS Access Key ID: <paste>
   # AWS Secret Access Key: <paste>
   # Default region name: ap-south-1
   # Default output format: json
   ```

> **Rotate access keys regularly** (every 90 days) and delete unused ones immediately via **Security credentials** → **Deactivate/Delete**.

---

## Step 10: Enable IAM Access Analyzer (Recommended)

Detects resources (S3 buckets, IAM roles, KMS keys, etc.) shared with external entities.

1. Left sidebar → **Access Analyzer** → **Create analyzer**
2. Name: `account-analyzer`
3. Zone of trust: **Current account** (or organization, if using AWS Organizations)
4. Click **Create analyzer**
5. Review findings periodically under **Access Analyzer** → **Findings**

---

## Step 11: Enable CloudTrail for Auditing (Recommended)

IAM changes and API calls should be logged for security auditing.

1. Search for **CloudTrail** in the console
2. **Create trail** → name it `management-events-trail`
3. Apply to **all regions**
4. Choose an S3 bucket for log storage (create new or use existing)
5. Click **Create trail**
6. Use **Event history** to review who made IAM changes and when

---

## Step 12: Verification Checklist

- [ ] Root account has MFA enabled and is not used for daily tasks
- [ ] No access keys exist for the root user
- [ ] IAM groups created per function (Admins, Developers, ReadOnly, etc.)
- [ ] Users added to groups — not attached to policies directly
- [ ] MFA enabled for all IAM users, especially those with console access
- [ ] Custom least-privilege policies created instead of relying solely on broad AWS-managed policies
- [ ] IAM roles used for EC2/Lambda/service access instead of embedded access keys
- [ ] Account password policy meets organizational security standards
- [ ] Access keys rotated regularly; unused ones deleted
- [ ] IAM Access Analyzer enabled and findings reviewed
- [ ] CloudTrail logging enabled for auditing

---

## Quick Reference Summary

| Component | Purpose |
|---|---|
| IAM User | Represents a person or application with long-term credentials |
| IAM Group | Collection of users sharing the same permissions |
| IAM Policy | JSON document defining allowed/denied actions on resources |
| IAM Role | Temporary credentials assumed by services, accounts, or federated identities |
| MFA | Extra authentication factor beyond password |
| Access Key | Programmatic (CLI/SDK) credential pair — use sparingly |
| Access Analyzer | Detects unintended external resource sharing |
| CloudTrail | Logs all API activity for auditing |

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| `AccessDenied` errors despite policy attached | Policy attached to wrong group/user, or explicit `Deny` elsewhere overriding | Check all attached policies; explicit `Deny` always wins over `Allow` |
| User can't log in to console | Console access wasn't enabled at creation | Edit user → enable console access, reset password |
| EC2 instance can't access S3 | No IAM role attached, or role lacks permissions | Attach role via EC2 console; verify policy resource ARNs match bucket |
| MFA device out of sync | Clock drift on authenticator app | Resync device time; if it fails, remove and re-add MFA device |

---

## Next Steps / Advanced Topics

- **AWS Organizations** — manage multiple AWS accounts centrally with Service Control Policies (SCPs)
- **IAM Identity Center (SSO)** — centralized login for multiple accounts, replacing individual IAM users for humans
- **Permission boundaries** — cap the maximum permissions a user/role can ever have, even if a policy grants more
- **Tag-based access control (ABAC)** — grant permissions dynamically based on resource tags
- **Infrastructure as Code** — manage IAM users, groups, and policies via Terraform or AWS CloudFormation for consistency and version control


---

<a id="chapter-2-vpc"></a>

# Creating a VPC in AWS — Complete Step-by-Step Guide

A Virtual Private Cloud (VPC) is an isolated virtual network within AWS where you launch resources like EC2 instances, RDS databases, and Lambda functions. This guide walks through building a **production-style VPC** with public and private subnets across multiple Availability Zones (AZs), internet access, NAT for private resources, and proper security controls.

---

## Architecture Overview

```
                              Internet
                                 │
                          Internet Gateway
                                 │
        ┌────────────────────────────────────────────┐
        │                    VPC (10.0.0.0/16)         │
        │                                              │
        │  AZ-a                        AZ-b            │
        │  ┌────────────┐              ┌────────────┐  │
        │  │ Public      │              │ Public      │  │
        │  │ 10.0.1.0/24 │              │ 10.0.3.0/24 │  │
        │  │  [NAT GW]   │              │             │  │
        │  └─────┬───────┘              └─────┬───────┘  │
        │        │                            │          │
        │  ┌─────▼───────┐              ┌─────▼───────┐  │
        │  │ Private     │              │ Private     │  │
        │  │ 10.0.2.0/24 │              │ 10.0.4.0/24 │  │
        │  └─────────────┘              └─────────────┘  │
        └──────────────────────────────────────────────┘
```

---

## Prerequisites

- An active AWS account with billing enabled
- IAM user/role with `AmazonVPCFullAccess` (or admin) permissions
- Basic understanding of CIDR notation (e.g., `10.0.0.0/16` = 65,536 IPs)
- Decide your region ahead of time (e.g., `us-east-1`, `ap-south-1`) — VPCs are region-scoped and cannot span regions

### CIDR Planning Reference

| CIDR | Total IPs | Usable IPs (AWS reserves 5) |
|---|---|---|
| /16 | 65,536 | 65,531 |
| /24 | 256 | 251 |
| /28 | 16 | 11 |

> **Tip:** Plan your IP ranges before starting. Avoid overlapping with any existing VPCs you may later peer with, or with your on-premises network if using VPN/Direct Connect.

---

## Step 1: Sign In and Select Region

1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in with your IAM credentials (avoid root account for daily operations)
3. In the top-right corner, click the **region dropdown** and select your target region (e.g., `Asia Pacific (Mumbai) ap-south-1`)
4. Confirm the region — all subsequent resources will be created here

---

## Step 2: Open the VPC Dashboard

1. Click the **search bar** at the top of the console
2. Type `VPC` and select **VPC** from the results
3. You'll land on the **VPC Dashboard**, showing existing VPCs, subnets, route tables, etc.
4. Note the **"Resources by Region"** panel — useful to confirm you're not duplicating existing resources

---

## Step 3: Create the VPC

1. In the left sidebar, click **Your VPCs** → **Create VPC**
2. Choose the creation method:
   - **VPC only** — manual control over every component (recommended for learning/production customization)
   - **VPC and more** — AWS auto-generates subnets, route tables, NAT gateways, and endpoints
3. For manual setup, configure:

| Field | Value | Notes |
|---|---|---|
| Name tag | `prod-vpc` | Helps identify in console |
| IPv4 CIDR block | `10.0.0.0/16` | Provides 65,536 IPs |
| IPv6 CIDR block | No IPv6 CIDR block | Enable only if you need IPv6 |
| Tenancy | Default | "Dedicated" costs extra, isolates hardware |

4. Click **Create VPC**
5. Confirm the VPC appears in **Your VPCs** with state `Available`

---

## Step 4: Create Subnets (Multi-AZ)

Subnets divide your VPC's CIDR range across Availability Zones for high availability.

1. Left sidebar → **Subnets** → **Create subnet**
2. Select your VPC (`prod-vpc`)
3. Add each subnet individually:

| Subnet Name | AZ | CIDR Block | Type |
|---|---|---|---|
| `public-subnet-a` | ap-south-1a | 10.0.1.0/24 | Public |
| `private-subnet-a` | ap-south-1a | 10.0.2.0/24 | Private |
| `public-subnet-b` | ap-south-1b | 10.0.3.0/24 | Public |
| `private-subnet-b` | ap-south-1b | 10.0.4.0/24 | Private |

4. Click **Add new subnet** for each row, fill details, then click **Create subnet**
5. **Enable auto-assign public IP** for public subnets:
   - Select `public-subnet-a` → **Actions** → **Edit subnet settings**
   - Check **Enable auto-assign public IPv4 address** → **Save**
   - Repeat for `public-subnet-b`

---

## Step 5: Create and Attach an Internet Gateway (IGW)

The IGW allows communication between your VPC and the internet.

1. Left sidebar → **Internet Gateways** → **Create internet gateway**
2. Name tag: `prod-igw`
3. Click **Create internet gateway**
4. Select it → **Actions** → **Attach to VPC**
5. Choose `prod-vpc` → **Attach internet gateway**
6. Confirm state changes to `Attached`

---

## Step 6: Configure Route Tables

### 6a. Public Route Table

1. Left sidebar → **Route Tables** → **Create route table**
2. Name: `public-rt`, VPC: `prod-vpc` → **Create**
3. Select `public-rt` → **Routes** tab → **Edit routes**
4. **Add route**:
   - Destination: `0.0.0.0/0`
   - Target: **Internet Gateway** → select `prod-igw`
5. **Save changes**
6. Go to **Subnet associations** tab → **Edit subnet associations**
7. Check `public-subnet-a` and `public-subnet-b` → **Save**

### 6b. Private Route Table

1. **Create route table** again
2. Name: `private-rt`, VPC: `prod-vpc` → **Create**
3. Leave routes as default (local only) for now — NAT route added in Step 7
4. **Subnet associations** → associate `private-subnet-a` and `private-subnet-b`

---

## Step 7: Create a NAT Gateway (for Private Subnet Internet Access)

Private subnet resources (e.g., app servers, databases) need outbound-only internet access for updates, without being publicly reachable.

1. Left sidebar → **NAT Gateways** → **Create NAT gateway**
2. Configure:
   - Name: `prod-nat-gw`
   - Subnet: **must be a public subnet** (e.g., `public-subnet-a`)
   - Connectivity type: **Public**
   - Elastic IP: click **Allocate Elastic IP** → select the new EIP
3. Click **Create NAT gateway**
4. Wait for state to become `Available` (takes a few minutes)
5. Go back to **Route Tables** → select `private-rt` → **Edit routes**
6. **Add route**:
   - Destination: `0.0.0.0/0`
   - Target: **NAT Gateway** → select `prod-nat-gw`
7. **Save changes**

> **Cost note:** NAT Gateways incur hourly charges plus data processing fees. For dev/test environments, consider a NAT instance (EC2-based) instead to save cost.

---

## Step 8: Configure Security Groups

Security groups act as virtual firewalls at the instance level (stateful).

1. Left sidebar → **Security Groups** → **Create security group**
2. Configure:
   - Name: `web-sg`
   - Description: `Allow HTTP/HTTPS/SSH`
   - VPC: `prod-vpc`
3. **Inbound rules** — click **Add rule** for each:

| Type | Protocol | Port Range | Source | Purpose |
|---|---|---|---|---|
| HTTP | TCP | 80 | 0.0.0.0/0 | Public web traffic |
| HTTPS | TCP | 443 | 0.0.0.0/0 | Secure web traffic |
| SSH | TCP | 22 | Your IP/32 | Admin access only |

4. **Outbound rules**: leave default (all traffic allowed) unless you need restrictions
5. Click **Create security group**
6. Repeat for a `db-sg` restricting inbound to only the `web-sg` on the database port (e.g., 3306 for MySQL)

---

## Step 9: Configure Network ACLs (Optional, Extra Layer)

NACLs are stateless, subnet-level firewalls — an additional layer beyond security groups.

1. Left sidebar → **Network ACLs** → **Create network ACL**
2. Name: `prod-nacl`, VPC: `prod-vpc`
3. Associate with your subnets under **Subnet associations**
4. Define inbound/outbound rules with rule numbers (evaluated in order, lowest first)

> Most setups rely on Security Groups alone; NACLs are useful for blocking specific malicious IP ranges at the subnet level.

---

## Step 10: Set Up VPC Endpoints (Optional but Recommended)

Avoid routing traffic to AWS services (like S3, DynamoDB) through the public internet/NAT — reduces cost and latency.

1. Left sidebar → **Endpoints** → **Create endpoint**
2. Service category: **AWS services**
3. Search for `s3` → select **Gateway** type endpoint
4. Select `prod-vpc`
5. Select route tables to associate (`private-rt`, `public-rt`)
6. Click **Create endpoint**

---

## Step 11: Launch a Test EC2 Instance to Validate

1. Go to **EC2 Dashboard** → **Launch instance**
2. Choose an AMI (e.g., Amazon Linux 2023)
3. Instance type: `t2.micro` (free tier eligible)
4. Network settings:
   - VPC: `prod-vpc`
   - Subnet: `public-subnet-a`
   - Auto-assign public IP: **Enable**
   - Security group: `web-sg`
5. Configure key pair for SSH access
6. Click **Launch instance**
7. Once running, test connectivity:
   ```bash
   ssh -i your-key.pem ec2-user@<public-ip>
   ```
8. To verify private subnet + NAT setup, launch a second instance in `private-subnet-a` (no public IP) and confirm it can reach the internet (e.g., `curl https://amazon.com`) via a bastion host or Session Manager, but is not directly reachable from outside

---

## Step 12: Verification Checklist

- [ ] VPC shows `Available` state with correct CIDR
- [ ] All 4 subnets created and mapped to correct AZs
- [ ] Internet Gateway attached to VPC
- [ ] Public route table has `0.0.0.0/0 → IGW` and is associated with public subnets
- [ ] Private route table has `0.0.0.0/0 → NAT Gateway` and is associated with private subnets
- [ ] NAT Gateway state is `Available`
- [ ] Security groups restrict SSH to known IPs only
- [ ] Test EC2 instance in public subnet is internet-reachable
- [ ] Test instance in private subnet has outbound-only access

---

## Cleanup (To Avoid Ongoing Charges)

If this was for testing/learning, delete resources in this order:

1. Terminate EC2 instances
2. Delete NAT Gateway (releases the Elastic IP association)
3. Release the Elastic IP
4. Detach and delete the Internet Gateway
5. Delete subnets
6. Delete route tables (except the default one, which is deleted with the VPC)
7. Delete the VPC

> NAT Gateways and Elastic IPs incur charges even when idle — always clean these up first.

---

## Quick Reference Summary

| Component | Purpose | Scope |
|---|---|---|
| VPC | Isolated virtual network | Regional |
| Subnet | Segments of VPC CIDR | AZ-specific |
| Internet Gateway | Public internet access | VPC-attached |
| NAT Gateway | Outbound-only access for private subnets | Subnet-placed |
| Route Table | Directs traffic based on destination | Subnet-associated |
| Security Group | Instance-level stateful firewall | Instance-attached |
| Network ACL | Subnet-level stateless firewall | Subnet-associated |
| VPC Endpoint | Private access to AWS services | VPC-attached |

---

## Next Steps / Advanced Topics

- **VPC Peering** — connect two VPCs privately
- **Transit Gateway** — hub-and-spoke connectivity for many VPCs
- **VPN/Direct Connect** — hybrid connectivity to on-premises networks
- **Flow Logs** — enable for traffic monitoring and troubleshooting
- **Infrastructure as Code** — replicate this setup using Terraform or AWS CloudFormation for repeatability

---

<a id="chapter-3-ec2"></a>

# Launching an EC2 Instance in AWS — Complete Step-by-Step Guide

Amazon EC2 (Elastic Compute Cloud) provides resizable virtual servers in the cloud. This guide covers launching an instance into an existing VPC, securing it properly, connecting to it, and cleaning it up afterward.

> **Prerequisite:** A VPC with at least one public subnet (see the companion *AWS VPC Creation Guide*). If you don't have one, AWS will use your account's **default VPC**, which already has public subnets and an internet gateway pre-configured.

---

## Architecture Overview

```
                     Internet
                        │
                 Internet Gateway
                        │
        ┌───────────────────────────────┐
        │         VPC (10.0.0.0/16)      │
        │                                │
        │   Public Subnet (10.0.1.0/24)  │
        │   ┌─────────────────────────┐  │
        │   │   EC2 Instance          │  │
        │   │   - Public IP           │  │
        │   │   - Security Group      │  │
        │   │   - Key Pair (SSH)      │  │
        │   └─────────────────────────┘  │
        └───────────────────────────────┘
```

---

## Prerequisites

- Active AWS account with billing enabled
- IAM user/role with `AmazonEC2FullAccess` (or admin) permissions
- A VPC and public subnet (existing or default)
- An SSH client (Terminal on Mac/Linux, PuTTY or Windows Terminal on Windows)

---

## Step 1: Sign In and Select Region

1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in with IAM credentials (avoid using the root account)
3. Select your target **region** from the top-right dropdown (e.g., `Asia Pacific (Mumbai) ap-south-1`)
4. Confirm the region — EC2 instances, key pairs, and security groups are all region-specific

---

## Step 2: Open the EC2 Dashboard

1. Click the **search bar** at the top of the console
2. Type `EC2` and select **EC2** from the results
3. You'll land on the **EC2 Dashboard**, showing running instances, resource counts, and service health

---

## Step 3: Create a Key Pair (If You Don't Have One)

A key pair is used to securely SSH into your instance (Linux) or decrypt the admin password (Windows).

1. Left sidebar → **Network & Security** → **Key Pairs** → **Create key pair**
2. Configure:

| Field | Value | Notes |
|---|---|---|
| Name | `my-ec2-key` | Identifiable name |
| Key pair type | RSA | ED25519 also supported |
| Private key format | `.pem` (Mac/Linux/OpenSSH) or `.ppk` (PuTTY on Windows) | |

3. Click **Create key pair**
4. The private key file downloads automatically — **save it securely; it cannot be re-downloaded**
5. On Mac/Linux, restrict permissions:
   ```bash
   chmod 400 my-ec2-key.pem
   ```

---

## Step 4: Launch an Instance

1. From the EC2 Dashboard, click **Launch instance**
2. **Name and tags**:
   - Name: `web-server-01`
   - (Optional) Add tags like `Environment: Production`

### 4a. Choose an Amazon Machine Image (AMI)

| AMI | Use Case | Free Tier |
|---|---|---|
| Amazon Linux 2023 | General purpose, AWS-optimized | Yes |
| Ubuntu Server 24.04 LTS | Popular for web apps | Yes |
| Windows Server 2022 | .NET / Windows workloads | Yes (limited) |
| Red Hat Enterprise Linux | Enterprise workloads | No |

Select **Amazon Linux 2023 AMI** for this guide.

### 4b. Choose an Instance Type

| Instance Type | vCPU | Memory | Use Case |
|---|---|---|---|
| t2.micro | 1 | 1 GiB | Free tier, testing |
| t3.medium | 2 | 4 GiB | Small production workloads |
| m5.large | 2 | 8 GiB | General purpose production |

Select **t2.micro** (free tier eligible).

### 4c. Key Pair

- Select the key pair created in Step 3 (`my-ec2-key`)
- If you skip this, you won't be able to SSH into the instance later

### 4d. Network Settings

Click **Edit** next to Network settings to expand full control:

| Field | Value | Notes |
|---|---|---|
| VPC | `prod-vpc` (or default) | Must match your target VPC |
| Subnet | `public-subnet-a` | Use a **public** subnet |
| Auto-assign public IP | **Enable** | Required for direct internet access |
| Firewall (security group) | Create new security group | See Step 4e |

### 4e. Configure Security Group

1. Select **Create security group**
2. Name: `web-sg`
3. Description: `Allow SSH, HTTP, HTTPS`
4. Add inbound rules:

| Type | Protocol | Port | Source | Purpose |
|---|---|---|---|---|
| SSH | TCP | 22 | My IP | Admin access only |
| HTTP | TCP | 80 | 0.0.0.0/0 | Public web traffic |
| HTTPS | TCP | 443 | 0.0.0.0/0 | Secure web traffic |

> **Security best practice:** Never set SSH source to `0.0.0.0/0` in production — restrict to your IP or a bastion host/VPN range.

### 4f. Configure Storage

1. Default: `8 GiB gp3` root volume (sufficient for testing)
2. Adjust size if needed (e.g., `20 GiB` for application workloads)
3. Volume type options:

| Type | Use Case |
|---|---|
| gp3 | General purpose SSD (recommended default) |
| io2 | High-performance, low-latency (databases) |
| st1 | Throughput-optimized HDD (big data) |

### 4g. Advanced Details (Optional)

- **IAM instance profile**: attach an IAM role if the instance needs to call other AWS services (e.g., S3 access)
- **User data**: add a bootstrap script to run on first boot, e.g.:
  ```bash
  #!/bin/bash
  yum update -y
  yum install -y httpd
  systemctl start httpd
  systemctl enable httpd
  echo "<h1>Hello from EC2</h1>" > /var/www/html/index.html
  ```
  This automatically installs and starts a web server on launch.

### 4h. Review and Launch

1. Review the **Summary** panel on the right (instance count, AMI, type, storage, security group)
2. Set **Number of instances**: `1`
3. Click **Launch instance**
4. Click **View all instances** to go to the instance list

---

## Step 5: Verify Instance Status

1. In the **Instances** view, locate `web-server-01`
2. Wait for:
   - **Instance state**: `Running`
   - **Status check**: `2/2 checks passed` (may take 1–2 minutes)
3. Note the **Public IPv4 address** and **Public IPv4 DNS** from the details pane

---

## Step 6: Connect to the Instance

### Option A: SSH (Mac/Linux/Windows Terminal)

```bash
ssh -i my-ec2-key.pem ec2-user@<public-ip-or-dns>
```

- Username depends on AMI: `ec2-user` (Amazon Linux/RHEL), `ubuntu` (Ubuntu), `admin` (Debian)

### Option B: EC2 Instance Connect (Browser-Based, No Key Needed Locally)

1. Select the instance in the console
2. Click **Connect** → **EC2 Instance Connect** tab
3. Click **Connect** — opens a browser-based terminal session

### Option C: Session Manager (No Open SSH Port Required)

1. Requires the **SSM Agent** (pre-installed on Amazon Linux) and an IAM role with `AmazonSSMManagedInstanceCore` attached to the instance
2. Select the instance → **Connect** → **Session Manager** tab → **Connect**
3. This method works even with **no inbound SSH rule at all** — more secure for production

---

## Step 7: Verify the Web Server (If User Data Script Was Used)

1. Open a browser and navigate to:
   ```
   http://<public-ip-or-dns>
   ```
2. You should see **"Hello from EC2"** if the Apache user data script ran successfully
3. If not loading, check:
   - Security group allows inbound port 80
   - Instance status checks passed
   - `systemctl status httpd` on the instance (via SSH) to confirm the service is running

---

## Step 8: Allocate an Elastic IP (Optional, for a Static IP)

By default, the public IP changes if the instance is stopped and restarted. Use an Elastic IP for a permanent address.

1. Left sidebar → **Network & Security** → **Elastic IPs** → **Allocate Elastic IP address**
2. Click **Allocate**
3. Select the new EIP → **Actions** → **Associate Elastic IP address**
4. Choose the instance `web-server-01` → **Associate**

> **Cost note:** Elastic IPs are free while associated with a running instance, but incur charges if left unassociated.

---

## Step 9: Set Up Monitoring and Alarms (Optional but Recommended)

1. Select the instance → **Monitoring** tab to view CPU, network, and disk metrics
2. To set an alarm: **Actions** → **Monitor and troubleshoot** → **Manage CloudWatch alarms**
3. Example: create a **CPU Utilization > 80%** alarm to get notified of high load

---

## Step 10: Verification Checklist

- [ ] Key pair created and stored securely
- [ ] Instance launched in the correct VPC and public subnet
- [ ] Security group allows only necessary inbound ports
- [ ] Instance state is `Running` with `2/2` status checks passed
- [ ] Successfully connected via SSH / Instance Connect / Session Manager
- [ ] (If applicable) Web server accessible via public IP/DNS
- [ ] Elastic IP associated (if static IP required)
- [ ] CloudWatch alarms configured for monitoring

---

## Cleanup (To Avoid Ongoing Charges)

1. Disassociate and release the Elastic IP (if allocated):
   - **Elastic IPs** → select → **Actions** → **Release Elastic IP address**
2. Terminate the instance:
   - Select instance → **Instance state** → **Terminate instance**
3. Delete the security group (if no longer needed):
   - **Security Groups** → select `web-sg` → **Actions** → **Delete security group**
4. Delete the key pair (if no longer needed):
   - **Key Pairs** → select → **Actions** → **Delete**

> Stopped instances still incur EBS storage charges — terminate instances you no longer need rather than just stopping them.

---

## Quick Reference Summary

| Component | Purpose |
|---|---|
| AMI | Template with OS and pre-installed software |
| Instance Type | Defines vCPU, memory, and network performance |
| Key Pair | SSH authentication credential |
| Security Group | Instance-level firewall (stateful) |
| Elastic IP | Static public IP address |
| User Data | Bootstrap script run on first launch |
| EBS Volume | Persistent block storage attached to instance |

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| `Connection timed out` on SSH | Security group blocks port 22, or instance in private subnet | Allow port 22 from your IP; confirm public subnet + public IP |
| `Permission denied (publickey)` | Wrong username or incorrect key file | Match username to AMI type; verify `.pem` file matches key pair |
| Website not loading | Port 80 not open, or web server not running | Check security group rules; SSH in and check `systemctl status httpd` |
| Instance stuck in `pending` | Rare AWS-side capacity issue | Wait a few minutes or try a different AZ/instance type |

---

## Next Steps / Advanced Topics

- **Auto Scaling Groups** — automatically scale instances based on demand
- **Elastic Load Balancer (ELB)** — distribute traffic across multiple instances
- **AMI creation** — create a custom AMI from a configured instance for repeatable deployments
- **IAM Roles for EC2** — grant instances secure access to other AWS services without hardcoding credentials
- **Infrastructure as Code** — replicate this setup using Terraform or AWS CloudFormation


---

<a id="chapter-4-s3"></a>

# Creating an S3 Bucket in AWS — Complete Step-by-Step Guide

Amazon S3 (Simple Storage Service) is an object storage service used for backups, static websites, data lakes, application assets, and more. This guide covers creating a secure bucket, configuring access, enabling versioning/encryption, and setting up lifecycle rules.

---

## Architecture Overview

```
                     Applications / Users
                              │
                    IAM Policy / Bucket Policy
                              │
                    ┌─────────────────────┐
                    │   S3 Bucket          │
                    │   my-app-bucket      │
                    │                      │
                    │  ┌────────────────┐  │
                    │  │ Objects/Files   │  │
                    │  │ (Versioned)     │  │
                    │  └────────────────┘  │
                    │                      │
                    │  Encryption: SSE-S3  │
                    │  Lifecycle Rules     │
                    │  Logging Enabled     │
                    └─────────────────────┘
```

---

## Prerequisites

- Active AWS account
- IAM user/role with `AmazonS3FullAccess` (or scoped equivalent) permissions
- Decide on a **globally unique** bucket name (S3 bucket names are unique across **all** AWS accounts, not just yours)

### S3 Bucket Naming Rules

| Rule | Detail |
|---|---|
| Length | 3–63 characters |
| Characters | Lowercase letters, numbers, hyphens, dots only |
| Format | Must start and end with a letter or number |
| Uniqueness | Globally unique across all AWS accounts/regions |
| Restrictions | Cannot look like an IP address (e.g., `192.168.1.1`) |

---

## Step 1: Sign In and Select Region

1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in with IAM credentials
3. Select your target **region** (e.g., `Asia Pacific (Mumbai) ap-south-1`)

> Note: S3 bucket **names** are global, but the bucket itself is created in a specific region — choose one close to your users/application for lower latency.

---

## Step 2: Open the S3 Console

1. In the search bar, type `S3` and select **S3**
2. You'll land on the **S3 Dashboard**, listing existing buckets across regions

---

## Step 3: Create the Bucket

1. Click **Create bucket**
2. **General configuration**:

| Field | Value | Notes |
|---|---|---|
| Bucket name | `my-app-bucket-prod-2026` | Must be globally unique |
| AWS Region | `ap-south-1` | Choose based on latency/compliance needs |
| Copy settings from existing bucket | (optional) | Skip for a fresh setup |

3. **Object Ownership**:
   - Select **ACLs disabled (recommended)** — bucket owner has full control, simplifies permission management
   - Only choose "ACLs enabled" if you have a specific legacy cross-account use case

4. **Block Public Access settings**:
   - Keep **all four checkboxes enabled** (default) unless you specifically need public access (e.g., static website hosting)
   - This is the single most important setting to prevent accidental data exposure

5. **Bucket Versioning**:
   - Select **Enable** (recommended) — protects against accidental deletes/overwrites by keeping object history

6. **Tags** (optional):
   - Add tags like `Environment: Production`, `Team: Backend`

7. **Default encryption**:
   - Encryption type: **SSE-S3** (Amazon S3-managed keys) — simplest, no extra cost
   - Or **SSE-KMS** (AWS Key Management Service) — for auditability and control over key rotation/access, incurs KMS costs
   - **Bucket Key**: Enable (reduces KMS request costs when using SSE-KMS)

8. Review settings, then click **Create bucket**

---

## Step 4: Upload Objects

1. Click into your new bucket (`my-app-bucket-prod-2026`)
2. Click **Upload** → **Add files** or **Add folder**
3. Select files from your local machine
4. Expand **Properties** to review:
   - Storage class (default: **Standard**)
   - Encryption settings (inherits bucket default, or override per-object)
5. Click **Upload**
6. Confirm objects appear in the bucket listing with a green **Succeeded** status

### Storage Class Reference

| Storage Class | Use Case | Retrieval |
|---|---|---|
| S3 Standard | Frequently accessed data | Immediate |
| S3 Intelligent-Tiering | Unknown/changing access patterns | Immediate |
| S3 Standard-IA | Infrequent access, needs fast retrieval | Immediate |
| S3 One Zone-IA | Infrequent, non-critical, recreatable data | Immediate |
| S3 Glacier Instant Retrieval | Archive, needs millisecond access | Immediate |
| S3 Glacier Flexible Retrieval | Archive, retrieval in minutes/hours OK | Minutes–hours |
| S3 Glacier Deep Archive | Long-term archive, rarely accessed | Hours |

---

## Step 5: Configure Bucket Policy (Fine-Grained Access Control)

Bucket policies define who can access the bucket and its objects, at the resource level.

1. Select the bucket → **Permissions** tab
2. Scroll to **Bucket policy** → **Edit**
3. Example — allow a specific IAM role read access only:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "AllowAppRoleRead",
         "Effect": "Allow",
         "Principal": {
           "AWS": "arn:aws:iam::123456789012:role/EC2-S3ReadOnly-Role"
         },
         "Action": ["s3:GetObject"],
         "Resource": "arn:aws:s3:::my-app-bucket-prod-2026/*"
       }
     ]
   }
   ```
4. Click **Save changes**

> **Never** use `"Principal": "*"` with broad actions unless you explicitly intend the bucket (or specific prefix) to be public — double-check against Block Public Access settings, which override policies by default.

---

## Step 6: Enable Server Access Logging (Optional, Recommended for Audit)

1. Select the bucket → **Properties** tab
2. Scroll to **Server access logging** → **Edit**
3. Select **Enable**
4. Target bucket: choose a separate bucket (e.g., `my-app-bucket-logs`) to store access logs
5. Target prefix: `access-logs/`
6. Click **Save changes**

> Use a dedicated logging bucket, not the same bucket being logged, to avoid recursive log growth.

---

## Step 7: Configure Lifecycle Rules (Cost Optimization)

Automatically transition or expire objects to reduce storage costs.

1. Select the bucket → **Management** tab → **Create lifecycle rule**
2. Configure:
   - **Lifecycle rule name**: `archive-old-logs`
   - **Rule scope**: limit to a prefix (e.g., `logs/`) or apply to all objects
3. **Lifecycle rule actions**:
   - Check **Transition current versions of objects between storage classes**
     - Transition to **Standard-IA** after 30 days
     - Transition to **Glacier Deep Archive** after 180 days
   - Check **Expire current versions of objects**
     - Expire after 365 days (if applicable)
   - If versioning is enabled, also configure **noncurrent version transitions/expiration** to clean up old versions
4. Click **Create rule**

---

## Step 8: Set Up Cross-Region Replication (Optional, for DR)

Replicates objects to a bucket in another region for disaster recovery.

1. Requires **versioning enabled** on both source and destination buckets
2. Select the bucket → **Management** tab → **Create replication rule**
3. Configure:
   - Source: entire bucket or specific prefix
   - Destination: select/create a bucket in a different region
   - IAM role: let AWS create one automatically
4. Click **Save**

---

## Step 9: Enable Static Website Hosting (Optional)

Only if this bucket serves public static content (HTML/CSS/JS).

1. Select the bucket → **Properties** tab → **Static website hosting** → **Edit**
2. Select **Enable**
3. Hosting type: **Host a static website**
4. Index document: `index.html`
5. Error document: `error.html`
6. Click **Save changes**
7. **Disable Block Public Access** (Step 3's setting) — required for public website access
8. Add a bucket policy allowing public `GetObject`:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "PublicReadGetObject",
         "Effect": "Allow",
         "Principal": "*",
         "Action": "s3:GetObject",
         "Resource": "arn:aws:s3:::my-app-bucket-prod-2026/*"
       }
     ]
   }
   ```
9. Access via the **Bucket website endpoint** shown in the Static website hosting panel

> For production static sites, front the bucket with **CloudFront** (CDN) instead of exposing the S3 endpoint directly — provides HTTPS, caching, and custom domains.

---

## Step 10: Verification Checklist

- [ ] Bucket name is globally unique and follows naming rules
- [ ] Block Public Access enabled (unless intentionally hosting public content)
- [ ] Versioning enabled for accidental-delete protection
- [ ] Default encryption configured (SSE-S3 or SSE-KMS)
- [ ] Bucket policy follows least-privilege (no unintended `Principal: *`)
- [ ] Server access logging enabled to a separate logging bucket
- [ ] Lifecycle rules configured for cost optimization
- [ ] (If applicable) Static website hosting configured with correct index/error documents
- [ ] (If applicable) CloudFront distribution set up in front of the bucket

---

## Cleanup (To Avoid Ongoing Charges)

1. Empty the bucket first (S3 won't delete a non-empty bucket):
   - Select bucket → **Empty** → type `permanently delete` to confirm
   - If versioning was enabled, this also removes all object versions
2. Delete the bucket:
   - Select bucket → **Delete** → type the bucket name to confirm
3. Delete any associated logging bucket if no longer needed
4. Remove any CloudFront distribution pointing to the bucket

---

## Quick Reference Summary

| Component | Purpose |
|---|---|
| Bucket | Top-level container for objects |
| Object | Individual file stored in S3 |
| Versioning | Keeps history of object changes/deletes |
| Bucket Policy | Resource-based access control (JSON) |
| Block Public Access | Account/bucket-level guardrail against accidental exposure |
| Storage Class | Cost/performance tier for stored objects |
| Lifecycle Rule | Automated transition/expiration of objects |
| Replication | Copies objects to another bucket/region |
| Server Access Logging | Records all requests made to the bucket |

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| `Access Denied` on upload/download | Missing IAM permission or restrictive bucket policy | Check both IAM policy and bucket policy — both must allow the action |
| Public website returns 403 | Block Public Access still enabled | Disable Block Public Access and confirm bucket policy allows `GetObject` |
| Bucket name unavailable | Name already taken globally | Choose a more unique name (add account ID, date, or random suffix) |
| Lifecycle rule not transitioning objects | Minimum storage duration not met, or rule filter/prefix mismatch | Verify object age meets transition minimums; check prefix filter |
| Replication not happening | Versioning not enabled on source/destination | Enable versioning on both buckets before creating replication rule |

---

## Next Steps / Advanced Topics

- **S3 Object Lock** — WORM (write-once-read-many) protection for compliance requirements
- **S3 Access Points** — simplify access management for shared datasets with multiple applications
- **CloudFront + S3** — serve content globally with a CDN, custom domain, and HTTPS
- **S3 Event Notifications** — trigger Lambda functions or SQS/SNS on object upload/delete
- **Infrastructure as Code** — manage buckets, policies, and lifecycle rules via Terraform or AWS CloudFormation


---

<a id="chapter-5-rds"></a>

# Creating an RDS Database in AWS — Complete Step-by-Step Guide

Amazon RDS (Relational Database Service) provisions and manages relational databases (MySQL, PostgreSQL, MariaDB, Oracle, SQL Server, or Aurora) without manual server administration. This guide covers creating a secure, production-style instance inside a VPC, connecting to it, and enabling backups/monitoring.

---

## Architecture Overview

```
                         Application / EC2
                                │
                         Security Group
                          (db-sg: port 5432/3306)
                                │
        ┌───────────────────────────────────────┐
        │              VPC (10.0.0.0/16)          │
        │                                          │
        │   Private Subnet A      Private Subnet B │
        │   10.0.2.0/24           10.0.4.0/24       │
        │   ┌─────────────┐       ┌─────────────┐  │
        │   │  RDS Primary │◄─────►│ RDS Standby │  │
        │   │  (AZ-a)      │  Sync │  (AZ-b)      │  │
        │   └─────────────┘ Repl. └─────────────┘  │
        │       (Multi-AZ deployment)               │
        └───────────────────────────────────────┘
```

---

## Prerequisites

- Active AWS account
- IAM user/role with `AmazonRDSFullAccess` (or scoped equivalent) permissions
- An existing VPC with **at least two private subnets in different AZs** (RDS requires a DB subnet group spanning 2+ AZs, even for single-AZ deployments) — see the companion *AWS VPC Creation Guide*
- Decide on engine (PostgreSQL, MySQL, etc.) and whether you need Multi-AZ high availability

---

## Step 1: Sign In and Select Region

1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in with IAM credentials
3. Select your target **region** (e.g., `Asia Pacific (Mumbai) ap-south-1`)

---

## Step 2: Create a DB Subnet Group

RDS needs to know which subnets it's allowed to place database instances in.

1. In the search bar, type `RDS` and select **RDS**
2. Left sidebar → **Subnet groups** → **Create DB subnet group**
3. Configure:
   - **Name**: `prod-db-subnet-group`
   - **Description**: `Private subnets for production RDS`
   - **VPC**: select your VPC (`prod-vpc`)
4. **Add subnets**:
   - Availability Zones: select at least 2 (e.g., `ap-south-1a`, `ap-south-1b`)
   - Subnets: select your **private subnets** (`private-subnet-a`, `private-subnet-b`)
5. Click **Create**

---

## Step 3: Create a Security Group for the Database

1. Go to **VPC Console** → **Security Groups** → **Create security group**
2. Configure:
   - Name: `db-sg`
   - Description: `Allow DB access from app tier only`
   - VPC: `prod-vpc`
3. **Inbound rules**:

| Type | Protocol | Port | Source | Purpose |
|---|---|---|---|---|
| PostgreSQL | TCP | 5432 | `web-sg` (security group, not CIDR) | Allow only app servers |

   (Use port `3306` for MySQL/MariaDB, `1433` for SQL Server, `1521` for Oracle)

4. Leave outbound as default (all traffic allowed)
5. Click **Create security group**

> **Best practice:** Reference the **application's security group** as the source, not a CIDR range — this way access automatically follows whichever instances belong to that group.

---

## Step 4: Create the Database

1. Return to **RDS Console** → **Databases** → **Create database**
2. **Choose a database creation method**:
   - **Standard create** (full control — recommended)
   - **Easy create** (uses recommended defaults, less configurable)

3. **Engine options**:

| Engine | Use Case |
|---|---|
| PostgreSQL | Open-source, feature-rich, good default choice |
| MySQL | Widely used, broad tooling support |
| MariaDB | MySQL-compatible, open-source |
| Amazon Aurora | AWS-optimized, MySQL/PostgreSQL-compatible, higher performance |
| Oracle / SQL Server | Enterprise/legacy workloads (licensing costs apply) |

   Select **PostgreSQL**, version: latest stable (e.g., `16.x`)

4. **Templates**:
   - **Production** — Multi-AZ enabled by default, deletion protection on
   - **Dev/Test** — fewer defaults enabled
   - **Free tier** — eligible for AWS Free Tier (single-AZ, `db.t3.micro`, limited storage)

5. **Settings**:

| Field | Value | Notes |
|---|---|---|
| DB instance identifier | `prod-postgres-db` | Unique name within region |
| Master username | `dbadmin` | Avoid default names like `admin`/`root` |
| Credentials management | **Self managed** or **Managed in Secrets Manager** | Secrets Manager recommended — auto-rotates password |
| Master password | (auto-generated or custom, min 8 characters) | Store securely if self-managed |

6. **Instance configuration**:

| Field | Value | Notes |
|---|---|---|
| DB instance class | `db.t3.micro` (dev/test) or `db.m6g.large` (production) | Burstable (t-class) vs. standard (m-class) |

7. **Storage**:

| Field | Value | Notes |
|---|---|---|
| Storage type | General Purpose SSD (gp3) | Good default; io1/io2 for high-IOPS needs |
| Allocated storage | 20 GB (adjust per workload) | |
| Storage autoscaling | Enable, max threshold e.g. 100 GB | Prevents "disk full" outages |

8. **Availability & durability**:
   - **Multi-AZ deployment**: Enable for production (creates synchronous standby in a second AZ, automatic failover)
   - Single-AZ acceptable for dev/test to save cost

9. **Connectivity**:

| Field | Value | Notes |
|---|---|---|
| Compute resource | Don't connect to an EC2 compute resource (unless using RDS Proxy setup wizard) | |
| VPC | `prod-vpc` | |
| DB subnet group | `prod-db-subnet-group` (from Step 2) | |
| Public access | **No** | Keep database in private subnet, unreachable from internet |
| VPC security group | Choose existing → `db-sg` (from Step 3) | |
| Availability Zone | No preference (or pick explicitly) | |
| Database port | `5432` (PostgreSQL default) | |

10. **Database authentication**:
    - **Password authentication** (standard)
    - Or **IAM database authentication** — lets IAM users/roles connect without a stored password (recommended for enhanced security)

11. **Additional configuration** (expand):

| Field | Value | Notes |
|---|---|---|
| Initial database name | `appdb` | Creates a default database on first launch |
| DB parameter group | Default (or custom for tuning) | |
| Backup retention period | 7 days (production) | Up to 35 days |
| Backup window | Choose low-traffic time | |
| Enable encryption | **Yes** | Uses AWS KMS; enable at creation — cannot be added retroactively |
| Enable Performance Insights | **Yes** (free tier: 7-day retention) | Useful for query performance troubleshooting |
| Enable auto minor version upgrade | **Yes** | Applies patches automatically during maintenance window |
| Deletion protection | **Enable** for production | Prevents accidental deletion |

12. Review the estimated monthly cost shown at the bottom
13. Click **Create database**
14. Status will show `Creating` → wait for `Available` (typically 5–15 minutes)

---

## Step 5: Retrieve Connection Details

1. Once status is `Available`, click into the database
2. Under **Connectivity & security** tab, note:
   - **Endpoint**: e.g., `prod-postgres-db.abc123xyz.ap-south-1.rds.amazonaws.com`
   - **Port**: `5432`
3. If using Secrets Manager, retrieve credentials:
   - **Secrets Manager** console → find the auto-created secret → **Retrieve secret value**

---

## Step 6: Connect to the Database

Since the database has **no public access**, you must connect from within the VPC — via an EC2 instance in the same VPC, a bastion host, or AWS Cloud9/Session Manager port forwarding.

### From an EC2 instance in the same VPC:

```bash
# Install PostgreSQL client (Amazon Linux)
sudo dnf install -y postgresql16

# Connect
psql -h prod-postgres-db.abc123xyz.ap-south-1.rds.amazonaws.com \
     -U dbadmin \
     -d appdb \
     -p 5432
```

Enter the master password when prompted.

### Using Session Manager Port Forwarding (No Bastion Needed):

```bash
aws ssm start-session \
  --target <ec2-instance-id> \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{"host":["prod-postgres-db.abc123xyz.ap-south-1.rds.amazonaws.com"],"portNumber":["5432"],"localPortNumber":["5432"]}'
```

Then connect to `localhost:5432` from your local machine.

---

## Step 7: Set Up Automated Backups & Snapshots

Automated backups are configured during creation (Step 4), but manual snapshots are useful before major changes.

1. Select the database → **Actions** → **Take snapshot**
2. Name: `prod-postgres-pre-migration-2026-07-31`
3. Click **Take snapshot**
4. To restore from a snapshot: **Snapshots** tab → select → **Actions** → **Restore snapshot** (creates a **new** DB instance)

---

## Step 8: Configure CloudWatch Monitoring & Alarms

1. Select the database → **Monitoring** tab to view CPU, storage, connections, IOPS
2. Set an alarm for critical metrics:
   - **CloudWatch** → **Alarms** → **Create alarm**
   - Metric: `FreeStorageSpace` for this DB instance
   - Threshold: e.g., alert if `< 2 GB` remaining
   - Notification: SNS topic (email/SMS)
3. Repeat for `CPUUtilization > 80%` and `DatabaseConnections` nearing max limit

---

## Step 9: Configure Read Replicas (Optional, for Read Scaling)

1. Select the database → **Actions** → **Create read replica**
2. Configure:
   - DB instance identifier: `prod-postgres-db-replica-1`
   - Instance class: same or smaller than primary
   - Can be in the **same region** or a **different region** (for DR/global read scaling)
3. Click **Create read replica**
4. Application read-only queries can now target the replica's endpoint to offload the primary

---

## Step 10: Verification Checklist

- [ ] DB subnet group spans at least 2 AZs using private subnets
- [ ] Security group restricts inbound DB port to application security group only
- [ ] Public access disabled
- [ ] Encryption at rest enabled (KMS)
- [ ] Multi-AZ enabled for production workloads
- [ ] Automated backups configured with adequate retention period
- [ ] Deletion protection enabled for production
- [ ] Performance Insights enabled for query visibility
- [ ] CloudWatch alarms set for storage, CPU, and connection count
- [ ] Successfully connected from an application/EC2 instance within the VPC
- [ ] Credentials stored in Secrets Manager, not hardcoded in application code

---

## Cleanup (To Avoid Ongoing Charges)

1. Disable deletion protection first (if enabled):
   - Select database → **Modify** → uncheck **Enable deletion protection** → **Continue** → **Apply immediately**
2. Delete the database:
   - Select database → **Actions** → **Delete**
   - Choose whether to create a **final snapshot** before deletion (recommended unless data is disposable)
   - Type `delete me` to confirm
3. Delete any read replicas separately
4. Delete manual snapshots if no longer needed: **Snapshots** tab → select → **Delete**
5. Delete the DB subnet group if unused by other databases

> RDS storage, backups beyond the free retention, and any Multi-AZ standby all incur ongoing charges until deleted.

---

## Quick Reference Summary

| Component | Purpose |
|---|---|
| DB Instance | The running database engine |
| DB Subnet Group | Defines which VPC subnets RDS can use |
| Security Group | Controls network access to the DB port |
| Multi-AZ | Synchronous standby replica for automatic failover |
| Read Replica | Asynchronous copy for scaling read traffic |
| Automated Backup | Point-in-time recovery within retention window |
| Manual Snapshot | On-demand backup, retained until explicitly deleted |
| Parameter Group | Engine configuration settings |
| Performance Insights | Query-level performance monitoring |

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| Connection timed out | Security group blocks the port, or instance not in same VPC | Verify `db-sg` allows inbound from the connecting resource's SG |
| `password authentication failed` | Wrong credentials, or using IAM auth incorrectly | Verify master password or IAM auth token generation |
| Storage full / performance degradation | Autoscaling not enabled, unexpected data growth | Enable storage autoscaling; review `FreeStorageSpace` metric |
| High latency / CPU spikes | Undersized instance class, missing indexes | Check Performance Insights for slow queries; consider read replica or larger instance |
| Cannot delete DB instance | Deletion protection enabled | Modify instance to disable deletion protection first |

---

## Next Steps / Advanced Topics

- **RDS Proxy** — connection pooling for serverless/Lambda applications to avoid connection exhaustion
- **Aurora Serverless v2** — auto-scaling database capacity based on load, pay-per-use
- **Cross-region read replicas** — for global applications and disaster recovery
- **Blue/Green Deployments** — safely test major version upgrades before cutover
- **Infrastructure as Code** — manage RDS instances, parameter groups, and subnet groups via Terraform or AWS CloudFormation


---

<a id="chapter-6-lambda"></a>

# Creating a Lambda Function in AWS — Complete Step-by-Step Guide

AWS Lambda runs code without provisioning or managing servers — you pay only for compute time consumed. This guide covers creating a function, configuring permissions, setting triggers, testing, and monitoring.

---

## Architecture Overview

```
        Trigger Sources
   ┌───────┬───────┬────────┐
   │       │       │        │
  S3    API GW   EventBridge  SQS
   │       │       │        │
   └───────┴───┬───┴────────┘
               │
        ┌──────▼───────┐
        │  Lambda        │
        │  Function      │
        │  - Runtime      │
        │  - Handler      │
        │  - IAM Role     │
        │  - Env Vars     │
        └──────┬────────┘
               │
       ┌───────┴────────┐
       │                │
   CloudWatch Logs   Other AWS Services
                      (S3, DynamoDB, SNS)
```

---

## Prerequisites

- Active AWS account
- IAM user/role with `AWSLambda_FullAccess` (or scoped equivalent) permissions
- Basic familiarity with at least one supported runtime language (Python, Node.js, Java, Go, .NET, Ruby)

---

## Step 1: Sign In and Select Region

1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in with IAM credentials
3. Select your target **region** (e.g., `Asia Pacific (Mumbai) ap-south-1`)

> Lambda functions are region-specific — triggers like S3 or DynamoDB should generally be in the same region for lowest latency, though cross-region invocation is possible.

---

## Step 2: Open the Lambda Console

1. In the search bar, type `Lambda` and select **Lambda**
2. You'll land on the **Lambda Dashboard**, showing existing functions and usage metrics

---

## Step 3: Create the Function

1. Click **Create function**
2. Choose a creation method:
   - **Author from scratch** — write code directly (recommended for this guide)
   - **Use a blueprint** — pre-built templates for common patterns
   - **Container image** — deploy a Docker container as the function
   - **Browse serverless app repository** — deploy a pre-packaged application

3. **Basic information**:

| Field | Value | Notes |
|---|---|---|
| Function name | `process-order-events` | Descriptive, no spaces |
| Runtime | `Python 3.13` | Or Node.js 22.x, Java 21, etc. |
| Architecture | `x86_64` | `arm64` (Graviton2) is cheaper and often faster |

4. **Permissions** — expand **Change default execution role**:
   - **Create a new role with basic Lambda permissions** (recommended for first-time setup) — auto-creates a role with CloudWatch Logs write access
   - **Use an existing role** — select a pre-created IAM role if you already have one scoped for this function
   - **Create a new role from AWS policy templates** — adds common permission sets (e.g., S3 read, DynamoDB CRUD)

5. Click **Create function**
6. Wait for the green **"Successfully created the function"** banner

---

## Step 4: Write and Deploy Function Code

1. In the function page, scroll to the **Code source** editor (or **Code** tab)
2. Replace the default handler with your logic. Example (Python):
   ```python
   import json

   def lambda_handler(event, context):
       print("Received event:", json.dumps(event))
       name = event.get("queryStringParameters", {}).get("name", "World")
       return {
           "statusCode": 200,
           "headers": {"Content-Type": "application/json"},
           "body": json.dumps({"message": f"Hello, {name}!"})
       }
   ```
3. Click **Deploy** (top of the code editor) to save and activate changes
4. For larger projects with dependencies, instead of the inline editor:
   - Package code and dependencies into a `.zip` file locally:
     ```bash
     pip install -r requirements.txt -t ./package
     cd package && zip -r ../function.zip . && cd ..
     zip -g function.zip lambda_function.py
     ```
   - Click **Upload from** → **.zip file** → select `function.zip`

---

## Step 5: Configure General Settings

1. Go to the **Configuration** tab → **General configuration** → **Edit**
2. Adjust:

| Setting | Recommended Value | Notes |
|---|---|---|
| Memory | 128–256 MB (start small, scale up if needed) | More memory also increases allocated CPU |
| Timeout | 3–15 seconds (adjust per workload) | Max is 15 minutes |
| Ephemeral storage | 512 MB (default) | Increase up to 10,240 MB if `/tmp` usage is high |

3. Click **Save**

> **Tip:** Use AWS Lambda Power Tuning (open-source tool) to find the optimal memory/cost/performance balance for your function.

---

## Step 6: Set Environment Variables

1. **Configuration** tab → **Environment variables** → **Edit**
2. Click **Add environment variable**:

| Key | Value |
|---|---|
| `TABLE_NAME` | `orders-table` |
| `LOG_LEVEL` | `INFO` |

3. For sensitive values (API keys, DB passwords), check **Enable helpers for encryption in transit** and use **AWS Secrets Manager** or **SSM Parameter Store** references instead of plaintext env vars
4. Click **Save**

---

## Step 7: Attach IAM Permissions for Downstream Services

If your function needs to read/write to other AWS services (e.g., DynamoDB, S3), attach a scoped policy to its execution role.

1. **Configuration** tab → **Permissions** → click the **Role name** link (opens IAM console)
2. Click **Add permissions** → **Create inline policy** (or attach an existing managed policy)
3. Example — allow read/write to a specific DynamoDB table:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem"],
         "Resource": "arn:aws:dynamodb:ap-south-1:123456789012:table/orders-table"
       }
     ]
   }
   ```
4. Name the policy `Lambda-DynamoDB-OrdersTable` → **Create policy**

---

## Step 8: Add a Trigger

Triggers invoke the function automatically based on events.

1. Return to the function page → **Add trigger**
2. Choose a source, e.g.:

### Option A: API Gateway (HTTP Endpoint)
- Trigger: **API Gateway**
- API type: **HTTP API** (cheaper/simpler) or **REST API** (more features)
- Security: **Open** (for testing) or **AWS_IAM** (for authenticated calls)
- Click **Add** — AWS generates an invoke URL automatically

### Option B: S3 (On Object Upload)
- Trigger: **S3**
- Bucket: select your bucket (e.g., `my-app-bucket-prod-2026`)
- Event type: **All object create events**
- Prefix/Suffix filter: e.g., suffix `.jpg` to trigger only on image uploads
- Click **Add**

### Option C: EventBridge (Scheduled/Cron)
- Trigger: **EventBridge (CloudWatch Events)**
- Rule type: **Schedule expression**
- Expression: `rate(5 minutes)` or `cron(0 9 * * ? *)` (daily at 9 AM UTC)
- Click **Add**

### Option D: SQS (Queue Processing)
- Trigger: **SQS**
- Queue: select an existing SQS queue
- Batch size: `10` (number of messages per invocation)
- Click **Add**

---

## Step 9: Test the Function

1. Go to the **Test** tab
2. Click **Create new event**
3. Event name: `test-event-1`
4. Choose a template matching your trigger (e.g., `apigateway-aws-proxy` or leave as generic JSON):
   ```json
   {
     "queryStringParameters": {
       "name": "AWS"
     }
   }
   ```
5. Click **Save**, then click **Test**
6. Review the **Execution result**:
   - **Response**: the returned payload
   - **Duration**: execution time in ms
   - **Billed duration**: rounded billing time
   - **Memory used**: actual vs. allocated memory
7. Check **Logs** for `print`/`console.log` output and any errors

---

## Step 10: Monitor with CloudWatch

1. Go to the **Monitor** tab on the function page
2. Review built-in graphs:
   - Invocations
   - Duration
   - Error count and success rate
   - Throttles
   - Concurrent executions
3. Click **View CloudWatch logs** to see detailed execution logs per invocation
4. (Optional) Set a CloudWatch Alarm:
   - Go to **CloudWatch** → **Alarms** → **Create alarm**
   - Metric: `Errors` for this function
   - Threshold: e.g., `> 5 errors in 5 minutes`
   - Notification: send to an SNS topic (email/SMS)

---

## Step 11: Configure Concurrency and Scaling (Optional)

1. **Configuration** tab → **Concurrency** → **Edit**
2. Options:
   - **Unreserved concurrency** (default): shares the account-wide pool (1,000 by default, can request increase)
   - **Reserved concurrency**: guarantees (and caps) a specific number of concurrent executions for this function — prevents it from starving other functions, or from over-scaling and overwhelming a downstream database
   - **Provisioned concurrency**: pre-warms execution environments to eliminate cold starts, at additional cost — useful for latency-sensitive APIs
3. Click **Save**

---

## Step 12: Set Up Versions and Aliases (For Safe Deployments)

1. **Actions** → **Publish new version** — creates an immutable snapshot of the current code + config
2. Go to **Aliases** tab → **Create alias**
   - Name: `prod`
   - Version: point to the published version (e.g., version `3`)
3. Use **weighted aliases** for canary deployments:
   - Route 90% of traffic to version 3, 10% to version 4, to test new code safely before full rollout
4. Point triggers (e.g., API Gateway) at the **alias ARN** rather than `$LATEST`, so you can shift traffic without reconfiguring triggers

---

## Step 13: Verification Checklist

- [ ] Function created with correct runtime and architecture
- [ ] Execution role scoped to least-privilege (only required service permissions)
- [ ] Environment variables set; secrets use Secrets Manager/Parameter Store, not plaintext
- [ ] Memory and timeout tuned to workload (not left at defaults blindly)
- [ ] Trigger configured and tested (API Gateway, S3, EventBridge, SQS, etc.)
- [ ] Test event runs successfully with expected output
- [ ] CloudWatch Logs show expected output with no unhandled errors
- [ ] CloudWatch alarm configured for error rate monitoring
- [ ] Concurrency limits reviewed (reserved/provisioned if needed)
- [ ] Versions/aliases used for production traffic instead of `$LATEST`

---

## Cleanup (To Avoid Ongoing Charges)

Lambda itself is pay-per-invocation with a generous free tier, but attached resources can incur cost:

1. Delete the function: **Actions** → **Delete function**
2. Remove associated triggers (API Gateway APIs, EventBridge rules, S3 event notifications) if not shared with other resources
3. Delete the CloudWatch Log Group: **CloudWatch** → **Log groups** → find `/aws/lambda/process-order-events` → **Delete**
4. Delete the IAM execution role if no longer needed
5. Remove any Provisioned Concurrency configuration (this incurs charges even when idle)

---

## Quick Reference Summary

| Component | Purpose |
|---|---|
| Function | The deployable unit of code + configuration |
| Handler | Entry-point function AWS invokes |
| Execution Role | IAM role granting the function its permissions |
| Trigger | Event source that invokes the function |
| Environment Variables | Runtime configuration values |
| Layers | Shared code/dependencies reusable across functions |
| Version | Immutable snapshot of code + config |
| Alias | Named pointer to a version, supports traffic-weighting |
| Concurrency | Controls parallel execution limits |

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| `Task timed out after X seconds` | Function logic takes longer than configured timeout | Increase timeout, or optimize code/downstream calls |
| `AccessDeniedException` calling another AWS service | Execution role missing required permission | Add scoped policy to the function's IAM role |
| Cold start latency spikes | No provisioned concurrency, VPC-attached function | Enable Provisioned Concurrency; avoid unnecessary VPC attachment |
| Function not triggered by S3 upload | Event notification misconfigured, or prefix/suffix filter mismatch | Recheck trigger config in both Lambda and S3 event notifications |
| `Unable to import module` error | Missing dependency in deployment package | Ensure all dependencies are bundled in the `.zip` or use a Lambda Layer |

---

## Next Steps / Advanced Topics

- **Lambda Layers** — share common dependencies/libraries across multiple functions
- **Step Functions** — orchestrate multiple Lambda functions into a workflow/state machine
- **Lambda@Edge / CloudFront Functions** — run code at CDN edge locations for ultra-low latency
- **Container Image Support** — package Lambda functions as Docker images for complex dependencies (up to 10 GB)
- **Infrastructure as Code** — manage functions, triggers, and permissions via Terraform, AWS SAM, or AWS CloudFormation


---

<a id="chapter-7-api-gateway"></a>

# Creating an API Gateway in AWS — Complete Step-by-Step Guide

Amazon API Gateway lets you create, publish, and manage REST, HTTP, and WebSocket APIs that front backend services like Lambda, EC2, or other HTTP endpoints. This guide covers building an HTTP API backed by Lambda, securing it, and deploying it to a custom domain.

---

## Architecture Overview

```
                    Client (Browser/App)
                            │
                         HTTPS
                            │
                  ┌─────────────────┐
                  │   API Gateway    │
                  │   (HTTP API)     │
                  │                  │
                  │  Route: GET /hi  │
                  │  Authorizer      │
                  │  Throttling      │
                  └────────┬─────────┘
                            │
                    ┌───────┴────────┐
                    │                │
              Lambda Function    EC2/ALB Backend
```

---

## Prerequisites

- Active AWS account
- IAM user/role with `AmazonAPIGatewayAdministrator` (or scoped equivalent) permissions
- A backend to integrate with — e.g., a Lambda function (see companion *AWS Lambda Creation Guide*), or an existing HTTP endpoint/ALB

### REST API vs. HTTP API — Which to Choose

| Feature | HTTP API | REST API |
|---|---|---|
| Cost | ~70% cheaper | Higher per-request cost |
| Latency | Lower | Higher |
| Features | Core routing, JWT/Lambda authorizers, CORS | Full feature set: API keys, usage plans, request/response transformation, WAF, private endpoints |
| Best for | Most modern serverless APIs | Enterprise APIs needing fine-grained control |

This guide uses **HTTP API** (recommended default for new projects) and notes REST API differences where relevant.

---

## Step 1: Sign In and Select Region

1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in with IAM credentials
3. Select your target **region** (e.g., `Asia Pacific (Mumbai) ap-south-1`)

> The API Gateway and its backend (e.g., Lambda) should generally be in the same region.

---

## Step 2: Open the API Gateway Console

1. In the search bar, type `API Gateway` and select **API Gateway**
2. You'll land on the **APIs** dashboard listing existing APIs

---

## Step 3: Create the API

1. Click **Create API**
2. Under **HTTP API**, click **Build**
3. **Step 1 — Integrations**:
   - Click **Add integration**
   - Integration type: **Lambda**
   - AWS Region: your region
   - Lambda function: select your function (e.g., `process-order-events`)
   - **API name**: `orders-api`
4. Click **Next**

5. **Step 2 — Configure routes**:
   - **Method**: `GET`
   - **Resource path**: `/hello`
   - **Integration target**: your Lambda function (auto-filled)
   - Click **Add route** to define additional routes, e.g.:

| Method | Path | Integration |
|---|---|---|
| GET | `/orders` | `list-orders-fn` |
| POST | `/orders` | `create-order-fn` |
| GET | `/orders/{id}` | `get-order-fn` |
| DELETE | `/orders/{id}` | `delete-order-fn` |

   - Click **Next**

6. **Step 3 — Configure stages**:
   - Stage name: `$default` (auto-deploys on every change) — good for dev
   - For production, uncheck auto-deploy and create a named stage instead (e.g., `prod`) — see Step 8
   - Click **Next**

7. **Step 4 — Review and create**:
   - Confirm integrations, routes, and stage settings
   - Click **Create**

8. Note the **Invoke URL** shown on the API's main page, e.g.:
   ```
   https://abc123xyz.execute-api.ap-south-1.amazonaws.com
   ```

---

## Step 4: Grant API Gateway Permission to Invoke Lambda

Usually configured automatically when you add the Lambda integration through the console, but verify:

1. Go to the **Lambda console** → select the function → **Configuration** tab → **Permissions**
2. Under **Resource-based policy statements**, confirm an entry exists allowing `apigateway.amazonaws.com` to invoke the function
3. If missing, add manually via AWS CLI:
   ```bash
   aws lambda add-permission \
     --function-name process-order-events \
     --statement-id apigateway-invoke \
     --action lambda:InvokeFunction \
     --principal apigateway.amazonaws.com \
     --source-arn "arn:aws:execute-api:ap-south-1:123456789012:abc123xyz/*/*/hello"
   ```

---

## Step 5: Test the API

1. Copy the **Invoke URL** + route path, e.g.:
   ```
   https://abc123xyz.execute-api.ap-south-1.amazonaws.com/hello
   ```
2. Test with curl:
   ```bash
   curl https://abc123xyz.execute-api.ap-south-1.amazonaws.com/hello
   ```
3. Or open directly in a browser for `GET` routes
4. Confirm the response matches your Lambda function's return payload
5. Check **CloudWatch Logs** (see Step 9) if the response is unexpected

---

## Step 6: Configure CORS (If Called from a Browser Frontend)

1. Select your API → left sidebar → **CORS** → **Configure**
2. Set:

| Field | Value |
|---|---|
| Access-Control-Allow-Origin | `https://myfrontend.com` (avoid `*` in production) |
| Access-Control-Allow-Methods | `GET, POST, DELETE, OPTIONS` |
| Access-Control-Allow-Headers | `Content-Type, Authorization` |
| Access-Control-Max-Age | `300` |

3. Click **Save**

---

## Step 7: Secure the API with an Authorizer

Choose one based on your auth model:

### Option A: JWT Authorizer (Cognito or Third-Party OIDC)

1. Left sidebar → **Authorization** → **Manage authorizers** → **Create**
2. Type: **JWT**
3. Identity source: `$request.header.Authorization`
4. Issuer URL: your Cognito User Pool or OIDC provider issuer URL
5. Audience: your app client ID
6. Click **Create**
7. Go to **Routes** → select a route → **Attach authorization** → choose the JWT authorizer

### Option B: Lambda Authorizer (Custom Logic)

1. **Manage authorizers** → **Create**
2. Type: **Lambda**
3. Select a Lambda function that validates tokens/API keys and returns an IAM policy
4. Identity source: `$request.header.Authorization`
5. Attach to routes as in Option A

### Option C: IAM Authorization (SigV4)

- Useful for service-to-service calls within AWS
- Set route authorization type to **AWS_IAM** under route settings
- Callers must sign requests with valid AWS credentials

> Routes without an authorizer attached are **publicly accessible** — review every route before going to production.

---

## Step 8: Create a Named Stage for Production

1. Left sidebar → **Stages** → **Create**
2. Stage name: `prod`
3. **Auto-deploy**: disable for controlled releases (deploy manually after testing)
4. **Default route settings**:
   - Throttling — burst: `100`, rate: `50` requests/second (adjust per capacity planning)
   - Enable **Detailed metrics** for per-route CloudWatch stats
5. Click **Create**
6. To deploy changes to this stage: **Deploy** button (top right) → select stage `prod` → **Deploy**
7. Your production invoke URL becomes:
   ```
   https://abc123xyz.execute-api.ap-south-1.amazonaws.com/prod
   ```

---

## Step 9: Enable Logging and Monitoring

1. Select your API → **Stages** → select `prod` → **Logging** tab → **Edit**
2. **Access logging**:
   - Enable, select/create a CloudWatch Log Group (e.g., `/aws/apigateway/orders-api-prod`)
   - Log format: JSON, including `requestId`, `ip`, `httpMethod`, `status`, `responseLength`, `integrationLatency`
3. Click **Save**
4. Go to **CloudWatch** → **Log groups** to view real-time request logs
5. Set alarms on key metrics (**Monitor** tab or CloudWatch directly):
   - `5xxError` count — backend failures
   - `4xxError` count — client/auth issues
   - `Latency` / `IntegrationLatency` — performance
   - `Count` — traffic volume

---

## Step 10: Set Up a Custom Domain (Optional)

1. Left sidebar (top-level, not inside a specific API) → **Custom domain names** → **Create**
2. Domain name: `api.mycompany.com`
3. Certificate: select an **ACM certificate** for this domain (request one first via **AWS Certificate Manager** if you don't have one — must be in the same region as the API, or `us-east-1` for edge-optimized)
4. Endpoint type: **Regional** (recommended) or **Edge-optimized** (uses CloudFront globally)
5. Click **Create domain name**
6. **API mappings** tab → **Configure API mappings** → **Add new mapping**:
   - API: `orders-api`
   - Stage: `prod`
   - Path (optional): leave blank or add a prefix like `v1`
7. In your DNS provider (e.g., Route 53), create an **alias/CNAME record** pointing `api.mycompany.com` to the API Gateway domain target shown in the console
8. Verify: `curl https://api.mycompany.com/orders`

---

## Step 11: Set Up Throttling and Usage Plans (REST API Only)

For fine-grained rate limiting per API key/customer, use a **REST API** instead of HTTP API:

1. Create API → **REST API** → **Build**
2. After creating routes and deploying to a stage, go to **Usage Plans** → **Create**
3. Configure:
   - Throttle: rate `10 req/s`, burst `20`
   - Quota: `10,000 requests / month`
4. Associate the usage plan with an **API stage**
5. Create an **API Key** under **API Keys** → **Create API key**
6. Associate the key with the usage plan
7. Require `x-api-key` header on requests; distribute keys to individual consumers/customers

---

## Step 12: Verification Checklist

- [ ] API type chosen appropriately (HTTP API for cost/simplicity, REST API for advanced features)
- [ ] All routes mapped to correct backend integrations
- [ ] Lambda resource-based policy allows API Gateway invocation
- [ ] CORS configured correctly if called from browser frontends
- [ ] Every route has explicit authorization (JWT, Lambda authorizer, IAM, or intentionally public)
- [ ] Named stage (e.g., `prod`) used for production, not relying on `$default` with auto-deploy
- [ ] Throttling limits set to protect backend from traffic spikes
- [ ] Access logging enabled to a dedicated CloudWatch Log Group
- [ ] CloudWatch alarms configured for 4xx/5xx error rates and latency
- [ ] Custom domain configured with valid ACM certificate (if applicable)
- [ ] Tested end-to-end with curl/Postman against the deployed stage URL

---

## Cleanup (To Avoid Ongoing Charges)

1. Delete custom domain mapping: **Custom domain names** → select → **API mappings** → remove mapping, then delete the domain
2. Delete the API: select API → **Actions**/**Delete** → confirm
3. Delete associated CloudWatch Log Groups if no longer needed
4. Remove the Lambda resource-based policy statement if the function is reused elsewhere
5. Delete unused ACM certificates and Route 53 records

> API Gateway itself has no idle cost beyond storage of logs — charges are per-request, but custom domain + ACM + Route 53 records can incur small ongoing DNS costs.

---

## Quick Reference Summary

| Component | Purpose |
|---|---|
| API | Top-level container for routes and stages |
| Route | Maps an HTTP method + path to a backend integration |
| Integration | The backend the route forwards requests to (Lambda, HTTP, etc.) |
| Stage | A named, deployed snapshot of the API (e.g., `dev`, `prod`) |
| Authorizer | Validates caller identity before allowing route access |
| Usage Plan | Rate limiting/quota tied to API keys (REST API only) |
| Custom Domain | Maps a friendly domain name to the API Gateway endpoint |
| Access Logging | Records each request for auditing/debugging |

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| `{"message":"Internal Server Error"}` | Lambda function threw an unhandled exception | Check CloudWatch Logs for the Lambda function |
| `{"message":"Forbidden"}` | Authorizer rejected the request, or missing `x-api-key` | Verify token validity/expiration; confirm API key is attached to usage plan |
| CORS errors in browser console | Preflight `OPTIONS` not handled, or headers misconfigured | Re-check CORS configuration; ensure it covers all needed methods/headers |
| Changes not reflected after editing routes | Stage not redeployed (`$default` with auto-deploy off, or named stage) | Click **Deploy** and select the correct stage |
| 429 Too Many Requests | Throttling limits too low for traffic | Increase stage/route throttle settings, or request a service quota increase |

---

## Next Steps / Advanced Topics

- **WebSocket APIs** — for real-time, bidirectional communication (chat apps, live dashboards)
- **Request/Response transformation (REST API)** — mapping templates (VTL) to reshape payloads between client and backend
- **AWS WAF integration** — protect REST APIs from common web exploits and bot traffic
- **Private APIs** — restrict access to only within a VPC via VPC endpoints
- **Infrastructure as Code** — manage APIs, routes, and stages via Terraform, AWS SAM, or AWS CloudFormation


---

<a id="chapter-8-cloudwatch"></a>

# Setting Up CloudWatch in AWS — Complete Step-by-Step Guide

Amazon CloudWatch collects metrics, logs, and events from your AWS resources so you can monitor performance, set alarms, and automate responses. This guide covers dashboards, custom metrics, log groups, alarms, and event-driven automation.

---

## Architecture Overview

```
        AWS Resources (EC2, Lambda, RDS, etc.)
                        │
              ┌─────────┴──────────┐
              │                    │
         Metrics                Logs
              │                    │
        ┌─────▼─────┐      ┌───────▼────────┐
        │ CloudWatch │      │ CloudWatch Logs │
        │  Metrics   │      │  (Log Groups)   │
        └─────┬─────┘      └───────┬────────┘
              │                    │
        ┌─────▼─────┐      ┌───────▼────────┐
        │   Alarms   │      │  Log Insights /  │
        │            │      │  Metric Filters  │
        └─────┬─────┘      └────────────────┘
              │
        ┌─────▼─────┐
        │ SNS Topic  │──► Email / SMS / Lambda
        └───────────┘

        CloudWatch Dashboards ── visualize everything above
        EventBridge Rules ── react to state changes / schedules
```

---

## Prerequisites

- Active AWS account
- IAM user/role with `CloudWatchFullAccess` (or scoped equivalent) permissions
- At least one running resource to monitor (EC2 instance, Lambda function, RDS database, etc. — see companion guides)

---

## Step 1: Sign In and Open CloudWatch

1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in with IAM credentials
3. Select your target **region** (e.g., `Asia Pacific (Mumbai) ap-south-1`) — CloudWatch is region-scoped; each region has its own metrics/logs/alarms
4. In the search bar, type `CloudWatch` and select **CloudWatch**

---

## Step 2: Explore Default Metrics

Most AWS services automatically publish metrics at no extra cost (standard resolution, 5-minute granularity).

1. Left sidebar → **Metrics** → **All metrics**
2. Browse by namespace, e.g.:
   - `AWS/EC2` — CPUUtilization, NetworkIn/Out, DiskReadOps
   - `AWS/Lambda` — Invocations, Errors, Duration, Throttles
   - `AWS/RDS` — CPUUtilization, FreeStorageSpace, DatabaseConnections
   - `AWS/ApplicationELB` — RequestCount, TargetResponseTime, HTTPCode_Target_5XX_Count
3. Select a metric (e.g., EC2 → Per-Instance Metrics → `CPUUtilization`) to view its graph
4. Adjust the time range and statistic (Average, Maximum, Sum, p99, etc.) at the top of the graph

---

## Step 3: Create a Dashboard

Dashboards give you a single view combining multiple metrics/logs across services.

1. Left sidebar → **Dashboards** → **Create dashboard**
2. Name: `production-overview`
3. Click **Create dashboard**
4. **Add widget** → choose a widget type:

| Widget Type | Use Case |
|---|---|
| Line / Number / Stacked area | Metric trends over time |
| Gauge | Single value against a threshold (e.g., % storage used) |
| Log table | Query results from CloudWatch Logs |
| Alarm status | Show current state of alarms |
| Text | Add markdown notes/headers to the dashboard |

5. For a **Line widget**:
   - Select data source: **Metrics**
   - Browse/search and check the metrics to include (e.g., `CPUUtilization` for your EC2 instance, `Errors` for your Lambda)
   - Click **Create widget**
6. Repeat to add widgets for each key resource
7. Drag/resize widgets to organize the layout
8. Click **Save dashboard**

> **Tip:** Build one dashboard per environment (`production-overview`, `staging-overview`) rather than one giant dashboard mixing everything.

---

## Step 4: Create a CloudWatch Log Group

Log groups store logs from applications, Lambda functions, EC2 instances (via the CloudWatch Agent), and more.

1. Left sidebar → **Logs** → **Log groups** → **Create log group**
2. Configure:
   - **Log group name**: `/app/orders-service`
   - **Retention setting**: 30 days (default is "Never expire" — set this explicitly to control cost)
   - **KMS encryption**: optional, select a KMS key for logs containing sensitive data
3. Click **Create**

> Lambda automatically creates a log group named `/aws/lambda/<function-name>` on first invocation — you don't need to create this manually.

---

## Step 5: Install the CloudWatch Agent on EC2 (For OS-Level Metrics/Logs)

Default EC2 metrics don't include memory or disk usage from inside the OS — the CloudWatch Agent adds these.

1. Attach an IAM role with the `CloudWatchAgentServerPolicy` to your EC2 instance:
   - EC2 Console → select instance → **Actions** → **Security** → **Modify IAM role** → attach role
2. SSH into the instance and install the agent (Amazon Linux):
   ```bash
   sudo yum install -y amazon-cloudwatch-agent
   ```
3. Create a configuration file interactively:
   ```bash
   sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard
   ```
   - Follow prompts to select metrics (CPU, memory, disk) and log files to collect (e.g., `/var/log/messages`, application logs)
   - This generates `/opt/aws/amazon-cloudwatch-agent/bin/config.json`
4. Start the agent with the generated config:
   ```bash
   sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
     -a fetch-config -m ec2 -s \
     -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json
   ```
5. Verify in the console: **Metrics** → namespace `CWAgent` should now show memory/disk metrics

---

## Step 6: Create Metric Filters (Extract Metrics from Log Data)

Turn log patterns into queryable metrics — e.g., count how often "ERROR" appears in application logs.

1. Select your log group (`/app/orders-service`) → **Metric filters** tab → **Create metric filter**
2. **Filter pattern**: `ERROR`
3. Click **Test pattern** against sample log events to confirm matches
4. Click **Next**
5. Configure the metric:
   - Filter name: `OrdersServiceErrorCount`
   - Metric namespace: `CustomApp/Orders`
   - Metric name: `ErrorCount`
   - Metric value: `1` (count occurrences)
6. Click **Next** → review → **Create metric filter**
7. This metric now appears under **Metrics** → `CustomApp/Orders` and can be used in alarms/dashboards

---

## Step 7: Create a CloudWatch Alarm

1. Left sidebar → **Alarms** → **All alarms** → **Create alarm**
2. **Select metric**:
   - Browse to the metric (e.g., `AWS/EC2` → `CPUUtilization` for your instance, or your custom `ErrorCount` metric from Step 6)
   - Click **Select metric**
3. **Specify metric and conditions**:
   - Statistic: `Average`
   - Period: `5 minutes`
   - Threshold type: **Static**
   - Condition: `Greater than 80` (for CPU) or `Greater than 5` (for error count)
   - Additional configuration: datapoints to alarm, e.g., `3 out of 3` (avoids false alarms from single spikes)
4. Click **Next**
5. **Configure actions**:
   - Alarm state trigger: **In alarm**
   - Select an SNS topic, or create a new one:
     - **Create new topic** → name: `prod-alerts` → email endpoint: `ops-team@company.com`
     - Confirm the subscription via the email sent to that address
   - (Optional) Add additional actions: **Auto Scaling action**, **EC2 action** (reboot/stop/terminate), **Lambda action**
6. Click **Next**
7. Name: `high-cpu-orders-server`
8. Description: `Triggers when EC2 CPU exceeds 80% for 15 minutes`
9. Click **Next** → review → **Create alarm**

### Common Alarm Examples

| Resource | Metric | Threshold | Purpose |
|---|---|---|---|
| EC2 | CPUUtilization | > 80% for 15 min | Detect overload |
| Lambda | Errors | > 5 in 5 min | Catch failing invocations |
| Lambda | Throttles | > 0 | Detect concurrency limits hit |
| RDS | FreeStorageSpace | < 2 GB | Prevent disk-full outages |
| RDS | DatabaseConnections | > 80% of max | Prevent connection exhaustion |
| ALB | HTTPCode_Target_5XX_Count | > 10 in 5 min | Detect backend failures |
| Custom | ErrorCount (from logs) | > 5 in 5 min | Application-level error spikes |

---

## Step 8: Use CloudWatch Logs Insights (Query Logs)

1. Left sidebar → **Logs** → **Logs Insights**
2. Select one or more log groups (e.g., `/aws/lambda/process-order-events`)
3. Write a query, e.g., find the slowest requests:
   ```
   fields @timestamp, @message, @duration
   | filter @type = "REPORT"
   | sort @duration desc
   | limit 20
   ```
4. Or count errors by hour:
   ```
   fields @timestamp, @message
   | filter @message like /ERROR/
   | stats count() by bin(1h)
   ```
5. Click **Run query**
6. Click **Add to dashboard** to pin useful queries for ongoing visibility

---

## Step 9: Set Up Composite Alarms (Optional, Reduce Alert Noise)

Combine multiple alarms into one higher-level alarm to avoid alert fatigue.

1. **Alarms** → **All alarms** → **Create alarm** → **Create composite alarm**
2. Build a rule combining existing alarms, e.g.:
   ```
   ALARM("high-cpu-orders-server") AND ALARM("high-memory-orders-server")
   ```
3. Configure actions (SNS notification) same as Step 7
4. Click **Create composite alarm**

> Useful for reducing noise — e.g., only page on-call if **both** CPU and memory are high simultaneously, rather than firing two separate pages.

---

## Step 10: Automate Responses with EventBridge (Optional)

React automatically to state changes instead of just notifying a human.

1. Search for **EventBridge** in the console → **Rules** → **Create rule**
2. Name: `restart-on-high-cpu`
3. Event source: **AWS services**
4. Event pattern: match CloudWatch Alarm state change to `ALARM` for a specific alarm name
5. Target: select a **Lambda function**, **SSM Automation document**, or **EC2 Actions** (e.g., reboot instance)
6. Click **Create rule**

Example use case: automatically restart an application service via SSM Run Command when a custom "app unhealthy" alarm triggers.

---

## Step 11: Set Log Retention and Cost Controls

CloudWatch Logs stored indefinitely can become a significant cost driver.

1. Review all log groups: **Logs** → **Log groups**
2. For each group, click the **Retention** column value → set an explicit period (e.g., 30, 90, or 365 days) instead of "Never expire"
3. For high-volume debug logs, consider:
   - Shorter retention (7–14 days)
   - Exporting older logs to **S3** for cheap long-term archival: select log group → **Actions** → **Export data to Amazon S3**
4. Review **CloudWatch Logs Insights** query costs — charged per GB scanned; narrow time ranges and log groups when querying

---

## Step 12: Verification Checklist

- [ ] Dashboard created covering key metrics for critical resources
- [ ] CloudWatch Agent installed on EC2 instances needing memory/disk metrics
- [ ] Log groups created with explicit (non-infinite) retention periods
- [ ] Metric filters configured to surface important log patterns (errors, warnings)
- [ ] Alarms created for critical thresholds (CPU, storage, errors, throttles)
- [ ] SNS topic confirmed and subscribed (check for the confirmation email)
- [ ] Composite alarms used where appropriate to reduce alert noise
- [ ] Logs Insights queries saved/pinned for common troubleshooting scenarios
- [ ] EventBridge automation configured for self-healing scenarios (if applicable)
- [ ] Old/unused log groups and alarms cleaned up periodically

---

## Cleanup (To Avoid Ongoing Charges)

1. Delete dashboards no longer needed: **Dashboards** → select → **Delete**
2. Delete alarms: **Alarms** → select → **Actions** → **Delete**
3. Delete log groups: **Log groups** → select → **Actions** → **Delete log group(s)**
4. Delete the SNS topic if unused: **SNS Console** → **Topics** → select → **Delete**
5. Remove EventBridge rules: **EventBridge** → **Rules** → select → **Delete**
6. Uninstall the CloudWatch Agent from EC2 instances being decommissioned

> CloudWatch has a free tier (basic metrics, some alarms, limited log ingestion), but custom metrics, high-resolution metrics, extended log retention, and Logs Insights queries all incur charges — review usage periodically via **Billing Dashboard**.

---

## Quick Reference Summary

| Component | Purpose |
|---|---|
| Metric | Time-series data point published by a resource |
| Namespace | Grouping for related metrics (e.g., `AWS/EC2`) |
| Dashboard | Customizable visual view combining metrics/logs/alarms |
| Log Group | Container for log streams from a resource |
| Metric Filter | Converts log patterns into queryable metrics |
| Alarm | Triggers an action when a metric crosses a threshold |
| Composite Alarm | Combines multiple alarms into one higher-level condition |
| Logs Insights | Query language for searching/analyzing log data |
| CloudWatch Agent | Collects OS-level metrics/logs from EC2/on-prem servers |
| EventBridge Rule | Automates responses to state changes or on a schedule |

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| No memory/disk metrics for EC2 | CloudWatch Agent not installed/running | Install agent (Step 5); verify IAM role has `CloudWatchAgentServerPolicy` |
| Alarm stuck in `INSUFFICIENT_DATA` | No metric data published yet, or wrong dimension selected | Verify the resource is actively publishing the metric; check dimension (e.g., correct InstanceId) |
| Not receiving alarm emails | SNS subscription not confirmed | Check inbox (including spam) for the confirmation email and click **Confirm subscription** |
| Logs Insights query returns nothing | Wrong log group selected, or time range too narrow | Verify correct log group(s) and widen the time range |
| Unexpectedly high CloudWatch bill | Log retention set to "Never expire", high-resolution custom metrics, frequent Insights queries | Set explicit retention; review custom metric usage; narrow query scope |

---

## Next Steps / Advanced Topics

- **CloudWatch Synthetics** — canary scripts that proactively test endpoints/APIs on a schedule
- **CloudWatch RUM (Real User Monitoring)** — capture performance data from actual end-user browsers
- **Contributor Insights** — identify top talkers/outliers in high-cardinality log data
- **Anomaly Detection** — machine-learning-based dynamic thresholds instead of static alarm values
- **Infrastructure as Code** — manage dashboards, alarms, and log groups via Terraform or AWS CloudFormation


---

<a id="chapter-9-dynamodb"></a>

# Creating a DynamoDB Table in AWS — Complete Step-by-Step Guide

Amazon DynamoDB is a fully managed, serverless NoSQL key-value/document database offering single-digit millisecond performance at any scale. This guide covers table design, indexes, capacity modes, access control, and integration with Lambda.

---

## Architecture Overview

```
                  Application / Lambda
                          │
                    IAM Policy
                          │
                ┌──────────────────┐
                │  DynamoDB Table    │
                │  Orders             │
                │                    │
                │  PK: orderId        │
                │  SK: customerId      │
                │                    │
                │  GSI: customerId-index │
                │  LSI: orderDate-index  │
                │                    │
                │  Streams ──► Lambda  │
                └──────────────────┘
```

---

## Prerequisites

- Active AWS account
- IAM user/role with `AmazonDynamoDBFullAccess` (or scoped equivalent) permissions
- A clear idea of your **access patterns** — unlike relational databases, DynamoDB table design starts from "how will I query this?" rather than normalized entity modeling

### Core Concepts Before You Start

| Concept | Description |
|---|---|
| Partition key (PK) | Determines which physical partition stores the item; must be highly unique/distributed |
| Sort key (SK) | Optional; combined with PK forms a composite primary key, enables range queries |
| Item | A single record (like a row), up to 400 KB |
| Attribute | A field on an item (like a column), but schema-less — items in the same table can have different attributes |
| GSI (Global Secondary Index) | Alternate PK/SK for different query patterns, own read/write capacity |
| LSI (Local Secondary Index) | Same PK as base table, different SK — must be created at table creation, cannot be added later |

---

## Step 1: Sign In and Select Region

1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in with IAM credentials
3. Select your target **region** (e.g., `Asia Pacific (Mumbai) ap-south-1`)

---

## Step 2: Open the DynamoDB Console

1. In the search bar, type `DynamoDB` and select **DynamoDB**
2. You'll land on the **DynamoDB Dashboard**

---

## Step 3: Design Your Key Schema

Before creating the table, define your access patterns on paper. Example — an e-commerce orders table:

| Access Pattern | Key Design |
|---|---|
| Get order by ID | PK: `orderId` |
| Get all orders for a customer | GSI PK: `customerId`, SK: `orderDate` |
| Get orders by status within a date range | GSI PK: `status`, SK: `orderDate` |

Chosen schema for this guide:
- **Table name**: `Orders`
- **Partition key**: `orderId` (String)
- **Sort key**: `customerId` (String)

---

## Step 4: Create the Table

1. Click **Create table**
2. **Table details**:

| Field | Value | Notes |
|---|---|---|
| Table name | `Orders` | |
| Partition key | `orderId` — Type: **String** | |
| Sort key | `customerId` — Type: **String** | Optional, add if composite key needed |

3. **Table settings**:
   - **Default settings** (recommended for most cases): on-demand capacity, AWS-owned encryption key
   - **Customize settings**: expand for full control (used below)

4. **Table class**:
   - **DynamoDB Standard** (default, most use cases)
   - **DynamoDB Standard-IA** — cheaper storage for infrequently accessed tables, higher read/write cost

5. **Capacity mode**:

| Mode | Best For | Billing |
|---|---|---|
| **On-demand** | Unpredictable/spiky traffic, new applications | Pay per request, no capacity planning |
| **Provisioned** | Steady, predictable traffic | Pay for reserved read/write capacity units (cheaper at scale, can use Auto Scaling) |

   Select **On-demand** for this guide (recommended default; switch to Provisioned later if traffic becomes predictable and cost-sensitive)

6. **Secondary indexes** — expand and click **Create global index** if needed now (can also be added after table creation for GSIs):
   - Index name: `customerId-orderDate-index`
   - Partition key: `customerId`
   - Sort key: `orderDate`
   - Projected attributes: **All** (simplest) or **Keys only** / **Include** specific attributes (cheaper storage/throughput for large items)

7. **Encryption at rest**:
   - **Amazon DynamoDB owned key** (default, no cost)
   - **AWS owned key** or **Customer managed key (KMS)** for audit/compliance requirements

8. Click **Create table**
9. Status shows `Creating` → wait for `Active` (usually under a minute)

---

## Step 5: Add Items (Manually, for Testing)

1. Select the table → **Explore table items** tab → **Create item**
2. Choose **Form** or **JSON** view. Example JSON:
   ```json
   {
     "orderId": "ORD-1001",
     "customerId": "CUST-500",
     "orderDate": "2026-07-31",
     "status": "SHIPPED",
     "total": 149.99,
     "items": [
       {"sku": "ITEM-1", "qty": 2},
       {"sku": "ITEM-2", "qty": 1}
     ]
   }
   ```
3. Click **Create item**
4. Repeat with more sample items to test queries later

---

## Step 6: Query and Scan the Table

### Query (Efficient — Uses an Index)

1. **Explore table items** tab → **Query**
2. Select the table or a GSI from the dropdown
3. Enter the partition key value (and optionally sort key condition):
   - Partition key: `orderId` = `ORD-1001`
4. Click **Run**

### Scan (Reads Entire Table — Use Sparingly)

1. Switch to **Scan** mode
2. Add filters if needed (e.g., `status = SHIPPED`)
3. Click **Run**

> **Best practice:** Always design GSIs to support **Query** operations for your access patterns. Avoid `Scan` in production application code — it reads every item and doesn't scale.

---

## Step 7: Set Up IAM Permissions (Least Privilege)

1. **IAM Console** → **Policies** → **Create policy** → **JSON** tab
2. Example — allow an application role to read/write only the `Orders` table and its indexes:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "dynamodb:GetItem",
           "dynamodb:PutItem",
           "dynamodb:UpdateItem",
           "dynamodb:DeleteItem",
           "dynamodb:Query"
         ],
         "Resource": [
           "arn:aws:dynamodb:ap-south-1:123456789012:table/Orders",
           "arn:aws:dynamodb:ap-south-1:123456789012:table/Orders/index/*"
         ]
       }
     ]
   }
   ```
3. Name: `DynamoDB-OrdersTable-ReadWrite`
4. Attach this policy to the relevant IAM role (e.g., a Lambda execution role or EC2 instance role)

---

## Step 8: Enable DynamoDB Streams (For Event-Driven Processing)

Streams capture item-level changes (insert/update/delete) in near real-time — commonly used to trigger Lambda functions.

1. Select the table → **Exports and streams** tab → **DynamoDB stream details** → **Enable**
2. **View type**:

| View Type | Captures |
|---|---|
| Key attributes only | Just the keys of the changed item |
| New image | The entire item after the change |
| Old image | The entire item before the change |
| New and old images | Both — most common choice |

3. Select **New and old images** → **Enable stream**
4. Under **Trigger** → **Create trigger**:
   - Select an existing Lambda function, or create a new one
   - Batch size: `10` (items per invocation)
   - Click **Create trigger**
5. This Lambda now fires automatically whenever items in `Orders` are created, updated, or deleted

---

## Step 9: Configure Time to Live (TTL) for Automatic Expiration

Useful for session data, temporary tokens, or logs that should auto-delete.

1. Select the table → **Additional settings** tab → **Time to Live (TTL)** → **Turn on**
2. TTL attribute name: `expiresAt` (must be a Number attribute storing a Unix epoch timestamp)
3. Click **Turn on TTL**
4. When writing items, set `expiresAt` to the epoch time you want the item removed:
   ```json
   { "orderId": "TEMP-1", "expiresAt": 1785600000 }
   ```
5. DynamoDB automatically deletes expired items within 48 hours of expiration (no extra write capacity consumed for the deletion)

---

## Step 10: Enable Point-in-Time Recovery (PITR) and Backups

1. Select the table → **Backups** tab
2. **Point-in-time recovery (PITR)**:
   - Click **Edit** → **Turn on**
   - Allows restoring the table to any point within the last 35 days
3. **On-demand backup** (manual snapshot):
   - Click **Create backup**
   - Name: `Orders-backup-2026-07-31`
   - Click **Create backup**
4. To restore: **Backups** tab → select a backup or PITR timestamp → **Restore backup** (creates a **new** table — cannot restore in-place)

---

## Step 11: Set Up Auto Scaling (Provisioned Mode Only)

If using **Provisioned** capacity mode instead of On-demand:

1. Select the table → **Additional settings** tab → **Read/write capacity** → **Edit**
2. Enable **Auto scaling** for both read and write capacity
3. Configure:
   - Minimum capacity: `5` units
   - Maximum capacity: `100` units
   - Target utilization: `70%`
4. Click **Save**

> Auto scaling adjusts provisioned capacity automatically based on consumed throughput, avoiding manual tuning while controlling costs better than always-on high provisioned capacity.

---

## Step 12: Monitor with CloudWatch

1. Select the table → **Monitor** tab
2. Review built-in metrics:
   - `ConsumedReadCapacityUnits` / `ConsumedWriteCapacityUnits`
   - `ThrottledRequests` — indicates capacity is too low (provisioned mode) or a hot partition
   - `SystemErrors` / `UserErrors`
   - `SuccessfulRequestLatency`
3. Set a CloudWatch alarm for throttling:
   - **CloudWatch** → **Alarms** → **Create alarm**
   - Metric: `ThrottledRequests` for this table
   - Threshold: `> 0`
   - Notify via SNS

---

## Step 13: Verification Checklist

- [ ] Key schema (PK/SK) matches actual application access patterns
- [ ] Capacity mode chosen appropriately (On-demand for unpredictable traffic, Provisioned + Auto Scaling for steady traffic)
- [ ] Secondary indexes created for all required query patterns (avoiding `Scan` in app code)
- [ ] IAM policy scoped to least-privilege actions and specific table/index ARNs
- [ ] Encryption at rest configured
- [ ] Point-in-time recovery enabled for production tables
- [ ] DynamoDB Streams enabled if event-driven processing is needed
- [ ] TTL configured for any time-limited data
- [ ] CloudWatch alarms set for throttling and errors
- [ ] Tested Query operations return expected results using the console or CLI

---

## Cleanup (To Avoid Ongoing Charges)

1. Delete on-demand/manual backups no longer needed: **Backups** tab → select → **Delete backup**
2. Delete the table: select table → **Delete**
   - Optionally create a final backup before deleting
   - Type the table name to confirm
3. Remove associated Lambda triggers/streams if the function is reused elsewhere
4. Delete the IAM policy if not used by other resources

> DynamoDB On-demand mode has no idle cost beyond stored data and PITR — Provisioned mode capacity is billed hourly whether or not it's used, so switch idle dev/test tables to On-demand or delete them when not in use.

---

## Quick Reference Summary

| Component | Purpose |
|---|---|
| Table | Top-level container for items |
| Item | A single record (schema-less beyond key attributes) |
| Partition Key | Determines data distribution; required |
| Sort Key | Enables range queries within a partition; optional |
| GSI | Alternate query pattern with its own PK/SK |
| LSI | Alternate sort key using the same PK, set at table creation |
| Streams | Real-time feed of item-level changes |
| TTL | Automatic item expiration based on a timestamp attribute |
| PITR | Continuous backups for point-in-time restore |

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| `ProvisionedThroughputExceededException` | Provisioned capacity too low, or hot partition key | Switch to On-demand, increase capacity, or improve key distribution |
| Query returns empty despite data existing | Wrong index selected, or key value/type mismatch | Confirm correct GSI/LSI selected; check attribute type (String vs Number) matches |
| High latency on large `Scan` operations | Scanning entire table instead of using Query | Redesign access pattern with an appropriate GSI |
| `ValidationException: The provided key element does not match schema` | Missing or mistyped PK/SK in request | Verify exact attribute names and types match table schema |
| Item not auto-deleting via TTL | TTL attribute not a Number/epoch, or up to 48-hour delay | Confirm attribute type is Number; note TTL deletion isn't instantaneous |

---

## Next Steps / Advanced Topics

- **DynamoDB Accelerator (DAX)** — in-memory caching layer for microsecond read latency
- **Global Tables** — multi-region, active-active replication for global applications
- **Single-table design** — advanced pattern modeling multiple entity types in one table using generic PK/SK naming
- **Transactions** — `TransactWriteItems`/`TransactGetItems` for atomic multi-item operations
- **Infrastructure as Code** — manage tables, indexes, and streams via Terraform or AWS CloudFormation


---

<a id="chapter-10-ecs"></a>

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


---

<a id="chapter-11-route53"></a>

# Setting Up Route 53 in AWS — Complete Step-by-Step Guide

Amazon Route 53 is AWS's scalable DNS and domain registration service. This guide covers registering/migrating a domain, creating hosted zones, routing records to AWS resources, and setting up health checks with failover.

---

## Architecture Overview

```
                        Internet Users
                              │
                        DNS Query: myapp.com
                              │
                    ┌──────────────────┐
                    │   Route 53         │
                    │   Hosted Zone       │
                    │   myapp.com         │
                    │                    │
                    │  A (alias) → ALB    │
                    │  CNAME → CloudFront │
                    │  MX → Email          │
                    │  Health Checks       │
                    └──────────────────┘
                          │        │
                    ALB/CloudFront  Failover Region
```

---

## Prerequisites

- Active AWS account
- IAM user/role with `AmazonRoute53FullAccess` (or scoped equivalent) permissions
- A domain name you own (registered with Route 53 or another registrar), or intent to register one

---

## Step 1: Sign In and Open Route 53

1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in with IAM credentials
3. In the search bar, type `Route 53` and select **Route 53**

> Route 53 is a **global** service — it is not tied to a specific region.

---

## Step 2: Register a Domain (Optional — Skip If You Already Own One)

1. Left sidebar → **Domains** → **Registered domains** → **Register domain**
2. Search for your desired domain, e.g., `myapp.com`
3. Select from available options and add to cart
4. Fill in **Contact details** (registrant, admin, tech) — enable **Privacy protection** to hide these from public WHOIS lookups
5. Review pricing (varies by TLD, typically billed annually)
6. Enable **Auto-renew** (recommended, avoid losing the domain)
7. Complete purchase — registration can take a few minutes to a few hours, and email verification may be required

---

## Step 3: Create a Hosted Zone (For a Domain Registered Elsewhere)

If your domain is registered with another provider (GoDaddy, Namecheap, etc.) but you want Route 53 to manage DNS:

1. Left sidebar → **Hosted zones** → **Create hosted zone**
2. Configure:
   - Domain name: `myapp.com`
   - Type: **Public hosted zone**
3. Click **Create hosted zone**
4. Route 53 automatically creates **NS** (name server) and **SOA** records
5. Copy the 4 name server values shown, e.g.:
   ```
   ns-123.awsdns-45.com
   ns-456.awsdns-67.net
   ns-789.awsdns-01.org
   ns-012.awsdns-23.co.uk
   ```
6. Log in to your **external registrar's** dashboard and update the domain's **nameservers** to these 4 values
7. DNS propagation can take up to 48 hours, though often much faster

> If the domain was registered **through Route 53** (Step 2), the hosted zone and nameserver linkage are created automatically — skip this manual step.

---

## Step 4: Create an A Record Pointing to an EC2/ALB Resource

1. Select your hosted zone (`myapp.com`) → **Create record**
2. Configure:

| Field | Value | Notes |
|---|---|---|
| Record name | (leave blank for root domain, or enter `www`) | |
| Record type | `A – IPv4 address` | |
| Alias | **Yes** (toggle on) | Required to point to AWS resources like ALB/CloudFront |
| Route traffic to | **Alias to Application and Classic Load Balancer** | |
| Region | select your ALB's region | |
| Load balancer | select `orders-alb` (or your ALB) | |

3. **Routing policy**: **Simple routing** (default — see Step 7 for advanced policies)
4. Click **Create records**

> **Alias records** are Route 53-specific and preferred over CNAME for AWS resources — they work at the zone apex (root domain) and have no additional query charge.

---

## Step 5: Create a CNAME Record (For Subdomains Pointing to Non-AWS or Non-Alias Targets)

1. **Create record**
2. Configure:
   - Record name: `blog`
   - Record type: `CNAME`
   - Value: `myblog.wordpress.com` (or any external hostname)
   - TTL: `300` seconds
3. Click **Create records**

> CNAME cannot be used at the zone apex (`myapp.com` itself) — use an Alias A record instead for the root domain.

---

## Step 6: Create MX Records (For Email)

1. **Create record**
2. Configure:
   - Record name: (leave blank for root domain)
   - Record type: `MX`
   - Value (priority + mail server), e.g.:
     ```
     10 mail.myapp.com
     ```
     Or for Google Workspace:
     ```
     1 ASPMX.L.GOOGLE.COM
     5 ALT1.ASPMX.L.GOOGLE.COM
     5 ALT2.ASPMX.L.GOOGLE.COM
     ```
   - TTL: `3600`
3. Click **Create records**
4. Add supporting **TXT** records for SPF/DKIM/DMARC as required by your email provider

---

## Step 7: Configure Advanced Routing Policies (Optional)

Route 53 supports routing policies beyond simple A/CNAME mapping:

| Policy | Use Case |
|---|---|
| **Simple** | One record, one resource — default |
| **Weighted** | Split traffic by percentage across multiple resources (e.g., canary releases, A/B testing) |
| **Latency-based** | Route users to the AWS region with lowest latency for them |
| **Failover** | Active-passive — route to primary, switch to secondary if primary fails health checks |
| **Geolocation** | Route based on the user's geographic location |
| **Geoproximity** | Route based on geographic location with bias adjustment (requires Route 53 Traffic Flow) |
| **Multivalue answer** | Return multiple healthy IPs, client picks — simple DNS-level load distribution |

### Example: Weighted Routing for Canary Deployment

1. **Create record** → Record name: (root or subdomain)
2. Routing policy: **Weighted**
3. Create two records with the same name:
   - Record 1: Value → old version ALB, Weight: `90`
   - Record 2: Value → new version ALB, Weight: `10`
4. Assign each a unique **Record ID** (e.g., `v1-90pct`, `v2-10pct`)
5. Click **Create records** for each

---

## Step 8: Set Up Health Checks

Health checks monitor endpoint availability and can drive failover routing.

1. Left sidebar → **Health checks** → **Create health check**
2. Configure:
   - Name: `orders-app-health`
   - What to monitor: **Endpoint**
   - Specify endpoint by: **Domain name** or **IP address**
   - Protocol: `HTTPS`
   - Domain name: `myapp.com`
   - Path: `/health`
   - Request interval: `30 seconds` (standard) or `10 seconds` (fast, costs more)
   - Failure threshold: `3` consecutive failures
3. **Advanced configuration**:
   - String matching (optional): confirm response body contains `"status":"ok"`
   - Latency graphs: enable to track response time from multiple AWS regions
4. Click **Create health check**
5. (Optional) **Configure SNS notifications**:
   - Create/select an SNS topic to alert when the health check fails
   - **Health checks** → select → **Notification** tab → configure

---

## Step 9: Configure Failover Routing (High Availability)

1. **Create record** in your hosted zone
2. Routing policy: **Failover**
3. Create the **Primary** record:
   - Failover record type: **Primary**
   - Value: primary region's ALB/endpoint
   - Associate health check: `orders-app-health` (from Step 8)
4. Create the **Secondary** record:
   - Failover record type: **Secondary**
   - Value: DR region's ALB/endpoint or a static "we'll be back soon" S3 static site
   - Health check optional on secondary
5. Click **Create records** for both
6. Route 53 automatically routes to the secondary if the primary's health check fails

---

## Step 10: Validate an ACM Certificate via DNS (Common Cross-Service Task)

When requesting an SSL/TLS certificate in AWS Certificate Manager for use with CloudFront/ALB/API Gateway:

1. **ACM Console** → request a public certificate for `myapp.com` and `*.myapp.com`
2. Choose **DNS validation**
3. ACM provides a CNAME name/value pair for validation
4. Back in Route 53 → select hosted zone → ACM often shows a **Create record in Route 53** button directly on the certificate page — click it to auto-create the validation CNAME
5. Wait for certificate status to change to **Issued** (usually a few minutes)

---

## Step 11: Verify DNS Propagation

1. Use `dig` or `nslookup` locally:
   ```bash
   dig myapp.com
   dig www.myapp.com CNAME
   ```
2. Or use Route 53's built-in **Test Record** feature: select hosted zone → select a record → **Test record**
3. Confirm the returned values match your expected target (ALB DNS name, IP, etc.)
4. External propagation checkers (e.g., whatsmydns.net) can confirm global resolution, though these are third-party tools outside the AWS console

---

## Step 12: Verification Checklist

- [ ] Domain registered or nameservers correctly pointed to the Route 53 hosted zone
- [ ] Root domain uses an **Alias** A record (not CNAME) when pointing to AWS resources
- [ ] MX/TXT records configured correctly if email is hosted elsewhere
- [ ] Health checks created for critical endpoints
- [ ] Failover or weighted routing configured for high-availability/canary needs
- [ ] ACM certificate validated via DNS and shows **Issued** status
- [ ] DNS resolution tested and confirmed via `dig`/`nslookup`
- [ ] TTLs set appropriately (lower before planned cutovers, higher for stability afterward)

---

## Cleanup (To Avoid Ongoing Charges)

1. Delete unused records: select hosted zone → select record(s) → **Delete**
2. Delete health checks no longer in use: **Health checks** → select → **Delete**
3. Delete the hosted zone if the domain is being decommissioned: **Hosted zones** → select → **Delete zone** (must remove all non-default records first)
4. Domain registration fees are annual and separate from hosted zone charges — cancel auto-renew before expiry if not keeping the domain

> Hosted zones incur a small monthly charge per zone plus per-query charges; health checks also bill per check — clean up unused ones periodically.

---

## Quick Reference Summary

| Component | Purpose |
|---|---|
| Hosted Zone | Container for all DNS records for a domain |
| Record | Maps a name to a value (A, CNAME, MX, TXT, etc.) |
| Alias Record | Route 53-specific record pointing to AWS resources, works at zone apex |
| Routing Policy | Determines how Route 53 responds when multiple records exist |
| Health Check | Monitors endpoint availability, can drive failover |
| TTL | How long resolvers cache a record's answer |

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| Domain not resolving after setup | Nameservers not updated at registrar, or propagation delay | Verify NS records at registrar match hosted zone; wait up to 48 hours |
| `CNAME` record fails at root domain | CNAME not allowed at zone apex | Use an Alias A record instead |
| ACM certificate stuck in `Pending validation` | DNS validation CNAME not created or propagated | Confirm the validation record exists in the hosted zone; wait a few minutes |
| Failover not triggering | Health check misconfigured or still passing | Verify health check path/protocol matches the actual endpoint behavior |
| Old IP still resolving after change | High TTL cached by resolvers | Lower TTL in advance of planned changes; wait out the previous TTL |

---

## Next Steps / Advanced Topics

- **Route 53 Resolver** — DNS resolution between VPCs and on-premises networks (hybrid DNS)
- **Route 53 Traffic Flow** — visual policy editor for complex multi-condition routing
- **Private Hosted Zones** — internal DNS resolution scoped to one or more VPCs
- **DNSSEC** — cryptographic signing to prevent DNS spoofing
- **Infrastructure as Code** — manage hosted zones and records via Terraform or AWS CloudFormation


---

<a id="chapter-12-cloudfront"></a>

# Setting Up CloudFront in AWS — Complete Step-by-Step Guide

Amazon CloudFront is AWS's global content delivery network (CDN) — it caches content at edge locations worldwide for low-latency delivery, and also provides HTTPS termination, DDoS protection (via AWS Shield), and request routing for both static and dynamic content.

---

## Architecture Overview

```
                     Global Users
                          │
                 ┌─────────────────┐
                 │  CloudFront Edge  │
                 │  Locations (300+) │
                 └────────┬────────┘
                          │ (cache miss)
              ┌───────────┴────────────┐
              │                        │
        S3 Origin                  ALB / EC2 / API GW
     (static assets)              (dynamic content)
              │                        │
        Origin Access Control    Custom Origin
        (OAC) — private bucket    (public endpoint)
```

---

## Prerequisites

- Active AWS account
- IAM user/role with `CloudFrontFullAccess` (or scoped equivalent) permissions
- An origin to serve content from — an S3 bucket (see companion *AWS S3 Creation Guide*) and/or an ALB/API Gateway endpoint
- (Optional) A custom domain and ACM certificate — see companion *AWS Route 53 Creation Guide*, Step 10

---

## Step 1: Sign In and Open CloudFront

1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in with IAM credentials
3. In the search bar, type `CloudFront` and select **CloudFront**

> CloudFront is a **global** service, though its console is typically accessed from `us-east-1`. Any ACM certificate used with CloudFront must be requested in `us-east-1`, regardless of where your origin resources live.

---

## Step 2: Prepare Your Origin

### Option A: S3 Bucket (Static Content)

1. Ensure you have an S3 bucket with your content uploaded (e.g., `my-app-bucket-prod-2026`)
2. Keep **Block Public Access enabled** on the bucket — CloudFront will access it privately via Origin Access Control (configured in Step 4), so the bucket itself never needs to be public

### Option B: ALB / API Gateway / Custom HTTP Origin (Dynamic Content)

1. Ensure your ALB or API Gateway is deployed and reachable (see companion guides)
2. Note its DNS name/endpoint, e.g., `orders-alb-123456.ap-south-1.elb.amazonaws.com`

---

## Step 3: Create a CloudFront Distribution

1. Left sidebar → **Distributions** → **Create distribution**
2. **Origin**:
   - **Origin domain**: click the field — it auto-suggests your S3 buckets and other AWS resources; select `my-app-bucket-prod-2026.s3.ap-south-1.amazonaws.com`
   - **Origin path**: (optional) e.g., `/static` if content lives in a subfolder
   - **Name**: auto-fills, can customize
   - **Origin access**: see Step 4

---

## Step 4: Configure Origin Access Control (OAC) — For S3 Origins

OAC lets CloudFront access a **private** S3 bucket securely, without making the bucket public.

1. Under **Origin access**, select **Origin access control settings (recommended)**
2. Click **Create control setting**
3. Configure:
   - Name: `my-app-bucket-oac`
   - Signing behavior: **Sign requests (recommended)**
4. Click **Create**
5. After the distribution is created, CloudFront shows a **bucket policy** you must add to the S3 bucket — copy it
6. Go to **S3 Console** → your bucket → **Permissions** → **Bucket policy** → **Edit** → paste the provided policy → **Save changes**
   - This policy allows only this specific CloudFront distribution to read from the bucket

---

## Step 5: Configure Default Cache Behavior

1. **Viewer protocol policy**: **Redirect HTTP to HTTPS** (recommended default)
2. **Allowed HTTP methods**:
   - `GET, HEAD` — for static/read-only content
   - `GET, HEAD, OPTIONS, PUT, POST, PATCH, DELETE` — if proxying a dynamic API through CloudFront
3. **Cache policy**:
   - **CachingOptimized** (managed policy) — good default for static assets, ignores query strings/cookies
   - **CachingDisabled** — for dynamic content that shouldn't be cached
   - Or create a **custom cache policy** to control TTL and which headers/query strings/cookies affect the cache key
4. **Origin request policy** (if forwarding data to a dynamic origin):
   - `AllViewer` — forwards all headers/cookies/query strings to the origin (needed for APIs)
5. **Response headers policy** (optional): add security headers like `Strict-Transport-Security`, `X-Content-Type-Options`

---

## Step 6: Configure Distribution Settings

1. **Price class**:

| Price Class | Coverage | Cost |
|---|---|---|
| Use all edge locations | Global | Highest |
| Use North America, Europe, Asia | Most major regions | Medium |
| Use only North America and Europe | Limited | Lowest |

   Select based on where your users actually are.

2. **WAF (Web Application Firewall)**: enable if you want to attach AWS WAF rules for protection against common exploits (additional cost)
3. **Alternate domain name (CNAME)**: add `cdn.myapp.com` if using a custom domain (requires an ACM certificate in `us-east-1` — see Step 8)
4. **Custom SSL certificate**: select your ACM certificate once added
5. **Default root object**: `index.html` (for static website distributions)
6. **Standard logging** (optional): enable and select/create an S3 bucket to store access logs
7. Click **Create distribution**
8. Status shows `Deploying` → wait for `Enabled` (typically 5–15 minutes for global edge propagation)

---

## Step 7: Test the Distribution

1. Copy the auto-generated **Distribution domain name**, e.g.:
   ```
   d1234abcd5678.cloudfront.net
   ```
2. Test in browser or via curl:
   ```bash
   curl -I https://d1234abcd5678.cloudfront.net/index.html
   ```
3. Confirm response headers include `x-cache: Hit from cloudfront` (on repeated requests) or `Miss from cloudfront` (first request)
4. Confirm content matches what's in your S3 bucket/origin

---

## Step 8: Attach a Custom Domain (Optional)

1. **ACM Console** (must be in **us-east-1** region regardless of where your resources live) → **Request certificate**
2. Domain names: `cdn.myapp.com` (and/or `myapp.com`, `*.myapp.com`)
3. Validation method: **DNS validation**
4. Complete validation via Route 53 (see companion *AWS Route 53 Creation Guide*, Step 10)
5. Wait for status: **Issued**
6. Return to your CloudFront distribution → **Edit** → **Settings**:
   - Alternate domain name (CNAME): `cdn.myapp.com`
   - Custom SSL certificate: select the newly issued certificate
7. Click **Save changes**
8. In **Route 53**, create an **Alias A record**:
   - Record name: `cdn`
   - Route traffic to: **Alias to CloudFront distribution**
   - Select your distribution
9. Click **Create records**
10. Test: `curl -I https://cdn.myapp.com`

---

## Step 9: Add Additional Cache Behaviors (Path-Based Routing)

Route different URL paths to different origins or apply different caching rules — e.g., `/api/*` goes to a dynamic backend while everything else is cached static content.

1. Select the distribution → **Behaviors** tab → **Create behavior**
2. Configure:
   - Path pattern: `/api/*`
   - Origin: select or add your ALB/API Gateway origin
   - Cache policy: **CachingDisabled**
   - Origin request policy: `AllViewer`
   - Viewer protocol policy: **Redirect HTTP to HTTPS**
3. Click **Create behavior**
4. CloudFront evaluates behaviors in priority order (top of list = highest priority) — reorder as needed via **Behaviors** tab → **Edit priority**

---

## Step 10: Configure Origin Failover (High Availability)

1. Select the distribution → **Origins** tab → ensure at least two origins are configured (e.g., primary S3 bucket + backup S3 bucket in another region)
2. **Origin groups** tab → **Create origin group**
3. Select primary and secondary origins
4. Failover criteria: HTTP status codes (e.g., `403, 404, 500, 502, 503, 504`)
5. Click **Create origin group**
6. Update the relevant cache behavior to point to this **origin group** instead of a single origin

---

## Step 11: Invalidate the Cache (After Updating Content)

When you update files in S3 but CloudFront is still serving the old cached version:

1. Select the distribution → **Invalidations** tab → **Create invalidation**
2. Object paths: `/*` (invalidate everything) or specific paths like `/images/logo.png`
3. Click **Create invalidation**
4. Wait for status to change to **Completed** (usually under a minute)

> Invalidations have a monthly free allotment, then incur a small per-path charge — for frequent deploys, prefer **versioned file names** (e.g., `app.v2.js`) over invalidating `/*` every time.

---

## Step 12: Monitor with CloudWatch

1. Select the distribution → **Monitoring** tab (or **CloudWatch** → `CloudFront` namespace, always in `us-east-1`)
2. Review:
   - **Requests** — total traffic volume
   - **4xx/5xx error rate** — client/origin errors
   - **Cache hit rate** — percentage served from edge vs. origin (higher is better/cheaper)
   - **Total bytes downloaded/uploaded**
3. Set a CloudWatch alarm on `5xxErrorRate` exceeding a threshold to catch origin failures early

---

## Step 13: Verification Checklist

- [ ] Origin configured correctly (S3 with OAC, or ALB/API Gateway)
- [ ] S3 bucket policy updated to allow only this CloudFront distribution (if using OAC)
- [ ] Viewer protocol policy forces HTTPS
- [ ] Cache policy matches content type (long TTL for static assets, disabled/short for dynamic APIs)
- [ ] Custom domain configured with ACM certificate issued in `us-east-1`
- [ ] Route 53 alias record points to the distribution
- [ ] Path-based behaviors correctly prioritized if multiple origins are used
- [ ] Logging enabled for audit/troubleshooting
- [ ] Cache invalidation tested after a content update
- [ ] CloudWatch alarms configured for error rate monitoring

---

## Cleanup (To Avoid Ongoing Charges)

1. Disable the distribution first: select → **Disable** (required before deletion)
2. Wait for status to change to **Deployed** (disabled state fully propagated)
3. Delete the distribution: select → **Delete**
4. Remove the Route 53 alias record pointing to it
5. Remove the S3 bucket policy statement granting the OAC access (if bucket is reused elsewhere)
6. Delete the ACM certificate if unused by other resources
7. Delete the CloudFront access log S3 bucket/objects if no longer needed

> CloudFront has a perpetual free tier for data transfer and requests up to certain limits — usage beyond that, plus invalidations beyond the free allotment, incur charges.

---

## Quick Reference Summary

| Component | Purpose |
|---|---|
| Distribution | The CDN configuration tying origins, behaviors, and domains together |
| Origin | The backend CloudFront fetches content from (S3, ALB, custom HTTP) |
| Origin Access Control (OAC) | Lets CloudFront securely access a private S3 bucket |
| Cache Behavior | Path-based rules controlling caching and routing |
| Cache Policy | Defines TTL and what varies the cache key (headers/cookies/query strings) |
| Invalidation | Forces removal of cached content before natural TTL expiry |
| Origin Group | Primary/secondary origin pairing for automatic failover |

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| `403 Forbidden` from CloudFront (S3 origin) | OAC bucket policy missing/incorrect | Re-copy and apply the bucket policy CloudFront generates for the OAC |
| Old content still served after update | Cache TTL hasn't expired | Create an invalidation, or use versioned file names |
| Custom domain SSL error | Certificate not in `us-east-1`, or not attached to distribution | Re-request ACM certificate in `us-east-1`; attach in distribution settings |
| Dynamic API returns cached/stale responses | Cache policy applied to API path is caching when it shouldn't | Use `CachingDisabled` policy on API path patterns |
| High origin load despite CDN | Low cache hit rate — TTL too short, or cache key too broad (varies by every header/cookie) | Review cache policy; increase TTL for cacheable content, narrow cache key |

---

## Next Steps / Advanced Topics

- **Lambda@Edge / CloudFront Functions** — run lightweight code at edge locations for redirects, header manipulation, A/B testing
- **Signed URLs / Signed Cookies** — restrict access to private content (e.g., paid video content)
- **Field-Level Encryption** — encrypt specific sensitive fields end-to-end through the CDN
- **Real-time logs** — stream request logs to Kinesis for near-instant analytics
- **Infrastructure as Code** — manage distributions, behaviors, and origins via Terraform or AWS CloudFormation


---

<a id="chapter-13-sns-sqs"></a>

# Setting Up SNS and SQS in AWS — Complete Step-by-Step Guide

Amazon SNS (Simple Notification Service) and SQS (Simple Queue Service) are AWS's core messaging services — SNS for pub/sub fan-out notifications, SQS for durable, decoupled message queuing. This guide covers both individually and the common **SNS → SQS fan-out** pattern used to decouple microservices.

---

## Architecture Overview

```
                    Event Source
                  (app, S3, CloudWatch)
                          │
                    ┌─────▼─────┐
                    │  SNS Topic │
                    │ order-events│
                    └─────┬─────┘
              ┌───────────┼────────────┐
              │           │            │
        ┌─────▼────┐ ┌────▼─────┐ ┌───▼────┐
        │ SQS Queue │ │ SQS Queue │ │ Lambda  │
        │ (billing) │ │(shipping) │ │(email)  │
        └─────┬────┘ └────┬─────┘ └────────┘
              │           │
        Billing Service  Shipping Service
        (polls queue)    (polls queue)

        Failed messages ──► Dead-Letter Queue (DLQ)
```

---

## Prerequisites

- Active AWS account
- IAM user/role with `AmazonSNSFullAccess` and `AmazonSQSFullAccess` (or scoped equivalents)

### SNS vs. SQS — When to Use Which

| Service | Model | Use Case |
|---|---|---|
| **SNS** | Pub/Sub — pushes to multiple subscribers immediately | Fan-out notifications, alerts (email/SMS), triggering multiple downstream systems at once |
| **SQS** | Point-to-point — consumers pull messages at their own pace | Decoupling producers/consumers, buffering load spikes, ensuring durable processing with retries |
| **SNS + SQS together** | Fan-out | One event needs to reliably reach multiple independent consumers, each processing at their own pace |

---

## Part A: Setting Up SNS

### Step A1: Sign In and Select Region

1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in with IAM credentials
3. Select your target **region** (e.g., `Asia Pacific (Mumbai) ap-south-1`)

### Step A2: Create an SNS Topic

1. In the search bar, type `SNS` and select **Simple Notification Service**
2. Left sidebar → **Topics** → **Create topic**
3. **Type**:

| Type | Ordering | Throughput | Use Case |
|---|---|---|---|
| **Standard** | Best-effort ordering | Nearly unlimited | Most use cases |
| **FIFO** | Strict ordering, exactly-once | Up to 300 msg/sec (3,000 batched) | Order-sensitive workflows (e.g., financial transactions) |

   Select **Standard** for this guide

4. Configure:
   - Name: `order-events`
   - Display name: `OrderEvents` (used as SMS sender ID prefix)
5. **Encryption**: enable **Server-side encryption** using an AWS managed KMS key (recommended for sensitive data)
6. **Access policy**: leave default (topic owner only) — refine in Step A5 if cross-account access is needed
7. Click **Create topic**
8. Note the **Topic ARN**, e.g.:
   ```
   arn:aws:sns:ap-south-1:123456789012:order-events
   ```

### Step A3: Subscribe an Email Endpoint

1. Select the topic → **Create subscription**
2. Protocol: **Email**
3. Endpoint: `ops-team@company.com`
4. Click **Create subscription**
5. Check the inbox for a confirmation email from AWS → click **Confirm subscription**
6. Subscription status changes from `Pending confirmation` to `Confirmed`

### Step A4: Subscribe an SMS Endpoint (Optional)

1. **Create subscription** → Protocol: **SMS** → Endpoint: `+919876543210` (E.164 format)
2. Click **Create subscription** — no confirmation step required for SMS
3. Note: SMS has per-message costs and country-specific sending restrictions; check the **Text messaging (SMS)** preferences page for spending limits

### Step A5: Publish a Test Message

1. Select the topic → **Publish message**
2. Subject: `Test Notification`
3. Message body: `This is a test message from SNS.`
4. Click **Publish message**
5. Confirm delivery to subscribed email/SMS endpoints

### Step A6: Set an Access Policy for Cross-Service Publishing (e.g., from S3 or CloudWatch)

1. Select the topic → **Edit** → **Access policy**
2. Example — allow S3 to publish to this topic:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "AllowS3Publish",
         "Effect": "Allow",
         "Principal": {"Service": "s3.amazonaws.com"},
         "Action": "SNS:Publish",
         "Resource": "arn:aws:sns:ap-south-1:123456789012:order-events",
         "Condition": {
           "ArnLike": {"aws:SourceArn": "arn:aws:s3:::my-app-bucket-prod-2026"}
         }
       }
     ]
   }
   ```
3. Click **Save changes**

---

## Part B: Setting Up SQS

### Step B1: Create a Standard Queue

1. In the search bar, type `SQS` and select **Simple Queue Service**
2. Click **Create queue**
3. **Type**:
   - **Standard** (default) — nearly unlimited throughput, at-least-once delivery, best-effort ordering
   - **FIFO** — strict ordering and exactly-once processing, name must end in `.fifo`, lower throughput
4. Name: `billing-queue`
5. **Configuration**:

| Field | Value | Notes |
|---|---|---|
| Visibility timeout | `30 seconds` | How long a message is hidden after being received, before it's visible again for retry |
| Message retention period | `4 days` (default) | Up to 14 days max |
| Delivery delay | `0 seconds` | Delay before a new message becomes visible |
| Receive message wait time | `10 seconds` | Enables long polling — reduces empty responses and cost |
| Maximum message size | `256 KB` (default) | Use S3 + a reference for larger payloads |

6. **Encryption**: enable **SSE (Server-side encryption)** with an AWS managed KMS key
7. Click **Create queue**
8. Note the **Queue URL** and **ARN**, e.g.:
   ```
   https://sqs.ap-south-1.amazonaws.com/123456789012/billing-queue
   arn:aws:sqs:ap-south-1:123456789012:billing-queue
   ```

### Step B2: Create a Dead-Letter Queue (DLQ)

Messages that repeatedly fail processing are moved to a DLQ instead of being retried forever or silently lost.

1. First create a second queue for the DLQ: **Create queue** → Name: `billing-queue-dlq` → same type as the source (Standard/FIFO must match) → **Create queue**
2. Go back to the source queue (`billing-queue`) → **Edit**
3. Scroll to **Dead-letter queue** → **Enable**
4. Choose the DLQ: `billing-queue-dlq`
5. **Maximum receives**: `3` (message moves to DLQ after 3 failed processing attempts)
6. Click **Save**

### Step B3: Send and Receive Test Messages

1. Select the queue → **Send and receive messages**
2. Under **Send message**, enter a message body:
   ```json
   {"orderId": "ORD-1001", "amount": 149.99}
   ```
3. Click **Send message**
4. Under **Receive messages**, click **Poll for messages**
5. Confirm the message appears — click on it to view the body
6. Click **Delete** to remove it from the queue after processing (simulates what a consumer application does)

### Step B4: Set Up IAM Permissions for Producers/Consumers

1. **IAM Console** → **Policies** → **Create policy** → **JSON** tab
2. Example — allow an application to send and receive from the queue:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "sqs:SendMessage",
           "sqs:ReceiveMessage",
           "sqs:DeleteMessage",
           "sqs:GetQueueAttributes"
         ],
         "Resource": "arn:aws:sqs:ap-south-1:123456789012:billing-queue"
       }
     ]
   }
   ```
3. Attach to the relevant Lambda execution role or application IAM role

---

## Part C: SNS → SQS Fan-Out Pattern

Connect SNS to multiple SQS queues so a single published event reliably reaches multiple independent consumers.

### Step C1: Subscribe SQS Queues to the SNS Topic

1. Go to **SNS Console** → select `order-events` topic → **Create subscription**
2. Protocol: **Amazon SQS**
3. Endpoint: select the queue ARN, e.g., `arn:aws:sqs:ap-south-1:123456789012:billing-queue`
4. Click **Create subscription**
5. Repeat for additional queues (e.g., `shipping-queue`, `email-queue`) to fan out the same event to multiple consumers

### Step C2: Grant SNS Permission to Send to the Queue

Usually configured automatically when subscribing through the console, but verify:

1. Go to **SQS Console** → select `billing-queue` → **Access policy** tab → **Edit**
2. Confirm a statement exists allowing `sns.amazonaws.com` to send messages, scoped to the specific topic ARN via a `Condition`
3. If missing, add manually:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "AllowSNSPublish",
         "Effect": "Allow",
         "Principal": {"Service": "sns.amazonaws.com"},
         "Action": "sqs:SendMessage",
         "Resource": "arn:aws:sqs:ap-south-1:123456789012:billing-queue",
         "Condition": {
           "ArnEquals": {"aws:SourceArn": "arn:aws:sns:ap-south-1:123456789012:order-events"}
         }
       }
     ]
   }
   ```

### Step C3: Test the Fan-Out

1. Go to the SNS topic → **Publish message**
2. Message body:
   ```json
   {"orderId": "ORD-1002", "status": "CREATED"}
   ```
3. Click **Publish message**
4. Go to each subscribed SQS queue → **Send and receive messages** → **Poll for messages**
5. Confirm the same message appears in **all** subscribed queues independently

### Step C4: (Optional) Add Subscription Filter Policies

Route only relevant messages to each queue instead of sending everything to everyone.

1. Select the SNS subscription (e.g., the one linking to `billing-queue`) → **Edit**
2. **Subscription filter policy** → enable
3. Example — only deliver messages where `eventType` is `PAYMENT`:
   ```json
   {
     "eventType": ["PAYMENT"]
   }
   ```
4. Click **Save changes**
5. Now publish messages with a `MessageAttributes` field matching `eventType` — only matching subscriptions receive them

---

## Step D: Connect Lambda as an SQS Consumer

1. **Lambda Console** → select/create a function → **Add trigger**
2. Source: **SQS**
3. Select the queue (e.g., `billing-queue`)
4. Batch size: `10`
5. Batch window: `0` seconds (or add a few seconds to batch more messages per invocation)
6. Click **Add**
7. Lambda automatically polls the queue and invokes your function with a batch of messages — no manual polling code needed

---

## Step E: Monitor with CloudWatch

1. **SNS**: select topic → **Monitoring** tab — review `NumberOfMessagesPublished`, `NumberOfNotificationsFailed`
2. **SQS**: select queue → **Monitoring** tab — review:
   - `ApproximateNumberOfMessagesVisible` — queue backlog
   - `ApproximateAgeOfOldestMessage` — processing lag
   - `NumberOfMessagesSent` / `NumberOfMessagesDeleted`
3. Set alarms:
   - SQS: alarm if `ApproximateNumberOfMessagesVisible` stays high (consumers falling behind)
   - SQS: alarm if DLQ (`billing-queue-dlq`) receives any messages — indicates repeated processing failures needing investigation
   - SNS: alarm on `NumberOfNotificationsFailed` > 0

---

## Verification Checklist

- [ ] SNS topic created with appropriate type (Standard/FIFO) and encryption enabled
- [ ] Email/SMS subscriptions confirmed (check for confirmation email)
- [ ] SQS queue created with appropriate visibility timeout and retention period
- [ ] Dead-letter queue configured with a sensible max-receive threshold
- [ ] IAM policies scoped to specific topic/queue ARNs, not wildcard resources
- [ ] SNS → SQS fan-out tested end-to-end (message appears in all subscribed queues)
- [ ] Filter policies applied where only a subset of consumers should receive certain messages
- [ ] Lambda SQS trigger tested and processing messages successfully
- [ ] CloudWatch alarms configured for DLQ message count and queue backlog age

---

## Cleanup (To Avoid Ongoing Charges)

1. Delete SNS subscriptions: select topic → select subscription(s) → **Delete**
2. Delete the SNS topic: select → **Delete**
3. Delete SQS queues (including the DLQ): select → **Delete**
4. Remove associated IAM policies if unused elsewhere
5. Remove Lambda triggers referencing deleted queues

> SNS and SQS both have generous free tiers (1 million requests/month each) — typical dev/test usage often stays within free tier, but clean up unused topics/queues to avoid clutter and potential misuse.

---

## Quick Reference Summary

| Component | Purpose |
|---|---|
| SNS Topic | Pub/sub channel — pushes messages to all subscribers |
| SNS Subscription | Endpoint (email, SMS, SQS, Lambda, HTTP) receiving topic messages |
| SQS Queue | Durable, pull-based message buffer |
| Visibility Timeout | Grace period before an unprocessed message becomes visible again |
| Dead-Letter Queue (DLQ) | Captures repeatedly failed messages for investigation |
| Filter Policy | Restricts which messages a subscriber receives |
| Long Polling | Reduces empty receive responses and API call costs |

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| Email subscription not receiving messages | Subscription still `Pending confirmation` | Check inbox/spam for AWS confirmation email, click confirm |
| SQS queue not receiving from SNS | Missing SQS access policy statement allowing SNS to publish | Add/verify the access policy shown in Step C2 |
| Messages disappearing without being processed | Visibility timeout too short — consumer takes longer than timeout, message becomes visible again and is picked up by another consumer/duplicated | Increase visibility timeout to exceed your typical processing time |
| Messages piling up in DLQ | Consumer code throwing errors on every attempt | Check consumer logs (CloudWatch); fix the underlying processing bug, then redrive messages from DLQ back to source queue |
| Duplicate message processing | Standard queue's at-least-once delivery model (expected behavior) | Design consumers to be idempotent, or switch to a FIFO queue for exactly-once processing |

---

## Next Steps / Advanced Topics

- **SQS FIFO Queues with Message Deduplication** — exactly-once processing for order-sensitive workflows
- **SNS Message Filtering with Multiple Attributes** — complex routing logic across many consumer types
- **Redrive to source queue** — reprocess DLQ messages via the console's **Start DLQ redrive** feature after fixing the root cause
- **EventBridge as an alternative** — richer event routing/filtering than SNS for many AWS-native event sources
- **Infrastructure as Code** — manage topics, queues, and subscriptions via Terraform or AWS CloudFormation


---

<a id="chapter-14-waf"></a>

# Setting Up AWS WAF — Complete Step-by-Step Guide

AWS WAF (Web Application Firewall) protects web applications from common exploits — SQL injection, XSS, bot traffic, and volumetric attacks — by filtering requests before they reach CloudFront, ALB, API Gateway, or AppSync. This guide covers creating a Web ACL, adding managed and custom rules, and monitoring blocked traffic.

---

## Architecture Overview

```
                    Internet Traffic
                          │
                  ┌───────────────┐
                  │   AWS WAF       │
                  │   Web ACL        │
                  │                 │
                  │  Managed Rules   │
                  │  Custom Rules    │
                  │  Rate Limiting   │
                  │  IP Sets         │
                  └───────┬────────┘
                          │ (allowed traffic only)
              ┌───────────┴────────────┐
              │            │           │
        CloudFront       ALB      API Gateway
```

---

## Prerequisites

- Active AWS account
- IAM user/role with `AWSWAFFullAccess` (or scoped equivalent) permissions
- An existing resource to protect: CloudFront distribution, Application Load Balancer, API Gateway REST API, or AppSync GraphQL API

---

## Step 1: Sign In and Open WAF

1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in with IAM credentials
3. In the search bar, type `WAF` and select **WAF & Shield**

> **Region note:** For CloudFront, WAF must be configured in the **Global (CloudFront)** scope, viewed from `us-east-1`. For ALB, API Gateway, or AppSync, select **Regional** and your target region.

---

## Step 2: Create a Web ACL

1. Left sidebar → **Web ACLs** → **Create web ACL**
2. **Web ACL details**:

| Field | Value | Notes |
|---|---|---|
| Name | `orders-app-waf` | |
| Description | `Protects orders-alb from common exploits` | |
| Resource type | **Regional** or **CloudFront** | Match to what you're protecting |
| Region | your region (if Regional) | |

3. **Associated AWS resources**:
   - Click **Add AWS resources**
   - Select your ALB, API Gateway stage, or CloudFront distribution
   - Click **Add**
4. Click **Next**

---

## Step 3: Add AWS Managed Rule Groups

Managed rule groups are pre-built, AWS-maintained rulesets covering common threats — the fastest way to get solid baseline protection.

1. On the **Rules** step, click **Add rules** → **Add managed rule groups**
2. Expand **AWS managed rule groups** and add:

| Rule Group | Protects Against |
|---|---|
| **Core rule set (CRS)** | Broad OWASP Top 10 coverage — generally recommended for all apps |
| **Known bad inputs** | Requests matching patterns of known exploitation attempts |
| **SQL database** | SQL injection attempts |
| **Amazon IP reputation list** | Requests from IPs with poor reputation (known bad actors) |
| **Anonymous IP list** | Traffic from VPNs, proxies, Tor exit nodes |
| **Bot Control** (additional cost) | Identifies and manages bot traffic |

3. For each, set the action:
   - **Block** — reject matching requests outright (recommended once confident in the rule)
   - **Count** — log but allow through (use first, to observe false positives before switching to Block)
4. Click **Add rules**

> **Best practice:** Start every managed rule group in **Count** mode for 24–48 hours, review the traffic in CloudWatch/Sampled requests (Step 7), then switch to **Block** once you've confirmed no legitimate traffic is being flagged.

---

## Step 4: Add a Rate-Based Rule (Prevent Brute Force / DDoS-Style Abuse)

1. On the **Rules** step → **Add rules** → **Add my own rules and rule groups**
2. Rule type: **Rate-based rule**
3. Configure:
   - Name: `rate-limit-per-ip`
   - Rate limit: `2000` requests per 5-minute period per IP (adjust based on expected traffic)
   - Aggregation key: **IP address** (or use a custom key like a header/cookie for API keys)
4. Action if the rate limit is exceeded: **Block**
5. Click **Add rule**

---

## Step 5: Add a Custom Rule (IP Allow/Block List)

1. **Create IP set** first: left sidebar → **IP sets** → **Create IP set**
   - Name: `office-allowlist`
   - IP version: IPv4
   - Addresses: `203.0.113.0/24` (your office/VPN CIDR)
   - Click **Create IP set**
2. Back in the Web ACL rules step → **Add my own rules and rule groups** → **Rule builder**
3. Configure:
   - Name: `allow-admin-path-from-office`
   - Type: **Regular rule**
   - If a request: **matches the statement**
   - Statement 1: **Originates from an IP address in** → select `office-allowlist`
   - AND
   - Statement 2: **URI path** → **Starts with** → `/admin`
   - Action: **Allow**
4. Click **Add rule**

### Common Custom Rule Examples

| Rule | Statement | Action |
|---|---|---|
| Block a known malicious IP | Source IP in a block-list IP set | Block |
| Restrict admin panel | URI starts with `/admin` AND source not in office IP set | Block |
| Block specific user agents | Header `User-Agent` contains known scraper strings | Block |
| Geo-blocking | Country code is NOT in allowed list (e.g., only allow `IN, US, GB`) | Block |
| SQLi on specific field | Body/query param matches SQL injection pattern | Block |

---

## Step 6: Set Rule Priority and Default Action

1. On the **Rules** step, drag to reorder rules — WAF evaluates rules **in priority order** (lower number = evaluated first) and stops at the first matching terminating action (Block/Allow)
2. Recommended order:
   1. Explicit allow rules (e.g., office IP allowlist for admin paths)
   2. Rate-based rules
   3. AWS managed rule groups
   4. Custom block rules
3. **Default web ACL action for requests that don't match any rules**:
   - **Allow** (most common — block only what you explicitly flag)
   - **Block** (allowlist-only model — more restrictive, requires explicit allow rules for all legitimate traffic)
4. Click **Next** → review → **Create web ACL**

---

## Step 7: Review Sampled Requests and Metrics

1. Select the Web ACL → **Sampled requests** tab
2. Filter by rule to see which requests matched (allowed/blocked) and why
3. Use this to identify false positives when a managed rule group is in **Count** mode before switching to **Block**
4. **Requests** tab → view aggregate metrics: total requests, allowed, blocked, by rule

---

## Step 8: Enable Logging

1. Select the Web ACL → **Logging and metrics** tab → **Enable logging**
2. Choose a destination:
   - **Amazon CloudWatch Logs** (log group, e.g., `aws-waf-logs-orders-app`)
   - **Amazon S3** (for long-term storage/analysis, e.g., with Athena)
   - **Amazon Kinesis Data Firehose** (for streaming to other analytics tools)
3. **Redacted fields** (optional): redact sensitive headers like `Authorization` or `Cookie` from logs
4. Click **Save**

---

## Step 9: Set Up CloudWatch Alarms

1. **CloudWatch Console** → **Alarms** → **Create alarm**
2. Metric: `BlockedRequests` for the Web ACL, namespace `AWS/WAFV2`
3. Threshold: e.g., `> 1000` blocked requests in 5 minutes — could indicate an active attack
4. Notification: SNS topic for the security/ops team
5. Repeat for `CountedRequests` if you want visibility into rules still in Count mode picking up unusual volume

---

## Step 10: Test the Web ACL

1. Send a benign request to confirm normal traffic still works:
   ```bash
   curl -I https://myapp.com/
   ```
   Expect a normal `200`/`302` response.
2. Send a request simulating a blocked pattern (e.g., SQLi test string) to confirm it's blocked:
   ```bash
   curl "https://myapp.com/search?q=' OR '1'='1"
   ```
   Expect a `403 Forbidden` response from WAF.
3. Check **Sampled requests** to confirm which rule triggered the block

---

## Step 11: Verification Checklist

- [ ] Web ACL created with correct scope (Regional vs. CloudFront) matching the protected resource
- [ ] Resource (ALB/CloudFront/API Gateway) associated with the Web ACL
- [ ] AWS managed rule groups added and validated in Count mode before switching to Block
- [ ] Rate-based rule configured to prevent abuse/brute force
- [ ] Custom rules cover known application-specific risks (admin paths, geo-restrictions, etc.)
- [ ] Rule priority ordered correctly (allow-lists before block-lists)
- [ ] Logging enabled to CloudWatch/S3 with sensitive headers redacted
- [ ] CloudWatch alarms configured for spikes in blocked/counted requests
- [ ] Tested both legitimate and malicious sample requests to confirm expected behavior

---

## Cleanup (To Avoid Ongoing Charges)

1. Disassociate the Web ACL from resources: select Web ACL → **Associated AWS resources** → select → **Disassociate**
2. Delete the Web ACL: select → **Delete**
3. Delete unused IP sets: **IP sets** → select → **Delete**
4. Delete the CloudWatch log group / S3 bucket used for WAF logs if no longer needed

> WAF bills per Web ACL per month plus per-rule and per-million-requests charges — remove unused Web ACLs and rule groups (especially Bot Control, which has a higher cost) when not actively needed.

---

## Quick Reference Summary

| Component | Purpose |
|---|---|
| Web ACL | The top-level container of rules, associated with protected resources |
| Managed Rule Group | AWS-maintained ruleset for common threats |
| Custom Rule | User-defined condition and action (block/allow/count) |
| Rate-Based Rule | Blocks IPs exceeding a request-rate threshold |
| IP Set | Reusable list of IP addresses/CIDRs referenced by rules |
| Sampled Requests | Sample of recent requests showing which rule matched |
| Default Action | Fallback behavior for requests matching no explicit rule |

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| Legitimate users getting blocked (403) | Managed rule group too aggressive, or overly broad custom rule | Check Sampled requests to identify the matching rule; switch to Count mode, adjust, or add an allow exception |
| WAF not blocking expected malicious traffic | Rule not associated with the correct resource, or rule in Count mode | Confirm resource association; verify rule action is set to Block |
| No logs appearing | Logging not enabled, or IAM/resource policy issue on log destination | Verify logging configuration and destination permissions |
| Rate-based rule not triggering | Aggregation key mismatch (e.g., traffic behind a shared NAT/proxy all appears as one IP, or as many different IPs) | Adjust aggregation key or threshold; consider header-based aggregation for API traffic |
| High false-positive rate from Core Rule Set | Application legitimately uses patterns resembling attacks (e.g., HTML in form fields) | Add rule exclusions for specific labels within the managed rule group |

---

## Next Steps / Advanced Topics

- **AWS Shield Advanced** — enhanced DDoS protection with 24/7 DRT (DDoS Response Team) support, layered with WAF
- **AWS Firewall Manager** — centrally manage WAF rules across many accounts/resources in an AWS Organization
- **Custom response bodies** — return a friendly error page instead of the default 403 for blocked requests
- **CAPTCHA and Challenge actions** — interactive verification for suspected bot traffic instead of outright blocking
- **Infrastructure as Code** — manage Web ACLs, rules, and IP sets via Terraform or AWS CloudFormation


---

<a id="chapter-15-secrets-manager"></a>

# Setting Up AWS Secrets Manager — Complete Step-by-Step Guide

AWS Secrets Manager securely stores, retrieves, and automatically rotates credentials, API keys, and other secrets — removing hardcoded passwords from application code and configuration files. This guide covers creating secrets, retrieving them in applications, setting up automatic rotation, and cross-service integration.

---

## Architecture Overview

```
        Application / Lambda / EC2
                    │
              IAM Policy (GetSecretValue)
                    │
          ┌──────────────────┐
          │  Secrets Manager   │
          │                   │
          │  prod/db/password  │
          │  prod/api/stripe-key │
          │                   │
          │  KMS Encryption     │
          │  Auto Rotation       │
          └────────┬─────────┘
                    │ (rotation Lambda)
              Target Database
              (RDS, DocumentDB, etc.)
```

---

## Prerequisites

- Active AWS account
- IAM user/role with `SecretsManagerReadWrite` (or scoped equivalent) permissions
- (For rotation) A target resource like an RDS database whose credentials need periodic rotation

### Secrets Manager vs. SSM Parameter Store

| Feature | Secrets Manager | SSM Parameter Store (SecureString) |
|---|---|---|
| Automatic rotation | Built-in, native integration with RDS/DocumentDB/Redshift | Requires custom Lambda + EventBridge setup |
| Cost | ~$0.40/secret/month + API calls | Free (standard tier), low cost (advanced tier) |
| Cross-account sharing | Native resource policies | More limited |
| Best for | Database credentials, API keys needing rotation | Simple config values, feature flags, non-rotating secrets |

This guide covers Secrets Manager; use Parameter Store for simple non-sensitive or non-rotating configuration instead when cost is a primary concern.

---

## Step 1: Sign In and Select Region

1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in with IAM credentials
3. Select your target **region** (e.g., `Asia Pacific (Mumbai) ap-south-1`)

> Secrets are region-scoped — replicate to other regions explicitly if a multi-region application needs the same secret (Step 8).

---

## Step 2: Open Secrets Manager

1. In the search bar, type `Secrets Manager` and select **Secrets Manager**
2. You'll land on the **Secrets** dashboard

---

## Step 3: Create a Secret

### Option A: Database Credentials (With Native Rotation Support)

1. Click **Store a new secret**
2. Secret type: **Credentials for Amazon RDS database**
3. Configure:
   - User name: `dbadmin`
   - Password: enter the current database password
   - Encryption key: `aws/secretsmanager` (default) or a custom KMS key
4. **Database**: select your RDS instance from the dropdown (e.g., `prod-postgres-db`) — this links the secret to the DB for rotation later
5. Click **Next**

### Option B: Generic API Key / Other Credentials

1. Click **Store a new secret**
2. Secret type: **Other type of secret**
3. **Key/value pairs**, e.g.:

| Key | Value |
|---|---|
| `api_key` | `sk_live_xxxxxxxxxxxx` |
| `webhook_secret` | `whsec_xxxxxxxxxxxx` |

4. Encryption key: default or custom KMS key
5. Click **Next**

---

## Step 4: Name and Tag the Secret

1. **Secret name**: use a hierarchical naming convention for easy IAM scoping later, e.g.:
   ```
   prod/orders-service/db-credentials
   prod/orders-service/stripe-api-key
   ```
2. **Description**: `Database credentials for the orders production database`
3. **Tags** (optional): `Environment: Production`, `Team: Backend`
4. **Resource permissions** (optional): click **Edit permissions** to add a resource policy for cross-account access
5. **Replicate secret** (optional): see Step 8 for multi-region setups
6. Click **Next**

---

## Step 5: Configure Rotation (Database Secrets)

1. On the **Configure rotation** step, toggle **Automatic rotation** → **Enable**
2. **Rotation schedule**:
   - Time unit: **Days**
   - Rotate every: `30` days (adjust per your security policy)
   - Or specify a fixed schedule expression (cron-style) for more control
3. **Rotation function**:
   - AWS auto-generates a Lambda function (e.g., using the `SecretsManagerRDSPostgreSQLRotationSingleUser` template) if this is a linked RDS secret
   - Review the auto-created rotation Lambda's name
4. Click **Next** → review → **Store**

> For non-database secrets (API keys), you must write a **custom rotation Lambda** implementing the 4-step rotation protocol (`createSecret`, `setSecret`, `testSecret`, `finishSecret`) — many third-party APIs don't support programmatic key rotation, so rotation is often manual for those.

---

## Step 6: Retrieve the Secret Programmatically

### From Lambda / Application Code (Python example using boto3)

```python
import boto3
import json

def get_secret(secret_name, region_name="ap-south-1"):
    client = boto3.client("secretsmanager", region_name=region_name)
    response = client.get_secret_value(SecretId=secret_name)
    return json.loads(response["SecretString"])

secret = get_secret("prod/orders-service/db-credentials")
db_password = secret["password"]
```

### From AWS CLI

```bash
aws secretsmanager get-secret-value \
  --secret-id prod/orders-service/db-credentials \
  --query SecretString \
  --output text
```

### From EC2 User Data / Startup Script

```bash
DB_SECRET=$(aws secretsmanager get-secret-value \
  --secret-id prod/orders-service/db-credentials \
  --query SecretString --output text)
DB_PASSWORD=$(echo $DB_SECRET | jq -r .password)
```

---

## Step 7: Grant IAM Access to the Secret (Least Privilege)

1. **IAM Console** → **Policies** → **Create policy** → **JSON** tab
2. Example — allow a Lambda/EC2 role to read one specific secret:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": ["secretsmanager:GetSecretValue"],
         "Resource": "arn:aws:secretsmanager:ap-south-1:123456789012:secret:prod/orders-service/db-credentials-*"
       }
     ]
   }
   ```
   > Note the trailing `-*` — Secrets Manager appends a random 6-character suffix to the ARN, so a wildcard is required unless you reference the exact generated ARN.
3. Name: `SecretsManager-OrdersDBCredentials-Read`
4. Attach to the relevant execution role (Lambda) or instance profile (EC2)

---

## Step 8: Set Up Cross-Region Replication (Optional, for DR/Multi-Region Apps)

1. Select the secret → **Replicate secret**
2. Choose the target region(s), e.g., `ap-southeast-1`
3. Choose an encryption key for the replica region (default or custom KMS key in that region)
4. Click **Save**
5. Application code in the replica region reads the secret using that region's endpoint — updates to the primary secret propagate automatically to replicas (read-only in replica regions)

---

## Step 9: Rotate a Secret Manually (On-Demand)

Useful immediately after a suspected credential leak, without waiting for the schedule.

1. Select the secret → **Rotate secret immediately**
2. Confirm — this triggers the rotation Lambda right away
3. Monitor progress: **Secret details** → check **Rotation status**
4. Verify the application can still connect using the new credentials (rotation Lambda tests this automatically as part of the 4-step protocol before finalizing)

---

## Step 10: Monitor with CloudWatch and CloudTrail

1. **CloudTrail** (enabled by default for management events) logs every `GetSecretValue`, `PutSecretValue`, and rotation event — useful for auditing who/what accessed a secret and when
2. **CloudWatch** → set an alarm on the rotation Lambda's `Errors` metric to catch failed rotations
3. Search CloudTrail **Event history** filtered by event name `GetSecretValue` to audit access patterns

---

## Step 11: Verification Checklist

- [ ] Secrets named using a consistent, hierarchical convention (e.g., `env/service/secret-name`)
- [ ] Database secrets linked to their RDS/DocumentDB instance for native rotation support
- [ ] Automatic rotation enabled with an appropriate schedule for production credentials
- [ ] IAM policies scope access to specific secret ARNs, not wildcard `secret:*`
- [ ] No secrets hardcoded in application code, environment variables in plaintext, or committed to source control
- [ ] Cross-region replication configured if the application spans multiple regions
- [ ] CloudTrail logging confirmed for secret access auditing
- [ ] CloudWatch alarm configured for rotation Lambda failures
- [ ] Manual rotation tested successfully at least once

---

## Cleanup (To Avoid Ongoing Charges)

1. Select the secret → **Actions** → **Delete secret**
2. Choose a **recovery window** (7–30 days, default 30) — the secret remains recoverable during this window before permanent deletion
3. For immediate permanent deletion (use cautiously — cannot be undone):
   ```bash
   aws secretsmanager delete-secret \
     --secret-id prod/orders-service/db-credentials \
     --force-delete-without-recovery
   ```
4. Delete the auto-created rotation Lambda function if no longer needed
5. Remove replica regions before deleting the primary secret, if applicable

> Secrets Manager bills per secret per month plus API call charges — delete unused secrets and their replicas rather than leaving them idle.

---

## Quick Reference Summary

| Component | Purpose |
|---|---|
| Secret | Encrypted key/value or credential pair stored securely |
| Rotation | Automatic periodic credential change without app downtime |
| Rotation Lambda | Function implementing the create/set/test/finish rotation protocol |
| Resource Policy | Controls cross-account access to a specific secret |
| Recovery Window | Grace period before permanent deletion (7–30 days) |
| Replication | Read-only copies of a secret in other regions |

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| `AccessDeniedException` retrieving secret | IAM policy doesn't include the secret's ARN (or wildcard suffix missing) | Verify policy `Resource` includes `-*` suffix; confirm correct region |
| Rotation fails and secret is stuck | Rotation Lambda lacks network access to the database (e.g., not in the right VPC/subnet) | Ensure rotation Lambda's VPC config allows it to reach the DB; check its execution role permissions |
| Application still using old credentials after rotation | App caches the secret in memory and doesn't re-fetch | Implement a cache with periodic refresh, or catch auth failures and re-fetch on error |
| `ResourceNotFoundException` | Secret name typo, or looking in the wrong region | Double-check exact secret name/ARN and region |
| Unexpectedly high bill | Excessive `GetSecretValue` calls (e.g., fetching on every request instead of caching) | Cache secret values in application memory with a reasonable TTL instead of fetching per-request |

---

## Next Steps / Advanced Topics

- **Custom rotation Lambdas** — implement rotation for non-native services (third-party APIs, custom databases)
- **Resource-based policies for cross-account secrets** — share a secret with another AWS account without duplicating it
- **Secrets Manager + ECS/Fargate** — inject secrets directly into container environment variables via task definition `secrets` field
- **AWS Config rules** — enforce that all secrets have rotation enabled across the account
- **Infrastructure as Code** — manage secrets (metadata, not values) via Terraform or AWS CloudFormation, with values injected securely outside version control


---

<a id="chapter-16-codepipeline"></a>

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


---

<a id="chapter-17-eks"></a>

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


---

<a id="chapter-18-vpc-peering-tgw"></a>

# Connecting VPCs in AWS: Peering & Transit Gateway — Complete Step-by-Step Guide

When you have multiple VPCs — across environments, teams, or accounts — you need a way for them to communicate privately. This guide covers **VPC Peering** (simple, direct, point-to-point) and **Transit Gateway** (scalable hub-and-spoke for many VPCs), including cross-account setups.

---

## Architecture Overview

```
VPC Peering (point-to-point):

    VPC A (10.0.0.0/16)  ◄──── Peering Connection ────►  VPC B (10.1.0.0/16)


Transit Gateway (hub-and-spoke, scales to many VPCs):

         VPC A          VPC B          VPC C          On-Premises
     (10.0.0.0/16)  (10.1.0.0/16)  (10.2.0.0/16)      (via VPN/DX)
            │              │              │                 │
            └──────────────┴──────┬───────┴─────────────────┘
                                   │
                          Transit Gateway
                        (central routing hub)
```

---

## Prerequisites

- Active AWS account(s) with IAM permissions for `AmazonVPCFullAccess` and (for Transit Gateway) `AmazonEC2TransitGatewayFullAccess`
- Two or more existing VPCs, each with **non-overlapping CIDR ranges** (this is critical — overlapping ranges cannot be peered or connected)
- For cross-account setups: the account ID of the peer account

### VPC Peering vs. Transit Gateway — Which to Use

| Feature | VPC Peering | Transit Gateway |
|---|---|---|
| Topology | Point-to-point only | Hub-and-spoke, scales to hundreds of VPCs |
| Transitive routing | **No** — A↔B and B↔C does NOT mean A↔C | **Yes** — all attached VPCs can route through the hub |
| Cost | Free (only data transfer charges) | Hourly charge per attachment + data processing fee |
| Best for | 2–3 VPCs needing simple connectivity | Many VPCs, multi-account, hybrid (VPN/Direct Connect) networks |
| Route table complexity | Grows quickly (N×(N-1)/2 connections for full mesh) | Centralized — one hub, simpler at scale |

**Rule of thumb:** Use Peering for a handful of VPCs. Use Transit Gateway once you have more than ~3–4 VPCs needing interconnection, or need hybrid on-premises connectivity alongside VPC-to-VPC routing.

---

## Part A: VPC Peering

### Step A1: Sign In and Review CIDR Ranges

1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in with IAM credentials
3. **VPC Console** → **Your VPCs** → confirm CIDR blocks for both VPCs don't overlap, e.g.:
   - VPC A: `10.0.0.0/16`
   - VPC B: `10.1.0.0/16`

### Step A2: Create the Peering Connection

1. **VPC Console** → **Peering connections** → **Create peering connection**
2. Configure:

| Field | Value | Notes |
|---|---|---|
| Name | `vpc-a-to-vpc-b` | |
| VPC (Requester) | `vpc-a` (your current VPC) | |
| Account | **My account** or **Another account** | |
| Region | **This region** or **Another region** | Supports inter-region peering |
| VPC (Accepter) | select `vpc-b`, or enter the peer VPC ID + account ID for cross-account | |

3. Click **Create peering connection**
4. Status shows `Pending acceptance`

### Step A3: Accept the Peering Connection

**Same account:**
1. Select the pending connection → **Actions** → **Accept request**
2. Confirm → status changes to `Active`

**Cross-account:**
1. The peer account owner signs in to **their** AWS console
2. **VPC Console** → **Peering connections** → select the pending request → **Actions** → **Accept request**

### Step A4: Update Route Tables (Both VPCs)

Peering alone doesn't route traffic — you must explicitly add routes.

1. **VPC A**: select its route table(s) → **Edit routes** → **Add route**:
   - Destination: `10.1.0.0/16` (VPC B's CIDR)
   - Target: **Peering Connection** → select `vpc-a-to-vpc-b`
2. Click **Save changes**
3. **VPC B**: select its route table(s) → **Edit routes** → **Add route**:
   - Destination: `10.0.0.0/16` (VPC A's CIDR)
   - Target: the same peering connection
4. Click **Save changes**
5. Repeat for **every route table** in each VPC that needs cross-VPC access (e.g., both public and private subnet route tables)

### Step A5: Update Security Groups

1. In VPC B's security group protecting the target resource (e.g., an RDS database), add an inbound rule:
   - Type: (relevant port, e.g., PostgreSQL `5432`)
   - Source: `10.0.0.0/16` (VPC A's CIDR) — or narrower if only specific subnets need access
2. Repeat symmetrically in VPC A if bidirectional access is needed

### Step A6: Test Connectivity

1. From an EC2 instance in VPC A, ping or connect to a private IP in VPC B:
   ```bash
   ping 10.1.1.50
   # or for a service
   curl http://10.1.1.50:8080/health
   ```
2. Confirm connectivity works; if not, see troubleshooting table below

> **Reminder:** Peering is **not transitive**. If VPC A peers with VPC B, and VPC B peers with VPC C, resources in A **cannot** reach C through B. Each pair needing connectivity requires its own peering connection and route entries — or use Transit Gateway instead.

---

## Part B: Transit Gateway

### Step B1: Create the Transit Gateway

1. **VPC Console** → **Transit Gateways** → **Create transit gateway**
2. Configure:
   - Name: `main-transit-gateway`
   - Description: `Central hub for VPC and hybrid connectivity`
   - Amazon side ASN: leave default (`64512`) unless integrating with existing BGP infrastructure
   - **DNS support**: Enable
   - **VPN ECMP support**: Enable (if using multiple VPN connections for redundancy)
   - **Default route table association/propagation**: Enable (simplest for most setups — see Step B5 for segmented routing)
3. Click **Create transit gateway**
4. Wait for state to become `Available` (a few minutes)

### Step B2: Create VPC Attachments

Repeat for each VPC you want connected to the hub.

1. Left sidebar → **Transit Gateway Attachments** → **Create transit gateway attachment**
2. Configure:
   - Transit gateway ID: `main-transit-gateway`
   - Attachment type: **VPC**
   - VPC ID: select `vpc-a`
   - Subnet IDs: select **one subnet per AZ** you want to route through (typically private subnets)
3. Click **Create transit gateway attachment**
4. Repeat for `vpc-b`, `vpc-c`, etc.
5. Wait for each attachment to reach `Available` state

### Step B3: Accept Cross-Account Attachments (If Applicable)

If a VPC belongs to a different AWS account:

1. **Resource Access Manager (RAM)**: the Transit Gateway owner shares it via **RAM** → **Create resource share** → select the Transit Gateway → specify the peer account ID
2. The peer account: **RAM** → **Resource shares** → **Accept resource share**
3. The peer account can now create a VPC attachment (Step B2) referencing the shared Transit Gateway ID

### Step B4: Update VPC Route Tables to Point to the Transit Gateway

1. **VPC A**'s route table(s) → **Edit routes** → **Add route**:
   - Destination: `10.0.0.0/8` (a broad range covering all your VPC CIDRs), or specific CIDRs per VPC for tighter control
   - Target: **Transit Gateway** → select `main-transit-gateway`
2. Repeat for VPC B, VPC C, and any others — each pointing broader/other-VPC CIDR ranges at the Transit Gateway
3. Click **Save changes** for each

### Step B5: Configure Transit Gateway Route Tables (Segmented Routing, Optional)

By default (if you enabled default association/propagation in Step B1), all attachments can reach all other attachments. For segmented environments (e.g., isolate a "shared services" VPC from a "production" VPC that shouldn't talk to "dev"):

1. Left sidebar → **Transit Gateway Route Tables** → **Create transit gateway route table**
2. Create separate route tables, e.g., `prod-rt`, `dev-rt`
3. For each VPC attachment: **Transit Gateway Attachments** → select → **Actions** → **Modify transit gateway route table associations** → associate with the appropriate route table (`prod-rt` or `dev-rt`)
4. Under **Transit Gateway Route Tables** → select a table → **Propagations** tab → **Create propagation** → choose which attachments' routes are learned into this table
5. This creates isolated routing domains — e.g., `prod-rt` only propagates routes from production VPCs, so dev VPCs are unreachable from production even though both are attached to the same Transit Gateway

### Step B6: Update Security Groups

Same as Step A5 — Transit Gateway routes packets, but security groups still enforce port/protocol-level access control at the destination resource.

### Step B7: Test Connectivity

1. From an EC2 instance in VPC A, test reachability to a resource in VPC C (transitive — this is the key advantage over Peering):
   ```bash
   curl http://10.2.1.50:8080/health
   ```
2. Confirm traffic flows through the Transit Gateway as expected

---

## Step C: Monitor with CloudWatch and VPC Flow Logs

1. **Transit Gateway metrics**: select the Transit Gateway → **Monitoring** tab — view `BytesIn`, `BytesOut`, `PacketDropCount` per attachment
2. Enable **VPC Flow Logs** on relevant VPCs/subnets to audit and troubleshoot traffic:
   - **VPC Console** → select VPC → **Flow logs** tab → **Create flow log**
   - Destination: CloudWatch Logs or S3
   - Filter: **All** (accepted and rejected traffic)
3. Set a CloudWatch alarm on `PacketDropCount` > 0 to catch routing misconfigurations early

---

## Verification Checklist

- [ ] VPC CIDR ranges confirmed non-overlapping before creating any connection
- [ ] Peering connection (or Transit Gateway attachment) shows `Active`/`Available` state
- [ ] Route tables updated in **all** relevant VPCs/subnets — not just one side
- [ ] Security groups updated to allow the specific ports/protocols needed, scoped to the peer CIDR (not `0.0.0.0/0`)
- [ ] Cross-account sharing (RAM) accepted if applicable
- [ ] For Transit Gateway: route table segmentation configured if isolation between environments is required
- [ ] Connectivity tested end-to-end (ping/curl between instances in different VPCs)
- [ ] VPC Flow Logs enabled for auditing and troubleshooting
- [ ] Understood peering's non-transitive limitation vs. Transit Gateway's hub-and-spoke model — chose the right tool for the topology

---

## Cleanup (To Avoid Ongoing Charges)

### VPC Peering
1. Remove routes referencing the peering connection from all route tables
2. Delete the peering connection: **Peering connections** → select → **Actions** → **Delete peering connection**

### Transit Gateway
1. Remove routes referencing the Transit Gateway from all VPC route tables
2. Delete VPC attachments: **Transit Gateway Attachments** → select each → **Delete**
3. Delete custom transit gateway route tables (if created): **Transit Gateway Route Tables** → select → **Delete**
4. Delete the Transit Gateway itself: **Transit Gateways** → select → **Delete**
5. If cross-account, unshare via **RAM** → **Resource shares** → **Delete**

> VPC Peering itself is free (only standard data transfer charges apply). Transit Gateway bills an hourly charge **per attachment** plus a per-GB data processing fee — delete unused attachments and the gateway itself when no longer needed.

---

## Quick Reference Summary

| Component | Purpose |
|---|---|
| Peering Connection | Direct, non-transitive link between exactly two VPCs |
| Transit Gateway | Central hub enabling transitive routing across many VPCs/VPNs |
| Attachment | Connects a VPC (or VPN/Direct Connect) to the Transit Gateway |
| Transit Gateway Route Table | Controls which attachments can route to which — enables segmentation |
| Resource Access Manager (RAM) | Shares a Transit Gateway across AWS accounts |
| VPC Flow Logs | Records accepted/rejected traffic for auditing |

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| Peering connection stuck at `Pending acceptance` | Accepter side hasn't accepted yet | Peer account/owner must explicitly accept in their console |
| Cannot connect despite `Active` peering/attachment | Route tables not updated on one or both sides | Verify routes exist in **every** relevant route table, both directions |
| Connectivity works one way but not the other | Asymmetric route table or security group configuration | Check both VPCs' route tables and security groups symmetrically |
| "Overlapping CIDR" error creating peering/attachment | Both VPCs use the same or overlapping IP ranges | Cannot be resolved without re-IP'ing one VPC — plan CIDR ranges carefully upfront |
| VPC A can't reach VPC C via VPC B (peering) | Peering is not transitive by design | Create a direct A↔C peering connection, or migrate to Transit Gateway |
| Transit Gateway traffic silently dropped | Attachment associated with a route table that doesn't propagate the destination VPC's routes | Review Transit Gateway route table associations/propagations (Step B5) |

---

## Next Steps / Advanced Topics

- **AWS PrivateLink** — expose a specific service privately across VPCs/accounts without full network peering, more restrictive and secure for single-service access
- **Transit Gateway Connect** — SD-WAN integration for simplified hybrid connectivity
- **Site-to-Site VPN / Direct Connect via Transit Gateway** — extend the hub-and-spoke model to on-premises networks
- **Network Firewall** — centralized traffic inspection at the Transit Gateway level
- **Infrastructure as Code** — manage peering connections, transit gateways, and route tables via Terraform or AWS CloudFormation


---

<a id="chapter-19-organizations-cost"></a>

# Setting Up AWS Organizations, Cost Explorer & Budgets — Complete Step-by-Step Guide

AWS Organizations centrally manages multiple AWS accounts with consolidated billing and governance guardrails (Service Control Policies). Cost Explorer and Budgets give visibility and control over spend across those accounts. This guide covers setting up a multi-account structure, applying SCPs, and configuring cost monitoring/alerts.

---

## Architecture Overview

```
                    Management Account
                    (billing, Organizations root)
                              │
                    ┌─────────┴─────────┐
                    │                   │
              Organizational Unit    Organizational Unit
                 "Production"           "Development"
                    │                   │
          ┌─────────┴────────┐         │
          │                  │         │
     Prod-App-Account   Prod-Data-Account   Dev-Account

        Service Control Policies (SCPs) applied per OU
        Consolidated billing → single invoice
        Cost Explorer + Budgets → spend visibility & alerts
```

---

## Prerequisites

- Active AWS account to serve as the **management account** (formerly called "master account")
- IAM user/role with `AWSOrganizationsFullAccess` and `AWSBillingConductorFullAccess`/billing permissions
- Email addresses available for each new member account (each AWS account requires a unique email)

---

## Part A: Setting Up AWS Organizations

### Step A1: Sign In and Enable Organizations

1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in as the account that will become the **management account** (root/admin of your organization)
3. In the search bar, type `Organizations` and select **AWS Organizations**
4. Click **Create an organization**
5. Choose feature set: **Enable all features** (recommended — enables SCPs, tag policies, and consolidated billing; the alternative "Consolidated billing only" skips governance features)
6. Click **Create organization**
7. AWS may send a verification email to the management account's email address — confirm it

> Organizations is a **global** service, not tied to a specific region.

---

### Step A2: Create Organizational Units (OUs)

OUs group accounts for applying policies collectively, mirroring your org structure.

1. Left sidebar → **AWS accounts** → view the organization root
2. Click **Actions** → **Create new** (or select the root) → **Create organizational unit**
3. Create OUs matching your structure, e.g.:
   - `Production`
   - `Development`
   - `Security` (for centralized logging/audit accounts)
   - `Sandbox` (for experimentation, tightly restricted)
4. Repeat to create each OU under the root

---

### Step A3: Create or Invite Member Accounts

#### Option A: Create a New Account

1. **AWS accounts** → **Add an AWS account** → **Create an AWS account**
2. Configure:
   - AWS account name: `prod-app-account`
   - Email address: a unique email (e.g., `aws-prod-app@company.com` — use an alias/distribution list, not a personal inbox)
   - IAM role name: `OrganizationAccountAccessRole` (default — used by the management account to assume access into the new account)
3. Click **Create AWS account**
4. Wait a few minutes for creation to complete — check status under **AWS accounts**

#### Option B: Invite an Existing Account

1. **Add an AWS account** → **Invite an existing AWS account**
2. Enter the target account's ID or email
3. Click **Send invitation**
4. The invited account's owner signs in and **Accepts** the invitation under their own **Organizations** console

---

### Step A4: Move Accounts into OUs

1. **AWS accounts** → select an account (e.g., `prod-app-account`)
2. Click **Actions** → **Move**
3. Select the destination OU: `Production`
4. Click **Move AWS account**
5. Repeat for each account, organizing them under `Production`, `Development`, etc.

---

### Step A5: Access Member Accounts

1. From the management account, **AWS accounts** → select a member account → note the **Account ID**
2. Switch roles: click your account name (top-right) → **Switch role**, or use the direct URL:
   ```
   https://signin.aws.amazon.com/switchrole?account=<ACCOUNT_ID>&roleName=OrganizationAccountAccessRole
   ```
3. This grants admin access into the member account using the role created in Step A3

---

### Step A6: Apply a Service Control Policy (SCP)

SCPs set the **maximum available permissions** for accounts — they don't grant permissions themselves, only restrict what IAM policies within the account can allow.

1. Left sidebar → **Policies** → **Service control policies** → **Create policy**
2. Example — deny leaving the organization and deny disabling CloudTrail (common security guardrail):
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "DenyLeaveOrganization",
         "Effect": "Deny",
         "Action": "organizations:LeaveOrganization",
         "Resource": "*"
       },
       {
         "Sid": "DenyDisableCloudTrail",
         "Effect": "Deny",
         "Action": [
           "cloudtrail:StopLogging",
           "cloudtrail:DeleteTrail"
         ],
         "Resource": "*"
       }
     ]
   }
   ```
3. Name: `guardrail-prevent-security-tampering`
4. Click **Create policy**
5. Go to **AWS accounts** → select the target OU (e.g., `Production`) → **Policies** tab → **Attach** → select the SCP
6. Click **Attach policy**

### Common SCP Guardrail Examples

| Guardrail | Purpose |
|---|---|
| Deny use of regions outside approved list | Data residency / cost control |
| Deny root user actions | Force use of IAM roles, not root credentials |
| Deny disabling GuardDuty/Config/CloudTrail | Prevent tampering with security monitoring |
| Require specific tags on resource creation | Enforce cost allocation tagging |
| Deny deletion of specific critical resources | Protect production databases/buckets from accidental deletion |

---

### Step A7: Enable Consolidated Billing Review

1. From the management account: **Billing and Cost Management Console** → **Bills**
2. Confirm charges from all member accounts roll up into a single consolidated invoice
3. Member accounts can still view their own usage/costs but billing is centralized to the management account by default

---

## Part B: Cost Explorer

### Step B1: Enable Cost Explorer

1. From the management account (or any account with billing access): **Billing and Cost Management Console**
2. Left sidebar → **Cost Explorer** → if first time, click **Enable Cost Explorer**
3. Data typically becomes available within 24 hours of enabling

### Step B2: Explore Cost and Usage Reports

1. **Cost Explorer** → default view shows costs over the last 6 months
2. Adjust:
   - **Date range**: last 7/30/90 days, custom range
   - **Granularity**: Daily, Monthly, Hourly (last 14 days only)
   - **Group by**: Service, Linked Account, Region, Usage Type, Tag
3. Example — see spend broken down by account:
   - Group by: **Linked Account**
   - Identify which member accounts are driving cost
4. Example — see spend broken down by service within one account:
   - Filter: **Linked Account** = `prod-app-account`
   - Group by: **Service**

### Step B3: Save a Custom Report

1. Configure filters/grouping as needed (e.g., EC2 costs by Availability Zone, last 90 days)
2. Click **Save as** → name it, e.g., `ec2-costs-by-az`
3. Access saved reports anytime from the **Cost Explorer** left sidebar

### Step B4: Set Up Cost Allocation Tags

Tags let you attribute costs to specific teams, projects, or environments.

1. **Billing Console** → **Cost allocation tags**
2. AWS-generated tags (e.g., `aws:createdBy`) are available by default
3. For **user-defined tags** (e.g., `Team`, `Environment`, `Project`) applied to your resources: select them from the list → **Activate**
4. Allow up to 24 hours for tagged cost data to appear in Cost Explorer
5. In Cost Explorer, **Group by** → **Tag** → select your activated tag to see cost breakdowns by team/project

---

## Part C: AWS Budgets

### Step C1: Create a Cost Budget

1. **Billing Console** → **Budgets** → **Create budget**
2. Budget type: **Customize (Advanced)** → **Cost budget**
3. Configure:
   - Budget name: `monthly-total-spend`
   - Period: **Monthly**
   - Budget renewal type: **Recurring budget**
   - Budgeted amount: `$5,000` (adjust to your expected spend)
   - (Optional) **Enter a specific amount** or **Auto-adjust** based on prior spend trends
4. **Scope** (optional): filter to specific accounts, services, or tags — e.g., only track `Production` OU accounts

### Step C2: Configure Alert Thresholds

1. **Set alert thresholds** → **Add an alert threshold**
2. Configure multiple thresholds, e.g.:

| Threshold | Trigger On | Notify |
|---|---|---|
| 50% | Actual spend | Team lead (early warning) |
| 80% | Actual spend | Team lead + finance |
| 100% | Actual spend | Team lead + finance + management |
| 100% | **Forecasted** spend | Team lead (proactive — before it actually happens) |

3. For each threshold: enter **email recipients**, or select an **SNS topic** to integrate with Slack/PagerDuty via subscription
4. Click **Next** → review → **Create budget**

### Step C3: Create a Usage Budget (Optional)

Track non-cost metrics like EC2 running hours or S3 storage GB, useful for capacity planning independent of pricing changes.

1. **Create budget** → **Customize (Advanced)** → **Usage budget**
2. Configure the service and usage type to track (e.g., "EC2-Instance-Hours")
3. Set thresholds and notifications as in Step C2

### Step C4: Create a Savings Plan / Reserved Instance Coverage Budget (Optional)

For organizations using Savings Plans or Reserved Instances, track coverage/utilization to ensure commitments are being used efficiently.

1. **Create budget** → **Customize (Advanced)** → **Savings Plans budget** or **Reservation budget**
2. Set a target coverage/utilization percentage (e.g., alert if utilization drops below 90%, indicating wasted commitment spend)

---

## Step D: Set Up Anomaly Detection

Automatically flags unusual spend patterns without manually configured thresholds.

1. **Cost Explorer** (or **Billing Console**) → **Cost Anomaly Detection** → **Create monitor**
2. Monitor type:
   - **AWS Services** — monitors overall spend by service
   - **Linked Account** — monitors per-member-account spend
   - **Cost Category** or **Cost Allocation Tag** — monitors a custom grouping
3. Click **Next**
4. **Create alert subscription**:
   - Frequency: **Immediate**, **Daily summary**, or **Weekly summary**
   - Threshold: alert only on anomalies above a dollar amount (e.g., `$100`) to avoid noise from tiny fluctuations
   - Recipients: email or SNS topic
5. Click **Create**

---

## Step E: Review Regularly with the Cost and Usage Report (CUR)

For deeper analysis (e.g., with QuickSight, Athena, or a BI tool):

1. **Billing Console** → **Cost & Usage Reports** → **Create report**
2. Configure:
   - Report name: `monthly-cur`
   - Include resource IDs: **Yes** (needed for granular per-resource cost attribution)
   - Data refresh settings: automatically refresh when charges are updated
3. **Delivery options**: select an S3 bucket to receive the report (create one if needed)
4. Report format: **Parquet** (recommended for Athena) or CSV
5. Click **Next** → review → **Create report**
6. Reports are delivered to S3 daily/periodically — query with **Athena** or visualize with **QuickSight** for custom dashboards

---

## Verification Checklist

- [ ] Organization created with **all features** enabled (not just consolidated billing)
- [ ] OUs structured to reflect your environment/team boundaries
- [ ] Member accounts created/invited and moved into the correct OUs
- [ ] SCPs attached to enforce security guardrails at the OU level
- [ ] Consolidated billing confirmed — single invoice covering all member accounts
- [ ] Cost Explorer enabled and reviewed at least once
- [ ] Cost allocation tags activated for key dimensions (Team, Environment, Project)
- [ ] Budgets created with multiple alert thresholds (50/80/100% actual, 100% forecasted)
- [ ] Cost Anomaly Detection monitor configured
- [ ] (Optional) Cost and Usage Report configured for deep-dive analysis via Athena/QuickSight

---

## Cleanup / Ongoing Governance Notes

Organizations, Cost Explorer, and Budgets themselves have **no direct cost** — Cost Explorer's first API-based query access carries a small per-request fee, but console usage is free. There's little to "clean up" here beyond removing unused budgets or SCPs; however:

1. Removing a member account from an Organization requires the member account to first have valid standalone payment method details on file
2. Deleting an OU requires it to be empty (move or remove all accounts first)
3. Detach and delete unused SCPs: **Policies** → **Service control policies** → select → **Detach**, then **Delete**
4. Delete unused budgets: **Budgets** → select → **Delete**

---

## Quick Reference Summary

| Component | Purpose |
|---|---|
| Organization | Top-level container unifying multiple AWS accounts |
| Management Account | The account that owns the Organization and consolidated billing |
| Organizational Unit (OU) | Groups accounts for applying policies collectively |
| Service Control Policy (SCP) | Sets maximum allowed permissions for accounts in an OU |
| Cost Explorer | Visual cost/usage analysis and reporting |
| Budget | Threshold-based spend alerts (cost, usage, or reservation coverage) |
| Cost Anomaly Detection | ML-based automatic flagging of unusual spend |
| Cost & Usage Report (CUR) | Most granular billing data export, for BI tools |

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| Can't create new accounts | Organization not verified, or account limit reached | Confirm management account email verification; request a service quota increase for account limit |
| SCP not taking effect | Attached to wrong OU, or an explicit Allow elsewhere doesn't override an SCP Deny | SCPs are a ceiling, not a grant — verify the SCP is attached to the correct OU/account and check for typos in the policy JSON |
| Cost Explorer shows no data | Just enabled (data takes ~24 hours), or wrong date range selected | Wait 24 hours after first enabling; verify date range and account scope |
| Budget alerts not arriving | Email not verified, or SNS subscription not confirmed | Check spam folder for AWS budget alert emails; confirm SNS subscription if used |
| Tags not appearing in Cost Explorer | Cost allocation tag not activated, or resources tagged after cost data was generated | Activate the tag in Billing Console; allow 24 hours for tagged data to populate; ensure resources are actually tagged going forward |

---

## Next Steps / Advanced Topics

- **AWS Control Tower** — automates Organizations/OU/SCP setup with pre-built landing zone best practices
- **Tag Policies** — enforce consistent tag keys/values across the organization (separate from SCPs)
- **Backup Policies** — centrally enforce AWS Backup plans across accounts
- **Resource Access Manager (RAM)** — share resources like Transit Gateways or subnets across accounts within the organization
- **Infrastructure as Code** — manage OUs, accounts, and SCPs via Terraform (`aws_organizations_*` resources) or AWS CloudFormation StackSets for cross-account deployments


---

<a id="chapter-20-cloudformation"></a>

# Setting Up AWS CloudFormation — Complete Step-by-Step Guide

AWS CloudFormation is AWS's native Infrastructure as Code (IaC) service — define resources in a YAML/JSON template, and CloudFormation provisions, updates, and tears them down as a single managed unit called a **stack**.

---

## Architecture Overview

```
        template.yaml (VPC, EC2, RDS, IAM...)
                    │
              CloudFormation
                    │
        ┌───────────┴────────────┐
        │         Stack            │
        │  ┌────┐ ┌────┐ ┌────┐   │
        │  │VPC  │ │EC2  │ │RDS  │   │
        │  └────┘ └────┘ └────┘   │
        │                          │
        │  Change Sets → preview    │
        │  Drift Detection           │
        │  Stack Outputs → cross-ref │
        └─────────────────────────┘
```

---

## Prerequisites

- Active AWS account
- IAM user/role with `AWSCloudFormationFullAccess` plus permissions for the resource types you'll create
- Basic YAML familiarity

---

## Step 1: Sign In and Select Region

1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in with IAM credentials
3. Select your target **region**
4. In the search bar, type `CloudFormation` and select **CloudFormation**

---

## Step 2: Write a Template

Create `template.yaml`:

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Description: Simple VPC and EC2 instance

Parameters:
  InstanceType:
    Type: String
    Default: t2.micro
    AllowedValues: [t2.micro, t3.micro, t3.small]

Resources:
  AppVPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      Tags:
        - Key: Name
          Value: cfn-vpc

  PublicSubnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref AppVPC
      CidrBlock: 10.0.1.0/24
      AvailabilityZone: !Select [0, !GetAZs ""]
      MapPublicIpOnLaunch: true

  WebServer:
    Type: AWS::EC2::Instance
    Properties:
      InstanceType: !Ref InstanceType
      ImageId: ami-0abcdef1234567890
      SubnetId: !Ref PublicSubnet
      Tags:
        - Key: Name
          Value: cfn-web-server

Outputs:
  InstancePublicIp:
    Description: Public IP of the web server
    Value: !GetAtt WebServer.PublicIp
  VpcId:
    Value: !Ref AppVPC
    Export:
      Name: cfn-vpc-id
```

### Key Template Sections

| Section | Purpose |
|---|---|
| `Parameters` | Input values supplied at deploy time |
| `Resources` | The AWS resources to create (required) |
| `Outputs` | Values exposed after creation — can be imported by other stacks |
| `Conditions` | Conditional resource creation (e.g., prod vs. dev) |
| `Mappings` | Static lookup tables (e.g., AMI IDs per region) |

---

## Step 3: Validate the Template

```bash
aws cloudformation validate-template --template-body file://template.yaml
```

Fixes syntax errors before attempting a deployment.

---

## Step 4: Create the Stack (Console)

1. **CloudFormation Console** → **Stacks** → **Create stack** → **With new resources (standard)**
2. **Prerequisite**: choose **Template is ready** → **Upload a template file** → select `template.yaml`
3. Click **Next**
4. **Stack details**:
   - Stack name: `orders-app-infra`
   - Parameters: adjust `InstanceType` if needed
5. Click **Next**
6. **Configure stack options**:
   - Tags: add `Environment: Production`
   - **IAM role**: assign a role if CloudFormation needs elevated permissions beyond your user's
   - **Stack failure options**: **Roll back all stack resources** (default, recommended)
   - **Termination protection**: **Enable** for production stacks (prevents accidental deletion)
7. Click **Next** → review → check the acknowledgment box if IAM resources are included → **Submit**
8. Watch the **Events** tab — status progresses `CREATE_IN_PROGRESS` → `CREATE_COMPLETE`

### Alternative: Create via CLI

```bash
aws cloudformation create-stack \
  --stack-name orders-app-infra \
  --template-body file://template.yaml \
  --parameters ParameterKey=InstanceType,ParameterValue=t3.micro \
  --capabilities CAPABILITY_NAMED_IAM
```

---

## Step 5: Preview Changes with Change Sets

Before applying an update to a live stack, preview exactly what will change.

1. Select the stack → **Stack actions** → **Create change set for current stack**
2. Upload the modified template
3. Click **Create change set**
4. Review the **Changes** tab — shows Add/Modify/Remove per resource, and whether a change requires **replacement** (destructive) vs. **in-place update**
5. If acceptable, select the change set → **Execute**

---

## Step 6: Reference Outputs Across Stacks (Cross-Stack References)

1. In the producing stack's template, export a value (already shown in Step 2's `Outputs`)
2. In a consuming stack's template, import it:
   ```yaml
   Resources:
     AppServer:
       Type: AWS::EC2::Instance
       Properties:
         SubnetId: !ImportValue cfn-vpc-id
   ```
3. This lets you split infrastructure into logical stacks (network, database, application) while still wiring them together

---

## Step 7: Use Nested Stacks (For Modular Templates)

```yaml
Resources:
  NetworkStack:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: https://s3.amazonaws.com/my-templates/network.yaml
      Parameters:
        CidrBlock: 10.0.0.0/16
```

Nested stacks let you reuse common templates (e.g., a standard VPC pattern) across multiple parent stacks.

---

## Step 8: Detect and Remediate Drift

Drift occurs when someone manually changes a resource outside CloudFormation.

1. Select the stack → **Stack actions** → **Detect drift**
2. Wait for detection to complete
3. Review the **Drift status** column per resource: `IN_SYNC`, `MODIFIED`, `DELETED`
4. For drifted resources, either manually revert the out-of-band change, or update the template to match reality and redeploy

---

## Step 9: Set Up Stack Policies (Protect Critical Resources)

Prevent specific resources from being accidentally updated/replaced during a stack update.

1. Select the stack → **Edit stack policy**
2. Example — deny replacement of the production database:
   ```json
   {
     "Statement": [
       {
         "Effect": "Deny",
         "Action": "Update:Replace",
         "Principal": "*",
         "Resource": "LogicalResourceId/ProdDatabase"
       },
       {
         "Effect": "Allow",
         "Action": "Update:*",
         "Principal": "*",
         "Resource": "*"
       }
     ]
   }
   ```
3. Click **Save**

---

## Step 10: Delete the Stack

1. Select the stack → **Delete**
2. Confirm — CloudFormation deletes resources in dependency order automatically
3. If deletion fails on a resource (e.g., a non-empty S3 bucket), resolve the blocker (empty the bucket) and retry, or use **Delete** → **Force delete** for stacks stuck in `DELETE_FAILED`

---

## Verification Checklist

- [ ] Template validated before deployment
- [ ] Change sets used to preview updates before executing against live stacks
- [ ] Termination protection enabled on production stacks
- [ ] Stack policies protect critical resources from accidental replacement
- [ ] Outputs/exports used for clean cross-stack references instead of hardcoded ARNs
- [ ] Drift detection run periodically to catch manual out-of-band changes
- [ ] Rollback behavior tested (intentionally trigger a failure in a test stack to confirm rollback works)

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| Stack stuck in `ROLLBACK_COMPLETE` | Initial creation failed; stack can't be updated from this state | Delete the stack and recreate |
| `Insufficient capabilities` error | Template creates IAM resources without acknowledgment | Add `--capabilities CAPABILITY_NAMED_IAM` (CLI) or check the acknowledgment box (console) |
| Update requires replacement unexpectedly | Changed an immutable property (e.g., subnet CIDR) | Check the change set's **Replacement** column before executing; some properties can't be updated in place |
| `DELETE_FAILED` | A resource has dependencies preventing deletion (e.g., non-empty S3 bucket, ENI still attached) | Manually resolve the blocker, then retry delete |

---

## Next Steps / Advanced Topics

- **AWS CDK** — define infrastructure in TypeScript/Python/Java, which synthesizes to CloudFormation templates
- **StackSets** — deploy the same stack across multiple accounts/regions simultaneously
- **Custom Resources** — extend CloudFormation with Lambda-backed logic for unsupported resource types
- **SAM (Serverless Application Model)** — CloudFormation extension simplifying Lambda/API Gateway templates


---

<a id="chapter-21-ssm"></a>

# Setting Up AWS Systems Manager (SSM) — Complete Step-by-Step Guide

AWS Systems Manager is an operations hub for managing EC2 instances and on-premises servers at scale — patching, running commands remotely, secure shell access without SSH keys/bastion hosts, and centralized parameter storage.

---

## Architecture Overview

```
        Admin (Console / CLI)
                │
        Systems Manager
                │
    ┌───────────┼────────────┐
    │           │            │
Run Command  Session Mgr  Parameter Store
    │           │            │
    └───────────┴────────────┘
                │
          SSM Agent (on instances)
                │
        EC2 Instances (no open SSH port needed)
```

---

## Prerequisites

- Active AWS account
- IAM user/role with `AmazonSSMFullAccess` (or scoped equivalent)
- EC2 instances with the **SSM Agent** installed (pre-installed on Amazon Linux 2023, Ubuntu 20.04+, Windows Server 2016+ AMIs)

---

## Step 1: Sign In and Open Systems Manager

1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in with IAM credentials
3. Select your target **region**
4. In the search bar, type `Systems Manager` and select **Systems Manager**

---

## Step 2: Attach the SSM IAM Role to Instances

1. **IAM Console** → **Roles** → **Create role**
2. Trusted entity: **AWS service** → **EC2**
3. Attach policy: `AmazonSSMManagedInstanceCore`
4. Name: `ssm-instance-role`
5. Click **Create role**
6. **EC2 Console** → select instance → **Actions** → **Security** → **Modify IAM role** → attach `ssm-instance-role`

---

## Step 3: Verify Managed Instances

1. **Systems Manager Console** → **Fleet Manager** (or **Managed instances** under Node Management)
2. Confirm your instance appears with **Ping status: Online**
3. If not appearing, verify: SSM Agent running, IAM role attached, instance has outbound internet/NAT access (or SSM VPC endpoints for private-only instances)

---

## Step 4: Connect via Session Manager (No SSH Key/Open Port Needed)

1. **EC2 Console** → select instance → **Connect** → **Session Manager** tab → **Connect**
2. Opens a browser-based shell directly on the instance
3. Or via CLI:
   ```bash
   aws ssm start-session --target i-0123456789abcdef0
   ```
4. **Key benefit**: no inbound SSH port (22) needs to be open in the security group at all — all access is via the SSM Agent's outbound connection, fully logged in CloudTrail

---

## Step 5: Run Commands Across Multiple Instances (Run Command)

1. Left sidebar → **Run Command** → **Run command**
2. Select a document, e.g., `AWS-RunShellScript`
3. **Command parameters**:
   ```bash
   sudo yum update -y
   sudo systemctl restart httpd
   ```
4. **Targets**: select instances by tag (e.g., `Environment=Production`), manually, or by resource group
5. **Output options**: enable S3 or CloudWatch Logs output for auditing
6. Click **Run**
7. Review per-instance output under the command's **Output** tab

---

## Step 6: Store Configuration in Parameter Store

1. Left sidebar → **Parameter Store** → **Create parameter**
2. Configure:
   - Name: `/orders-app/prod/db-host`
   - Type: **String** (or **SecureString** for sensitive values, encrypted via KMS)
   - Value: `prod-postgres-db.abc123.ap-south-1.rds.amazonaws.com`
3. Click **Create parameter**
4. Retrieve in application code:
   ```bash
   aws ssm get-parameter --name /orders-app/prod/db-host --with-decryption
   ```
5. Use hierarchical naming (`/app/env/key`) for organized, IAM-scopable access via path-based policies

---

## Step 7: Automate Patching with Patch Manager

1. Left sidebar → **Patch Manager** → **Configure patching**
2. Select target instances by tag
3. **Patch baseline**: use the default (AWS-provided), or create a custom baseline defining approval rules (e.g., auto-approve security patches after 7 days)
4. **Schedule**: create a maintenance window, e.g., weekly Sunday 2 AM
5. Click **Configure patching**
6. Review compliance under **Patch Manager** → **Compliance reporting**

---

## Step 8: Use State Manager to Enforce Configuration Drift Correction

1. Left sidebar → **State Manager** → **Create association**
2. Select a document (e.g., ensure a specific package is always installed, or a config file matches a defined state)
3. Targets: by tag
4. Schedule: **Rate**, e.g., every 30 minutes — State Manager continuously re-applies the desired state
5. Click **Create association**

---

## Step 9: Use Automation Runbooks (Self-Healing / Routine Ops)

1. Left sidebar → **Automation** → **Execute automation**
2. Choose a document, e.g., `AWS-RestartEC2Instance` or a custom automation document chaining multiple steps
3. Targets and parameters as needed → **Execute**
4. Combine with **CloudWatch Alarms** → **EventBridge** to trigger automation runbooks automatically on alarm state changes (e.g., auto-restart an unhealthy service)

---

## Step 10: Port Forwarding via Session Manager (Access Private Resources)

Connect to a private RDS/internal service without a bastion host:

```bash
aws ssm start-session \
  --target i-0123456789abcdef0 \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{"host":["prod-postgres-db.abc123.ap-south-1.rds.amazonaws.com"],"portNumber":["5432"],"localPortNumber":["5432"]}'
```

Then connect to `localhost:5432` locally — traffic tunnels securely through the SSM Agent on the EC2 instance.

---

## Verification Checklist

- [ ] SSM Agent running and instances show **Online** in Fleet Manager
- [ ] IAM role `AmazonSSMManagedInstanceCore` attached to all managed instances
- [ ] Session Manager tested — no SSH port needed to be open
- [ ] Sensitive config stored as `SecureString` parameters, not plaintext
- [ ] Patch Manager baseline and maintenance window configured for production instances
- [ ] Run Command output logged to S3/CloudWatch for auditing
- [ ] CloudTrail confirms all Session Manager sessions are logged

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| Instance shows offline in Fleet Manager | SSM Agent not running, missing IAM role, or no outbound connectivity | Verify agent status, attach role, confirm NAT/internet access or SSM VPC endpoints |
| Session Manager connection fails | Security group blocks all outbound, or agent outdated | Allow outbound HTTPS (443); update the SSM Agent |
| Run Command shows "Failed" on some instances | Script error, or command timeout too short | Check per-instance output; increase the command timeout |
| Parameter Store `AccessDenied` | IAM policy doesn't cover the specific parameter path | Scope policy to `arn:aws:ssm:region:account:parameter/orders-app/*` |

---

## Next Steps / Advanced Topics

- **SSM Inventory** — collect software/configuration metadata across your fleet for compliance reporting
- **Change Manager** — formal change request/approval workflow before running automations in production
- **Hybrid Activations** — manage on-premises servers alongside EC2 through the same SSM console
- **Infrastructure as Code** — manage parameters, patch baselines, and associations via Terraform or CloudFormation


---

<a id="chapter-22-codecommit-codedeploy"></a>

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


---

<a id="chapter-23-stepfunctions-eventbridge"></a>

# Setting Up Step Functions & EventBridge in AWS — Complete Step-by-Step Guide

AWS Step Functions orchestrates multi-step workflows (state machines) across Lambda, ECS, SQS, and other services with built-in error handling and retries. Amazon EventBridge is AWS's event bus, routing events between AWS services, SaaS apps, and custom applications based on rules. This guide covers both — commonly used together to build event-driven, orchestrated automation.

---

## Architecture Overview

```
      Event Source (S3, custom app, schedule)
                    │
             EventBridge Bus
                    │
              Rule (pattern match)
                    │
        ┌───────────┼────────────┐
        │           │            │
    Lambda      Step Functions   SQS/SNS
                     │
          ┌──────────┼──────────┐
          │          │          │
      Task 1      Choice     Task 2
     (Lambda)    (branch)   (Lambda)
          │
      Parallel / Retry / Catch
```

---

## Prerequisites

- Active AWS account
- IAM user/role with `AWSStepFunctionsFullAccess` and `AmazonEventBridgeFullAccess`
- Existing Lambda functions or other targets to orchestrate (see companion *AWS Lambda Creation Guide*)

---

## Part A: Step Functions

### Step A1: Sign In and Open Step Functions

1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in, select your region
3. Search for `Step Functions` and select it

### Step A2: Create a State Machine

1. **State machines** → **Create state machine**
2. Choose authoring method: **Design your workflow visually** (drag-and-drop) or **Write your workflow in code** (Amazon States Language / ASL)
3. Type: **Standard** (durable, up to 1 year, exactly-once, best for long workflows/audit trail) or **Express** (high-volume, up to 5 minutes, at-least-once, cheaper per-execution — best for event processing)

Select **Standard** for this guide.

### Step A3: Define the Workflow (ASL)

```json
{
  "Comment": "Order processing workflow",
  "StartAt": "ValidateOrder",
  "States": {
    "ValidateOrder": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:ap-south-1:123456789012:function:validate-order",
      "Next": "IsValid",
      "Retry": [
        {
          "ErrorEquals": ["States.TaskFailed"],
          "IntervalSeconds": 2,
          "MaxAttempts": 3,
          "BackoffRate": 2.0
        }
      ],
      "Catch": [
        {
          "ErrorEquals": ["States.ALL"],
          "Next": "NotifyFailure"
        }
      ]
    },
    "IsValid": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.isValid",
          "BooleanEquals": true,
          "Next": "ProcessPayment"
        }
      ],
      "Default": "NotifyFailure"
    },
    "ProcessPayment": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:ap-south-1:123456789012:function:process-payment",
      "Next": "ParallelFulfillment"
    },
    "ParallelFulfillment": {
      "Type": "Parallel",
      "Branches": [
        {
          "StartAt": "UpdateInventory",
          "States": {
            "UpdateInventory": {
              "Type": "Task",
              "Resource": "arn:aws:lambda:ap-south-1:123456789012:function:update-inventory",
              "End": true
            }
          }
        },
        {
          "StartAt": "SendConfirmationEmail",
          "States": {
            "SendConfirmationEmail": {
              "Type": "Task",
              "Resource": "arn:aws:lambda:ap-south-1:123456789012:function:send-email",
              "End": true
            }
          }
        }
      ],
      "Next": "Success"
    },
    "Success": {
      "Type": "Succeed"
    },
    "NotifyFailure": {
      "Type": "Task",
      "Resource": "arn:aws:sns:ap-south-1:123456789012:order-events",
      "End": true
    }
  }
}
```

### Key State Types

| State Type | Purpose |
|---|---|
| `Task` | Invokes a Lambda, ECS task, or other supported service integration |
| `Choice` | Branches based on input data (like an if/else) |
| `Parallel` | Runs multiple branches concurrently |
| `Map` | Iterates over a collection, running a sub-workflow per item |
| `Wait` | Pauses for a fixed time or until a timestamp |
| `Succeed` / `Fail` | Terminal states |

### Step A4: Set the Execution Role

1. On the review step, select/create an IAM role that Step Functions assumes to invoke the resources in your workflow (Lambda, SNS, etc.)
2. Name: `orders-workflow-role`
3. Click **Create state machine**

### Step A5: Execute and Test

1. Select the state machine → **Start execution**
2. Input (JSON):
   ```json
   {"orderId": "ORD-1001", "amount": 149.99}
   ```
3. Click **Start execution**
4. Watch the **Graph view** — completed states turn green, failed states red
5. Click any state to see its input/output for debugging

### Step A6: Add Error Handling Patterns

- **Retry**: automatically retries a failed task with exponential backoff (shown in Step A3)
- **Catch**: routes to a fallback state on specific error types instead of failing the whole execution
- **Timeout**: set `TimeoutSeconds` on a Task to prevent it from hanging indefinitely

### Step A7: Monitor Executions

1. Select the state machine → **Executions** tab — see history of all runs, filterable by status
2. **CloudWatch** → `AWS/States` namespace — metrics like `ExecutionsFailed`, `ExecutionTime`
3. Set an alarm on `ExecutionsFailed > 0` to catch workflow failures

---

## Part B: EventBridge

### Step B1: Explore the Default Event Bus

1. Search for `EventBridge` and select it
2. Left sidebar → **Event buses** — the `default` bus automatically receives events from most AWS services
3. Create a **custom event bus** for application-specific events: **Event buses** → **Create event bus** → name: `orders-app-bus`

### Step B2: Create a Rule (Schedule-Based)

1. Left sidebar → **Rules** → **Create rule**
2. Name: `nightly-cleanup`
3. Event bus: `default`
4. Rule type: **Schedule**
5. Schedule pattern:
   - Cron expression: `cron(0 2 * * ? *)` (2 AM daily)
   - Or rate expression: `rate(1 hour)`
6. Click **Next**
7. **Target**: select **Lambda function**, **Step Functions state machine**, or another target → select your resource
8. Click **Next** → review → **Create rule**

### Step B3: Create a Rule (Event Pattern-Based)

React to actual AWS service events, e.g., an S3 upload:

1. **Create rule** → Rule type: **Event pattern**
2. **Event source**: **AWS services**
3. **AWS service**: **Simple Storage Service (S3)**
4. **Event type**: **Object Created**
5. Specify the bucket name to filter to
6. Generated pattern:
   ```json
   {
     "source": ["aws.s3"],
     "detail-type": ["Object Created"],
     "detail": {
       "bucket": {"name": ["my-app-bucket-prod-2026"]}
     }
   }
   ```
7. Target: your Lambda function or Step Functions state machine
8. Click **Create rule**

### Step B4: Publish Custom Application Events

From your application code:

```python
import boto3
import json

client = boto3.client("events")
client.put_events(
    Entries=[
        {
            "Source": "orders.app",
            "DetailType": "OrderCreated",
            "Detail": json.dumps({"orderId": "ORD-1001", "amount": 149.99}),
            "EventBusName": "orders-app-bus"
        }
    ]
)
```

Create a matching rule on `orders-app-bus`:
```json
{
  "source": ["orders.app"],
  "detail-type": ["OrderCreated"]
}
```

### Step B5: Trigger a Step Functions Workflow from EventBridge

1. **Create rule** on the relevant event bus with the pattern from Step B4
2. Target: **Step Functions state machine** → select the workflow from Part A
3. **Configure input**: pass the full event, or a **constant JSON text**, or **input transformer** to reshape the event before passing it to the state machine
4. Click **Create rule**

This is the standard pattern for **event-driven orchestration**: an event occurs → EventBridge routes it → Step Functions coordinates the multi-step response.

### Step B6: Set Up an Archive and Replay (Optional)

Useful for debugging or reprocessing past events.

1. Left sidebar → **Archives** → **Create archive**
2. Select the event bus, retention period (or indefinite), and an optional filter
3. To replay: **Replays** → **Start new replay** → select the archive and a time range → target the same or a different rule/bus

### Step B7: Cross-Account/Cross-Region Event Bus

1. **Event buses** → select bus → **Permissions** → add a resource policy granting another account `events:PutEvents`
2. In the sending account, create a rule targeting the receiving account's event bus ARN as the target
3. Useful for centralizing events (e.g., security findings) from many accounts into one monitoring account

---

## Verification Checklist

- [ ] State machine type (Standard vs. Express) matches the workflow's duration/volume needs
- [ ] Retry and Catch configured on tasks likely to transiently fail
- [ ] Execution role scoped to only the resources the workflow actually invokes
- [ ] CloudWatch alarm configured on `ExecutionsFailed`
- [ ] EventBridge rules use specific event patterns, not overly broad matches
- [ ] Custom application events follow a consistent `Source`/`DetailType` naming convention
- [ ] Archive configured for critical event buses to support replay/debugging
- [ ] Cross-account event routing tested if applicable

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| Step Functions execution fails immediately | Execution role lacks permission to invoke the target Lambda/service | Add the missing `lambda:InvokeFunction` (or equivalent) permission to the execution role |
| EventBridge rule never triggers | Event pattern doesn't match actual event structure | Use the **Sample events** feature in the console to compare against your pattern; check `source`/`detail-type` casing |
| Scheduled rule fires at unexpected time | Cron expressions in EventBridge use **UTC**, not local time | Convert your desired local time to UTC when writing the cron expression |
| Duplicate workflow executions from one event | EventBridge's at-least-once delivery, or Express state machine's at-least-once semantics | Design downstream tasks to be idempotent |

---

## Next Steps / Advanced Topics

- **Step Functions + Map (Distributed Map)** — process millions of items in parallel (e.g., S3 objects) at scale
- **EventBridge Pipes** — simplified point-to-point integration between a source (e.g., SQS) and a target, with optional filtering/enrichment, without writing custom Lambda glue code
- **EventBridge Scheduler** — a dedicated, more flexible scheduling service (millions of schedules) as an alternative to schedule-based rules
- **Infrastructure as Code** — manage state machines, rules, and event buses via Terraform, AWS SAM, or CloudFormation


---

<a id="chapter-24-cloudtrail-xray"></a>

# Setting Up CloudTrail & X-Ray in AWS — Complete Step-by-Step Guide

AWS CloudTrail records every API call made in your account for auditing and security investigation. AWS X-Ray traces requests as they travel through distributed applications, pinpointing latency and errors across services. Together they cover **who did what** (CloudTrail) and **where time is spent/what broke** (X-Ray) — two pillars of DevOps observability.

---

## Architecture Overview

```
   Every API call (console, CLI, SDK)
                │
           CloudTrail
                │
      ┌─────────┴─────────┐
      │                   │
  S3 (log archive)   CloudWatch Logs (alerting)


   Request → API Gateway → Lambda → DynamoDB
                │            │         │
                └──────┬─────┴─────────┘
                    X-Ray traces
                (Service Map + timing)
```

---

## Prerequisites

- Active AWS account
- IAM user/role with `AWSCloudTrail_FullAccess` and `AWSXRayFullAccess`

---

## Part A: CloudTrail

### Step A1: Sign In and Open CloudTrail

1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in with IAM credentials
3. Search for `CloudTrail` and select it

> A basic **Event history** (last 90 days, management events) is enabled automatically in every account at no cost — creating a **Trail** (Step A2) extends this with permanent storage, data events, and alerting.

### Step A2: Create a Trail

1. Left sidebar → **Trails** → **Create trail**
2. Configure:
   - Trail name: `org-management-trail`
   - **Enable for all accounts in my organization**: check if using AWS Organizations and this is the management account
   - Storage location: **Create new S3 bucket** (or use existing) — e.g., `cloudtrail-logs-123456789012`
   - **Log file SSE-KMS encryption**: enable, select/create a KMS key
   - **Log file validation**: enable (detects tampering via digest files)
3. Click **Next**

### Step A3: Choose Event Types

1. **Management events**: check **Read** and **Write** — captures control-plane operations (creating/deleting resources, IAM changes)
2. **Data events** (optional, higher cost/volume): capture object-level activity, e.g.:
   - S3: `GetObject`, `PutObject` on specific buckets
   - Lambda: `Invoke` calls
   - DynamoDB: item-level `GetItem`/`PutItem`
3. **Insights events** (optional): CloudTrail Insights automatically detects unusual API call volume/error rate patterns
4. Click **Next** → review → **Create trail**

### Step A4: Enable CloudWatch Logs Integration (For Alerting)

1. Select the trail → **Edit**
2. **CloudWatch Logs**: enable, select/create a log group (e.g., `CloudTrail/org-management-trail`)
3. IAM role: auto-create one with permission to deliver logs
4. Click **Save**
5. Now you can create **CloudWatch Alarms** or **Metric Filters** on specific API activity, e.g., alert whenever `DeleteBucket`, `AuthorizationFailure`, or root account login occurs

### Step A5: Create a Metric Filter/Alarm for Security-Critical Events

1. **CloudWatch** → **Log groups** → select `CloudTrail/org-management-trail` → **Metric filters** → **Create metric filter**
2. Filter pattern (example — detect root account usage):
   ```
   { $.userIdentity.type = "Root" && $.eventType != "AwsServiceEvent" }
   ```
3. Metric name: `RootAccountUsage`
4. Create a CloudWatch alarm on this metric ≥ 1 → notify via SNS
5. Repeat for other high-value patterns: `ConsoleLogin` failures, `DeleteTrail`, `StopLogging`, IAM policy changes

### Step A6: Query and Investigate Events

1. **Event history** tab — filter by event name, resource, user, or time range without needing Athena
2. For deeper analysis at scale, set up **CloudTrail Lake**:
   - Left sidebar → **Lake** → **Create event data store**
   - Query with SQL directly in the console — no need to set up Athena/S3 manually
   ```sql
   SELECT eventName, eventTime, userIdentity.arn
   FROM event_data_store
   WHERE eventName = 'DeleteBucket'
   ORDER BY eventTime DESC
   ```

### Step A7: Verify Log Integrity

1. Select the trail → **Log file validation** should show **Enabled**
2. To manually validate a range of log files:
   ```bash
   aws cloudtrail validate-logs \
     --trail-arn arn:aws:cloudtrail:ap-south-1:123456789012:trail/org-management-trail \
     --start-time 2026-07-01T00:00:00Z
   ```

---

## Part B: X-Ray

### Step B1: Open X-Ray

1. Search for `X-Ray` and select it (or find it under **CloudWatch** → **Application Signals / X-Ray traces** in newer console layouts)

### Step B2: Enable X-Ray on Lambda

1. **Lambda Console** → select function → **Configuration** tab → **Monitoring and operations tools** → **Edit**
2. Enable **Active tracing**
3. Click **Save**
4. Attach the `AWSXRayDaemonWriteAccess` policy to the function's execution role (often bundled automatically when enabling via console)

### Step B3: Instrument Application Code

**Python (Lambda) example:**
```python
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.core import patch_all

patch_all()  # auto-instruments boto3, requests, etc.

def lambda_handler(event, context):
    subsegment = xray_recorder.begin_subsegment("process-order")
    try:
        # business logic
        result = process_order(event)
    finally:
        xray_recorder.end_subsegment()
    return result
```

**Node.js example:**
```javascript
const AWSXRay = require('aws-xray-sdk-core');
const AWS = AWSXRay.captureAWS(require('aws-sdk'));

exports.handler = async (event) => {
  const segment = AWSXRay.getSegment();
  const subsegment = segment.addNewSubsegment('process-order');
  try {
    // business logic
  } finally {
    subsegment.close();
  }
};
```

### Step B4: Enable X-Ray on API Gateway

1. **API Gateway Console** → select API → **Stages** → select stage → **Logs/Tracing** tab → **Edit**
2. Enable **X-Ray Tracing**
3. Click **Save**

### Step B5: Enable X-Ray on ECS/Fargate

1. Add the **X-Ray daemon** as a sidecar container in your task definition:
   ```json
   {
     "name": "xray-daemon",
     "image": "amazon/aws-xray-daemon",
     "cpu": 32,
     "memoryReservation": 256,
     "portMappings": [{"containerPort": 2000, "protocol": "udp"}]
   }
   ```
2. Ensure the task role has `AWSXRayDaemonWriteAccess`
3. Application code sends trace data to `localhost:2000` (the daemon sidecar)

### Step B6: View the Service Map

1. **X-Ray Console** → **Service map**
2. Visualizes every service your traced requests pass through, color-coded by health:
   - Green: healthy response times/error rates
   - Yellow/Red: elevated latency or error rate
3. Click any node to drill into its traces

### Step B7: Analyze Individual Traces

1. **X-Ray Console** → **Traces**
2. Filter by time range, response time, or annotation
3. Click a trace ID to see the full **timeline** — each segment/subsegment shows exactly how long each downstream call took
4. Identify bottlenecks: e.g., a DynamoDB call taking 800ms out of a 900ms total Lambda duration

### Step B8: Add Custom Annotations and Metadata

```python
subsegment.put_annotation("orderId", event["orderId"])  # indexed, searchable
subsegment.put_metadata("orderDetails", event)            # not indexed, for context only
```

Annotations let you filter traces in the console, e.g., find all traces for a specific `orderId` during a customer support investigation.

### Step B9: Set Up Sampling Rules (Control Cost/Volume)

1. Left sidebar → **Sampling rules** → **Create rule**
2. Configure:
   - Rule name: `orders-app-sampling`
   - Reservoir size: `1` request/second traced at 100%, beyond that
   - Rate: `5%` of additional requests
3. Click **Create**
4. Reduces X-Ray costs on high-traffic services while still capturing a representative sample plus every distinct new pattern

---

## Verification Checklist

- [ ] CloudTrail trail created covering all regions, with log file validation and encryption enabled
- [ ] CloudTrail logs delivered to both S3 (long-term) and CloudWatch Logs (alerting)
- [ ] Metric filters/alarms configured for security-critical events (root login, IAM changes, trail tampering)
- [ ] X-Ray active tracing enabled on Lambda/API Gateway/ECS
- [ ] Application code instrumented with the X-Ray SDK, not just infrastructure-level tracing
- [ ] Service map reviewed to confirm all expected services appear and are connected correctly
- [ ] Sampling rules configured to control cost on high-volume services
- [ ] Custom annotations added for key business identifiers (order ID, user ID) to aid debugging

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| CloudTrail Event history missing expected events | Data events not enabled (only management events captured by default) | Enable data events for the specific resource types you need to audit |
| Metric filter alarm never fires | Filter pattern doesn't match actual log JSON structure | Test the pattern against a real sample log entry in the console |
| X-Ray shows no traces | Active tracing not enabled, or SDK not instrumented in code | Verify both infrastructure-level tracing AND application code `patch_all()`/SDK wrapping |
| Service map shows a gap between two services | One service isn't propagating the trace header (`X-Amzn-Trace-Id`) downstream | Ensure the HTTP client/SDK used for that call is X-Ray-instrumented |
| Sampling causes missing traces during an incident | Sampling rate too low for the traffic pattern | Temporarily increase the sampling rate/reservoir during active investigations |

---

## Next Steps / Advanced Topics

- **CloudTrail Lake + Athena** — long-term SQL-based forensic analysis across years of API history
- **GuardDuty** — layer machine-learning threat detection on top of CloudTrail/VPC Flow Logs data
- **AWS Config** — complements CloudTrail by tracking resource *configuration state* over time, not just API calls
- **X-Ray + CloudWatch ServiceLens** — unified view combining traces, logs, and metrics in one dashboard
- **Infrastructure as Code** — manage trails, event data stores, and sampling rules via Terraform or CloudFormation
