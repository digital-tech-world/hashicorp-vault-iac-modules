# ---------------------------------------------------------------------------
# modules/vault-namespace-team/variables.tf
# ---------------------------------------------------------------------------

variable "vault_address" {
  type        = string
  description = "Vault cluster URL, e.g. https://vault.example.com"
}

variable "vault_token" {
  type        = string
  description = "Root / automation token used by GitOps pipeline (store in CI secrets)"
  sensitive   = true
}

variable "parent_namespace" {
  type        = string
  description = "Parent namespace path. Use empty string for root. E.g. 'admin'"
  default     = ""
}

variable "team_name" {
  type        = string
  description = "Short team slug used for namespace path and resource names, e.g. 'payments'"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.team_name))
    error_message = "team_name must be lowercase alphanumeric with hyphens only."
  }
}

variable "env" {
  type        = string
  description = "Deployment environment label."

  validation {
    condition     = contains(["prod", "staging"], var.env)
    error_message = "env must be one of: prod, staging."
  }
}

variable "admin_auth_type" {
  type        = string
  description = "Auth backend type for namespace admin self-service. Supported: oidc, userpass, ldap, approle"
  default     = "oidc"

  validation {
    condition     = contains(["oidc", "userpass", "ldap", "approle"], var.admin_auth_type)
    error_message = "admin_auth_type must be one of: oidc, userpass, ldap, approle."
  }
}

variable "admin_auth_path" {
  type        = string
  description = "Mount path for the admin auth method inside the team namespace."
  default     = "oidc"
}

variable "oidc_discovery_url" {
  type        = string
  description = "OIDC discovery URL (required when admin_auth_type = oidc)."
  default     = ""
}

variable "oidc_client_id" {
  type        = string
  description = "OIDC client ID (required when admin_auth_type = oidc)."
  default     = ""
  sensitive   = true
}

variable "oidc_client_secret" {
  type        = string
  description = "OIDC client secret (required when admin_auth_type = oidc)."
  default     = ""
  sensitive   = true
}

variable "admin_group_name" {
  type        = string
  description = "Identity group name that receives namespace-admin policy."
  default     = "ns-admins"
}

variable "default_lease_ttl" {
  type        = string
  description = "Default lease TTL for the namespace."
  default     = "768h"
}

variable "max_lease_ttl" {
  type        = string
  description = "Maximum lease TTL for the namespace."
  default     = "8760h"
}

variable "tags" {
  type        = map(string)
  description = "Arbitrary metadata tags added to namespace description."
  default     = {}
}
