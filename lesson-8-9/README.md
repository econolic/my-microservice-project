# Lesson 8-9: CI/CD Pipeline з Jenkins, Helm, Terraform та Argo CD

## Зміст
- [Огляд](#огляд)
- [Архітектура](#архітектура)
- [Передумови](#передумови)
- [Структура проєкту](#структура-проєкту)
- [Крок 1: Підготовка](#крок-1-підготовка)
- [Крок 2: Розгортання інфраструктури](#крок-2-розгортання-інфраструктури)
- [Крок 3: Налаштування Jenkins](#крок-3-налаштування-jenkins)
- [Крок 4: Налаштування Argo CD](#крок-4-налаштування-argo-cd)
- [Крок 5: Запуск CI/CD Pipeline](#крок-5-запуск-cicd-pipeline)
- [Перевірка роботи](#перевірка-роботи)
- [Видалення ресурсів](#видалення-ресурсів)
- [Troubleshooting](#troubleshooting)

## Огляд

Цей проєкт демонструє повний CI/CD процес із використанням:
- **Jenkins** - для автоматизації збірки та деплою
- **Kaniko** - для збірки Docker-образів в Kubernetes
- **Amazon ECR** - для зберігання Docker-образів
- **Helm** - для управління Kubernetes deployments
- **Argo CD** - для GitOps-based continuous delivery
- **Terraform** - для Infrastructure as Code

### Workflow

```
┌─────────────┐      ┌──────────┐      ┌─────────┐      ┌──────────┐      ┌────────────┐
│   GitHub    │─────▶│ Jenkins  │─────▶│   ECR   │─────▶│  GitHub  │─────▶│  Argo CD   │
│   (Code)    │      │ Pipeline │      │ (Image) │      │ (Helm)   │      │  (Deploy)  │
└─────────────┘      └──────────┘      └─────────┘      └──────────┘      └────────────┘
                           │                                                      │
                           │                                                      ▼
                           │                                              ┌──────────────┐
                           └─────────────────────────────────────────────▶│ EKS Cluster  │
                                                                           └──────────────┘
```

## Архітектура

### Компоненти інфраструктури:
1. **VPC** - ізольована мережа з публічними та приватними підмережами
2. **EKS Cluster** - керований Kubernetes кластер
3. **ECR Repository** - приватний Docker registry
4. **Jenkins** - встановлений через Helm в EKS
5. **Argo CD** - встановлений через Helm в EKS
6. **S3 + DynamoDB** - для збереження Terraform state

### CI/CD Flow:
1. Developer пушить код в GitHub
2. Jenkins pipeline автоматично:
   - Клонує репозиторій
   - Збирає Docker образ з Kaniko
   - Пушить образ в ECR
   - Оновлює Helm chart з новим тегом
   - Комітить зміни в GitHub
3. Argo CD автоматично:
   - Детектує зміни в Git
   - Синхронізує Helm chart з кластером
   - Деплоїть нову версію застосунку

## Передумови

### Необхідне ПЗ:
- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) >= 2.0
- [kubectl](https://kubernetes.io/docs/tasks/tools/) >= 1.28
- [Helm](https://helm.sh/docs/intro/install/) >= 3.0
- Git
- [WSL](https://docs.microsoft.com/en-us/windows/wsl/install) (для Windows користувачів)

### AWS Credentials:
```bash
# Налаштуйте AWS CLI
aws configure
# Введіть:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region: us-west-2
# - Default output format: json
```

### GitHub:
- Створіть GitHub Personal Access Token (PAT) з правами:
  - `repo` (повний доступ до репозиторіїв)
  - `workflow` (оновлення GitHub Actions workflows)
- Збережіть токен в безпечному місці

## Структура проєкту

```
lesson-8-9/
├── main.tf                          # Головний конфігураційний файл
├── backend.tf                       # Налаштування S3 backend
├── variables.tf                     # Змінні
├── outputs.tf                       # Виводи
├── terraform.tfvars.example         # Приклад змінних
├── Jenkinsfile                      # Jenkins pipeline
│
├── modules/
│   ├── vpc/                         # VPC модуль
│   ├── ecr/                         # ECR модуль
│   ├── eks/                         # EKS модуль
│   ├── s3-backend/                  # S3 + DynamoDB модуль
│   │
│   ├── jenkins/                     # Jenkins модуль
│   │   ├── jenkins.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── providers.tf
│   │   └── values.yaml              # Helm values для Jenkins
│   │
│   └── argo_cd/                     # Argo CD модуль
│       ├── argocd.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── values.yaml              # Helm values для Argo CD
│       └── charts/
│           └── argo-apps/           # Helm chart для Argo Applications
│               ├── Chart.yaml
│               ├── values.yaml
│               └── templates/
│                   └── application.yaml
│
└── charts/
    └── django-app/                  # Helm chart для Django app
        ├── Chart.yaml
        ├── values.yaml
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            ├── configmap.yaml
            └── hpa.yaml
```

## Крок 1: Підготовка

### 1.1 Клонування репозиторію

```bash
git clone https://github.com/econolic/my-microservice-project.git
cd my-microservice-project
git checkout -b lesson-8-9
```

### 1.2 Створення terraform.tfvars

**⚠️ ВАЖЛИВО: Безпека секретів**

Файл `terraform.tfvars` містить конфіденційну інформацію (токени, паролі) і **НЕ ПОВИНЕН** комітитись в Git. Переконайтесь, що він у `.gitignore` перед початком роботи.

```bash
cd lesson-8-9
cp terraform.tfvars.example terraform.tfvars
```

Відредагуйте `terraform.tfvars`:
```hcl
# GitHub Configuration
github_token    = "ghp_YOUR_GITHUB_TOKEN"         # Ваш GitHub Personal Access Token
github_username = "YOUR_GITHUB_USERNAME"
github_repo_url = "https://github.com/YOUR_GITHUB_USERNAME/my-microservice-project.git"

# Jenkins Configuration
jenkins_admin_password = "YOUR_SECURE_PASSWORD"   # Складний пароль (НЕ "Admin123!")

# Інші параметри можна залишити за замовчуванням
```

**Примітка**: Дефолтні паролі видалені з `variables.tf` — ви **обов'язково** маєте надати `jenkins_admin_password` та `github_token` у `terraform.tfvars`.

### 1.3 Додайте terraform.tfvars в .gitignore

```bash
echo "lesson-8-9/terraform.tfvars" >> .gitignore
echo "lesson-8-9/.terraform/" >> .gitignore
echo "lesson-8-9/.terraform.lock.hcl" >> .gitignore
echo "lesson-8-9/terraform.tfstate*" >> .gitignore
```

## Крок 2: Розгортання інфраструктури

### 2.1 Ініціалізація Terraform

```bash
# Linux/macOS
cd lesson-8-9
terraform init

# Windows (WSL приклад)
wsl bash -lc "cd /mnt/... && terraform init"
```

### 2.2 Перегляд плану

```bash
# Linux/macOS
terraform plan

# Windows (WSL приклад)
wsl bash -lc "cd /mnt/... && terraform plan"
```

### 2.3 Застосування конфігурації

```bash
# Linux/macOS
terraform apply

# Windows (WSL приклад)
wsl bash -lc "cd /mnt/... && terraform apply -auto-approve"
```

**Примітка**: Процес займе 15-20 хвилин. Terraform створить:
- VPC з підмережами
- EKS кластер
- ECR репозиторій
- S3 bucket та DynamoDB таблицю
- Jenkins (через Helm)
- Argo CD (через Helm)

### 2.4 Налаштування kubectl

Після успішного apply, налаштуйте kubectl:

```bash
# Отримайте команду з Terraform output
terraform output configure_kubectl_command

# Виконайте команду (приклад):
aws eks update-kubeconfig --region us-west-2 --name lesson-8-9-eks-cluster
```

Перевірте підключення:
```bash
kubectl get nodes
kubectl get namespaces
```

### 2.5 Міграція state в S3 (опціонально)

Після створення S3 та DynamoDB:

1. Відкоментуйте блок в `backend.tf`
2. Виконайте міграцію:
```bash
terraform init -migrate-state
```

## 🔧 Крок 3: Налаштування Jenkins

### 3.1 Отримання доступу до Jenkins

**Отримайте URL Jenkins:**
```bash
# Отримайте LoadBalancer URL
kubectl get svc jenkins -n jenkins

# Або використайте команду з outputs:
terraform output get_jenkins_loadbalancer_command | sh
```

Зачекайте поки LoadBalancer буде готовий (декілька хвилин).

**Отримайте пароль адміністратора:**
```bash
terraform output -raw jenkins_admin_password

```

**Логін:**
- Username: `admin`
- Password: [output з попередньої команди]
- URL: `http://[LOADBALANCER_URL]:8080`

### 3.2 Налаштування Credentials в Jenkins

1. Перейдіть в Jenkins UI: **Manage Jenkins → Credentials → System → Global credentials**

2. **Додайте GitHub Token:**
   - Click "Add Credentials"
   - Kind: `Secret text`
   - Secret: ваш GitHub PAT
   - ID: `github-token`
   - Description: `GitHub Personal Access Token`

3. **Додайте GitHub Username:**
   - Click "Add Credentials"
   - Kind: `Secret text`
   - Secret: ваш GitHub username
   - ID: `github-username`
   - Description: `GitHub Username`

4. **Додайте ECR Registry URL:**
   - Click "Add Credentials"
   - Kind: `Secret text`
   - Secret: отримайте з `terraform output ecr_repository_url` (без тегу)
   - ID: `ecr-registry-url`
   - Description: `ECR Registry URL`

### 3.3 Налаштування AWS Credentials для ECR

Jenkins потребує доступу до ECR. Налаштуйте ServiceAccount з IRSA:

```bash
# Отримайте OIDC provider ARN
export OIDC_PROVIDER=$(aws eks describe-cluster --name lesson-8-9-eks-cluster --region us-west-2 --query "cluster.identity.oidc.issuer" --output text | sed 's/https:\/\///')

# Створіть IAM роль для Jenkins ServiceAccount
cat > jenkins-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):oidc-provider/${OIDC_PROVIDER}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${OIDC_PROVIDER}:sub": "system:serviceaccount:jenkins:jenkins"
        }
      }
    }
  ]
}
EOF

# Створіть роль
aws iam create-role --role-name jenkins-ecr-role --assume-role-policy-document file://jenkins-trust-policy.json

# Додайте політику для ECR
aws iam attach-role-policy --role-name jenkins-ecr-role --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser

# Анотуйте ServiceAccount
kubectl annotate serviceaccount jenkins -n jenkins eks.amazonaws.com/role-arn=arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/jenkins-ecr-role --overwrite
```

### 3.4 Створення Jenkins Pipeline

1. В Jenkins UI: **New Item**
2. Name: `django-app-pipeline`
3. Type: **Pipeline**
4. В розділі **Pipeline**:
   - Definition: `Pipeline script from SCM`
   - SCM: `Git`
   - Repository URL: `https://github.com/YOUR_USERNAME/my-microservice-project.git`
   - Credentials: виберіть `github-token`
   - Branch: `*/lesson-8-9`
   - Script Path: `lesson-8-9/Jenkinsfile`
5. Save

## Крок 4: Налаштування Argo CD

### 4.1 Отримання доступу до Argo CD

**Отримайте URL Argo CD:**
```bash
# Отримати адресу сервісу
kubectl get svc argocd-server -n argocd

# Linux/macOS (через output)
terraform output get_argocd_loadbalancer_command | sh

# Windows (WSL)
wsl bash -lc "$(terraform output -raw get_argocd_loadbalancer_command)"
```

**Отримайте пароль адміністратора:**
```bash
# Linux/macOS
terraform output -raw get_argocd_password_command | sh

# Або напряму (Linux/macOS):
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d

# Windows (PowerShell):
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' |
  ForEach-Object { [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_)) }
```

**Логін:**
- Username: `admin`
- Password: [output з попередньої команди]
- URL: `http://[LOADBALANCER_URL]` (без порту)

### 4.2 Перевірка Argo CD Application

1. Chart `argocd-apps` створює Application `django-app` автоматично.
2. Перевірте наявність ресурсу:
  ```bash
  kubectl get application -n argocd
  ```
3. Після появи `django-app`, перевірте статус синхронізації. Application створить namespace `default` та задеплоїть Django app.

### 4.3 Налаштування Auto-Sync (якщо потрібно)

Auto-sync вже налаштований через Terraform. Перевірте:

```bash
kubectl get application django-app -n argocd -o yaml
```

Ви маєте побачити:
```yaml
spec:
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Крок 5: Запуск CI/CD Pipeline

### 5.1 Зробіть зміни в коді

Наприклад, змініть щось у Django застосунку або просто запустіть pipeline.

### 5.2 Запустіть Jenkins Pipeline

1. Перейдіть в Jenkins UI
2. Виберіть `django-app-pipeline`
3. Click **Build Now**

### 5.3 Моніторинг Pipeline

Pipeline виконає наступні етапи:
1. Checkout Code - клонування репозиторію
2. Build Docker Image with Kaniko - збірка образу
3. Update Helm Chart - оновлення values.yaml з новим тегом
4. Verify Argo CD Sync - підтвердження

### 5.4 Перевірка Argo CD

1. Перейдіть в Argo CD UI
2. `django-app` має автоматично синхронізуватись
3. Перевірте статус деплойменту

## Перевірка роботи

### Перевірка подів

```bash
# Перевірте Jenkins
kubectl get pods -n jenkins

# Перевірте Argo CD
kubectl get pods -n argocd

# Перевірте Django app
kubectl get pods -n default
kubectl get svc -n default
```

### Перевірка образів в ECR

```bash
# Список образів
aws ecr list-images --repository-name django-app-lesson8-9 --region us-west-2
```

### Перевірка Git історії

```bash
# Перевірте коміти в charts/django-app/values.yaml
git log --oneline charts/django-app/values.yaml
```

### Доступ до Django app

```bash
# Отримайте Service URL (якщо LoadBalancer)
kubectl get svc django-app -n default

# Або використайте port-forward
kubectl port-forward svc/django-app 8000:80 -n default
```

Відкрийте в браузері: `http://localhost:8000`

## Видалення ресурсів

**⚠️ ВАЖЛИВО**: Видаляйте ресурси в правильному порядку!

### Крок 1: Видалення Argo CD Applications

```bash
kubectl delete application django-app -n argocd
```

### Крок 2: Видалення всіх deployments

```bash
kubectl delete all --all -n default
```

### Крок 3: Видалення інфраструктури через Terraform

```bash
cd lesson-8-9
terraform destroy
```

Підтвердьте видалення. Процес займе 10-15 хвилин.

### Крок 4: Видалення образів з ECR (опціонально)

```bash
# Видалити всі образи перед видаленням репозиторію
aws ecr batch-delete-image \
    --repository-name django-app-lesson8-9 \
    --image-ids imageTag=latest \
    --region us-west-2
```

### Крок 5: Видалення IAM ролей (якщо створювали)

```bash
aws iam detach-role-policy --role-name jenkins-ecr-role --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser
aws iam delete-role --role-name jenkins-ecr-role
```

## Troubleshooting

### Малий кластер і ресурси компонентів

Для кластера з одним вузлом `t3.small` ресурси компонентів зменшені у `modules/jenkins/values.yaml` і `modules/argo_cd/values.yaml`. Якщо `argocd-application-controller` не розміщується (Insufficient memory), зменште запити (requests) або тимчасово масштабуйте кластер.

### Jenkins не може пушити образ в ECR

**Симптоми**: Pipeline fails на етапі "Build Docker Image with Kaniko"

**Рішення**:
```bash
# Перевірте чи ServiceAccount анотований
kubectl describe sa jenkins -n jenkins

# Якщо немає анотації, додайте:
kubectl annotate serviceaccount jenkins -n jenkins \
  eks.amazonaws.com/role-arn=arn:aws:iam::ACCOUNT_ID:role/jenkins-ecr-role \
  --overwrite

# Рестартуйте Jenkins pod
kubectl delete pod -l app.kubernetes.io/name=jenkins -n jenkins
```

### Argo CD не синхронізується автоматично

**Симптоми**: Application в стані "OutOfSync" і не оновлюється

**Рішення**:
```bash
# Перевірте application конфігурацію
kubectl get application django-app -n argocd -o yaml

# Manually trigger sync
kubectl patch application django-app -n argocd \
  --type merge -p '{"operation":{"sync":{}}}'

# Або через CLI
argocd app sync django-app
```

### Pod не може витягнути образ з ECR

**Симптоми**: `ImagePullBackOff` error

**Рішення**:
```bash
# Перевірте, чи Node IAM role має доступ до ECR
aws iam list-attached-role-policies \
  --role-name lesson-8-9-node-group-role

# Додайте політику якщо потрібно
aws iam attach-role-policy \
  --role-name lesson-8-9-node-group-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
```

### LoadBalancer не створюється

**Симптоми**: Service в стані "Pending"

**Рішення**:
```bash
# Перевірте AWS Load Balancer Controller
kubectl get pods -n kube-system | grep aws-load-balancer

# Перевірте events
kubectl describe svc jenkins -n jenkins
kubectl describe svc argocd-server -n argocd

# Якщо потрібно встановити AWS Load Balancer Controller:
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=lesson-8-9-eks-cluster
```

### Terraform apply fails на Jenkins/Argo CD модулі

**Симптоми**: Error під час helm_release

**Рішення**:
```bash
# Перевірте, чи kubectl налаштований правильно
kubectl get nodes

# Видаліть lock файли якщо потрібно
rm -rf .terraform/
terraform init

# Спробуйте apply знову з target
terraform apply -target=module.eks
terraform apply -target=module.jenkins
terraform apply -target=module.argocd
```

---
**Примітка**: Завжди видаляйте невикористані AWS ресурси щоб уникнути непередбачуваних витрат!
