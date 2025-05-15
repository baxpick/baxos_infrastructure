# set from .tfvars file
# #####################

# set from .tfvars file
variable "location" {
  description = "location"
  type = string
}

# set from .tfvars file
variable "project" {
  description = "project"
  type = string
}

# set from .tfvars file
variable "rg_all" {
  description = "resource group for all resources"
  type = string
}

# set from command line using "-var"
# ##################################

# set from command line using "-var"
variable "environment" {
  description = "environment"
  type = string
}

# set from command line using "-var"
variable "action" {
  description = "Action to perform with terraform"
}

# set from command line using "-var"
# REMARK: this secret variable can also be set in codespaces secrets so it must be uppercase
variable "BAXOS_SRC_GIT_ROOT_CREDS" {
  description = "baxos source git root with credentials"
  type        = string
  sensitive   = true
  nullable    = false
}

# set from command line using "-var"
# REMARK: this secret variable can also be set in codespaces secrets so it must be uppercase
variable "BAXOS_SRC_GIT_ROOT" {
  description = "baxos source git root"
  type        = string
  sensitive   = true
  nullable    = false
}
# set from command line using "-var"
# REMARK: this secret variable can also be set in codespaces secrets so it must be uppercase
variable "BAXOS_SRC_GIT_PROJECT_SUFFIX" {
  description = "baxos source git project suffix"
  type        = string
  sensitive   = true
  nullable    = false
}
