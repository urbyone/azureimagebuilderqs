output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "location" {
  description = "Azure region location"
  value       = azurerm_resource_group.main.location
}

output "managed_identity_id" {
  description = "ID of the managed identity for Packer"
  value       = azurerm_user_assigned_identity.packer.id
}

output "managed_identity_client_id" {
  description = "Client ID of the managed identity"
  value       = azurerm_user_assigned_identity.packer.client_id
}

output "gallery_name" {
  description = "Name of the Azure Compute Gallery"
  value       = azurerm_shared_image_gallery.main.name
}

output "image_definition_name" {
  description = "Name of the image definition"
  value       = azurerm_shared_image.windows_2022.name
}

output "subscription_id" {
  description = "Azure subscription ID"
  value       = data.azurerm_client_config.current.subscription_id
}

output "source_image_publisher" {
  description = "Source image publisher"
  value       = var.source_image.publisher
}

output "source_image_offer" {
  description = "Source image offer"
  value       = var.source_image.offer
}

output "source_image_sku" {
  description = "Source image SKU"
  value       = var.source_image.sku
}
