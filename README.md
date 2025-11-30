# Jenkins + Argo CD CI/CD Pipeline on AWS EKS

This repository contains a complete CI/CD infrastructure deployed on AWS EKS using Terraform, Jenkins, and Argo CD.

## 🏗️ Architecture Overview

```
Developer → Git Push → Jenkins Pipeline → ECR + Git → Argo CD → Kubernetes
```

### Components:

- **Terraform**: Infrastructure as Code for AWS resources
- **AWS EKS**: Managed Kubernetes cluster
- **Jenkins**: CI/CD automation server (Build & Push)
- **Argo CD**: GitOps continuous delivery (Sync & Deploy)
- **ECR**: Docker image registry
- **Kaniko**: Container image builder (rootless)
- **RDS/Aurora**: Managed database service

---

## 📁 Project Structure

```
goit-devops/
├── main.tf                    # Root Terraform configuration
├── backend.tf                 # S3 backend for Terraform state
├── terraform.tfvars           # Variables (GitHub PAT, AWS region, etc.)
├── Jenkinsfile                # Jenkins CI/CD pipeline definition
├── Dockerfile                 # Django application Dockerfile
│
├── modules/
│   ├── s3-backend/            # S3 + DynamoDB for Terraform state
│   ├── vpc/                   # VPC with 3 public subnets
│   ├── ecr/                   # Elastic Container Registry
│   ├── eks/                   # EKS cluster + node groups + EBS CSI driver
│   ├── rds/                   # RDS/Aurora database module
│   │   ├── rds.tf             # Standard RDS instance
│   │   ├── aurora.tf          # Aurora cluster
│   │   ├── shared.tf          # Shared resources (subnet group, security group)
│   │   ├── variables.tf       # Module variables
│   │   └── outputs.tf         # Database connection outputs
│   ├── jenkins/               # Jenkins Helm deployment
│   │   ├── jenkins.tf
│   │   ├── values.yaml        # Jenkins configuration (agents, plugins, etc.)
│   │   └── variables.tf
│   └── argo_cd/               # Argo CD Helm deployment
│       ├── jenkins.tf         # Argo CD Helm release
│       ├── values.yaml        # Argo CD configuration
│       ├── variables.tf
│       └── charts/            # Argo CD Application definitions
│           ├── Chart.yaml
│           ├── values.yaml
│           └── templates/
│               ├── application.yaml
│               └── repository.yaml
│
└── charts/
    └── django-app/            # Helm chart for Django application
        ├── Chart.yaml
        ├── values.yaml        # Image tag (auto-updated by Jenkins)
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            ├── hpa.yaml
            ├── configmap.yaml
            └── secret.yaml
```

---

## 🗄️ RDS/Aurora Database Module

The project includes a flexible Terraform module for deploying production-ready databases on AWS. You can choose between a standard RDS instance or an Aurora cluster.

### Module Features

- ✅ Create standard RDS instances (PostgreSQL, MySQL, MariaDB)
- ✅ Create Aurora clusters with read replicas
- ✅ Multi-AZ deployments for high availability
- ✅ Flexible parameter groups for database tuning
- ✅ Automatic subnet groups and security groups
- ✅ Support for public and private access
- ✅ Automated backups configuration

### Basic Usage Example

#### Standard RDS PostgreSQL Database

```hcl
module "rds" {
  source = "./modules/rds"

  # Instance configuration
  name                       = "myapp-db"
  use_aurora                 = false

  # Database engine
  engine                     = "postgres"
  engine_version             = "17.2"
  parameter_group_family_rds = "postgres17"

  # Instance specifications
  instance_class             = "db.t3.medium"
  allocated_storage          = 20

  # Database credentials
  db_name                    = "myapp"
  username                   = "postgres"
  password                   = "SecurePassword123!"

  # Network configuration
  subnet_private_ids         = module.vpc.private_subnets
  subnet_public_ids          = module.vpc.public_subnets
  vpc_id                     = module.vpc.vpc_id
  publicly_accessible        = false

  # High availability
  multi_az                   = true
  backup_retention_period    = 7

  # Custom database parameters
  parameters = {
    max_connections            = "200"
    log_min_duration_statement = "500"
  }

  tags = {
    Environment = "production"
    Project     = "myapp"
  }

  depends_on = [module.vpc]
}
```

