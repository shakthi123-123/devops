# GitLab: Complete Step-by-Step Guide

A practical guide covering self-hosted GitLab installation, initial setup, project/repo basics, merge requests, CI/CD pipelines, GitLab Runners, and best practices.

---

## Table of Contents

1. [Installing GitLab (Self-Hosted)](#1-installing-gitlab-self-hosted)
2. [Initial Setup](#2-initial-setup)
3. [GitLab Concepts Overview](#3-gitlab-concepts-overview)
4. [Creating Your First Project](#4-creating-your-first-project)
5. [Working with Git + Merge Requests](#5-working-with-git--merge-requests)
6. [Setting Up a GitLab Runner](#6-setting-up-a-gitlab-runner)
7. [Building a CI/CD Pipeline (.gitlab-ci.yml)](#7-building-a-cicd-pipeline-gitlab-ciyml)
8. [Managing Variables & Secrets](#8-managing-variables--secrets)
9. [Environments & Deployments](#9-environments--deployments)
10. [Best Practices](#10-best-practices)
11. [Cheat Sheet](#11-cheat-sheet)

---

## 1. Installing GitLab (Self-Hosted)

> If you're using **gitlab.com** (SaaS), skip to [Section 2](#2-initial-setup) — just sign up at [gitlab.com](https://gitlab.com).

### Option A — Ubuntu/Debian (Omnibus package)

```bash
# Install dependencies
sudo apt update
sudo apt install -y curl openssh-server ca-certificates tzdata perl

# (Optional but recommended) Install Postfix for email notifications
sudo apt install -y postfix

# Add the GitLab package repository
curl -fsSL https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash

# Install GitLab, setting the external URL
sudo EXTERNAL_URL="http://gitlab.example.com" apt install -y gitlab-ee
```

GitLab automatically runs its configuration (`gitlab-ctl reconfigure`) at the end of installation.

### Option B — Docker

```bash
docker run --detach \
  --hostname gitlab.example.com \
  --publish 443:443 --publish 80:80 --publish 22:22 \
  --name gitlab \
  --restart always \
  --volume $PWD/gitlab/config:/etc/gitlab \
  --volume $PWD/gitlab/logs:/var/log/gitlab \
  --volume $PWD/gitlab/data:/var/opt/gitlab \
  --shm-size 256m \
  gitlab/gitlab-ee:latest
```

Give it a few minutes to initialize:

```bash
docker logs -f gitlab
```

### Option C — Docker Compose (recommended for repeatable setups)

Create `docker-compose.yml`:

```yaml
version: '3.6'
services:
  gitlab:
    image: gitlab/gitlab-ee:latest
    container_name: gitlab
    restart: always
    hostname: 'gitlab.example.com'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://gitlab.example.com'
    ports:
      - '80:80'
      - '443:443'
      - '22:22'
    volumes:
      - './config:/etc/gitlab'
      - './logs:/var/log/gitlab'
      - './data:/var/opt/gitlab'
    shm_size: '256m'
```

```bash
docker compose up -d
```

### Verify installation

```bash
sudo gitlab-ctl status      # apt install
docker exec gitlab gitlab-ctl status   # docker install
```

Then open a browser to your configured URL (e.g. `http://gitlab.example.com` or `http://localhost`).

---

## 2. Initial Setup

### Step 2.1 — Retrieve the initial root password

**Self-hosted (first 24 hours only):**
```bash
sudo cat /etc/gitlab/initial_root_password
```
```bash
docker exec gitlab cat /etc/gitlab/initial_root_password
```

**gitlab.com:** just register a new account directly — no root password needed.

### Step 2.2 — Log in

- Username: `root`
- Password: from Step 2.1

### Step 2.3 — Change the root password immediately

**User menu (top right) → Edit profile → Password**

### Step 2.4 — Set up two-factor authentication (recommended)

**User menu → Edit profile → Account → Enable Two-Factor Authentication**

### Step 2.5 — Create your first group (optional but recommended)

Groups organize related projects (like a GitHub "organization").

**Left sidebar → Groups → New group → Create group**
- Group name: e.g. `my-team`
- Visibility: Private / Internal / Public

---

## 3. GitLab Concepts Overview

| Term | Meaning |
|---|---|
| **Project** | A single Git repository plus its issues, wiki, CI/CD, etc. |
| **Group** | A collection of projects (like a folder/organization) |
| **Merge Request (MR)** | GitLab's term for a pull request |
| **Pipeline** | A CI/CD run, made of stages and jobs |
| **Stage** | A phase in a pipeline (e.g. build, test, deploy) |
| **Job** | A single task within a stage (runs in its own container/shell) |
| **Runner** | The agent that actually executes pipeline jobs |
| **.gitlab-ci.yml** | The YAML file defining your pipeline, committed to the repo |
| **Environment** | A named deployment target (e.g. staging, production) tracked by GitLab |
| **Issue Board** | Kanban-style board for tracking issues |

---

## 4. Creating Your First Project

### Step 4.1 — Create a new project

**Left sidebar → Projects → New project → Create blank project**

Fill in:
- Project name: e.g. `hello-world`
- Project URL: choose namespace (your username or a group)
- Visibility level: Private / Internal / Public
- Check **Initialize repository with a README**

Click **Create project**.

### Step 4.2 — Clone the repo locally

```bash
git clone http://gitlab.example.com/your-namespace/hello-world.git
cd hello-world
```

(Or clone via SSH — see Step 4.3.)

### Step 4.3 — Add an SSH key (recommended over HTTPS)

```bash
# Generate a key if you don't have one
ssh-keygen -t ed25519 -C "you@example.com"

# Copy the public key
cat ~/.ssh/id_ed25519.pub
```

**GitLab UI: User menu → Edit profile → SSH Keys → paste key → Add key**

Then clone via SSH:
```bash
git clone git@gitlab.example.com:your-namespace/hello-world.git
```

### Step 4.4 — Make your first commit

```bash
echo "# Hello World" >> README.md
git add README.md
git commit -m "Update README"
git push origin main
```

---

## 5. Working with Git + Merge Requests

### Step 5.1 — Create a feature branch

```bash
git checkout -b feature/add-login
```

### Step 5.2 — Make changes and push

```bash
git add .
git commit -m "Add login page"
git push origin feature/add-login
```

### Step 5.3 — Open a Merge Request

After pushing, GitLab shows a direct link in the terminal output, or:

**Project → Merge Requests → New merge request**
1. Source branch: `feature/add-login`
2. Target branch: `main`
3. Add a title and description
4. Assign a reviewer
5. Click **Create merge request**

### Step 5.4 — Review process

- Reviewers leave inline comments on the **Changes** tab.
- Push additional commits to the same branch to update the MR automatically.
- Use **Resolve thread** once feedback is addressed.

### Step 5.5 — Merge

Once approved and pipeline passes:
**Merge request page → Merge**

Optional settings before merging:
- ☑ Delete source branch
- ☑ Squash commits

---

## 6. Setting Up a GitLab Runner

Runners execute the jobs defined in your pipeline. GitLab.com provides shared runners by default; self-hosted instances need at least one runner registered.

### Step 6.1 — Install GitLab Runner (on the machine that will run jobs)

```bash
# Add the runner repository
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash

# Install
sudo apt install -y gitlab-runner
```

### Step 6.2 — Get a registration token

**Project → Settings → CI/CD → Runners → expand "Project runners"** (or Group/Instance level for shared runners) → copy the registration token.

### Step 6.3 — Register the runner

```bash
sudo gitlab-runner register
```

You'll be prompted for:
- GitLab instance URL: `http://gitlab.example.com`
- Registration token: (from Step 6.2)
- Description: e.g. `docker-runner-1`
- Tags: e.g. `docker,linux`
- Executor: choose `docker` (recommended), `shell`, `kubernetes`, etc.
- Default Docker image (if executor is `docker`): e.g. `alpine:latest`

### Step 6.4 — Verify the runner is active

**Project → Settings → CI/CD → Runners** — you should see it listed as "Available."

### Step 6.5 — Start the runner service

```bash
sudo gitlab-runner start
sudo gitlab-runner status
```

---

## 7. Building a CI/CD Pipeline (.gitlab-ci.yml)

### Step 7.1 — Create the pipeline file

In your project root, create `.gitlab-ci.yml`:

```yaml
stages:
  - build
  - test
  - deploy

build-job:
  stage: build
  script:
    - echo "Building the application..."
    - echo "Build complete."

test-job:
  stage: test
  script:
    - echo "Running tests..."
    - echo "Tests passed."

deploy-job:
  stage: deploy
  script:
    - echo "Deploying application..."
  only:
    - main
```

### Step 7.2 — Commit and push

```bash
git add .gitlab-ci.yml
git commit -m "Add CI/CD pipeline"
git push origin main
```

### Step 7.3 — Watch the pipeline run

**Project → Build → Pipelines** — you'll see the pipeline execute stage by stage.

### Step 7.4 — A real-world example (Node.js app)

```yaml
image: node:20

stages:
  - install
  - test
  - build
  - deploy

cache:
  paths:
    - node_modules/

install-deps:
  stage: install
  script:
    - npm install

run-tests:
  stage: test
  script:
    - npm test

build-app:
  stage: build
  script:
    - npm run build
  artifacts:
    paths:
      - dist/

deploy-prod:
  stage: deploy
  script:
    - echo "Deploying to production..."
    - ./deploy.sh
  only:
    - main
  environment:
    name: production
```

### Step 7.5 — Parallel jobs within a stage

Jobs in the **same stage** run in parallel automatically if resources allow:

```yaml
test:
  stage: test
  script:
    - npm run test:unit

lint:
  stage: test
  script:
    - npm run lint
```

### Step 7.6 — Conditional jobs with `rules`

```yaml
deploy-staging:
  stage: deploy
  script:
    - ./deploy.sh staging
  rules:
    - if: '$CI_COMMIT_BRANCH == "develop"'

deploy-production:
  stage: deploy
  script:
    - ./deploy.sh production
  rules:
    - if: '$CI_COMMIT_BRANCH == "main"'
      when: manual
```

### Step 7.7 — Using templates/includes for reuse

```yaml
include:
  - local: '.gitlab/ci/build.yml'
  - local: '.gitlab/ci/test.yml'
```

### Step 7.8 — Validate your CI file before committing

**Project → Build → Pipeline editor** has a built-in linter, or via CLI:
```bash
curl --header "PRIVATE-TOKEN: <your_token>" \
  --data "content=$(cat .gitlab-ci.yml)" \
  "http://gitlab.example.com/api/v4/ci/lint"
```

---

## 8. Managing Variables & Secrets

### Step 8.1 — Add a CI/CD variable

**Project → Settings → CI/CD → Variables → Add variable**

- Key: e.g. `DEPLOY_TOKEN`
- Value: (the secret)
- Type: Variable (or File, for larger secrets like a kubeconfig)
- ☑ Protect variable (only exposed on protected branches/tags)
- ☑ Mask variable (hides value in job logs)

### Step 8.2 — Use it in `.gitlab-ci.yml`

```yaml
deploy-job:
  stage: deploy
  script:
    - echo "Deploying with token..."
    - curl -H "Authorization: Bearer $DEPLOY_TOKEN" https://api.example.com/deploy
```

### Step 8.3 — Built-in predefined variables

GitLab automatically provides variables like:
```
$CI_COMMIT_BRANCH
$CI_COMMIT_SHA
$CI_PROJECT_NAME
$CI_PIPELINE_ID
$CI_JOB_NAME
```

---

## 9. Environments & Deployments

### Step 9.1 — Define an environment in a job

```yaml
deploy-staging:
  stage: deploy
  script:
    - ./deploy.sh staging
  environment:
    name: staging
    url: https://staging.example.com
```

### Step 9.2 — View environments

**Project → Operate → Environments** — shows deployment history, current status, and a **Stop** button for tearing down.

### Step 9.3 — Manual deployment approval gate

```yaml
deploy-production:
  stage: deploy
  script:
    - ./deploy.sh production
  environment:
    name: production
  when: manual
```

This adds a "play" button in the pipeline UI that a team member must click to trigger the deploy.

---

## 10. Best Practices

### 10.1 — Keep `.gitlab-ci.yml` in version control (it already is by default)

Treat pipeline changes like code — review them in merge requests too.

### 10.2 — Use `rules` over `only`/`except`

`rules` is the modern, more flexible way to control when jobs run; `only`/`except` are legacy.

### 10.3 — Cache dependencies to speed up pipelines

```yaml
cache:
  key: ${CI_COMMIT_REF_SLUG}
  paths:
    - node_modules/
    - .cache/pip
```

### 10.4 — Use `artifacts` to pass files between stages

```yaml
build:
  stage: build
  script: npm run build
  artifacts:
    paths:
      - dist/
    expire_in: 1 week
```

### 10.5 — Protect important branches

**Project → Settings → Repository → Protected branches** — restrict who can push/merge to `main`.

### 10.6 — Require approvals on merge requests

**Project → Settings → Merge requests → Merge request approvals** — set minimum number of approvals.

### 10.7 — Use merge request pipelines, not just branch pipelines

```yaml
workflow:
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == "main"'
```
This avoids duplicate pipelines running on both the branch push and the MR.

### 10.8 — Scan for secrets and vulnerabilities

Enable built-in security scanning (SAST, dependency scanning) via **Secure** category templates:
```yaml
include:
  - template: Security/SAST.gitlab-ci.yml
```

### 10.9 — Back up self-hosted instances regularly

```bash
sudo gitlab-backup create
```
Store backups off-server, and back up `/etc/gitlab/gitlab-secrets.json` separately (required to restore).

### 10.10 — Right-size your runners

Use tagged runners (`docker`, `gpu`, `large`) so jobs land on appropriately-sized infrastructure rather than contending for one shared runner.

---

## 11. Cheat Sheet

### Common Git + GitLab CLI commands

```bash
git clone <repo-url>
git checkout -b feature/my-change
git add .
git commit -m "message"
git push origin feature/my-change
git pull origin main
```

### GitLab Runner commands

```bash
sudo gitlab-runner register
sudo gitlab-runner list
sudo gitlab-runner start
sudo gitlab-runner stop
sudo gitlab-runner status
sudo gitlab-runner unregister --name "runner-name"
```

### Self-hosted server management

```bash
sudo gitlab-ctl status
sudo gitlab-ctl restart
sudo gitlab-ctl reconfigure
sudo gitlab-ctl tail             # tail all logs
sudo gitlab-backup create
```

### Pipeline keywords reference

| Keyword | Purpose |
|---|---|
| `stages` | Defines the ordered list of stages |
| `script` | Shell commands the job runs |
| `image` | Docker image to run the job in |
| `only` / `except` | (Legacy) conditions for running a job |
| `rules` | Modern conditional job execution |
| `artifacts` | Files to pass to later stages / download |
| `cache` | Files to reuse between pipeline runs |
| `environment` | Tracks a deployment target |
| `when: manual` | Requires a manual click to run |
| `needs` | Run jobs out of stage order based on dependencies |
| `include` | Reuse CI config from other files |

---

### Next steps

- Explore **GitLab Pages** for hosting static sites straight from CI/CD.
- Look into **Kubernetes-based runners** (`gitlab-runner` with the `kubernetes` executor) for auto-scaling build capacity.
- Try **Auto DevOps** for a zero-config pipeline that builds, tests, and deploys automatically based on detected project type.
