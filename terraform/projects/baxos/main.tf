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
  https_traffic_only_enabled      = false
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

# Upload static files from files/ludic to the share
locals {
  static_files = fileset("${path.module}/files/ludic", "**")
}

resource "azurerm_storage_share_file" "static_files" {
  for_each = local.static_files
  
  name             = each.value
  storage_share_id = "https://${azurerm_storage_account.storage.name}.file.core.windows.net/${azurerm_storage_share.share.name}"
  source           = "${path.module}/files/ludic/${each.value}"
  content_md5      = filemd5("${path.module}/files/ludic/${each.value}")
}

# Containers
# ##########

resource "azurerm_container_registry" "acr" {
  name                = "${local.acr_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = true
}

# Serverless build orchestration with Container Apps Job
resource "azurerm_container_app_environment" "build_env" {
  name                = "env-${var.project}-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_container_app_environment_storage" "build" {
  name                         = "build"
  container_app_environment_id = azurerm_container_app_environment.build_env.id
  account_name                 = azurerm_storage_account.storage.name
  share_name                   = azurerm_storage_share.share.name
  access_key                   = azurerm_storage_account.storage.primary_access_key
  access_mode                  = "ReadWrite"
}

data "external" "cpc_image_ready" {
  program = ["bash", "-c", <<-EOT
    #!/usr/bin/env bash
    set -euo pipefail

    ACR_NAME="${local.acr_name}"
    REPO1="cpctelera-build-cpc"
    REPO2="cpctelera-build-enterprise"

    has_latest() {
      az acr repository show-tags \
        --name "$ACR_NAME" \
        --repository "$1" \
        --query "contains(@, 'latest')" -o tsv \
      | grep -q true
    }

    if has_latest "$REPO1" && has_latest "$REPO2"; then
      echo '{"exists":"true"}'
    else
      echo '{"exists":"false"}'
    fi
  EOT
  ]
}

locals {
  acr_name                    = "acr${var.project}${var.environment}"
  jobs_enabled                = try(data.external.cpc_image_ready.result.exists, false)
  enabled_build_containers    = local.jobs_enabled ? local.build_containers : {}
}

resource "azurerm_container_app_job" "build_jobs" {
  for_each                     = local.enabled_build_containers

  name                         = "build-${each.value.platform}-${each.value.card}-${var.environment}"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.build_env.id

  replica_timeout_in_seconds = 600
  replica_retry_limit        = 0
  manual_trigger_config {
    parallelism              = 1
    replica_completion_count = 1
  }

  secret {
    name  = "acr-password"
    value = azurerm_container_registry.acr.admin_password
  }

  registry {
    server = azurerm_container_registry.acr.login_server
    username = azurerm_container_registry.acr.admin_username
    password_secret_name = "acr-password"
  }

  template {

    container {
      image   = "${azurerm_container_registry.acr.login_server}/cpctelera-build-${each.value.platform}:latest"
      name    = "build"
      cpu     = tonumber(local.build_container_defaults.cpu)
      memory  = "${local.build_container_defaults.memory}Gi"

      volume_mounts {
        name  = "shared-volume"
        path  = "/output"
      }

      # env vars (container specific)
      env {
        name  = "ARG_SF3_OR_RSF3"
        value = each.value.card
      }
      env {
        name  = "ARG_PLATFORM"
        value = each.value.platform
      }

      # env vars (common)
      dynamic "env" {
        for_each = local.build_container_defaults.common_env_vars
        content {
          name  = env.key
          value = env.value
        }
      }
    }

    volume {
      name         = "shared-volume"
      storage_name = azurerm_container_app_environment_storage.build.name
      storage_type = "AzureFile"
      mount_options = "dir_mode=0777,file_mode=0777"
    }    
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

# Invoke AWS script to update Route53 nameservers from Azure DNS Zone
resource "null_resource" "update_aws_ns" {
  provisioner "local-exec" {
    interpreter = ["bash","-c"]

    command = <<-EOF
      source "${path.cwd}/../../../bash/aws.sh"
      aws_update_nameservers_from_azure_dns_zone \
        --domainName "${azurerm_dns_zone.dns_zone.name}" \
        --awsRegion "${var.aws_default_region}" \
        --azureDnsZoneRg "${azurerm_resource_group.rg.name}" \
        --waitForUpdate YES
    EOF
  }

  triggers = { always_run = timestamp() }
}

# Create DNS A record pointing to the web server FQDN
resource "azurerm_dns_cname_record" "web_server" {
  name                = "${var.project}"
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
  record              = azurerm_container_group.web_server.fqdn
}
