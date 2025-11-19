# DB Subnet Group - shared for both RDS and Aurora
resource "aws_db_subnet_group" "this" {
  name        = "${var.identifier}-subnet-group"
  description = "DB subnet group for ${var.identifier}"
  subnet_ids  = var.subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.identifier}-subnet-group"
    }
  )
}

# Security Group - shared for both RDS and Aurora
resource "aws_security_group" "this" {
  name        = "${var.identifier}-db-sg"
  description = "Security group for ${var.identifier} database"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.identifier}-db-sg"
    }
  )
}

# Ingress rule from CIDR blocks
resource "aws_security_group_rule" "ingress_cidr" {
  count             = length(var.allowed_cidr_blocks) > 0 ? 1 : 0
  type              = "ingress"
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = aws_security_group.this.id
  description       = "Allow database access from specified CIDR blocks"
}

# Ingress rule from security groups
resource "aws_security_group_rule" "ingress_sg" {
  count                    = length(var.allowed_security_group_ids)
  type                     = "ingress"
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  source_security_group_id = var.allowed_security_group_ids[count.index]
  security_group_id        = aws_security_group.this.id
  description              = "Allow database access from security group ${var.allowed_security_group_ids[count.index]}"
}

# Egress rule - allow all outbound traffic
resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this.id
  description       = "Allow all outbound traffic"
}

# Parameter Group for standard RDS
resource "aws_db_parameter_group" "this" {
  count       = var.use_aurora ? 0 : 1
  name        = "${var.identifier}-params"
  family      = local.parameter_group_family
  description = "Parameter group for ${var.identifier}"

  dynamic "parameter" {
    for_each = local.default_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.identifier}-params"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Cluster Parameter Group for Aurora
resource "aws_rds_cluster_parameter_group" "this" {
  count       = var.use_aurora ? 1 : 0
  name        = "${var.identifier}-cluster-params"
  family      = local.parameter_group_family
  description = "Cluster parameter group for ${var.identifier}"

  dynamic "parameter" {
    for_each = local.default_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.identifier}-cluster-params"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Local values for parameter group configuration
locals {
  # Determine parameter group family based on engine and version
  parameter_group_family = var.use_aurora ? (
    contains(["aurora-postgresql", "aurora-mysql"], var.engine) ? (
      var.engine == "aurora-postgresql" ? "aurora-postgresql${split(".", var.engine_version)[0]}" : "aurora-mysql${split(".", var.engine_version)[0]}"
    ) : var.engine
  ) : (
    var.engine == "postgres" ? "postgres${split(".", var.engine_version)[0]}" : (
      var.engine == "mysql" ? "mysql${split(".", var.engine_version)[0]}" : var.engine
    )
  )

  # Default parameters based on engine type
  default_parameters = var.engine == "postgres" || var.engine == "aurora-postgresql" ? [
    {
      name  = "max_connections"
      value = "100"
    },
    {
      name  = "shared_buffers"
      value = "{DBInstanceClassMemory/32768}"
    },
    {
      name  = "log_statement"
      value = "all"
    }
  ] : var.engine == "mysql" || var.engine == "aurora-mysql" ? [
    {
      name  = "max_connections"
      value = "100"
    },
    {
      name  = "slow_query_log"
      value = "1"
    },
    {
      name  = "long_query_time"
      value = "2"
    }
  ] : []
}
