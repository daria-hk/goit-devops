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
  default     = "jenkins@daria-hk.com"
}

