output "github_token_secret_arn" {
  description = "ARN of GitHub token secret"
  value       = aws_secretsmanager_secret.github_token.arn
}

output "github_token_secret_name" {
  description = "Name of GitHub token secret"
  value       = aws_secretsmanager_secret.github_token.name
}

output "jenkins_password_secret_arn" {
  description = "ARN of Jenkins password secret"
  value       = aws_secretsmanager_secret.jenkins_password.arn
}

output "jenkins_password_secret_name" {
  description = "Name of Jenkins password secret"
  value       = aws_secretsmanager_secret.jenkins_password.name
}

output "rds_password_secret_arn" {
  description = "ARN of RDS password secret"
  value       = aws_secretsmanager_secret.rds_password.arn
}

output "rds_password_secret_name" {
  description = "Name of RDS password secret"
  value       = aws_secretsmanager_secret.rds_password.name
}

output "secrets_access_policy_arn" {
  description = "ARN of IAM policy for secrets access"
  value       = aws_iam_policy.secrets_access.arn
}
