# Web server information
output "web_server_info" {
  value       = "The container group 'server-containers-${var.project}-${var.environment}' is hosted in ${azurerm_container_group.web_server.location} and is accessible at http://${azurerm_container_group.web_server.fqdn}"
  description = "Information about where the server container group is hosted"
}
