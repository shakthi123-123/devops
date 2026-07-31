# Creating a Lambda Function in AWS — Complete Step-by-Step Guide

AWS Lambda runs code without provisioning or managing servers — you pay only for compute time consumed. This guide covers creating a function, configuring permissions, setting triggers, testing, and monitoring.

---

## Architecture Overview

```
        Trigger Sources
   ┌───────┬───────┬────────┐
   │       │       │        │
  S3    API GW   EventBridge  SQS
   │       │       │        │
   └───────┴───┬───┴────────┘
               │
        ┌──────▼───────┐
        │  Lambda        │
        │  Function      │
        │  - Runtime      │
        │  - Handler      │
        │  - IAM Role     │
        │  - Env Vars     │
        └──────┬────────┘
               │
       ┌───────┴────────┐
       │                │
   CloudWatch Logs   Other AWS Services
                      (S3, DynamoDB, SNS)
```

---

## Prerequisites

- Active AWS account
- IAM user/role with `AWSLambda_FullAccess` (or scoped equivalent) permissions
- Basic familiarity with at least one supported runtime language (Python, Node.js, Java, Go, .NET, Ruby)

---

## Step 1: Sign In and Select Region

1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in with IAM credentials
3. Select your target **region** (e.g., `Asia Pacific (Mumbai) ap-south-1`)

> Lambda functions are region-specific — triggers like S3 or DynamoDB should generally be in the same region for lowest latency, though cross-region invocation is possible.

---

## Step 2: Open the Lambda Console

1. In the search bar, type `Lambda` and select **Lambda**
2. You'll land on the **Lambda Dashboard**, showing existing functions and usage metrics

---

## Step 3: Create the Function

1. Click **Create function**
2. Choose a creation method:
   - **Author from scratch** — write code directly (recommended for this guide)
   - **Use a blueprint** — pre-built templates for common patterns
   - **Container image** — deploy a Docker container as the function
   - **Browse serverless app repository** — deploy a pre-packaged application

3. **Basic information**:

| Field | Value | Notes |
|---|---|---|
| Function name | `process-order-events` | Descriptive, no spaces |
| Runtime | `Python 3.13` | Or Node.js 22.x, Java 21, etc. |
| Architecture | `x86_64` | `arm64` (Graviton2) is cheaper and often faster |

4. **Permissions** — expand **Change default execution role**:
   - **Create a new role with basic Lambda permissions** (recommended for first-time setup) — auto-creates a role with CloudWatch Logs write access
   - **Use an existing role** — select a pre-created IAM role if you already have one scoped for this function
   - **Create a new role from AWS policy templates** — adds common permission sets (e.g., S3 read, DynamoDB CRUD)

5. Click **Create function**
6. Wait for the green **"Successfully created the function"** banner

---

## Step 4: Write and Deploy Function Code

1. In the function page, scroll to the **Code source** editor (or **Code** tab)
2. Replace the default handler with your logic. Example (Python):
   ```python
   import json

   def lambda_handler(event, context):
       print("Received event:", json.dumps(event))
       name = event.get("queryStringParameters", {}).get("name", "World")
       return {
           "statusCode": 200,
           "headers": {"Content-Type": "application/json"},
           "body": json.dumps({"message": f"Hello, {name}!"})
       }
   ```
3. Click **Deploy** (top of the code editor) to save and activate changes
4. For larger projects with dependencies, instead of the inline editor:
   - Package code and dependencies into a `.zip` file locally:
     ```bash
     pip install -r requirements.txt -t ./package
     cd package && zip -r ../function.zip . && cd ..
     zip -g function.zip lambda_function.py
     ```
   - Click **Upload from** → **.zip file** → select `function.zip`

---

## Step 5: Configure General Settings

1. Go to the **Configuration** tab → **General configuration** → **Edit**
2. Adjust:

| Setting | Recommended Value | Notes |
|---|---|---|
| Memory | 128–256 MB (start small, scale up if needed) | More memory also increases allocated CPU |
| Timeout | 3–15 seconds (adjust per workload) | Max is 15 minutes |
| Ephemeral storage | 512 MB (default) | Increase up to 10,240 MB if `/tmp` usage is high |

