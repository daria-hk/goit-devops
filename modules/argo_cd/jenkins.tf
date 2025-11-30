# Argo CD Namespace
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
  }
}

# Argo CD Helm Release
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  values = [
    file("${path.module}/values.yaml")
  ]

  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "server.extraArgs[0]"
    value = "--insecure"
  }

  timeout = 600

  depends_on = [kubernetes_namespace.argocd]
}

# GitHub Repository Secret for Argo CD
resource "kubernetes_secret" "github_repo" {
  metadata {
    name      = "github-repo-creds"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type     = "git"
    url      = var.github_repo_url
    password = var.github_pat
    username = var.github_user
  }

  depends_on = [helm_release.argocd]
}

# Argo CD Application using Helm chart
resource "helm_release" "django_app" {
  name      = "django-app-argocd"
  chart     = "${path.module}/charts"
  namespace = kubernetes_namespace.argocd.metadata[0].name

  set {
    name  = "application.name"
    value = var.app_name
  }

  set {
    name  = "application.namespace"
    value = var.app_namespace
  }

  set {
    name  = "application.repoURL"
    value = var.github_repo_url
  }

  set {
    name  = "application.path"
    value = var.app_path
  }

  set {
    name  = "application.targetRevision"
    value = var.target_revision
  }

  depends_on = [
    helm_release.argocd,
    kubernetes_secret.github_repo
  ]
}

