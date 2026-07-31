# Setting Up AWS CloudFormation — Complete Step-by-Step Guide

AWS CloudFormation is AWS's native Infrastructure as Code (IaC) service — define resources in a YAML/JSON template, and CloudFormation provisions, updates, and tears them down as a single managed unit called a **stack**.

---

## Architecture Overview

```
        template.yaml (VPC, EC2, RDS, IAM...)
                    │
              CloudFormation
                    │
        ┌───────────┴────────────┐
        │         Stack            │
        │  ┌────┐ ┌────┐ ┌────┐   │
        │  │VPC  │ │EC2  │ │RDS  │   │
        │  └────┘ └────┘ └────┘   │
        │                          │
        │  Change Sets → preview    │
        │  Drift Detection           │
        │  Stack Outputs → cross-ref │
        └─────────────────────────┘
```

---

## Prerequisites

- Active AWS account
- IAM user/role with `AWSCloudFormationFullAccess` plus permissions for the resource types you'll create
- Basic YAML familiarity

---

## Step 1: Sign In and Select Region

1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in with IAM credentials
3. Select your target **region**
4. In the search bar, type `CloudFormation` and select **CloudFormation**

---

## Step 2: Write a Template

Create `template.yaml`:

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Description: Simple VPC and EC2 instance

Parameters:
  InstanceType:
    Type: String
    Default: t2.micro
    AllowedValues: [t2.micro, t3.micro, t3.small]

Resources:
  AppVPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      Tags:
        - Key: Name
          Value: cfn-vpc

  PublicSubnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref AppVPC
      CidrBlock: 10.0.1.0/24
      AvailabilityZone: !Select [0, !GetAZs ""]
      MapPublicIpOnLaunch: true

  WebServer:
    Type: AWS::EC2::Instance
    Properties:
      InstanceType: !Ref InstanceType
      ImageId: ami-0abcdef1234567890
      SubnetId: !Ref PublicSubnet
      Tags:
        - Key: Name
          Value: cfn-web-server

Outputs:
  InstancePublicIp:
    Description: Public IP of the web server
    Value: !GetAtt WebServer.PublicIp
  VpcId:
    Value: !Ref AppVPC
    Export:
      Name: cfn-vpc-id
```

### Key Template Sections

| Section | Purpose |
|---|---|
| `Parameters` | Input values supplied at deploy time |
| `Resources` | The AWS resources to create (required) |
| `Outputs` | Values exposed after creation — can be imported by other stacks |
| `Conditions` | Conditional resource creation (e.g., prod vs. dev) |
| `Mappings` | Static lookup tables (e.g., AMI IDs per region) |

---

## Step 3: Validate the Template

```bash
aws cloudformation validate-template --template-body file://template.yaml
```

Fixes syntax errors before attempting a deployment.

---

## Step 4: Create the Stack (Console)

1. **CloudFormation Console** → **Stacks** → **Create stack** → **With new resources (standard)**
2. **Prerequisite**: choose **Template is ready** → **Upload a template file** → select `template.yaml`
3. Click **Next**
4. **Stack details**:
   - Stack name: `orders-app-infra`
   - Parameters: adjust `InstanceType` if needed
5. Click **Next**
6. **Configure stack options**:
   - Tags: add `Environment: Production`
   - **IAM role**: assign a role if CloudFormation needs elevated permissions beyond your user's
   - **Stack failure options**: **Roll back all stack resources** (default, recommended)
   - **Termination protection**: **Enable** for production stacks (prevents accidental deletion)
7. Click **Next** → review → check the acknowledgment box if IAM resources are included → **Submit**
8. Watch the **Events** tab — status progresses `CREATE_IN_PROGRESS` → `CREATE_COMPLETE`

### Alternative: Create via CLI

```bash
aws cloudformation create-stack \
  --stack-name orders-app-infra \
  --template-body file://template.yaml \
  --parameters ParameterKey=InstanceType,ParameterValue=t3.micro \
  --capabilities CAPABILITY_NAMED_IAM
