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

  default_tags {
    tags = {
      Project     = "lesson-5"
      ManagedBy   = "Terraform"
      Environment = "infrastructure"
    }
  }
}

module "s3_backend" {
  source = "./modules/s3-backend"

  bucket_name = var.s3_bucket_name
  table_name  = var.dynamodb_table_name
  region      = var.aws_region

  tags = {
    Module = "s3-backend"
  }
}

module "vpc" {
  source = "./modules/vpc"

  vpc_cidr_block     = var.vpc_cidr_block
  vpc_name           = var.vpc_name
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  availability_zones = var.availability_zones

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  tags = {
    Module = "vpc"
  }
}

module "ecr" {
  source = "./modules/ecr"

  ecr_name     = var.ecr_repository_name
  scan_on_push = var.ecr_scan_on_push

  image_tag_mutability  = var.ecr_image_tag_mutability
  lifecycle_policy_days = var.ecr_lifecycle_policy_days
  max_image_count       = var.ecr_max_image_count

  tags = {
    Module = "ecr"
  }
}
