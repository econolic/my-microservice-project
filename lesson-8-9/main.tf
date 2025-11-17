terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Configure Kubernetes provider using EKS cluster
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name,
      "--region",
      var.aws_region
    ]
  }
}

# Configure Helm provider using EKS cluster
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
    
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.cluster_name,
        "--region",
        var.aws_region
      ]
    }
  }
}

# S3 Backend for Terraform State
module "s3_backend" {
  source = "./modules/s3-backend"

  bucket_name = var.backend_bucket_name
  table_name  = var.backend_table_name
  region      = var.aws_region
  tags        = var.tags
}

# VPC Network Infrastructure
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr_block     = var.vpc_cidr
  vpc_name           = var.vpc_name
  availability_zones = var.availability_zones
  public_subnets     = var.public_subnet_cidrs
  private_subnets    = var.private_subnet_cidrs
  single_nat_gateway = true
  tags               = var.tags
}

# ECR Repository for Django application
module "ecr" {
  source = "./modules/ecr"

  ecr_name = var.ecr_repository_name
  tags     = var.tags
}

# EKS Cluster
module "eks" {
  source = "./modules/eks"

  cluster_name        = var.cluster_name
  cluster_version     = var.cluster_version
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = concat(module.vpc.public_subnet_ids, module.vpc.private_subnet_ids)
  node_group_name     = var.node_group_name
  node_instance_types = var.node_instance_types
  node_min_size       = var.node_min_size
  node_desired_size   = var.node_desired_size
  node_max_size       = var.node_max_size
  tags                = var.tags
}

# Jenkins Installation
module "jenkins" {
  source = "./modules/jenkins"

  namespace              = var.jenkins_namespace
  chart_version          = var.jenkins_chart_version
  jenkins_admin_password = var.jenkins_admin_password
  service_type           = var.jenkins_service_type
  storage_size           = var.jenkins_storage_size
  ecr_registry_url       = module.ecr.repository_url
  aws_region             = var.aws_region
  github_token           = var.github_token
  github_username        = var.github_username
  tags                   = var.tags

  providers = {
    kubernetes = kubernetes
    helm       = helm
  }

  depends_on = [module.eks]
}

# Argo CD Installation
module "argocd" {
  source = "./modules/argo_cd"

  namespace       = var.argocd_namespace
  chart_version   = var.argocd_chart_version
  service_type    = var.argocd_service_type
  github_repo_url = var.github_repo_url
  github_token    = var.github_token
  helm_chart_path = var.helm_chart_path
  auto_sync       = var.argocd_auto_sync
  self_heal       = var.argocd_self_heal
  tags            = var.tags

  providers = {
    kubernetes = kubernetes
    helm       = helm
  }

  depends_on = [module.eks, module.jenkins]
}
