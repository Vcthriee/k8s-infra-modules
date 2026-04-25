
# ---------------------------------------------------------------------------------------------------------------------
# VELERO - BACKUP AND DISASTER RECOVERY
# ---------------------------------------------------------------------------------------------------------------------
# Velero backs up Kubernetes resources and persistent volumes
# to S3. It enables disaster recovery and cluster migration.
#
# Features:
# - Scheduled backups (cron-based)
# - On-demand backups
# - Restore to same or different cluster
# - Persistent volume snapshots (AWS EBS)
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Helm values for Velero installation
  velero_values = {
    
    # Velero image configuration
    image = {
      repository = "velero/velero"
      tag        = "v1.12.0"
    }
    
    # S3 backup storage location
    configuration = {
      backupStorageLocation = [
        {
          name = "aws"
          provider = "aws"
          bucket = var.velero_bucket_name                  # S3 bucket for backups
          prefix = var.cluster_name                        # Organize by cluster
          config = {
            region = var.aws_region
            s3ForcePathStyle = "false"
          }
        }
      ]
      
      # Volume snapshot location (AWS EBS)
      volumeSnapshotLocation = [
        {
          name = "aws"
          provider = "aws"
          config = {
            region = var.aws_region
          }
        }
      ]
      
      # Features to enable
      features = "EnableCSI"                               # Enable CSI snapshot support
    }
    
    # Credentials (not needed with IRSA, but kept for compatibility)
    credentials = {
      useSecret = false                                    # Use IRSA instead
    }
    
    # Service account with IRSA
    serviceAccount = {
      server = {
        create = true
        name   = "velero-server"
        annotations = {
          "eks.amazonaws.com/role-arn" = ""                # Add IRSA role in consumer
        }
      }
    }
    
    # Init containers (plugins)
    initContainers = [
      {
        name = "velero-plugin-for-aws"
        image = "velero/velero-plugin-for-aws:v1.8.0"
        volumeMounts = [
          {
            mountPath = "/target"
            name      = "plugins"
          }
        ]
      }
    ]
    
    # Resource constraints
    resources = {
      requests = {
        cpu    = "100m"
        memory = "256Mi"
      }
      limits = {
        cpu    = "500m"
        memory = "512Mi"
      }
    }
    
    # Deploy node agent (for CSI snapshots)
    deployNodeAgent = true
    
    # Node agent resources
    nodeAgent = {
      resources = {
        requests = {
          cpu    = "50m"
          memory = "128Mi"
        }
        limits = {
          cpu    = "250m"
          memory = "256Mi"
        }
      }
    }
    
    # Clean up CRDs on uninstall (disable for safety)
    cleanUpCRDs = false
  }
  
  # Scheduled backup - runs daily at 3 AM
  velero_schedule = <<-YAML
    apiVersion: velero.io/v1
    kind: Schedule
    metadata:
      name: daily-backup
      namespace: velero
    spec:
      schedule: 0 3 * * *                                 # Cron: 3 AM daily
      template:
        includedNamespaces:
        - '*'                                            # Backup all namespaces
        excludedNamespaces:
        - kube-system                                    # Skip system namespace
        - velero                                         # Skip self
        snapshotVolumes: true                           # Include PV snapshots
        ttl: 720h0m0s                                   # Retain for 30 days
  YAML
  
  # On-demand backup example
  velero_backup_example = <<-YAML
    apiVersion: velero.io/v1
    kind: Backup
    metadata:
      name: manual-backup-2024-01-01
      namespace: velero
    spec:
      includedNamespaces:
      - ecommerce
      - monitoring
      snapshotVolumes: true
      storageLocation: aws
      ttl: 168h0m0s                                     # 7 days retention
  YAML
}

# Output Helm values
