#!/bin/bash

# Deploy script for Lesson 8-9 CI/CD Infrastructure
# This script automates the deployment process

set -e

echo "🚀 Starting Lesson 8-9 Infrastructure Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    print_error "terraform.tfvars not found!"
    print_warning "Please copy terraform.tfvars.example to terraform.tfvars and configure it"
    exit 1
fi

# Check required tools
print_status "Checking required tools..."

command -v terraform >/dev/null 2>&1 || { print_error "Terraform is not installed. Aborting."; exit 1; }
command -v aws >/dev/null 2>&1 || { print_error "AWS CLI is not installed. Aborting."; exit 1; }
command -v kubectl >/dev/null 2>&1 || { print_error "kubectl is not installed. Aborting."; exit 1; }

print_status "All required tools are installed"

# Check AWS credentials
print_status "Checking AWS credentials..."
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    print_error "AWS credentials are not configured properly"
    exit 1
fi
print_status "AWS credentials are valid"

# Initialize Terraform
print_status "Initializing Terraform..."
terraform init

# Validate Terraform configuration
print_status "Validating Terraform configuration..."
terraform validate

# Show Terraform plan
print_status "Generating Terraform plan..."
terraform plan -out=tfplan

# Ask for confirmation
echo ""
print_warning "Review the plan above. Do you want to apply these changes? (yes/no)"
read -r response

if [[ "$response" != "yes" ]]; then
    print_warning "Deployment cancelled"
    rm -f tfplan
    exit 0
fi

# Apply Terraform configuration
print_status "Applying Terraform configuration..."
terraform apply tfplan
rm -f tfplan

# Configure kubectl
print_status "Configuring kubectl..."
CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
AWS_REGION=$(terraform output -json | jq -r '.configure_kubectl_command.value' | grep -oP '(?<=--region )\S+')

aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"

print_status "kubectl configured successfully"

# Wait for Jenkins to be ready
print_status "Waiting for Jenkins to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=jenkins -n jenkins --timeout=600s

# Wait for Argo CD to be ready
print_status "Waiting for Argo CD to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=600s

# Get Jenkins URL and password
echo ""
print_status "Deployment completed successfully!"
echo ""
echo "======================================"
echo "Jenkins Information:"
echo "======================================"
echo "URL: Get LoadBalancer URL with:"
echo "  kubectl get svc jenkins -n jenkins"
echo ""
echo "Username: admin"
echo "Password:"
terraform output -raw jenkins_admin_password
echo ""
echo ""

# Get Argo CD URL and password
echo "======================================"
echo "Argo CD Information:"
echo "======================================"
echo "URL: Get LoadBalancer URL with:"
echo "  kubectl get svc argocd-server -n argocd"
echo ""
echo "Username: admin"
echo "Password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
echo ""
echo ""

# Get ECR repository URL
echo "======================================"
echo "ECR Repository:"
echo "======================================"
terraform output ecr_repository_url
echo ""

print_status "Next steps:"
echo "1. Access Jenkins and configure credentials"
echo "2. Access Argo CD and verify the application"
echo "3. Create Jenkins pipeline for django-app"
echo "4. Test the CI/CD flow"
echo ""
print_warning "Don't forget to run 'terraform destroy' when done to avoid charges!"
