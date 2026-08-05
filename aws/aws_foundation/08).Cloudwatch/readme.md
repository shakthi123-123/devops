# Setting Up CloudWatch in AWS — Complete Step-by-Step Guide

Amazon CloudWatch collects metrics, logs, and events from your AWS resources so you can monitor performance, set alarms, and automate responses. This guide covers dashboards, custom metrics, log groups, alarms, and event-driven automation.

---

## Architecture Overview

```
        AWS Resources (EC2, Lambda, RDS, etc.)
                        │
              ┌─────────┴──────────┐
              │                    │
         Metrics                Logs
              │                    │
        ┌─────▼─────┐      ┌───────▼────────┐
        │ CloudWatch │      │ CloudWatch Logs │
        │  Metrics   │      │  (Log Groups)   │
        └─────┬─────┘      └───────┬────────┘
              │                    │
        ┌─────▼─────┐      ┌───────▼────────┐
        │   Alarms   │      │  Log Insights /  │
        │            │      │  Metric Filters  │
        └─────┬─────┘      └────────────────┘
              │
        ┌─────▼─────┐
        │ SNS Topic  │──► Email / SMS / Lambda
        └───────────┘

        CloudWatch Dashboards ── visualize everything above
        EventBridge Rules ── react to state changes / schedules
```

---

## Prerequisites

- Active AWS account
- IAM user/role with `CloudWatchFullAccess` (or scoped equivalent) permissions
- At least one running resource to monitor (EC2 instance, Lambda function, RDS database, etc. — see companion guides)

---

## Step 1: Sign In and Open CloudWatch

1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in with IAM credentials
3. Select your target **region** (e.g., `Asia Pacific (Mumbai) ap-south-1`) — CloudWatch is region-scoped; each region has its own metrics/logs/alarms
4. In the search bar, type `CloudWatch` and select **CloudWatch**

---

## Step 2: Explore Default Metrics

Most AWS services automatically publish metrics at no extra cost (standard resolution, 5-minute granularity).

1. Left sidebar → **Metrics** → **All metrics**
2. Browse by namespace, e.g.:
   - `AWS/EC2` — CPUUtilization, NetworkIn/Out, DiskReadOps
   - `AWS/Lambda` — Invocations, Errors, Duration, Throttles
   - `AWS/RDS` — CPUUtilization, FreeStorageSpace, DatabaseConnections
   - `AWS/ApplicationELB` — RequestCount, TargetResponseTime, HTTPCode_Target_5XX_Count
3. Select a metric (e.g., EC2 → Per-Instance Metrics → `CPUUtilization`) to view its graph
4. Adjust the time range and statistic (Average, Maximum, Sum, p99, etc.) at the top of the graph

---

## Step 3: Create a Dashboard

Dashboards give you a single view combining multiple metrics/logs across services.

1. Left sidebar → **Dashboards** → **Create dashboard**
2. Name: `production-overview`
3. Click **Create dashboard**
4. **Add widget** → choose a widget type:

| Widget Type | Use Case |
|---|---|
| Line / Number / Stacked area | Metric trends over time |
| Gauge | Single value against a threshold (e.g., % storage used) |
| Log table | Query results from CloudWatch Logs |
| Alarm status | Show current state of alarms |
| Text | Add markdown notes/headers to the dashboard |

5. For a **Line widget**:
   - Select data source: **Metrics**
   - Browse/search and check the metrics to include (e.g., `CPUUtilization` for your EC2 instance, `Errors` for your Lambda)
   - Click **Create widget**
6. Repeat to add widgets for each key resource
7. Drag/resize widgets to organize the layout
8. Click **Save dashboard**

> **Tip:** Build one dashboard per environment (`production-overview`, `staging-overview`) rather than one giant dashboard mixing everything.

---

## Step 4: Create a CloudWatch Log Group

Log groups store logs from applications, Lambda functions, EC2 instances (via the CloudWatch Agent), and more.

1. Left sidebar → **Logs** → **Log groups** → **Create log group**
2. Configure:
   - **Log group name**: `/app/orders-service`
   - **Retention setting**: 30 days (default is "Never expire" — set this explicitly to control cost)
   - **KMS encryption**: optional, select a KMS key for logs containing sensitive data
3. Click **Create**

> Lambda automatically creates a log group named `/aws/lambda/<function-name>` on first invocation — you don't need to create this manually.

---

## Step 5: Install the CloudWatch Agent on EC2 (For OS-Level Metrics/Logs)

Default EC2 metrics don't include memory or disk usage from inside the OS — the CloudWatch Agent adds these.

1. Attach an IAM role with the `CloudWatchAgentServerPolicy` to your EC2 instance:
   - EC2 Console → select instance → **Actions** → **Security** → **Modify IAM role** → attach role
