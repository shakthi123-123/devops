# Setting Up SNS and SQS in AWS — Complete Step-by-Step Guide

Amazon SNS (Simple Notification Service) and SQS (Simple Queue Service) are AWS's core messaging services — SNS for pub/sub fan-out notifications, SQS for durable, decoupled message queuing. This guide covers both individually and the common **SNS → SQS fan-out** pattern used to decouple microservices.

---

## Architecture Overview

```
                    Event Source
                  (app, S3, CloudWatch)
                          │
                    ┌─────▼─────┐
                    │  SNS Topic │
                    │ order-events│
                    └─────┬─────┘
              ┌───────────┼────────────┐
              │           │            │
        ┌─────▼────┐ ┌────▼─────┐ ┌───▼────┐
        │ SQS Queue │ │ SQS Queue │ │ Lambda  │
        │ (billing) │ │(shipping) │ │(email)  │
        └─────┬────┘ └────┬─────┘ └────────┘
              │           │
        Billing Service  Shipping Service
        (polls queue)    (polls queue)

        Failed messages ──► Dead-Letter Queue (DLQ)
```

---

## Prerequisites

- Active AWS account
- IAM user/role with `AmazonSNSFullAccess` and `AmazonSQSFullAccess` (or scoped equivalents)

### SNS vs. SQS — When to Use Which

| Service | Model | Use Case |
|---|---|---|
| **SNS** | Pub/Sub — pushes to multiple subscribers immediately | Fan-out notifications, alerts (email/SMS), triggering multiple downstream systems at once |
| **SQS** | Point-to-point — consumers pull messages at their own pace | Decoupling producers/consumers, buffering load spikes, ensuring durable processing with retries |
| **SNS + SQS together** | Fan-out | One event needs to reliably reach multiple independent consumers, each processing at their own pace |

---

## Part A: Setting Up SNS

### Step A1: Sign In and Select Region

1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in with IAM credentials
3. Select your target **region** (e.g., `Asia Pacific (Mumbai) ap-south-1`)

### Step A2: Create an SNS Topic

1. In the search bar, type `SNS` and select **Simple Notification Service**
2. Left sidebar → **Topics** → **Create topic**
3. **Type**:

| Type | Ordering | Throughput | Use Case |
|---|---|---|---|
| **Standard** | Best-effort ordering | Nearly unlimited | Most use cases |
| **FIFO** | Strict ordering, exactly-once | Up to 300 msg/sec (3,000 batched) | Order-sensitive workflows (e.g., financial transactions) |

   Select **Standard** for this guide

4. Configure:
   - Name: `order-events`
   - Display name: `OrderEvents` (used as SMS sender ID prefix)
5. **Encryption**: enable **Server-side encryption** using an AWS managed KMS key (recommended for sensitive data)
6. **Access policy**: leave default (topic owner only) — refine in Step A5 if cross-account access is needed
7. Click **Create topic**
8. Note the **Topic ARN**, e.g.:
   ```
   arn:aws:sns:ap-south-1:123456789012:order-events
   ```

### Step A3: Subscribe an Email Endpoint

1. Select the topic → **Create subscription**
2. Protocol: **Email**
3. Endpoint: `ops-team@company.com`
4. Click **Create subscription**
5. Check the inbox for a confirmation email from AWS → click **Confirm subscription**
6. Subscription status changes from `Pending confirmation` to `Confirmed`

### Step A4: Subscribe an SMS Endpoint (Optional)

1. **Create subscription** → Protocol: **SMS** → Endpoint: `+919876543210` (E.164 format)
2. Click **Create subscription** — no confirmation step required for SMS
3. Note: SMS has per-message costs and country-specific sending restrictions; check the **Text messaging (SMS)** preferences page for spending limits

### Step A5: Publish a Test Message

1. Select the topic → **Publish message**
2. Subject: `Test Notification`
3. Message body: `This is a test message from SNS.`
4. Click **Publish message**
5. Confirm delivery to subscribed email/SMS endpoints

### Step A6: Set an Access Policy for Cross-Service Publishing (e.g., from S3 or CloudWatch)