3. Click **Save**

> **Tip:** Use AWS Lambda Power Tuning (open-source tool) to find the optimal memory/cost/performance balance for your function.

---

## Step 6: Set Environment Variables

1. **Configuration** tab → **Environment variables** → **Edit**
2. Click **Add environment variable**:

| Key | Value |
|---|---|
| `TABLE_NAME` | `orders-table` |
| `LOG_LEVEL` | `INFO` |

3. For sensitive values (API keys, DB passwords), check **Enable helpers for encryption in transit** and use **AWS Secrets Manager** or **SSM Parameter Store** references instead of plaintext env vars
4. Click **Save**

---

## Step 7: Attach IAM Permissions for Downstream Services

If your function needs to read/write to other AWS services (e.g., DynamoDB, S3), attach a scoped policy to its execution role.

1. **Configuration** tab → **Permissions** → click the **Role name** link (opens IAM console)
2. Click **Add permissions** → **Create inline policy** (or attach an existing managed policy)
3. Example — allow read/write to a specific DynamoDB table:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem"],
         "Resource": "arn:aws:dynamodb:ap-south-1:123456789012:table/orders-table"
       }
     ]
   }
   ```
4. Name the policy `Lambda-DynamoDB-OrdersTable` → **Create policy**

---

## Step 8: Add a Trigger

Triggers invoke the function automatically based on events.

1. Return to the function page → **Add trigger**
2. Choose a source, e.g.:

### Option A: API Gateway (HTTP Endpoint)
- Trigger: **API Gateway**
- API type: **HTTP API** (cheaper/simpler) or **REST API** (more features)
- Security: **Open** (for testing) or **AWS_IAM** (for authenticated calls)
- Click **Add** — AWS generates an invoke URL automatically

### Option B: S3 (On Object Upload)
- Trigger: **S3**
- Bucket: select your bucket (e.g., `my-app-bucket-prod-2026`)
- Event type: **All object create events**
- Prefix/Suffix filter: e.g., suffix `.jpg` to trigger only on image uploads
- Click **Add**

### Option C: EventBridge (Scheduled/Cron)
- Trigger: **EventBridge (CloudWatch Events)**
- Rule type: **Schedule expression**
- Expression: `rate(5 minutes)` or `cron(0 9 * * ? *)` (daily at 9 AM UTC)
- Click **Add**

### Option D: SQS (Queue Processing)
- Trigger: **SQS**
- Queue: select an existing SQS queue
- Batch size: `10` (number of messages per invocation)
- Click **Add**

---

## Step 9: Test the Function

1. Go to the **Test** tab
2. Click **Create new event**
3. Event name: `test-event-1`
4. Choose a template matching your trigger (e.g., `apigateway-aws-proxy` or leave as generic JSON):
   ```json
   {
     "queryStringParameters": {
       "name": "AWS"
     }
   }
   ```
5. Click **Save**, then click **Test**
6. Review the **Execution result**:
   - **Response**: the returned payload
   - **Duration**: execution time in ms
   - **Billed duration**: rounded billing time
   - **Memory used**: actual vs. allocated memory
7. Check **Logs** for `print`/`console.log` output and any errors

---

## Step 10: Monitor with CloudWatch

1. Go to the **Monitor** tab on the function page
2. Review built-in graphs:
   - Invocations
   - Duration
   - Error count and success rate
   - Throttles
   - Concurrent executions
3. Click **View CloudWatch logs** to see detailed execution logs per invocation
4. (Optional) Set a CloudWatch Alarm:
   - Go to **CloudWatch** → **Alarms** → **Create alarm**
   - Metric: `Errors` for this function
   - Threshold: e.g., `> 5 errors in 5 minutes`
   - Notification: send to an SNS topic (email/SMS)

---

## Step 11: Configure Concurrency and Scaling (Optional)

1. **Configuration** tab → **Concurrency** → **Edit**
2. Options:
   - **Unreserved concurrency** (default): shares the account-wide pool (1,000 by default, can request increase)
   - **Reserved concurrency**: guarantees (and caps) a specific number of concurrent executions for this function — prevents it from starving other functions, or from over-scaling and overwhelming a downstream database
   - **Provisioned concurrency**: pre-warms execution environments to eliminate cold starts, at additional cost — useful for latency-sensitive APIs
3. Click **Save**

---

## Step 12: Set Up Versions and Aliases (For Safe Deployments)

1. **Actions** → **Publish new version** — creates an immutable snapshot of the current code + config
2. Go to **Aliases** tab → **Create alias**
   - Name: `prod`
   - Version: point to the published version (e.g., version `3`)
3. Use **weighted aliases** for canary deployments:
   - Route 90% of traffic to version 3, 10% to version 4, to test new code safely before full rollout
4. Point triggers (e.g., API Gateway) at the **alias ARN** rather than `$LATEST`, so you can shift traffic without reconfiguring triggers

---

## Step 13: Verification Checklist

- [ ] Function created with correct runtime and architecture
- [ ] Execution role scoped to least-privilege (only required service permissions)
- [ ] Environment variables set; secrets use Secrets Manager/Parameter Store, not plaintext
- [ ] Memory and timeout tuned to workload (not left at defaults blindly)
- [ ] Trigger configured and tested (API Gateway, S3, EventBridge, SQS, etc.)
- [ ] Test event runs successfully with expected output
- [ ] CloudWatch Logs show expected output with no unhandled errors
- [ ] CloudWatch alarm configured for error rate monitoring
- [ ] Concurrency limits reviewed (reserved/provisioned if needed)
- [ ] Versions/aliases used for production traffic instead of `$LATEST`

---

## Cleanup (To Avoid Ongoing Charges)

Lambda itself is pay-per-invocation with a generous free tier, but attached resources can incur cost:

1. Delete the function: **Actions** → **Delete function**
2. Remove associated triggers (API Gateway APIs, EventBridge rules, S3 event notifications) if not shared with other resources
3. Delete the CloudWatch Log Group: **CloudWatch** → **Log groups** → find `/aws/lambda/process-order-events` → **Delete**
4. Delete the IAM execution role if no longer needed
5. Remove any Provisioned Concurrency configuration (this incurs charges even when idle)

---

## Quick Reference Summary

| Component | Purpose |
|---|---|
| Function | The deployable unit of code + configuration |
| Handler | Entry-point function AWS invokes |
| Execution Role | IAM role granting the function its permissions |
| Trigger | Event source that invokes the function |
| Environment Variables | Runtime configuration values |
| Layers | Shared code/dependencies reusable across functions |
| Version | Immutable snapshot of code + config |
| Alias | Named pointer to a version, supports traffic-weighting |
| Concurrency | Controls parallel execution limits |

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| `Task timed out after X seconds` | Function logic takes longer than configured timeout | Increase timeout, or optimize code/downstream calls |
| `AccessDeniedException` calling another AWS service | Execution role missing required permission | Add scoped policy to the function's IAM role |
| Cold start latency spikes | No provisioned concurrency, VPC-attached function | Enable Provisioned Concurrency; avoid unnecessary VPC attachment |
| Function not triggered by S3 upload | Event notification misconfigured, or prefix/suffix filter mismatch | Recheck trigger config in both Lambda and S3 event notifications |
| `Unable to import module` error | Missing dependency in deployment package | Ensure all dependencies are bundled in the `.zip` or use a Lambda Layer |

---

## Next Steps / Advanced Topics

- **Lambda Layers** — share common dependencies/libraries across multiple functions
- **Step Functions** — orchestrate multiple Lambda functions into a workflow/state machine
- **Lambda@Edge / CloudFront Functions** — run code at CDN edge locations for ultra-low latency
- **Container Image Support** — package Lambda functions as Docker images for complex dependencies (up to 10 GB)
- **Infrastructure as Code** — manage functions, triggers, and permissions via Terraform, AWS SAM, or AWS CloudFormation
