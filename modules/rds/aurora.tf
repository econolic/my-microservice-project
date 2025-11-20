# Aurora Cluster (created when use_aurora = true)
resource "aws_rds_cluster" "this" {
  count = var.use_aurora ? 1 : 0

  cluster_identifier = var.identifier
  engine             = var.engine
  engine_version     = var.engine_version
  database_name      = var.database_name
  master_username    = var.master_username
  master_password    = var.master_password
  port               = var.port

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]

  # Parameter group
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this[0].name

  # Backup configuration
  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.backup_window
  preferred_maintenance_window = var.maintenance_window
  skip_final_snapshot          = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : (
    var.final_snapshot_identifier != null ? var.final_snapshot_identifier : "${var.identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  )

  # Encryption
  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.kms_key_id

  # Deletion protection
  deletion_protection = var.deletion_protection

  # CloudWatch Logs
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  # Upgrades
  apply_immediately = var.apply_immediately

  tags = merge(
    var.tags,
    {
      Name = var.identifier
      Type = "Aurora Cluster"
    }
  )

  lifecycle {
    ignore_changes = [
      final_snapshot_identifier
    ]
  }
}

# Aurora Cluster Instances
resource "aws_rds_cluster_instance" "this" {
  count = var.use_aurora ? var.aurora_cluster_instances : 0

  identifier         = "${var.identifier}-instance-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.this[0].id
  engine             = var.engine
  engine_version     = var.engine_version
  instance_class     = lookup(var.aurora_instance_class_overrides, count.index, var.instance_class)

  # Network
  publicly_accessible = var.publicly_accessible

  # Monitoring
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                   = var.monitoring_interval > 0 ? var.monitoring_role_arn : null

  # Upgrades
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.apply_immediately

  tags = merge(
    var.tags,
    {
      Name = "${var.identifier}-instance-${count.index + 1}"
      Type = "Aurora Instance"
    }
  )
}

# Aurora Autoscaling (for read replicas)
resource "aws_appautoscaling_target" "aurora" {
  count = var.use_aurora && var.aurora_autoscaling_enabled ? 1 : 0

  max_capacity       = var.aurora_autoscaling_max_capacity
  min_capacity       = var.aurora_autoscaling_min_capacity
  resource_id        = "cluster:${aws_rds_cluster.this[0].cluster_identifier}"
  scalable_dimension = "rds:cluster:ReadReplicaCount"
  service_namespace  = "rds"
}

resource "aws_appautoscaling_policy" "aurora_cpu" {
  count = var.use_aurora && var.aurora_autoscaling_enabled ? 1 : 0

  name               = "${var.identifier}-autoscaling-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.aurora[0].resource_id
  scalable_dimension = aws_appautoscaling_target.aurora[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.aurora[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "RDSReaderAverageCPUUtilization"
    }
    target_value = var.aurora_autoscaling_target_cpu
  }
}

resource "aws_appautoscaling_policy" "aurora_connections" {
  count = var.use_aurora && var.aurora_autoscaling_enabled && var.aurora_autoscaling_target_connections != null ? 1 : 0

  name               = "${var.identifier}-autoscaling-connections"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.aurora[0].resource_id
  scalable_dimension = aws_appautoscaling_target.aurora[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.aurora[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "RDSReaderAverageDatabaseConnections"
    }
    target_value = var.aurora_autoscaling_target_connections
  }
}
