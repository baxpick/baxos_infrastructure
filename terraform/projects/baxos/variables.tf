# Configuration variables set from .tfvars files
# ################################################

variable "location" {
  description = "The Azure region where all resources will be stored"
  type        = string
}

variable "location_backend" {
  description = "The Azure region where backend state file will be stored"
  type        = string
}

variable "aws_default_region" {
  description = "Default AWS region for any AWS resources"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.aws_default_region))
    error_message = "AWS region must be a valid region identifier."
  }
}

variable "project" {
  description = "Project name used for resource naming and tagging"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9]*$", var.project))
    error_message = "Project name must start with a letter and contain only lowercase letters and numbers."
  }
}

variable "rg_all" {
  description = "Name of the main resource group containing all project resources"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]+$", var.rg_all))
    error_message = "Resource group name must contain only alphanumeric characters, periods, underscores, and hyphens."
  }
}

# Runtime variables set from command line
# ########################################

variable "environment" {
  description = "Deployment environment (dev, prod)"
  type        = string
  validation {
    condition     = var.environment == "dev" || var.environment == "prod"
    error_message = "Environment must be exactly 'dev' or 'prod'."
  }
}

variable "action" {
  description = "Action to perform with OpenTofu (resourcesCreate, resourcesDelete, etc.)"
  type        = string
  validation {
    condition     = var.action == "resourcesCreate" || var.action == "resourcesDelete"
    error_message = "Action must be exactly 'resourcesCreate' or 'resourcesDelete'."
  }
}

variable "my_ip" {
  description = "Your machine IP address (e.g., 192.168.1.100)"
  type        = string
  validation {
    condition     = can(regex("^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", var.my_ip))
    error_message = "IP must be a valid IPv4 address (e.g., 192.168.1.100)."
  }
}

# set from environment using TF_VAR_... syntax
# ############################################

# REMARK: this secret variable can also be set in codespaces secrets so it must be uppercase
variable "BAXOS_SRC_PROJECT_GIT_REPO" {
  description = "baxos source git repo with credentials"
  type        = string
  sensitive   = true
  nullable    = false
}
