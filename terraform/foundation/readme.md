# Terraform Foundations: A Step-by-Step Guide

A ground-up walkthrough of Terraform's core concepts and building blocks — everything you need to understand *how* Terraform works before writing real infrastructure. (Installation is assumed already done.)

---

## Table of Contents

1. [What Terraform Is](#1-what-terraform-is)
2. [HCL Syntax Basics](#2-hcl-syntax-basics)
3. [Providers](#3-providers)
4. [Resources](#4-resources)
5. [Data Sources](#5-data-sources)
6. [Variables](#6-variables)
7. [Outputs](#7-outputs)
8. [Locals](#8-locals)
9. [State](#9-state)
10. [Dependency Graph & Implicit Ordering](#10-dependency-graph--implicit-ordering)
11. [Meta-Arguments: count, for_each, depends_on, lifecycle](#11-meta-arguments-count-for_each-depends_on-lifecycle)
12. [Expressions & Functions](#12-expressions--functions)
13. [Modules](#13-modules)
14. [Putting It All Together](#14-putting-it-all-together)

---

## 1. What Terraform Is

Terraform is an **Infrastructure as Code (IaC)** tool. Instead of clicking through a cloud console to create servers, networks, or databases, you describe the infrastructure you want in configuration files, and Terraform figures out how to create, update, or delete real resources to match that description.

Core ideas:
- **Declarative**: you describe the desired end state, not the steps to get there.
- **Provider-agnostic**: the same workflow works for AWS, Azure, GCP, Kubernetes, GitHub, Datadog, and hundreds of other systems.
- **Stateful**: Terraform keeps a record (the "state file") of what it has created, so it knows what to change on the next run.

---

## 2. HCL Syntax Basics

Terraform configuration is written in **HCL** (HashiCorp Configuration Language), stored in `.tf` files.

### Step 2.1 — The basic block structure

Everything in Terraform is a **block**:

```hcl
<block_type> "<label_1>" "<label_2>" {
  argument = value
}
```

Example:
```hcl
resource "aws_instance" "web" {
  ami           = "ami-0123456789"
  instance_type = "t3.micro"
}
```
- `resource` — the block type
- `"aws_instance"` — the resource type (label 1)
- `"web"` — the local name you give it (label 2)
- Everything inside `{ }` is the block's body

### Step 2.2 — Data types

```hcl
string_example  = "hello"
number_example  = 42
bool_example    = true
list_example    = ["a", "b", "c"]
map_example     = { key1 = "value1", key2 = "value2" }
object_example  = { name = "web", size = 3 }
```

### Step 2.3 — Comments

```hcl
# single line comment
// also a single line comment
/*
  multi-line
  comment
*/
```

---

## 3. Providers

A **provider** is a plugin that lets Terraform talk to a specific platform (AWS, Azure, GCP, Kubernetes, GitHub, etc.).

### Step 3.1 — Declare which providers you need

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

### Step 3.2 — Configure the provider

```hcl
provider "aws" {
  region = "us-east-1"
}
```

### Step 3.3 — Multiple provider configurations (aliasing)

Useful when you need resources in more than one region or account:

```hcl
provider "aws" {
  alias  = "west"
  region = "us-west-2"
}

resource "aws_instance" "west_server" {
  provider      = aws.west
  ami           = "ami-0123456789"
  instance_type = "t3.micro"
}
```

---

## 4. Resources

A **resource** is the fundamental building block — it represents one piece of real infrastructure (a server, a bucket, a DNS record, etc.).

### Step 4.1 — Anatomy of a resource block

```hcl
resource "aws_s3_bucket" "data" {
  bucket = "my-app-data-bucket"

  tags = {
    Environment = "production"
  }
}
```

- `aws_s3_bucket` — the resource **type** (defined by the provider)
- `data` — the local **name**, used to reference this resource elsewhere
- Referencing it elsewhere: `aws_s3_bucket.data.bucket` or `aws_s3_bucket.data.arn`

### Step 4.2 — Referencing one resource from another

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0123456789"
  instance_type = "t3.micro"

  # Reference another resource's attribute
  subnet_id = aws_subnet.main.id
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}
```
Terraform automatically figures out that `aws_subnet.main` must be created before `aws_instance.web` because of this reference — this is the **implicit dependency graph** (more in Section 10).

---

## 5. Data Sources

A **data source** lets you *read* information about existing infrastructure that Terraform did not create — without managing it.

```hcl
data "aws_vpc" "default" {
  default = true
}

resource "aws_instance" "web" {
  ami           = "ami-0123456789"
  instance_type = "t3.micro"
  subnet_id     = data.aws_vpc.default.id
}
```

Note the block type is `data`, not `resource`, and you reference it as `data.<type>.<name>.<attribute>`.

---

## 6. Variables

**Input variables** let you parameterize your configuration instead of hardcoding values.

### Step 6.1 — Declare a variable

```hcl
variable "instance_type" {
  description = "The EC2 instance type to use"
  type        = string
  default     = "t3.micro"
}
```

### Step 6.2 — Common type constraints

```hcl
variable "region"        { type = string }
variable "instance_count"{ type = number }
variable "enable_backup" { type = bool }
variable "tags"          { type = map(string) }
variable "azs"           { type = list(string) }

variable "server_config" {
  type = object({
    name = string
    size = number
  })
}
```

### Step 6.3 — Use a variable in configuration

```hcl
resource "aws_instance" "web" {
  instance_type = var.instance_type
}
```

### Step 6.4 — Ways to supply variable values (in order of precedence, highest last)

1. Default value in the `variable` block
2. `terraform.tfvars` file (auto-loaded)
3. `*.auto.tfvars` files (auto-loaded)
4. `-var-file="custom.tfvars"` flag
5. `-var="key=value"` flag
6. `TF_VAR_<name>` environment variable

### Step 6.5 — Validation rules (optional)

```hcl
variable "instance_type" {
  type = string
  validation {
    condition     = contains(["t3.micro", "t3.small"], var.instance_type)
    error_message = "Instance type must be t3.micro or t3.small."
  }
}
```

---

## 7. Outputs

**Outputs** expose values from your configuration — useful for chaining modules together or just displaying results.

```hcl
output "instance_ip" {
  description = "Public IP of the web server"
  value       = aws_instance.web.public_ip
}

output "instance_arn" {
  value     = aws_instance.web.arn
  sensitive = true   # hides value from CLI output/logs
}
```

---

## 8. Locals

**Local values** are named expressions you can reuse throughout a configuration — like variables, but computed internally rather than passed in.

```hcl
locals {
  common_tags = {
    Project     = "my-app"
    Environment = "production"
  }
  full_name = "${var.project}-${var.environment}"
}

resource "aws_instance" "web" {
  tags = local.common_tags
}
```

---

## 9. State

Terraform's **state file** (`terraform.tfstate`) is a JSON file that maps your configuration to real-world resources. It's how Terraform knows what already exists.

### Step 9.1 — Why state matters

- Tracks resource IDs, attributes, and metadata
- Lets Terraform detect drift (differences between config and real infrastructure)
- Used to compute the diff shown in `terraform plan`

### Step 9.2 — Local vs remote state

- **Local state**: a `terraform.tfstate` file sits in your project folder. Fine for solo experimentation, risky for teams (no locking, easy to lose, may contain secrets in plaintext).
- **Remote state**: stored in a shared backend (S3, Terraform Cloud, Azure Blob, GCS, etc.), with locking so two people can't apply simultaneously.

```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}
```

### Step 9.3 — Never edit state by hand

Use `terraform state mv`, `terraform state rm`, or `terraform import` instead of hand-editing the JSON — a malformed state file can corrupt your infrastructure tracking.

---

## 10. Dependency Graph & Implicit Ordering

Terraform builds a **directed acyclic graph (DAG)** of all resources based on references between them, then creates/updates/destroys resources in the correct order — creating independent resources in parallel where possible.

- **Implicit dependency**: created automatically when one resource references another's attribute (as in Section 4.2).
- **Explicit dependency**: when there's no direct attribute reference but an ordering requirement still exists.

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0123456789"
  instance_type = "t3.micro"

  depends_on = [aws_iam_role_policy.web_policy]
}
```

---

## 11. Meta-Arguments: count, for_each, depends_on, lifecycle

### Step 11.1 — `count`: create multiple similar resources by number

```hcl
resource "aws_instance" "web" {
  count         = 3
  ami           = "ami-0123456789"
  instance_type = "t3.micro"

  tags = {
    Name = "web-${count.index}"
  }
}
```
Reference a specific one: `aws_instance.web[0]`.

### Step 11.2 — `for_each`: create multiple resources from a map or set

```hcl
resource "aws_instance" "web" {
  for_each      = toset(["app1", "app2", "app3"])
  ami           = "ami-0123456789"
  instance_type = "t3.micro"

  tags = {
    Name = each.key
  }
}
```
Reference a specific one: `aws_instance.web["app1"]`.

> `for_each` is generally preferred over `count` when items have distinct identities, since adding/removing an item in the middle of a `count` list can force unrelated resources to be recreated.

### Step 11.3 — `lifecycle`: control creation/destruction behavior

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0123456789"
  instance_type = "t3.micro"

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false
    ignore_changes        = [tags]
  }
}
```

---

## 12. Expressions & Functions

### Step 12.1 — String interpolation

```hcl
name = "web-${var.environment}-${count.index}"
```

### Step 12.2 — Conditional expressions

```hcl
instance_type = var.environment == "production" ? "t3.large" : "t3.micro"
```

### Step 12.3 — Common built-in functions

```hcl
length(var.list)                     # number of items
join(",", var.list)                  # combine list into a string
split(",", var.string)               # string into a list
lookup(var.map, "key", "default")    # safe map lookup
merge(map1, map2)                    # combine two maps
concat(list1, list2)                 # combine two lists
file("path/to/file.txt")             # read a file's contents
jsonencode({ key = "value" })        # convert to JSON string
```

### Step 12.4 — `for` expressions

```hcl
locals {
  upper_names = [for name in var.names : upper(name)]
}
```

---

## 13. Modules

A **module** is a reusable, self-contained group of `.tf` files — think of it as a function for infrastructure.

### Step 13.1 — Anatomy of a module

```
modules/vpc/
├── main.tf       # resources
├── variables.tf  # inputs
└── outputs.tf    # outputs
```

### Step 13.2 — Calling a local module

```hcl
module "vpc" {
  source     = "./modules/vpc"
  cidr_block = "10.0.0.0/16"
}
```

### Step 13.3 — Calling a module from the public registry

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"
}
```

### Step 13.4 — Referencing a module's output

```hcl
resource "aws_instance" "web" {
  subnet_id = module.vpc.public_subnet_ids[0]
}
```

---

## 14. Putting It All Together

Here's a small but complete example that uses most of the concepts above:

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
  region = var.region
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_instance" "web" {
  for_each      = toset(["app1", "app2"])
  ami           = "ami-0123456789"
  instance_type = var.environment == "prod" ? "t3.large" : "t3.micro"
  subnet_id     = data.aws_vpc.default.id

  tags = merge(local.common_tags, { Name = each.key })

  lifecycle {
    create_before_destroy = true
  }
}

output "instance_ids" {
  value = [for i in aws_instance.web : i.id]
}
```

### Concept map — what each piece does

| Concept | Role in the example above |
|---|---|
| `terraform { required_providers }` | Declares the AWS provider |
| `provider "aws"` | Configures region |
| `variable` | Parameterizes region/environment |
| `locals` | Computes reusable tag map |
| `data "aws_vpc"` | Reads existing default VPC |
| `resource ... for_each` | Creates one instance per app name |
| `lifecycle` | Ensures zero-downtime replacement |
| `output` | Exposes created instance IDs |

---

### Where to go next

Once these foundations are solid, the natural next steps are:
- Practicing the actual CLI workflow (`init`, `plan`, `apply`, `destroy`)
- Setting up remote state and locking for team use
- Structuring a real project with environment-specific modules (`envs/dev`, `envs/prod`)
