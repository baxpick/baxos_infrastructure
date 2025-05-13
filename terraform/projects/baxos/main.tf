### Group for all resorces
##########################

resource "azurerm_resource_group" "rg" {
  name     = var.rg_all
  location = var.location
}

# Storage
#########

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
############

resource "azurerm_container_registry" "acr" {
  name                = "acr${var.project}${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = true
}

# Azure Container Group
resource "azurerm_container_group" "containers" {
  name                = "containers-${var.project}-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  ip_address_type     = "None"
  restart_policy      = "Never"

  container {
    name   = "${var.project}-build-cpc-rsf3"
    image  = "${azurerm_container_registry.acr.login_server}/cpctelera-build-cpc:latest"
    cpu    = "4.0"
    memory = "8"

    environment_variables = {
      "IS_STARTED_FROM_BAXOS_BUILD_CONTAINER"       = "YES"
      "FOLDER_ROOT"                                 = "/build/retro/projects"
      "ARG_PLATFORM"                                = "CPC"
      "ARG_COMPRESSION"                             = "NONE"
      "ARG_SF3_OR_RSF3"                             = "RSF3"
      "GIT_ROOT_CREDS"                              = var.baxos_src_git_root_creds
      "GIT_ROOT"                                    = var.baxos_src_git_root
      "GIT_PROJECT_SUFIX"                           = var.baxos_src_git_project_suffix
      "BUILD_SCRIPT"                                = "/build/retro/projects/loader/build_from_container.sh"
    }

    volume {
      name                 = "sharevolume1"
      mount_path           = "/output" # Since build script writes to /output/...
      read_only            = false
      share_name           = azurerm_storage_share.share.name
      storage_account_name = azurerm_storage_account.storage.name
      storage_account_key  = azurerm_storage_account.storage.primary_access_key
    }
  }

  container {
    name   = "${var.project}-build-cpc-sf3"
    image  = "${azurerm_container_registry.acr.login_server}/cpctelera-build-cpc:latest"
    cpu    = "4.0"
    memory = "8"

    environment_variables = {
      "IS_STARTED_FROM_BAXOS_BUILD_CONTAINER"       = "YES"
      "FOLDER_ROOT"                                 = "/build/retro/projects"
      "ARG_PLATFORM"                                = "CPC"
      "ARG_COMPRESSION"                             = "NONE"
      "ARG_SF3_OR_RSF3"                             = "SF3"
      "GIT_ROOT_CREDS"                              = var.baxos_src_git_root_creds
      "GIT_ROOT"                                    = var.baxos_src_git_root
      "GIT_PROJECT_SUFIX"                           = var.baxos_src_git_project_suffix
      "BUILD_SCRIPT"                                = "/build/retro/projects/loader/build_from_container.sh"
    }

    volume {
      name                 = "sharevolume2"
      mount_path           = "/output" # Since build script writes to /output/...
      read_only            = false
      share_name           = azurerm_storage_share.share.name
      storage_account_name = azurerm_storage_account.storage.name
      storage_account_key  = azurerm_storage_account.storage.primary_access_key
    }
  }

  image_registry_credential {
    server   = azurerm_container_registry.acr.login_server
    username = azurerm_container_registry.acr.admin_username
    password = azurerm_container_registry.acr.admin_password
  }  
}

# # Outputs
# output "storage_account_name" {
#   value = azurerm_storage_account.storage.name
# }

# output "file_share_url" {
#   value = azurerm_storage_share.share.url
# }

# # Output the Managed Identity ID
# output "managed_identity_id" {
#   value = azurerm_user_assigned_identity.sa_identity.id
# }
