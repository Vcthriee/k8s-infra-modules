# EKS Node Security Group - worker nodes and pods
resource "aws_security_group" "eks_nodes" {
  name        = "${var.project_name}-${var.environment}-eks-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  # Allow ALL traffic from VPC CIDR (includes control plane)
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "All TCP from VPC"
  }

  # Allow ALL traffic from self (node-to-node)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Inter-node communication"
  }

  # Egress to all
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name                                        = "${var.project_name}-${var.environment}-eks-nodes-sg"
    "karpenter.sh/discovery"                    = "${var.project_name}-${var.environment}"
    "kubernetes.io/cluster/${var.project_name}-${var.environment}" = "owned"
  }
}

# Ingress from ALB
resource "aws_security_group_rule" "eks_nodes_alb_ingress" {
  security_group_id        = aws_security_group.eks_nodes.id
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  description              = "Traffic from ALB"
}