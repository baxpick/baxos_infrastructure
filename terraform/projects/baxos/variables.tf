# set from .tfvars file
# #####################

# set from .tfvars file
variable "location" {
  description = "location"
  type = string
}

# set from .tfvars file
variable "aws_default_region" {
  description = "default region for AWS"
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

# set from environment using TF_VAR_... syntax
# ############################################

# REMARK: this secret variable can also be set in codespaces secrets so it must be uppercase
variable "BAXOS_SRC_PROJECT_GIT_REPO" {
  description = "baxos source git repo with credentials"
  type        = string
  sensitive   = true
  nullable    = false
}
