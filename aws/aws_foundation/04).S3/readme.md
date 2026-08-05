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
