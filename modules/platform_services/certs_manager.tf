
# ---------------------------------------------------------------------------------------------------------------------
# CERT MANAGER - AUTOMATED TLS CERTIFICATE MANAGEMENT
# ---------------------------------------------------------------------------------------------------------------------
# Cert Manager automatically provisions and renews TLS certificates
# from Let's Encrypt (public) or private CAs.
#
# Features:
# - Automatic certificate issuance
# - Automatic renewal before expiry
# - Integration with ingress (auto-creates certificates)
# - Support for multiple issuers (staging, production)
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Helm values for Cert Manager installation
  cert_manager_values = {
    
    # Install CRDs (Custom Resource Definitions)
    installCRDs = true
    
    # Number of replicas for HA
    replicaCount = 1                                   # Single for dev
    
    # Resource constraints
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
    
    # Prometheus metrics
    prometheus = {
      enabled = true
      servicemonitor = {
        enabled = true
      }
    }
    
    # Leader election (for HA)
    config = {
      leaderElection = {
        namespace = "cert-manager"
      }
    }
  }
  
  # Let's Encrypt staging issuer (for testing, no rate limits)
  cert_manager_issuer_staging = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt-staging
    spec:
      acme:
        server: https://acme-staging-v02.api.letsencrypt.org/directory
        email: admin@${var.domain}                        # Replace with real email
        privateKeySecretRef:
          name: letsencrypt-staging
        solvers:
        - http01:
            ingress:
              class: alb                                  # Use ALB for HTTP-01 challenge
  YAML
  
  # Let's Encrypt production issuer (for real certificates)
  cert_manager_issuer_prod = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt-prod
    spec:
      acme:
        server: https://acme-v02.api.letsencrypt.org/directory
        email: admin@${var.domain}
        privateKeySecretRef:
          name: letsencrypt-prod
        solvers:
        - http01:
            ingress:
              class: alb
  YAML
  
  # Example certificate for the main domain
  cert_manager_certificate = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: ${var.project_name}-tls
      namespace: default
    spec:
      secretName: ${var.project_name}-tls-secret          # Secret where cert is stored
      issuerRef:
        name: letsencrypt-staging                         # Use staging for dev
        kind: ClusterIssuer
      dnsNames:
      - ${var.domain}
      - '*.${var.domain}'                                  # Wildcard certificate
  YAML
}
