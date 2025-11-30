variable "namespace" {
  description = "Kubernetes namespace for Argo CD"
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "Argo CD Helm chart version"
  type        = string
  default     = "5.51.6"
}

variable "github_repo_url" {
  description = "GitHub repository URL for GitOps"
  type        = string
}

variable "github_user" {
  description = "GitHub username"
  type        = string
}

variable "github_pat" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}

variable "app_name" {
  description = "Name of the Argo CD application"
  type        = string
  default     = "django-app"
}

variable "app_path" {
  description = "Path to Helm chart in repository"
  type        = string
  default     = "charts/django-app"
}

variable "app_namespace" {
  description = "Target namespace for the application"
  type        = string
  default     = "default"
}

variable "target_revision" {
  description = "Git branch to track"
  type        = string
  default     = "main"
}
