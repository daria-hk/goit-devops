variable "cluster_name" {
  description = "Назва Kubernetes кластера"
  type        = string
}


variable "oidc_provider_arn" {
  description = "OIDC provider ARN from EKS cluster"
  type        = string
}

variable "oidc_provider_url" {
  type = string
}

variable "github_pat" {
  type        = string
  description = "GitHub Personal Access Token"
}

variable "github_user" {
  type        = string
  description = "GitHub username"
}

variable "github_repo_url" {
  type        = string
  description = "GitHub repository URL"
}