#### Aurora PostgreSQL Cluster

```hcl
module "aurora" {
  source = "./modules/rds"

  # Cluster configuration
  name                         = "myapp-aurora"
  use_aurora                   = true
  aurora_instance_count        = 3  # 1 primary + 2 replicas

  # Aurora engine
  engine_cluster               = "aurora-postgresql"
  engine_version_cluster       = "15.3"
  parameter_group_family_aurora = "aurora-postgresql15"

  # Instance specifications
  instance_class               = "db.r5.large"

  # Database credentials
  db_name                      = "myapp"
  username                     = "postgres"
  password                     = "SecurePassword123!"

  # Network configuration
  subnet_private_ids           = module.vpc.private_subnets
  subnet_public_ids            = module.vpc.public_subnets
  vpc_id                       = module.vpc.vpc_id
  publicly_accessible          = false

  # Backup configuration
  backup_retention_period      = 14

  # Custom cluster parameters
  parameters = {
    max_connections            = "500"
    shared_buffers             = "{DBInstanceClassMemory/10240}"
  }

  tags = {
    Environment = "production"
    Project     = "myapp"
  }

  depends_on = [module.vpc]
}
```

### Module Variables

#### Required Variables

| Variable             | Type         | Description                                                        |
| -------------------- | ------------ | ------------------------------------------------------------------ |
| `name`               | string       | Name of the database instance or cluster (used as identifier)      |
| `db_name`            | string       | Name of the default database to create                             |
| `username`           | string       | Master username for database access                                |
| `password`           | string       | Master password (sensitive, use AWS Secrets Manager in production) |
| `vpc_id`             | string       | ID of the VPC where database will be deployed                      |
| `subnet_private_ids` | list(string) | List of private subnet IDs for database placement                  |
| `subnet_public_ids`  | list(string) | List of public subnet IDs (used if publicly_accessible = true)     |

#### Optional Variables

| Variable                        | Type        | Default                 | Description                                                    |
| ------------------------------- | ----------- | ----------------------- | -------------------------------------------------------------- |
| `use_aurora`                    | bool        | `false`                 | If true, creates Aurora cluster instead of RDS instance        |
| `engine`                        | string      | `"postgres"`            | Database engine for RDS (postgres, mysql, mariadb, etc.)       |
| `engine_cluster`                | string      | `"aurora-postgresql"`   | Database engine for Aurora (aurora-postgresql, aurora-mysql)   |
| `engine_version`                | string      | `"14.7"`                | Engine version for standard RDS                                |
| `engine_version_cluster`        | string      | `"15.3"`                | Engine version for Aurora cluster                              |
| `instance_class`                | string      | `"db.t3.micro"`         | Instance class (e.g., db.t3.medium, db.r5.large)               |
| `allocated_storage`             | number      | `20`                    | Storage size in GB (RDS only, not used for Aurora)             |
| `publicly_accessible`           | bool        | `false`                 | Whether database is accessible from internet                   |
| `multi_az`                      | bool        | `false`                 | Enable Multi-AZ deployment for RDS (standby replica)           |
| `backup_retention_period`       | number      | `7`                     | Number of days to retain automated backups (0-35)              |
| `aurora_instance_count`         | number      | `2`                     | Number of instances in Aurora cluster (1 primary + N replicas) |
| `parameter_group_family_rds`    | string      | `"postgres15"`          | Parameter group family for RDS                                 |
| `parameter_group_family_aurora` | string      | `"aurora-postgresql15"` | Parameter group family for Aurora                              |
| `parameters`                    | map(string) | `{}`                    | Custom database parameters (e.g., max_connections)             |
| `tags`                          | map(string) | `{}`                    | Tags to apply to all resources                                 |

### Module Outputs

#### Standard RDS Outputs

