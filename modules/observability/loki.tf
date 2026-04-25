
# ---------------------------------------------------------------------------------------------------------------------
# LOKI CONFIGURATION
# ---------------------------------------------------------------------------------------------------------------------
# Loki is a log aggregation system designed for Kubernetes.
# Unlike Elasticsearch, it only indexes labels (metadata) not
# full log content, making it 10x cheaper for the same volume.
# 
# Architecture: Simple scalable mode (single binary for dev)
# Storage: Filesystem PVC (S3 in production)
# ---------------------------------------------------------------------------------------------------------------------

locals {
  loki_values = {
    
    # Loki server configuration
    loki = {
      
      # Disable multi-tenant authentication (single team)
      auth_enabled = false
      
      # Replication factor for ingesters (1 for dev, 3 for production)
      commonConfig = {
        replication_factor = 1
      }
      
      # Storage backend configuration
      storage = {
        type = "filesystem"                              # Local PVC (use S3 in prod)
      }
      
      # Limits to prevent resource exhaustion
      limits_config = {
        enforce_metric_name       = false                  # Allow any metric names
        reject_old_samples        = true                   # Reject logs older than max age
        reject_old_samples_max_age = "${var.retention_days * 24}h"  # Convert days to hours
      }
    }
    
    # Single binary mode: all Loki components in one pod
    # Good for dev/small clusters. Production uses distributed mode.
    singleBinary = {
      
      replicas = 1                                       # One pod (HA not needed for dev)
      
      # Persistent storage for log data
      persistence = {
        enabled      = true
        size         = "10Gi"
        storageClass = "gp2"
      }
      
      # Resource constraints
      resources = {
        requests = {
          cpu    = "200m"
          memory = "256Mi"
        }
        limits = {
          cpu    = "1000m"                               # 1 vCPU max
          memory = "1Gi"                                 # 1GB max
        }
      }
    }
    
    # Disable self-monitoring (Grafana Agent) to reduce complexity
    monitoring = {
      selfMonitoring = {
        enabled = false                                  # Don't monitor Loki with itself
      }
      lokiCanary = {
        enabled = false                                  # Disable synthetic log generator
      }
    }
    
    # Disable built-in tests
    test = {
      enabled = false
    }
    
    # Disable gateway (nginx frontend) - access via Kubernetes service
    gateway = {
      enabled = false
    }
    
    # Disable ingress - access via port-forward or internal service
    ingress = {
      enabled = false
    }
  }
}