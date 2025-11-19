# Monitoring Module - Prometheus & Grafana via kube-prometheus-stack

# Create namespace for monitoring
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
    }
  }
}

# Deploy kube-prometheus-stack (Prometheus + Grafana + AlertManager)
resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.chart_version
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  timeout = 600

  values = [
    templatefile("${path.module}/values.yaml", {
      service_type = var.service_type
    })
  ]

  depends_on = [kubernetes_namespace.monitoring]
}

# Wait for Grafana to be ready
resource "null_resource" "wait_for_grafana" {
  provisioner "local-exec" {
    command = "kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n ${var.namespace} --timeout=300s || true"
  }

  depends_on = [helm_release.kube_prometheus_stack]
}
