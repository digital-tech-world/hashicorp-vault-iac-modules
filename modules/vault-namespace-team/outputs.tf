output "namespace_path" {
  description = "Full path of the created team namespace"
  value       = vault_namespace.team.path
}

output "namespace_id" {
  description = "Vault internal ID of the created namespace"
  value       = vault_namespace.team.id
}

output "namespace_admin_policy_name" {
  description = "Name of the namespace-admin policy inside the team namespace"
  value       = vault_policy.namespace_admin.name
}

output "oidc_auth_backend_path" {
  description = "Path of the OIDC auth backend inside the team namespace"
  value       = vault_jwt_auth_backend.oidc.path
}

output "oidc_auth_backend_accessor" {
  description = "Accessor of the OIDC auth backend (used for group alias mapping)"
  value       = vault_jwt_auth_backend.oidc.accessor
}

output "ns_admin_identity_group_id" {
  description = "Vault identity group ID for the namespace-admin external group"
  value       = vault_identity_group.ns_admin_group.id
}

output "ns_admin_role_name" {
  description = "OIDC role name that issues namespace-admin tokens"
  value       = vault_jwt_auth_backend_role.ns_admin.role_name
}