| Output         | Description                              |
| -------------- | ---------------------------------------- |
| `rds_endpoint` | Full endpoint for connection (host:port) |
| `rds_address`  | DNS address of RDS instance              |
| `rds_port`     | Port number for database connection      |
| `rds_id`       | AWS resource ID of RDS instance          |

#### Aurora Outputs

| Output                    | Description                                        |
| ------------------------- | -------------------------------------------------- |
| `aurora_cluster_endpoint` | Write endpoint (primary instance)                  |
| `aurora_reader_endpoint`  | Read-only endpoint (load balanced across replicas) |
| `aurora_cluster_id`       | AWS resource ID of Aurora cluster                  |
| `aurora_cluster_members`  | List of all cluster instance identifiers           |

#### Common Outputs

| Output              | Description                           |
| ------------------- | ------------------------------------- |
| `db_name`           | Name of the database                  |
| `db_username`       | Master username (marked as sensitive) |
| `security_group_id` | ID of the database security group     |
| `subnet_group_name` | Name of the DB subnet group           |

### How to Change Database Configuration

#### Changing Database Engine

**For RDS:**

```hcl
# PostgreSQL
engine         = "postgres"
engine_version = "17.2"
parameter_group_family_rds = "postgres17"

# MySQL
engine         = "mysql"
engine_version = "8.0.35"
parameter_group_family_rds = "mysql8.0"

# MariaDB
engine         = "mariadb"
engine_version = "10.11.6"
parameter_group_family_rds = "mariadb10.11"
```

**For Aurora:**

```hcl
# Aurora PostgreSQL
engine_cluster               = "aurora-postgresql"
engine_version_cluster       = "15.3"
parameter_group_family_aurora = "aurora-postgresql15"

# Aurora MySQL
engine_cluster               = "aurora-mysql"
engine_version_cluster       = "8.0.mysql_aurora.3.04.0"
parameter_group_family_aurora = "aurora-mysql8.0"
```

#### Changing Instance Class

```hcl
# Development/Testing
instance_class = "db.t3.micro"   # 2 vCPU, 1 GB RAM - $13/month
instance_class = "db.t3.small"   # 2 vCPU, 2 GB RAM - $26/month
instance_class = "db.t3.medium"  # 2 vCPU, 4 GB RAM - $52/month

# Production (General Purpose)
instance_class = "db.m5.large"   # 2 vCPU, 8 GB RAM
instance_class = "db.m5.xlarge"  # 4 vCPU, 16 GB RAM

# Production (Memory Optimized)
instance_class = "db.r5.large"   # 2 vCPU, 16 GB RAM
instance_class = "db.r5.xlarge"  # 4 vCPU, 32 GB RAM

# Aurora Serverless (auto-scaling)
# For Aurora only - use db.serverless instance class
```

#### Changing Storage Configuration

**For Standard RDS:**

```hcl
# Storage size
allocated_storage = 20   # Minimum for gp2
allocated_storage = 100  # Recommended for production

# Note: Aurora storage auto-scales (10 GB to 128 TB)
# No need to specify allocated_storage for Aurora
```

#### Switching Between RDS and Aurora

**Change one variable:**

```hcl
# Use standard RDS
use_aurora = false

# Use Aurora cluster
use_aurora = true
aurora_instance_count = 3  # 1 primary + 2 replicas
```

#### Configuring High Availability

**Multi-AZ for RDS:**

```hcl
multi_az = true  # Creates standby replica in different AZ
```

**Aurora Replicas:**

```hcl
use_aurora = true
aurora_instance_count = 3  # More replicas = higher availability
```

#### Custom Database Parameters

```hcl
parameters = {
  # Connection settings
  max_connections              = "200"

  # Logging
  log_statement                = "all"
  log_min_duration_statement   = "1000"  # Log queries > 1 second

  # Memory
  shared_buffers               = "256MB"
  work_mem                     = "16MB"

  # Performance
  effective_cache_size         = "1GB"
  random_page_cost             = "1.1"
}
```

### Connection Examples

#### Get Connection Details

