# Creating a DynamoDB Table in AWS — Complete Step-by-Step Guide

Amazon DynamoDB is a fully managed, serverless NoSQL key-value/document database offering single-digit millisecond performance at any scale. This guide covers table design, indexes, capacity modes, access control, and integration with Lambda.

---

## Architecture Overview

```
                  Application / Lambda
                          │
                    IAM Policy
                          │
                ┌──────────────────┐
                │  DynamoDB Table    │
                │  Orders             │
                │                    │
                │  PK: orderId        │
                │  SK: customerId      │
                │                    │
                │  GSI: customerId-index │
                │  LSI: orderDate-index  │
                │                    │
                │  Streams ──► Lambda  │
                └──────────────────┘
```

---

## Prerequisites

- Active AWS account
- IAM user/role with `AmazonDynamoDBFullAccess` (or scoped equivalent) permissions
- A clear idea of your **access patterns** — unlike relational databases, DynamoDB table design starts from "how will I query this?" rather than normalized entity modeling

### Core Concepts Before You Start

| Concept | Description |
|---|---|
| Partition key (PK) | Determines which physical partition stores the item; must be highly unique/distributed |
| Sort key (SK) | Optional; combined with PK forms a composite primary key, enables range queries |
| Item | A single record (like a row), up to 400 KB |
| Attribute | A field on an item (like a column), but schema-less — items in the same table can have different attributes |
| GSI (Global Secondary Index) | Alternate PK/SK for different query patterns, own read/write capacity |
| LSI (Local Secondary Index) | Same PK as base table, different SK — must be created at table creation, cannot be added later |

---

## Step 1: Sign In and Select Region

1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in with IAM credentials
3. Select your target **region** (e.g., `Asia Pacific (Mumbai) ap-south-1`)

---

## Step 2: Open the DynamoDB Console

1. In the search bar, type `DynamoDB` and select **DynamoDB**
2. You'll land on the **DynamoDB Dashboard**

---

## Step 3: Design Your Key Schema

Before creating the table, define your access patterns on paper. Example — an e-commerce orders table:

| Access Pattern | Key Design |
|---|---|
| Get order by ID | PK: `orderId` |
| Get all orders for a customer | GSI PK: `customerId`, SK: `orderDate` |
| Get orders by status within a date range | GSI PK: `status`, SK: `orderDate` |

Chosen schema for this guide:
- **Table name**: `Orders`
- **Partition key**: `orderId` (String)
- **Sort key**: `customerId` (String)

---

## Step 4: Create the Table

1. Click **Create table**
2. **Table details**:

| Field | Value | Notes |
|---|---|---|
| Table name | `Orders` | |
| Partition key | `orderId` — Type: **String** | |
| Sort key | `customerId` — Type: **String** | Optional, add if composite key needed |

3. **Table settings**:
   - **Default settings** (recommended for most cases): on-demand capacity, AWS-owned encryption key
   - **Customize settings**: expand for full control (used below)

4. **Table class**:
   - **DynamoDB Standard** (default, most use cases)
   - **DynamoDB Standard-IA** — cheaper storage for infrequently accessed tables, higher read/write cost

5. **Capacity mode**:

| Mode | Best For | Billing |
|---|---|---|
| **On-demand** | Unpredictable/spiky traffic, new applications | Pay per request, no capacity planning |
| **Provisioned** | Steady, predictable traffic | Pay for reserved read/write capacity units (cheaper at scale, can use Auto Scaling) |

   Select **On-demand** for this guide (recommended default; switch to Provisioned later if traffic becomes predictable and cost-sensitive)

6. **Secondary indexes** — expand and click **Create global index** if needed now (can also be added after table creation for GSIs):
   - Index name: `customerId-orderDate-index`
   - Partition key: `customerId`
   - Sort key: `orderDate`
   - Projected attributes: **All** (simplest) or **Keys only** / **Include** specific attributes (cheaper storage/throughput for large items)

7. **Encryption at rest**:
   - **Amazon DynamoDB owned key** (default, no cost)
   - **AWS owned key** or **Customer managed key (KMS)** for audit/compliance requirements

8. Click **Create table**
9. Status shows `Creating` → wait for `Active` (usually under a minute)

