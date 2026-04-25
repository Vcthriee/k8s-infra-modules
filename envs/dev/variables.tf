# ---------------------------------------------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# ---------------------------------------------------------------------------------------------------------------------
# Configuration specific to the dev environment.
# These values are passed to modules and used for resource naming.
# ---------------------------------------------------------------------------------------------------------------------

# Project identifier
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "cloudnexus"
}

# Environment name
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# AWS region
variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "af-south-1"
}

# AWS account ID (required for IAM ARNs)
variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
  default     = "904690835870"
}

# VPC CIDR block
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

# Availability zones
variable "availability_zones" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["af-south-1a", "af-south-1b", "af-south-1c"]
}

# EKS Kubernetes version
variable "eks_cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.31"
}

# Domain for applications
variable "domain" {
  description = "Base domain for applications"
  type        = string
  default     = "cloudnexus.local"
}

# Git repository for ArgoCD
variable "argocd_repo_url" {
  description = "Git repository URL for ArgoCD"
  type        = string
  default     = "https://github.com/Vcthriee/ecommerce-k8s.git"
}

# S3 bucket for Velero backups
variable "velero_bucket_name" {
  description = "S3 bucket for Velero backups"
  type        = string
  default     = "cloudnexus-velero-backups"
}

# Application image tag
variable "app_image_tag" {
  description = "Ecommerce app image tag"
  type        = string
  default     = "latest"
}