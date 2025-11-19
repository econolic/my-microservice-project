terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
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
