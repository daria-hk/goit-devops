variable "github_pat" {
  description = "GitHub Personal Access Token for Jenkins pipeline"
  type        = string
}

variable "github_user" {
  description = "GitHub username"
  type        = string
}

variable "github_repo_url" {
  description = "Repository URL containing the Helm chart or application"
  type        = string
}
