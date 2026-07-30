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
