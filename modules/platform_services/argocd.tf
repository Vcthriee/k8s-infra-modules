
# ---------------------------------------------------------------------------------------------------------------------
# ARGOCD - GITOPS CONTINUOUS DELIVERY
# ---------------------------------------------------------------------------------------------------------------------
# ArgoCD is a declarative, GitOps continuous delivery tool for
# Kubernetes. It watches a Git repository and automatically
# applies changes to the cluster.
#
# Key features:
# - Automated sync from Git to cluster
# - Drift detection (alerts if cluster diverges from Git)
# - Rollback to previous Git commits
# - ApplicationSets for multi-environment deployments
# - Image Updater for automated promotions
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Helm values for ArgoCD installation
  argocd_values = {
    
    # Global configuration
    global = {
      domain = "argocd.${var.domain}"                    # ArgoCD UI domain
    }
    
    # Server configuration (API and UI)
    server = {
      # Extra command line arguments
      extraArgs = [
        "--insecure"                                     # Disable TLS termination (handled by ALB)
      ]
      
      # Ingress configuration
      ingress = {
        enabled = true
        annotations = {
          "kubernetes.io/ingress.class"                   = "alb"
          "alb.ingress.kubernetes.io/scheme"            = "internet-facing"
          "alb.ingress.kubernetes.io/target-type"         = "ip"
          "alb.ingress.kubernetes.io/listen-ports"        = "[{\"HTTPS\":443}]"
          "alb.ingress.kubernetes.io/certificate-arn"     = ""  # Add ACM cert ARN in consumer
        }
        hosts = ["argocd.${var.domain}"]
      }
      
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
    }
    
    # Repo server (generates Kubernetes manifests)
    repoServer = {
      # Enable multiple replicas for HA
      replicas = 1                                       # Single for dev
      
      resources = {
        requests = {
          cpu    = "100m"
          memory = "256Mi"
        }
        limits = {
          cpu    = "1000m"                               # Can spike during manifest generation
          memory = "512Mi"
        }
      }
    }
    
    # Application controller (applies manifests to cluster)
    controller = {
      resources = {
        requests = {
          cpu    = "250m"
          memory = "512Mi"
        }
        limits = {
          cpu    = "1000m"
          memory = "1Gi"
        }
      }
    }
    
    # Dex (authentication)
    # Disabled for now - use admin password
    dex = {
      enabled = false
    }
    
    # Notifications (slack, email, etc.)
    notifications = {
      enabled = false                                    # Enable for production alerts
    }
    
    # ApplicationSet controller (generates apps from templates)
    applicationSet = {
      enabled = true
      resources = {
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
        limits = {
          cpu    = "500m"
          memory = "256Mi"
        }
      }
    }
  }
  
  # ArgoCD Application manifest for the main application
  # This creates the root "app of apps" that manages all other apps
  argocd_root_app = <<-YAML
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: root-app
      namespace: argocd
      finalizers:
      - resources-finalizer.argocd.argoproj.io          # Cascade delete resources
    spec:
      project: default
      source:
        repoURL: ${var.argocd_repo_url}                  # Git repository URL
        targetRevision: HEAD                             # Track main branch
        path: ${var.argocd_repo_path}                    # Path to manifests
      destination:
        server: https://kubernetes.default.svc           # In-cluster API server
        namespace: default
      syncPolicy:
        automated:
          prune: true                                    # Remove resources not in Git
          selfHeal: true                                 # Fix drift automatically
          allowEmpty: false
        syncOptions:
        - CreateNamespace=true                           # Auto-create namespaces
        retry:
          limit: 5                                       # Retry failed syncs
          backoff:
            duration: 5s
            factor: 2
            maxDuration: 3m
  YAML
  
  # ArgoCD ApplicationSet for multi-environment deployments
  # Generates applications for each environment automatically
  argocd_applicationset = <<-YAML
    apiVersion: argoproj.io/v1alpha1
    kind: ApplicationSet
    metadata:
      name: ecommerce-apps
      namespace: argocd
    spec:
      generators:
      - list:
          elements:
          - env: dev
            namespace: ecommerce-dev
            replicas: 2
          - env: staging
            namespace: ecommerce-staging
            replicas: 3
          - env: prod
            namespace: ecommerce-prod
            replicas: 5
      template:
        metadata:
          name: 'ecommerce-{{env}}'
        spec:
          project: default
          source:
            repoURL: ${var.argocd_repo_url}
            targetRevision: HEAD
            path: apps/ecommerce
            helm:
              valueFiles:
              - values-{{env}}.yaml
          destination:
            server: https://kubernetes.default.svc
            namespace: '{{namespace}}'
          syncPolicy:
            automated:
              prune: true
              selfHeal: true
            syncOptions:
            - CreateNamespace=true
  YAML
}