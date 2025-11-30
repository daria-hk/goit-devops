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
- VPC with 3 subnets
- EKS cluster with 2x t3.medium nodes
- ECR repository
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
    prune: true      # Delete resources not in Git
    selfHeal: true   # Auto-correct drift
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
- VPC and networking
- S3 bucket (if empty)

---

## 📊 Resource Requirements

| Component | CPU | Memory | Storage |
|-----------|-----|--------|---------|
| EKS Nodes (2x t3.medium) | 2 vCPU each | 4 GB each | 20 GB each |
| Jenkins Controller | 500m-2000m | 1-4 GB | 10 GB PVC |
| Argo CD (total) | ~1000m | ~2 GB | - |
| Django App (per pod) | 100m-500m | 128-512 MB | - |

**Estimated AWS Cost**: ~$100-150/month (eu-central-1)

---

## 🔐 Security Notes

1. **GitHub PAT**: Stored in Terraform variables and Kubernetes secrets
2. **AWS Credentials**: IAM user for Jenkins ECR push (not recommended for production - use IRSA)
3. **Jenkins**: Basic auth with `admin/admin123` (change in production!)
4. **Argo CD**: Initial admin secret (rotate after first login)
5. **ECR**: Images are private, accessible only from EKS cluster

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

---

## 📚 Technologies Used

- **Terraform** v1.5+ - Infrastructure as Code
- **AWS EKS** v1.31 - Kubernetes
- **Jenkins** v2.528.2 - CI/CD
- **Argo CD** v2.9.3 - GitOps
- **Helm** v3.x - Package manager
- **Kaniko** v1.19.0 - Container builder
- **Docker** - Containerization
- **Git** - Version control

---

## 📖 Additional Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Argo CD Documentation](https://argo-cd.readthedocs.io/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Kaniko Documentation](https://github.com/GoogleContainerTools/kaniko)

---

## ✅ Project Status

- ✅ Infrastructure deployed via Terraform
- ✅ Jenkins pipeline working
- ✅ Docker images building and pushing to ECR
- ✅ Argo CD auto-sync enabled
- ✅ Complete CI/CD flow functional

**Last Updated**: 2025-11-30
**Author**: daria-hk
**License**: MIT

