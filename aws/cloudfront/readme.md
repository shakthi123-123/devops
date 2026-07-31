# Setting Up CloudFront in AWS — Complete Step-by-Step Guide

Amazon CloudFront is AWS's global content delivery network (CDN) — it caches content at edge locations worldwide for low-latency delivery, and also provides HTTPS termination, DDoS protection (via AWS Shield), and request routing for both static and dynamic content.

---

## Architecture Overview

```
                     Global Users
                          │
                 ┌─────────────────┐
                 │  CloudFront Edge  │
                 │  Locations (300+) │
                 └────────┬────────┘
                          │ (cache miss)
              ┌───────────┴────────────┐
              │                        │
        S3 Origin                  ALB / EC2 / API GW
     (static assets)              (dynamic content)
              │                        │
        Origin Access Control    Custom Origin
        (OAC) — private bucket    (public endpoint)
```

---

## Prerequisites

- Active AWS account
- IAM user/role with `CloudFrontFullAccess` (or scoped equivalent) permissions
- An origin to serve content from — an S3 bucket (see companion *AWS S3 Creation Guide*) and/or an ALB/API Gateway endpoint
- (Optional) A custom domain and ACM certificate — see companion *AWS Route 53 Creation Guide*, Step 10

---

## Step 1: Sign In and Open CloudFront

1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in with IAM credentials
3. In the search bar, type `CloudFront` and select **CloudFront**

> CloudFront is a **global** service, though its console is typically accessed from `us-east-1`. Any ACM certificate used with CloudFront must be requested in `us-east-1`, regardless of where your origin resources live.

---

## Step 2: Prepare Your Origin

### Option A: S3 Bucket (Static Content)

1. Ensure you have an S3 bucket with your content uploaded (e.g., `my-app-bucket-prod-2026`)
2. Keep **Block Public Access enabled** on the bucket — CloudFront will access it privately via Origin Access Control (configured in Step 4), so the bucket itself never needs to be public

### Option B: ALB / API Gateway / Custom HTTP Origin (Dynamic Content)

1. Ensure your ALB or API Gateway is deployed and reachable (see companion guides)
2. Note its DNS name/endpoint, e.g., `orders-alb-123456.ap-south-1.elb.amazonaws.com`

---

## Step 3: Create a CloudFront Distribution

1. Left sidebar → **Distributions** → **Create distribution**
2. **Origin**:
   - **Origin domain**: click the field — it auto-suggests your S3 buckets and other AWS resources; select `my-app-bucket-prod-2026.s3.ap-south-1.amazonaws.com`
   - **Origin path**: (optional) e.g., `/static` if content lives in a subfolder
   - **Name**: auto-fills, can customize
   - **Origin access**: see Step 4

---

## Step 4: Configure Origin Access Control (OAC) — For S3 Origins

OAC lets CloudFront access a **private** S3 bucket securely, without making the bucket public.

1. Under **Origin access**, select **Origin access control settings (recommended)**
2. Click **Create control setting**
3. Configure:
   - Name: `my-app-bucket-oac`
   - Signing behavior: **Sign requests (recommended)**
4. Click **Create**
5. After the distribution is created, CloudFront shows a **bucket policy** you must add to the S3 bucket — copy it
6. Go to **S3 Console** → your bucket → **Permissions** → **Bucket policy** → **Edit** → paste the provided policy → **Save changes**
   - This policy allows only this specific CloudFront distribution to read from the bucket

---

## Step 5: Configure Default Cache Behavior

1. **Viewer protocol policy**: **Redirect HTTP to HTTPS** (recommended default)
2. **Allowed HTTP methods**:
   - `GET, HEAD` — for static/read-only content
   - `GET, HEAD, OPTIONS, PUT, POST, PATCH, DELETE` — if proxying a dynamic API through CloudFront
3. **Cache policy**:
   - **CachingOptimized** (managed policy) — good default for static assets, ignores query strings/cookies
   - **CachingDisabled** — for dynamic content that shouldn't be cached
   - Or create a **custom cache policy** to control TTL and which headers/query strings/cookies affect the cache key
