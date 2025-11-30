output "jenkins_url" {
  description = "Jenkins URL (LoadBalancer)"
  value       = length(data.kubernetes_service.jenkins.status[0].load_balancer[0].ingress) > 0 ? "http://${data.kubernetes_service.jenkins.status[0].load_balancer[0].ingress[0].hostname}" : "Pending..."
}

output "jenkins_admin_user" {
  description = "Jenkins Admin Username"
  value       = "admin"
}

output "jenkins_admin_password" {
  description = "Jenkins Admin Password"
  value       = random_password.jenkins_admin_password.result
  sensitive   = true
}

output "jenkins_namespace" {
  description = "Kubernetes Namespace für Jenkins"
  value       = kubernetes_namespace.jenkins.metadata[0].name
}

output "jenkins_service_name" {
  description = "Jenkins Service Name"
  value       = data.kubernetes_service.jenkins.metadata[0].name
}

