# ---------------------------------------------------------------------------------------------------------------------
# EKS CONTROL PLANE IAM ROLE
# ---------------------------------------------------------------------------------------------------------------------
# IAM role that AWS assumes to manage the EKS cluster on your behalf.
# This role allows EKS to create ENIs, manage load balancers, and 
# interact with other AWS services as part of cluster operations.
# ---------------------------------------------------------------------------------------------------------------------

# IAM role for EKS control plane
# Trust policy allows only EKS service to assume this role
resource "aws_iam_role" "cluster" {
  name = "${var.project_name}-${var.environment}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"                  # Only EKS service can assume this
      }
      Action = "sts:AssumeRole"                        # Standard STS assume role action
    }]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-cluster-role"
  }
}

# Attach AWS managed policy for EKS cluster operations
# Grants permissions to manage EC2, ELB, and other resources for cluster
resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Attach VPC resource controller policy
# Enables advanced networking features like security groups for pods
resource "aws_iam_role_policy_attachment" "cluster_vpc_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}