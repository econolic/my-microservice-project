# Create namespace for Argo CD
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
    }
  }
}

# Create secret for GitHub repository access
resource "kubernetes_secret" "github_repo" {
  count = var.github_token != "" ? 1 : 0

  metadata {
    name      = "github-repo-secret"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type     = "git"
    url      = var.github_repo_url
    password = var.github_token
    username = "git"
  }

  type = "Opaque"
}

# Install Argo CD using Helm
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  values = [
    templatefile("${path.module}/values.yaml", {
      service_type = var.service_type
    })
  ]

  timeout = 1200

  depends_on = [
    kubernetes_namespace.argocd
  ]
}

# Install Argo CD Applications using Helm chart
resource "helm_release" "argocd_apps" {
  name      = "argocd-apps"
  chart     = "${path.module}/charts/argo-apps"
  namespace = kubernetes_namespace.argocd.metadata[0].name

  set {
    name  = "github.repoUrl"
    value = var.github_repo_url
  }

  set {
    name  = "github.chartPath"
    value = var.helm_chart_path
  }

  set {
    name  = "github.targetRevision"
    value = "final-project"
  }

  set {
    name  = "sync.automated"
    value = var.auto_sync
  }

  set {
    name  = "sync.selfHeal"
    value = var.self_heal
  }

  depends_on = [
    helm_release.argocd,
    kubernetes_secret.github_repo
  ]
}
