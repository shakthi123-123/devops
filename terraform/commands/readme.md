# Terraform Commands: Step-by-Step Guide

A detailed walkthrough of Terraform commands in the order you'd typically use them, from project setup to teardown.

---

## Table of Contents

1. [Setup Commands](#1-setup-commands)
2. [Core Workflow Commands](#2-core-workflow-commands)
3. [Inspecting State](#3-inspecting-state)
4. [Formatting & Validation](#4-formatting--validation)
5. [Working with Variables](#5-working-with-variables)
6. [Modules & Workspaces](#6-modules--workspaces)
7. [Importing & Modifying Existing Resources](#7-importing--modifying-existing-resources)
8. [Destroying Infrastructure](#8-destroying-infrastructure)
9. [Debugging Commands](#9-debugging-commands)
10. [Full Command Reference Table](#10-full-command-reference-table)

---

## 1. Setup Commands

### Step 1.1 — Check Terraform is installed

```bash
terraform -version
```
Confirms the installed version and lists loaded provider versions (if run inside a project).

### Step 1.2 — Create a project directory

```bash
mkdir my-terraform-project
cd my-terraform-project
```

### Step 1.3 — Create your configuration file(s)

```bash
touch main.tf
```
Add your `provider`, `resource`, and `terraform` blocks here.

### Step 1.4 — Initialize the working directory

```bash
terraform init
```
What this does:
- Downloads provider plugins declared in your config
- Sets up the `.terraform` directory
- Configures the backend (local by default, or remote if specified)
- Creates/updates `.terraform.lock.hcl` to pin provider versions

Re-run this any time you:
- Add/change a provider
- Add/change a module source
- Change your backend configuration (add `-migrate-state` or `-reconfigure` as needed)

```bash
terraform init -upgrade        # upgrade providers/modules to latest allowed versions
terraform init -reconfigure    # reconfigure backend without migrating state
terraform init -migrate-state  # migrate existing state to a new backend
```

---

## 2. Core Workflow Commands

### Step 2.1 — Preview changes with `plan`

```bash
terraform plan
```
Shows what Terraform **will** do — resources to add (`+`), change (`~`), or destroy (`-`) — without touching real infrastructure.

Useful flags:
```bash
terraform plan -out=tfplan          # save the plan to a file for later apply
terraform plan -var="region=us-west-2"   # override a variable inline
terraform plan -var-file="prod.tfvars"   # use a specific variable file
terraform plan -target=aws_instance.web  # plan only a specific resource
terraform plan -destroy             # preview what a destroy would do
```

### Step 2.2 — Apply changes

```bash
terraform apply
```
Terraform re-runs the plan, shows it to you, and asks for confirmation:
```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

Common flags:
```bash
terraform apply tfplan              # apply a previously saved plan file
terraform apply -auto-approve       # skip the yes/no confirmation (use carefully, e.g. in CI)
terraform apply -var="instance_type=t3.small"
terraform apply -target=aws_s3_bucket.demo   # apply only one resource
```

> ⚠️ Always review the plan output before typing `yes`. Look for unexpected `-` (destroy) actions.

---

## 3. Inspecting State

### Step 3.1 — List all resources being tracked

```bash
terraform state list
```

### Step 3.2 — Show details of a specific resource

```bash
terraform state show aws_instance.web
```

### Step 3.3 — Show the full current state (human-readable)

```bash
terraform show
```

```bash
terraform show -json > state.json    # export state as JSON
```

### Step 3.4 — View output values

```bash
terraform output
terraform output instance_public_ip     # a single output
terraform output -json                  # machine-readable
```

### Step 3.5 — Move a resource within state (e.g. after renaming)

```bash
terraform state mv aws_instance.old_name aws_instance.new_name
```

### Step 3.6 — Remove a resource from state (without destroying it)

```bash
terraform state rm aws_instance.web
```
Useful when you want Terraform to "forget" a resource but leave the real infrastructure untouched.

### Step 3.7 — Pull/push raw state (remote backends)

```bash
terraform state pull > backup.tfstate   # download current state
terraform state push backup.tfstate     # upload a modified state file (use with caution)
```

---

## 4. Formatting & Validation

### Step 4.1 — Auto-format your `.tf` files

```bash
terraform fmt
```
```bash
terraform fmt -recursive     # format all files in subdirectories too
terraform fmt -check         # only check, don't modify (useful in CI)
```

### Step 4.2 — Validate syntax and internal consistency

```bash
terraform validate
```
Catches errors like missing required arguments or type mismatches — but does **not** check against live cloud state.

---

## 5. Working with Variables

### Step 5.1 — Pass variables via command line

```bash
terraform apply -var="bucket_name=my-bucket" -var="region=us-east-1"
```

### Step 5.2 — Use a `.tfvars` file

Create `terraform.tfvars` (auto-loaded) or a custom file:
```hcl
bucket_name = "my-bucket"
region      = "us-east-1"
```

```bash
terraform apply -var-file="terraform.tfvars"
terraform apply -var-file="staging.tfvars"
```

### Step 5.3 — Use environment variables

```bash
export TF_VAR_bucket_name="my-bucket"
export TF_VAR_region="us-east-1"
terraform apply
```

---

## 6. Modules & Workspaces

### Step 6.1 — Download/update module dependencies

```bash
terraform get
terraform get -update
```
(Usually handled automatically by `terraform init`, but useful standalone.)

### Step 6.2 — Workspace commands (for managing multiple environments)

```bash
terraform workspace list              # list all workspaces
terraform workspace show              # show the current workspace
terraform workspace new staging       # create a new workspace
terraform workspace select staging    # switch to a workspace
terraform workspace delete staging    # delete a workspace
```

Reference the current workspace inside your config:
```hcl
resource "aws_instance" "web" {
  tags = {
    Environment = terraform.workspace
  }
}
```

---

## 7. Importing & Modifying Existing Resources

### Step 7.1 — Import an existing resource into Terraform state

```bash
terraform import aws_instance.web i-0123456789abcdef0
```
This brings a manually-created resource under Terraform management. You still need to write the matching `resource` block in your `.tf` file yourself.

### Step 7.2 — Force a resource to be recreated

```bash
terraform apply -replace="aws_instance.web"
```
(This replaces the older `terraform taint` command in modern Terraform versions.)

### Step 7.3 — (Legacy) Taint/untaint a resource

```bash
terraform taint aws_instance.web       # mark for recreation on next apply
terraform untaint aws_instance.web     # undo that mark
```

---

## 8. Destroying Infrastructure

### Step 8.1 — Preview what would be destroyed

```bash
terraform plan -destroy
```

### Step 8.2 — Destroy everything managed by this config

```bash
terraform destroy
```
```bash
terraform destroy -auto-approve             # skip confirmation
terraform destroy -target=aws_instance.web  # destroy only one resource
```

---

## 9. Debugging Commands

### Step 9.1 — Enable verbose logging

```bash
export TF_LOG=DEBUG
terraform apply
```
Levels (least to most verbose): `TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR`.

```bash
export TF_LOG_PATH="./terraform.log"    # write logs to a file
```

### Step 9.2 — Interactive expression console

```bash
terraform console
```
```
> var.region
"us-east-1"
> aws_instance.web.public_ip
"3.92.14.55"
```
Type `exit` or `Ctrl+D` to leave.

### Step 9.3 — Graph the resource dependency tree

```bash
terraform graph | dot -Tpng > graph.png
```
(Requires Graphviz's `dot` command installed.)

---

## 10. Full Command Reference Table

| Command | Purpose |
|---|---|
| `terraform init` | Initialize directory, download providers/modules |
| `terraform fmt` | Auto-format configuration files |
| `terraform validate` | Check syntax and internal validity |
| `terraform plan` | Preview changes |
| `terraform apply` | Apply changes to real infrastructure |
| `terraform destroy` | Remove all managed infrastructure |
| `terraform state list` | List resources tracked in state |
| `terraform state show <addr>` | Show details of one resource |
| `terraform state mv <src> <dst>` | Rename/move a resource in state |
| `terraform state rm <addr>` | Remove a resource from state (keeps real infra) |
| `terraform state pull` / `push` | Download/upload raw state |
| `terraform show` | Human-readable current state |
| `terraform output` | Show output values |
| `terraform import <addr> <id>` | Bring existing infra under management |
| `terraform apply -replace=<addr>` | Force recreation of a resource |
| `terraform taint` / `untaint` | (Legacy) mark/unmark for recreation |
| `terraform workspace *` | Manage environments/workspaces |
| `terraform console` | Interactive expression evaluator |
| `terraform graph` | Output dependency graph (DOT format) |
| `terraform get` | Download/update module dependencies |
| `terraform version` | Show installed Terraform + provider versions |

---

### Typical end-to-end sequence

```bash
terraform init
terraform fmt
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
terraform output
# ...later, when done:
terraform destroy
```