```bash
# Standard RDS
terraform output rds_endpoint
terraform output rds_address

# Aurora
terraform output aurora_cluster_endpoint  # For writes
terraform output aurora_reader_endpoint   # For reads
```

#### Connect via psql (PostgreSQL)

```bash
# Standard RDS
psql -h $(terraform output -raw rds_address) -U postgres -d myapp

# Aurora (write)
psql -h $(terraform output -raw aurora_cluster_endpoint) -U postgres -d myapp

# Aurora (read-only)
psql -h $(terraform output -raw aurora_reader_endpoint) -U postgres -d myapp
```

#### Connection String for Applications

```bash
# Standard RDS
postgresql://postgres:SecurePassword123!@myapp-db.xxxxx.eu-central-1.rds.amazonaws.com:5432/myapp

# Aurora
postgresql://postgres:SecurePassword123!@myapp-aurora.cluster-xxxxx.eu-central-1.rds.amazonaws.com:5432/myapp
```

### Security Best Practices

1. **Use Private Subnets**

   ```hcl
   publicly_accessible = false
   # Database will only be accessible from VPC
   ```

2. **Restrict Security Group**

   - Modify `modules/rds/shared.tf` to limit CIDR blocks
   - Default allows `0.0.0.0/0` - change to your specific IPs

3. **Use Secrets Manager**

   ```hcl
   # Store password in AWS Secrets Manager
   password = data.aws_secretsmanager_secret_version.db_password.secret_string
   ```

4. **Enable Encryption**

   ```hcl
   storage_encrypted = true  # Add to rds.tf
   kms_key_id       = aws_kms_key.db.arn
   ```

5. **Regular Backups**
   ```hcl
   backup_retention_period = 14  # 2 weeks minimum
   backup_window          = "03:00-04:00"
   maintenance_window     = "mon:04:00-mon:05:00"
   ```

### When to Use RDS vs Aurora

**Use Standard RDS if:**

- Budget-conscious development/testing environment
- Predictable, moderate workloads
- Simple database requirements
- Single-region deployment

**Use Aurora if:**

- Production workloads with high availability requirements
- Read-heavy workloads (use reader endpoint with replicas)
- Need for fast failover (< 30 seconds)
- Global applications (Aurora Global Database)
- Serverless requirements (Aurora Serverless)

---

## 🚀 How to Deploy Infrastructure with Terraform

### Prerequisites

1. **AWS CLI** configured with credentials
2. **kubectl** installed
3. **Terraform** v1.5+ installed
4. **GitHub Personal Access Token** with `repo` scope

### Step 1: Configure Variables

Edit `terraform.tfvars`:

```hcl
github_pat      = "github_pat_YOUR_TOKEN_HERE"
github_user     = "your-github-username"
github_repo_url = "https://github.com/your-username/goit-devops.git"
github_email    = "your-email@example.com"
```

### Step 2: Initialize Terraform

```bash
terraform init
```

This will:

- Download required providers (AWS, Kubernetes, Helm)
- Initialize modules
- Configure S3 backend

### Step 3: Plan Infrastructure

```bash
terraform plan
```

Review the resources that will be created:

- VPC with 3 public and 3 private subnets
- EKS cluster with 2x t3.medium nodes
- ECR repository
- RDS PostgreSQL database (or Aurora cluster)
- Jenkins (via Helm)
- Argo CD (via Helm)

### Step 4: Apply Configuration

```bash
terraform apply
```

Type `yes` to confirm. This will take **10-15 minutes** to create all resources.

### Step 5: Configure kubectl

```bash
aws eks --region eu-central-1 update-kubeconfig --name eks-cluster-demo
kubectl get nodes
```

You should see 2 nodes in `Ready` status.

### Step 6: Get Service URLs

```bash
# Jenkins URL
kubectl get svc jenkins -n jenkins

# Argo CD URL
kubectl get svc argocd-server -n argocd
```

### Step 7: Access Credentials

**Jenkins:**

```bash
# Username: admin
# Password: admin123 (configured in jenkins/values.yaml)
```

