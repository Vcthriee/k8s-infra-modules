# ---------------------------------------------------------------------------------------------------------------------
# EKS CONTROL PLANE
# ---------------------------------------------------------------------------------------------------------------------
# This file creates the Kubernetes API server managed by AWS. It includes:
# - KMS encryption for secrets at rest (etcd encryption)
# - Private API endpoint for security (traffic never leaves VPC)
# - CloudWatch logging for audit compliance
# - Security group for control plane network access
# ---------------------------------------------------------------------------------------------------------------------

# KMS key for encrypting Kubernetes secrets at rest
# AWS manages etcd, but we control the encryption key
resource "aws_kms_key" "eks" {
  description             = "KMS key for EKS secret encryption (envelope encryption for etcd)"
  deletion_window_in_days = 7                          # 7-day grace period before key deletion
  enable_key_rotation     = true                       # Automatic annual key rotation

  tags = {
    Name = "${var.project_name}-${var.environment}-eks-key"
  }
}

# Alias for easier key identification in AWS console
resource "aws_kms_alias" "eks" {
  name          = "alias/${var.project_name}-${var.environment}-eks"
  target_key_id = aws_kms_key.eks.key_id
}

# CloudWatch log group for EKS control plane logs
# Captures API audit logs, authentication decisions, and scheduler events
resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.project_name}-${var.environment}/cluster"
  retention_in_days = 7                              # 7 days for dev; 30-90 days for production compliance

  tags = {
    Name = "${var.project_name}-${var.environment}-eks-logs"
  }
}

# EKS cluster resource - the Kubernetes API server
resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-${var.environment}"  # Cluster name (e.g., cloudnexus-dev)
  version  = var.cluster_version                       # Kubernetes version (e.g., 1.31)
  role_arn = aws_iam_role.cluster.arn                  # IAM role AWS assumes to manage this cluster

  # VPC configuration for cluster networking
  vpc_config {
    subnet_ids              = var.private_subnet_ids   # Subnets for ENIs that connect to nodes
    security_group_ids      = [aws_security_group.cluster.id]  # Additional security group for cluster
    endpoint_private_access = var.enable_private_endpoint      # Private API endpoint (security best practice)
    endpoint_public_access  = var.enable_public_endpoint       # Public endpoint for kubectl access
    public_access_cidrs     = var.public_endpoint_cidrs          # IP whitelist for public endpoint
  }

  # Encryption configuration for secrets at rest
  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn                    # Customer-managed key for envelope encryption
    }
    resources = ["secrets"]                            # Encrypt Secrets in etcd (not ConfigMaps)
  }

  # Control plane logging to CloudWatch
  enabled_cluster_log_types = [
    "api",                                             # API server requests (who did what)
    "audit",                                           # Authentication/authorization decisions
    "authenticator",                                   # AWS IAM authenticator logs
    "controllerManager",                               # Kubernetes controller decisions
    "scheduler"                                        # Pod scheduling decisions
  ]

  # Ensure IAM role and log group exist before creating cluster
  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_iam_role_policy_attachment.cluster_vpc_policy,
    aws_cloudwatch_log_group.eks,
  ]

  tags = {
    Name = "${var.project_name}-${var.environment}"
  }
}

# Security group for EKS control plane ENIs
# AWS automatically creates a cross-account security group for node-to-control-plane traffic
# This SG is for additional control plane network access if needed
resource "aws_security_group" "cluster" {
  name        = "${var.project_name}-${var.environment}-cluster-sg"
  description = "EKS cluster security group for control plane ENIs"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-cluster-sg"
  }
}

# Egress rule for cluster security group
# Allows control plane to reach nodes (required for kubelet API)
resource "aws_security_group_rule" "cluster_egress" {
  security_group_id = aws_security_group.cluster.id
  type              = "egress"                        # Outbound traffic
  from_port         = 0                              # All ports
  to_port           = 0                              # All ports
  protocol          = "-1"                           # All protocols
  cidr_blocks       = ["0.0.0.0/0"]                  # To VPC (restricted by VPC routing)
  description       = "Allow all outbound traffic from control plane"
}