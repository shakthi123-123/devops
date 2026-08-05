# Setting Up CloudTrail & X-Ray in AWS — Complete Step-by-Step Guide

AWS CloudTrail records every API call made in your account for auditing and security investigation. AWS X-Ray traces requests as they travel through distributed applications, pinpointing latency and errors across services. Together they cover **who did what** (CloudTrail) and **where time is spent/what broke** (X-Ray) — two pillars of DevOps observability.

---

## Architecture Overview

```
   Every API call (console, CLI, SDK)
                │
           CloudTrail
                │
      ┌─────────┴─────────┐
      │                   │
  S3 (log archive)   CloudWatch Logs (alerting)


   Request → API Gateway → Lambda → DynamoDB
                │            │         │
                └──────┬─────┴─────────┘
                    X-Ray traces
                (Service Map + timing)
```

---

## Prerequisites

- Active AWS account
- IAM user/role with `AWSCloudTrail_FullAccess` and `AWSXRayFullAccess`

---

## Part A: CloudTrail

### Step A1: Sign In and Open CloudTrail

1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in with IAM credentials
3. Search for `CloudTrail` and select it

> A basic **Event history** (last 90 days, management events) is enabled automatically in every account at no cost — creating a **Trail** (Step A2) extends this with permanent storage, data events, and alerting.

### Step A2: Create a Trail

1. Left sidebar → **Trails** → **Create trail**
2. Configure:
   - Trail name: `org-management-trail`
   - **Enable for all accounts in my organization**: check if using AWS Organizations and this is the management account
   - Storage location: **Create new S3 bucket** (or use existing) — e.g., `cloudtrail-logs-123456789012`
   - **Log file SSE-KMS encryption**: enable, select/create a KMS key
   - **Log file validation**: enable (detects tampering via digest files)
3. Click **Next**

### Step A3: Choose Event Types

1. **Management events**: check **Read** and **Write** — captures control-plane operations (creating/deleting resources, IAM changes)
2. **Data events** (optional, higher cost/volume): capture object-level activity, e.g.:
   - S3: `GetObject`, `PutObject` on specific buckets
   - Lambda: `Invoke` calls
   - DynamoDB: item-level `GetItem`/`PutItem`
3. **Insights events** (optional): CloudTrail Insights automatically detects unusual API call volume/error rate patterns
4. Click **Next** → review → **Create trail**

### Step A4: Enable CloudWatch Logs Integration (For Alerting)

1. Select the trail → **Edit**
2. **CloudWatch Logs**: enable, select/create a log group (e.g., `CloudTrail/org-management-trail`)
3. IAM role: auto-create one with permission to deliver logs
4. Click **Save**
5. Now you can create **CloudWatch Alarms** or **Metric Filters** on specific API activity, e.g., alert whenever `DeleteBucket`, `AuthorizationFailure`, or root account login occurs

### Step A5: Create a Metric Filter/Alarm for Security-Critical Events

1. **CloudWatch** → **Log groups** → select `CloudTrail/org-management-trail` → **Metric filters** → **Create metric filter**
2. Filter pattern (example — detect root account usage):
   ```
   { $.userIdentity.type = "Root" && $.eventType != "AwsServiceEvent" }
   ```
3. Metric name: `RootAccountUsage`
4. Create a CloudWatch alarm on this metric ≥ 1 → notify via SNS
5. Repeat for other high-value patterns: `ConsoleLogin` failures, `DeleteTrail`, `StopLogging`, IAM policy changes

### Step A6: Query and Investigate Events

1. **Event history** tab — filter by event name, resource, user, or time range without needing Athena
2. For deeper analysis at scale, set up **CloudTrail Lake**:
   - Left sidebar → **Lake** → **Create event data store**
   - Query with SQL directly in the console — no need to set up Athena/S3 manually
   ```sql
   SELECT eventName, eventTime, userIdentity.arn
   FROM event_data_store
   WHERE eventName = 'DeleteBucket'
   ORDER BY eventTime DESC
   ```

### Step A7: Verify Log Integrity

1. Select the trail → **Log file validation** should show **Enabled**
2. To manually validate a range of log files:
   ```bash
   aws cloudtrail validate-logs \
     --trail-arn arn:aws:cloudtrail:ap-south-1:123456789012:trail/org-management-trail \
     --start-time 2026-07-01T00:00:00Z
   ```

---

## Part B: X-Ray

### Step B1: Open X-Ray

1. Search for `X-Ray` and select it (or find it under **CloudWatch** → **Application Signals / X-Ray traces** in newer console layouts)

### Step B2: Enable X-Ray on Lambda

1. **Lambda Console** → select function → **Configuration** tab → **Monitoring and operations tools** → **Edit**
2. Enable **Active tracing**
3. Click **Save**
4. Attach the `AWSXRayDaemonWriteAccess` policy to the function's execution role (often bundled automatically when enabling via console)

### Step B3: Instrument Application Code

