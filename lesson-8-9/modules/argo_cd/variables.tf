variable "namespace" {
  description = "Kubernetes namespace for Argo CD"
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "Argo CD Helm chart version"
  type        = string
  default     = "7.7.1"
}

variable "service_type" {
  description = "Kubernetes service type for Argo CD server"
  type        = string
  default     = "LoadBalancer"
}

variable "github_repo_url" {
  description = "GitHub repository URL for Argo CD applications"
  type        = string
}

variable "github_token" {
  description = "GitHub personal access token for Argo CD"
  type        = string
  sensitive   = true
  default     = ""
}

variable "helm_chart_path" {
  description = "Path to Helm chart in repository"
  type        = string
  default     = "charts/django-app"
}

variable "auto_sync" {
  description = "Enable auto sync for Argo CD applications"
  type        = bool
  default     = true
}

variable "self_heal" {
  description = "Enable self-healing for Argo CD applications"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
