# ---------------------------------------------------------------------------------------------------------------------
# EKS MODULE - INPUT VARIABLES
# ---------------------------------------------------------------------------------------------------------------------
# This module creates a production-grade EKS cluster with Karpenter autoscaling.
# All configurable values are exposed as variables to allow environment-specific
# customization without modifying the module code (separation of concerns).
# ---------------------------------------------------------------------------------------------------------------------

variable "project_name" {
  description = "Project name used as prefix for all resource naming (e.g., cloudnexus)"
  type        = string
}

variable "environment" {
  description = "Environment identifier (dev, staging, prod) for resource segregation"
  type        = string
}

variable "aws_region" {
  description = "AWS region where EKS cluster will be deployed (e.g., af-south-1)"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID required for constructing IAM ARNs in policies"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for EKS cluster (e.g., 1.31). AWS supports N-3 versions."
  type        = string
  default     = "1.31"
}

variable "vpc_id" {
  description = "VPC ID where EKS cluster and nodes will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EKS node placement. Must span multiple AZs for HA."
  type        = list(string)
}

variable "eks_node_security_group_id" {
  description = "Security group ID to attach to all EKS worker nodes for network access control"
  type        = string
  default     = null
}

variable "eks_cluster_security_group_id" {
  description = "Security group ID of the EKS cluster control plane"
  type        = string
  default     = null
}

variable "enable_private_endpoint" {
  description = "Enable private API server endpoint (true = API traffic stays in VPC)"
  type        = bool
  default     = true
}

variable "enable_public_endpoint" {
  description = "Enable public API server endpoint (true = kubectl works from internet)"
  type        = bool
  default     = true
}

variable "public_endpoint_cidrs" {
  description = "Allowed CIDR blocks for public API endpoint access (restrict to office/VPN IPs in prod)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  description = "EC2 instance types for managed node group (system nodes only, Karpenter handles apps)"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of nodes in system node group (runs Karpenter, CoreDNS, addons)"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum nodes in system node group (maintain HA for critical components)"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum nodes in system node group (prevents runaway scaling)"
  type        = number
  default     = 4
}