**Argo CD:**

```bash
# Username: admin
# Password:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

---

## 🔧 How to Check Jenkins Job

### 1. Access Jenkins UI

Get the LoadBalancer URL:

```bash
kubectl get svc jenkins -n jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Open in browser: `http://<JENKINS_URL>:8080`

Login with:

- **Username**: `admin`
- **Password**: `admin123`

### 2. View Pipeline

1. Click on **"deploy-app"** pipeline
2. Click **"Build Now"** to trigger a new build
3. Click on the build number (e.g., #25)
4. Click **"Console Output"** to see logs

### 3. Pipeline Stages

The Jenkins pipeline performs the following stages:

```
┌─────────────────────────────────────────────────────┐
│ 1. Prepare ECR Authentication                       │
│    → Gets AWS ECR login token                       │
│    → Creates Docker config.json                     │
├─────────────────────────────────────────────────────┤
│ 2. Checkout Code                                    │
│    → Clones Git repository                          │
├─────────────────────────────────────────────────────┤
│ 3. Build & Push Docker Image                       │
│    → Builds image with Kaniko                       │
│    → Pushes to ECR with build number tag           │
├─────────────────────────────────────────────────────┤
│ 4. Update Helm Chart                                │
│    → Updates charts/django-app/values.yaml         │
│    → Changes image tag to build number             │
│    → Commits and pushes to main branch             │
├─────────────────────────────────────────────────────┤
│ 5. Verify Deployment                                │
│    → Success message                                │
└─────────────────────────────────────────────────────┘
```

### 4. Check Build Success

A successful build will show:

```
✅ Stage: Prepare ECR Authentication - SUCCESS
✅ Stage: Checkout Code - SUCCESS
✅ Stage: Build & Push Docker Image - SUCCESS
   INFO Pushed <account>.dkr.ecr.eu-central-1.amazonaws.com/lesson-5-ecr:25
✅ Stage: Update Helm Chart - SUCCESS
   📝 Updated image tag to 25
   ✅ Changes detected, committing...
   ✅ Successfully pushed changes to Git!
✅ Stage: Verify Deployment - SUCCESS

🎉 Pipeline succeeded!
```

### 5. Verify Image in ECR

```bash
aws ecr describe-images --repository-name lesson-5-ecr --region eu-central-1
```

---

## 🎯 How to See Results in Argo CD

### 1. Access Argo CD UI

Get the LoadBalancer URL:

```bash
kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Open in browser: `http://<ARGOCD_URL>`

Login with:

- **Username**: `admin`
- **Password**: (get from command below)

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

### 2. View Application

You will see the **"django-app"** application card showing:

- **Sync Status**: `Synced` (when up-to-date) or `OutOfSync` (when changes detected)
- **Health Status**: `Healthy`, `Progressing`, or `Degraded`
- **Repository**: `https://github.com/daria-hk/goit-devops.git`
- **Path**: `charts/django-app`
- **Target Revision**: `main`

### 3. View Deployment Details

Click on the **"django-app"** card to see:

```
┌─────────────────────────────────────────────────┐
│  Application: django-app                        │
│  Status: Synced + Healthy                       │
│                                                  │
│  Resources:                                      │
│  ├─ Deployment (django-app)                     │
│  │  └─ ReplicaSet                               │
│  │     ├─ Pod 1 (Running)                       │
│  │     └─ Pod 2 (Running)                       │
│  ├─ Service (django-service)                    │
│  │  └─ LoadBalancer (External IP)               │
│  └─ HorizontalPodAutoscaler (django-hpa)        │
│     └─ 2/2 replicas (CPU: 0%/70%)               │
└─────────────────────────────────────────────────┘
```

### 4. Check Auto-Sync

Argo CD is configured with **automatic synchronization**:

```yaml
syncPolicy:
  automated:
    prune: true # Delete resources not in Git
    selfHeal: true # Auto-correct drift
```

This means:

- ✅ When Jenkins pushes new `values.yaml` → Argo CD syncs automatically
- ✅ Changes are applied within ~3 minutes
- ✅ Old resources are pruned
- ✅ Manual changes are reverted

### 5. Verify Deployment in Kubernetes

```bash
# Check pods
kubectl get pods -n default

# Check service
kubectl get svc django-service -n default

# Check HPA
kubectl get hpa django-hpa -n default

# Get application URL
kubectl get svc django-service -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### 6. View Sync History

In Argo CD UI:

1. Click on **"django-app"**
2. Go to **"History and Rollback"** tab
3. See all sync operations with:
   - Git commit SHA
   - Sync timestamp
   - Sync status (Success/Failed)
   - Deployed image tag

---

## 🔄 Complete CI/CD Workflow

### Manual Trigger

1. Make changes to `Dockerfile` or application code
2. Trigger Jenkins pipeline manually
3. Jenkins builds new image with tag (e.g., `26`)
4. Jenkins updates `charts/django-app/values.yaml`:
   ```yaml
   image:
     tag: "26"
   ```
5. Jenkins commits and pushes to `main` branch
6. Argo CD detects Git change (within 3 minutes)
7. Argo CD syncs and deploys new version
8. Kubernetes rolls out new pods with image tag `26`

### Verify End-to-End

```bash
# 1. Check Jenkins build
kubectl logs -n jenkins <jenkins-pod-name> -f

# 2. Check Argo CD sync
kubectl get application django-app -n argocd -w

# 3. Check pod rollout
kubectl rollout status deployment/django-app -n default

# 4. Check running pods
kubectl get pods -n default -l app=django-app
```

---

## 🛠️ Kubernetes Components

### Jenkins (namespace: jenkins)

```bash
kubectl get all -n jenkins
```

Resources:

- **Pod**: `jenkins-0` (StatefulSet)
- **Service**: `jenkins` (LoadBalancer)
- **PVC**: `jenkins-jenkins-0` (10Gi, gp2-csi)
- **Secrets**: GitHub credentials, Docker config, AWS credentials
- **ConfigMaps**: Jenkins environment variables, ECR policy

### Argo CD (namespace: argocd)

```bash
kubectl get all -n argocd
```

Resources:

- **Pods**:
  - `argocd-server` (UI + API)
  - `argocd-application-controller` (Sync engine)
  - `argocd-repo-server` (Git repository access)
  - `argocd-redis` (Cache)
- **Service**: `argocd-server` (LoadBalancer)
- **Application**: `django-app` (Custom Resource)

### Django App (namespace: default)

```bash
kubectl get all -n default
```

Resources:

- **Deployment**: `django-app` (2 replicas)
- **Service**: `django-service` (LoadBalancer, port 80)
- **HPA**: `django-hpa` (2-6 replicas, CPU 70%)
- **ConfigMap**: Environment variables
- **Secret**: Django secret key, database password

---

## 🧹 Cleanup

### Destroy All Infrastructure

```bash
# 1. Delete Argo CD applications first
kubectl delete application django-app -n argocd

# 2. Delete helm releases
helm uninstall argocd -n argocd
helm uninstall jenkins -n jenkins

# 3. Destroy Terraform resources
terraform destroy
```

**Warning**: This will delete:

- EKS cluster
- All Kubernetes resources
- ECR repository and images
- RDS database (final snapshot will be skipped)
- VPC and networking
- S3 bucket (if empty)

**Note**: RDS deletion takes 5-10 minutes. To preserve data, modify `modules/rds/rds.tf`:

```hcl
skip_final_snapshot = false
final_snapshot_identifier = "myapp-db-final-snapshot"
```

---

## 📊 Resource Requirements

| Component                | CPU         | Memory     | Storage    |
| ------------------------ | ----------- | ---------- | ---------- |
| EKS Nodes (2x t3.medium) | 2 vCPU each | 4 GB each  | 20 GB each |
| Jenkins Controller       | 500m-2000m  | 1-4 GB     | 10 GB PVC  |
| Argo CD (total)          | ~1000m      | ~2 GB      | -          |
| Django App (per pod)     | 100m-500m   | 128-512 MB | -          |
| RDS db.t3.medium         | 2 vCPU      | 4 GB       | 20 GB gp2  |

**Estimated AWS Cost**: ~$150-200/month (eu-central-1)

- EKS Cluster: ~$70/month
- EC2 Nodes (2x t3.medium): ~$60/month
- RDS db.t3.medium: ~$50-60/month
- Data transfer & storage: ~$10-20/month

---

## 🔐 Security Notes

1. **GitHub PAT**: Stored in Terraform variables and Kubernetes secrets
2. **AWS Credentials**: IAM user for Jenkins ECR push (not recommended for production - use IRSA)
3. **Jenkins**: Basic auth with `admin/admin123` (change in production!)
4. **Argo CD**: Initial admin secret (rotate after first login)
5. **ECR**: Images are private, accessible only from EKS cluster
6. **RDS**: Password stored in plain text in Terraform (use AWS Secrets Manager in production!)
7. **RDS Security Group**: Currently allows `0.0.0.0/0` on port 5432 (restrict to VPC CIDR in production!)

---

## 🐛 Troubleshooting

### Jenkins Pod Not Starting

```bash
kubectl describe pod jenkins-0 -n jenkins
kubectl logs jenkins-0 -n jenkins -c jenkins
```

Common issues:

- PVC not binding → Check EBS CSI driver
- Out of memory → Increase node size or reduce Jenkins memory

### Argo CD Not Syncing

```bash
kubectl describe application django-app -n argocd
kubectl logs -n argocd deployment/argocd-application-controller
```

Common issues:

- Git repository not accessible → Check GitHub PAT
- Helm chart errors → Check `charts/django-app/values.yaml` syntax

### Django Pods CrashLoopBackOff

```bash
kubectl logs <pod-name> -n default
kubectl describe pod <pod-name> -n default
```

Common issues:

- Missing database → Django app expects PostgreSQL
- Missing secrets → Check `values.yaml` for `secrets` section

### RDS Database Creation Taking Too Long

RDS creation typically takes **10-15 minutes**:

```bash
# Check Terraform progress
terraform show

# Check AWS Console or CLI
aws rds describe-db-instances --db-instance-identifier myapp-db
```

Common stages:

- Creating instance: ~6-10 minutes
- Configuring Multi-AZ: ~2-4 minutes
- Backing up: ~2-5 minutes
- Available: Ready for connections

### Cannot Connect to RDS Database

```bash
# Check security group
aws ec2 describe-security-groups --group-ids <sg-id>

# Check from EKS pod
kubectl run -it --rm debug --image=postgres:17 --restart=Never -- \
  psql -h <rds-endpoint> -U postgres -d myapp
```

Common issues:

- Security group not allowing port 5432
- Database not in same VPC
- Incorrect credentials
- Database still initializing

---

## 📚 Technologies Used

- **Terraform** v1.5+ - Infrastructure as Code
- **AWS EKS** v1.31 - Kubernetes
- **AWS RDS** - Managed relational database
- **AWS Aurora** - High-performance managed database
- **Jenkins** v2.528.2 - CI/CD
- **Argo CD** v2.9.3 - GitOps
- **Helm** v3.x - Package manager
- **Kaniko** v1.19.0 - Container builder
- **Docker** - Containerization
- **PostgreSQL** v17.2 - Database engine
- **Git** - Version control

---

## 📖 Additional Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Argo CD Documentation](https://argo-cd.readthedocs.io/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)
- [AWS Aurora Documentation](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/)
- [Kaniko Documentation](https://github.com/GoogleContainerTools/kaniko)

---

## ✅ Project Status

- ✅ Infrastructure deployed via Terraform
- ✅ VPC with public and private subnets
- ✅ EKS cluster with node groups
- ✅ RDS/Aurora database module
- ✅ Jenkins pipeline working
- ✅ Docker images building and pushing to ECR
- ✅ Argo CD auto-sync enabled
- ✅ Complete CI/CD flow functional

**Last Updated**: 2025-11-30
**Author**: daria-hk
**License**: MIT
