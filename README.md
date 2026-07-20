# DevOps Architecture & Tools — Detailed Reference

A complete overview of the DevOps lifecycle, architecture, and the tools used at each stage.

## Table of Contents
1. [What Is DevOps](#1-what-is-devops)
2. [DevOps Lifecycle Architecture](#2-devops-lifecycle-architecture)
3. [CI/CD Pipeline Architecture](#3-cicd-pipeline-architecture)
4. [Tools by Lifecycle Stage](#4-tools-by-lifecycle-stage)
   - [4.1 Plan](#41-plan)
   - [4.2 Code / Source Control](#42-code--source-control)
   - [4.3 Build](#43-build)
   - [4.4 Test](#44-test)
   - [4.5 Release / CI-CD](#45-release--cicd)
   - [4.6 Deploy](#46-deploy)
   - [4.7 Operate / Infrastructure](#47-operate--infrastructure)
   - [4.8 Monitor / Observe](#48-monitor--observe)
5. [Containerization & Orchestration Architecture](#5-containerization--orchestration-architecture)
6. [Infrastructure as Code (IaC)](#6-infrastructure-as-code-iac)
7. [Cloud Provider Landscape](#7-cloud-provider-landscape)
8. [Security in DevOps (DevSecOps)](#8-security-in-devops-devsecops)
9. [Configuration Management](#9-configuration-management)
10. [Sample End-to-End Pipeline](#10-sample-end-to-end-pipeline)
11. [Common DevOps Toolchain Stacks](#11-common-devops-toolchain-stacks)

---

## 1. What Is DevOps

DevOps is a set of practices, culture, and tooling that unifies **software development (Dev)** and **IT operations (Ops)** to shorten the development lifecycle while delivering features, fixes, and updates frequently and reliably.

Core principles:
- **Continuous Integration (CI)** — merge and test code changes frequently
- **Continuous Delivery/Deployment (CD)** — ship changes to production safely and often
- **Infrastructure as Code (IaC)** — manage infrastructure through versioned, declarative config
- **Monitoring & Observability** — continuous feedback from production
- **Collaboration & Automation** — break silos between dev, ops, QA, and security

---

## 2. DevOps Lifecycle Architecture

```
        ┌────────┐      ┌────────┐      ┌────────┐      ┌────────┐
        │  PLAN   │─────▶│  CODE   │─────▶│  BUILD  │─────▶│  TEST   │
        └────────┘      └────────┘      └────────┘      └───┬────┘
             ▲                                                │
             │                                                ▼
        ┌────┴───┐      ┌────────┐      ┌────────┐      ┌────────┐
        │ MONITOR │◀─────│ OPERATE │◀─────│ DEPLOY  │◀─────│ RELEASE │
        └────────┘      └────────┘      └────────┘      └────────┘

                  (This loop repeats continuously — the "infinity loop" of DevOps)
```

This is often visualized as an **infinity loop**: Plan → Code → Build → Test → Release → Deploy → Operate → Monitor → back to Plan, driven by continuous feedback.

---

## 3. CI/CD Pipeline Architecture

```
┌──────────┐   push    ┌──────────────┐   trigger   ┌────────────────┐
│ Developer │──────────▶│ Git Repository│────────────▶│  CI Server      │
│  (git push)│           │ (GitHub/GitLab│             │ (Jenkins/GitHub │
└──────────┘            │  /Bitbucket)  │             │  Actions/GitLab │
                          └──────────────┘             │  CI)            │
                                                        └───────┬────────┘
                                                                │
                        ┌───────────────────────────────────────┼─────────────────┐
                        ▼                                       ▼                 ▼
                 ┌─────────────┐                        ┌──────────────┐  ┌──────────────┐
                 │  Build stage │                        │  Test stage   │  │ Security scan │
                 │ (compile,    │                        │ (unit, integ- │  │ (SAST, SCA,   │
                 │  package)    │                        │  ration, e2e) │  │  image scan)  │
                 └──────┬──────┘                        └──────┬───────┘  └──────┬───────┘
                        │                                       │                  │
                        └───────────────────┬───────────────────┴──────────────────┘
                                             ▼
                                     ┌───────────────┐
                                     │ Artifact Store │  (Docker Registry, Nexus, Artifactory)
                                     └───────┬───────┘
                                             ▼
                                     ┌───────────────┐
                                     │  CD / Deploy   │  (ArgoCD, Spinnaker, Flux, Helm)
                                     └───────┬───────┘
                                             ▼
                     ┌───────────────────────┼───────────────────────┐
                     ▼                       ▼                       ▼
              ┌─────────────┐        ┌─────────────┐         ┌─────────────┐
              │  Staging Env │        │  Prod Env    │         │  DR/Canary   │
              └─────────────┘        └──────┬──────┘         └─────────────┘
                                             ▼
                                     ┌───────────────┐
                                     │  Monitoring &  │  (Prometheus, Grafana,
                                     │  Observability  │   Datadog, ELK)
                                     └───────────────┘
```

---

## 4. Tools by Lifecycle Stage

### 4.1 Plan

| Tool | Purpose |
|---|---|
| Jira | Issue tracking, agile boards, sprint planning |
| Confluence | Documentation and knowledge base |
| Trello | Lightweight kanban boards |
| Azure Boards | Work item tracking in the Azure DevOps suite |
| Linear | Modern issue tracking for engineering teams |

### 4.2 Code / Source Control

| Tool | Purpose |
|---|---|
| Git | Distributed version control (the foundation) |
| GitHub | Git hosting, PRs, Actions (CI/CD), issues |
| GitLab | Git hosting + built-in CI/CD + full DevOps platform |
| Bitbucket | Git hosting, integrates with Jira/Trello |
| Gerrit | Code review tool, often paired with Git |

### 4.3 Build

| Tool | Purpose |
|---|---|
| Maven | Build automation for Java projects |
| Gradle | Build automation, faster incremental builds |
| Make | Generic build automation (C/C++ and beyond) |
| npm / yarn / pnpm | JavaScript package management + build scripts |
| Bazel | Fast, scalable multi-language build system |

### 4.4 Test

| Tool | Purpose |
|---|---|
| JUnit / TestNG | Unit testing (Java) |
| PyTest | Unit testing (Python) |
| Selenium | Browser/UI automation testing |
| Cypress / Playwright | Modern end-to-end web testing |
| Postman / Newman | API testing |
| SonarQube | Static code analysis, code quality gates |
| JMeter / k6 | Load and performance testing |

### 4.5 Release / CI-CD

| Tool | Purpose |
|---|---|
| Jenkins | Self-hosted automation server, highly extensible |
| GitHub Actions | CI/CD natively integrated with GitHub |
| GitLab CI/CD | CI/CD natively integrated with GitLab |
| CircleCI | Cloud-based CI/CD |
| Travis CI | Cloud-based CI/CD (legacy-popular for OSS) |
| Azure DevOps Pipelines | CI/CD within the Azure DevOps suite |
| TeamCity | JetBrains CI/CD server |

### 4.6 Deploy

| Tool | Purpose |
|---|---|
| ArgoCD | GitOps continuous delivery for Kubernetes |
| Flux | GitOps toolkit for Kubernetes |
| Spinnaker | Multi-cloud continuous delivery platform |
| Helm | Kubernetes package manager (deploy via "charts") |
| Octopus Deploy | Release management and deployment automation |

### 4.7 Operate / Infrastructure

| Tool | Purpose |
|---|---|
| Docker | Containerization |
| Kubernetes | Container orchestration at scale |
| Terraform | Infrastructure as Code, multi-cloud |
| Ansible | Configuration management, agentless automation |
| Chef / Puppet | Configuration management (agent-based) |
| Vagrant | Local dev environment provisioning |

### 4.8 Monitor / Observe

| Tool | Purpose |
|---|---|
| Prometheus | Metrics collection and alerting |
| Grafana | Dashboards and visualization |
| ELK Stack (Elasticsearch, Logstash, Kibana) | Centralized logging and search |
| Datadog | Full-stack observability (metrics, logs, traces, APM) |
| New Relic | Application performance monitoring |
| Splunk | Log aggregation and analysis |
| PagerDuty / Opsgenie | Incident alerting and on-call management |
| Jaeger / Zipkin | Distributed tracing |

---

## 5. Containerization & Orchestration Architecture

```
                        ┌───────────────────────────────────────┐
                        │            Kubernetes Cluster           │
                        │                                         │
   ┌─────────────┐      │  ┌─────────────┐    ┌─────────────┐    │
   │  kubectl /   │──────┼─▶│  Control Plane│    │   Worker Node │    │
   │  CI/CD tool  │      │  │  (API server, │───▶│  (kubelet,    │    │
   └─────────────┘      │  │   scheduler,  │    │   kube-proxy, │    │
                        │  │   etcd, ctrl-  │    │   container   │    │
                        │  │   manager)     │    │   runtime)    │    │
                        │  └─────────────┘    └──────┬──────┘    │
                        │                              │           │
                        │                       ┌──────▼──────┐    │
                        │                       │    Pods      │    │
                        │                       │  (containers) │    │
                        │                       └─────────────┘    │
                        └───────────────────────────────────────┘
```

| Tool | Purpose |
|---|---|
| Docker | Build/run individual containers |
| containerd / CRI-O | Container runtimes used by Kubernetes |
| Kubernetes (K8s) | Orchestration: scheduling, scaling, self-healing |
| Helm | Package manager for Kubernetes manifests |
| Istio / Linkerd | Service mesh: traffic control, mTLS, observability |
| Rancher | Kubernetes cluster management UI |
| OpenShift | Enterprise Kubernetes platform (Red Hat) |
| k3s / kind / minikube | Lightweight/local Kubernetes for dev & edge |

---

## 6. Infrastructure as Code (IaC)

| Tool | Approach | Notes |
|---|---|---|
| Terraform | Declarative, multi-cloud | Most widely adopted; state-based |
| Pulumi | Declarative, uses real programming languages (Python, TS, Go) | Good for teams wanting IaC in a familiar language |
| AWS CloudFormation | Declarative, AWS-only | Native AWS IaC |
| Azure Resource Manager (ARM) / Bicep | Declarative, Azure-only | Native Azure IaC |
| Google Deployment Manager | Declarative, GCP-only | Native GCP IaC |
| Ansible | Procedural/declarative hybrid | Also does configuration management |

---

## 7. Cloud Provider Landscape

| Provider | Key DevOps-relevant Services |
|---|---|
| AWS | EC2, EKS (Kubernetes), CodePipeline, CloudFormation, S3, Lambda |
| Azure | AKS, Azure DevOps, ARM/Bicep, Azure Functions |
| Google Cloud (GCP) | GKE, Cloud Build, Deployment Manager, Cloud Functions |
| DigitalOcean | Droplets, DOKS (managed Kubernetes) — popular for smaller teams |
| Oracle Cloud (OCI) | OKE (Kubernetes), Compute, Resource Manager |

---

## 8. Security in DevOps (DevSecOps)

| Tool | Purpose |
|---|---|
| Snyk | Dependency & container vulnerability scanning |
| Trivy | Open-source container/IaC vulnerability scanner |
| SonarQube | Static Application Security Testing (SAST) + code quality |
| OWASP ZAP | Dynamic Application Security Testing (DAST) |
| HashiCorp Vault | Secrets management |
| AWS Secrets Manager / Azure Key Vault | Cloud-native secrets management |
| Aqua Security / Falco | Runtime container security & threat detection |
| Checkov / tfsec | Static analysis for Terraform/IaC security |

DevSecOps embeds these checks directly into the CI/CD pipeline ("shift-left security") rather than treating security as a final gate.

---

## 9. Configuration Management

| Tool | Model | Notes |
|---|---|---|
| Ansible | Agentless, push-based, YAML playbooks | Easiest to start with, SSH-based |
| Puppet | Agent-based, pull-based, declarative DSL | Strong for large, long-lived infrastructure |
| Chef | Agent-based, pull-based, Ruby DSL | Highly flexible, steeper learning curve |
| SaltStack | Agent or agentless, event-driven | Fast, good for large-scale orchestration |

---

## 10. Sample End-to-End Pipeline

```yaml
# Example: GitHub Actions CI/CD pipeline
name: CI-CD Pipeline

on:
  push:
    branches: [main]

jobs:
  build-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install dependencies
        run: npm install
      - name: Run tests
        run: npm test
      - name: Build Docker image
        run: docker build -t myapp:${{ github.sha }} .

  security-scan:
    needs: build-test
    runs-on: ubuntu-latest
    steps:
      - name: Scan image for vulnerabilities
        run: trivy image myapp:${{ github.sha }}

  push-image:
    needs: security-scan
    runs-on: ubuntu-latest
    steps:
      - name: Push to registry
        run: |
          docker tag myapp:${{ github.sha }} myregistry.com/myapp:${{ github.sha }}
          docker push myregistry.com/myapp:${{ github.sha }}

  deploy:
    needs: push-image
    runs-on: ubuntu-latest
    steps:
      - name: Deploy via Helm
        run: helm upgrade --install myapp ./chart --set image.tag=${{ github.sha }}
```

---

## 11. Common DevOps Toolchain Stacks

| Stack Style | Typical Tools |
|---|---|
| **AWS-native** | GitHub, CodePipeline/CodeBuild, ECR, EKS, CloudWatch, Terraform |
| **Open-source/self-hosted** | GitLab, Jenkins, Docker, Kubernetes, Prometheus/Grafana, Ansible |
| **Azure-native** | Azure Repos, Azure Pipelines, ACR, AKS, Azure Monitor, Bicep |
| **GitOps-centric** | GitHub/GitLab, ArgoCD/Flux, Kubernetes, Helm, Prometheus |
| **Startup/lean** | GitHub Actions, Docker, DigitalOcean/Fly.io, Sentry, Datadog (free tier) |
