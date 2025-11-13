# Terraform AWS Infrastructure Project

This repository contains a modular Terraform configuration that deploys a basic AWS infrastructure including:

- **S3 backend for Terraform state storage**
- **DynamoDB table for state locking**
- **Custom VPC with public and private subnets**
- **ECR repository for container images**
- **EC2 instance stored inside the VPC**

---

## 📁 Project Structure

```
project/
├── main.tf                # Root configuration & module calls
├── outputs.tf             # Root outputs
├── variables.tf           # (optional root variables)
├── backend.tf             # S3 backend configuration
├── modules/
│   ├── s3-backend/
│   │   ├── s3.tf
│   │   ├── dynamodb.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │
│   ├── vpc/
│   │   ├── vpc.tf
│   │   ├── routes.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │
│   └── ecr/
│       ├── ecr.tf
│       ├── variables.tf
│       ├── outputs.tf
└── README.md              # Project documentation
```

---

## 🚀 How to Deploy

### 1. Initialize Terraform

```
terraform init
```

This downloads providers, configures the backend, and prepares modules.

### 2. Show the execution plan

```
terraform plan
```

This displays what Terraform will create or modify.

### 3. Apply the configuration

```
terraform apply
```

This creates all AWS resources.

### 4. Destroy the infrastructure

```
terraform destroy
```

This removes all created AWS resources.

---

## 📦 Module Descriptions

### 🔹 **s3-backend module**

Creates the backend infrastructure for Terraform state management:

- S3 bucket for storing `terraform.tfstate`
- Versioning enabled for recovery of old state versions
- Bucket ownership controls (BucketOwnerEnforced)
- DynamoDB table for state locking (prevents parallel modifications)

Outputs:

- `s3_bucket_name`
- `dynamodb_table_name`

---

### 🔹 **vpc module**

Creates a complete Virtual Private Cloud with networking components:

Resources created:

- Main VPC
- 3 public subnets
- 3 private subnets
- Internet Gateway
- Public route table + route associations

Outputs:

- `vpc_id`
- `public_subnets`
- `private_subnets`
- `internet_gateway_id`

---

### 🔹 **ecr module**

Creates an Amazon Elastic Container Registry (ECR) repository:

- Repository name configurable via `ecr_name`
- Optional image scan on push

Outputs:

- `ecr_url`

---

## 📝 Notes

- All resources are deployed in the region **eu-central-1**
- The S3 backend must exist before enabling backend configuration
- State locking (DynamoDB) prevents concurrent Terraform executions

---

## ✔️ Project Ready

This README provides a full overview of your AWS Terraform infrastructure. You can now use it for deployment, documentation, or as coursework submission.
