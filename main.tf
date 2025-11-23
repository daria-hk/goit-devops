terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
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
  source         = "./modules/vpc"
  vpc_cidr_block = "10.0.0.0/16"

  public_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24",
  ]

  private_subnets = [
    "10.0.4.0/24",
    "10.0.5.0/24",
    "10.0.6.0/24",
  ]

  availability_zones = [
    "eu-central-1a",
    "eu-central-1b",
    "eu-central-1c",
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
  source        = "./modules/eks"
  cluster_name  = "eks-cluster-demo"
  subnet_ids    = module.vpc.public_subnets
  instance_type = "t3.small"
  desired_size  = 1
  max_size      = 2
  min_size      = 1
}

# EKS cluster data for providers
data "aws_eks_cluster" "eks" {
  name = module.eks.eks_cluster_name
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.eks_cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

module "jenkins" {
  source            = "./modules/jenkins"
  cluster_name      = module.eks.eks_cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url

  github_pat      = var.github_pat
  github_user     = var.github_user
  github_repo_url = var.github_repo_url

  depends_on = [module.eks]

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }
}