2. SSH into the instance and install the agent (Amazon Linux):
   ```bash
   sudo yum install -y amazon-cloudwatch-agent
   ```
3. Create a configuration file interactively:
   ```bash
   sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard
   ```
   - Follow prompts to select metrics (CPU, memory, disk) and log files to collect (e.g., `/var/log/messages`, application logs)
   - This generates `/opt/aws/amazon-cloudwatch-agent/bin/config.json`
4. Start the agent with the generated config:
   ```bash
   sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
     -a fetch-config -m ec2 -s \
     -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json
   ```
5. Verify in the console: **Metrics** → namespace `CWAgent` should now show memory/disk metrics

---

## Step 6: Create Metric Filters (Extract Metrics from Log Data)

Turn log patterns into queryable metrics — e.g., count how often "ERROR" appears in application logs.

1. Select your log group (`/app/orders-service`) → **Metric filters** tab → **Create metric filter**
2. **Filter pattern**: `ERROR`
3. Click **Test pattern** against sample log events to confirm matches
4. Click **Next**
5. Configure the metric:
   - Filter name: `OrdersServiceErrorCount`
   - Metric namespace: `CustomApp/Orders`
   - Metric name: `ErrorCount`
   - Metric value: `1` (count occurrences)
6. Click **Next** → review → **Create metric filter**
7. This metric now appears under **Metrics** → `CustomApp/Orders` and can be used in alarms/dashboards

---

## Step 7: Create a CloudWatch Alarm

1. Left sidebar → **Alarms** → **All alarms** → **Create alarm**
2. **Select metric**:
   - Browse to the metric (e.g., `AWS/EC2` → `CPUUtilization` for your instance, or your custom `ErrorCount` metric from Step 6)
   - Click **Select metric**
3. **Specify metric and conditions**:
   - Statistic: `Average`
   - Period: `5 minutes`
   - Threshold type: **Static**
   - Condition: `Greater than 80` (for CPU) or `Greater than 5` (for error count)
   - Additional configuration: datapoints to alarm, e.g., `3 out of 3` (avoids false alarms from single spikes)
4. Click **Next**
5. **Configure actions**:
   - Alarm state trigger: **In alarm**
   - Select an SNS topic, or create a new one:
     - **Create new topic** → name: `prod-alerts` → email endpoint: `ops-team@company.com`
     - Confirm the subscription via the email sent to that address
   - (Optional) Add additional actions: **Auto Scaling action**, **EC2 action** (reboot/stop/terminate), **Lambda action**
6. Click **Next**
7. Name: `high-cpu-orders-server`
8. Description: `Triggers when EC2 CPU exceeds 80% for 15 minutes`
9. Click **Next** → review → **Create alarm**

### Common Alarm Examples

| Resource | Metric | Threshold | Purpose |
|---|---|---|---|
| EC2 | CPUUtilization | > 80% for 15 min | Detect overload |
| Lambda | Errors | > 5 in 5 min | Catch failing invocations |
| Lambda | Throttles | > 0 | Detect concurrency limits hit |
| RDS | FreeStorageSpace | < 2 GB | Prevent disk-full outages |
| RDS | DatabaseConnections | > 80% of max | Prevent connection exhaustion |
| ALB | HTTPCode_Target_5XX_Count | > 10 in 5 min | Detect backend failures |
| Custom | ErrorCount (from logs) | > 5 in 5 min | Application-level error spikes |

---

## Step 8: Use CloudWatch Logs Insights (Query Logs)

1. Left sidebar → **Logs** → **Logs Insights**
2. Select one or more log groups (e.g., `/aws/lambda/process-order-events`)
3. Write a query, e.g., find the slowest requests:
   ```
   fields @timestamp, @message, @duration
   | filter @type = "REPORT"
   | sort @duration desc
   | limit 20
   ```
4. Or count errors by hour:
   ```
   fields @timestamp, @message
   | filter @message like /ERROR/
   | stats count() by bin(1h)
   ```
5. Click **Run query**
6. Click **Add to dashboard** to pin useful queries for ongoing visibility

---

## Step 9: Set Up Composite Alarms (Optional, Reduce Alert Noise)

Combine multiple alarms into one higher-level alarm to avoid alert fatigue.

1. **Alarms** → **All alarms** → **Create alarm** → **Create composite alarm**
2. Build a rule combining existing alarms, e.g.:
   ```
   ALARM("high-cpu-orders-server") AND ALARM("high-memory-orders-server")
   ```
3. Configure actions (SNS notification) same as Step 7
4. Click **Create composite alarm**

> Useful for reducing noise — e.g., only page on-call if **both** CPU and memory are high simultaneously, rather than firing two separate pages.

---

## Step 10: Automate Responses with EventBridge (Optional)

