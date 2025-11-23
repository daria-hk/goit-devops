output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.eks.name
}

output "eks_cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  value       = aws_eks_cluster.eks.endpoint
}

output "eks_node_role_arn" {
  description = "IAM role ARN for EKS worker nodes"
  value       = aws_iam_role.eks_node_role.arn
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN for EKS"
  value       = aws_iam_openid_connect_provider.oidc.arn
}

output "oidc_provider_url" {
  description = "OIDC provider URL for EKS"
  value       = aws_iam_openid_connect_provider.oidc.url
}
