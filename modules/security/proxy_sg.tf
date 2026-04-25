# RDS Proxy Security Group - connection pooling layer
# Sits between EKS and RDS, reduces connection overhead
resource "aws_security_group" "rds_proxy" {
  name        = "${var.project_name}-${var.environment}-rds-proxy-sg"
  description = "Security group for RDS Proxy"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-proxy-sg"
  }
}

# PostgreSQL from EKS nodes - application connections
resource "aws_security_group_rule" "proxy_eks_ingress" {
  security_group_id        = aws_security_group.rds_proxy.id
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_nodes.id
  description              = "PostgreSQL from EKS nodes"
}

# Outbound to RDS - forwards pooled connections
# Use cidr_blocks or reference the RDS security group via data source
# Simpler approach: allow egress to VPC CIDR on PostgreSQL port
resource "aws_security_group_rule" "proxy_rds_egress" {
  security_group_id = aws_security_group.rds_proxy.id
  type              = "egress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  description       = "Forward to RDS"
}