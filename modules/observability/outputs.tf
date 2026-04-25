
# ---------------------------------------------------------------------------------------------------------------------
# OBSERVABILITY MODULE OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------
# These outputs provide the consumer with Helm values and
# configuration needed to install the observability stack.
# ---------------------------------------------------------------------------------------------------------------------

# Namespace where observability components will be installed
output "namespace" {
  description = "Kubernetes namespace for observability stack"
  value       = "monitoring"
}

# Prometheus Helm values (passed to helm_release resource)
output "prometheus_helm_values" {
  description = "Helm values for Prometheus"
  value       = local.prometheus_values
}

# Grafana Helm values (passed to helm_release resource)
output "grafana_helm_values" {
  description = "Helm values for Grafana"
  value       = local.grafana_values
}

# Loki Helm values (passed to helm_release resource)
output "loki_helm_values" {
  description = "Helm values for Loki"
  value       = local.loki_values
}

# Name of the Kubernetes Secret containing Grafana admin password
# The consumer must create this Secret before installing Grafana
output "grafana_admin_secret_name" {
  description = "Secret name for Grafana admin credentials"
  value       = "grafana-admin-credentials"
}