#!/bin/bash

# Lesson 7 - Build and Deploy Django to EKS
# This script automates the Docker build, ECR push, and Helm deployment

set -e  # Exit on error

echo "==================================="
echo "Lesson 7 - Django EKS Deployment"
echo "==================================="

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="us-west-2"
AWS_ACCOUNT_ID="978045176156"
ECR_REPOSITORY="django-app-lesson7"
ECR_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}"
IMAGE_TAG="latest"
HELM_RELEASE="django-app"
HELM_CHART="./charts/django-app"

# Step 1: Authenticate to ECR
echo -e "${YELLOW}Step 1: Authenticating to ECR...${NC}"
aws ecr get-login-password --region ${AWS_REGION} | \
    docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ ECR authentication successful${NC}"
else
    echo -e "${RED}✗ ECR authentication failed${NC}"
    exit 1
fi

# Step 2: Build Docker image
echo -e "${YELLOW}Step 2: Building Docker image...${NC}"
cd ..  # Go to project root
docker build -t ${ECR_REPOSITORY}:${IMAGE_TAG} .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Docker build successful${NC}"
else
    echo -e "${RED}✗ Docker build failed${NC}"
    exit 1
fi

# Step 3: Tag image for ECR
echo -e "${YELLOW}Step 3: Tagging image for ECR...${NC}"
docker tag ${ECR_REPOSITORY}:${IMAGE_TAG} ${ECR_URL}:${IMAGE_TAG}
echo -e "${GREEN}✓ Image tagged: ${ECR_URL}:${IMAGE_TAG}${NC}"

# Step 4: Push to ECR
echo -e "${YELLOW}Step 4: Pushing image to ECR...${NC}"
docker push ${ECR_URL}:${IMAGE_TAG}

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Image pushed to ECR successfully${NC}"
else
    echo -e "${RED}✗ Failed to push image to ECR${NC}"
    exit 1
fi

# Step 5: Update kubeconfig
echo -e "${YELLOW}Step 5: Updating kubeconfig...${NC}"
cd lesson-7
aws eks update-kubeconfig --region ${AWS_REGION} --name lesson-7-eks-cluster

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Kubeconfig updated${NC}"
else
    echo -e "${RED}✗ Failed to update kubeconfig${NC}"
    exit 1
fi

# Step 6: Verify cluster access
echo -e "${YELLOW}Step 6: Verifying cluster access...${NC}"
kubectl cluster-info
kubectl get nodes

# Step 7: Deploy/Upgrade with Helm
echo -e "${YELLOW}Step 7: Deploying application with Helm...${NC}"

# Check if release exists
if helm list | grep -q ${HELM_RELEASE}; then
    echo "Release ${HELM_RELEASE} exists. Upgrading..."
    helm upgrade ${HELM_RELEASE} ${HELM_CHART}
else
    echo "Installing new release ${HELM_RELEASE}..."
    helm install ${HELM_RELEASE} ${HELM_CHART}
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Helm deployment successful${NC}"
else
    echo -e "${RED}✗ Helm deployment failed${NC}"
    exit 1
fi

# Step 8: Show deployment status
echo -e "${YELLOW}Step 8: Checking deployment status...${NC}"
kubectl rollout status deployment/${HELM_RELEASE}

# Show all resources
echo -e "${YELLOW}Kubernetes Resources:${NC}"
kubectl get all

# Get LoadBalancer URL
echo -e "${YELLOW}Getting LoadBalancer URL...${NC}"
sleep 5  # Wait a bit for service to be ready
LB_URL=$(kubectl get service ${HELM_RELEASE} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

if [ -z "$LB_URL" ]; then
    echo -e "${YELLOW}⚠ LoadBalancer URL not ready yet. Check with:${NC}"
    echo "kubectl get service ${HELM_RELEASE}"
else
    echo -e "${GREEN}✓ Application URL: http://${LB_URL}${NC}"
fi

echo ""
echo -e "${GREEN}==================================="
echo "Deployment Complete!"
echo "===================================${NC}"
echo ""
echo "Next steps:"
echo "1. Wait for LoadBalancer to be ready: kubectl get service ${HELM_RELEASE} -w"
echo "2. Check pods: kubectl get pods"
echo "3. View logs: kubectl logs -f <pod-name>"
echo "4. Access application: http://<EXTERNAL-IP>"
echo "5. Monitor HPA: kubectl get hpa -w"
