# Standard RDS Instance (created when use_aurora = false)
resource "aws_db_instance" "this" {
  count = var.use_aurora ? 0 : 1

  identifier     = var.identifier
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  # Storage configuration
  allocated_storage     = var.allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = var.kms_key_id
  max_allocated_storage = var.allocated_storage * 2 # Enable storage autoscaling

  # Database configuration
  db_name  = var.database_name
  username = var.master_username
  password = var.master_password
  port     = var.port

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  publicly_accessible    = var.publicly_accessible
  multi_az               = var.multi_az

  # Parameter and option groups
  parameter_group_name = aws_db_parameter_group.this[0].name

  # Backup configuration
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window
  skip_final_snapshot     = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : (
    var.final_snapshot_identifier != null ? var.final_snapshot_identifier : "${var.identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  )

  # Deletion protection
  deletion_protection = var.deletion_protection

  # Monitoring
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  enabled_cloudwatch_logs_exports       = var.enabled_cloudwatch_logs_exports
  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                   = var.monitoring_interval > 0 ? var.monitoring_role_arn : null

  # Upgrades
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.apply_immediately

  tags = merge(
    var.tags,
    {
      Name = var.identifier
      Type = "RDS Instance"
    }
  )

  lifecycle {
    ignore_changes = [
      final_snapshot_identifier
    ]
  }
}