1. Select the topic → **Edit** → **Access policy**
2. Example — allow S3 to publish to this topic:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "AllowS3Publish",
         "Effect": "Allow",
         "Principal": {"Service": "s3.amazonaws.com"},
         "Action": "SNS:Publish",
         "Resource": "arn:aws:sns:ap-south-1:123456789012:order-events",
         "Condition": {
           "ArnLike": {"aws:SourceArn": "arn:aws:s3:::my-app-bucket-prod-2026"}
         }
       }
     ]
   }
   ```
3. Click **Save changes**

---

## Part B: Setting Up SQS

### Step B1: Create a Standard Queue

1. In the search bar, type `SQS` and select **Simple Queue Service**
2. Click **Create queue**
3. **Type**:
   - **Standard** (default) — nearly unlimited throughput, at-least-once delivery, best-effort ordering
   - **FIFO** — strict ordering and exactly-once processing, name must end in `.fifo`, lower throughput
4. Name: `billing-queue`
5. **Configuration**:

| Field | Value | Notes |
|---|---|---|
| Visibility timeout | `30 seconds` | How long a message is hidden after being received, before it's visible again for retry |
| Message retention period | `4 days` (default) | Up to 14 days max |
| Delivery delay | `0 seconds` | Delay before a new message becomes visible |
| Receive message wait time | `10 seconds` | Enables long polling — reduces empty responses and cost |
| Maximum message size | `256 KB` (default) | Use S3 + a reference for larger payloads |

6. **Encryption**: enable **SSE (Server-side encryption)** with an AWS managed KMS key
7. Click **Create queue**
8. Note the **Queue URL** and **ARN**, e.g.:
   ```
   https://sqs.ap-south-1.amazonaws.com/123456789012/billing-queue
   arn:aws:sqs:ap-south-1:123456789012:billing-queue
   ```

### Step B2: Create a Dead-Letter Queue (DLQ)

Messages that repeatedly fail processing are moved to a DLQ instead of being retried forever or silently lost.

1. First create a second queue for the DLQ: **Create queue** → Name: `billing-queue-dlq` → same type as the source (Standard/FIFO must match) → **Create queue**
2. Go back to the source queue (`billing-queue`) → **Edit**
3. Scroll to **Dead-letter queue** → **Enable**
4. Choose the DLQ: `billing-queue-dlq`
5. **Maximum receives**: `3` (message moves to DLQ after 3 failed processing attempts)
6. Click **Save**

### Step B3: Send and Receive Test Messages

1. Select the queue → **Send and receive messages**
2. Under **Send message**, enter a message body:
   ```json
   {"orderId": "ORD-1001", "amount": 149.99}
   ```
3. Click **Send message**
4. Under **Receive messages**, click **Poll for messages**
5. Confirm the message appears — click on it to view the body
6. Click **Delete** to remove it from the queue after processing (simulates what a consumer application does)

### Step B4: Set Up IAM Permissions for Producers/Consumers

1. **IAM Console** → **Policies** → **Create policy** → **JSON** tab
2. Example — allow an application to send and receive from the queue:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "sqs:SendMessage",
           "sqs:ReceiveMessage",
           "sqs:DeleteMessage",
           "sqs:GetQueueAttributes"
         ],
         "Resource": "arn:aws:sqs:ap-south-1:123456789012:billing-queue"
       }
     ]
   }
   ```
3. Attach to the relevant Lambda execution role or application IAM role

---

## Part C: SNS → SQS Fan-Out Pattern

Connect SNS to multiple SQS queues so a single published event reliably reaches multiple independent consumers.

### Step C1: Subscribe SQS Queues to the SNS Topic

1. Go to **SNS Console** → select `order-events` topic → **Create subscription**
2. Protocol: **Amazon SQS**
3. Endpoint: select the queue ARN, e.g., `arn:aws:sqs:ap-south-1:123456789012:billing-queue`
4. Click **Create subscription**
5. Repeat for additional queues (e.g., `shipping-queue`, `email-queue`) to fan out the same event to multiple consumers

### Step C2: Grant SNS Permission to Send to the Queue

Usually configured automatically when subscribing through the console, but verify:

