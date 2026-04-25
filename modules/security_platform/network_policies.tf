
# ---------------------------------------------------------------------------------------------------------------------
# DEFAULT NETWORK POLICIES
# ---------------------------------------------------------------------------------------------------------------------
# Network policies provide zero-trust micro-segmentation.
# These policies are applied to all protected namespaces to
# enforce least-privilege communication.
# 
# Default posture: deny all, explicitly allow required traffic
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Default deny all ingress and egress for protected namespaces
  # Applied by Kyverno generate policy, but explicit here for reference
  default_deny_policy = {
    for namespace in var.protected_namespaces : namespace => <<-YAML
      apiVersion: networking.k8s.io/v1
      kind: NetworkPolicy
      metadata:
        name: default-deny-all
        namespace: ${namespace}
      spec:
        podSelector: {}                                   # Select all pods in namespace
        policyTypes:
        - Ingress                                         # Deny all incoming traffic
        - Egress                                          # Deny all outgoing traffic
    YAML
  }
  
  # Allow DNS egress (required by all pods for service discovery)
  allow_dns_policy = {
    for namespace in var.protected_namespaces : namespace => <<-YAML
      apiVersion: networking.k8s.io/v1
      kind: NetworkPolicy
      metadata:
        name: allow-dns
        namespace: ${namespace}
      spec:
        podSelector: {}                                   # All pods
        policyTypes:
        - Egress
        egress:
        - to:
          - namespaceSelector:
              matchLabels:
                kubernetes.io/metadata.name: kube-system  # kube-system namespace
          ports:
          - protocol: UDP
            port: 53                                      # DNS
          - protocol: TCP
            port: 53                                      # DNS TCP fallback
    YAML
  }
  
  # Allow ecommerce namespace to reach database
  ecommerce_db_policy = <<-YAML
    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: allow-ecommerce-to-db
      namespace: ecommerce
    spec:
      podSelector:
        matchLabels:
          app: ecommerce-api                              # Only ecommerce API pods
      policyTypes:
      - Egress
      egress:
      - to:
        - ipBlock:
            cidr: ${var.vpc_cidr}                         # VPC CIDR (includes RDS/ElastiCache)
        ports:
        - protocol: TCP
          port: 5432                                      # PostgreSQL
        - protocol: TCP
          port: 6379                                      # Redis
  YAML
}

# Output default deny policies
