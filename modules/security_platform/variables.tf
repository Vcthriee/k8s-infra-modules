
# ---------------------------------------------------------------------------------------------------------------------
# SECURITY PLATFORM MODULE - INPUT VARIABLES
# ---------------------------------------------------------------------------------------------------------------------
# This module provides Kubernetes-native security: runtime threat
# detection (Falco), admission control (Kyverno), eBPF networking
# and service mesh (Cilium), and network policies for zero-trust.
# ---------------------------------------------------------------------------------------------------------------------

# Project name for resource naming and labels
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

# Environment identifier (dev, staging, prod)
variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

# EKS cluster name for Cilium and Falco configuration
variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

# VPC CIDR for network policy calculations
variable "vpc_cidr" {
  description = "VPC CIDR block for network policies"
  type        = string
}

# List of namespaces to create with default network policies
variable "protected_namespaces" {
  description = "Namespaces requiring default deny network policies"
  type        = list(string)
  default     = ["ecommerce", "monitoring", "karpenter"]
}