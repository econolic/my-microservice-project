# AWS Secrets Manager для зберігання чутливих даних

# GitHub Token Secret
resource "aws_secretsmanager_secret" "github_token" {
  name                    = "${var.project_name}-github-token"
  description             = "GitHub Personal Access Token for CI/CD"
  recovery_window_in_days = 7

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "github_token" {
  secret_id     = aws_secretsmanager_secret.github_token.id
  secret_string = var.github_token
}

# Jenkins Admin Password Secret
resource "aws_secretsmanager_secret" "jenkins_password" {
  name                    = "${var.project_name}-jenkins-admin-password"
  description             = "Jenkins admin password"
  recovery_window_in_days = 7

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "jenkins_password" {
  secret_id     = aws_secretsmanager_secret.jenkins_password.id
  secret_string = var.jenkins_admin_password
}

# RDS Master Password Secret
resource "aws_secretsmanager_secret" "rds_password" {
  name                    = "${var.project_name}-rds-master-password"
  description             = "RDS PostgreSQL master password"
  recovery_window_in_days = 7

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "rds_password" {
  secret_id     = aws_secretsmanager_secret.rds_password.id
  secret_string = var.rds_master_password
}

# IAM Policy для доступу до секретів
resource "aws_iam_policy" "secrets_access" {
  name        = "${var.project_name}-secrets-access"
  description = "Allow access to application secrets in Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.github_token.arn,
          aws_secretsmanager_secret.jenkins_password.arn,
          aws_secretsmanager_secret.rds_password.arn
        ]
      }
    ]
  })

  tags = var.tags
}
