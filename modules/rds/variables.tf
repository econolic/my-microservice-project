variable "identifier" {
  description = "Identifier for the database (used as a prefix for resources)"
  type        = string
}

variable "use_aurora" {
  description = "Whether to create Aurora cluster (true) or standard RDS instance (false)"
  type        = bool
  default     = false
}

variable "engine" {
  description = "Database engine type (postgres, mysql, aurora-postgresql, aurora-mysql)"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
  default     = "16.1"
}

variable "instance_class" {
  description = "Instance type for RDS instance or Aurora cluster instances"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB (only for standard RDS, not Aurora)"
  type        = number
  default     = 20
}

variable "storage_type" {
  description = "Storage type (gp2, gp3, io1, io2)"
  type        = string
  default     = "gp3"
}

variable "storage_encrypted" {
  description = "Enable storage encryption"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for encryption (optional)"
  type        = string
  default     = null
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "mydb"
}

variable "master_username" {
  description = "Master username for the database"
  type        = string
  default     = "admin"
}

variable "master_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}

variable "port" {
  description = "Port on which the database accepts connections"
  type        = number
  default     = 5432
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment (only for standard RDS)"
  type        = bool
  default     = false
}

variable "publicly_accessible" {
  description = "Whether the database is publicly accessible"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID where the database will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the database"
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "List of security group IDs allowed to access the database"
  type        = list(string)
  default     = []
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Preferred backup window (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Preferred maintenance window (UTC)"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when destroying the database"
  type        = bool
  default     = false
}

variable "final_snapshot_identifier" {
  description = "Name of the final snapshot when destroying (if skip_final_snapshot = false)"
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = false
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention period in days"
  type        = number
  default     = 7
}

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch"
  type        = list(string)
  default     = []
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds (0, 1, 5, 10, 15, 30, 60)"
  type        = number
  default     = 0
}

variable "monitoring_role_arn" {
  description = "ARN of IAM role for enhanced monitoring (required if monitoring_interval > 0)"
  type        = string
  default     = null
}

variable "auto_minor_version_upgrade" {
  description = "Enable automatic minor version upgrades"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply changes immediately instead of during maintenance window"
  type        = bool
  default     = false
}

# Aurora-specific variables
variable "aurora_cluster_instances" {
  description = "Number of Aurora cluster instances to create (only used when use_aurora = true)"
  type        = number
  default     = 1
}

variable "aurora_instance_class_overrides" {
  description = "Map of instance class overrides for specific Aurora instances (e.g., {1 = 'db.r5.large'})"
  type        = map(string)
  default     = {}
}

variable "aurora_autoscaling_enabled" {
  description = "Enable autoscaling for Aurora read replicas"
  type        = bool
  default     = false
}

variable "aurora_autoscaling_min_capacity" {
  description = "Minimum number of Aurora read replicas when autoscaling is enabled"
  type        = number
  default     = 1
}

variable "aurora_autoscaling_max_capacity" {
  description = "Maximum number of Aurora read replicas when autoscaling is enabled"
  type        = number
  default     = 5
}

variable "aurora_autoscaling_target_cpu" {
  description = "Target CPU utilization for Aurora autoscaling"
  type        = number
  default     = 70
}

variable "aurora_autoscaling_target_connections" {
  description = "Target connections for Aurora autoscaling"
  type        = number
  default     = null
}

# Parameter Group settings
variable "db_parameters" {
  description = "List of database parameters to apply"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
