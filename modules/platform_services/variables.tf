
# ---------------------------------------------------------------------------------------------------------------------
# PLATFORM SERVICES MODULE - INPUT VARIABLES
# ---------------------------------------------------------------------------------------------------------------------
# This module provides essential platform capabilities:
# - ArgoCD: GitOps continuous delivery
# - Cert Manager: Automated TLS certificate management
# - External Secrets: AWS Secrets Manager integration
# - Velero: Backup and disaster recovery
# ---------------------------------------------------------------------------------------------------------------------

# Project name for resource naming
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

# Environment identifier (dev, staging, prod)
variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

# AWS region for S3 backup bucket and Secrets Manager
variable "aws_region" {
  description = "AWS region for S3 and Secrets Manager"
  type        = string
}

# EKS cluster name for resource tagging
variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

# IRSA role ARN for External Secrets Operator
# Passed from EKS module output
variable "external_secrets_role_arn" {
  description = "IRSA role ARN for External Secrets Operator"
  type        = string
}

# Domain for Cert Manager (e.g., cloudnexus.io)
# Used for Let's Encrypt certificate issuance
variable "domain" {
  description = "Base domain for Cert Manager certificates"
  type        = string
  default     = "example.com"
}

# S3 bucket name for Velero backups
variable "velero_bucket_name" {
  description = "S3 bucket name for Velero backups"
  type        = string
}

# Git repository URL for ArgoCD
# The source of truth for all deployments
variable "argocd_repo_url" {
  description = "Git repository URL for ArgoCD"
  type        = string
}

# Git repository path for ArgoCD applications
variable "argocd_repo_path" {
  description = "Path in Git repo where manifests live"
  type        = string
  default     = "apps"
}