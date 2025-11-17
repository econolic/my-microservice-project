output "jenkins_namespace" {
  description = "Namespace where Jenkins is installed"
  value       = kubernetes_namespace.jenkins.metadata[0].name
}

output "jenkins_service_name" {
  description = "Jenkins service name"
  value       = "jenkins"
}

output "jenkins_url" {
  description = "Jenkins URL (LoadBalancer hostname)"
  value       = "http://${helm_release.jenkins.name}.${kubernetes_namespace.jenkins.metadata[0].name}.svc.cluster.local:8080"
}

output "jenkins_admin_user" {
  description = "Jenkins admin username"
  value       = "admin"
}

output "jenkins_admin_password" {
  description = "Jenkins admin password"
  value       = var.jenkins_admin_password
  sensitive   = true
}

output "service_account_name" {
  description = "Jenkins service account name"
  value       = kubernetes_service_account.jenkins.metadata[0].name
}
