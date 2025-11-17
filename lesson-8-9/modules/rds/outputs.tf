# Common outputs
output "db_subnet_group_id" {
  description = "The ID of the DB subnet group"
  value       = aws_db_subnet_group.this.id
}

output "db_subnet_group_arn" {
  description = "The ARN of the DB subnet group"
  value       = aws_db_subnet_group.this.arn
}

output "security_group_id" {
  description = "The ID of the database security group"
  value       = aws_security_group.this.id
}

output "security_group_arn" {
  description = "The ARN of the database security group"
  value       = aws_security_group.this.arn
}

output "parameter_group_id" {
  description = "The ID of the parameter group (RDS) or cluster parameter group (Aurora)"
  value       = var.use_aurora ? aws_rds_cluster_parameter_group.this[0].id : aws_db_parameter_group.this[0].id
}

output "parameter_group_arn" {
  description = "The ARN of the parameter group (RDS) or cluster parameter group (Aurora)"
  value       = var.use_aurora ? aws_rds_cluster_parameter_group.this[0].arn : aws_db_parameter_group.this[0].arn
}

# RDS Instance outputs
output "db_instance_id" {
  description = "The ID of the RDS instance (only for standard RDS)"
  value       = var.use_aurora ? null : aws_db_instance.this[0].id
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance (only for standard RDS)"
  value       = var.use_aurora ? null : aws_db_instance.this[0].arn
}

output "db_instance_endpoint" {
  description = "The connection endpoint for the RDS instance (only for standard RDS)"
  value       = var.use_aurora ? null : aws_db_instance.this[0].endpoint
}

output "db_instance_address" {
  description = "The hostname of the RDS instance (only for standard RDS)"
  value       = var.use_aurora ? null : aws_db_instance.this[0].address
}

output "db_instance_port" {
  description = "The port of the RDS instance (only for standard RDS)"
  value       = var.use_aurora ? null : aws_db_instance.this[0].port
}

output "db_instance_resource_id" {
  description = "The resource ID of the RDS instance (only for standard RDS)"
  value       = var.use_aurora ? null : aws_db_instance.this[0].resource_id
}

output "db_instance_status" {
  description = "The status of the RDS instance (only for standard RDS)"
  value       = var.use_aurora ? null : aws_db_instance.this[0].status
}

# Aurora Cluster outputs
output "cluster_id" {
  description = "The ID of the Aurora cluster (only for Aurora)"
  value       = var.use_aurora ? aws_rds_cluster.this[0].id : null
}

output "cluster_arn" {
  description = "The ARN of the Aurora cluster (only for Aurora)"
  value       = var.use_aurora ? aws_rds_cluster.this[0].arn : null
}

output "cluster_endpoint" {
  description = "The cluster endpoint (writer) for the Aurora cluster (only for Aurora)"
  value       = var.use_aurora ? aws_rds_cluster.this[0].endpoint : null
}

output "cluster_reader_endpoint" {
  description = "The cluster reader endpoint for the Aurora cluster (only for Aurora)"
  value       = var.use_aurora ? aws_rds_cluster.this[0].reader_endpoint : null
}

output "cluster_port" {
  description = "The port of the Aurora cluster (only for Aurora)"
  value       = var.use_aurora ? aws_rds_cluster.this[0].port : null
}

output "cluster_resource_id" {
  description = "The resource ID of the Aurora cluster (only for Aurora)"
  value       = var.use_aurora ? aws_rds_cluster.this[0].cluster_resource_id : null
}

output "cluster_members" {
  description = "List of RDS instances that are part of this cluster (only for Aurora)"
  value       = var.use_aurora ? aws_rds_cluster.this[0].cluster_members : null
}

output "cluster_instance_ids" {
  description = "List of Aurora cluster instance IDs (only for Aurora)"
  value       = var.use_aurora ? aws_rds_cluster_instance.this[*].id : null
}

output "cluster_instance_endpoints" {
  description = "List of Aurora cluster instance endpoints (only for Aurora)"
  value       = var.use_aurora ? aws_rds_cluster_instance.this[*].endpoint : null
}

# Universal outputs (work for both RDS and Aurora)
output "endpoint" {
  description = "The connection endpoint (works for both RDS and Aurora)"
  value       = var.use_aurora ? aws_rds_cluster.this[0].endpoint : aws_db_instance.this[0].endpoint
}

output "reader_endpoint" {
  description = "The reader endpoint (only for Aurora, null for RDS)"
  value       = var.use_aurora ? aws_rds_cluster.this[0].reader_endpoint : null
}

output "port" {
  description = "The port of the database (works for both RDS and Aurora)"
  value       = var.use_aurora ? aws_rds_cluster.this[0].port : aws_db_instance.this[0].port
}

output "database_name" {
  description = "The name of the database"
  value       = var.database_name
}

output "master_username" {
  description = "The master username for the database"
  value       = var.master_username
  sensitive   = true
}

output "engine" {
  description = "The database engine"
  value       = var.engine
}

output "engine_version" {
  description = "The database engine version"
  value       = var.engine_version
}

output "is_aurora" {
  description = "Whether this is an Aurora cluster (true) or standard RDS (false)"
  value       = var.use_aurora
}
