[aws-route53-creation-guide.md](https://github.com/user-attachments/files/30575573/aws-route53-creation-guide.md)
# Setting Up Route 53 in AWS — Complete Step-by-Step Guide

Amazon Route 53 is AWS's scalable DNS and domain registration service. This guide covers registering/migrating a domain, creating hosted zones, routing records to AWS resources, and setting up health checks with failover.

---

## Architecture Overview

```
                        Internet Users
                              │
                        DNS Query: myapp.com
                              │
                    ┌──────────────────┐
                    │   Route 53         │
                    │   Hosted Zone       │
                    │   myapp.com         │
                    │                    │
                    │  A (alias) → ALB    │
                    │  CNAME → CloudFront │
                    │  MX → Email          │
                    │  Health Checks       │
                    └──────────────────┘
                          │        │
                    ALB/CloudFront  Failover Region
```

---

## Prerequisites

- Active AWS account
- IAM user/role with `AmazonRoute53FullAccess` (or scoped equivalent) permissions
- A domain name you own (registered with Route 53 or another registrar), or intent to register one

---

## Step 1: Sign In and Open Route 53

1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in with IAM credentials
3. In the search bar, type `Route 53` and select **Route 53**

> Route 53 is a **global** service — it is not tied to a specific region.

---

## Step 2: Register a Domain (Optional — Skip If You Already Own One)

1. Left sidebar → **Domains** → **Registered domains** → **Register domain**
2. Search for your desired domain, e.g., `myapp.com`
3. Select from available options and add to cart
4. Fill in **Contact details** (registrant, admin, tech) — enable **Privacy protection** to hide these from public WHOIS lookups
5. Review pricing (varies by TLD, typically billed annually)
6. Enable **Auto-renew** (recommended, avoid losing the domain)
7. Complete purchase — registration can take a few minutes to a few hours, and email verification may be required

---

## Step 3: Create a Hosted Zone (For a Domain Registered Elsewhere)

If your domain is registered with another provider (GoDaddy, Namecheap, etc.) but you want Route 53 to manage DNS:

1. Left sidebar → **Hosted zones** → **Create hosted zone**
2. Configure:
   - Domain name: `myapp.com`
   - Type: **Public hosted zone**
3. Click **Create hosted zone**
4. Route 53 automatically creates **NS** (name server) and **SOA** records
5. Copy the 4 name server values shown, e.g.:
   ```
   ns-123.awsdns-45.com
   ns-456.awsdns-67.net
   ns-789.awsdns-01.org
   ns-012.awsdns-23.co.uk
   ```
6. Log in to your **external registrar's** dashboard and update the domain's **nameservers** to these 4 values
7. DNS propagation can take up to 48 hours, though often much faster

> If the domain was registered **through Route 53** (Step 2), the hosted zone and nameserver linkage are created automatically — skip this manual step.

---

## Step 4: Create an A Record Pointing to an EC2/ALB Resource

1. Select your hosted zone (`myapp.com`) → **Create record**
2. Configure:

| Field | Value | Notes |
|---|---|---|
| Record name | (leave blank for root domain, or enter `www`) | |
| Record type | `A – IPv4 address` | |
| Alias | **Yes** (toggle on) | Required to point to AWS resources like ALB/CloudFront |
| Route traffic to | **Alias to Application and Classic Load Balancer** | |
| Region | select your ALB's region | |
| Load balancer | select `orders-alb` (or your ALB) | |

3. **Routing policy**: **Simple routing** (default — see Step 7 for advanced policies)
4. Click **Create records**

> **Alias records** are Route 53-specific and preferred over CNAME for AWS resources — they work at the zone apex (root domain) and have no additional query charge.

---

## Step 5: Create a CNAME Record (For Subdomains Pointing to Non-AWS or Non-Alias Targets)

1. **Create record**
2. Configure:
   - Record name: `blog`
   - Record type: `CNAME`
   - Value: `myblog.wordpress.com` (or any external hostname)
   - TTL: `300` seconds
3. Click **Create records**

> CNAME cannot be used at the zone apex (`myapp.com` itself) — use an Alias A record instead for the root domain.

---

## Step 6: Create MX Records (For Email)

1. **Create record**
2. Configure:
   - Record name: (leave blank for root domain)
   - Record type: `MX`
   - Value (priority + mail server), e.g.:
     ```
     10 mail.myapp.com
     ```
     Or for Google Workspace:
     ```
     1 ASPMX.L.GOOGLE.COM
     5 ALT1.ASPMX.L.GOOGLE.COM
     5 ALT2.ASPMX.L.GOOGLE.COM
     ```
   - TTL: `3600`
3. Click **Create records**
4. Add supporting **TXT** records for SPF/DKIM/DMARC as required by your email provider

---

## Step 7: Configure Advanced Routing Policies (Optional)

Route 53 supports routing policies beyond simple A/CNAME mapping:

| Policy | Use Case |
|---|---|
| **Simple** | One record, one resource — default |
| **Weighted** | Split traffic by percentage across multiple resources (e.g., canary releases, A/B testing) |
| **Latency-based** | Route users to the AWS region with lowest latency for them |
| **Failover** | Active-passive — route to primary, switch to secondary if primary fails health checks |
| **Geolocation** | Route based on the user's geographic location |
| **Geoproximity** | Route based on geographic location with bias adjustment (requires Route 53 Traffic Flow) |
| **Multivalue answer** | Return multiple healthy IPs, client picks — simple DNS-level load distribution |

### Example: Weighted Routing for Canary Deployment

1. **Create record** → Record name: (root or subdomain)
2. Routing policy: **Weighted**
3. Create two records with the same name:
   - Record 1: Value → old version ALB, Weight: `90`
   - Record 2: Value → new version ALB, Weight: `10`
4. Assign each a unique **Record ID** (e.g., `v1-90pct`, `v2-10pct`)
5. Click **Create records** for each

---

## Step 8: Set Up Health Checks

Health checks monitor endpoint availability and can drive failover routing.

1. Left sidebar → **Health checks** → **Create health check**
2. Configure:
   - Name: `orders-app-health`
   - What to monitor: **Endpoint**
   - Specify endpoint by: **Domain name** or **IP address**
   - Protocol: `HTTPS`
   - Domain name: `myapp.com`
   - Path: `/health`
   - Request interval: `30 seconds` (standard) or `10 seconds` (fast, costs more)
   - Failure threshold: `3` consecutive failures
3. **Advanced configuration**:
   - String matching (optional): confirm response body contains `"status":"ok"`
   - Latency graphs: enable to track response time from multiple AWS regions
4. Click **Create health check**
5. (Optional) **Configure SNS notifications**:
   - Create/select an SNS topic to alert when the health check fails
   - **Health checks** → select → **Notification** tab → configure

---

## Step 9: Configure Failover Routing (High Availability)

1. **Create record** in your hosted zone
2. Routing policy: **Failover**
3. Create the **Primary** record:
   - Failover record type: **Primary**
   - Value: primary region's ALB/endpoint
   - Associate health check: `orders-app-health` (from Step 8)
4. Create the **Secondary** record:
   - Failover record type: **Secondary**
   - Value: DR region's ALB/endpoint or a static "we'll be back soon" S3 static site
   - Health check optional on secondary
5. Click **Create records** for both
6. Route 53 automatically routes to the secondary if the primary's health check fails

---

## Step 10: Validate an ACM Certificate via DNS (Common Cross-Service Task)

When requesting an SSL/TLS certificate in AWS Certificate Manager for use with CloudFront/ALB/API Gateway:

1. **ACM Console** → request a public certificate for `myapp.com` and `*.myapp.com`
2. Choose **DNS validation**
3. ACM provides a CNAME name/value pair for validation
4. Back in Route 53 → select hosted zone → ACM often shows a **Create record in Route 53** button directly on the certificate page — click it to auto-create the validation CNAME
5. Wait for certificate status to change to **Issued** (usually a few minutes)

---

## Step 11: Verify DNS Propagation

1. Use `dig` or `nslookup` locally:
   ```bash
   dig myapp.com
   dig www.myapp.com CNAME
   ```
2. Or use Route 53's built-in **Test Record** feature: select hosted zone → select a record → **Test record**
3. Confirm the returned values match your expected target (ALB DNS name, IP, etc.)
4. External propagation checkers (e.g., whatsmydns.net) can confirm global resolution, though these are third-party tools outside the AWS console

---

## Step 12: Verification Checklist

- [ ] Domain registered or nameservers correctly pointed to the Route 53 hosted zone
- [ ] Root domain uses an **Alias** A record (not CNAME) when pointing to AWS resources
- [ ] MX/TXT records configured correctly if email is hosted elsewhere
- [ ] Health checks created for critical endpoints
- [ ] Failover or weighted routing configured for high-availability/canary needs
- [ ] ACM certificate validated via DNS and shows **Issued** status
- [ ] DNS resolution tested and confirmed via `dig`/`nslookup`
- [ ] TTLs set appropriately (lower before planned cutovers, higher for stability afterward)

---

## Cleanup (To Avoid Ongoing Charges)

1. Delete unused records: select hosted zone → select record(s) → **Delete**
2. Delete health checks no longer in use: **Health checks** → select → **Delete**
3. Delete the hosted zone if the domain is being decommissioned: **Hosted zones** → select → **Delete zone** (must remove all non-default records first)
4. Domain registration fees are annual and separate from hosted zone charges — cancel auto-renew before expiry if not keeping the domain

> Hosted zones incur a small monthly charge per zone plus per-query charges; health checks also bill per check — clean up unused ones periodically.

---

## Quick Reference Summary

| Component | Purpose |
|---|---|
| Hosted Zone | Container for all DNS records for a domain |
| Record | Maps a name to a value (A, CNAME, MX, TXT, etc.) |
| Alias Record | Route 53-specific record pointing to AWS resources, works at zone apex |
| Routing Policy | Determines how Route 53 responds when multiple records exist |
| Health Check | Monitors endpoint availability, can drive failover |
| TTL | How long resolvers cache a record's answer |

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| Domain not resolving after setup | Nameservers not updated at registrar, or propagation delay | Verify NS records at registrar match hosted zone; wait up to 48 hours |
| `CNAME` record fails at root domain | CNAME not allowed at zone apex | Use an Alias A record instead |
| ACM certificate stuck in `Pending validation` | DNS validation CNAME not created or propagated | Confirm the validation record exists in the hosted zone; wait a few minutes |
| Failover not triggering | Health check misconfigured or still passing | Verify health check path/protocol matches the actual endpoint behavior |
| Old IP still resolving after change | High TTL cached by resolvers | Lower TTL in advance of planned changes; wait out the previous TTL |

---

## Next Steps / Advanced Topics

- **Route 53 Resolver** — DNS resolution between VPCs and on-premises networks (hybrid DNS)
- **Route 53 Traffic Flow** — visual policy editor for complex multi-condition routing
- **Private Hosted Zones** — internal DNS resolution scoped to one or more VPCs
- **DNSSEC** — cryptographic signing to prevent DNS spoofing
- **Infrastructure as Code** — manage hosted zones and records via Terraform or AWS CloudFormation
