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
