# Standard RDS outputs
output "rds_endpoint" {
  description = "Endpoint RDS"
  value       = var.use_aurora ? null : try(aws_db_instance.standard[0].endpoint, null)
}

output "rds_address" {
  description = "DNS address RDS "
  value       = var.use_aurora ? null : try(aws_db_instance.standard[0].address, null)
}

output "rds_port" {
  description = "port RDS "
  value       = var.use_aurora ? null : try(aws_db_instance.standard[0].port, null)
}

output "rds_id" {
  description = "ID RDS "
  value       = var.use_aurora ? null : try(aws_db_instance.standard[0].id, null)
}

# Aurora outputs
output "aurora_cluster_endpoint" {
  description = "Endpoint"
  value       = var.use_aurora ? try(aws_rds_cluster.aurora[0].endpoint, null) : null
}

output "aurora_reader_endpoint" {
  description = "Reader endpoint"
  value       = var.use_aurora ? try(aws_rds_cluster.aurora[0].reader_endpoint, null) : null
}

output "aurora_cluster_id" {
  description = "aurora_cluster_idа"
  value       = var.use_aurora ? try(aws_rds_cluster.aurora[0].id, null) : null
}

output "aurora_cluster_members" {
  description = "aurora_cluster_members"
  value       = var.use_aurora ? try(aws_rds_cluster.aurora[0].cluster_members, []) : []
}

# Common outputs
output "db_name" {
  description = "db name"
  value       = var.db_name
}

output "db_username" {
  description = "Username"
  value       = var.username
  sensitive   = true
}

output "security_group_id" {
  description = "ID Security Group"
  value       = aws_security_group.rds.id
}

output "subnet_group_name" {
  description = "name DB Subnet Group"
  value       = aws_db_subnet_group.default.name
}

