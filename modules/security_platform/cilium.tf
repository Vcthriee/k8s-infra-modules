
# ---------------------------------------------------------------------------------------------------------------------
# CILIUM - EBPF NETWORKING AND OBSERVABILITY
# ---------------------------------------------------------------------------------------------------------------------
# Cilium replaces kube-proxy and provides:
# - eBPF-based networking (faster, more efficient than iptables)
# - Network policies with L3/L4/L7 visibility
# - Hubble observability (pod-to-pod traffic visibility)
# - Service mesh capabilities (mTLS, traffic management)
# 
# Why Cilium over Calico:
# - eBPF is kernel-native (performance)
# - No sidecars for service mesh (efficiency)
# - Built-in observability (Hubble)
# - Replaces multiple tools (kube-proxy, Calico, Istio sidecars)
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Helm values for Cilium installation
  cilium_values = {
    
    # Cilium version and upgrade settings
    upgradeCompatibility = "1.16"
    
    # Cluster configuration
    cluster = {
      name = var.cluster_name
      id   = 0                                           # Cluster ID for multi-cluster (0 = single cluster)
    }
    
    # IP address management (Cilium replaces AWS VPC CNI optionally)
    # For now, we run in chaining mode with AWS VPC CNI
    ipam = {
      mode = "cluster-pool"                              # Cilium manages pod IPs
      operator = {
        clusterPoolIPv4PodCIDRList = ["10.0.0.0/8"]       # Pod CIDR range
        clusterPoolIPv4MaskSize = 24                       # /24 per node
      }
    }
    
    # eBPF settings
    bpf = {
      masquerade = true                                  # eBPF-based NAT (faster than iptables)
    }
    
    # kube-proxy replacement (optional - can coexist initially)
    kubeProxyReplacement = "partial"                     # Replace some kube-proxy functions
    
    # Hubble observability
    hubble = {
      enabled = true                                     # Enable Hubble
      
      # Hubble UI for visualizing pod-to-pod traffic
      ui = {
        enabled = true
      }
      
      # Hubble relay for multi-node visibility
      relay = {
        enabled = true
      }
      
      # Metrics for Prometheus
      metrics = {
        enabled = [
          "dns:query",                                   # DNS query metrics
          "drop",                                        # Packet drop metrics
          "tcp",                                         # TCP metrics
          "flow",                                        # Flow metrics
          "icmp",                                        # ICMP metrics
          "http"                                         # HTTP metrics (L7)
        ]
      }
    }
    
    # Prometheus metrics
    prometheus = {
      enabled = true
      port    = 9090
    }
    
    # Operator configuration
    operator = {
      enabled = true
      replicas = 1                                       # Single replica for dev
      
      prometheus = {
        enabled = true
      }
      
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
    
    # Agent configuration (runs on every node as DaemonSet)
    resources = {
      requests = {
        cpu    = "100m"
        memory = "128Mi"
      }
      limits = {
        cpu    = "1000m"                                 # Can spike during policy updates
        memory = "256Mi"
      }
    }
    
    # Enable host firewall (optional security layer)
    hostFirewall = {
      enabled = false                                    # Disable initially (complexity)
    }
    
    # Enable bandwidth manager for QoS
    bandwidthManager = {
      enabled = true
    }
  }
}

# Output Helm values for consumer
