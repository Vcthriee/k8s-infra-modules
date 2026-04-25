# ElastiCache Security Group - Redis cluster
# Accessible from EKS nodes only
resource "aws_security_group" "elasticache" {
  name        = "${var.project_name}-${var.environment}-elasticache-sg"
  description = "Security group for ElastiCache Redis"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-elasticache-sg"
  }
}

# Redis from EKS nodes - application cache access
resource "aws_security_group_rule" "elasticache_eks_ingress" {
  security_group_id        = aws_security_group.elasticache.id
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_nodes.id
  description              = "Redis from EKS nodes"
}

# No egress - Redis is passive