
# ---------------------------------------------------------------------------------------------------------------------
# PROMETHEUS CONFIGURATION
# ---------------------------------------------------------------------------------------------------------------------
# Prometheus is a time-series database that scrapes metrics from
# Kubernetes API server, nodes, and application pods. It stores
# metrics for alerting and visualization in Grafana.
# 
# Key features configured:
# - Service discovery: Automatically finds pods to scrape via K8s API
# - Retention: Local storage limited to control costs
# - Remote write: Can forward to long-term storage (Thanos, Cortex)
# - Pod scraping: Uses annotations to identify scrape targets
# ---------------------------------------------------------------------------------------------------------------------

# Local values block defines the complete Helm values for Prometheus
# This is output to the consumer which applies it via helm_release
locals {
  prometheus_values = {
    
    # Main Prometheus server configuration
    server = {
      
      # How long to keep metrics locally (e.g., "7d" for 7 days)
      # After this, metrics are deleted or remote-written if configured
      retention = "${var.retention_days}d"
      
      # Persistent volume for metrics storage
      # Prevents data loss when pod restarts
      persistentVolume = {
        enabled      = true                              # Enable PVC
        size         = "10Gi"                            # 10GB storage
        storageClass = "gp2"                             # AWS EBS gp2 volume
      }
      
      # Resource requests and limits for the Prometheus pod
      # Requests: guaranteed resources (kubelet reserves these)
      # Limits: maximum allowed (OOMKill if exceeded)
      resources = {
        requests = {
          cpu    = "500m"                                # 0.5 vCPU guaranteed
          memory = "512Mi"                               # 512MB guaranteed
        }
        limits = {
          cpu    = "1000m"                               # 1 vCPU max
          memory = "1Gi"                                 # 1GB max
        }
      }
      
      # Service type for Prometheus API access
      # ClusterIP = internal only (accessed via Grafana or port-forward)
      service = {
        type = "ClusterIP"
      }
      
      # Remote write configuration for long-term storage
      # Currently points to self (disabled) - add Thanos/Cortex URL here
      remoteWrite = [
        {
          url = "http://localhost:9090/api/v1/write"      # Placeholder for future
        }
      ]
    }
    
    # Alertmanager handles alerts sent by Prometheus
    # Sends notifications to PagerDuty, Slack, email, etc.
    alertmanager = {
      enabled = true                                     # Enable alertmanager
      
      # Persistent storage for alertmanager state (silences, notifications)
      persistence = {
        enabled = true
        size    = "5Gi"
      }
    }
    
    # Node exporter runs on every node
    # Collects host-level metrics: CPU, memory, disk, network
    nodeExporter = {
      enabled = true                                     # DaemonSet on all nodes
    }
    
    # kube-state-metrics converts K8s resource state to metrics
    # Exports: deployment replicas, pod status, job completions
    kubeStateMetrics = {
      enabled = true                                     # Enable KSM
    }
    
    # Pushgateway allows short-lived jobs to push metrics
    # Disabled - not needed for standard workloads
    pushgateway = {
      enabled = false
    }
    
    # Prometheus scrape configuration
    # Defines what targets to scrape and how to discover them
    serverFiles = {
      "prometheus.yml" = {
        
        # List of scrape jobs (targets that expose metrics)
        scrape_configs = [
          
          # Job 1: Kubernetes API servers
          # Scrapes metrics from kube-apiserver (request rates, latency, errors)
          {
            job_name = "kubernetes-apiservers"
            
            # Service discovery: find endpoints named "kubernetes" in "default" namespace
            kubernetes_sd_configs = [
              {
                role = "endpoints"                         # Watch Kubernetes Endpoints
              }
            ]
            
            # HTTPS configuration (API server requires TLS)
            scheme = "https"
            tls_config = {
              ca_file = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"  # Use pod CA
              insecure_skip_verify = true                    # Skip cert verification (in-cluster)
            }
            
            # Authentication using pod service account token
            bearer_token_file = "/var/run/secrets/kubernetes.io/serviceaccount/token"
            
            # Relabeling: only keep the "kubernetes" endpoint in "default" namespace
            relabel_configs = [
              {
                source_labels = ["__meta_kubernetes_namespace", "__meta_kubernetes_service_name", "__meta_kubernetes_endpoint_port_name"]
                action        = "keep"
                regex         = "default;kubernetes;https"   # Only scrape this endpoint
              }
            ]
          },
          
          # Job 2: Kubernetes nodes (kubelet)
          # Scrapes node-level metrics: container CPU, memory, network
          {
            job_name = "kubernetes-nodes"
            
            kubernetes_sd_configs = [
              {
                role = "node"                              # Watch Kubernetes Nodes
              }
            ]
            
            scheme = "https"
            tls_config = {
              ca_file                 = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
              insecure_skip_verify    = true
            }
            bearer_token_file = "/var/run/secrets/kubernetes.io/serviceaccount/token"
            
            # Relabel node labels to metric labels
            relabel_configs = [
              {
                action = "labelmap"
                regex  = "__meta_kubernetes_node_label_(.+)"  # Convert node labels to metrics
              }
            ]
          },
          
          # Job 3: Kubernetes pods
          # Scrapes application pods that expose metrics
          {
            job_name = "kubernetes-pods"
            
            kubernetes_sd_configs = [
              {
                role = "pod"                               # Watch Kubernetes Pods
              }
            ]
            
            # Relabeling logic to identify scrapeable pods
            relabel_configs = [
              {
                # Only scrape pods with prometheus.io/scrape: "true" annotation
                source_labels = ["__meta_kubernetes_pod_annotation_prometheus_io_scrape"]
                action        = "keep"
                regex         = "true"
              },
              {
                # Use custom metrics path if specified (default: /metrics)
                source_labels = ["__meta_kubernetes_pod_annotation_prometheus_io_path"]
                action        = "replace"
                target_label  = "__metrics_path__"
                regex         = "(.+)"
              },
              {
                # Use custom port if specified in annotation
                source_labels = ["__address__", "__meta_kubernetes_pod_annotation_prometheus_io_port"]
                action        = "replace"
                regex         = "([^:]+)(?::\\d+)?;(\\d+)"   # Parse address and port
                replacement   = "$1:$2"                    # Reconstruct with custom port
                target_label  = "__address__"
              }
            ]
          }
        ]
      }
    }
  }
}
