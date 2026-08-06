# AWS VPC Creation Guide (Step-by-Step, Console Click-Path)

## What you'll build
- 1 VPC (10.0.0.0/16)
- 2 Public Subnets (2 AZs) + 2 Private Subnets (2 AZs)
- 1 Internet Gateway
- 1 NAT Gateway (on-demand, in a public subnet)
- Public + Private Route Tables
- Security Groups (public + private)
- 1 EC2 in a public subnet, 1 EC2 in a private subnet
- Full teardown steps at the end (NAT Gateway bills hourly — delete it first when done)

Region used in this guide: **us-east-1**. Swap AZs if you use a different region.

---

## Step 1: Create the VPC

`VPC Console → Your VPCs → Create VPC`

Select **VPC only**.

| Field | Value |
|---|---|
| Name tag | Demo-VPC |
| IPv4 CIDR | 10.0.0.0/16 |
| IPv6 CIDR | No IPv6 CIDR Block |
| Tenancy | Default |
| VPC encryption control | None |

Click **Create VPC**.

---

## Step 2: Create the 4 Subnets

`VPC Console → Subnets → Create subnet` (do this 4 times, one per row below)

| Subnet Name | AZ | CIDR | Auto-assign public IPv4 |
|---|---|---|---|
| Public-Subnet-1 | us-east-1a | 10.0.1.0/24 | Enable (after creation, see note below) |
| Public-Subnet-2 | us-east-1b | 10.0.2.0/24 | Enable (after creation, see note below) |
| Private-Subnet-1 | us-east-1a | 10.0.3.0/24 | Leave disabled |
| Private-Subnet-2 | us-east-1b | 10.0.4.0/24 | Leave disabled |

All four use VPC = **Demo-VPC**. Set the **Tag Name** to match the Subnet Name for each.

**Enable auto-assign public IP on the public subnets:**
`Select Public-Subnet-1 → Actions → Edit subnet settings → Enable auto-assign public IPv4 address → Save`
Repeat for Public-Subnet-2.

---

## Step 3: Create and Attach the Internet Gateway

`VPC Console → Internet Gateways → Create internet gateway`

| Field | Value |
|---|---|
| Name tag | Demo-IGW |

Click **Create internet gateway**.

Then: `Select Demo-IGW → Actions → Attach to VPC → choose Demo-VPC → Attach internet gateway`

---

## Step 4: Create Route Tables

### Public Route Table
`VPC Console → Route Tables → Create route table`

| Field | Value |
|---|---|
| Name | Public-RT |
| VPC | Demo-VPC |

**Add the internet route:**
`Select Public-RT → Routes tab → Edit routes → Add route`

| Destination | Target |
|---|---|
| 0.0.0.0/0 | Internet Gateway → Demo-IGW |

Save changes.

**Associate subnets:**
`Select Public-RT → Subnet associations tab → Edit subnet associations → check Public-Subnet-1 and Public-Subnet-2 → Save`

### Private Route Table
`VPC Console → Route Tables → Create route table`

| Field | Value |
|---|---|
| Name | Private-RT |
| VPC | Demo-VPC |

Leave routes as-is for now — the NAT route gets added in Step 5, after the NAT Gateway exists.

**Associate subnets:**
`Select Private-RT → Subnet associations tab → Edit subnet associations → check Private-Subnet-1 and Private-Subnet-2 → Save`

---

## Step 5: Create the NAT Gateway (on-demand)

`VPC Console → NAT Gateways → Create NAT gateway`

| Field | Value |
|---|---|
| Name | Demo-NAT |
| Subnet | Public-Subnet-1 |
| Connectivity type | Public |
| Elastic IP allocation ID | Allocate Elastic IP → select it |

Click **Create NAT gateway**. Wait until status is **Available** (takes a few minutes).

> Cost note: a NAT Gateway bills ~$0.045/hr (region-dependent) plus data processing charges the moment it's Available — this is the main reason to delete it promptly when you're done.

**Route private traffic through it:**
`Route Tables → Private-RT → Routes tab → Edit routes → Add route`

| Destination | Target |
|---|---|
| 0.0.0.0/0 | NAT Gateway → Demo-NAT |

Save changes.

---

## Step 6: Create Security Groups

`VPC Console → Security Groups → Create security group`

### Public-SG (for the public EC2, e.g. a bastion/web host)

| Field | Value |
|---|---|
| Name | Public-SG |
| Description | Public EC2 access |
| VPC | Demo-VPC |

Inbound rules:
| Type | Port | Source |
|---|---|---|
| SSH | 22 | My IP |
| HTTP | 80 | 0.0.0.0/0 *(only if hosting a web app)* |

Outbound: leave default (All traffic → 0.0.0.0/0).

### Private-SG (for the private EC2)

| Field | Value |
|---|---|
| Name | Private-SG |
| Description | Private EC2 access |
| VPC | Demo-VPC |

Inbound rules:
| Type | Port | Source |
|---|---|---|
| SSH | 22 | Public-SG *(select the security group, not an IP — allows SSH only from the public instance)* |

Outbound: leave default.

---

## Step 7: Launch the EC2 Instances

`EC2 Console → Instances → Launch instances`

