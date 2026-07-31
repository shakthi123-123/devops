# Creating an API Gateway in AWS — Complete Step-by-Step Guide

Amazon API Gateway lets you create, publish, and manage REST, HTTP, and WebSocket APIs that front backend services like Lambda, EC2, or other HTTP endpoints. This guide covers building an HTTP API backed by Lambda, securing it, and deploying it to a custom domain.

---

## Architecture Overview

```
                    Client (Browser/App)
                            │
                         HTTPS
                            │
                  ┌─────────────────┐
                  │   API Gateway    │
                  │   (HTTP API)     │
                  │                  │
                  │  Route: GET /hi  │
                  │  Authorizer      │
                  │  Throttling      │
                  └────────┬─────────┘
                            │
                    ┌───────┴────────┐
                    │                │
              Lambda Function    EC2/ALB Backend
```

---

## Prerequisites

- Active AWS account
- IAM user/role with `AmazonAPIGatewayAdministrator` (or scoped equivalent) permissions
- A backend to integrate with — e.g., a Lambda function (see companion *AWS Lambda Creation Guide*), or an existing HTTP endpoint/ALB

### REST API vs. HTTP API — Which to Choose

| Feature | HTTP API | REST API |
|---|---|---|
| Cost | ~70% cheaper | Higher per-request cost |
| Latency | Lower | Higher |
| Features | Core routing, JWT/Lambda authorizers, CORS | Full feature set: API keys, usage plans, request/response transformation, WAF, private endpoints |
| Best for | Most modern serverless APIs | Enterprise APIs needing fine-grained control |

This guide uses **HTTP API** (recommended default for new projects) and notes REST API differences where relevant.

---

## Step 1: Sign In and Select Region

1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in with IAM credentials
3. Select your target **region** (e.g., `Asia Pacific (Mumbai) ap-south-1`)

> The API Gateway and its backend (e.g., Lambda) should generally be in the same region.

---

## Step 2: Open the API Gateway Console

1. In the search bar, type `API Gateway` and select **API Gateway**
2. You'll land on the **APIs** dashboard listing existing APIs

---

## Step 3: Create the API

1. Click **Create API**
2. Under **HTTP API**, click **Build**
3. **Step 1 — Integrations**:
   - Click **Add integration**
   - Integration type: **Lambda**
   - AWS Region: your region
   - Lambda function: select your function (e.g., `process-order-events`)
   - **API name**: `orders-api`
4. Click **Next**

5. **Step 2 — Configure routes**:
   - **Method**: `GET`
   - **Resource path**: `/hello`
   - **Integration target**: your Lambda function (auto-filled)
   - Click **Add route** to define additional routes, e.g.:

| Method | Path | Integration |
|---|---|---|
| GET | `/orders` | `list-orders-fn` |
| POST | `/orders` | `create-order-fn` |
| GET | `/orders/{id}` | `get-order-fn` |
| DELETE | `/orders/{id}` | `delete-order-fn` |

   - Click **Next**

6. **Step 3 — Configure stages**:
   - Stage name: `$default` (auto-deploys on every change) — good for dev
   - For production, uncheck auto-deploy and create a named stage instead (e.g., `prod`) — see Step 8
   - Click **Next**

7. **Step 4 — Review and create**:
   - Confirm integrations, routes, and stage settings
   - Click **Create**

8. Note the **Invoke URL** shown on the API's main page, e.g.:
   ```
   https://abc123xyz.execute-api.ap-south-1.amazonaws.com
   ```

---

## Step 4: Grant API Gateway Permission to Invoke Lambda

Usually configured automatically when you add the Lambda integration through the console, but verify:

1. Go to the **Lambda console** → select the function → **Configuration** tab → **Permissions**
2. Under **Resource-based policy statements**, confirm an entry exists allowing `apigateway.amazonaws.com` to invoke the function
3. If missing, add manually via AWS CLI:
   ```bash
   aws lambda add-permission \
     --function-name process-order-events \
     --statement-id apigateway-invoke \
     --action lambda:InvokeFunction \
     --principal apigateway.amazonaws.com \
     --source-arn "arn:aws:execute-api:ap-south-1:123456789012:abc123xyz/*/*/hello"
   ```

