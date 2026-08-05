# Setting Up Step Functions & EventBridge in AWS — Complete Step-by-Step Guide

AWS Step Functions orchestrates multi-step workflows (state machines) across Lambda, ECS, SQS, and other services with built-in error handling and retries. Amazon EventBridge is AWS's event bus, routing events between AWS services, SaaS apps, and custom applications based on rules. This guide covers both — commonly used together to build event-driven, orchestrated automation.

---

## Architecture Overview

```
      Event Source (S3, custom app, schedule)
                    │
             EventBridge Bus
                    │
              Rule (pattern match)
                    │
        ┌───────────┼────────────┐
        │           │            │
    Lambda      Step Functions   SQS/SNS
                     │
          ┌──────────┼──────────┐
          │          │          │
      Task 1      Choice     Task 2
     (Lambda)    (branch)   (Lambda)
          │
      Parallel / Retry / Catch
```

---

## Prerequisites

- Active AWS account
- IAM user/role with `AWSStepFunctionsFullAccess` and `AmazonEventBridgeFullAccess`
- Existing Lambda functions or other targets to orchestrate (see companion *AWS Lambda Creation Guide*)

---

## Part A: Step Functions

### Step A1: Sign In and Open Step Functions

1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in, select your region
3. Search for `Step Functions` and select it

### Step A2: Create a State Machine

1. **State machines** → **Create state machine**
2. Choose authoring method: **Design your workflow visually** (drag-and-drop) or **Write your workflow in code** (Amazon States Language / ASL)
3. Type: **Standard** (durable, up to 1 year, exactly-once, best for long workflows/audit trail) or **Express** (high-volume, up to 5 minutes, at-least-once, cheaper per-execution — best for event processing)

Select **Standard** for this guide.

### Step A3: Define the Workflow (ASL)

```json
{
  "Comment": "Order processing workflow",
  "StartAt": "ValidateOrder",
  "States": {
    "ValidateOrder": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:ap-south-1:123456789012:function:validate-order",
      "Next": "IsValid",
      "Retry": [
        {
          "ErrorEquals": ["States.TaskFailed"],
          "IntervalSeconds": 2,
          "MaxAttempts": 3,
          "BackoffRate": 2.0
        }
      ],
      "Catch": [
        {
          "ErrorEquals": ["States.ALL"],
          "Next": "NotifyFailure"
        }
      ]
    },
    "IsValid": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.isValid",
          "BooleanEquals": true,
          "Next": "ProcessPayment"
        }
      ],
      "Default": "NotifyFailure"
    },
    "ProcessPayment": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:ap-south-1:123456789012:function:process-payment",
      "Next": "ParallelFulfillment"
    },
    "ParallelFulfillment": {
      "Type": "Parallel",
      "Branches": [
        {
          "StartAt": "UpdateInventory",
          "States": {
            "UpdateInventory": {
              "Type": "Task",
              "Resource": "arn:aws:lambda:ap-south-1:123456789012:function:update-inventory",
              "End": true
            }
          }
        },
        {
          "StartAt": "SendConfirmationEmail",
          "States": {
            "SendConfirmationEmail": {
              "Type": "Task",
              "Resource": "arn:aws:lambda:ap-south-1:123456789012:function:send-email",
              "End": true
            }
          }
        }
      ],
      "Next": "Success"
    },
    "Success": {
      "Type": "Succeed"
    },
    "NotifyFailure": {
      "Type": "Task",
      "Resource": "arn:aws:sns:ap-south-1:123456789012:order-events",
      "End": true
    }
  }
}
```

### Key State Types

| State Type | Purpose |
|---|---|
| `Task` | Invokes a Lambda, ECS task, or other supported service integration |
| `Choice` | Branches based on input data (like an if/else) |
| `Parallel` | Runs multiple branches concurrently |
| `Map` | Iterates over a collection, running a sub-workflow per item |
| `Wait` | Pauses for a fixed time or until a timestamp |
| `Succeed` / `Fail` | Terminal states |

### Step A4: Set the Execution Role

1. On the review step, select/create an IAM role that Step Functions assumes to invoke the resources in your workflow (Lambda, SNS, etc.)
2. Name: `orders-workflow-role`
3. Click **Create state machine**

### Step A5: Execute and Test

1. Select the state machine → **Start execution**
2. Input (JSON):
   ```json
   {"orderId": "ORD-1001", "amount": 149.99}
   ```
3. Click **Start execution**
4. Watch the **Graph view** — completed states turn green, failed states red
5. Click any state to see its input/output for debugging

### Step A6: Add Error Handling Patterns

- **Retry**: automatically retries a failed task with exponential backoff (shown in Step A3)
- **Catch**: routes to a fallback state on specific error types instead of failing the whole execution
- **Timeout**: set `TimeoutSeconds` on a Task to prevent it from hanging indefinitely

### Step A7: Monitor Executions

1. Select the state machine → **Executions** tab — see history of all runs, filterable by status
2. **CloudWatch** → `AWS/States` namespace — metrics like `ExecutionsFailed`, `ExecutionTime`
3. Set an alarm on `ExecutionsFailed > 0` to catch workflow failures

