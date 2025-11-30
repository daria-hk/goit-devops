# Namespace für Jenkins
resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.namespace
  }
}

# Secret für GitHub Credentials
resource "kubernetes_secret" "github_credentials" {
  metadata {
    name      = "github-credentials"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }

  data = {
    username = var.github_user
    password = var.github_pat
  }

  type = "kubernetes.io/basic-auth"
}

# Secret für Git Config (für Commits)
resource "kubernetes_secret" "git_config" {
  metadata {
    name      = "git-config"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }

  data = {
    ".gitconfig" = <<-EOT
      [user]
        name = ${var.github_user}
        email = ${var.github_email}
      [credential]
        helper = store
      [credential "https://github.com"]
        username = ${var.github_user}
    EOT
    ".git-credentials" = "https://${var.github_user}:${var.github_pat}@github.com"
  }
}

# Secret für Docker Config (ECR Authentication)
# Kaniko benötigt dies für ECR Push
resource "kubernetes_secret" "docker_config" {
  metadata {
    name      = "docker-config"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }

  data = {
    "config.json" = jsonencode({
      credHelpers = {
        "${var.aws_region}.dkr.ecr.amazonaws.com" = "ecr-login"
      }
      auths = {
        "${var.ecr_registry}" = {
          auth = ""
        }
      }
    })
  }
}

# ConfigMap mit Pipeline-Umgebungsvariablen
resource "kubernetes_config_map" "jenkins_env" {
  metadata {
    name      = "jenkins-env"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }

  data = {
    ECR_REGISTRY       = var.ecr_registry
    ECR_REPOSITORY_URL = var.ecr_repository_url
    AWS_REGION         = var.aws_region
    GITHUB_REPO_URL    = var.github_repo_url
    GITHUB_USER        = var.github_user
  }
}

# IAM Policy für ECR Push (als Kubernetes ConfigMap für Referenz)
# In Produktion sollte IRSA (IAM Roles for Service Accounts) verwendet werden
resource "kubernetes_config_map" "ecr_policy" {
  metadata {
    name      = "ecr-policy"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }

  data = {
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:PutImage",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload"
          ]
          Resource = "*"
        }
      ]
    })
  }
}

# Helm Release für Jenkins
resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  version    = var.chart_version
  namespace  = kubernetes_namespace.jenkins.metadata[0].name

  values = [
    file("${path.module}/values.yaml")
  ]

  # Überschreibe bestimmte Values via set
  set {
    name  = "controller.serviceType"
    value = var.service_type
  }

  set {
    name  = "controller.admin.username"
    value = "admin"
  }

  # Generate Admin Password
  set {
    name  = "controller.admin.password"
    value = random_password.jenkins_admin_password.result
  }

  # Jenkins URL wird automatisch gesetzt
  set {
    name  = "controller.jenkinsUrl"
    value = ""
    type  = "string"
  }

  # Agent Namespace
  set {
    name  = "agent.namespace"
    value = kubernetes_namespace.jenkins.metadata[0].name
  }

  depends_on = [
    kubernetes_namespace.jenkins,
    kubernetes_secret.github_credentials,
    kubernetes_secret.docker_config,
    kubernetes_secret.git_config,
    kubernetes_config_map.jenkins_env
  ]

  timeout = 600
}

# Generate Random Admin Password
resource "random_password" "jenkins_admin_password" {
  length  = 16
  special = true
}

# Warte auf Jenkins LoadBalancer
data "kubernetes_service" "jenkins" {
  metadata {
    name      = "jenkins"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }

  depends_on = [helm_release.jenkins]
}

