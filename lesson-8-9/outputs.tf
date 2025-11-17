# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

# ECR Outputs
output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_url
}

output "ecr_repository_name" {
  description = "ECR repository name"
  value       = module.ecr.repository_name
}

# EKS Outputs
output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_version" {
  description = "EKS cluster version"
  value       = module.eks.cluster_version
}

output "configure_kubectl_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

# Jenkins Outputs
output "jenkins_namespace" {
  description = "Jenkins namespace"
  value       = module.jenkins.jenkins_namespace
}

output "jenkins_url" {
  description = "Jenkins URL"
  value       = module.jenkins.jenkins_url
}

output "jenkins_admin_user" {
  description = "Jenkins admin username"
  value       = module.jenkins.jenkins_admin_user
}

output "jenkins_admin_password" {
  description = "Jenkins admin password"
  value       = module.jenkins.jenkins_admin_password
  sensitive   = true
}

output "get_jenkins_password_command" {
  description = "Command to get Jenkins admin password"
  value       = "terraform output -raw jenkins_admin_password"
}

output "get_jenkins_loadbalancer_command" {
  description = "Command to get Jenkins LoadBalancer URL"
  value       = "kubectl get svc jenkins -n ${module.jenkins.jenkins_namespace} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}

# Argo CD Outputs
output "argocd_namespace" {
  description = "Argo CD namespace"
  value       = module.argocd.argocd_namespace
}

output "argocd_server_url" {
  description = "Argo CD server URL"
  value       = module.argocd.argocd_server_url
}

output "get_argocd_password_command" {
  description = "Command to get Argo CD admin password"
  value       = module.argocd.argocd_admin_password_command
}

output "get_argocd_loadbalancer_command" {
  description = "Command to get Argo CD LoadBalancer URL"
  value       = "kubectl get svc argocd-server -n ${module.argocd.argocd_namespace} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}

# RDS/Database Outputs
output "db_endpoint" {
  description = "Database connection endpoint"
  value       = module.rds.endpoint
}

output "db_reader_endpoint" {
  description = "Database reader endpoint (Aurora only)"
  value       = module.rds.reader_endpoint
}

output "db_port" {
  description = "Database port"
  value       = module.rds.port
}

output "db_name" {
  description = "Database name"
  value       = module.rds.database_name
}

output "db_username" {
  description = "Database master username"
  value       = module.rds.master_username
  sensitive   = true
}

output "db_engine" {
  description = "Database engine"
  value       = module.rds.engine
}

output "db_engine_version" {
  description = "Database engine version"
  value       = module.rds.engine_version
}

output "db_is_aurora" {
  description = "Whether this is an Aurora cluster"
  value       = module.rds.is_aurora
}

output "db_security_group_id" {
  description = "Database security group ID"
  value       = module.rds.security_group_id
}

output "db_connection_string" {
  description = "Database connection string (for reference)"
  value       = "postgresql://${module.rds.master_username}:PASSWORD@${module.rds.endpoint}/${module.rds.database_name}"
  sensitive   = true
}