React automatically to state changes instead of just notifying a human.

1. Search for **EventBridge** in the console → **Rules** → **Create rule**
2. Name: `restart-on-high-cpu`
3. Event source: **AWS services**
4. Event pattern: match CloudWatch Alarm state change to `ALARM` for a specific alarm name
5. Target: select a **Lambda function**, **SSM Automation document**, or **EC2 Actions** (e.g., reboot instance)
6. Click **Create rule**

Example use case: automatically restart an application service via SSM Run Command when a custom "app unhealthy" alarm triggers.

---

## Step 11: Set Log Retention and Cost Controls

CloudWatch Logs stored indefinitely can become a significant cost driver.

1. Review all log groups: **Logs** → **Log groups**
2. For each group, click the **Retention** column value → set an explicit period (e.g., 30, 90, or 365 days) instead of "Never expire"
3. For high-volume debug logs, consider:
   - Shorter retention (7–14 days)
   - Exporting older logs to **S3** for cheap long-term archival: select log group → **Actions** → **Export data to Amazon S3**
4. Review **CloudWatch Logs Insights** query costs — charged per GB scanned; narrow time ranges and log groups when querying

---

## Step 12: Verification Checklist

- [ ] Dashboard created covering key metrics for critical resources
- [ ] CloudWatch Agent installed on EC2 instances needing memory/disk metrics
- [ ] Log groups created with explicit (non-infinite) retention periods
- [ ] Metric filters configured to surface important log patterns (errors, warnings)
- [ ] Alarms created for critical thresholds (CPU, storage, errors, throttles)
- [ ] SNS topic confirmed and subscribed (check for the confirmation email)
- [ ] Composite alarms used where appropriate to reduce alert noise
- [ ] Logs Insights queries saved/pinned for common troubleshooting scenarios
- [ ] EventBridge automation configured for self-healing scenarios (if applicable)
- [ ] Old/unused log groups and alarms cleaned up periodically

---

## Cleanup (To Avoid Ongoing Charges)

1. Delete dashboards no longer needed: **Dashboards** → select → **Delete**
2. Delete alarms: **Alarms** → select → **Actions** → **Delete**
3. Delete log groups: **Log groups** → select → **Actions** → **Delete log group(s)**
4. Delete the SNS topic if unused: **SNS Console** → **Topics** → select → **Delete**
5. Remove EventBridge rules: **EventBridge** → **Rules** → select → **Delete**
6. Uninstall the CloudWatch Agent from EC2 instances being decommissioned

> CloudWatch has a free tier (basic metrics, some alarms, limited log ingestion), but custom metrics, high-resolution metrics, extended log retention, and Logs Insights queries all incur charges — review usage periodically via **Billing Dashboard**.

---

## Quick Reference Summary

| Component | Purpose |
|---|---|
| Metric | Time-series data point published by a resource |
| Namespace | Grouping for related metrics (e.g., `AWS/EC2`) |
| Dashboard | Customizable visual view combining metrics/logs/alarms |
| Log Group | Container for log streams from a resource |
| Metric Filter | Converts log patterns into queryable metrics |
| Alarm | Triggers an action when a metric crosses a threshold |
| Composite Alarm | Combines multiple alarms into one higher-level condition |
| Logs Insights | Query language for searching/analyzing log data |
| CloudWatch Agent | Collects OS-level metrics/logs from EC2/on-prem servers |
| EventBridge Rule | Automates responses to state changes or on a schedule |

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| No memory/disk metrics for EC2 | CloudWatch Agent not installed/running | Install agent (Step 5); verify IAM role has `CloudWatchAgentServerPolicy` |
| Alarm stuck in `INSUFFICIENT_DATA` | No metric data published yet, or wrong dimension selected | Verify the resource is actively publishing the metric; check dimension (e.g., correct InstanceId) |
| Not receiving alarm emails | SNS subscription not confirmed | Check inbox (including spam) for the confirmation email and click **Confirm subscription** |
| Logs Insights query returns nothing | Wrong log group selected, or time range too narrow | Verify correct log group(s) and widen the time range |
| Unexpectedly high CloudWatch bill | Log retention set to "Never expire", high-resolution custom metrics, frequent Insights queries | Set explicit retention; review custom metric usage; narrow query scope |

---

## Next Steps / Advanced Topics

- **CloudWatch Synthetics** — canary scripts that proactively test endpoints/APIs on a schedule
- **CloudWatch RUM (Real User Monitoring)** — capture performance data from actual end-user browsers
- **Contributor Insights** — identify top talkers/outliers in high-cardinality log data
- **Anomaly Detection** — machine-learning-based dynamic thresholds instead of static alarm values
- **Infrastructure as Code** — manage dashboards, alarms, and log groups via Terraform or AWS CloudFormation
