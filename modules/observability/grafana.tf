
# ---------------------------------------------------------------------------------------------------------------------
# GRAFANA CONFIGURATION
# ---------------------------------------------------------------------------------------------------------------------
# Grafana is the visualization layer for observability data.
# It connects to Prometheus (metrics), Loki (logs), and CloudWatch
# to provide unified dashboards and alerting.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  grafana_values = {
    
    # Admin credentials configuration
    # References a Kubernetes Secret created by the consumer
    admin = {
      existingSecret = "grafana-admin-credentials"       # Secret name in K8s
    }
    
    # Persistent storage for dashboards and settings
    # Survives pod restarts and updates
    persistence = {
      enabled      = true
      size         = "5Gi"
      storageClass = "gp2"
    }
    
    # Data sources: connections to metric and log backends
    # Pre-configured so dashboards work immediately after install
    datasources = {
      "datasources.yaml" = {
        apiVersion = 1                                   # Grafana API version
        
        # List of data source connections
        datasources = [
          {
            name      = "Prometheus"                     # Display name in Grafana
            type      = "prometheus"                     # Data source type
            url       = "http://prometheus-server.monitoring.svc.cluster.local"  # In-cluster URL
            access    = "proxy"                          # Grafana proxies requests (no CORS)
            isDefault = true                             # Default for new panels
          },
          {
            name   = "Loki"                              # Log aggregation
            type   = "loki"
            url    = "http://loki.monitoring.svc.cluster.local:3100"
            access = "proxy"
          },
          {
            name   = "CloudWatch"                        # AWS native metrics
            type   = "cloudwatch"
            jsonData = {
              defaultRegion = var.aws_region             # Use same region as cluster
              authType      = "default"                  # Use IRSA or instance role
            }
          }
        ]
      }
    }
    
    # Dashboard providers: where to load dashboards from
    dashboardProviders = {
      "dashboardproviders.yaml" = {
        apiVersion = 1
        
        providers = [
          {
            name              = "default"
            orgId             = 1                          # Default organization
            folder            = ""                         # Root folder
            type              = "file"                      # Load from files
            disableDeletion   = false                      # Allow dashboard deletion
            editable          = true                       # Allow UI editing
            options = {
              path = "/var/lib/grafana/dashboards/default"  # Path in container
            }
          }
        ]
      }
    }
    
    # Pre-loaded dashboards (from Grafana.com)
    # These provide immediate value without manual configuration
    dashboards = {
      default = {
        # Kubernetes cluster overview dashboard
        "kubernetes-cluster" = {
          gnetId     = 724                                  # Grafana.com dashboard ID
          revision   = 1                                    # Version to use
          datasource = "Prometheus"                         # Which DS to use
        }
        # Node exporter full dashboard (detailed node metrics)
        "node-exporter" = {
          gnetId     = 1860
          revision   = 27
          datasource = "Prometheus"
        }
      }
    }
    
    # Service type for Grafana UI access
    service = {
      type = "ClusterIP"                                  # Internal only
    }
    
    # Ingress for external access via ALB
    ingress = {
      enabled = true
      
      annotations = {
        "kubernetes.io/ingress.class"                = "alb"           # Use AWS ALB
        "alb.ingress.kubernetes.io/scheme"           = "internet-facing"  # Public ALB
        "alb.ingress.kubernetes.io/target-type"      = "ip"            # Target pods directly
      }
      
      # DNS name for Grafana (update with real domain in production)
      hosts = ["grafana.${var.project_name}.${var.environment}.local"]
    }
    
    # Resource constraints for Grafana pod
    resources = {
      requests = {
        cpu    = "100m"                                   # 0.1 vCPU
        memory = "128Mi"                                  # 128MB
      }
      limits = {
        cpu    = "500m"                                   # 0.5 vCPU max
        memory = "256Mi"                                  # 256MB max
      }
    }
  }
}
