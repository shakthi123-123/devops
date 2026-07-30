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
