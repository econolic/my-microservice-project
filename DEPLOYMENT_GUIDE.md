# Final Project Deployment Guide
## Complete DevOps Infrastructure on AWS

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Pre-Deployment Checklist](#pre-deployment-checklist)
4. [Deployment Steps](#deployment-steps)
5. [Post-Deployment Configuration](#post-deployment-configuration)
6. [Validation & Testing](#validation--testing)
7. [Access Services](#access-services)
8. [Troubleshooting](#troubleshooting)
9. [Cleanup](#cleanup)

---

## Overview

This deployment creates a complete DevOps infrastructure on AWS including:

- **Infrastructure as Code:** Terraform
- **Container Orchestration:** Amazon EKS (Kubernetes 1.28)
- **Networking:** VPC with public/private subnets
- **Database:** RDS PostgreSQL 16.1
- **Container Registry:** Amazon ECR
- **CI/CD:** Jenkins + Argo CD (GitOps)
- **Monitoring:** Prometheus + Grafana
- **Application:** Django web application

### Architecture Components

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
│  │                    │  (t3.small) │                         │  │
│  │                    │             │                         │  │
│  │                    │  - Jenkins  │                         │  │
│  │                    │  - Argo CD  │                         │  │
│  │  ┌──────────────┐  │  - Prometheus│  ┌──────────────┐     │  │
│  │  │   Private    │  │  - Grafana  │  │   Private    │     │  │
│  │  │   Subnet     │  │  - Django   │  │   Subnet     │     │  │
│  │  │ 10.0.4.0/24  │  └─────────────┘  │ 10.0.6.0/24  │     │  │
│  │  │              │                   │              │     │  │
│  │  │  ┌────────┐  │                   │              │     │  │
│  │  │  │  RDS   │  │                   │              │     │  │
│  │  │  │  PG16  │  │                   │              │     │  │
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

## Prerequisites

### Required Software

| Tool | Version | Installation |
|------|---------|--------------|
| Terraform | >= 1.0 | https://www.terraform.io/downloads |
| AWS CLI | >= 2.0 | https://aws.amazon.com/cli/ |
| kubectl | >= 1.28 | https://kubernetes.io/docs/tasks/tools/ |
| Git | Latest | https://git-scm.com/ |
| WSL (Windows) | Ubuntu 20.04+ | https://docs.microsoft.com/windows/wsl |

### AWS Account Setup

```bash
# Configure AWS credentials
aws configure

# Required inputs:
# - AWS Access Key ID: [Your Access Key]
# - AWS Secret Access Key: [Your Secret Key]
# - Default region: us-west-2
# - Default output format: json

# Verify configuration
aws sts get-caller-identity
```

### GitHub Setup

1. **Create Personal Access Token (PAT)**:
   - Go to GitHub Settings → Developer settings → Personal access tokens
   - Click "Generate new token (classic)"
   - Select scopes: `repo` (full), `workflow`
   - Copy token and save securely

2. **Fork/Clone Repository**:
   ```bash
   git clone https://github.com/econolic/my-microservice-project.git
   cd my-microservice-project
   ```

---

## Pre-Deployment Checklist

### 1. Security Configuration

⚠️ **CRITICAL**: Never commit secrets to Git!

```bash
# Ensure .gitignore includes sensitive files
cat .gitignore | grep terraform.tfvars

# Should include:
# terraform.tfvars
# .terraform/
# terraform.tfstate*
```

### 2. Create terraform.tfvars

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
# IMPORTANT: Update these values!

# GitHub Configuration
github_token    = "ghp_YOUR_GITHUB_TOKEN_HERE"    # ⚠️ Update this!
github_username = "your-username"                  # ⚠️ Update this!
github_repo_url = "https://github.com/your-username/my-microservice-project.git"

# Jenkins Configuration
jenkins_admin_password = "YourSecurePassword123!"  # ⚠️ Use strong password!

# RDS Database Configuration
rds_master_password = "SecureDbPassword123!"       # ⚠️ Use strong password!

# Other configurations can use defaults
```

**What happens with secrets:**

1. **terraform.tfvars** - local file, protected by .gitignore
2. **Terraform apply** → creates secrets in **AWS Secrets Manager**
3. **AWS Secrets Manager** → stores encrypted secrets
4. **EKS Pods** → access via IAM roles

```bash
# Verify secrets will NOT be committed to Git
git check-ignore terraform.tfvars
# Should output: terraform.tfvars

# After terraform apply, retrieve secrets:
terraform output get_github_token_command
terraform output get_rds_password_command
```

### 3. Security Scanning Setup (Optional but Recommended)

```bash
# Install pre-commit hooks
pip install pre-commit
pre-commit install

# Run all checks
pre-commit run --all-files
```

**What is checked:**
- tfsec - Terraform security issues
- GitLeaks - secrets detection in code
- Hadolint - Dockerfile best practices
- YAML/Markdown syntax

📖 More details: [SECURITY_SETUP.md](./SECURITY_SETUP.md)

### 4. Verify AWS Quotas

Ensure your AWS account has sufficient limits:
- VPC: 1
- EKS Clusters: 1
- RDS Instances: 1
- EC2 Instances (t3.small): 2
- Elastic Load Balancers: 4

---

## Deployment Steps

### Step 1: Initialize Terraform

```bash
# Initialize Terraform (from project root)
terraform init

# Expected output:
# Terraform has been successfully initialized!
```

### Step 2: Validate Configuration

```bash
# Validate syntax
terraform validate

# Preview changes
terraform plan

# Review the plan - should show creation of ~50-60 resources
```

### Step 3: Deploy Infrastructure

```bash
# Apply configuration
terraform apply

# Review the plan and type 'yes' when prompted
# ⏱️ Deployment takes 15-20 minutes
```

**What gets created:**
1. S3 bucket + DynamoDB table (state management)
2. VPC with 6 subnets (3 public, 3 private)
3. NAT Gateway, Internet Gateway, Route Tables
4. EKS Cluster (Kubernetes 1.28)
5. EKS Node Group (t3.small instances)
6. ECR Repository for Docker images
7. RDS PostgreSQL 16.1 instance
8. Jenkins (Helm deployment)
9. Argo CD (Helm deployment)
10. Prometheus + Grafana (Helm deployment)

### Step 4: Configure kubectl

```bash
# Get kubeconfig
aws eks update-kubeconfig --region us-west-2 --name final-project-eks-cluster

# Verify connection
kubectl get nodes

# Expected output:
# NAME                                         STATUS   ROLES    AGE   VERSION
# ip-10-0-x-x.us-west-2.compute.internal      Ready    <none>   5m    v1.28.x
```

### Step 5: Verify Deployments

```bash
# Check all namespaces
kubectl get namespaces

# Expected namespaces:
# - default
# - jenkins
# - argocd
# - monitoring
# - kube-system

# Check pods in each namespace
kubectl get pods -n jenkins
kubectl get pods -n argocd
kubectl get pods -n monitoring
kubectl get pods -n default
```

---

## Post-Deployment Configuration

### 1. Verify Secrets in AWS Secrets Manager

**Verify secrets were created:**

```bash
# List all secrets
aws secretsmanager list-secrets --query 'SecretList[?contains(Name, `final-project`)].Name'

# Should display:
# - final-project-github-token
# - final-project-jenkins-admin-password
# - final-project-rds-master-password

# Get secret value (for verification)
aws secretsmanager get-secret-value \
  --secret-id final-project-rds-master-password \
  --query SecretString --output text
```

**Outputs for quick access:**

```bash
# Commands to retrieve secrets
terraform output get_github_token_command
terraform output get_rds_password_command
terraform output github_token_secret_name
```

### 2. Update Django Helm Chart with RDS Endpoint

**CRITICAL STEP**: The Django application needs the actual RDS endpoint.

```bash
# 1. Get RDS endpoint from Terraform
terraform output db_endpoint

# Output example:
# lesson-db-postgres.c1a2b3c4d5e6.us-west-2.rds.amazonaws.com:5432

# 2. Extract hostname (without port)
DB_HOST=$(terraform output -raw db_endpoint | cut -d: -f1)
echo $DB_HOST

# 3. Update Helm chart
cd charts/django-app
sed -i "s/REPLACE_WITH_RDS_ENDPOINT/$DB_HOST/g" values.yaml

# 4. Verify the change
grep "host:" values.yaml

# Should show:
# host: "lesson-db-postgres.c1a2b3c4d5e6.us-west-2.rds.amazonaws.com"

# 5. Commit and push changes
git add values.yaml
git commit -m "feat: Update RDS endpoint for Django application"
git push origin final-project
```

### 2. Configure Jenkins

**Get Jenkins URL and Password:**

```bash
# Get LoadBalancer URL
kubectl get svc jenkins -n jenkins

# Get admin password
terraform output -raw jenkins_admin_password
```

**Access Jenkins:**
1. Open: `http://[LOADBALANCER_URL]:8080`
2. Login: `admin` / [password from above]

**Add Credentials:**

Navigate to: **Manage Jenkins → Credentials → System → Global credentials**

Add these credentials:

| ID | Kind | Secret | Description |
|----|------|--------|-------------|
| `github-token` | Secret text | Your GitHub PAT | GitHub Access Token |
| `github-username` | Secret text | Your GitHub username | GitHub Username |
| `ecr-registry-url` | Secret text | `terraform output -raw ecr_repository_url` | ECR Registry URL |

### 3. Create Jenkins Pipeline

1. Click **New Item**
2. Name: `django-app-pipeline`
3. Type: **Pipeline**
4. Configure:
   - **Pipeline → Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: Your GitHub repo URL
   - **Credentials**: Select `github-token`
   - **Branch**: `*/final-project`
   - **Script Path**: `Django/Jenkinsfile`
5. Save

### 4. Configure Argo CD

**Get Argo CD URL and Password:**

```bash
# Get LoadBalancer URL
kubectl get svc argocd-server -n argocd

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d; echo
```

**Access Argo CD:**
1. Open: `http://[LOADBALANCER_URL]`
2. Login: `admin` / [password from above]
3. Verify `django-app` application is created
4. Wait for auto-sync to complete

---

## Validation & Testing

### 1. Verify All Pods Running

```bash
# Jenkins
kubectl get pods -n jenkins
# Should show: jenkins-0 (Running)

# Argo CD
kubectl get pods -n argocd
# Should show all argocd-* pods (Running)

# Monitoring
kubectl get pods -n monitoring
# Should show prometheus, grafana, alertmanager (Running)

# Django App
kubectl get pods -n default
# Should show: django-app-* pods (Running)
```

### 2. Test CI/CD Pipeline

```bash
# Make a code change
echo "# Test change" >> README.md

# Commit and push
git add .
git commit -m "test: Trigger CI/CD pipeline"
git push origin final-project

# Monitor Jenkins pipeline
# Go to Jenkins UI → django-app-pipeline → Build History

# Monitor Argo CD sync
# Go to Argo CD UI → django-app → Refresh

# Verify new pods deployed
kubectl get pods -n default -w
```

### 3. Test Database Connection

```bash
# Get RDS endpoint
terraform output db_endpoint

# Run PostgreSQL client pod
kubectl run -it --rm psql-test --image=postgres:16 --restart=Never -- \
  psql -h $(terraform output -raw db_endpoint | cut -d: -f1) \
  -U dbadmin -d djangodb

# If connected successfully, run:
\l          # List databases
\q          # Quit
```

### 4. Check Application Health

```bash
# Get Django service
kubectl get svc django-app -n default

# Port-forward to local
kubectl port-forward svc/django-app 8000:80 -n default

# Open browser: http://localhost:8000
# Should see Django default page
```

---

## Access Services

### Jenkins

```bash
# LoadBalancer URL
kubectl get svc jenkins -n jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Port-forward (alternative)
kubectl port-forward svc/jenkins 8080:8080 -n jenkins

# Access: http://localhost:8080
# Username: admin
# Password: terraform output -raw jenkins_admin_password
```

### Argo CD

```bash
# LoadBalancer URL
kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Port-forward (alternative)
kubectl port-forward svc/argocd-server 8081:443 -n argocd

# Access: http://localhost:8081
# Username: admin
# Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

### Grafana

```bash
# Port-forward
kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring

# Access: http://localhost:3000
# Username: admin
# Password: admin (change on first login)
```

**Recommended Dashboards:**
1. Kubernetes / Compute Resources / Cluster
2. Kubernetes / Compute Resources / Namespace (Pods)
3. Node Exporter / Nodes

### Prometheus

```bash
# Port-forward
kubectl port-forward svc/kube-prometheus-stack-prometheus 9090:9090 -n monitoring

# Access: http://localhost:9090
```

**Useful Queries:**
- `up` - Service status
- `container_cpu_usage_seconds_total` - CPU usage
- `container_memory_usage_bytes` - Memory usage
- `kube_pod_status_phase` - Pod status

### Django Application

```bash
# Port-forward
kubectl port-forward svc/django-app 8000:80 -n default

# Access: http://localhost:8000
```

---

## Troubleshooting

### Issue: Terraform Apply Fails

**Symptoms**: Error during `terraform apply`

**Solutions:**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Check quotas
aws service-quotas list-service-quotas --service-code ec2 | grep -A2 "QuotaName.*Running On-Demand Standard"

# Retry with specific target
terraform apply -target=module.vpc
terraform apply -target=module.eks
terraform apply
```

### Issue: Pods Stuck in Pending

**Symptoms**: Pods show `Pending` status

**Solutions:**
```bash
# Check node capacity
kubectl describe nodes

# Check pod events
kubectl describe pod [POD_NAME] -n [NAMESPACE]

# Scale node group if needed
# Edit terraform.tfvars: node_max_size = 3
# terraform apply
```

### Issue: Database Connection Failed

**Symptoms**: Django can't connect to RDS

**Solutions:**
```bash
# Verify RDS endpoint in Helm chart
kubectl get configmap -n default -o yaml | grep DATABASE_HOST

# Check RDS security group
aws ec2 describe-security-groups \
  --group-ids $(terraform output -raw db_security_group_id)

# Verify VPC CIDR is allowed
terraform output db_security_group_id

# Test connectivity
kubectl run -it --rm psql-test --image=postgres:16 --restart=Never -- \
  psql -h [RDS_ENDPOINT] -U dbadmin -d djangodb
```

### Issue: Grafana Shows No Data

**Symptoms**: Empty dashboards in Grafana

**Solutions:**
```bash
# Check Prometheus targets
kubectl port-forward svc/kube-prometheus-stack-prometheus 9090:9090 -n monitoring
# Open: http://localhost:9090/targets

# Verify ServiceMonitors
kubectl get servicemonitor -n monitoring

# Restart Prometheus
kubectl rollout restart statefulset/prometheus-kube-prometheus-stack-prometheus -n monitoring
```

### Issue: Secrets Not Found

**Symptoms**: Pods can't access database password or other secrets

**Solutions:**
```bash
# Verify secrets exist in AWS Secrets Manager
aws secretsmanager list-secrets --query 'SecretList[?contains(Name, `final-project`)].Name'

# Check Kubernetes secrets
kubectl get secrets -n default

# Verify secret in pod
kubectl describe pod [POD_NAME] -n default

# Manually create Kubernetes secret from AWS Secrets Manager (workaround)
DB_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id final-project-rds-master-password \
  --query SecretString --output text)

kubectl create secret generic django-db-secret \
  --from-literal=password=$DB_PASSWORD \
  -n default
```

### Issue: Pre-commit Hooks Failing

**Symptoms**: `git commit` fails with tfsec or other errors

**Solutions:**
```bash
# Skip hooks temporarily (not recommended)
git commit --no-verify -m "message"

# Fix Terraform formatting
terraform fmt -recursive

# Update pre-commit hooks
pre-commit autoupdate

# Run specific hook to debug
pre-commit run terraform_fmt --all-files
pre-commit run tfsec --all-files

# Reinstall hooks
pre-commit uninstall
pre-commit install
```

### Issue: GitHub Actions Security Scan Failed

**Symptoms**: Security workflow fails on push

**Solutions:**
```bash
# Check workflow logs in GitHub
# Actions → Security Scanning → Failed run

# Common fixes:
# 1. tfsec issues - fix reported security problems
# 2. Secrets detected - remove from code
# 3. Dockerfile issues - fix with hadolint locally

# Test locally before push
docker run --rm -v $(pwd):/src aquasec/tfsec /src
docker run --rm -i hadolint/hadolint < Django/Dockerfile
```

---

## Cleanup

⚠️ **WARNING**: This will delete ALL resources and incur no further costs.

### Step 1: Delete Kubernetes Resources

```bash
# Delete applications
kubectl delete application --all -n argocd

# Delete all workloads
kubectl delete all --all -n default
kubectl delete all --all -n monitoring
```

### Step 2: Destroy Terraform Infrastructure

```bash
# Destroy all resources (from project root)
terraform destroy

# Type 'yes' when prompted
# ⏱️ Destruction takes 10-15 minutes
```

### Step 3: Verify Cleanup

```bash
# Check AWS Console:
# - VPC: Deleted
# - EKS: Deleted
# - RDS: Deleted
# - ECR: Deleted (or empty)
# - S3: May remain (if versioned objects exist)
```

### Step 4: Manual Cleanup (if needed)

```bash
# Delete S3 bucket versions
aws s3api list-object-versions \
  --bucket terraform-state-budyakov-final-project \
  --output json | jq -r '.Versions[] | .Key + " " + .VersionId' | \
  while read key versionId; do
    aws s3api delete-object \
      --bucket terraform-state-budyakov-final-project \
      --key "$key" --version-id "$versionId"
  done

# Delete bucket
aws s3 rb s3://terraform-state-budyakov-final-project --force

# Delete DynamoDB table
aws dynamodb delete-table --table-name terraform-locks-final-project
```

---

## Additional Resources

- **Terraform AWS Provider**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **EKS Best Practices**: https://aws.github.io/aws-eks-best-practices/
- **Argo CD Documentation**: https://argo-cd.readthedocs.io/
- **Prometheus Operator**: https://github.com/prometheus-operator/prometheus-operator
- **Django on Kubernetes**: https://kubernetes.io/blog/2019/07/23/get-started-with-kubernetes-using-python/

---

**Good luck with your deployment!**
