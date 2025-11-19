# Secrets Module

Цей модуль створює та управляє чутливими даними через AWS Secrets Manager.

## Створені ресурси

1. **GitHub Token Secret** - Personal Access Token для CI/CD
2. **Jenkins Admin Password Secret** - Пароль адміністратора Jenkins
3. **RDS Master Password Secret** - Пароль master користувача PostgreSQL
4. **IAM Policy** - Політика для доступу до секретів з EKS

## Використання

### Отримання секретів через AWS CLI

```bash
# GitHub Token
aws secretsmanager get-secret-value \
  --secret-id final-project-github-token \
  --query SecretString --output text

# Jenkins Password
aws secretsmanager get-secret-value \
  --secret-id final-project-jenkins-admin-password \
  --query SecretString --output text

# RDS Password
aws secretsmanager get-secret-value \
  --secret-id final-project-rds-master-password \
  --query SecretString --output text
```

### Використання в Kubernetes

Для доступу до секретів зподів в EKS потрібно:

1. **External Secrets Operator** (рекомендовано для production)
2. **AWS Secrets Manager CSI Driver**
3. **IAM Roles for Service Accounts (IRSA)**

## Безпека

- Секрети зберігаються в AWS Secrets Manager (encrypted at rest)
- Terraform state містить тільки ARN, не сам секрет
- Доступ контролюється через IAM policies
- Recovery window 7 днів після видалення

## Outputs

- `github_token_secret_arn` - ARN секрету GitHub token
- `jenkins_password_secret_arn` - ARN секрету Jenkins password  
- `rds_password_secret_arn` - ARN секрету RDS password
- `secrets_access_policy_arn` - ARN IAM політики для доступу

## Важливо

⚠️ **Не додавайте terraform.tfvars до Git!** Файл вже в .gitignore
