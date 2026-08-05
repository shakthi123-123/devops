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
