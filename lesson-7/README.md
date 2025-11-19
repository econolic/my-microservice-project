# Кластер EKS Kubernetes з розгортанням через Helm - Lesson 7

Цей урок демонструє розгортання Django додатку на AWS EKS (Elastic Kubernetes Service) використовуючи Terraform для створення інфраструктури та Helm для розгортання додатку.

## Огляд архітектури

- **EKS Кластер**: Kubernetes 1.28 з керованими групами вузлів
- **VPC**: мережева конфігурація (10.0.0.0/16)
- **ECR**: приватний Docker registry для образів Django додатку
- **Helm Chart**: Kubernetes deployment з автомасштабуванням та балансуванням навантаження
- **S3 Backend**: централізоване управління станом Terraform

## Структура директорій

```
lesson-7/
├── main.tf                 # Головна конфігурація Terraform
├── variables.tf            # Вхідні змінні
├── outputs.tf              # Вихідні значення
├── backend.tf              # Конфігурація S3 backend (закоментовано)
├── .gitignore              # Terraform-специфічні ігнори
├── deploy.sh               # Скрипт розгортання для Linux/WSL/Mac
├── deploy.ps1              # Скрипт розгортання для Windows PowerShell
├── modules/
│   ├── s3-backend/         # S3 + DynamoDB для управління станом
│   ├── vpc/                # VPC з публічними/приватними підмережами
│   ├── ecr/                # Container registry
│   └── eks/                # EKS кластер та групи вузлів
│       ├── variables.tf
│       ├── eks.tf
│       └── outputs.tf
└── charts/
    └── django-app/         # Helm chart для Django додатку
        ├── Chart.yaml
        ├── values.yaml
        └── templates/
            ├── _helpers.tpl
            ├── configmap.yaml
            ├── deployment.yaml
            ├── service.yaml
            ├── hpa.yaml
            └── serviceaccount.yaml
```

## Передумови

### 1. Права AWS IAM

Ваш IAM користувач потребує наступні AWS managed policies:

```bash
# Додати policies через AWS CLI
aws iam attach-user-policy --user-name it --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
aws iam attach-user-policy --user-name it --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess
aws iam attach-user-policy --user-name it --policy-arn arn:aws:iam::aws:policy/AmazonVPCFullAccess
aws iam attach-user-policy --user-name it --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess
aws iam attach-user-policy --user-name it --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess
aws iam attach-user-policy --user-name it --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
aws iam attach-user-policy --user-name it --policy-arn arn:aws:iam::aws:policy/IAMFullAccess
```

**Примітка**: Для навчальних цілей можна тимчасово використати `AdministratorAccess`, але для production обов'язково використовуйте принцип найменших привілеїв.

### 2. Необхідні інструменти

- **Terraform** >= 1.0
- **AWS CLI** налаштований з credentials
- **Docker** для побудови образів
- **kubectl** для управління Kubernetes
- **Helm** >= 3.0 для розгортання charts

Встановлення kubectl та Helm на Windows:
```powershell
# Встановити kubectl
choco install kubernetes-cli

# Встановити Helm
choco install kubernetes-helm
```

Або завантажити з:
- kubectl: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
- Helm: https://helm.sh/docs/intro/install/

## Покрокове розгортання

### Фаза 1: Створення інфраструктури через Terraform

#### 1.1 Ініціалізація Terraform (WSL)

```bash
cd lesson-7
terraform init
```

#### 1.2 Перегляд та застосування конфігурації

```bash
# Переглянути що буде створено
terraform plan

# Створити всю інфраструктуру
terraform apply
```

Це створить приблизно **38 ресурсів**:
- S3 bucket для зберігання стану
- DynamoDB таблиця для блокування стану
- VPC з 6 підмережами в 3 availability zones
- NAT Gateway та Internet Gateway
- ECR репозиторій для Docker образів
- EKS кластер з control plane
- EKS керована група вузлів з 2 нодами
- IAM ролі та security groups

**Очікуваний час**: 15-20 хвилин (створення EKS кластера повільне)

#### 1.3 Збереження важливих outputs

```bash
terraform output > infrastructure-info.txt
```

#### 1.4 Міграція на S3 Backend

Після успішного створення:

1. Розкоментуйте конфігурацію в `backend.tf`
2. Запустіть міграцію:
```bash
terraform init -migrate-state
```

### Фаза 2: Побудова та завантаження Docker образу

#### 2.1 Автентифікація Docker в ECR

Отримайте ECR repository URL з Terraform outputs:
```bash
terraform output -raw ecr_info
```

Увійдіть в ECR (Windows PowerShell):
```powershell
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 978045176156.dkr.ecr.us-west-2.amazonaws.com
```

#### 2.2 Побудова Django образу

З кореневої директорії проекту:
```powershell
docker build -t django-app-lesson7 .
```

#### 2.3 Тегування та завантаження в ECR

```powershell
# Тегування образу
docker tag django-app-lesson7:latest 978045176156.dkr.ecr.us-west-2.amazonaws.com/django-app-lesson7:latest

# Завантаження в ECR
docker push 978045176156.dkr.ecr.us-west-2.amazonaws.com/django-app-lesson7:latest
```

