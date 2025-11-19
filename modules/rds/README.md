# RDS Module

Універсальний Terraform модуль для створення AWS RDS баз даних, який підтримує як звичайні RDS інстанси, так і Aurora кластери.

## Можливості

- Підтримка звичайних RDS інстансів (PostgreSQL, MySQL)
- Підтримка Aurora кластерів (Aurora PostgreSQL, Aurora MySQL)
- Автоматичне створення DB Subnet Group
- Автоматичне створення Security Group з налаштованими правилами
- Автоматичне створення Parameter Group з базовими параметрами
- Підтримка Multi-AZ для RDS
- Автоскейлінг для Aurora read replicas
- Шифрування сховища (KMS)
- Performance Insights
- CloudWatch Logs експорт
- Налаштовувані параметри бази даних

## Структура модуля

```
modules/rds/
├── shared.tf       # Спільні ресурси (subnet group, security group, parameter groups)
├── rds.tf          # Ресурси для звичайної RDS instance
├── aurora.tf       # Ресурси для Aurora cluster
├── variables.tf    # Визначення змінних
└── outputs.tf      # Виводи модуля
```

## Використання

### Приклад 1: Звичайна RDS PostgreSQL інстанс

```hcl
module "rds" {
  source = "./modules/rds"

  identifier   = "my-postgres-db"
  use_aurora   = false  # Використовувати звичайну RDS

  # Database engine
  engine         = "postgres"
  engine_version = "16.1"
  instance_class = "db.t3.micro"

  # Storage
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  # Database configuration
  database_name   = "myapp"
  master_username = "dbadmin"
  master_password = "SecurePassword123!"  # Використовуйте AWS Secrets Manager в продакшн
  port            = 5432

  # Network
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnet_ids
  allowed_cidr_blocks        = ["10.0.0.0/16"]
  publicly_accessible        = false
  multi_az                   = true  # Високі availability

  # Backup
  backup_retention_period = 7
  skip_final_snapshot     = false
  deletion_protection     = true

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```

### Приклад 2: Aurora PostgreSQL кластер

```hcl
module "aurora" {
  source = "./modules/rds"

  identifier   = "my-aurora-cluster"
  use_aurora   = true  # Використовувати Aurora

  # Database engine
  engine         = "aurora-postgresql"
  engine_version = "16.1"
  instance_class = "db.r6g.large"

  # Aurora cluster configuration
  aurora_cluster_instances = 2  # 1 writer + 1 reader

  # Database configuration
  database_name   = "myapp"
  master_username = "dbadmin"
  master_password = "SecurePassword123!"
  port            = 5432

  # Network
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnet_ids
  allowed_cidr_blocks        = ["10.0.0.0/16"]
  publicly_accessible        = false

  # Backup
  backup_retention_period = 14
  skip_final_snapshot     = false
  deletion_protection     = true

  # Monitoring
  performance_insights_enabled = true
  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```

### Приклад 3: Aurora з автоскейлінгом

```hcl
module "aurora_autoscaling" {
  source = "./modules/rds"

  identifier   = "my-aurora-autoscaling"
  use_aurora   = true

  engine         = "aurora-mysql"
  engine_version = "8.0.mysql_aurora.3.04.0"
  instance_class = "db.r6g.large"

  # Aurora autoscaling configuration
  aurora_cluster_instances           = 1  # Мінімум 1 writer
  aurora_autoscaling_enabled         = true
  aurora_autoscaling_min_capacity    = 1
  aurora_autoscaling_max_capacity    = 5
  aurora_autoscaling_target_cpu      = 70

  # Database configuration
  database_name   = "myapp"
  master_username = "dbadmin"
  master_password = "SecurePassword123!"
  port            = 3306

  # Network
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnet_ids
  allowed_security_group_ids = [aws_security_group.app.id]

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```

### Приклад 4: RDS з кастомними параметрами

