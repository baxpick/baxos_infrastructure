# Group for all
# #############

resource "azurerm_resource_group" "rg" {
  name     = var.rg_all
  location = var.location
}

# Storage
# #######

# Storage Account
resource "azurerm_storage_account" "storage" {
  name                            = "sa${var.project}build${var.environment}"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  access_tier                     = "Hot"
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = true
  shared_access_key_enabled       = true # REMARK: must be true so azure container can access it
  public_network_access_enabled   = true
  local_user_enabled              = false

  share_properties {
    retention_policy {
      days = 1  # Minimal recovery window
    }
    smb {
      versions = ["SMB3.0", "SMB3.1.1"]
    }
  }
}

# File Share
resource "azurerm_storage_share" "share" {
  name                    = "share${var.project}build${var.environment}"
  storage_account_id      = azurerm_storage_account.storage.id
  quota                   = 1
  
  #access_tier             = "Cool" # Lower storage cost, higher access cost
  access_tier             = "Hot"
  enabled_protocol        = "SMB"
}

# Containers
# ##########

resource "azurerm_container_registry" "acr" {
  name                = "acr${var.project}${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = true
}

# Azure Container Group for Build Containers
resource "azurerm_container_group" "build-containers" {
  name                = "build-containers-${var.project}-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  ip_address_type     = "None"   # Build containers should not be publicly accessible
  restart_policy      = "Never"

  # Use dynamic block to create containers
  dynamic "container" {
    for_each = local.containers
    content {
      name   = "build-${container.value.platform}-${container.value.card}"
      image  = "${azurerm_container_registry.acr.login_server}/cpctelera-build-${container.value.platform}:latest"
      cpu    = local.container_defaults.cpu
      memory = local.container_defaults.memory

      # Merge common and specific environment variables
      environment_variables = merge(
        local.container_defaults.common_env_vars,
        {
          "ARG_SF3_OR_RSF3" = "${container.value.card}"
          "ARG_PLATFORM"    = "${container.value.platform}"
        }
      )

      volume {
        name                 = "vol-${container.value.platform}-${container.value.card}"
        mount_path           = "/output"
        read_only            = false
        share_name           = azurerm_storage_share.share.name
        storage_account_name = azurerm_storage_account.storage.name
        storage_account_key  = azurerm_storage_account.storage.primary_access_key
      }
    }
  }

  image_registry_credential {
    server   = azurerm_container_registry.acr.login_server
    username = azurerm_container_registry.acr.admin_username
    password = azurerm_container_registry.acr.admin_password
  }
}

# New container group for the web server
resource "azurerm_container_group" "web_server" {
  name                = "server-containers-${var.project}-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  ip_address_type     = "Public"
  dns_name_label      = "server-${var.project}-${var.environment}"
  restart_policy      = "OnFailure"
  
  container {
    name   = local.web_server.name
    image  = local.web_server.image
    cpu    = local.web_server.cpu
    memory = local.web_server.memory

    # Mount the share at the nginx html directory
    volume {
      name                 = "nginx-share"
      mount_path           = "/usr/share/nginx/html"
      read_only            = true  # Read-only access is sufficient for serving files
      share_name           = azurerm_storage_share.share.name
      storage_account_name = azurerm_storage_account.storage.name
      storage_account_key  = azurerm_storage_account.storage.primary_access_key
    }

    ports {
      port     = local.web_server.port
      protocol = "TCP"
    }
  }
}

# DNS
# ###

## DNS Zone
resource "azurerm_dns_zone" "dns_zone" {
  name                = "osmobits.com"
  resource_group_name = azurerm_resource_group.rg.name
}
