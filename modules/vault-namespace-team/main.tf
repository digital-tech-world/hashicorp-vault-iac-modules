terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.3"
    }
  }
}

# ---------------------------------------------------------------
# Parent namespace provider (automation token context)
# ---------------------------------------------------------------
provider "vault" {
  address   = var.vault_address
  token     = var.vault_token
  namespace = var.parent_namespace
}

# ---------------------------------------------------------------
# 1. Team namespace  -->  <env>/<team_name>
# ---------------------------------------------------------------
resource "vault_namespace" "team" {
  path        = "${var.env}/${var.team_name}"
  description = "Namespace for team ${var.team_name} in ${var.env}"
}

# ---------------------------------------------------------------
# Child namespace provider (scoped inside the team namespace)
# ---------------------------------------------------------------
provider "vault" {
  alias     = "child"
  address   = var.vault_address
  token     = var.vault_token
  namespace = vault_namespace.team.path
}

# ---------------------------------------------------------------
# 2. Namespace-admin policy (created inside the team namespace)
# ---------------------------------------------------------------
resource "vault_policy" "namespace_admin" {
  provider = vault.child
  name     = "ns-admin"

  policy = <<EOT
# Full admin capabilities scoped to this namespace only.

# Manage auth methods
path "sys/auth/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage secrets engines
path "sys/mounts/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage ACL policies
path "sys/policies/acl/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Full access to all paths within this namespace
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOT

  depends_on = [vault_namespace.team]
}

# ---------------------------------------------------------------
# 3. OIDC / JWT auth backend (mounted inside the team namespace)
# ---------------------------------------------------------------
resource "vault_jwt_auth_backend" "oidc" {
  provider = vault.child

  path               = var.oidc_auth_path
  type               = "oidc"
  oidc_discovery_url = var.oidc_discovery_url
  oidc_client_id     = var.oidc_client_id
  oidc_client_secret = var.oidc_client_secret
  default_role       = "${var.team_name}-${var.env}-ns-admin"

  depends_on = [vault_namespace.team]
}

# ---------------------------------------------------------------
# 4. OIDC role  -->  issues tokens with namespace-admin policy
# ---------------------------------------------------------------
resource "vault_jwt_auth_backend_role" "ns_admin" {
  provider = vault.child

  backend   = vault_jwt_auth_backend.oidc.path
  role_name = "${var.team_name}-${var.env}-ns-admin"

  role_type             = "oidc"
  user_claim            = "groups"              # Azure AD groups claim (object IDs)
  bound_audiences       = [var.oidc_client_id]
  token_policies        = [vault_policy.namespace_admin.name]
  allowed_redirect_uris = var.oidc_redirect_uris
}

# ---------------------------------------------------------------
# 5. Identity external group  -->  namespace-admin
# ---------------------------------------------------------------
resource "vault_identity_group" "ns_admin_group" {
  provider = vault.child

  name     = "${var.team_name}-${var.env}-ns-admin"
  type     = "external"
  policies = [vault_policy.namespace_admin.name]
}

# ---------------------------------------------------------------
# 6. Group alias  -->  Azure AD group object ID --> Vault group
# ---------------------------------------------------------------
resource "vault_identity_group_alias" "ns_admin_alias" {
  provider = vault.child

  name           = var.oidc_ns_admin_group_id   # Azure AD group object ID from 'groups' claim
  mount_accessor = vault_jwt_auth_backend.oidc.accessor
  canonical_id   = vault_identity_group.ns_admin_group.id
}