```hcl
module "rds_custom_params" {
  source = "./modules/rds"

  identifier   = "my-custom-postgres"
  use_aurora   = false

  engine         = "postgres"
  engine_version = "16.1"
  instance_class = "db.t3.medium"

  allocated_storage = 100
  storage_encrypted = true

  database_name   = "myapp"
  master_username = "dbadmin"
  master_password = var.db_password

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  allowed_cidr_blocks = ["10.0.0.0/16"]

  # Кастомні параметри БД
  db_parameters = [
    {
      name  = "max_connections"
      value = "200"
    },
    {
      name  = "shared_buffers"
      value = "256MB"
    },
    {
      name  = "work_mem"
      value = "16MB"
    },
    {
      name  = "maintenance_work_mem"
      value = "128MB"
    }
  ]

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```

## Змінні

### Обов'язкові змінні

| Назва | Тип | Опис |
|-------|-----|------|
| `identifier` | string | Унікальний ідентифікатор для бази даних |
| `master_password` | string | Пароль для master користувача (sensitive) |
| `vpc_id` | string | ID VPC для створення ресурсів |
| `subnet_ids` | list(string) | Список ID підмереж для DB subnet group |

### Основні змінні

| Назва | Тип | Default | Опис |
|-------|-----|---------|------|
| `use_aurora` | bool | `false` | Використовувати Aurora (true) або звичайну RDS (false) |
| `engine` | string | `"postgres"` | Тип БД: `postgres`, `mysql`, `aurora-postgresql`, `aurora-mysql` |
| `engine_version` | string | `"16.1"` | Версія движка БД |
| `instance_class` | string | `"db.t3.micro"` | Клас інстансу |
| `database_name` | string | `"mydb"` | Назва БД для створення |
| `master_username` | string | `"admin"` | Master username |
| `port` | number | `5432` | Порт для підключень |

### Storage (тільки для RDS)

| Назва | Тип | Default | Опис |
|-------|-----|---------|------|
| `allocated_storage` | number | `20` | Розмір сховища в ГБ |
| `storage_type` | string | `"gp3"` | Тип сховища: `gp2`, `gp3`, `io1`, `io2` |
| `storage_encrypted` | bool | `true` | Увімкнути шифрування |
| `kms_key_id` | string | `null` | KMS key ID для шифрування |

### Network

| Назва | Тип | Default | Опис |
|-------|-----|---------|------|
| `allowed_cidr_blocks` | list(string) | `[]` | CIDR блоки з доступом до БД |
| `allowed_security_group_ids` | list(string) | `[]` | Security group IDs з доступом до БД |
| `publicly_accessible` | bool | `false` | Публічний доступ до БД |
| `multi_az` | bool | `false` | Multi-AZ deployment (тільки RDS) |

### Backup & Maintenance

| Назва | Тип | Default | Опис |
|-------|-----|---------|------|
| `backup_retention_period` | number | `7` | Кількість днів зберігання бекапів |
| `backup_window` | string | `"03:00-04:00"` | Вікно бекапу (UTC) |
| `maintenance_window` | string | `"sun:04:00-sun:05:00"` | Вікно обслуговування (UTC) |
| `skip_final_snapshot` | bool | `false` | Пропустити фінальний snapshot |
| `deletion_protection` | bool | `false` | Захист від видалення |

### Aurora-specific

| Назва | Тип | Default | Опис |
|-------|-----|---------|------|
| `aurora_cluster_instances` | number | `1` | Кількість інстансів в кластері |
| `aurora_autoscaling_enabled` | bool | `false` | Увімкнути автоскейлінг |
| `aurora_autoscaling_min_capacity` | number | `1` | Мінімальна кількість read replicas |
| `aurora_autoscaling_max_capacity` | number | `5` | Максимальна кількість read replicas |
| `aurora_autoscaling_target_cpu` | number | `70` | Цільове CPU використання для автоскейлінгу |

### Monitoring

| Назва | Тип | Default | Опис |
|-------|-----|---------|------|
| `performance_insights_enabled` | bool | `false` | Увімкнути Performance Insights |
| `enabled_cloudwatch_logs_exports` | list(string) | `[]` | Типи логів для експорту в CloudWatch |
| `monitoring_interval` | number | `0` | Інтервал моніторингу (0, 1, 5, 10, 15, 30, 60) |

