# EKS MANAGED NODE GROUP
resource "aws_eks_node_group" "system" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "system"
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = var.private_subnet_ids

  instance_types = var.node_instance_types

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable_percentage = 25
  }

  capacity_type = "ON_DEMAND"

  labels = {
    workload-type = "system"
  }

  depends_on = [
    aws_iam_role_policy_attachment.nodes_worker,
    aws_iam_role_policy_attachment.nodes_cni,
    aws_iam_role_policy_attachment.nodes_ecr,
  ]

  tags = {
    Name                                        = "${var.project_name}-${var.environment}-system-ng"
    "karpenter.sh/discovery"                    = "${var.project_name}-${var.environment}"
    "kubernetes.io/cluster/${var.project_name}-${var.environment}" = "owned"
  }
}