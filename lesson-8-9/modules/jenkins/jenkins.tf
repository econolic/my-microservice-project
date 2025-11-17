# Create namespace for Jenkins
resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
    }
  }
}

# Create ServiceAccount for Jenkins with permissions
resource "kubernetes_service_account" "jenkins" {
  metadata {
    name      = "jenkins"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }
}

# Create ClusterRole for Jenkins to manage pods
resource "kubernetes_cluster_role" "jenkins" {
  metadata {
    name = "jenkins-cluster-role"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log", "pods/exec", "persistentvolumeclaims", "services"]
    verbs      = ["get", "list", "watch", "create", "delete", "update", "patch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "statefulsets"]
    verbs      = ["get", "list", "watch", "create", "delete", "update", "patch"]
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces"]
    verbs      = ["get", "list", "watch"]
  }
}

# Bind ClusterRole to ServiceAccount
resource "kubernetes_cluster_role_binding" "jenkins" {
  metadata {
    name = "jenkins-cluster-role-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.jenkins.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.jenkins.metadata[0].name
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }
}

# Create Secret for GitHub credentials
resource "kubernetes_secret" "github_credentials" {
  count = var.github_token != "" ? 1 : 0

  metadata {
    name      = "github-credentials"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }

  data = {
    username = var.github_username
    password = var.github_token
  }

  type = "kubernetes.io/basic-auth"
}

# Install Jenkins using Helm
resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  version    = var.chart_version
  namespace  = kubernetes_namespace.jenkins.metadata[0].name

  values = [
    templatefile("${path.module}/values.yaml", {
      admin_password = var.jenkins_admin_password
      service_type   = var.service_type
      storage_size   = var.storage_size
    })
  ]

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.jenkins.metadata[0].name
  }

  depends_on = [
    kubernetes_namespace.jenkins,
    kubernetes_service_account.jenkins,
    kubernetes_cluster_role_binding.jenkins
  ]

  timeout = 600
}

# Wait for Jenkins to be ready
resource "null_resource" "wait_for_jenkins" {
  depends_on = [helm_release.jenkins]

  provisioner "local-exec" {
    command = "echo 'Waiting for Jenkins to be ready...'"
  }
}
