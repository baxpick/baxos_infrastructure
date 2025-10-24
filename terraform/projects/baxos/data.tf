# Shared Resources
# ################

# DNS Zone (shared across all projects)
data "azurerm_dns_zone" "dns_zone" {
  name                = var.shared_dns_zone_name
  resource_group_name = var.shared_rg
}
