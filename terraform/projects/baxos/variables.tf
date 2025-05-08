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
