# Azure Key Vault Configuration
# Secrets and certificate management - BRIT Insurance
# Author: Nimisha Chelladurai

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                = "${var.prefix}-keyvault"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Soft delete protection
  soft_delete_retention_days = 90
  purge_protection_enabled   = true

  # Network access control - private only
  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"

    ip_rules = [var.allowed_ip]
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Key Vault Secret - DB Connection String
resource "azurerm_key_vault_secret" "db_connection" {
  name         = "db-connection-string"
  value        = var.db_connection_string
  key_vault_id = azurerm_key_vault.kv.id

  tags = {
    Environment = var.environment
  }
}

# Key Vault Secret - API Key
resource "azurerm_key_vault_secret" "api_key" {
  name         = "app-api-key"
  value        = var.api_key
  key_vault_id = azurerm_key_vault.kv.id

  tags = {
    Environment = var.environment
  }
}

# RBAC - Key Vault Secrets Officer (Admin)
resource "azurerm_role_assignment" "kv_secrets_officer" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.admin_principal_id
}

# RBAC - Key Vault Secrets User (Application)
resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.app_principal_id
}

# Key Vault Certificate
resource "azurerm_key_vault_certificate" "ssl_cert" {
  name         = "${var.prefix}-ssl-cert"
  key_vault_id = azurerm_key_vault.kv.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]
      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]
      subject            = "CN=${var.prefix}-ssl"
      validity_in_months = 12
    }
  }
}
