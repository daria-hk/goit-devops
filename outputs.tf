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

output "jenkins_release" {
  value = module.jenkins.jenkins_release_name
}

output "jenkins_namespace" {
  value = module.jenkins.jenkins_namespace
}

