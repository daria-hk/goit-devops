output "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = module.s3_backend.s3_bucket_name
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = module.s3_backend.dynamodb_table_name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "ecr_repository_url" {
  description = "ECR Repository URL"
  value       = module.ecr.ecr_url
}

output "eks_cluster_name" {
  description = "EKS Cluster Name"
  value       = module.eks.eks_cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS Cluster Endpoint"
  value       = module.eks.eks_cluster_endpoint
}

output "jenkins_url" {
  description = "Jenkins URL"
  value       = module.jenkins.jenkins_url
}

output "jenkins_admin_password" {
  description = "Jenkins Admin Password"
  value       = module.jenkins.jenkins_admin_password
  sensitive   = true
}