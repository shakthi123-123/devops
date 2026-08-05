# Terraform: Complete Step-by-Step Guide

A practical guide covering installation, the core workflow, deploying real infrastructure on AWS, and best practices for using Terraform in production.

---

## Table of Contents

1. [Installing Terraform](#1-installing-terraform)
2. [Core Workflow: init, plan, apply, destroy](#2-core-workflow-init-plan-apply-destroy)
3. [Deploying Infrastructure on AWS](#3-deploying-infrastructure-on-aws)
4. [Best Practices: Modules, State, Workspaces](#4-best-practices-modules-state-workspaces)
5. [Cheat Sheet](#5-cheat-sheet)

---

## 1. Installing Terraform

### macOS (Homebrew)

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

### Windows (Chocolatey)

```powershell
choco install terraform
```

### Linux (Debian/Ubuntu)

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

### Manual install (any OS)

1. Download the binary for your OS from the [official Terraform downloads page](https://developer.hashicorp.com/terraform/install).
2. Unzip it.
3. Move the `terraform` binary into a directory on your `PATH`, e.g.:
   ```bash
   sudo mv terraform /usr/local/bin/
   ```

### Verify installation

```bash
terraform -version
```

You should see output like:
```
Terraform v1.9.x
on linux_amd64
```

---

## 2. Core Workflow: init, plan, apply, destroy

Terraform's workflow always follows the same four steps: **write → init → plan → apply**.

### Step 1 — Create a project folder

```bash
mkdir terraform-demo && cd terraform-demo
```

### Step 2 — Write your first configuration file

Create a file named `main.tf`:

```hcl
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

resource "local_file" "hello" {
  filename = "${path.module}/hello.txt"
  content  = "Hello from Terraform!"
}
```

This example uses the `local` provider (no cloud account needed) so you can test the workflow risk-free.

### Step 3 — Initialize the working directory

```bash
terraform init
```

This downloads the provider plugins declared in `required_providers` and sets up the `.terraform` directory.

### Step 4 — Preview the changes

```bash
terraform plan
```

Terraform shows what it **will** do without actually doing it — look for a summary like:
```
Plan: 1 to add, 0 to change, 0 to destroy.
```

### Step 5 — Apply the changes

```bash
terraform apply
```

Type `yes` when prompted. Terraform creates `hello.txt` in your folder.

### Step 6 — Inspect state

```bash
terraform show
terraform state list
```

### Step 7 — Destroy resources when done

```bash
terraform destroy
```

Type `yes` to confirm. This tears down everything Terraform created.

---

## 3. Deploying Infrastructure on AWS

This example provisions an S3 bucket and an EC2 instance on AWS.

### Prerequisites

- An AWS account
- AWS CLI installed and configured:
  ```bash
  aws configure
  ```
  (You'll need an Access Key ID and Secret Access Key from IAM.)

### Step 1 — Project structure

```bash
mkdir terraform-aws-demo && cd terraform-aws-demo
touch main.tf variables.tf outputs.tf terraform.tfvars
```

### Step 2 — Define the provider (`main.tf`)

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

### Step 3 — Define variables (`variables.tf`)

```hcl
variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
```

### Step 4 — Set variable values (`terraform.tfvars`)

```hcl
bucket_name = "my-unique-terraform-demo-bucket-2026"
```

### Step 5 — Add resources to `main.tf`

```hcl
resource "aws_s3_bucket" "demo" {
  bucket = var.bucket_name

  tags = {
    Environment = "demo"
    ManagedBy   = "terraform"
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "demo" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  tags = {
    Name = "terraform-demo-instance"
  }
}
```

### Step 6 — Define outputs (`outputs.tf`)

```hcl
output "bucket_name" {
  value = aws_s3_bucket.demo.bucket
}

output "instance_public_ip" {
  value = aws_instance.demo.public_ip
}
```

### Step 7 — Run the workflow

```bash
terraform init
terraform fmt        # auto-formats your files
terraform validate   # checks syntax
terraform plan -out=tfplan
terraform apply tfplan
```

### Step 8 — Confirm and clean up

```bash
terraform output              # view outputs (bucket name, IP)
terraform destroy             # tear everything down when finished
```

> ⚠️ **Cost warning:** EC2 instances and some AWS resources incur charges. Always run `terraform destroy` after testing.

---

## 4. Best Practices: Modules, State, Workspaces

### 4.1 Use remote state (don't keep state local in a team setting)

Local `terraform.tfstate` files are dangerous for teams — no locking, no history, easy to lose. Use a remote backend, e.g. S3 + DynamoDB for locking:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "prod/network/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

Steps to set this up:
1. Create the S3 bucket and DynamoDB table manually (or via a separate "bootstrap" Terraform config) **before** referencing them as a backend.
2. Add the `backend "s3"` block above.
3. Run:
   ```bash
   terraform init -migrate-state
   ```

### 4.2 Structure code with modules

Instead of one giant `main.tf`, break infrastructure into reusable modules.

```
project/
├── main.tf
├── variables.tf
├── outputs.tf
└── modules/
    └── vpc/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

Call a module from your root config:

```hcl
module "vpc" {
  source     = "./modules/vpc"
  cidr_block = "10.0.0.0/16"
}
```

Best practices for modules:
- Keep modules focused on one concern (e.g., `vpc`, `ec2-cluster`, `rds`).
- Version modules pulled from a registry: `source = "terraform-aws-modules/vpc/aws" version = "5.1.0"`.
- Always define `variables.tf` (inputs) and `outputs.tf` (what the module exposes).

### 4.3 Use workspaces for environment separation (small projects)

```bash
terraform workspace new staging
terraform workspace new production
terraform workspace select staging
terraform apply
```

> Note: For larger teams, **separate state files/directories per environment** (e.g. `envs/staging`, `envs/prod`) are usually preferred over workspaces, since workspaces share the same backend config and can be easy to apply against the wrong environment by accident.

### 4.4 Never hardcode secrets

- Don't put AWS keys, passwords, or tokens directly in `.tf` files.
- Use environment variables, a secrets manager (AWS Secrets Manager, Vault), or `-var` flags pulled from a secure CI/CD pipeline.
- Add to `.gitignore`:
  ```
  *.tfstate
  *.tfstate.backup
  .terraform/
  *.tfvars
  ```

### 4.5 Lock provider versions

Pin versions to avoid surprise breaking changes:

```hcl
terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.55.0"   # exact pin, not "~>"
    }
  }
}
```

Commit the generated `.terraform.lock.hcl` file to version control.

### 4.6 Use `terraform plan` in CI before every apply

A typical CI/CD pattern:
1. On pull request → run `terraform fmt -check`, `terraform validate`, `terraform plan`.
2. Post the plan output as a PR comment for review.
3. On merge to main → run `terraform apply` (often with manual approval gate).

### 4.7 Tag everything

Consistent tagging makes cost tracking and cleanup far easier:

```hcl
default_tags {
  tags = {
    Project     = "my-app"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```
(Place inside the `provider "aws"` block to apply to all resources automatically.)

---

## 5. Cheat Sheet

| Command | Purpose |
|---|---|
| `terraform init` | Initialize working directory, download providers |
| `terraform fmt` | Auto-format `.tf` files |
| `terraform validate` | Check syntax/config validity |
| `terraform plan` | Preview changes |
| `terraform apply` | Apply changes |
| `terraform destroy` | Tear down all managed resources |
| `terraform state list` | List resources in state |
| `terraform show` | Show current state in human-readable form |
| `terraform output` | Show output values |
| `terraform workspace list` | List workspaces |
| `terraform import <addr> <id>` | Bring existing infra under Terraform management |
| `terraform taint <addr>` | Force a resource to be recreated on next apply |
| `terraform console` | Interactive expression evaluator |

---

### Next steps

- Explore the [Terraform Registry](https://registry.terraform.io/) for pre-built modules and providers.
- Look into **Terraform Cloud** or **Atlantis** for managed remote state + CI/CD workflows at scale.
- Read up on `for_each` and `count` for creating multiple similar resources without duplicating code.
