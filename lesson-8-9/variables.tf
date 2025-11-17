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

# RDS/Database Variables
variable "rds_identifier" {
  description = "Identifier for the database"
  type        = string
  default     = "lesson-db-postgres"
}

variable "rds_use_aurora" {
  description = "Whether to create Aurora cluster (true) or standard RDS (false)"
  type        = bool
  default     = false
}

variable "rds_engine" {
  description = "Database engine (postgres, mysql, aurora-postgresql, aurora-mysql)"
  type        = string
  default     = "postgres"
}

variable "rds_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "16.1"
}

variable "rds_instance_class" {
  description = "Instance class for database"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "Allocated storage in GB (only for standard RDS)"
  type        = number
  default     = 20
}

variable "rds_storage_type" {
  description = "Storage type (gp2, gp3, io1)"
  type        = string
  default     = "gp3"
}

variable "rds_storage_encrypted" {
  description = "Enable storage encryption"
  type        = bool
  default     = true
}

variable "rds_database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "djangodb"
}

variable "rds_master_username" {
  description = "Master username for the database"
  type        = string
  default     = "dbadmin"
}

variable "rds_master_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}

variable "rds_port" {
  description = "Port for database connections"
  type        = number
  default     = 5432
}

variable "rds_allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the database"
  type        = list(string)
  default     = []
}

variable "rds_allowed_security_group_ids" {
  description = "Security group IDs allowed to access the database"
  type        = list(string)
  default     = []
}

variable "rds_publicly_accessible" {
  description = "Whether the database is publicly accessible"
  type        = bool
  default     = false
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ deployment (standard RDS only)"
  type        = bool
  default     = false
}

variable "rds_backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "rds_backup_window" {
  description = "Preferred backup window (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "rds_maintenance_window" {
  description = "Preferred maintenance window (UTC)"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "rds_skip_final_snapshot" {
  description = "Skip final snapshot when destroying"
  type        = bool
  default     = true
}

variable "rds_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "rds_performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = false
}

variable "rds_enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch"
  type        = list(string)
  default     = ["postgresql"]
}

variable "rds_aurora_cluster_instances" {
  description = "Number of Aurora cluster instances (Aurora only)"
  type        = number
  default     = 2
}

variable "rds_aurora_autoscaling_enabled" {
  description = "Enable autoscaling for Aurora read replicas"
  type        = bool
  default     = false
}

variable "rds_aurora_autoscaling_min_capacity" {
  description = "Minimum number of Aurora read replicas"
  type        = number
  default     = 1
}

variable "rds_aurora_autoscaling_max_capacity" {
  description = "Maximum number of Aurora read replicas"
  type        = number
  default     = 5
}

variable "rds_db_parameters" {
  description = "Custom database parameters"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

