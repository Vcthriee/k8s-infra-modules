output "vpc_id" {
  description = "VPC ID for resource placement"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block for security group rules"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs for ALB placement"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs for EKS nodes and pods"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "Database subnet IDs for RDS and ElastiCache"
  value       = aws_subnet.database[*].id
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs for private subnet internet access"
  value       = aws_nat_gateway.main[*].id
}

output "s3_endpoint_id" {
  description = "S3 VPC endpoint ID"
  value       = aws_vpc_endpoint.s3.id
}