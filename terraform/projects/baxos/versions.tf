terraform {
  backend "azurerm" {}
  required_version = "1.11.4"
  required_providers {
    azuread = {
      version = "3.3.0"
    }
    azurerm = {
      version = "4.27.0"
    }  
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }    
  }
  # if you disable shared_access_key_enabled for storage accounts => use AD for authentication
  #storage_use_azuread = true
}

provider "azuread" {
}

provider "null" {
}