**Альтернатива**: Використайте скрипт автоматизації:
```bash
# Linux/WSL/Mac
./deploy.sh

# Windows PowerShell
.\deploy.ps1
```

### Фаза 3: Налаштування kubectl

#### 3.1 Оновлення kubeconfig

Отримайте команду kubeconfig з Terraform outputs:
```bash
terraform output -raw kubeconfig_command
```

Виконайте її:
```bash
aws eks update-kubeconfig --region us-west-2 --name lesson-7-eks-cluster
```

#### 3.2 Перевірка доступу до кластера

```bash
kubectl get nodes
kubectl cluster-info
```

Ви повинні побачити 2 ноди в стані Ready.

### Фаза 4: Розгортання додатку через Helm

#### 4.1 Оновлення Helm Values (якщо потрібно)

Відредагуйте `charts/django-app/values.yaml`:
- Оновіть `image.repository` якщо ваш ECR URL відрізняється
- Змініть `django.database.*` налаштування для production бази даних
- Оновіть `django.secretKey` на безпечне випадкове значення

#### 4.2 Встановлення Helm Chart

З директорії lesson-7:
```bash
helm install django-app ./charts/django-app
```

#### 4.3 Моніторинг розгортання

```bash
# Спостереження за запуском подів
kubectl get pods -w

# Перевірка статусу розгортання
kubectl rollout status deployment/django-app

# Перегляд всіх ресурсів
kubectl get all
```

#### 4.4 Отримання URL LoadBalancer

```bash
kubectl get service django-app -o wide
```

Зачекайте поки з'явиться `EXTERNAL-IP` (може зайняти 2-3 хвилини). Це URL вашого додатку.

#### 4.5 Тестування додатку

```bash
curl http://<EXTERNAL-IP>
```

Або відкрийте в браузері: `http://<EXTERNAL-IP>`

### Фаза 5: Перевірка автомасштабування

#### 5.1 Перевірка статусу HPA

```bash
kubectl get hpa
```

Ви повинні побачити:
```
NAME         REFERENCE               TARGETS   MINPODS   MAXPODS   REPLICAS
django-app   Deployment/django-app   0%/70%    2         6         2
```

#### 5.2 Генерація навантаження (Опціонально)

Для тестування автомасштабування:
```bash
# Встановити hey для навантажувального тестування
go install github.com/rakyll/hey@latest

# Згенерувати навантаження
hey -z 2m -c 50 http://<EXTERNAL-IP>
```

Спостерігайте за масштабуванням HPA:
```bash
kubectl get hpa -w
```

## Деталі конфігурації

### Конфігурація Helm Chart

Django Helm chart включає:

**deployment.yaml**:
- 2 репліки за замовчуванням (контролюється HPA)
- Перевірки здоров'я (liveness та readiness probes)
- Запити ресурсів: 250m CPU, 256Mi пам'яті
- Ліміти ресурсів: 500m CPU, 512Mi пам'яті
- Змінні оточення з ConfigMap та Secret

**service.yaml**:
- Тип: LoadBalancer (створює AWS ELB)
- Порт: 80 → 8000 (зовнішній → внутрішній)

**hpa.yaml**:
- Мін реплік: 2
- Макс реплік: 6
- Масштабування на: 70% CPU або 80% пам'яті

**configmap.yaml**:
- Неконфіденційна конфігурація (DATABASE_HOST, DATABASE_NAME, тощо)
- Налаштування Django (DEBUG, ALLOWED_HOSTS)

**Secret** (в configmap.yaml):
- Конфіденційні дані (DATABASE_PASSWORD, SECRET_KEY)

### Змінні оточення

Django додаток отримує ці змінні з Kubernetes:

```yaml
DATABASE_NAME: myproject_db
DATABASE_USER: myproject_user
DATABASE_PASSWORD: myproject_password  # з Secret
DATABASE_HOST: postgres-service
DATABASE_PORT: "5432"
DEBUG: "False"
SECRET_KEY: <secure-random-key>  # з Secret
ALLOWED_HOSTS: "*"
```

**Примітка**: Ця конфігурація передбачає PostgreSQL сервіс який працює в кластері. Для production розгляньте AWS RDS.

## Корисні команди

### Terraform

```bash
# Показати поточний стан
terraform show

# Список всіх ресурсів
terraform state list

# Отримати конкретний output
terraform output eks_info

# Видалити все (обережно!)
terraform destroy
```

### Kubernetes

```bash
# Отримати всі ресурси
kubectl get all

# Описати pod
kubectl describe pod <pod-name>

# Переглянути логи
kubectl logs <pod-name>
kubectl logs -f <pod-name>  # слідкувати

# Виконати команду в поді
kubectl exec -it <pod-name> -- /bin/bash

# Отримати події
kubectl get events --sort-by='.lastTimestamp'

# Масштабувати вручну (тимчасово перевизначає HPA)
kubectl scale deployment django-app --replicas=4
```

