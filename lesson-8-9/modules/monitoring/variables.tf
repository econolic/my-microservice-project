variable "namespace" {
  description = "Kubernetes namespace for monitoring stack"
  type        = string
  default     = "monitoring"
}

variable "chart_version" {
  description = "Version of kube-prometheus-stack Helm chart"
  type        = string
  default     = "65.0.0"
}

variable "service_type" {
  description = "Kubernetes service type for Grafana and Prometheus"
  type        = string
  default     = "LoadBalancer"
  
  validation {
    condition     = contains(["ClusterIP", "NodePort", "LoadBalancer"], var.service_type)
    error_message = "Service type must be ClusterIP, NodePort, or LoadBalancer."
  }
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
