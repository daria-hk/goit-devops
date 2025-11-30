terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

# Kubernetes Provider - wird nach EKS-Erstellung konfiguriert
provider "kubernetes" {
  host                   = try(module.eks.eks_cluster_endpoint, "")
  cluster_ca_certificate = try(base64decode(module.eks.eks_cluster_ca_certificate), "")
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      try(module.eks.eks_cluster_name, "")
    ]
  }
}

# Helm Provider - wird nach EKS-Erstellung konfiguriert
provider "helm" {
  kubernetes {
    host                   = try(module.eks.eks_cluster_endpoint, "")
    cluster_ca_certificate = try(base64decode(module.eks.eks_cluster_ca_certificate), "")
    
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        try(module.eks.eks_cluster_name, "")
      ]
    }
  }
}

# EC2 Instance
resource "aws_instance" "example" {
  ami           = "ami-089a7a2a13629ecc4"
  instance_type = "t3.small"              

  tags = {
    Name = "lesson5"
  }
}

# S3 Backend Module
module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "terraform-state-bucket-001001-daria-hk"
  table_name  = "terraform-locks"
}

# VPC Module
module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"

  public_subnets     = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]

  private_subnets    = [
    "10.0.4.0/24",
    "10.0.5.0/24",
    "10.0.6.0/24"
  ]

  availability_zones = [
    "eu-central-1a",
    "eu-central-1b",
    "eu-central-1c"
  ]

  vpc_name = "lesson-5-vpc"
}

# ECR Module
module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "lesson-5-ecr"
  scan_on_push = true
}

# EKS Module
module "eks" {
  source          = "./modules/eks"          
  cluster_name    = "eks-cluster-demo"
  subnet_ids      = module.vpc.public_subnets
  instance_type   = "t3.medium"
  desired_size    = 2
  max_size        = 2
  min_size        = 1
}

# Jenkins Module
module "jenkins" {
  source                 = "./modules/jenkins"
  
  # Jenkins Konfiguration
  namespace              = "jenkins"
  chart_version          = "5.1.27"
  service_type           = "LoadBalancer"
  
  # ECR Konfiguration
  ecr_registry           = regex("^(.*)/.*$", module.ecr.ecr_url)[0]
  ecr_repository_url     = module.ecr.ecr_url
  aws_region             = "eu-central-1"
  
  # GitHub Credentials (aus variables)
  github_pat             = var.github_pat
  github_user            = var.github_user
  github_repo_url        = var.github_repo_url
  github_email           = var.github_email
  
  depends_on = [module.eks]
}

# ===============================
# Argo CD Module
# ===============================
module "argo_cd" {
  source = "./modules/argo_cd"
  
  namespace       = "argocd"
  chart_version   = "5.51.6"
  
  # GitHub Configuration
  github_repo_url = var.github_repo_url
  github_user     = var.github_user
  github_pat      = var.github_pat
  
  # Application Configuration
  app_name         = "django-app"
  app_path         = "charts/django-app"
  app_namespace    = "default"
  target_revision  = "main"
  
  depends_on = [module.eks, module.jenkins]
}