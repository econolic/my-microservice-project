output "argocd_namespace" {
  description = "Namespace where Argo CD is installed"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "argocd_server_url" {
  description = "Argo CD server URL"
  value       = "http://argocd-server.${kubernetes_namespace.argocd.metadata[0].name}.svc.cluster.local"
}

output "argocd_admin_password_command" {
  description = "Command to get Argo CD admin password"
  value       = "kubectl -n ${kubernetes_namespace.argocd.metadata[0].name} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}