**Python (Lambda) example:**
```python
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.core import patch_all

patch_all()  # auto-instruments boto3, requests, etc.

def lambda_handler(event, context):
    subsegment = xray_recorder.begin_subsegment("process-order")
    try:
        # business logic
        result = process_order(event)
    finally:
        xray_recorder.end_subsegment()
    return result
```

**Node.js example:**
```javascript
const AWSXRay = require('aws-xray-sdk-core');
const AWS = AWSXRay.captureAWS(require('aws-sdk'));

exports.handler = async (event) => {
  const segment = AWSXRay.getSegment();
  const subsegment = segment.addNewSubsegment('process-order');
  try {
    // business logic
  } finally {
    subsegment.close();
  }
};
```

### Step B4: Enable X-Ray on API Gateway

1. **API Gateway Console** → select API → **Stages** → select stage → **Logs/Tracing** tab → **Edit**
2. Enable **X-Ray Tracing**
3. Click **Save**

### Step B5: Enable X-Ray on ECS/Fargate

1. Add the **X-Ray daemon** as a sidecar container in your task definition:
   ```json
   {
     "name": "xray-daemon",
     "image": "amazon/aws-xray-daemon",
     "cpu": 32,
     "memoryReservation": 256,
     "portMappings": [{"containerPort": 2000, "protocol": "udp"}]
   }
   ```
2. Ensure the task role has `AWSXRayDaemonWriteAccess`
3. Application code sends trace data to `localhost:2000` (the daemon sidecar)

### Step B6: View the Service Map

1. **X-Ray Console** → **Service map**
2. Visualizes every service your traced requests pass through, color-coded by health:
   - Green: healthy response times/error rates
   - Yellow/Red: elevated latency or error rate
3. Click any node to drill into its traces

### Step B7: Analyze Individual Traces

1. **X-Ray Console** → **Traces**
2. Filter by time range, response time, or annotation
3. Click a trace ID to see the full **timeline** — each segment/subsegment shows exactly how long each downstream call took
4. Identify bottlenecks: e.g., a DynamoDB call taking 800ms out of a 900ms total Lambda duration

### Step B8: Add Custom Annotations and Metadata

```python
subsegment.put_annotation("orderId", event["orderId"])  # indexed, searchable
subsegment.put_metadata("orderDetails", event)            # not indexed, for context only
```

Annotations let you filter traces in the console, e.g., find all traces for a specific `orderId` during a customer support investigation.

### Step B9: Set Up Sampling Rules (Control Cost/Volume)

1. Left sidebar → **Sampling rules** → **Create rule**
2. Configure:
   - Rule name: `orders-app-sampling`
   - Reservoir size: `1` request/second traced at 100%, beyond that
   - Rate: `5%` of additional requests
3. Click **Create**
4. Reduces X-Ray costs on high-traffic services while still capturing a representative sample plus every distinct new pattern

---

## Verification Checklist

- [ ] CloudTrail trail created covering all regions, with log file validation and encryption enabled
- [ ] CloudTrail logs delivered to both S3 (long-term) and CloudWatch Logs (alerting)
- [ ] Metric filters/alarms configured for security-critical events (root login, IAM changes, trail tampering)
- [ ] X-Ray active tracing enabled on Lambda/API Gateway/ECS
- [ ] Application code instrumented with the X-Ray SDK, not just infrastructure-level tracing
- [ ] Service map reviewed to confirm all expected services appear and are connected correctly
- [ ] Sampling rules configured to control cost on high-volume services
- [ ] Custom annotations added for key business identifiers (order ID, user ID) to aid debugging

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| CloudTrail Event history missing expected events | Data events not enabled (only management events captured by default) | Enable data events for the specific resource types you need to audit |
| Metric filter alarm never fires | Filter pattern doesn't match actual log JSON structure | Test the pattern against a real sample log entry in the console |
| X-Ray shows no traces | Active tracing not enabled, or SDK not instrumented in code | Verify both infrastructure-level tracing AND application code `patch_all()`/SDK wrapping |
| Service map shows a gap between two services | One service isn't propagating the trace header (`X-Amzn-Trace-Id`) downstream | Ensure the HTTP client/SDK used for that call is X-Ray-instrumented |
| Sampling causes missing traces during an incident | Sampling rate too low for the traffic pattern | Temporarily increase the sampling rate/reservoir during active investigations |

---

## Next Steps / Advanced Topics

- **CloudTrail Lake + Athena** — long-term SQL-based forensic analysis across years of API history
- **GuardDuty** — layer machine-learning threat detection on top of CloudTrail/VPC Flow Logs data
- **AWS Config** — complements CloudTrail by tracking resource *configuration state* over time, not just API calls
- **X-Ray + CloudWatch ServiceLens** — unified view combining traces, logs, and metrics in one dashboard
- **Infrastructure as Code** — manage trails, event data stores, and sampling rules via Terraform or CloudFormation
