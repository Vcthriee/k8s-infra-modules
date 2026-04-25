output "rds_endpoint" {
  description = "Primary RDS endpoint for manual connections"
  value       = aws_db_instance.primary.address
}

output "rds_proxy_endpoint" {
  description = "RDS Proxy endpoint for application connections"
  value       = aws_db_proxy.main.endpoint
}

output "redis_endpoint" {
  description = "Redis primary endpoint (write)"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "redis_reader_endpoint" {
  description = "Redis reader endpoint (read replicas)"
  value       = aws_elasticache_replication_group.main.reader_endpoint_address
}

output "db_secret_arn" {
  description = "Secrets Manager ARN for database credentials"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "db_secret_name" {
  description = "Secrets Manager secret name for External Secrets"
  value       = aws_secretsmanager_secret.db_password.name
}

output "jwt_secret_arn" {
  description = "Secrets Manager ARN for JWT secret"
  value       = aws_secretsmanager_secret.jwt_secret.arn
}

output "rds_instance_id" {
  description = "RDS instance ID for CloudWatch alarms"
  value       = aws_db_instance.primary.identifier
}

output "elasticache_id" {
  description = "ElastiCache replication group ID for CloudWatch"
  value       = aws_elasticache_replication_group.main.id
}