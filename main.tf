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
  instance_type   = "t3.small"
  desired_size    = 1
  max_size        = 2
  min_size        = 1
}