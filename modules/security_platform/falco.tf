
# ---------------------------------------------------------------------------------------------------------------------
# FALCO - RUNTIME THREAT DETECTION
# ---------------------------------------------------------------------------------------------------------------------
# Falco is a cloud-native runtime security tool that detects
# anomalous activity in containers. It uses eBPF or kernel
# modules to trace system calls and match against rules.
# 
# Detects:
# - Unexpected process execution (e.g., shell in web server)
# - File access outside allowed paths
# - Network connections to unexpected destinations
# - Privilege escalation attempts
# 
# Outputs alerts to stdout (collected by Fluent Bit → Loki)
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Helm values for Falco installation
  falco_values = {
    
    # Falco driver configuration
    driver = {
      enabled  = true                                    # Enable the driver
      kind     = "modern_ebpf"                           # Use modern eBPF probe (recommended for EKS)
    }
    
    # Falco collectors (sources of security events)
    collectors = {
      # Collect from Kubernetes audit logs
      kubernetes = {
        enabled = true
      }
      # Collect from container runtime (containerd)
      containerd = {
        enabled = true
        socket  = "/run/containerd/containerd.sock"      # Standard containerd socket
      }
    }
    
    # Falco configuration
    falco = {
      # Rules files to load
      rules_files = [
        "/etc/falco/falco_rules.yaml",                     # Default Falco rules
        "/etc/falco/falco_rules.local.yaml",               # Local customizations
        "/etc/falco/rules.d"                               # Additional rule directory
      ]
      
      # HTTP server for health checks and metrics
      http_output = {
        enabled = true
        listen_port = 8765
      }
      
      # Output configuration (where alerts go)
      stdout_output = {
        enabled = true                                   # Print to stdout (captured by Fluent Bit)
      }
      
      # Program output (disabled - use stdout for simplicity)
      program_output = {
        enabled = false
      }
      
      # File output (disabled - use centralized logging)
      file_output = {
        enabled = false
      }
    }
    
    # Falco sidekick - forwards alerts to external systems
    falcosidekick = {
      enabled = false                                    # Disabled for now (enable for Slack/PagerDuty)
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
    
    # Tolerations to run on all nodes including tainted ones
    tolerations = [
      {
        operator = "Exists"                                # Tolerate any taint
      }
    ]
    
    # Run as DaemonSet (one pod per node)
    daemonset = {
      enabled = true
    }
  }
}

# Output Helm values for consumer