4. **Origin request policy** (if forwarding data to a dynamic origin):
   - `AllViewer` — forwards all headers/cookies/query strings to the origin (needed for APIs)
5. **Response headers policy** (optional): add security headers like `Strict-Transport-Security`, `X-Content-Type-Options`

---

## Step 6: Configure Distribution Settings

1. **Price class**:

| Price Class | Coverage | Cost |
|---|---|---|
| Use all edge locations | Global | Highest |
| Use North America, Europe, Asia | Most major regions | Medium |
| Use only North America and Europe | Limited | Lowest |

   Select based on where your users actually are.

2. **WAF (Web Application Firewall)**: enable if you want to attach AWS WAF rules for protection against common exploits (additional cost)
3. **Alternate domain name (CNAME)**: add `cdn.myapp.com` if using a custom domain (requires an ACM certificate in `us-east-1` — see Step 8)
4. **Custom SSL certificate**: select your ACM certificate once added
5. **Default root object**: `index.html` (for static website distributions)
6. **Standard logging** (optional): enable and select/create an S3 bucket to store access logs
7. Click **Create distribution**
8. Status shows `Deploying` → wait for `Enabled` (typically 5–15 minutes for global edge propagation)

---

## Step 7: Test the Distribution

1. Copy the auto-generated **Distribution domain name**, e.g.:
   ```
   d1234abcd5678.cloudfront.net
   ```
2. Test in browser or via curl:
   ```bash
   curl -I https://d1234abcd5678.cloudfront.net/index.html
   ```
3. Confirm response headers include `x-cache: Hit from cloudfront` (on repeated requests) or `Miss from cloudfront` (first request)
4. Confirm content matches what's in your S3 bucket/origin

---

## Step 8: Attach a Custom Domain (Optional)

1. **ACM Console** (must be in **us-east-1** region regardless of where your resources live) → **Request certificate**
2. Domain names: `cdn.myapp.com` (and/or `myapp.com`, `*.myapp.com`)
3. Validation method: **DNS validation**
4. Complete validation via Route 53 (see companion *AWS Route 53 Creation Guide*, Step 10)
5. Wait for status: **Issued**
6. Return to your CloudFront distribution → **Edit** → **Settings**:
   - Alternate domain name (CNAME): `cdn.myapp.com`
   - Custom SSL certificate: select the newly issued certificate
7. Click **Save changes**
8. In **Route 53**, create an **Alias A record**:
   - Record name: `cdn`
   - Route traffic to: **Alias to CloudFront distribution**
   - Select your distribution
9. Click **Create records**
10. Test: `curl -I https://cdn.myapp.com`

---

## Step 9: Add Additional Cache Behaviors (Path-Based Routing)

Route different URL paths to different origins or apply different caching rules — e.g., `/api/*` goes to a dynamic backend while everything else is cached static content.

1. Select the distribution → **Behaviors** tab → **Create behavior**
2. Configure:
   - Path pattern: `/api/*`
   - Origin: select or add your ALB/API Gateway origin
   - Cache policy: **CachingDisabled**
   - Origin request policy: `AllViewer`
   - Viewer protocol policy: **Redirect HTTP to HTTPS**
3. Click **Create behavior**
4. CloudFront evaluates behaviors in priority order (top of list = highest priority) — reorder as needed via **Behaviors** tab → **Edit priority**

---

## Step 10: Configure Origin Failover (High Availability)

1. Select the distribution → **Origins** tab → ensure at least two origins are configured (e.g., primary S3 bucket + backup S3 bucket in another region)
2. **Origin groups** tab → **Create origin group**
3. Select primary and secondary origins
4. Failover criteria: HTTP status codes (e.g., `403, 404, 500, 502, 503, 504`)
5. Click **Create origin group**
6. Update the relevant cache behavior to point to this **origin group** instead of a single origin

---

## Step 11: Invalidate the Cache (After Updating Content)

When you update files in S3 but CloudFront is still serving the old cached version:

1. Select the distribution → **Invalidations** tab → **Create invalidation**
2. Object paths: `/*` (invalidate everything) or specific paths like `/images/logo.png`
3. Click **Create invalidation**
4. Wait for status to change to **Completed** (usually under a minute)

