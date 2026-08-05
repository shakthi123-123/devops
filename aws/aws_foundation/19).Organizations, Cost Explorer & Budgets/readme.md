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
