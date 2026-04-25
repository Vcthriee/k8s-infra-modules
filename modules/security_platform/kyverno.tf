
# ---------------------------------------------------------------------------------------------------------------------
# KYVERNO - KUBERNETES POLICY ENGINE
# ---------------------------------------------------------------------------------------------------------------------
# Kyverno is a policy engine designed for Kubernetes.
# It validates, mutates, and generates configurations using
# Kubernetes-native YAML (not Rego like OPA).
# 
# Policies enforced:
# - Require resource limits (prevent cluster starvation)
# - Require labels (cost allocation, ownership)
# - Block latest image tags (enforce immutable tags)
# - Auto-inject sidecars (observability agents)
# - Generate network policies (default deny)
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Helm values for Kyverno installation
  kyverno_values = {
    
    # Kyverno configuration
    config = {
      # Webhook configuration
      webhooks = [
        {
          namespaceSelector = {
            matchExpressions = [
              {
                key      = "kubernetes.io/metadata.name"
                operator = "NotIn"
                values   = ["kube-system", "kyverno"]      # Don't enforce on system namespaces
              }
            ]
          }
        }
      ]
    }
    
    # Resource constraints for Kyverno pods
    resources = {
      limits = {
        cpu    = "500m"
        memory = "256Mi"
      }
      requests = {
        cpu    = "100m"
        memory = "128Mi"
      }
    }
    
    # ServiceMonitor for Prometheus metrics
    serviceMonitor = {
      enabled = true                                     # Enable metrics scraping
    }
  }
  
  # Kyverno policies to enforce (as Kubernetes manifests)
  # These are applied after Kyverno is installed
  kyverno_policies = {
    
    # Policy 1: Require resource limits
    # Prevents pods from consuming all cluster resources
    require_limits = <<-YAML
      apiVersion: kyverno.io/v1
      kind: ClusterPolicy
      metadata:
        name: require-resource-limits
        annotations:
          policies.kyverno.io/title: Require Resource Limits
          policies.kyverno.io/category: Best Practices
          policies.kyverno.io/severity: medium
          policies.kyverno.io/subject: Pod
      spec:
        validationFailureAction: Enforce                   # Block non-compliant pods
        background: true
        rules:
        - name: validate-resources
          match:
            resources:
              kinds:
              - Pod
          validate:
            message: "Pods must specify resource limits"
            pattern:
              spec:
                containers:
                - resources:
                    limits:
                      memory: "?*"                        # Memory limit required
                      cpu: "?*"                           # CPU limit required
    YAML
    
    # Policy 2: Block latest image tags
    # Enforces immutable infrastructure
    block_latest = <<-YAML
      apiVersion: kyverno.io/v1
      kind: ClusterPolicy
      metadata:
        name: disallow-latest-tag
        annotations:
          policies.kyverno.io/title: Disallow Latest Tag
          policies.kyverno.io/category: Best Practices
          policies.kyverno.io/severity: medium
      spec:
        validationFailureAction: Enforce
        rules:
        - name: validate-image-tag
          match:
            resources:
              kinds:
              - Pod
          validate:
            message: "Using 'latest' tag is not allowed"
            pattern:
              spec:
                containers:
                - image: "!*:latest"                      # Block images ending in :latest
    YAML
    
    # Policy 3: Require labels for cost allocation
    require_labels = <<-YAML
      apiVersion: kyverno.io/v1
      kind: ClusterPolicy
      metadata:
        name: require-labels
        annotations:
          policies.kyverno.io/title: Require Labels
          policies.kyverno.io/category: Cost Management
      spec:
        validationFailureAction: Enforce
        rules:
        - name: check-team-label
          match:
            resources:
              kinds:
              - Pod
              - Deployment
              - Service
          validate:
            message: "Resource must have app.kubernetes.io/team label"
            pattern:
              metadata:
                labels:
                  app.kubernetes.io/team: "?*"            # Team label required
        - name: check-cost-center
          match:
            resources:
              kinds:
              - Pod
              - Deployment
              - Service
          validate:
            message: "Resource must have cost-center label"
            pattern:
              metadata:
                labels:
                  cost-center: "?*"                        # Cost center required
    YAML
    
    # Policy 4: Auto-generate network policies for new namespaces
    generate_networkpolicy = <<-YAML
      apiVersion: kyverno.io/v1
      kind: ClusterPolicy
      metadata:
        name: generate-default-networkpolicy
        annotations:
          policies.kyverno.io/title: Generate Default Network Policy
          policies.kyverno.io/category: Security
      spec:
        rules:
        - name: generate-network-policy
          match:
            resources:
              kinds:
              - Namespace
          generate:
            kind: NetworkPolicy
            apiVersion: networking.k8s.io/v1
            name: default-deny
            namespace: "{{request.object.metadata.name}}"
            synchronize: true
            data:
              spec:
                podSelector: {}                             # Select all pods
                policyTypes:
                - Ingress                                     # Deny all ingress
                - Egress                                      # Deny all egress
    YAML
  }
}

# Output Helm values for consumer
