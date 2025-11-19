# Security Setup Guide

## Overview

Проект використовує багаторівневий підхід до безпеки:

1. **Pre-commit hooks** - локальна перевірка перед commit
2. **GitHub Actions** - автоматичне сканування при push
3. **Jenkins Pipeline** - сканування Docker images перед deployment

---

## 📋 Pre-commit Hooks

### Встановлення

```bash
# Встановити pre-commit
pip install pre-commit

# Або через brew (macOS)
brew install pre-commit

# Встановити hooks
pre-commit install
```

### Використання

```bash
# Автоматично запускається при git commit
git commit -m "your message"

# Ручний запуск на всіх файлах
pre-commit run --all-files

# Запуск конкретного hook
pre-commit run terraform_fmt --all-files
pre-commit run tfsec --all-files
```

### Що перевіряється:

* **Terraform:**
    - Форматування (terraform fmt)
    - Валідація (terraform validate)
    - Безпека (tfsec)
    - Документація

* **Secrets:**
    - GitLeaks - виявлення секретів
    - Приватні ключі

* **Python:**
    - Black - форматування
    - Flake8 - linting
* **Docker:**
    - Hadolint - Dockerfile best practices

* **YAML/Markdown:**
    - Синтаксис та форматування

---

## GitHub Actions

### Security Scanning Workflow

Автоматично запускається при:
- Push в `main`, `final-project`, `lesson-*`
- Pull requests

### Що сканується:

1. **Terraform Security (tfsec)**
   - Перевірка безпеки IaC
   - Мінімальна severity: MEDIUM
   - Результати в GitHub Security tab

2. **Dockerfile Security (Trivy)**
   - Сканування Dockerfile конфігурації
   - CRITICAL/HIGH/MEDIUM вразливості

3. **Secrets Scan (GitLeaks)**
   - Пошук витоків секретів
   - Історія всіх commits

4. **Dependencies (Safety + pip-audit)**
   - Python залежності
   - Відомі CVE

5. **Terraform Validation**
   - Format check
   - Init/Validate

### Перегляд результатів:

```
GitHub → Repository → Security → Code scanning alerts
```

---

## Jenkins Pipeline Security

### Trivy Image Scanning

Додано в pipeline після build:

```groovy
stage('Security Scan with Trivy') {
  // Сканує Docker image перед push
  // Виявляє HIGH/CRITICAL вразливості
}
```

### Процес:

1. Build image (без push)
2. Scan з Trivy
3. Якщо OK → Push to ECR
4. Якщо є критичні вразливості → warning (не блокує)

---

## Security Checklist

### Перед commit:

- [ ] `pre-commit run --all-files` пройшов успішно
- [ ] Немає секретів у коді
- [ ] Terraform відформатований
- [ ] Dockerfile проходить hadolint

### Перед push:

- [ ] GitHub Actions будуть зелені
- [ ] Додані нові файли у .gitignore (якщо потрібно)

### Перед production:

- [ ] Trivy scan показує 0 CRITICAL
- [ ] tfsec не має HIGH severity issues
- [ ] Всі secrets в AWS Secrets Manager
- [ ] terraform.tfvars в .gitignore

---

## Налаштування

### tfsec custom rules (опціонально)

Створіть `.tfsec/config.yml`:

```yaml
severity_overrides:
  aws-s3-enable-bucket-encryption: ERROR
  aws-ec2-no-public-ingress-sgr: WARNING
```

### GitLeaks custom config (опціонально)

Створіть `.gitleaks.toml`:

```toml
[extend]
useDefault = true

[[rules]]
id = "custom-aws-key"
description = "AWS Access Key"
regex = '''AKIA[0-9A-Z]{16}'''
```

---

## Ресурси

- [tfsec documentation](https://aquasecurity.github.io/tfsec/)
- [Trivy documentation](https://aquasecurity.github.io/trivy/)
- [GitLeaks](https://github.com/gitleaks/gitleaks)
- [pre-commit hooks](https://pre-commit.com/)

---

## Troubleshooting

### Pre-commit не працює

```bash
# Переінсталюйте hooks
pre-commit uninstall
pre-commit install

# Оновіть hooks до останніх версій
pre-commit autoupdate
```

### GitHub Actions failed

Перегляньте logs:
```
Actions → Security Scanning → Failed job → Logs
```

### Trivy timeout в Jenkins

Збільшіть timeout або виключіть деякі перевірки:
```groovy
trivy image --timeout 10m ...
```