### Custom Parameters

| Назва | Тип | Default | Опис |
|-------|-----|---------|------|
| `db_parameters` | list(object) | `[]` | Список кастомних параметрів БД |

## Outputs

### Загальні outputs

| Назва | Опис |
|-------|------|
| `endpoint` | Connection endpoint (працює для RDS і Aurora) |
| `reader_endpoint` | Reader endpoint (тільки для Aurora) |
| `port` | Порт БД |
| `database_name` | Назва БД |
| `master_username` | Master username (sensitive) |
| `engine` | Тип движка БД |
| `engine_version` | Версія движка БД |
| `is_aurora` | Чи це Aurora кластер |

### Інфраструктурні outputs

| Назва | Опис |
|-------|------|
| `security_group_id` | ID security group БД |
| `db_subnet_group_id` | ID DB subnet group |
| `parameter_group_id` | ID parameter group |

### RDS-specific outputs

| Назва | Опис |
|-------|------|
| `db_instance_id` | ID RDS інстансу |
| `db_instance_arn` | ARN RDS інстансу |
| `db_instance_endpoint` | Endpoint RDS інстансу |

### Aurora-specific outputs

| Назва | Опис |
|-------|------|
| `cluster_id` | ID Aurora кластера |
| `cluster_arn` | ARN Aurora кластера |
| `cluster_endpoint` | Writer endpoint Aurora кластера |
| `cluster_reader_endpoint` | Reader endpoint Aurora кластера |
| `cluster_instance_ids` | Список ID інстансів кластера |

## Підтримувані движки

### Standard RDS
- `postgres` - PostgreSQL 12.x - 16.x
- `mysql` - MySQL 5.7, 8.0

### Aurora
- `aurora-postgresql` - Aurora PostgreSQL 13.x - 16.x
- `aurora-mysql` - Aurora MySQL 5.7, 8.0

## Parameter Groups

Модуль автоматично створює parameter group з базовими параметрами:

### PostgreSQL / Aurora PostgreSQL
- `max_connections` = 100
- `shared_buffers` = {DBInstanceClassMemory/32768}
- `log_statement` = all

### MySQL / Aurora MySQL
- `max_connections` = 100
- `slow_query_log` = 1
- `long_query_time` = 2

Ви можете додати кастомні параметри через змінну `db_parameters`.

## Перемикання між RDS і Aurora

Для зміни типу БД просто змініть змінну `use_aurora`:

```hcl
# Звичайна RDS
module "db" {
  source     = "./modules/rds"
  use_aurora = false
  engine     = "postgres"
  # ...
}

# Перемикання на Aurora
module "db" {
  source     = "./modules/rds"
  use_aurora = true
  engine     = "aurora-postgresql"
  # ...
}
```

⚠️ **УВАГА**: Пряме перемикання між RDS і Aurora вимагає міграції даних. Terraform видалить стару БД і створить нову.

## Security Best Practices

1. **Паролі**: Використовуйте AWS Secrets Manager або Terraform variables
2. **Шифрування**: Завжди увімкнуйте `storage_encrypted = true`
3. **Network**: Не використовуйте `publicly_accessible = true` в продакшн
4. **Backups**: Налаштуйте адекватний `backup_retention_period`
5. **Deletion Protection**: Увімкніть для продакшн БД

## Приклади версій движків

```hcl
# PostgreSQL
engine_version = "16.1"  # Рекомендовано
engine_version = "15.5"
engine_version = "14.10"

# MySQL
engine_version = "8.0.35"  # Рекомендовано
engine_version = "5.7.44"

# Aurora PostgreSQL
engine_version = "16.1"
engine_version = "15.5"

# Aurora MySQL
engine_version = "8.0.mysql_aurora.3.04.0"
engine_version = "5.7.mysql_aurora.2.12.0"
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |

