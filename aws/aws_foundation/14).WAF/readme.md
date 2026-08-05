# Setting Up AWS WAF — Complete Step-by-Step Guide

AWS WAF (Web Application Firewall) protects web applications from common exploits — SQL injection, XSS, bot traffic, and volumetric attacks — by filtering requests before they reach CloudFront, ALB, API Gateway, or AppSync. This guide covers creating a Web ACL, adding managed and custom rules, and monitoring blocked traffic.

---

## Architecture Overview

```
                    Internet Traffic
                          │
                  ┌───────────────┐
                  │   AWS WAF       │
                  │   Web ACL        │
                  │                 │
                  │  Managed Rules   │
                  │  Custom Rules    │
                  │  Rate Limiting   │
                  │  IP Sets         │
                  └───────┬────────┘
                          │ (allowed traffic only)
              ┌───────────┴────────────┐
              │            │           │
        CloudFront       ALB      API Gateway
```

---

## Prerequisites

- Active AWS account
- IAM user/role with `AWSWAFFullAccess` (or scoped equivalent) permissions
- An existing resource to protect: CloudFront distribution, Application Load Balancer, API Gateway REST API, or AppSync GraphQL API

---

## Step 1: Sign In and Open WAF

1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in with IAM credentials
3. In the search bar, type `WAF` and select **WAF & Shield**

> **Region note:** For CloudFront, WAF must be configured in the **Global (CloudFront)** scope, viewed from `us-east-1`. For ALB, API Gateway, or AppSync, select **Regional** and your target region.

---

## Step 2: Create a Web ACL

1. Left sidebar → **Web ACLs** → **Create web ACL**
2. **Web ACL details**:

| Field | Value | Notes |
|---|---|---|
| Name | `orders-app-waf` | |
| Description | `Protects orders-alb from common exploits` | |
| Resource type | **Regional** or **CloudFront** | Match to what you're protecting |
| Region | your region (if Regional) | |

3. **Associated AWS resources**:
   - Click **Add AWS resources**
   - Select your ALB, API Gateway stage, or CloudFront distribution
   - Click **Add**
4. Click **Next**

---

## Step 3: Add AWS Managed Rule Groups

Managed rule groups are pre-built, AWS-maintained rulesets covering common threats — the fastest way to get solid baseline protection.

1. On the **Rules** step, click **Add rules** → **Add managed rule groups**
2. Expand **AWS managed rule groups** and add:

| Rule Group | Protects Against |
|---|---|
| **Core rule set (CRS)** | Broad OWASP Top 10 coverage — generally recommended for all apps |
| **Known bad inputs** | Requests matching patterns of known exploitation attempts |
| **SQL database** | SQL injection attempts |
| **Amazon IP reputation list** | Requests from IPs with poor reputation (known bad actors) |
| **Anonymous IP list** | Traffic from VPNs, proxies, Tor exit nodes |
| **Bot Control** (additional cost) | Identifies and manages bot traffic |

3. For each, set the action:
   - **Block** — reject matching requests outright (recommended once confident in the rule)
   - **Count** — log but allow through (use first, to observe false positives before switching to Block)
4. Click **Add rules**

> **Best practice:** Start every managed rule group in **Count** mode for 24–48 hours, review the traffic in CloudWatch/Sampled requests (Step 7), then switch to **Block** once you've confirmed no legitimate traffic is being flagged.

---

## Step 4: Add a Rate-Based Rule (Prevent Brute Force / DDoS-Style Abuse)

1. On the **Rules** step → **Add rules** → **Add my own rules and rule groups**
2. Rule type: **Rate-based rule**
3. Configure:
   - Name: `rate-limit-per-ip`
   - Rate limit: `2000` requests per 5-minute period per IP (adjust based on expected traffic)
   - Aggregation key: **IP address** (or use a custom key like a header/cookie for API keys)
4. Action if the rate limit is exceeded: **Block**
5. Click **Add rule**

---

## Step 5: Add a Custom Rule (IP Allow/Block List)

1. **Create IP set** first: left sidebar → **IP sets** → **Create IP set**
   - Name: `office-allowlist`
   - IP version: IPv4
   - Addresses: `203.0.113.0/24` (your office/VPN CIDR)
   - Click **Create IP set**
2. Back in the Web ACL rules step → **Add my own rules and rule groups** → **Rule builder**
3. Configure:
   - Name: `allow-admin-path-from-office`
   - Type: **Regular rule**
   - If a request: **matches the statement**
   - Statement 1: **Originates from an IP address in** → select `office-allowlist`
   - AND
   - Statement 2: **URI path** → **Starts with** → `/admin`
   - Action: **Allow**
4. Click **Add rule**

### Common Custom Rule Examples

| Rule | Statement | Action |
|---|---|---|
| Block a known malicious IP | Source IP in a block-list IP set | Block |
| Restrict admin panel | URI starts with `/admin` AND source not in office IP set | Block |
| Block specific user agents | Header `User-Agent` contains known scraper strings | Block |
| Geo-blocking | Country code is NOT in allowed list (e.g., only allow `IN, US, GB`) | Block |
| SQLi on specific field | Body/query param matches SQL injection pattern | Block |

---

## Step 6: Set Rule Priority and Default Action

1. On the **Rules** step, drag to reorder rules — WAF evaluates rules **in priority order** (lower number = evaluated first) and stops at the first matching terminating action (Block/Allow)
2. Recommended order:
   1. Explicit allow rules (e.g., office IP allowlist for admin paths)
   2. Rate-based rules
   3. AWS managed rule groups
   4. Custom block rules
3. **Default web ACL action for requests that don't match any rules**:
   - **Allow** (most common — block only what you explicitly flag)
   - **Block** (allowlist-only model — more restrictive, requires explicit allow rules for all legitimate traffic)
4. Click **Next** → review → **Create web ACL**

---

## Step 7: Review Sampled Requests and Metrics

1. Select the Web ACL → **Sampled requests** tab
2. Filter by rule to see which requests matched (allowed/blocked) and why
3. Use this to identify false positives when a managed rule group is in **Count** mode before switching to **Block**
4. **Requests** tab → view aggregate metrics: total requests, allowed, blocked, by rule

---

## Step 8: Enable Logging

1. Select the Web ACL → **Logging and metrics** tab → **Enable logging**
2. Choose a destination:
   - **Amazon CloudWatch Logs** (log group, e.g., `aws-waf-logs-orders-app`)
   - **Amazon S3** (for long-term storage/analysis, e.g., with Athena)
   - **Amazon Kinesis Data Firehose** (for streaming to other analytics tools)
3. **Redacted fields** (optional): redact sensitive headers like `Authorization` or `Cookie` from logs
4. Click **Save**

---

## Step 9: Set Up CloudWatch Alarms

1. **CloudWatch Console** → **Alarms** → **Create alarm**
2. Metric: `BlockedRequests` for the Web ACL, namespace `AWS/WAFV2`
3. Threshold: e.g., `> 1000` blocked requests in 5 minutes — could indicate an active attack
4. Notification: SNS topic for the security/ops team
5. Repeat for `CountedRequests` if you want visibility into rules still in Count mode picking up unusual volume

---

## Step 10: Test the Web ACL

1. Send a benign request to confirm normal traffic still works:
   ```bash
   curl -I https://myapp.com/
   ```
   Expect a normal `200`/`302` response.
2. Send a request simulating a blocked pattern (e.g., SQLi test string) to confirm it's blocked:
   ```bash
   curl "https://myapp.com/search?q=' OR '1'='1"
   ```
   Expect a `403 Forbidden` response from WAF.
3. Check **Sampled requests** to confirm which rule triggered the block

---

## Step 11: Verification Checklist

- [ ] Web ACL created with correct scope (Regional vs. CloudFront) matching the protected resource
- [ ] Resource (ALB/CloudFront/API Gateway) associated with the Web ACL
- [ ] AWS managed rule groups added and validated in Count mode before switching to Block
- [ ] Rate-based rule configured to prevent abuse/brute force
- [ ] Custom rules cover known application-specific risks (admin paths, geo-restrictions, etc.)
- [ ] Rule priority ordered correctly (allow-lists before block-lists)
- [ ] Logging enabled to CloudWatch/S3 with sensitive headers redacted
- [ ] CloudWatch alarms configured for spikes in blocked/counted requests
- [ ] Tested both legitimate and malicious sample requests to confirm expected behavior

---

## Cleanup (To Avoid Ongoing Charges)

1. Disassociate the Web ACL from resources: select Web ACL → **Associated AWS resources** → select → **Disassociate**
2. Delete the Web ACL: select → **Delete**
3. Delete unused IP sets: **IP sets** → select → **Delete**
4. Delete the CloudWatch log group / S3 bucket used for WAF logs if no longer needed

> WAF bills per Web ACL per month plus per-rule and per-million-requests charges — remove unused Web ACLs and rule groups (especially Bot Control, which has a higher cost) when not actively needed.

---

## Quick Reference Summary

| Component | Purpose |
|---|---|
| Web ACL | The top-level container of rules, associated with protected resources |
| Managed Rule Group | AWS-maintained ruleset for common threats |
| Custom Rule | User-defined condition and action (block/allow/count) |
| Rate-Based Rule | Blocks IPs exceeding a request-rate threshold |
| IP Set | Reusable list of IP addresses/CIDRs referenced by rules |
| Sampled Requests | Sample of recent requests showing which rule matched |
| Default Action | Fallback behavior for requests matching no explicit rule |

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| Legitimate users getting blocked (403) | Managed rule group too aggressive, or overly broad custom rule | Check Sampled requests to identify the matching rule; switch to Count mode, adjust, or add an allow exception |
| WAF not blocking expected malicious traffic | Rule not associated with the correct resource, or rule in Count mode | Confirm resource association; verify rule action is set to Block |
| No logs appearing | Logging not enabled, or IAM/resource policy issue on log destination | Verify logging configuration and destination permissions |
| Rate-based rule not triggering | Aggregation key mismatch (e.g., traffic behind a shared NAT/proxy all appears as one IP, or as many different IPs) | Adjust aggregation key or threshold; consider header-based aggregation for API traffic |
| High false-positive rate from Core Rule Set | Application legitimately uses patterns resembling attacks (e.g., HTML in form fields) | Add rule exclusions for specific labels within the managed rule group |

---

## Next Steps / Advanced Topics

- **AWS Shield Advanced** — enhanced DDoS protection with 24/7 DRT (DDoS Response Team) support, layered with WAF
- **AWS Firewall Manager** — centrally manage WAF rules across many accounts/resources in an AWS Organization
- **Custom response bodies** — return a friendly error page instead of the default 403 for blocked requests
- **CAPTCHA and Challenge actions** — interactive verification for suspected bot traffic instead of outright blocking
- **Infrastructure as Code** — manage Web ACLs, rules, and IP sets via Terraform or AWS CloudFormation
