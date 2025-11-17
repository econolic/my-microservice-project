variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-west-2"
}

# S3 Backend Variables
variable "backend_bucket_name" {
  description = "Name of S3 bucket for Terraform state"
  type        = string
  default     = "terraform-state-budyakov-lesson8-9"
}

variable "backend_table_name" {
  description = "Name of DynamoDB table for state locking"
  type        = string
  default     = "terraform-locks-lesson8-9"
}

# VPC Variables
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "lesson-8-9-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

# ECR Variables
variable "ecr_repository_name" {
  description = "Name of ECR repository for Django application"
  type        = string
  default     = "django-app-lesson8-9"
}

# EKS Variables
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "lesson-8-9-eks-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "node_group_name" {
  description = "Name of the EKS node group"
  type        = string
  default     = "lesson-8-9-node-group"
}

variable "node_instance_types" {
  description = "Instance types for EKS nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 2
}

variable "node_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 4
}

# Jenkins Variables
variable "jenkins_namespace" {
  description = "Kubernetes namespace for Jenkins"
  type        = string
  default     = "jenkins"
}

variable "jenkins_chart_version" {
  description = "Jenkins Helm chart version"
  type        = string
  default     = "5.7.0"
}

variable "jenkins_admin_password" {
  description = "Jenkins admin password"
  type        = string
  sensitive   = true
  # No default - must be provided in terraform.tfvars (not committed)
}

variable "jenkins_service_type" {
  description = "Kubernetes service type for Jenkins"
  type        = string
  default     = "LoadBalancer"
}

variable "jenkins_storage_size" {
  description = "Storage size for Jenkins persistent volume"
  type        = string
  default     = "10Gi"
}

# Argo CD Variables
variable "argocd_namespace" {
  description = "Kubernetes namespace for Argo CD"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "Argo CD Helm chart version"
  type        = string
  default     = "7.7.1"
}

variable "argocd_service_type" {
  description = "Kubernetes service type for Argo CD server"
  type        = string
  default     = "LoadBalancer"
}

variable "argocd_auto_sync" {
  description = "Enable auto sync for Argo CD applications"
  type        = bool
  default     = true
}

variable "argocd_self_heal" {
  description = "Enable self-healing for Argo CD applications"
  type        = bool
  default     = true
}

# GitHub Variables
variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
}

variable "github_username" {
  description = "GitHub username"
  type        = string
}

variable "github_repo_url" {
  description = "GitHub repository URL for Argo CD applications"
  type        = string
}

variable "helm_chart_path" {
  description = "Path to Helm chart in repository"
  type        = string
  default     = "charts/django-app"
}

# Common Tags
variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "MyMicroservice"
    Lesson      = "8-9"
    Environment = "development"
    ManagedBy   = "Terraform"
  }
}
