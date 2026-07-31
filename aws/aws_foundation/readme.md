# AWS Foundations — Complete Setup Guide

A combined, ordered reference for provisioning a secure AWS environment from scratch: networking, identity, compute, storage, databases, serverless functions, APIs, monitoring, NoSQL, and containers.

## Recommended Build Order

This document follows the sequence a real deployment typically uses — each chapter builds on resources created in the ones before it:

1. **[VPC](#chapter-1-vpc)** — network foundation (subnets, routing, internet/NAT gateways)
2. **[IAM](#chapter-2-iam)** — users, groups, roles, and least-privilege policies
3. **[EC2](#chapter-3-ec2)** — virtual servers in the VPC's public subnet
4. **[S3](#chapter-4-s3)** — object storage for assets, backups, and static content
5. **[RDS](#chapter-5-rds)** — managed relational database in the VPC's private subnets
6. **[Lambda](#chapter-6-lambda)** — serverless functions, often reading/writing S3 and RDS
7. **[API Gateway](#chapter-7-api-gateway)** — HTTP front door for Lambda and other backends
8. **[CloudWatch](#chapter-8-cloudwatch)** — dashboards, logs, alarms, and automated monitoring across every service above
9. **[DynamoDB](#chapter-9-dynamodb)** — serverless NoSQL database, often paired with Lambda and API Gateway
10. **[ECS (Fargate)](#chapter-10-ecs)** — containerized services as an alternative/complement to EC2 and Lambda

Each chapter is self-contained with its own prerequisites, verification checklist, cleanup steps, and troubleshooting table, so you can also jump directly to the service you need.

---


<a id="chapter-1-vpc"></a>

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

<a id="chapter-2-iam"></a>

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