---

## Step 5: Test the API

1. Copy the **Invoke URL** + route path, e.g.:
   ```
   https://abc123xyz.execute-api.ap-south-1.amazonaws.com/hello
   ```
2. Test with curl:
   ```bash
   curl https://abc123xyz.execute-api.ap-south-1.amazonaws.com/hello
   ```
3. Or open directly in a browser for `GET` routes
4. Confirm the response matches your Lambda function's return payload
5. Check **CloudWatch Logs** (see Step 9) if the response is unexpected

---

## Step 6: Configure CORS (If Called from a Browser Frontend)

1. Select your API → left sidebar → **CORS** → **Configure**
2. Set:

| Field | Value |
|---|---|
| Access-Control-Allow-Origin | `https://myfrontend.com` (avoid `*` in production) |
| Access-Control-Allow-Methods | `GET, POST, DELETE, OPTIONS` |
| Access-Control-Allow-Headers | `Content-Type, Authorization` |
| Access-Control-Max-Age | `300` |

3. Click **Save**

---

## Step 7: Secure the API with an Authorizer

Choose one based on your auth model:

### Option A: JWT Authorizer (Cognito or Third-Party OIDC)

1. Left sidebar → **Authorization** → **Manage authorizers** → **Create**
2. Type: **JWT**
3. Identity source: `$request.header.Authorization`
4. Issuer URL: your Cognito User Pool or OIDC provider issuer URL
5. Audience: your app client ID
6. Click **Create**
7. Go to **Routes** → select a route → **Attach authorization** → choose the JWT authorizer

### Option B: Lambda Authorizer (Custom Logic)

1. **Manage authorizers** → **Create**
2. Type: **Lambda**
3. Select a Lambda function that validates tokens/API keys and returns an IAM policy
4. Identity source: `$request.header.Authorization`
5. Attach to routes as in Option A

### Option C: IAM Authorization (SigV4)

- Useful for service-to-service calls within AWS
- Set route authorization type to **AWS_IAM** under route settings
- Callers must sign requests with valid AWS credentials

> Routes without an authorizer attached are **publicly accessible** — review every route before going to production.

---

## Step 8: Create a Named Stage for Production

1. Left sidebar → **Stages** → **Create**
2. Stage name: `prod`
3. **Auto-deploy**: disable for controlled releases (deploy manually after testing)
4. **Default route settings**:
   - Throttling — burst: `100`, rate: `50` requests/second (adjust per capacity planning)
   - Enable **Detailed metrics** for per-route CloudWatch stats
5. Click **Create**
6. To deploy changes to this stage: **Deploy** button (top right) → select stage `prod` → **Deploy**
7. Your production invoke URL becomes:
   ```
   https://abc123xyz.execute-api.ap-south-1.amazonaws.com/prod
   ```

---

## Step 9: Enable Logging and Monitoring

1. Select your API → **Stages** → select `prod` → **Logging** tab → **Edit**
2. **Access logging**:
   - Enable, select/create a CloudWatch Log Group (e.g., `/aws/apigateway/orders-api-prod`)
   - Log format: JSON, including `requestId`, `ip`, `httpMethod`, `status`, `responseLength`, `integrationLatency`
3. Click **Save**
4. Go to **CloudWatch** → **Log groups** to view real-time request logs
5. Set alarms on key metrics (**Monitor** tab or CloudWatch directly):
   - `5xxError` count — backend failures
   - `4xxError` count — client/auth issues
   - `Latency` / `IntegrationLatency` — performance
   - `Count` — traffic volume

---

## Step 10: Set Up a Custom Domain (Optional)

