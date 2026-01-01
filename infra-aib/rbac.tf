# Generate a unique suffix for the role name
resource "random_id" "role_suffix" {
  byte_length = 4
}

# Custom Role Definition for Azure Image Builder
resource "azurerm_role_definition" "aib_image_creation" {
  name        = "Azure Image Builder Service Image Creation Role-${random_id.role_suffix.hex}"
  scope       = azurerm_resource_group.main.id
  description = "Image Builder access to create resources for the image build"

  permissions {
    actions = [
      "Microsoft.Compute/galleries/read",
      "Microsoft.Compute/galleries/images/read",
      "Microsoft.Compute/galleries/images/versions/read",
      "Microsoft.Compute/galleries/images/versions/write",
      "Microsoft.Compute/images/write",
      "Microsoft.Compute/images/read",
      "Microsoft.Compute/images/delete"
    ]
    not_actions = []
  }

  assignable_scopes = [
    azurerm_resource_group.main.id
  ]

  depends_on = [azurerm_resource_group.main]
}

# Role Assignment - Assign custom role to managed identity on resource group
resource "azurerm_role_assignment" "aib_image_creation" {
  scope              = azurerm_resource_group.main.id
  role_definition_id = azurerm_role_definition.aib_image_creation.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.main.principal_id
  depends_on         = [azurerm_role_definition.aib_image_creation, azurerm_user_assigned_identity.main, azurerm_resource_group.main]
}