1. Go to **SQS Console** → select `billing-queue` → **Access policy** tab → **Edit**
2. Confirm a statement exists allowing `sns.amazonaws.com` to send messages, scoped to the specific topic ARN via a `Condition`
3. If missing, add manually:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "AllowSNSPublish",
         "Effect": "Allow",
         "Principal": {"Service": "sns.amazonaws.com"},
         "Action": "sqs:SendMessage",
         "Resource": "arn:aws:sqs:ap-south-1:123456789012:billing-queue",
         "Condition": {
           "ArnEquals": {"aws:SourceArn": "arn:aws:sns:ap-south-1:123456789012:order-events"}
         }
       }
     ]
   }
   ```

### Step C3: Test the Fan-Out

1. Go to the SNS topic → **Publish message**
2. Message body:
   ```json
   {"orderId": "ORD-1002", "status": "CREATED"}
   ```
3. Click **Publish message**
4. Go to each subscribed SQS queue → **Send and receive messages** → **Poll for messages**
5. Confirm the same message appears in **all** subscribed queues independently

### Step C4: (Optional) Add Subscription Filter Policies

Route only relevant messages to each queue instead of sending everything to everyone.

1. Select the SNS subscription (e.g., the one linking to `billing-queue`) → **Edit**
2. **Subscription filter policy** → enable
3. Example — only deliver messages where `eventType` is `PAYMENT`:
   ```json
   {
     "eventType": ["PAYMENT"]
   }
   ```
4. Click **Save changes**
5. Now publish messages with a `MessageAttributes` field matching `eventType` — only matching subscriptions receive them

---

## Step D: Connect Lambda as an SQS Consumer

1. **Lambda Console** → select/create a function → **Add trigger**
2. Source: **SQS**
3. Select the queue (e.g., `billing-queue`)
4. Batch size: `10`
5. Batch window: `0` seconds (or add a few seconds to batch more messages per invocation)
6. Click **Add**
7. Lambda automatically polls the queue and invokes your function with a batch of messages — no manual polling code needed

---

## Step E: Monitor with CloudWatch

1. **SNS**: select topic → **Monitoring** tab — review `NumberOfMessagesPublished`, `NumberOfNotificationsFailed`
2. **SQS**: select queue → **Monitoring** tab — review:
   - `ApproximateNumberOfMessagesVisible` — queue backlog
   - `ApproximateAgeOfOldestMessage` — processing lag
   - `NumberOfMessagesSent` / `NumberOfMessagesDeleted`
3. Set alarms:
   - SQS: alarm if `ApproximateNumberOfMessagesVisible` stays high (consumers falling behind)
   - SQS: alarm if DLQ (`billing-queue-dlq`) receives any messages — indicates repeated processing failures needing investigation
   - SNS: alarm on `NumberOfNotificationsFailed` > 0

---

## Verification Checklist

- [ ] SNS topic created with appropriate type (Standard/FIFO) and encryption enabled
- [ ] Email/SMS subscriptions confirmed (check for confirmation email)
- [ ] SQS queue created with appropriate visibility timeout and retention period
- [ ] Dead-letter queue configured with a sensible max-receive threshold
- [ ] IAM policies scoped to specific topic/queue ARNs, not wildcard resources
- [ ] SNS → SQS fan-out tested end-to-end (message appears in all subscribed queues)
- [ ] Filter policies applied where only a subset of consumers should receive certain messages
- [ ] Lambda SQS trigger tested and processing messages successfully
- [ ] CloudWatch alarms configured for DLQ message count and queue backlog age

---

## Cleanup (To Avoid Ongoing Charges)

1. Delete SNS subscriptions: select topic → select subscription(s) → **Delete**
2. Delete the SNS topic: select → **Delete**
3. Delete SQS queues (including the DLQ): select → **Delete**
4. Remove associated IAM policies if unused elsewhere
5. Remove Lambda triggers referencing deleted queues

> SNS and SQS both have generous free tiers (1 million requests/month each) — typical dev/test usage often stays within free tier, but clean up unused topics/queues to avoid clutter and potential misuse.

---

## Quick Reference Summary

| Component | Purpose |
|---|---|
| SNS Topic | Pub/sub channel — pushes messages to all subscribers |
| SNS Subscription | Endpoint (email, SMS, SQS, Lambda, HTTP) receiving topic messages |
| SQS Queue | Durable, pull-based message buffer |
| Visibility Timeout | Grace period before an unprocessed message becomes visible again |
| Dead-Letter Queue (DLQ) | Captures repeatedly failed messages for investigation |
| Filter Policy | Restricts which messages a subscriber receives |
| Long Polling | Reduces empty receive responses and API call costs |

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| Email subscription not receiving messages | Subscription still `Pending confirmation` | Check inbox/spam for AWS confirmation email, click confirm |
| SQS queue not receiving from SNS | Missing SQS access policy statement allowing SNS to publish | Add/verify the access policy shown in Step C2 |
| Messages disappearing without being processed | Visibility timeout too short — consumer takes longer than timeout, message becomes visible again and is picked up by another consumer/duplicated | Increase visibility timeout to exceed your typical processing time |
| Messages piling up in DLQ | Consumer code throwing errors on every attempt | Check consumer logs (CloudWatch); fix the underlying processing bug, then redrive messages from DLQ back to source queue |
| Duplicate message processing | Standard queue's at-least-once delivery model (expected behavior) | Design consumers to be idempotent, or switch to a FIFO queue for exactly-once processing |

---

## Next Steps / Advanced Topics

- **SQS FIFO Queues with Message Deduplication** — exactly-once processing for order-sensitive workflows
- **SNS Message Filtering with Multiple Attributes** — complex routing logic across many consumer types
- **Redrive to source queue** — reprocess DLQ messages via the console's **Start DLQ redrive** feature after fixing the root cause
- **EventBridge as an alternative** — richer event routing/filtering than SNS for many AWS-native event sources
- **Infrastructure as Code** — manage topics, queues, and subscriptions via Terraform or AWS CloudFormation