---

## Part B: EventBridge

### Step B1: Explore the Default Event Bus

1. Search for `EventBridge` and select it
2. Left sidebar → **Event buses** — the `default` bus automatically receives events from most AWS services
3. Create a **custom event bus** for application-specific events: **Event buses** → **Create event bus** → name: `orders-app-bus`

### Step B2: Create a Rule (Schedule-Based)

1. Left sidebar → **Rules** → **Create rule**
2. Name: `nightly-cleanup`
3. Event bus: `default`
4. Rule type: **Schedule**
5. Schedule pattern:
   - Cron expression: `cron(0 2 * * ? *)` (2 AM daily)
   - Or rate expression: `rate(1 hour)`
6. Click **Next**
7. **Target**: select **Lambda function**, **Step Functions state machine**, or another target → select your resource
8. Click **Next** → review → **Create rule**

### Step B3: Create a Rule (Event Pattern-Based)

React to actual AWS service events, e.g., an S3 upload:

1. **Create rule** → Rule type: **Event pattern**
2. **Event source**: **AWS services**
3. **AWS service**: **Simple Storage Service (S3)**
4. **Event type**: **Object Created**
5. Specify the bucket name to filter to
6. Generated pattern:
   ```json
   {
     "source": ["aws.s3"],
     "detail-type": ["Object Created"],
     "detail": {
       "bucket": {"name": ["my-app-bucket-prod-2026"]}
     }
   }
   ```
7. Target: your Lambda function or Step Functions state machine
8. Click **Create rule**

### Step B4: Publish Custom Application Events

From your application code:

```python
import boto3
import json

client = boto3.client("events")
client.put_events(
    Entries=[
        {
            "Source": "orders.app",
            "DetailType": "OrderCreated",
            "Detail": json.dumps({"orderId": "ORD-1001", "amount": 149.99}),
            "EventBusName": "orders-app-bus"
        }
    ]
)
```

Create a matching rule on `orders-app-bus`:
```json
{
  "source": ["orders.app"],
  "detail-type": ["OrderCreated"]
}
```

### Step B5: Trigger a Step Functions Workflow from EventBridge

1. **Create rule** on the relevant event bus with the pattern from Step B4
2. Target: **Step Functions state machine** → select the workflow from Part A
3. **Configure input**: pass the full event, or a **constant JSON text**, or **input transformer** to reshape the event before passing it to the state machine
4. Click **Create rule**

This is the standard pattern for **event-driven orchestration**: an event occurs → EventBridge routes it → Step Functions coordinates the multi-step response.

### Step B6: Set Up an Archive and Replay (Optional)

Useful for debugging or reprocessing past events.

1. Left sidebar → **Archives** → **Create archive**
2. Select the event bus, retention period (or indefinite), and an optional filter
3. To replay: **Replays** → **Start new replay** → select the archive and a time range → target the same or a different rule/bus

### Step B7: Cross-Account/Cross-Region Event Bus

1. **Event buses** → select bus → **Permissions** → add a resource policy granting another account `events:PutEvents`
2. In the sending account, create a rule targeting the receiving account's event bus ARN as the target
3. Useful for centralizing events (e.g., security findings) from many accounts into one monitoring account

---

## Verification Checklist

- [ ] State machine type (Standard vs. Express) matches the workflow's duration/volume needs
- [ ] Retry and Catch configured on tasks likely to transiently fail
- [ ] Execution role scoped to only the resources the workflow actually invokes
- [ ] CloudWatch alarm configured on `ExecutionsFailed`
- [ ] EventBridge rules use specific event patterns, not overly broad matches
- [ ] Custom application events follow a consistent `Source`/`DetailType` naming convention
- [ ] Archive configured for critical event buses to support replay/debugging
- [ ] Cross-account event routing tested if applicable

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| Step Functions execution fails immediately | Execution role lacks permission to invoke the target Lambda/service | Add the missing `lambda:InvokeFunction` (or equivalent) permission to the execution role |
| EventBridge rule never triggers | Event pattern doesn't match actual event structure | Use the **Sample events** feature in the console to compare against your pattern; check `source`/`detail-type` casing |
| Scheduled rule fires at unexpected time | Cron expressions in EventBridge use **UTC**, not local time | Convert your desired local time to UTC when writing the cron expression |
| Duplicate workflow executions from one event | EventBridge's at-least-once delivery, or Express state machine's at-least-once semantics | Design downstream tasks to be idempotent |

---

## Next Steps / Advanced Topics

- **Step Functions + Map (Distributed Map)** — process millions of items in parallel (e.g., S3 objects) at scale
- **EventBridge Pipes** — simplified point-to-point integration between a source (e.g., SQS) and a target, with optional filtering/enrichment, without writing custom Lambda glue code
- **EventBridge Scheduler** — a dedicated, more flexible scheduling service (millions of schedules) as an alternative to schedule-based rules
- **Infrastructure as Code** — manage state machines, rules, and event buses via Terraform, AWS SAM, or CloudFormation
