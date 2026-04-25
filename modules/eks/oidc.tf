# ---------------------------------------------------------------------------------------------------------------------
# EKS OIDC PROVIDER FOR IRSA
# ---------------------------------------------------------------------------------------------------------------------
# Creates OpenID Connect (OIDC) identity provider that enables
# IAM Roles for Service Accounts (IRSA). This allows Kubernetes
# service accounts to assume AWS IAM roles via OIDC tokens.
# 
# Without this, all pods inherit the EC2 instance role (insecure).
# With IRSA, each pod gets specific AWS permissions via IAM role.
# ---------------------------------------------------------------------------------------------------------------------

# Fetch the TLS certificate of the EKS OIDC issuer
# Required to establish trust between AWS and Kubernetes
data "tls_certificate" "cluster" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer  # OIDC issuer URL from cluster
}

# Create OIDC provider in AWS IAM
# This allows AWS to validate Kubernetes-issued JWT tokens
resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]                # Audience for STS (Security Token Service)
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]  # Certificate fingerprint
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer  # OIDC issuer URL

  tags = {
    Name = "${var.project_name}-${var.environment}-oidc"
  }
}