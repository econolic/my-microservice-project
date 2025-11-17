# Uncomment this block after creating the S3 bucket and DynamoDB table with Terraform
# Run:
# 1. terraform apply (creates S3 bucket and DynamoDB table)
# 2. Uncomment this block
# 3. terraform init -migrate-state (migrates state to S3)

# terraform {
#   backend "s3" {
#     bucket         = "terraform-state-budyakov-lesson8-9"
#     key            = "lesson-8-9/terraform.tfstate"
#     region         = "us-west-2"
#     dynamodb_table = "terraform-locks-lesson8-9"
#     encrypt        = true
#   }
# }
