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
