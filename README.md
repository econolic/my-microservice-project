# Final Project: Complete DevOps Infrastructure on AWS

---

## Зміст

- [Огляд проекту](#огляд-проекту)
- [Архітектура](#архітектура)
- [Структура проекту](#структура-проекту)
- [Передумови](#передумови)
- [Швидкий старт](#швидкий-старт)
- [Детальна документація](#детальна-документація)
- [Модулі інфраструктури](#модулі-інфраструктури)
- [CI/CD Pipeline](#cicd-pipeline)
- [Моніторинг](#моніторинг)

---

## Огляд проекту

Цей проект демонструє повний цикл побудови, розгортання та підтримки DevOps інфраструктури на AWS.

### Ключові компоненти:

- Infrastructure as Code (Terraform)  
- Container Orchestration (Amazon EKS)  
- Database (RDS PostgreSQL 16.1)  
- CI/CD (Jenkins + Argo CD)  
- Monitoring (Prometheus + Grafana)  
- Application (Django)

---

## Архітектура
```
┌─────────────────────────────────────────────────────────────────────┐
│                          AWS Cloud (us-west-2)                      │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                     VPC (10.0.0.0/16)                        │  │
│  │                                                              │  │
│  │  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │  │
│  │  │   Public     │    │   Public     │    │   Public     │  │
│  │  │   Subnet     │    │   Subnet     │    │   Subnet     │  │
│  │  │ 10.0.1.0/24  │    │ 10.0.2.0/24  │    │ 10.0.3.0/24  │  │
│  │  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘  │  │
│  │         │                   │                   │          │  │
│  │         └───────────────────┴───────────────────┘          │  │
│  │                           │                                │  │
│  │                    ┌──────▼──────┐                         │  │
│  │                    │ EKS Cluster │                         │  │
│  │                    │  (1.28)     │                         │  │
│  │                    │             │                         │  │
│  │                    │  - Jenkins  │                         │  │
│  │  ┌──────────────┐  │  - Argo CD  │  ┌──────────────┐     │  │
│  │  │   Private    │  │  - Prometheus│  │   Private    │     │  │
│  │  │   Subnet     │  │  - Grafana  │  │   Subnet     │     │  │
│  │  │ 10.0.4.0/24  │  │  - Django   │  │ 10.0.6.0/24  │     │  │
│  │  │              │  └─────────────┘  │              │     │  │
│  │  │  ┌────────┐  │                   │              │     │  │
│  │  │  │  RDS   │  │                   │              │     │  │
│  │  │  │ PG 16  │  │                   │              │     │  │
│  │  │  └────────┘  │                   │              │     │  │
│  │  └──────────────┘                   └──────────────┘     │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐                 │
│  │   ECR    │    │    S3    │    │ DynamoDB │                 │
│  │ Registry │    │  State   │    │   Lock   │                 │
│  └──────────┘    └──────────┘    └──────────┘                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📁 Структура проекту

```
final-project/
│
├── main.tf                      # Головний файл Terraform
├── backend.tf                   # Налаштування S3 backend
├── variables.tf                 # Змінні
├── outputs.tf                   # Виводи
├── terraform.tfvars.example     # Приклад конфігурації
│
├── modules/                     # Terraform модулі
│   ├── s3-backend/             # S3 + DynamoDB для стану
│   ├── vpc/                    # VPC, Subnets, NAT, IGW
│   ├── ecr/                    # ECR Registry
│   ├── eks/                    # EKS Cluster + Node Groups
│   │   └── aws_ebs_csi_driver.tf
│   ├── rds/                    # RDS PostgreSQL
│   ├── jenkins/                # Jenkins (Helm)
│   ├── argo_cd/                # Argo CD (Helm)
│   └── monitoring/             # Prometheus + Grafana
│
├── charts/                     # Helm Charts
│   └── django-app/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│
├── Django/                     # Django додаток
│   ├── app/
│   ├── Dockerfile
│   ├── Jenkinsfile
│   └── docker-compose.yaml
│
├── DEPLOYMENT_GUIDE.md         # Повна інструкція
└── README.md                   # Цей файл
```

---

## Передумови

### Необхідне ПЗ

- **Terraform** >= 1.0
- **AWS CLI** >= 2.0
- **kubectl** >= 1.28
- **Git**
- **WSL** (для Windows)

### AWS Account

```bash
aws configure
# AWS Access Key ID: [Your Key]
# AWS Secret Access Key: [Your Secret]
# Default region: us-west-2
```

### GitHub Token

Створіть Personal Access Token з правами `repo` та `workflow`

---

## Швидкий старт

### 1. Клонування

```bash
git clone https://github.com/econolic/my-microservice-project.git
cd my-microservice-project
git checkout final-project
```

### 2. Налаштування

```bash
cp terraform.tfvars.example terraform.tfvars
# Відредагуйте terraform.tfvars
```

Оновіть у `terraform.tfvars`:
- `github_token` - ваш GitHub PAT
- `github_username` - ваш GitHub username
- `jenkins_admin_password` - надійний пароль
- `rds_master_password` - надійний пароль для БД

### 3. Розгортання

```bash
# Ініціалізація
terraform init

# Перегляд плану
terraform plan

# Розгортання (15-20 хв)
terraform apply
```

### 4. Налаштування kubectl

```bash
aws eks update-kubeconfig --region us-west-2 --name final-project-eks-cluster
kubectl get nodes
```

### 5. Оновлення RDS endpoint

```bash
# Отримати endpoint
terraform output db_endpoint

# Оновити values.yaml
DB_HOST=$(terraform output -raw db_endpoint | cut -d: -f1)
cd charts/django-app
sed -i "s/REPLACE_WITH_RDS_ENDPOINT/$DB_HOST/g" values.yaml

# Закоммітити
git add values.yaml
git commit -m "feat: Update RDS endpoint"
git push origin final-project
```

---

## Детальна документація

Повна інструкція з розгортання, налаштування та troubleshooting:

**[DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)**

---

## Безпека та Секрети

### AWS Secrets Manager

Всі чутливі дані зберігаються в AWS Secrets Manager:

- **GitHub Token** - для CI/CD інтеграції
- **Jenkins Admin Password** - пароль адміністратора
- **RDS Master Password** - пароль бази даних

```bash
# Отримати секрет з AWS Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id final-project-github-token \
  --query SecretString --output text
```

### SAST (Static Application Security Testing)

Проект включає багаторівневу систему безпеки:

1. **Pre-commit hooks** - локальна перевірка перед commit
   - tfsec (Terraform security)
   - GitLeaks (secrets detection)
   - Hadolint (Dockerfile linting)

2. **GitHub Actions** - автоматичне сканування
   - Terraform security scan
   - Dockerfile vulnerabilities (Trivy)
   - Dependencies audit
   - Secrets scan

3. **Jenkins Pipeline** - CI/CD security
   - Trivy image scanning перед push
   - Vulnerability reports

**Детальна інструкція:** [SECURITY_SETUP.md](./SECURITY_SETUP.md)

### Важливо

* **terraform.tfvars** - в .gitignore, не комітиться  
* **terraform.tfvars.example** - шаблон без секретів  
* **AWS Secrets Manager** - production секрети

---

## Модулі інфраструктури

### Secrets
- AWS Secrets Manager для чутливих даних
- IAM policies для доступу
- Kubernetes Secrets integration

### S3 Backend
- S3 bucket для Terraform state
- DynamoDB для state locking

### VPC
- CIDR: 10.0.0.0/16
- 3 публічних підмережі
- 3 приватних підмережі
- NAT Gateway, Internet Gateway

### EKS
- Kubernetes 1.28
- Node Group (t3.small)
- AWS EBS CSI Driver
- IAM roles та policies

### RDS
- PostgreSQL 16.1
- Multi-AZ для production
- Автоматичні backup
- Security groups

### ECR
- Docker registry
- Image scanning
- Lifecycle policies

### Jenkins
- Helm chart 5.8.110
- LoadBalancer service
- Persistent volume

### Argo CD
- GitOps deployment
- Auto-sync
- Application CRD

### Monitoring
- Prometheus (metrics)
- Grafana (dashboards)
- AlertManager

---

## CI/CD Pipeline

### Jenkins Pipeline

1. **Checkout** - клонує код з GitHub
2. **Build** - збирає Docker image (Kaniko)
3. **Push** - завантажує в ECR
4. **Update Helm** - оновлює values.yaml
5. **Commit** - пушить зміни в GitHub

### Argo CD Sync

1. Відслідковує зміни в Git
2. Auto-sync з `charts/django-app/`
3. Розгортає нову версію
4. Health checks

---

## Моніторинг

### Prometheus

```bash
kubectl port-forward svc/kube-prometheus-stack-prometheus 9090:9090 -n monitoring
# http://localhost:9090
```

### Grafana

```bash
kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring
# http://localhost:3000
# admin / admin
```

**Рекомендовані дашборди:**
- Kubernetes / Compute Resources / Cluster
- Kubernetes / Compute Resources / Namespace (Pods)
- Node Exporter / Nodes

---

## Тестування

### Перевірка подів

```bash
kubectl get pods -A
```

### Тест БД

```bash
kubectl run -it --rm psql-test --image=postgres:16 --restart=Never -- \
  psql -h $(terraform output -raw db_endpoint | cut -d: -f1) \
  -U dbadmin -d djangodb
```

### Тест Django

```bash
kubectl port-forward svc/django-app 8000:80 -n default
# http://localhost:8000
```

---

## Ресурси

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Argo CD Documentation](https://argo-cd.readthedocs.io/)
- [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator)
- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/)
- [tfsec Security Scanning](https://aquasecurity.github.io/tfsec/)

---

**Успішного розгортання! **