---

## Step 5: Add Items (Manually, for Testing)

1. Select the table → **Explore table items** tab → **Create item**
2. Choose **Form** or **JSON** view. Example JSON:
   ```json
   {
     "orderId": "ORD-1001",
     "customerId": "CUST-500",
     "orderDate": "2026-07-31",
     "status": "SHIPPED",
     "total": 149.99,
     "items": [
       {"sku": "ITEM-1", "qty": 2},
       {"sku": "ITEM-2", "qty": 1}
     ]
   }
   ```
3. Click **Create item**
4. Repeat with more sample items to test queries later

---

## Step 6: Query and Scan the Table

### Query (Efficient — Uses an Index)

1. **Explore table items** tab → **Query**
2. Select the table or a GSI from the dropdown
3. Enter the partition key value (and optionally sort key condition):
   - Partition key: `orderId` = `ORD-1001`
4. Click **Run**

### Scan (Reads Entire Table — Use Sparingly)

1. Switch to **Scan** mode
2. Add filters if needed (e.g., `status = SHIPPED`)
3. Click **Run**

> **Best practice:** Always design GSIs to support **Query** operations for your access patterns. Avoid `Scan` in production application code — it reads every item and doesn't scale.

---

## Step 7: Set Up IAM Permissions (Least Privilege)

