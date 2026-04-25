# ---------------------------------------------------------------------------------------------------------------------
# EKS MANAGED ADDONS
# ---------------------------------------------------------------------------------------------------------------------
# AWS-managed addons are critical cluster components that AWS
# maintains and versions. They are installed via AWS API (not Helm)
# to ensure integration with EKS lifecycle management.
# 
# Addons installed:
# - vpc-cni: Pod networking (IP address management)
# - coredns: Cluster DNS (service discovery)
# - kube-proxy: Network proxy for services
# - ebs-csi-driver: Persistent volume management
# ---------------------------------------------------------------------------------------------------------------------

# VPC CNI addon - pod networking
# Responsible for assigning IP addresses to pods and enabling VPC networking
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"
  addon_version = "v1.18.0-eksbuild.1"                 # Pin version for stability

  resolve_conflicts_on_create = "OVERWRITE"           # Overwrite if exists
  resolve_conflicts_on_update = "OVERWRITE"           # Overwrite on update

  # Wait for system node group to exist (addon pods need nodes)
  depends_on = [aws_eks_node_group.system]

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc-cni"
  }
}

# CoreDNS addon - cluster DNS
# Provides DNS resolution for services and pods (kubernetes.default.svc.cluster.local)
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"
  addon_version = "v1.11.1-eksbuild.6"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.system]

  tags = {
    Name = "${var.project_name}-${var.environment}-coredns"
  }
}

# kube-proxy addon - network proxy
# Maintains network rules for service traffic routing
resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"
  addon_version = "v1.31.0-eksbuild.5"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.system]

  tags = {
    Name = "${var.project_name}-${var.environment}-kube-proxy"
  }
}

# EBS CSI driver addon - persistent volumes
# Allows pods to mount EBS volumes for persistent storage
resource "aws_eks_addon" "ebs_csi" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "aws-ebs-csi-driver"
  addon_version = "v1.35.0-eksbuild.1"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  # IRSA role for EBS CSI driver pod (separate from node role)
  service_account_role_arn = aws_iam_role.ebs_csi.arn

  depends_on = [aws_eks_node_group.system]

  tags = {
    Name = "${var.project_name}-${var.environment}-ebs-csi"
  }
}