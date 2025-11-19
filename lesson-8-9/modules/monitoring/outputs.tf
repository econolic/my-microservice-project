output "monitoring_namespace" {
  description = "Namespace where monitoring stack is deployed"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "prometheus_service_name" {
  description = "Prometheus service name"
  value       = "kube-prometheus-stack-prometheus"
}

output "grafana_service_name" {
  description = "Grafana service name"
  value       = "kube-prometheus-stack-grafana"
}

output "alertmanager_service_name" {
  description = "AlertManager service name"
  value       = "kube-prometheus-stack-alertmanager"
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = "admin"
  sensitive   = true
}

output "get_grafana_url_command" {
  description = "Command to get Grafana LoadBalancer URL"
  value       = "kubectl get svc kube-prometheus-stack-grafana -n ${kubernetes_namespace.monitoring.metadata[0].name} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}

output "get_prometheus_url_command" {
  description = "Command to get Prometheus LoadBalancer URL"
  value       = "kubectl get svc kube-prometheus-stack-prometheus -n ${kubernetes_namespace.monitoring.metadata[0].name} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}

output "port_forward_grafana_command" {
  description = "Command to port-forward Grafana (use if LoadBalancer not available)"
  value       = "kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n ${kubernetes_namespace.monitoring.metadata[0].name}"
}

output "port_forward_prometheus_command" {
  description = "Command to port-forward Prometheus (use if LoadBalancer not available)"
  value       = "kubectl port-forward svc/kube-prometheus-stack-prometheus 9090:9090 -n ${kubernetes_namespace.monitoring.metadata[0].name}"
}
