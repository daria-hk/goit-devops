# Jenkins Konfiguration
variable "namespace" {
  description = "Kubernetes Namespace für Jenkins"
  type        = string
  default     = "jenkins"
}

variable "chart_version" {
  description = "Jenkins Helm Chart Version"
  type        = string
  default     = "5.1.27"
}

variable "service_type" {
  description = "Kubernetes Service Type für Jenkins"
  type        = string
  default     = "LoadBalancer"
}

# ECR Konfiguration
variable "ecr_registry" {
  description = "ECR Registry URL (ohne Repository Name)"
  type        = string
}

variable "ecr_repository_url" {
  description = "Vollständige ECR Repository URL"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "eu-central-1"
}

# GitHub Credentials
variable "github_pat" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}

variable "github_user" {
  description = "GitHub Username"
  type        = string
}

variable "github_repo_url" {
  description = "GitHub Repository URL für Helm Charts"
  type        = string
}

variable "github_email" {
  description = "GitHub Email für Git Commits"
  type        = string
  default     = "jenkins@example.com"
}

# AWS Credentials (für ECR Push)
variable "aws_access_key_id" {
  description = "AWS Access Key ID für ECR"
  type        = string
  sensitive   = true
  default     = ""
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key für ECR"
  type        = string
  sensitive   = true
  default     = ""
}

