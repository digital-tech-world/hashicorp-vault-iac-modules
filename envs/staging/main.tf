# =============================================================
# Staging environment  --  Vault namespace provisioning
# GitOps entrypoint: driven by ArgoCD / Atlantis on push to
# the feature/vault-namespace-iac-module (or main) branch.
# =============================================================

terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.3"
    }
  }

  # Uncomment and configure your remote state backend
  # backend "s3" {
  #   bucket = "my-tfstate-bucket"
  #   key    = "vault/staging/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

# -----------------------------------------------------------
# Input variables (values supplied via CI/CD secrets or
# a tfvars file that is NOT committed to source control)
# -----------------------------------------------------------
variable "vault_address" {
  type        = string
  description = "Vault cluster URL for the staging environment"
}

variable "vault_token" {
  type        = string
  sensitive   = true
  description = "Automation token with namespace-create permissions"
}

variable "oidc_discovery_url" {
  type        = string
  description = "Azure AD OIDC discovery URL (tenant-specific)"
}

variable "oidc_client_id" {
  type        = string
  description = "Azure AD app registration client ID"
}

variable "oidc_client_secret" {
  type        = string
  sensitive   = true
  description = "Azure AD app registration client secret"
}

# -----------------------------------------------------------
# Local values
# -----------------------------------------------------------
locals {
  env              = "staging"
  parent_namespace = ""   # root; change to "admin" if using an admin ns

  # Base redirect URIs for OIDC login (staging URLs)
  oidc_redirect_uris = [
    "https://vault-staging.example.com/ui/vault/auth/oidc/oidc/callback",
    "http://localhost:8250/oidc/callback"
  ]
}

# -----------------------------------------------------------
# Team: payments  (add more module blocks for additional teams)
# -----------------------------------------------------------
module "payments_namespace" {
  source = "../../modules/vault-namespace-team"

  vault_address    = var.vault_address
  vault_token      = var.vault_token
  parent_namespace = local.parent_namespace

  team_name = "payments"
  env       = local.env

  # OIDC / Azure AD
  oidc_auth_path           = "oidc"
  oidc_discovery_url       = var.oidc_discovery_url
  oidc_client_id           = var.oidc_client_id
  oidc_client_secret       = var.oidc_client_secret
  oidc_redirect_uris       = local.oidc_redirect_uris
  oidc_ns_admin_group_id   = "<payments-staging-aad-group-object-id>"  # replace with real AAD group OID
}

# -----------------------------------------------------------
# Team: platform  (example second team)
# -----------------------------------------------------------
module "platform_namespace" {
  source = "../../modules/vault-namespace-team"

  vault_address    = var.vault_address
  vault_token      = var.vault_token
  parent_namespace = local.parent_namespace

  team_name = "platform"
  env       = local.env

  # OIDC / Azure AD
  oidc_auth_path           = "oidc"
  oidc_discovery_url       = var.oidc_discovery_url
  oidc_client_id           = var.oidc_client_id
  oidc_client_secret       = var.oidc_client_secret
  oidc_redirect_uris       = local.oidc_redirect_uris
  oidc_ns_admin_group_id   = "<platform-staging-aad-group-object-id>"  # replace with real AAD group OID
}

# -----------------------------------------------------------
# Outputs (useful for debugging and downstream references)
# -----------------------------------------------------------
output "payments_namespace_path" {
  value = module.payments_namespace.namespace_path
}

output "platform_namespace_path" {
  value = module.platform_namespace.namespace_path
}