> Invalidations have a monthly free allotment, then incur a small per-path charge — for frequent deploys, prefer **versioned file names** (e.g., `app.v2.js`) over invalidating `/*` every time.

---

## Step 12: Monitor with CloudWatch

1. Select the distribution → **Monitoring** tab (or **CloudWatch** → `CloudFront` namespace, always in `us-east-1`)
2. Review:
   - **Requests** — total traffic volume
   - **4xx/5xx error rate** — client/origin errors
   - **Cache hit rate** — percentage served from edge vs. origin (higher is better/cheaper)
   - **Total bytes downloaded/uploaded**
3. Set a CloudWatch alarm on `5xxErrorRate` exceeding a threshold to catch origin failures early

---

## Step 13: Verification Checklist

- [ ] Origin configured correctly (S3 with OAC, or ALB/API Gateway)
- [ ] S3 bucket policy updated to allow only this CloudFront distribution (if using OAC)
- [ ] Viewer protocol policy forces HTTPS
- [ ] Cache policy matches content type (long TTL for static assets, disabled/short for dynamic APIs)
- [ ] Custom domain configured with ACM certificate issued in `us-east-1`
- [ ] Route 53 alias record points to the distribution
- [ ] Path-based behaviors correctly prioritized if multiple origins are used
- [ ] Logging enabled for audit/troubleshooting
- [ ] Cache invalidation tested after a content update
- [ ] CloudWatch alarms configured for error rate monitoring

---

## Cleanup (To Avoid Ongoing Charges)

1. Disable the distribution first: select → **Disable** (required before deletion)
2. Wait for status to change to **Deployed** (disabled state fully propagated)
3. Delete the distribution: select → **Delete**
4. Remove the Route 53 alias record pointing to it
5. Remove the S3 bucket policy statement granting the OAC access (if bucket is reused elsewhere)
6. Delete the ACM certificate if unused by other resources
7. Delete the CloudFront access log S3 bucket/objects if no longer needed

> CloudFront has a perpetual free tier for data transfer and requests up to certain limits — usage beyond that, plus invalidations beyond the free allotment, incur charges.

---

## Quick Reference Summary

| Component | Purpose |
|---|---|
| Distribution | The CDN configuration tying origins, behaviors, and domains together |
| Origin | The backend CloudFront fetches content from (S3, ALB, custom HTTP) |
| Origin Access Control (OAC) | Lets CloudFront securely access a private S3 bucket |
| Cache Behavior | Path-based rules controlling caching and routing |
| Cache Policy | Defines TTL and what varies the cache key (headers/cookies/query strings) |
| Invalidation | Forces removal of cached content before natural TTL expiry |
| Origin Group | Primary/secondary origin pairing for automatic failover |

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| `403 Forbidden` from CloudFront (S3 origin) | OAC bucket policy missing/incorrect | Re-copy and apply the bucket policy CloudFront generates for the OAC |
| Old content still served after update | Cache TTL hasn't expired | Create an invalidation, or use versioned file names |
| Custom domain SSL error | Certificate not in `us-east-1`, or not attached to distribution | Re-request ACM certificate in `us-east-1`; attach in distribution settings |
| Dynamic API returns cached/stale responses | Cache policy applied to API path is caching when it shouldn't | Use `CachingDisabled` policy on API path patterns |
| High origin load despite CDN | Low cache hit rate — TTL too short, or cache key too broad (varies by every header/cookie) | Review cache policy; increase TTL for cacheable content, narrow cache key |

---

## Next Steps / Advanced Topics

- **Lambda@Edge / CloudFront Functions** — run lightweight code at edge locations for redirects, header manipulation, A/B testing
- **Signed URLs / Signed Cookies** — restrict access to private content (e.g., paid video content)
- **Field-Level Encryption** — encrypt specific sensitive fields end-to-end through the CDN
- **Real-time logs** — stream request logs to Kinesis for near-instant analytics
- **Infrastructure as Code** — manage distributions, behaviors, and origins via Terraform or AWS CloudFormation
