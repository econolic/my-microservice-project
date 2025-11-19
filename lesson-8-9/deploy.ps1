# Deploy script for Lesson 8-9 CI/CD Infrastructure (PowerShell)
# This script automates the deployment process

$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting Lesson 8-9 Infrastructure Deployment..." -ForegroundColor Green

function Write-Status {
    param($Message)
    Write-Host "[✓] $Message" -ForegroundColor Green
}

function Write-Error-Message {
    param($Message)
    Write-Host "[✗] $Message" -ForegroundColor Red
}

function Write-Warning-Message {
    param($Message)
    Write-Host "[!] $Message" -ForegroundColor Yellow
}

# Check if terraform.tfvars exists
if (-not (Test-Path "terraform.tfvars")) {
    Write-Error-Message "terraform.tfvars not found!"
    Write-Warning-Message "Please copy terraform.tfvars.example to terraform.tfvars and configure it"
    exit 1
}

# Check required tools
Write-Status "Checking required tools..."

$tools = @("terraform", "aws", "kubectl")
foreach ($tool in $tools) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        Write-Error-Message "$tool is not installed. Aborting."
        exit 1
    }
}

Write-Status "All required tools are installed"

# Check AWS credentials
Write-Status "Checking AWS credentials..."
try {
    aws sts get-caller-identity | Out-Null
    Write-Status "AWS credentials are valid"
} catch {
    Write-Error-Message "AWS credentials are not configured properly"
    exit 1
}

# Initialize Terraform
Write-Status "Initializing Terraform..."
terraform init

# Validate Terraform configuration
Write-Status "Validating Terraform configuration..."
terraform validate

# Show Terraform plan
Write-Status "Generating Terraform plan..."
terraform plan -out=tfplan

# Ask for confirmation
Write-Host ""
Write-Warning-Message "Review the plan above. Do you want to apply these changes? (yes/no)"
$response = Read-Host

if ($response -ne "yes") {
    Write-Warning-Message "Deployment cancelled"
    Remove-Item tfplan -ErrorAction SilentlyContinue
    exit 0
}

# Apply Terraform configuration
Write-Status "Applying Terraform configuration..."
terraform apply tfplan
Remove-Item tfplan -ErrorAction SilentlyContinue

# Configure kubectl
Write-Status "Configuring kubectl..."
$clusterName = terraform output -raw eks_cluster_name
$awsRegion = "us-west-2"  # Adjust if needed

aws eks update-kubeconfig --region $awsRegion --name $clusterName

Write-Status "kubectl configured successfully"

# Wait for Jenkins to be ready
Write-Status "Waiting for Jenkins to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=jenkins -n jenkins --timeout=600s

# Wait for Argo CD to be ready
Write-Status "Waiting for Argo CD to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=600s

# Get Jenkins URL and password
Write-Host ""
Write-Status "Deployment completed successfully!"
Write-Host ""
Write-Host "======================================"
Write-Host "Jenkins Information:"
Write-Host "======================================"
Write-Host "URL: Get LoadBalancer URL with:"
Write-Host "  kubectl get svc jenkins -n jenkins"
Write-Host ""
Write-Host "Username: admin"
Write-Host "Password:"
terraform output -raw jenkins_admin_password
Write-Host ""
Write-Host ""

# Get Argo CD URL and password
Write-Host "======================================"
Write-Host "Argo CD Information:"
Write-Host "======================================"
Write-Host "URL: Get LoadBalancer URL with:"
Write-Host "  kubectl get svc argocd-server -n argocd"
Write-Host ""
Write-Host "Username: admin"
Write-Host "Password:"
$argoCdPassword = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}'
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($argoCdPassword))
Write-Host ""
Write-Host ""

# Get ECR repository URL
Write-Host "======================================"
Write-Host "ECR Repository:"
Write-Host "======================================"
terraform output ecr_repository_url
Write-Host ""

Write-Status "Next steps:"
Write-Host "1. Access Jenkins and configure credentials"
Write-Host "2. Access Argo CD and verify the application"
Write-Host "3. Create Jenkins pipeline for django-app"
Write-Host "4. Test the CI/CD flow"
Write-Host ""
Write-Warning-Message "Don't forget to run 'terraform destroy' when done to avoid charges!"
