# Backend configuration for Terraform state
# Uncomment this block after creating the S3 bucket and DynamoDB table

# Steps to enable remote state:
# 1. terraform apply (creates S3/DynamoDB)
# 2. Uncomment the block below
# 3. terraform init -migrate-state (migrates state to S3)

# terraform {
#   backend "s3" {
#     bucket         = "terraform-state-budyakov-final-project"
#     key            = "final-project/terraform.tfstate"
#     region         = "us-west-2"
#     dynamodb_table = "terraform-locks-final-project"
#     encrypt        = true
#   }
# }
