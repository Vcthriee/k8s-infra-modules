# ---------------------------------------------------------------------------------------------------------------------
# EKS MODULE OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------
# These values are consumed by the envs/dev configuration and
# other modules. They provide cluster identity, authentication
# details, and IRSA role ARNs for Helm installations.
# ---------------------------------------------------------------------------------------------------------------------

output "cluster_name" {
  description = "EKS cluster name for kubectl context and Helm --kube-context"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint URL for kubectl and Kubernetes provider"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_ca_certificate" {
  description = "Base64 encoded cluster CA certificate for TLS verification"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "Security group ID attached to EKS control plane ENIs"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "oidc_provider_url" {
  description = "OIDC provider URL (without https://) for IRSA trust policies"
  value       = aws_iam_openid_connect_provider.cluster.url
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN for IAM role trust policy configuration"
  value       = aws_iam_openid_connect_provider.cluster.arn
}

output "node_role_arn" {
  description = "IAM role ARN for EKS worker nodes (used by Karpenter NodePool)"
  value       = aws_iam_role.nodes.arn
}

output "node_role_name" {
  description = "IAM role name for EKS worker nodes (EC2 instance profile reference)"
  value       = aws_iam_role.nodes.name
}

output "karpenter_controller_role_arn" {
  description = "IRSA role ARN for Karpenter controller (Helm serviceAccount annotation)"
  value       = aws_iam_role.karpenter_controller.arn
}

output "karpenter_interruption_queue_name" {
  description = "SQS queue name for Karpenter Spot interruption handling (Helm value)"
  value       = aws_sqs_queue.karpenter_interruption.name
}

output "karpenter_interruption_queue_arn" {
  description = "SQS queue ARN for IAM policies"
  value       = aws_sqs_queue.karpenter_interruption.arn
}

output "ebs_csi_role_arn" {
  description = "IRSA role ARN for EBS CSI driver addon"
  value       = aws_iam_role.ebs_csi.arn
}

output "alb_controller_role_arn" {
  description = "IRSA role ARN for AWS Load Balancer Controller"
  value       = aws_iam_role.alb_controller.arn
}

output "external_secrets_role_arn" {
  description = "IRSA role ARN for External Secrets Operator"
  value       = aws_iam_role.external_secrets.arn
} 