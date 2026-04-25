
# ---------------------------------------------------------------------------------------------------------------------
# PLATFORM SERVICES MODULE OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------
# These outputs provide Helm values and Kubernetes manifests
# for installing and configuring platform services.
# ---------------------------------------------------------------------------------------------------------------------

# Namespace for platform services
output "namespace_argocd" {
  description = "Namespace for ArgoCD"
  value       = "argocd"
}

output "namespace_cert_manager" {
  description = "Namespace for Cert Manager"
  value       = "cert-manager"
}

output "namespace_external_secrets" {
  description = "Namespace for External Secrets"
  value       = "external-secrets"
}

output "namespace_velero" {
  description = "Namespace for Velero"
  value       = "velero"
}

# ArgoCD outputs
output "argocd_helm_values" {
  description = "Helm values for ArgoCD"
  value       = local.argocd_values
}

output "argocd_root_app" {
  description = "ArgoCD root application manifest"
  value       = local.argocd_root_app
}

output "argocd_applicationset" {
  description = "ArgoCD ApplicationSet manifest"
  value       = local.argocd_applicationset
}

# Cert Manager outputs
output "cert_manager_helm_values" {
  description = "Helm values for Cert Manager"
  value       = local.cert_manager_values
}

output "cert_manager_issuer_staging" {
  description = "Let's Encrypt staging issuer"
  value       = local.cert_manager_issuer_staging
}

output "cert_manager_issuer_prod" {
  description = "Let's Encrypt production issuer"
  value       = local.cert_manager_issuer_prod
}

output "cert_manager_certificate" {
  description = "Example TLS certificate"
  value       = local.cert_manager_certificate
}

# External Secrets outputs
output "external_secrets_helm_values" {
  description = "Helm values for External Secrets"
  value       = local.external_secrets_values
}

output "cluster_secret_store" {
  description = "ClusterSecretStore manifest"
  value       = local.cluster_secret_store
}

output "external_secret_example" {
  description = "Example ExternalSecret"
  value       = local.external_secret_example
}

# Velero outputs
output "velero_helm_values" {
  description = "Helm values for Velero"
  value       = local.velero_values
}

output "velero_schedule" {
  description = "Velero scheduled backup"
  value       = local.velero_schedule
}

output "velero_backup_example" {
  description = "Velero backup example"
  value       = local.velero_backup_example
}