# Lesson 7 - Build and Deploy Django to EKS (PowerShell)
# This script automates the Docker build, ECR push, and Helm deployment

$ErrorActionPreference = "Stop"

Write-Host "===================================" -ForegroundColor Cyan
Write-Host "Lesson 7 - Django EKS Deployment" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

# Configuration
$AWS_REGION = "us-west-2"
$AWS_ACCOUNT_ID = "978045176156"
$ECR_REPOSITORY = "django-app-lesson7"
$ECR_URL = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}"
$IMAGE_TAG = "latest"
$HELM_RELEASE = "django-app"
$HELM_CHART = "./charts/django-app"

# Step 1: Authenticate to ECR
Write-Host "`nStep 1: Authenticating to ECR..." -ForegroundColor Yellow
try {
    $password = aws ecr get-login-password --region $AWS_REGION
    $password | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    Write-Host "✓ ECR authentication successful" -ForegroundColor Green
} catch {
    Write-Host "✗ ECR authentication failed" -ForegroundColor Red
    exit 1
}

# Step 2: Build Docker image
Write-Host "`nStep 2: Building Docker image..." -ForegroundColor Yellow
try {
    Set-Location ..  # Go to project root
    docker build -t "${ECR_REPOSITORY}:${IMAGE_TAG}" .
    Write-Host "✓ Docker build successful" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker build failed" -ForegroundColor Red
    exit 1
}

# Step 3: Tag image for ECR
Write-Host "`nStep 3: Tagging image for ECR..." -ForegroundColor Yellow
docker tag "${ECR_REPOSITORY}:${IMAGE_TAG}" "${ECR_URL}:${IMAGE_TAG}"
Write-Host "✓ Image tagged: ${ECR_URL}:${IMAGE_TAG}" -ForegroundColor Green

# Step 4: Push to ECR
Write-Host "`nStep 4: Pushing image to ECR..." -ForegroundColor Yellow
try {
    docker push "${ECR_URL}:${IMAGE_TAG}"
    Write-Host "✓ Image pushed to ECR successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to push image to ECR" -ForegroundColor Red
    exit 1
}

# Step 5: Update kubeconfig
Write-Host "`nStep 5: Updating kubeconfig..." -ForegroundColor Yellow
try {
    Set-Location lesson-7
    aws eks update-kubeconfig --region $AWS_REGION --name lesson-7-eks-cluster
    Write-Host "✓ Kubeconfig updated" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to update kubeconfig" -ForegroundColor Red
    exit 1
}

# Step 6: Verify cluster access
Write-Host "`nStep 6: Verifying cluster access..." -ForegroundColor Yellow
kubectl cluster-info
kubectl get nodes

# Step 7: Deploy/Upgrade with Helm
Write-Host "`nStep 7: Deploying application with Helm..." -ForegroundColor Yellow

# Check if release exists
$releases = helm list -q
if ($releases -contains $HELM_RELEASE) {
    Write-Host "Release ${HELM_RELEASE} exists. Upgrading..." -ForegroundColor Yellow
    helm upgrade $HELM_RELEASE $HELM_CHART
} else {
    Write-Host "Installing new release ${HELM_RELEASE}..." -ForegroundColor Yellow
    helm install $HELM_RELEASE $HELM_CHART
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Helm deployment successful" -ForegroundColor Green
} else {
    Write-Host "✗ Helm deployment failed" -ForegroundColor Red
    exit 1
}

# Step 8: Show deployment status
Write-Host "`nStep 8: Checking deployment status..." -ForegroundColor Yellow
kubectl rollout status deployment/$HELM_RELEASE

# Show all resources
Write-Host "`nKubernetes Resources:" -ForegroundColor Yellow
kubectl get all

# Get LoadBalancer URL
Write-Host "`nGetting LoadBalancer URL..." -ForegroundColor Yellow
Start-Sleep -Seconds 5  # Wait a bit for service to be ready
$LB_URL = kubectl get service $HELM_RELEASE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null

if ([string]::IsNullOrEmpty($LB_URL)) {
    Write-Host "⚠ LoadBalancer URL not ready yet. Check with:" -ForegroundColor Yellow
    Write-Host "kubectl get service ${HELM_RELEASE}"
} else {
    Write-Host "✓ Application URL: http://${LB_URL}" -ForegroundColor Green
}

Write-Host "`n===================================" -ForegroundColor Green
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green

Write-Host "`nNext steps:"
Write-Host "1. Wait for LoadBalancer to be ready: kubectl get service ${HELM_RELEASE} -w"
Write-Host "2. Check pods: kubectl get pods"
Write-Host "3. View logs: kubectl logs -f <pod-name>"
Write-Host "4. Access application: http://<EXTERNAL-IP>"
Write-Host "5. Monitor HPA: kubectl get hpa -w"
