# ---------------------------------------------------------------------------------------------------------------------
# TERRAFORM BACKEND CONFIGURATION
# ---------------------------------------------------------------------------------------------------------------------
# Stores Terraform state in S3 with DynamoDB locking.
# This enables team collaboration and state recovery.
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  # Required Terraform version
  required_version = ">= 1.6.0"

  # Required providers
  required_providers {
    # AWS provider for infrastructure resources
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    
    # Kubernetes provider for K8s resources
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    
    # Helm provider for chart installations
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    
    # kubectl provider for raw manifests
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.0"
    }
  }

  # Remote state backend
  backend "s3" {
    bucket         = "cloudthrieesecurity-terraform-state"  # S3 bucket for state
    key            = "ecommerce-k8s/dev/terraform.tfstate"    # State file path
    region         = "af-south-1"                           # Cape Town region
    encrypt        = true                                   # Server-side encryption
    dynamodb_table = "cloudthrieesecurity-terraform-state-lock"  # Lock table
  }
}