output "alb_security_group_id" {
  description = "ALB security group ID for load balancer"
  value       = aws_security_group.alb.id
}

output "eks_node_security_group_id" {
  description = "EKS node security group ID for worker nodes"
  value       = aws_security_group.eks_nodes.id
}

output "rds_security_group_id" {
  description = "RDS security group ID for database"
  value       = aws_security_group.rds.id
}

output "rds_proxy_security_group_id" {
  description = "RDS Proxy security group ID for connection pooler"
  value       = aws_security_group.rds_proxy.id
}

output "elasticache_security_group_id" {
  description = "ElastiCache security group ID for Redis"
  value       = aws_security_group.elasticache.id
}

output "eks_nodes_security_group_id" {
  description = "Security group ID for EKS worker nodes"
  value       = aws_security_group.eks_nodes.id
}