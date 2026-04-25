
# ---------------------------------------------------------------------------------------------------------------------
# SECURITY PLATFORM MODULE OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------
# These outputs provide Helm values and Kubernetes manifests
# for the consumer to install and configure security tools.
# ---------------------------------------------------------------------------------------------------------------------

# Namespace for security tools
output "namespace" {
  description = "Kubernetes namespace for security platform tools"
  value       = "security"
}

# Falco Helm values
output "falco_helm_values" {
  description = "Helm values for Falco runtime security"
  value       = local.falco_values
}

# Kyverno Helm values
output "kyverno_helm_values" {
  description = "Helm values for Kyverno policy engine"
  value       = local.kyverno_values
}

# Kyverno policy manifests
output "kyverno_policies" {
  description = "Kyverno policy manifests to apply"
  value       = local.kyverno_policies
}

# Cilium Helm values
output "cilium_helm_values" {
  description = "Helm values for Cilium eBPF networking"
  value       = local.cilium_values
}

# Network policy manifests
output "default_deny_policies" {
  description = "Default deny network policies"
  value       = local.default_deny_policy
}

output "allow_dns_policies" {
  description = "DNS allow network policies"
  value       = local.allow_dns_policy
}

output "ecommerce_database_policy" {
  description = "Ecommerce database access policy"
  value       = local.ecommerce_db_policy
}