```

---

## Step 5: Preview Changes with Change Sets

Before applying an update to a live stack, preview exactly what will change.

1. Select the stack → **Stack actions** → **Create change set for current stack**
2. Upload the modified template
3. Click **Create change set**
4. Review the **Changes** tab — shows Add/Modify/Remove per resource, and whether a change requires **replacement** (destructive) vs. **in-place update**
5. If acceptable, select the change set → **Execute**

---

## Step 6: Reference Outputs Across Stacks (Cross-Stack References)

1. In the producing stack's template, export a value (already shown in Step 2's `Outputs`)
2. In a consuming stack's template, import it:
   ```yaml
   Resources:
     AppServer:
       Type: AWS::EC2::Instance
       Properties:
         SubnetId: !ImportValue cfn-vpc-id
   ```
3. This lets you split infrastructure into logical stacks (network, database, application) while still wiring them together

---

## Step 7: Use Nested Stacks (For Modular Templates)

```yaml
Resources:
  NetworkStack:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: https://s3.amazonaws.com/my-templates/network.yaml
      Parameters:
        CidrBlock: 10.0.0.0/16
```

Nested stacks let you reuse common templates (e.g., a standard VPC pattern) across multiple parent stacks.

---

## Step 8: Detect and Remediate Drift

Drift occurs when someone manually changes a resource outside CloudFormation.

1. Select the stack → **Stack actions** → **Detect drift**
2. Wait for detection to complete
3. Review the **Drift status** column per resource: `IN_SYNC`, `MODIFIED`, `DELETED`
4. For drifted resources, either manually revert the out-of-band change, or update the template to match reality and redeploy

---

## Step 9: Set Up Stack Policies (Protect Critical Resources)

Prevent specific resources from being accidentally updated/replaced during a stack update.

1. Select the stack → **Edit stack policy**
2. Example — deny replacement of the production database:
   ```json
   {
     "Statement": [
       {
         "Effect": "Deny",
         "Action": "Update:Replace",
         "Principal": "*",
         "Resource": "LogicalResourceId/ProdDatabase"
       },
       {
         "Effect": "Allow",
         "Action": "Update:*",
         "Principal": "*",
         "Resource": "*"
       }
     ]
   }
   ```
3. Click **Save**

---

## Step 10: Delete the Stack

1. Select the stack → **Delete**
2. Confirm — CloudFormation deletes resources in dependency order automatically
3. If deletion fails on a resource (e.g., a non-empty S3 bucket), resolve the blocker (empty the bucket) and retry, or use **Delete** → **Force delete** for stacks stuck in `DELETE_FAILED`

---

## Verification Checklist

- [ ] Template validated before deployment
- [ ] Change sets used to preview updates before executing against live stacks
- [ ] Termination protection enabled on production stacks
- [ ] Stack policies protect critical resources from accidental replacement
- [ ] Outputs/exports used for clean cross-stack references instead of hardcoded ARNs
- [ ] Drift detection run periodically to catch manual out-of-band changes
- [ ] Rollback behavior tested (intentionally trigger a failure in a test stack to confirm rollback works)

---

## Common Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| Stack stuck in `ROLLBACK_COMPLETE` | Initial creation failed; stack can't be updated from this state | Delete the stack and recreate |
| `Insufficient capabilities` error | Template creates IAM resources without acknowledgment | Add `--capabilities CAPABILITY_NAMED_IAM` (CLI) or check the acknowledgment box (console) |
| Update requires replacement unexpectedly | Changed an immutable property (e.g., subnet CIDR) | Check the change set's **Replacement** column before executing; some properties can't be updated in place |
| `DELETE_FAILED` | A resource has dependencies preventing deletion (e.g., non-empty S3 bucket, ENI still attached) | Manually resolve the blocker, then retry delete |

---

## Next Steps / Advanced Topics

- **AWS CDK** — define infrastructure in TypeScript/Python/Java, which synthesizes to CloudFormation templates
- **StackSets** — deploy the same stack across multiple accounts/regions simultaneously
- **Custom Resources** — extend CloudFormation with Lambda-backed logic for unsupported resource types
- **SAM (Serverless Application Model)** — CloudFormation extension simplifying Lambda/API Gateway templates
