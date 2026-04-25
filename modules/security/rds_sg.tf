# RDS Security Group - PostgreSQL database
# Only accessible from RDS Proxy and EKS nodes (via proxy)
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-sg"
  }
}

# PostgreSQL from RDS Proxy only - no direct EKS access
resource "aws_security_group_rule" "rds_proxy_ingress" {
  security_group_id        = aws_security_group.rds.id
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds_proxy.id
  description              = "PostgreSQL from RDS Proxy only"
}

# No egress rules - RDS does not initiate connections