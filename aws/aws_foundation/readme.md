# AWS Foundations — Complete Setup Guide

A combined, ordered reference for provisioning a secure AWS environment from scratch: networking, identity, compute, storage, databases, serverless functions, and APIs.

## Recommended Build Order

This document follows the sequence a real deployment typically uses — each chapter builds on resources created in the ones before it:

1. **[VPC](#chapter-1-vpc)** — network foundation (subnets, routing, internet/NAT gateways)
2. **[IAM](#chapter-2-iam)** — users, groups, roles, and least-privilege policies
3. **[EC2](#chapter-3-ec2)** — virtual servers in the VPC's public subnet
4. **[S3](#chapter-4-s3)** — object storage for assets, backups, and static content
5. **[RDS](#chapter-5-rds)** — managed relational database in the VPC's private subnets
6. **[Lambda](#chapter-6-lambda)** — serverless functions, often reading/writing S3 and RDS
7. **[API Gateway](#chapter-7-api-gateway)** — HTTP front door for Lambda and other backends

Each chapter is self-contained with its own prerequisites, verification checklist, cleanup steps, and troubleshooting table, so you can also jump directly to the service you need.

---
