# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# User Assigned Managed Identity for Packer
resource "azurerm_user_assigned_identity" "packer" {
  name                = var.managed_identity_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = var.tags
}

# Azure Compute Gallery (formerly Shared Image Gallery)
resource "azurerm_shared_image_gallery" "main" {
  name                = var.gallery_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  description         = "Shared image gallery for custom Windows images"
  tags                = var.tags
}

# Shared Image Definition for Windows Server 2022
resource "azurerm_shared_image" "windows_2022" {
  name                = var.image_definition_name
  gallery_name        = azurerm_shared_image_gallery.main.name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Windows"
  hyper_v_generation  = "V2"

  identifier {
    publisher = var.source_image.publisher
    offer     = var.source_image.offer
    sku       = var.source_image.sku
  }

  tags = merge(var.tags, {
    ImageType = "CustomWindows2022"
  })
}

# Role Assignment - Contributor on Resource Group for Packer Identity
resource "azurerm_role_assignment" "packer_contributor" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.packer.principal_id
}

# Random string for storage account name (24 characters, lowercase alphanumeric only)
resource "random_string" "storage_account" {
  length  = 24
  special = false
  upper   = false
  numeric = true
  lower   = true
}

# Optional: Create a storage account for Packer artifacts
resource "azurerm_storage_account" "packer" {
  name                     = random_string.storage_account.result
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

resource "azurerm_storage_container" "packer_artifacts" {
  name                  = "packer-artifacts"
  storage_account_name  = azurerm_storage_account.packer.name
  container_access_type = "private"
}