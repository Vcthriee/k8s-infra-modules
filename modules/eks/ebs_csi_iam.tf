# ---------------------------------------------------------------------------------------------------------------------
# EBS CSI DRIVER IRSA ROLE
# ---------------------------------------------------------------------------------------------------------------------
# IAM role for the EBS CSI driver pod to manage EBS volumes.
# Without this, pods cannot mount persistent storage.
# The driver runs as a pod in kube-system namespace.
# ---------------------------------------------------------------------------------------------------------------------

# IRSA role for EBS CSI driver
resource "aws_iam_role" "ebs_csi" {
  name = "${var.project_name}-${var.environment}-ebs-csi-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.cluster.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          # Only EBS CSI service account can assume this role
          "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-ebs-csi-role"
  }
}

# IAM policy for EBS CSI driver operations
resource "aws_iam_role_policy" "ebs_csi" {
  name = "${var.project_name}-${var.environment}-ebs-csi-policy"
  role = aws_iam_role.ebs_csi.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSnapshot",                          # Create volume snapshots for backups
          "ec2:AttachVolume",                            # Attach volume to instance
          "ec2:DetachVolume",                            # Detach volume from instance
          "ec2:ModifyVolume",                            # Resize volumes
          "ec2:DescribeAvailabilityZones",               # Find AZs for volume placement
          "ec2:DescribeInstances",                       # Find instances to attach to
          "ec2:DescribeSnapshots",                       # List existing snapshots
          "ec2:DescribeTags",                            # Read volume tags
          "ec2:DescribeVolumes",                         # List volumes
          "ec2:DescribeVolumesModifications"             # Check volume modification status
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags"                               # Tag volumes and snapshots
        ]
        Resource = [
          "arn:aws:ec2:*:*:volume/*",                    # Only EBS volumes
          "arn:aws:ec2:*:*:snapshot/*"                   # Only EBS snapshots
        ]
        Condition = {
          StringEquals = {
            "ec2:CreateAction" = ["CreateVolume", "CreateSnapshot"]  # Only on create
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DeleteTags"                               # Remove tags
        ]
        Resource = [
          "arn:aws:ec2:*:*:volume/*",
          "arn:aws:ec2:*:*:snapshot/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateVolume"                             # Create new EBS volumes
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:RequestTag/ebs.csi.aws.com/cluster" = "true"  # Must be tagged for CSI
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DeleteVolume"                             # Delete volumes
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "ec2:ResourceTag/ebs.csi.aws.com/cluster" = "true"  # Only CSI-managed volumes
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DeleteSnapshot"                             # Delete snapshots
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "ec2:ResourceTag/CSIDriverName" = "ebs.csi.aws.com"  # Only CSI snapshots
          }
        }
      }
    ]
  })
}