### Helm

```bash
# Список релізів
helm list

# Отримати values
helm get values django-app

# Оновити реліз
helm upgrade django-app ./charts/django-app

# Відкотити
helm rollback django-app

# Видалити
helm uninstall django-app
```

### Docker/ECR

```bash
# Список локальних образів
docker images

# Переглянути ECR репозиторії
aws ecr describe-repositories

# Список образів в ECR
aws ecr list-images --repository-name django-app-lesson7

# Видалити образ з ECR
aws ecr batch-delete-image --repository-name django-app-lesson7 --image-ids imageTag=latest
```

## Production міркування

### Безпека

1. **Управління секретами**: Використовуйте AWS Secrets Manager або external-secrets operator
2. **Мережеві політики**: Впровадьте Kubernetes NetworkPolicies
3. **Безпека подів**: Увімкніть Pod Security Standards
4. **RBAC**: Налаштуйте рольовий контроль доступу
5. **Security Groups**: Обмежте security groups нод

### База даних

**Варіант 1: RDS PostgreSQL** (Рекомендовано)
```bash
# Створити RDS інстанс через Terraform
# Оновити values.yaml:
django:
  database:
    host: mydb.xxxx.us-west-2.rds.amazonaws.com
    name: myproject_db
    user: postgres
    password: <from-secrets-manager>
```

**Варіант 2: PostgreSQL в Kubernetes**
```bash
# Використати Bitnami PostgreSQL chart
helm install postgres oci://registry-1.docker.io/bitnamicharts/postgresql
```

### Моніторинг

```bash
# Встановити Prometheus + Grafana
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack

# Встановити AWS CloudWatch Container Insights
# Слідуйте: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-setup-EKS-quickstart.html
```

### Оптимізація витрат

1. **Використання Spot Instances**: Додайте spot instance групу нод
2. **Cluster Autoscaler**: Масштабування нод на основі попиту
3. **Правильний розмір ресурсів**: Налаштуйте requests/limits на основі реального використання
4. **Видалення Dev ресурсів**: Видаляйте коли не використовуєте

### Висока доступність

1. **Multi-AZ розгортання**: Ноди розподілені по 3 AZ (вже налаштовано)
2. **Pod Disruption Budget**: Гарантуйте мінімум реплік під час оновлень
3. **Readiness Gates**: Запобігайте трафіку до нездорових подів
4. **Affinity Rules**: Розподіляйте поди по нодах/зонах

## Усунення неполадок

### Проблема: Помилка створення EKS кластера

**Рішення**: Перевірте IAM права та service quotas
```bash
aws eks describe-cluster --name lesson-7-eks-cluster
aws service-quotas list-service-quotas --service-code eks
```

### Проблема: Поди застрягли в Pending

**Рішення**: Перевірте статус нод та події
```bash
kubectl get nodes
kubectl describe pod <pod-name>
```

Поширені причини:
- Недостатня ємність нод → Масштабуйте групу нод
- Помилки завантаження образу → Перевірте автентифікацію ECR
- Обмеження ресурсів → Зменшіть requests/limits

### Проблема: LoadBalancer EXTERNAL-IP Pending

**Рішення**: Перевірте створення AWS ELB
```bash
kubectl describe service django-app
```

Перевірте в AWS Console: EC2 → Load Balancers

### Проблема: Додаток повертає 502/503

**Рішення**: Перевірте здоров'я подів та логи
```bash
kubectl get pods
kubectl logs <pod-name>
kubectl describe pod <pod-name>
```

Поширені причини:
- Додаток не слухає на порту 8000
- Перевірка здоров'я не проходить
- Проблеми з підключенням до бази даних

### Проблема: HPA не масштабується

**Рішення**: Перевірте metrics server
```bash
kubectl top nodes
kubectl top pods
```

Якщо метрики недоступні, встановіть metrics-server:
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

## Очищення

**Важливо**: Спочатку видалити Kubernetes ресурси, потім Terraform!

### Крок 1: Видалити Kubernetes ресурси

```bash
# LoadBalancer створює AWS ресурси поза Terraform!
kubectl delete all --all

# Почекати 1-2 хвилини поки AWS видалить LoadBalancer
```

### Крок 2: Видалити Terraform інфраструктуру

```bash
cd lesson-7
terraform destroy -auto-approve
```

### Якщо terraform destroy не вдається

```bash
# Знайти Security Groups створені Kubernetes
aws ec2 describe-security-groups --region us-west-2 \
  --filters "Name=vpc-id,Values=<VPC_ID>" \
  --query 'SecurityGroups[?GroupName!=`default`].[GroupId,GroupName]'

# Видалити їх вручну
aws ec2 delete-security-group --group-id <SG_ID> --region us-west-2

# Повторити terraform destroy
terraform destroy -auto-approve
```

### Очищення ECR образів

Якщо хочете видалити ECR образи перед видаленням:
```bash
aws ecr batch-delete-image \
  --repository-name django-app-lesson7 \
  --image-ids imageTag=latest
```

