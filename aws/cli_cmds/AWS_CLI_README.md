# AWS CLI Command Reference

A practical, categorized reference for the AWS Command Line Interface (CLI v2). Covers setup, configuration, and the most commonly used commands across core AWS services.

---

## Table of Contents

1. [Installation](#installation)
2. [Configuration](#configuration)
3. [IAM (Identity & Access Management)](#iam)
4. [S3 (Simple Storage Service)](#s3)
5. [EC2 (Elastic Compute Cloud)](#ec2)
6. [VPC (Virtual Private Cloud)](#vpc)
7. [Lambda](#lambda)
8. [RDS (Relational Database Service)](#rds)
9. [DynamoDB](#dynamodb)
10. [ECS / ECR (Containers)](#ecs--ecr)
11. [EKS (Kubernetes)](#eks)
12. [CloudFormation](#cloudformation)
13. [CloudWatch (Logs & Metrics)](#cloudwatch)
14. [SNS / SQS (Messaging)](#sns--sqs)
15. [Route 53 (DNS)](#route-53)
16. [Secrets Manager & SSM Parameter Store](#secrets-manager--ssm-parameter-store)
17. [Cost & Billing](#cost--billing)
18. [Useful Global Flags](#useful-global-flags)

---

## Installation

**Linux (x86_64):**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**macOS:**
```bash
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
```

**Windows:**
Download and run the MSI installer:
```
https://awscli.amazonaws.com/AWSCLIV2.msi
```

**Verify installation:**
```bash
aws --version
```

**Upgrade (Linux):**
```bash
sudo ./aws/install --update
```

---

## Configuration

**Interactive setup (creates a default profile):**
```bash
aws configure
```
Prompts for: `AWS Access Key ID`, `AWS Secret Access Key`, `Default region name`, `Default output format` (json, yaml, text, table).

**Configure a named profile:**
```bash
aws configure --profile myprofile
```

**Use a named profile in a command:**
```bash
aws s3 ls --profile myprofile
```

**Set a single config value:**
```bash
aws configure set region us-east-1
aws configure set output json
```

**List all configured profiles:**
```bash
aws configure list-profiles
```

**View current configuration:**
```bash
aws configure list
```

**Config file locations:**
- `~/.aws/credentials` — access keys per profile
- `~/.aws/config` — region/output settings per profile

**Environment variable alternative (no config file needed):**
```bash
export AWS_ACCESS_KEY_ID=xxxx
export AWS_SECRET_ACCESS_KEY=xxxx
export AWS_DEFAULT_REGION=us-east-1
```

**Check who you're authenticated as:**
```bash
aws sts get-caller-identity
```

**Assume an IAM role:**
```bash
aws sts assume-role \
  --role-arn arn:aws:iam::123456789012:role/MyRole \
  --role-session-name mysession
```

---

## IAM

**List users:**
```bash
aws iam list-users
```

**Create a user:**
```bash
aws iam create-user --user-name myuser
```

**Delete a user:**
```bash
aws iam delete-user --user-name myuser
```

**Create an access key for a user:**
```bash
aws iam create-access-key --user-name myuser
```

**List access keys for a user:**
```bash
aws iam list-access-keys --user-name myuser
```

**Attach a managed policy to a user:**
```bash
aws iam attach-user-policy \
  --user-name myuser \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
```

**List roles:**
```bash
aws iam list-roles
```

**Create a role with a trust policy:**
```bash
aws iam create-role \
  --role-name myrole \
  --assume-role-policy-document file://trust-policy.json
```

**List policies attached to a role:**
```bash
aws iam list-attached-role-policies --role-name myrole
```

**Generate an IAM credential report:**
```bash
aws iam generate-credential-report
aws iam get-credential-report --output text --query 'Content' | base64 -d
```

---

## S3

**List all buckets:**
```bash
aws s3 ls
```

**List objects in a bucket:**
```bash
aws s3 ls s3://my-bucket/
aws s3 ls s3://my-bucket/path/ --recursive
```

**Create a bucket:**
```bash
aws s3 mb s3://my-bucket --region us-east-1
```

**Remove an empty bucket:**
```bash
aws s3 rb s3://my-bucket
```

**Remove a bucket and all its contents:**
```bash
aws s3 rb s3://my-bucket --force
```

**Upload a file:**
```bash
aws s3 cp ./localfile.txt s3://my-bucket/path/localfile.txt
```

**Upload a folder recursively:**
```bash
aws s3 cp ./local-folder s3://my-bucket/path/ --recursive
```

**Download a file:**
```bash
aws s3 cp s3://my-bucket/path/file.txt ./file.txt
```

**Sync a local folder to S3 (only changed files):**
```bash
aws s3 sync ./local-folder s3://my-bucket/path/
```

**Sync S3 to local (reverse direction):**
```bash
aws s3 sync s3://my-bucket/path/ ./local-folder
```

**Delete an object:**
```bash
aws s3 rm s3://my-bucket/path/file.txt
```

**Delete all objects under a prefix:**
```bash
aws s3 rm s3://my-bucket/path/ --recursive
```

**Move/rename an object:**
```bash
aws s3 mv s3://my-bucket/old.txt s3://my-bucket/new.txt
```

**Set an object's ACL to public-read:**
```bash
aws s3api put-object-acl --bucket my-bucket --key file.txt --acl public-read
```

**Enable versioning on a bucket:**
```bash
aws s3api put-bucket-versioning \
  --bucket my-bucket \
  --versioning-configuration Status=Enabled
```

**Generate a presigned URL (temporary access link):**
```bash
aws s3 presign s3://my-bucket/path/file.txt --expires-in 3600
```

**Get bucket size / storage metrics (via CloudWatch, not s3 directly):**
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/S3 \
  --metric-name BucketSizeBytes \
  --dimensions Name=BucketName,Value=my-bucket Name=StorageType,Value=StandardStorage \
  --start-time 2026-07-01T00:00:00Z \
  --end-time 2026-07-24T00:00:00Z \
  --period 86400 \
  --statistics Average
```

---

## EC2

**List all instances:**
```bash
aws ec2 describe-instances
```

**List instances with a simplified table output:**
```bash
aws ec2 describe-instances \
  --query 'Reservations[].Instances[].{ID:InstanceId,State:State.Name,Type:InstanceType}' \
  --output table
```

**Launch an instance:**
```bash
aws ec2 run-instances \
  --image-id ami-0abcdef1234567890 \
  --instance-type t3.micro \
  --key-name my-keypair \
  --security-group-ids sg-0123456789abcdef0 \
  --subnet-id subnet-0123456789abcdef0 \
  --count 1
```

**Stop an instance:**
```bash
aws ec2 stop-instances --instance-ids i-0123456789abcdef0
```

**Start an instance:**
```bash
aws ec2 start-instances --instance-ids i-0123456789abcdef0
```

**Reboot an instance:**
```bash
aws ec2 reboot-instances --instance-ids i-0123456789abcdef0
```

**Terminate an instance:**
```bash
aws ec2 terminate-instances --instance-ids i-0123456789abcdef0
```

**Describe available AMIs (owned by you):**
```bash
aws ec2 describe-images --owners self
```

**Create a key pair:**
```bash
aws ec2 create-key-pair --key-name my-keypair \
  --query 'KeyMaterial' --output text > my-keypair.pem
chmod 400 my-keypair.pem
```

**List security groups:**
```bash
aws ec2 describe-security-groups
```

**Create a security group:**
```bash
aws ec2 create-security-group \
  --group-name my-sg \
  --description "My security group" \
  --vpc-id vpc-0123456789abcdef0
```

**Authorize inbound SSH on a security group:**
```bash
aws ec2 authorize-security-group-ingress \
  --group-id sg-0123456789abcdef0 \
  --protocol tcp --port 22 --cidr 0.0.0.0/0
```

**Create an EBS volume:**
```bash
aws ec2 create-volume --availability-zone us-east-1a --size 20 --volume-type gp3
```

**Attach a volume to an instance:**
```bash
aws ec2 attach-volume \
  --volume-id vol-0123456789abcdef0 \
  --instance-id i-0123456789abcdef0 \
  --device /dev/sdf
```

**Create a snapshot of a volume:**
```bash
aws ec2 create-snapshot --volume-id vol-0123456789abcdef0 --description "backup"
```

---

## VPC

**List VPCs:**
```bash
aws ec2 describe-vpcs
```

**Create a VPC:**
```bash
aws ec2 create-vpc --cidr-block 10.0.0.0/16
```

**Create a subnet:**
```bash
aws ec2 create-subnet --vpc-id vpc-0123456789abcdef0 --cidr-block 10.0.1.0/24
```

**List subnets:**
```bash
aws ec2 describe-subnets
```

**Create an internet gateway and attach it:**
```bash
aws ec2 create-internet-gateway
aws ec2 attach-internet-gateway --vpc-id vpc-0123456789abcdef0 --internet-gateway-id igw-0123456789abcdef0
```

**List route tables:**
```bash
aws ec2 describe-route-tables
```

**Add a route to the internet gateway:**
```bash
aws ec2 create-route \
  --route-table-id rtb-0123456789abcdef0 \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id igw-0123456789abcdef0
```

---

## Lambda

**List functions:**
```bash
aws lambda list-functions
```

**Create a function (from a zipped deployment package):**
```bash
aws lambda create-function \
  --function-name my-function \
  --runtime python3.12 \
  --role arn:aws:iam::123456789012:role/lambda-execution-role \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://function.zip
```

**Update function code:**
```bash
aws lambda update-function-code \
  --function-name my-function \
  --zip-file fileb://function.zip
```

**Invoke a function synchronously:**
```bash
aws lambda invoke \
  --function-name my-function \
  --payload '{"key": "value"}' \
  --cli-binary-format raw-in-base64-out \
  response.json
```

**View function configuration:**
```bash
aws lambda get-function --function-name my-function
```

**Delete a function:**
```bash
aws lambda delete-function --function-name my-function
```

**Add an environment variable:**
```bash
aws lambda update-function-configuration \
  --function-name my-function \
  --environment "Variables={KEY=value}"
```

---

## RDS

**List DB instances:**
```bash
aws rds describe-db-instances
```

**Create a DB instance (MySQL example):**
```bash
aws rds create-db-instance \
  --db-instance-identifier mydb \
  --db-instance-class db.t3.micro \
  --engine mysql \
  --master-username admin \
  --master-user-password 'ChangeMe123!' \
  --allocated-storage 20
```

**Stop a DB instance:**
```bash
aws rds stop-db-instance --db-instance-identifier mydb
```

**Start a DB instance:**
```bash
aws rds start-db-instance --db-instance-identifier mydb
```

**Create a manual snapshot:**
```bash
aws rds create-db-snapshot \
  --db-instance-identifier mydb \
  --db-snapshot-identifier mydb-snapshot-1
```

**Delete a DB instance:**
```bash
aws rds delete-db-instance \
  --db-instance-identifier mydb \
  --skip-final-snapshot
```

---

## DynamoDB

**List tables:**
```bash
aws dynamodb list-tables
```

**Create a table:**
```bash
aws dynamodb create-table \
  --table-name MyTable \
  --attribute-definitions AttributeName=Id,AttributeType=S \
  --key-schema AttributeName=Id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

**Put an item:**
```bash
aws dynamodb put-item \
  --table-name MyTable \
  --item '{"Id": {"S": "123"}, "Name": {"S": "example"}}'
```

**Get an item:**
```bash
aws dynamodb get-item \
  --table-name MyTable \
  --key '{"Id": {"S": "123"}}'
```

**Scan a table (all items):**
```bash
aws dynamodb scan --table-name MyTable
```

**Query a table:**
```bash
aws dynamodb query \
  --table-name MyTable \
  --key-condition-expression "Id = :id" \
  --expression-attribute-values '{":id": {"S": "123"}}'
```

**Delete an item:**
```bash
aws dynamodb delete-item \
  --table-name MyTable \
  --key '{"Id": {"S": "123"}}'
```

**Delete a table:**
```bash
aws dynamodb delete-table --table-name MyTable
```

---

## ECS / ECR

**ECR: authenticate Docker to your registry:**
```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com
```

**ECR: create a repository:**
```bash
aws ecr create-repository --repository-name my-app
```

**ECR: list repositories:**
```bash
aws ecr describe-repositories
```

**ECR: push an image:**
```bash
docker tag my-app:latest 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
```

**ECS: list clusters:**
```bash
aws ecs list-clusters
```

**ECS: create a cluster:**
```bash
aws ecs create-cluster --cluster-name my-cluster
```

**ECS: list services in a cluster:**
```bash
aws ecs list-services --cluster my-cluster
```

**ECS: list running tasks:**
```bash
aws ecs list-tasks --cluster my-cluster
```

**ECS: update a service (e.g. after new image push):**
```bash
aws ecs update-service \
  --cluster my-cluster \
  --service my-service \
  --force-new-deployment
```

---

## EKS

**List clusters:**
```bash
aws eks list-clusters
```

**Describe a cluster:**
```bash
aws eks describe-cluster --name my-cluster
```

**Create a cluster:**
```bash
aws eks create-cluster \
  --name my-cluster \
  --role-arn arn:aws:iam::123456789012:role/eks-cluster-role \
  --resources-vpc-config subnetIds=subnet-abc,subnet-def
```

**Update local kubeconfig for kubectl access:**
```bash
aws eks update-kubeconfig --name my-cluster --region us-east-1
```

**List node groups:**
```bash
aws eks list-nodegroups --cluster-name my-cluster
```

**Delete a cluster:**
```bash
aws eks delete-cluster --name my-cluster
```

---

## CloudFormation

**Deploy/update a stack from a template:**
```bash
aws cloudformation deploy \
  --template-file template.yaml \
  --stack-name my-stack \
  --capabilities CAPABILITY_IAM
```

**Create a stack (lower-level, non-idempotent):**
```bash
aws cloudformation create-stack \
  --stack-name my-stack \
  --template-body file://template.yaml
```

**List stacks:**
```bash
aws cloudformation list-stacks
```

**Describe stack status/outputs:**
```bash
aws cloudformation describe-stacks --stack-name my-stack
```

**Delete a stack:**
```bash
aws cloudformation delete-stack --stack-name my-stack
```

**Validate a template:**
```bash
aws cloudformation validate-template --template-body file://template.yaml
```

---

## CloudWatch

**List log groups:**
```bash
aws logs describe-log-groups
```

**Tail log events from a log group:**
```bash
aws logs tail /aws/lambda/my-function --follow
```

**Get log events (non-streaming):**
```bash
aws logs get-log-events \
  --log-group-name /aws/lambda/my-function \
  --log-stream-name 2026/07/24/[LATEST]abc123
```

**Create an alarm:**
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name high-cpu \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --dimensions Name=InstanceId,Value=i-0123456789abcdef0 \
  --alarm-actions arn:aws:sns:us-east-1:123456789012:my-topic
```

**List alarms:**
```bash
aws cloudwatch describe-alarms
```

---

## SNS / SQS

**SNS: create a topic:**
```bash
aws sns create-topic --name my-topic
```

**SNS: subscribe an email endpoint:**
```bash
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:123456789012:my-topic \
  --protocol email \
  --notification-endpoint me@example.com
```

**SNS: publish a message:**
```bash
aws sns publish \
  --topic-arn arn:aws:sns:us-east-1:123456789012:my-topic \
  --message "Hello from AWS CLI"
```

**SQS: create a queue:**
```bash
aws sqs create-queue --queue-name my-queue
```

**SQS: send a message:**
```bash
aws sqs send-message \
  --queue-url https://sqs.us-east-1.amazonaws.com/123456789012/my-queue \
  --message-body "Hello"
```

**SQS: receive messages:**
```bash
aws sqs receive-message \
  --queue-url https://sqs.us-east-1.amazonaws.com/123456789012/my-queue
```

**SQS: delete a message (after processing, using its receipt handle):**
```bash
aws sqs delete-message \
  --queue-url https://sqs.us-east-1.amazonaws.com/123456789012/my-queue \
  --receipt-handle AQEB...
```

---

## Route 53

**List hosted zones:**
```bash
aws route53 list-hosted-zones
```

**List records in a zone:**
```bash
aws route53 list-resource-record-sets --hosted-zone-id Z1234567890
```

**Create/update a DNS record (via a change batch file):**
```bash
aws route53 change-resource-record-sets \
  --hosted-zone-id Z1234567890 \
  --change-batch file://record-change.json
```

Example `record-change.json`:
```json
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "app.example.com",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "203.0.113.10"}]
    }
  }]
}
```

---

## Secrets Manager & SSM Parameter Store

**Secrets Manager: create a secret:**
```bash
aws secretsmanager create-secret \
  --name my-secret \
  --secret-string '{"username":"admin","password":"changeme"}'
```

**Secrets Manager: retrieve a secret:**
```bash
aws secretsmanager get-secret-value --secret-id my-secret
```

**SSM: put a parameter:**
```bash
aws ssm put-parameter \
  --name "/myapp/db/password" \
  --value "changeme" \
  --type SecureString
```

**SSM: get a parameter:**
```bash
aws ssm get-parameter --name "/myapp/db/password" --with-decryption
```

**SSM: list parameters under a path:**
```bash
aws ssm get-parameters-by-path --path "/myapp/" --recursive
```

---

## Cost & Billing

**Get cost and usage for the current month:**
```bash
aws ce get-cost-and-usage \
  --time-period Start=2026-07-01,End=2026-07-24 \
  --granularity MONTHLY \
  --metrics "UnblendedCost"
```

**Get cost forecast:**
```bash
aws ce get-cost-forecast \
  --time-period Start=2026-07-25,End=2026-08-24 \
  --metric UNBLENDED_COST \
  --granularity MONTHLY
```

---

## Useful Global Flags

These work with almost any `aws` command:

| Flag | Purpose |
|---|---|
| `--profile <name>` | Use a specific named credentials profile |
| `--region <region>` | Override the default region for this call |
| `--output json\|yaml\|text\|table` | Control output format |
| `--query '<JMESPath expression>'` | Filter/reshape output (JMESPath syntax) |
| `--dry-run` | Validate permissions/parameters without making the change (supported on many EC2 calls) |
| `--no-paginate` | Return all results in one call instead of paginating |
| `--debug` | Verbose debug output — useful for troubleshooting auth/API errors |

**Example combining flags:**
```bash
aws ec2 describe-instances \
  --profile prod \
  --region eu-west-1 \
  --query 'Reservations[].Instances[].InstanceId' \
  --output text
```

---

## Notes

- Replace all example IDs (`i-0123...`, `vpc-0123...`, account `123456789012`, etc.) with your actual resource identifiers.
- Commands that create billable resources (EC2, RDS, NAT gateways, etc.) will incur AWS charges — clean up test resources when done.
- Always double-check `--region` before running destructive commands (`terminate-instances`, `delete-*`) — the CLI defaults to your configured region, not necessarily where the resource lives.
- For destructive commands, consider testing with `--dry-run` first where supported.
