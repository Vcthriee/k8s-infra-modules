# ---------------------------------------------------------------------------------------------------------------------
# KARPENTER CONTROLLER IAM ROLE AND SPOT INTERRUPTION HANDLING
# ---------------------------------------------------------------------------------------------------------------------
# Karpenter runs as a pod in the cluster but needs AWS permissions
# to launch and terminate EC2 instances. This file creates:
# 1. IRSA role for Karpenter controller pod
# 2. SQS queue for Spot interruption warnings
# 3. EventBridge rule to capture interruption events
# 4. IAM role for EventBridge to write to SQS
# 
# Spot interruption handling gives Karpenter 2-minute warning before
# AWS reclaims Spot instances, allowing graceful pod eviction.
# ---------------------------------------------------------------------------------------------------------------------

# IRSA role for Karpenter controller pod
# Allows Karpenter pod to assume AWS role via OIDC
resource "aws_iam_role" "karpenter_controller" {
  name = "${var.project_name}-${var.environment}-karpenter-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.cluster.arn  # Trust OIDC provider
      }
      Action = "sts:AssumeRoleWithWebIdentity"                    # Web identity federation
      Condition = {
        StringEquals = {
          # Only this specific service account can assume this role
          "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:sub" = "system:serviceaccount:karpenter:karpenter"
          "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-karpenter-role"
  }
}

# IAM policy for Karpenter controller
# Grants permissions to launch, describe, and terminate EC2 instances
resource "aws_iam_role_policy" "karpenter_controller" {
  name = "${var.project_name}-${var.environment}-karpenter-policy"
  role = aws_iam_role.karpenter_controller.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateLaunchTemplate",                    # Create launch templates for nodes
          "ec2:DeleteLaunchTemplate",                    # Cleanup old templates
          "ec2:DescribeLaunchTemplates",               # List existing templates
          "ec2:DescribeInstances",                       # Check running instances
          "ec2:DescribeSecurityGroups",                  # Get security group info
          "ec2:DescribeSubnets",                         # Get subnet info for placement
          "ec2:DescribeInstanceTypes",                 # Get instance capabilities
          "ec2:DescribeInstanceTypeOfferings",           # Check what's available in AZs
          "ec2:DescribeAvailabilityZones",               # List AZs
          "ec2:DescribeSpotPriceHistory",                # Get Spot pricing for decisions
          "ec2:CreateFleet",                             # Launch instances (modern API)
          "ec2:RunInstances",                            # Launch instances (legacy API)
          "ec2:TerminateInstances",                      # Terminate nodes when consolidating
          "ec2:DescribeImages",                          # Find AMIs
          "pricing:GetProducts",                         # Get pricing for cost optimization
          "ssm:GetParameter"                             # Get AMI SSM parameters
        ]
        Resource = "*"                                   # These are describe/launch actions
      },
      {
        Effect = "Allow"
        Action = "iam:PassRole"                          # Pass node role to EC2 instances
        Resource = aws_iam_role.nodes.arn                # Only pass the node role we created
      },
      {
        Effect = "Allow"
        Action = "eks:DescribeCluster"                   # Get cluster info for node join
        Resource = aws_eks_cluster.main.arn
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:DeleteMessage",                           # Remove processed interruption notices
          "sqs:GetQueueAttributes",                      # Check queue status
          "sqs:GetQueueUrl",                             # Get queue URL
          "sqs:ReceiveMessage"                           # Poll for interruption notices
        ]
        Resource = aws_sqs_queue.karpenter_interruption.arn
      }
    ]
  })
}

# SQS queue for Spot interruption notices
# AWS sends interruption warning to this queue 2 minutes before reclaim
resource "aws_sqs_queue" "karpenter_interruption" {
  name = "${var.project_name}-${var.environment}-karpenter-interruption"

  message_retention_seconds = 300                      # 5 minutes retention (quick processing)
  sqs_managed_sse_enabled   = true                     # Server-side encryption

  tags = {
    Name = "${var.project_name}-${var.environment}-karpenter-interruption"
  }
}

# SQS queue policy - allows EventBridge and SQS to send messages
resource "aws_sqs_queue_policy" "karpenter_interruption" {
  queue_url = aws_sqs_queue.karpenter_interruption.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"               # EventBridge service
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.karpenter_interruption.arn
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "sqs.amazonaws.com"                    # SQS service itself
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.karpenter_interruption.arn
      }
    ]
  })
}

# EventBridge rule - captures EC2 Spot interruption warnings
resource "aws_cloudwatch_event_rule" "spot_interruption" {
  name        = "${var.project_name}-${var.environment}-spot-interruption"
  description = "Capture EC2 Spot Instance Interruption Warnings for Karpenter"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]                            # EC2 service events
    detail-type = ["EC2 Spot Instance Interruption Warning"]  # Specific event type
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-spot-interruption"
  }
}

# EventBridge target - forwards interruption events to SQS queue
resource "aws_cloudwatch_event_target" "spot_interruption" {
  rule     = aws_cloudwatch_event_rule.spot_interruption.name
  arn      = aws_sqs_queue.karpenter_interruption.arn
  role_arn = aws_iam_role.karpenter_events.arn         # IAM role for EventBridge to write to SQS
}

# IAM role for EventBridge to send messages to SQS
resource "aws_iam_role" "karpenter_events" {
  name = "${var.project_name}-${var.environment}-karpenter-events-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"                 # EventBridge service
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-karpenter-events-role"
  }
}

# IAM policy allowing EventBridge to send messages to SQS
resource "aws_iam_role_policy" "karpenter_events" {
  name = "${var.project_name}-${var.environment}-karpenter-events-policy"
  role = aws_iam_role.karpenter_events.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sqs:SendMessage"
      Resource = aws_sqs_queue.karpenter_interruption.arn
    }]
  })
}