variable "project_name" {
  description = "Name of the project, used as prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for security group placement"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block for internal traffic rules"
  type        = string
}

variable "eks_cluster_security_group_id" {
  description = "Security group ID of the EKS cluster control plane"
  type        = string
  default     = null
}