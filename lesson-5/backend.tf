# Uncomment after S3 bucket and DynamoDB table are created
# Run these steps:
# 1. Comment out this backend block
# 2. Run: terraform init
# 3. Run: terraform apply (creates S3 and DynamoDB)
# 4. Uncomment this backend block
# 5. Run: terraform init -migrate-state (migrates local state to S3)

# terraform {
#   backend "s3" {
#     bucket         = "terraform-state-budyakov-lesson5"
#     key            = "lesson-5/terraform.tfstate"
#     region         = "us-west-2"
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
# }
