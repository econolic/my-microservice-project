# Terraform Infrastructure - Lesson 5

Проект для розгортання AWS інфраструктури за допомогою Terraform з використанням модульної архітектури.

## Структура проекту

```
lesson-5/
├── main.tf                  # Головний файл з підключенням модулів
├── backend.tf               # Налаштування S3 backend для стейтів
├── variables.tf             # Змінні проекту
├── outputs.tf               # Виведення інформації про ресурси
├── terraform.tfvars         # Значення змінних (не комітиться в git)
├── terraform.tfvars.example # Приклад конфігурації
├── .gitignore              # Git ignore для Terraform
│
└── modules/
    ├── s3-backend/         # Модуль S3 та DynamoDB для стейтів
    │   ├── s3.tf
    │   ├── dynamodb.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── vpc/                # Модуль мережевої інфраструктури
    │   ├── vpc.tf
    │   ├── routes.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    └── ecr/                # Модуль ECR репозиторію
        ├── ecr.tf
        ├── variables.tf
        └── outputs.tf
```

## Опис модулів

### s3-backend
Модуль створює інфраструктуру для зберігання Terraform стейтів:
- **S3 Bucket**: для зберігання state файлів з увімкненим версіонуванням та шифруванням
- **DynamoDB Table**: для блокування стейтів під час concurrent операцій
- **Security**: блокування публічного доступу, lifecycle policy для очищення старих версій

### vpc
Модуль створює мережеву інфраструктуру:
- **VPC**: з кастомним CIDR блоком
- **Subnets**: 3 публічні + 3 приватні підмережі в різних AZ
- **Internet Gateway**: для публічних підмереж
- **NAT Gateway**: для приватних підмереж (опціонально single або per-AZ)
- **Route Tables**: налаштування маршрутизації

### ecr
Модуль створює ECR репозиторій для Docker образів:
- **ECR Repository**: з автоматичним скануванням на вразливості
- **Lifecycle Policy**: автоматичне видалення старих образів
- **Repository Policy**: контроль доступу на рівні організації
- **Encryption**: шифрування образів

## Передумови

- Terraform >= 1.0
- AWS CLI налаштований з credentials
- AWS акаунт з необхідними правами

## Налаштування IAM прав користувача

Для успішного створення всієї інфраструктури AWS IAM користувач повинен мати наступні права:

### Необхідні AWS Managed Policies:
1. **AmazonS3FullAccess** - для створення та управління S3 bucket
2. **AmazonDynamoDBFullAccess** - для створення DynamoDB таблиці
3. **AmazonVPCFullAccess** - для створення VPC інфраструктури
4. **AmazonEC2FullAccess** - для створення EIP, NAT Gateway та інших EC2 ресурсів
5. **AmazonEC2ContainerRegistryFullAccess** - для створення ECR репозиторію

### Додавання прав через AWS Console:
1. Увійдіть в AWS Console
2. Перейдіть: **IAM** → **Users** → виберіть свого користувача
3. Вкладка **Permissions** → **Add permissions** → **Attach policies directly**
4. Знайдіть і додайте вищезазначені policies
5. Натисніть **Add permissions**

### Додавання прав через AWS CLI:
```bash
# Замініть 'username' на ім'я вашого користувача
aws iam attach-user-policy --user-name username --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
aws iam attach-user-policy --user-name username --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess
aws iam attach-user-policy --user-name username --policy-arn arn:aws:iam::aws:policy/AmazonVPCFullAccess
aws iam attach-user-policy --user-name username --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess
aws iam attach-user-policy --user-name username --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess
```

### Перевірка прав:
```bash
# Перевірка поточного користувача
aws sts get-caller-identity

# Перегляд attached policies
aws iam list-attached-user-policies --user-name username
```

**Важливо**: Без цих прав Terraform не зможе створити ресурси і видасть помилки типу `AccessDenied` або `UnauthorizedOperation`.

## Налаштування AWS credentials

```bash
aws configure
```

Або встановіть змінні оточення:
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"
```

## Крок 1: Початкове розгортання

### 1.1 Налаштування змінних

Створіть `terraform.tfvars` на основі прикладу:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Відредагуйте `terraform.tfvars` зі своїми значеннями:
```hcl
s3_bucket_name = "terraform-state-budyakov-lesson5"
```

### 1.2 Перший запуск (без remote backend)

Переконайтеся, що `backend.tf` закоментований (за замовчуванням так і є).

```bash
# Ініціалізація Terraform
terraform init

# Перегляд плану
terraform plan

# Застосування змін (створення S3, DynamoDB, VPC, ECR)
terraform apply
```

При запиті підтвердження введіть `yes`.

### 1.3 Міграція на remote backend

Після успішного створення ресурсів:

1. Розкоментуйте блок в `backend.tf`:
```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-budyakov-lesson5"
    key            = "lesson-5/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

2. Мігрируйте стейт:
```bash
terraform init -migrate-state
```

При запиті підтвердіть міграцію введенням `yes`.

## Основні команди

```bash
# Форматування коду
terraform fmt -recursive

# Валідація конфігурації
terraform validate

# Перегляд плану змін
terraform plan

# Застосування змін
terraform apply

# Застосування без підтвердження
terraform apply -auto-approve

# Перегляд поточного стейту
terraform show

# Перегляд outputs
terraform output

# Детальний output конкретного значення
terraform output ecr_info
```

## Робота з ECR

### Логін в ECR
```bash
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <registry-id>.dkr.ecr.us-west-2.amazonaws.com
```

### Push образу в ECR
```bash
# Tag образу
docker tag your-image:latest <repository-url>:latest

# Push образу
docker push <repository-url>:latest
```

Отримати repository URL можна з output:
```bash
terraform output -raw ecr_info
```

## Управління ресурсами

### Оновлення інфраструктури
```bash
terraform plan
terraform apply
```

### Таргетоване оновлення модуля
```bash
terraform apply -target=module.vpc
```

### Перегляд конкретного ресурсу
```bash
terraform state show module.vpc.aws_vpc.main
```

## Видалення інфраструктури

**УВАГА**: Видалення ресурсів призведе до втрати даних. Переконайтеся, що у вас є резервні копії.

```bash
terraform destroy
```

### Важливо при видаленні всього
Якщо видаляєте всю інфраструктуру включно з S3 та DynamoDB:

1. Видаліть ресурси:
```bash
terraform destroy
```

2. Для повторного розгортання треба знову почати з локального backend (закоментувати `backend.tf`)

### Часткове видалення
```bash
# Видалити тільки ECR
terraform destroy -target=module.ecr

# Видалити тільки VPC
terraform destroy -target=module.vpc
```

## Безпека

### Що НЕ комітити в git
- `terraform.tfvars` - містить реальні значення
- `*.tfstate` - містить чутливу інформацію про інфраструктуру
- AWS credentials
- `.terraform/` - провайдери та модулі

### Що комітити
- `terraform.tfvars.example` - приклад без реальних даних
- `.terraform.lock.hcl` - версії провайдерів
- Всі `.tf` файли
- `.gitignore`

## Troubleshooting

### Проблема: "Error acquiring the state lock"
```bash
# Видалити блокування (обережно!)
terraform force-unlock <LOCK_ID>
```

### Проблема: "NoSuchBucket" при міграції
Переконайтеся, що S3 bucket створений:
```bash
aws s3 ls | grep terraform-state
```

### Проблема: Версії провайдерів
```bash
# Оновити провайдери
terraform init -upgrade
```

### Проблема: AWS credentials
```bash
# Перевірити credentials
aws sts get-caller-identity
```