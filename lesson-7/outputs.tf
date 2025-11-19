output "s3_backend_info" {
  description = "S3 Backend configuration details"
  value = {
    bucket_id     = module.s3_backend.s3_bucket_id
    bucket_arn    = module.s3_backend.s3_bucket_arn
    bucket_region = module.s3_backend.s3_bucket_region
    table_name    = module.s3_backend.dynamodb_table_name
    table_arn     = module.s3_backend.dynamodb_table_arn
  }
}

output "vpc_info" {
  description = "VPC configuration details"
  value = {
    vpc_id              = module.vpc.vpc_id
    vpc_cidr_block      = module.vpc.vpc_cidr_block
    public_subnet_ids   = module.vpc.public_subnet_ids
    private_subnet_ids  = module.vpc.private_subnet_ids
    nat_gateway_ids     = module.vpc.nat_gateway_ids
    internet_gateway_id = module.vpc.internet_gateway_id
  }
}

output "ecr_info" {
  description = "ECR repository details"
  value = {
    repository_name = module.ecr.repository_name
    repository_url  = module.ecr.repository_url
    repository_arn  = module.ecr.repository_arn
  }
}

output "eks_info" {
  description = "EKS cluster details"
  value = {
    cluster_id                  = module.eks.cluster_id
    cluster_arn                 = module.eks.cluster_arn
    cluster_endpoint            = module.eks.cluster_endpoint
    cluster_version             = module.eks.cluster_version
    cluster_security_group_id   = module.eks.cluster_security_group_id
    node_group_id               = module.eks.node_group_id
    node_group_status           = module.eks.node_group_status
    cluster_iam_role_arn        = module.eks.cluster_iam_role_arn
    node_iam_role_arn           = module.eks.node_iam_role_arn
  }
}

output "kubeconfig_command" {
  description = "Command to configure kubectl for the EKS cluster"
  value       = module.eks.kubeconfig_command
}

output "docker_login_command" {
  description = "Command to authenticate Docker with ECR"
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${module.ecr.repository_url}"
}

output "quick_reference" {
  description = "Quick reference commands for working with the infrastructure"
  value = {
    configure_kubectl = module.eks.kubeconfig_command
    docker_login      = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${module.ecr.repository_url}"
    docker_build      = "docker build -t ${module.ecr.repository_url}:latest ."
    docker_push       = "docker push ${module.ecr.repository_url}:latest"
    helm_install      = "helm install django-app ./charts/django-app"
    helm_upgrade      = "helm upgrade django-app ./charts/django-app"
  }
}
