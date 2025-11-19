variable "namespace" {
  description = "Kubernetes namespace for Jenkins"
  type        = string
  default     = "jenkins"
}

variable "chart_version" {
  description = "Jenkins Helm chart version"
  type        = string
  default     = "5.7.0"
}

variable "jenkins_admin_password" {
  description = "Jenkins admin password"
  type        = string
  sensitive   = true
  # No default - must be provided via root module
}

variable "service_type" {
  description = "Kubernetes service type for Jenkins"
  type        = string
  default     = "LoadBalancer"
}

variable "storage_size" {
  description = "Storage size for Jenkins persistent volume"
  type        = string
  default     = "10Gi"
}

variable "ecr_registry_url" {
  description = "ECR registry URL for Docker images"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "github_token" {
  description = "GitHub personal access token for Jenkins"
  type        = string
  sensitive   = true
  default     = ""
}

variable "github_username" {
  description = "GitHub username for Jenkins"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