1. **IAM Console** → **Policies** → **Create policy** → **JSON** tab
2. Example — allow an application role to read/write only the `Orders` table and its indexes:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "dynamodb:GetItem",
           "dynamodb:PutItem",
           "dynamodb:UpdateItem",
           "dynamodb:DeleteItem",
           "dynamodb:Query"
         ],
         "Resource": [
           "arn:aws:dynamodb:ap-south-1:123456789012:table/Orders",
           "arn:aws:dynamodb:ap-south-1:123456789012:table/Orders/index/*"
         ]
       }
     ]
   }
   ```
3. Name: `DynamoDB-OrdersTable-ReadWrite`
4. Attach this policy to the relevant IAM role (e.g., a Lambda execution role or EC2 instance role)

---

## Step 8: Enable DynamoDB Streams (For Event-Driven Processing)

Streams capture item-level changes (insert/update/delete) in near real-time — commonly used to trigger Lambda functions.

1. Select the table → **Exports and streams** tab → **DynamoDB stream details** → **Enable**
2. **View type**:

| View Type | Captures |
|---|---|
| Key attributes only | Just the keys of the changed item |
| New image | The entire item after the change |
| Old image | The entire item before the change |
| New and old images | Both — most common choice |

3. Select **New and old images** → **Enable stream**
4. Under **Trigger** → **Create trigger**:
   - Select an existing Lambda function, or create a new one
   - Batch size: `10` (items per invocation)
   - Click **Create trigger**
5. This Lambda now fires automatically whenever items in `Orders` are created, updated, or deleted

---

## Step 9: Configure Time to Live (TTL) for Automatic Expiration

Useful for session data, temporary tokens, or logs that should auto-delete.

1. Select the table → **Additional settings** tab → **Time to Live (TTL)** → **Turn on**
2. TTL attribute name: `expiresAt` (must be a Number attribute storing a Unix epoch timestamp)
3. Click **Turn on TTL**
4. When writing items, set `expiresAt` to the epoch time you want the item removed:
   ```json
   { "orderId": "TEMP-1", "expiresAt": 1785600000 }
   ```
5. DynamoDB automatically deletes expired items within 48 hours of expiration (no extra write capacity consumed for the deletion)

---

## Step 10: Enable Point-in-Time Recovery (PITR) and Backups

1. Select the table → **Backups** tab
2. **Point-in-time recovery (PITR)**:
   - Click **Edit** → **Turn on**
   - Allows restoring the table to any point within the last 35 days
3. **On-demand backup** (manual snapshot):
   - Click **Create backup**
   - Name: `Orders-backup-2026-07-31`
   - Click **Create backup**
4. To restore: **Backups** tab → select a backup or PITR timestamp → **Restore backup** (creates a **new** table — cannot restore in-place)

---

## Step 11: Set Up Auto Scaling (Provisioned Mode Only)

If using **Provisioned** capacity mode instead of On-demand:

1. Select the table → **Additional settings** tab → **Read/write capacity** → **Edit**
2. Enable **Auto scaling** for both read and write capacity
3. Configure:
   - Minimum capacity: `5` units
   - Maximum capacity: `100` units
   - Target utilization: `70%`
4. Click **Save**

> Auto scaling adjusts provisioned capacity automatically based on consumed throughput, avoiding manual tuning while controlling costs better than always-on high provisioned capacity.

---

## Step 12: Monitor with CloudWatch

1. Select the table → **Monitor** tab
2. Review built-in metrics:
   - `ConsumedReadCapacityUnits` / `ConsumedWriteCapacityUnits`
   - `ThrottledRequests` — indicates capacity is too low (provisioned mode) or a hot partition
   - `SystemErrors` / `UserErrors`
   - `SuccessfulRequestLatency`
3. Set a CloudWatch alarm for throttling:
   - **CloudWatch** → **Alarms** → **Create alarm**
   - Metric: `ThrottledRequests` for this table
   - Threshold: `> 0`
   - Notify via SNS

---

## Step 13: Verification Checklist

- [ ] Key schema (PK/SK) matches actual application access patterns
- [ ] Capacity mode chosen appropriately (On-demand for unpredictable traffic, Provisioned + Auto Scaling for steady traffic)
- [ ] Secondary indexes created for all required query patterns (avoiding `Scan` in app code)
- [ ] IAM policy scoped to least-privilege actions and specific table/index ARNs
- [ ] Encryption at rest configured
- [ ] Point-in-time recovery enabled for production tables
- [ ] DynamoDB Streams enabled if event-driven processing is needed
- [ ] TTL configured for any time-limited data
- [ ] CloudWatch alarms set for throttling and errors
- [ ] Tested Query operations return expected results using the console or CLI

---

## Cleanup (To Avoid Ongoing Charges)

1. Delete on-demand/manual backups no longer needed: **Backups** tab → select → **Delete backup**
2. Delete the table: select table → **Delete**
   - Optionally create a final backup before deleting
   - Type the table name to confirm
3. Remove associated Lambda triggers/streams if the function is reused elsewhere
4. Delete the IAM policy if not used by other resources

> DynamoDB On-demand mode has no idle cost beyond stored data and PITR — Provisioned mode capacity is billed hourly whether or not it's used, so switch idle dev/test tables to On-demand or delete them when not in use.

---

## Quick Reference Summary

| Component | Purpose |
|---|---|
| Table | Top-level container for items |
| Item | A single record (schema-less beyond key attributes) |
| Partition Key | Determines data distribution; required |
| Sort Key | Enables range queries within a partition; optional |
| GSI | Alternate query pattern with its own PK/SK |
| LSI | Alternate sort key using the same PK, set at table creation |
| Streams | Real-time feed of item-level changes |
| TTL | Automatic item expiration based on a timestamp attribute |
| PITR | Continuous backups for point-in-time restore |

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| `ProvisionedThroughputExceededException` | Provisioned capacity too low, or hot partition key | Switch to On-demand, increase capacity, or improve key distribution |
| Query returns empty despite data existing | Wrong index selected, or key value/type mismatch | Confirm correct GSI/LSI selected; check attribute type (String vs Number) matches |
| High latency on large `Scan` operations | Scanning entire table instead of using Query | Redesign access pattern with an appropriate GSI |
| `ValidationException: The provided key element does not match schema` | Missing or mistyped PK/SK in request | Verify exact attribute names and types match table schema |
| Item not auto-deleting via TTL | TTL attribute not a Number/epoch, or up to 48-hour delay | Confirm attribute type is Number; note TTL deletion isn't instantaneous |

---

## Next Steps / Advanced Topics

- **DynamoDB Accelerator (DAX)** — in-memory caching layer for microsecond read latency
- **Global Tables** — multi-region, active-active replication for global applications
- **Single-table design** — advanced pattern modeling multiple entity types in one table using generic PK/SK naming
- **Transactions** — `TransactWriteItems`/`TransactGetItems` for atomic multi-item operations
- **Infrastructure as Code** — manage tables, indexes, and streams via Terraform or AWS CloudFormation
