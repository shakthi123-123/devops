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
