# ---------------------------------------------------------------------------------------------------------------------
# OBSERVABILITY MODULE - INPUT VARIABLES
# ---------------------------------------------------------------------------------------------------------------------
# This module configures the PLG stack (Prometheus, Loki, Grafana)
# for Kubernetes observability. It outputs Helm values that the
# consumer uses to install the stack.
# ---------------------------------------------------------------------------------------------------------------------

# Project name used for resource naming and labels
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

# Environment identifier for segregation (dev, staging, prod)
variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

# EKS cluster name for remote write configuration and labeling
variable "cluster_name" {
  description = "EKS cluster name for remote write configuration"
  type        = string
}

# AWS region for CloudWatch data source in Grafana
variable "aws_region" {
  description = "AWS region for CloudWatch data source configuration"
  type        = string
}

# Retention period for logs and metrics (controls cost)
variable "retention_days" {
  description = "Log and metric retention period"
  type        = number
  default     = 7
}