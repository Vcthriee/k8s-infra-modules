# ---------------------------------------------------------------------------------------------------------------------
# EKS WORKER NODE IAM ROLE
# ---------------------------------------------------------------------------------------------------------------------
# IAM role attached to EC2 instances that join the cluster as nodes.
# This role is a fallback - pods should use IRSA for AWS access.
# Nodes use this role to register with cluster and pull images.
# ---------------------------------------------------------------------------------------------------------------------

# IAM role for EC2 worker nodes
# Trust policy allows EC2 service to assume this role
resource "aws_iam_role" "nodes" {
  name = "${var.project_name}-${var.environment}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"                    # Only EC2 can assume this role
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-node-role"
  }
}

# Attach EKS worker node policy
# Allows nodes to register with cluster and describe resources
resource "aws_iam_role_policy_attachment" "nodes_worker" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Attach VPC CNI policy
# Allows nodes to configure pod networking (assign IP addresses)
resource "aws_iam_role_policy_attachment" "nodes_cni" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Attach ECR read-only policy
# Allows nodes to pull container images from ECR
resource "aws_iam_role_policy_attachment" "nodes_ecr" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Custom policy for Karpenter node capabilities
# Allows nodes to report instance type and pricing info to Karpenter
resource "aws_iam_role_policy" "nodes_karpenter" {
  name = "${var.project_name}-${var.environment}-node-karpenter-policy"
  role = aws_iam_role.nodes.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",                     # Describe own instance details
          "ec2:DescribeInstanceTypes",                   # Get instance type capabilities
          "ec2:DescribeAvailabilityZones",               # Report AZ placement
          "ec2:DescribeSpotPriceHistory"                 # Report Spot pricing for decisions
        ]
        Resource = "*"                                   # Read-only EC2 describe actions
      }
    ]
  })
}