1. Left sidebar (top-level, not inside a specific API) → **Custom domain names** → **Create**
2. Domain name: `api.mycompany.com`
3. Certificate: select an **ACM certificate** for this domain (request one first via **AWS Certificate Manager** if you don't have one — must be in the same region as the API, or `us-east-1` for edge-optimized)
4. Endpoint type: **Regional** (recommended) or **Edge-optimized** (uses CloudFront globally)
5. Click **Create domain name**
6. **API mappings** tab → **Configure API mappings** → **Add new mapping**:
   - API: `orders-api`
   - Stage: `prod`
   - Path (optional): leave blank or add a prefix like `v1`
7. In your DNS provider (e.g., Route 53), create an **alias/CNAME record** pointing `api.mycompany.com` to the API Gateway domain target shown in the console
8. Verify: `curl https://api.mycompany.com/orders`

---

## Step 11: Set Up Throttling and Usage Plans (REST API Only)

For fine-grained rate limiting per API key/customer, use a **REST API** instead of HTTP API:

1. Create API → **REST API** → **Build**
2. After creating routes and deploying to a stage, go to **Usage Plans** → **Create**
3. Configure:
   - Throttle: rate `10 req/s`, burst `20`
   - Quota: `10,000 requests / month`
4. Associate the usage plan with an **API stage**
5. Create an **API Key** under **API Keys** → **Create API key**
6. Associate the key with the usage plan
7. Require `x-api-key` header on requests; distribute keys to individual consumers/customers

---

## Step 12: Verification Checklist

- [ ] API type chosen appropriately (HTTP API for cost/simplicity, REST API for advanced features)
- [ ] All routes mapped to correct backend integrations
- [ ] Lambda resource-based policy allows API Gateway invocation
- [ ] CORS configured correctly if called from browser frontends
- [ ] Every route has explicit authorization (JWT, Lambda authorizer, IAM, or intentionally public)
- [ ] Named stage (e.g., `prod`) used for production, not relying on `$default` with auto-deploy
- [ ] Throttling limits set to protect backend from traffic spikes
- [ ] Access logging enabled to a dedicated CloudWatch Log Group
- [ ] CloudWatch alarms configured for 4xx/5xx error rates and latency
- [ ] Custom domain configured with valid ACM certificate (if applicable)
- [ ] Tested end-to-end with curl/Postman against the deployed stage URL

---

## Cleanup (To Avoid Ongoing Charges)

1. Delete custom domain mapping: **Custom domain names** → select → **API mappings** → remove mapping, then delete the domain
2. Delete the API: select API → **Actions**/**Delete** → confirm
3. Delete associated CloudWatch Log Groups if no longer needed
4. Remove the Lambda resource-based policy statement if the function is reused elsewhere
5. Delete unused ACM certificates and Route 53 records

> API Gateway itself has no idle cost beyond storage of logs — charges are per-request, but custom domain + ACM + Route 53 records can incur small ongoing DNS costs.

---

## Quick Reference Summary

| Component | Purpose |
|---|---|
| API | Top-level container for routes and stages |
| Route | Maps an HTTP method + path to a backend integration |
| Integration | The backend the route forwards requests to (Lambda, HTTP, etc.) |
| Stage | A named, deployed snapshot of the API (e.g., `dev`, `prod`) |
| Authorizer | Validates caller identity before allowing route access |
| Usage Plan | Rate limiting/quota tied to API keys (REST API only) |
| Custom Domain | Maps a friendly domain name to the API Gateway endpoint |
| Access Logging | Records each request for auditing/debugging |

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| `{"message":"Internal Server Error"}` | Lambda function threw an unhandled exception | Check CloudWatch Logs for the Lambda function |
| `{"message":"Forbidden"}` | Authorizer rejected the request, or missing `x-api-key` | Verify token validity/expiration; confirm API key is attached to usage plan |
| CORS errors in browser console | Preflight `OPTIONS` not handled, or headers misconfigured | Re-check CORS configuration; ensure it covers all needed methods/headers |
| Changes not reflected after editing routes | Stage not redeployed (`$default` with auto-deploy off, or named stage) | Click **Deploy** and select the correct stage |
| 429 Too Many Requests | Throttling limits too low for traffic | Increase stage/route throttle settings, or request a service quota increase |

---

## Next Steps / Advanced Topics

- **WebSocket APIs** — for real-time, bidirectional communication (chat apps, live dashboards)
- **Request/Response transformation (REST API)** — mapping templates (VTL) to reshape payloads between client and backend
- **AWS WAF integration** — protect REST APIs from common web exploits and bot traffic
- **Private APIs** — restrict access to only within a VPC via VPC endpoints
- **Infrastructure as Code** — manage APIs, routes, and stages via Terraform, AWS SAM, or AWS CloudFormation
