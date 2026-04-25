# ---------------------------------------------------------------------------------------------------------------------
# DEV ENVIRONMENT OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------
# These outputs provide useful information after deployment.
# ---------------------------------------------------------------------------------------------------------------------

# VPC outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.networking.private_subnet_ids
}

# EKS outputs
output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API endpoint"
  value       = module.eks.cluster_endpoint
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN"
  value       = module.eks.oidc_provider_arn
}

# Database outputs


# Application endpoints
output "grafana_url" {
  description = "Grafana dashboard URL"
  value       = "https://grafana.${var.domain}"
}

output "argocd_url" {
  description = "ArgoCD UI URL"
  value       = "https://argocd.${var.domain}"
}

# Kubeconfig command
output "kubeconfig_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}