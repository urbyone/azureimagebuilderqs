output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.main.id
}

output "managed_identity_id" {
  description = "ID of the user assigned managed identity"
  value       = azurerm_user_assigned_identity.main.id
}

output "managed_identity_principal_id" {
  description = "Principal ID of the managed identity"
  value       = azurerm_user_assigned_identity.main.principal_id
}

output "managed_identity_client_id" {
  description = "Client ID of the managed identity"
  value       = azurerm_user_assigned_identity.main.client_id
}

output "image_template_resource_name" {
  description = "Name of the Azure Image Builder template resource"
  value       = var.image_template_resource_name
}

output "image_template_json_filename" {
  description = "Filename of the generated image template JSON"
  value       = var.image_template_json_filename
}

output "output_image_name" {
  description = "Name of the output managed image"
  value       = var.output_image_name
}