### Public EC2

| Field | Value |
|---|---|
| Name | Public-EC2 |
| AMI | Amazon Linux 2023 |
| Instance type | t2.micro / t3.micro |
| Key pair | Create or select one — needed for SSH |
| Network (VPC) | Demo-VPC |
| Subnet | Public-Subnet-1 |
| Auto-assign public IP | Enable |
| Security group | Public-SG |

Launch instance.

### Private EC2

| Field | Value |
|---|---|
| Name | Private-EC2 |
| AMI | Amazon Linux 2023 |
| Instance type | t2.micro / t3.micro |
| Key pair | Same or a separate one |
| Network (VPC) | Demo-VPC |
| Subnet | Private-Subnet-1 |
| Auto-assign public IP | Disable |
| Security group | Private-SG |

Launch instance.

To reach Private-EC2, SSH into Public-EC2 first (using its public IP), then SSH from there to Private-EC2's private IP (this is why Private-SG allows SSH from Public-SG).

---

## Architecture

```
                         Internet
                             │
                     Internet Gateway (Demo-IGW)
                             │
                    ┌────────────────────┐
                    │      Demo-VPC       │
                    │    10.0.0.0/16      │
                    └────────────────────┘
                        │              │
                Public Route Table   Private Route Table
                  (0.0.0.0/0→IGW)     (0.0.0.0/0→NAT)
                        │              │
        ┌───────────────┴───┐   ┌──────┴───────────────┐
        │                    │   │                       │
 Public-Subnet-1(1a)  Public-Subnet-2(1b)  Private-Subnet-1(1a)  Private-Subnet-2(1b)
  10.0.1.0/24          10.0.2.0/24          10.0.3.0/24            10.0.4.0/24
        │
   Public-EC2
   (+ NAT Gateway
    lives here too)
                                              Private-EC2 (in Private-Subnet-1)
```

---

## Resources Created

| Resource | Name |
|---|---|
| VPC | Demo-VPC |
| Public Subnets | Public-Subnet-1, Public-Subnet-2 |
| Private Subnets | Private-Subnet-1, Private-Subnet-2 |
| Internet Gateway | Demo-IGW |
| NAT Gateway | Demo-NAT (+ its Elastic IP) |
| Public Route Table | Public-RT |
| Private Route Table | Private-RT |
| Security Groups | Public-SG, Private-SG |
| EC2 Instances | Public-EC2, Private-EC2 |

---

## Verification Checklist

- ✅ VPC created
- ✅ 2 public subnets created, in different AZs, auto-assign public IP enabled
- ✅ 2 private subnets created, in different AZs
- ✅ Internet Gateway created and attached to Demo-VPC
- ✅ Public-RT has `0.0.0.0/0 → Demo-IGW`, associated with both public subnets
- ✅ NAT Gateway created in a public subnet, status Available
- ✅ Private-RT has `0.0.0.0/0 → Demo-NAT`, associated with both private subnets
- ✅ Public-SG allows SSH from your IP
- ✅ Private-SG allows SSH only from Public-SG
- ✅ Public-EC2 launched in Public-Subnet-1, has a public IP
- ✅ Private-EC2 launched in Private-Subnet-1, no public IP, reachable via Public-EC2

---

## Teardown — Delete Everything (in this order)

Deleting out of order will fail on dependencies, so follow this sequence exactly.

1. **Terminate EC2 instances**
   `EC2 → Instances → select Public-EC2 and Private-EC2 → Instance state → Terminate instance`
   Wait until both show **Terminated**.

2. **Delete the NAT Gateway** (do this early — it's the main ongoing cost)
   `VPC → NAT Gateways → select Demo-NAT → Actions → Delete NAT gateway`
   Wait until it shows **Deleted** (takes a minute or two).

3. **Release the Elastic IP**
   `VPC → Elastic IPs → select the IP used by Demo-NAT → Actions → Release Elastic IP address`

4. **Detach and delete the Internet Gateway**
   `VPC → Internet Gateways → select Demo-IGW → Actions → Detach from VPC → confirm`
   Then: `Actions → Delete internet gateway`

5. **Delete the Route Tables**
   `VPC → Route Tables → select Public-RT → Actions → Delete route table`
   Repeat for Private-RT.
   (The main/default route table for the VPC deletes automatically with the VPC — don't try to delete it manually.)

6. **Delete the Security Groups**
   `VPC → Security Groups → select Private-SG → Actions → Delete security groups`
   Repeat for Public-SG.
   (Delete these before the VPC, but after the EC2 instances are terminated, since instances reference them.)

7. **Delete the Subnets**
   `VPC → Subnets → select all 4 (Public-Subnet-1, Public-Subnet-2, Private-Subnet-1, Private-Subnet-2) → Actions → Delete subnet → confirm`

8. **Delete the VPC**
   `VPC → Your VPCs → select Demo-VPC → Actions → Delete VPC`
   AWS will prompt to also delete any remaining dependent resources — review the list and confirm.

9. **Double-check nothing billable is left**
   Check **NAT Gateways**, **Elastic IPs**, and **EC2 Instances** consoles once more — an orphaned Elastic IP is the most common thing people forget, and it bills hourly if unattached.
