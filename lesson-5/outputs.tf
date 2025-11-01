output "s3_backend_info" {
  description = "S3 backend configuration details"
  value = {
    bucket_id   = module.s3_backend.s3_bucket_id
    bucket_arn  = module.s3_backend.s3_bucket_arn
    region      = module.s3_backend.s3_bucket_region
    table_name  = module.s3_backend.dynamodb_table_name
    table_arn   = module.s3_backend.dynamodb_table_arn
  }
}

output "vpc_info" {
  description = "VPC configuration details"
  value = {
    vpc_id                 = module.vpc.vpc_id
    vpc_cidr               = module.vpc.vpc_cidr_block
    public_subnet_ids      = module.vpc.public_subnet_ids
    private_subnet_ids     = module.vpc.private_subnet_ids
    internet_gateway_id    = module.vpc.internet_gateway_id
    nat_gateway_ids        = module.vpc.nat_gateway_ids
    public_route_table_id  = module.vpc.public_route_table_id
    private_route_table_ids = module.vpc.private_route_table_ids
  }
}

output "ecr_info" {
  description = "ECR repository details"
  value = {
    repository_url  = module.ecr.repository_url
    repository_arn  = module.ecr.repository_arn
    repository_name = module.ecr.repository_name
    registry_id     = module.ecr.registry_id
  }
}

output "quick_reference" {
  description = "Quick reference commands"
  value = {
    docker_login = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${module.ecr.registry_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
    docker_push  = "docker tag your-image:tag ${module.ecr.repository_url}:tag && docker push ${module.ecr.repository_url}:tag"
  }
}
