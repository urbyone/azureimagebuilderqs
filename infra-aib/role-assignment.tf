# Generate the aibRoleImageCreation.json file
resource "local_file" "aib_role_json" {
  filename = "${path.module}/aibRoleImageCreation.json"
  content = jsonencode({
    Name        = "Azure Image Builder Service Image Creation Role"
    IsCustom    = true
    Description = "Image Builder access to create resources for the image build, you should delete or split out as appropriate"
    Actions = [
      "Microsoft.Compute/galleries/read",
      "Microsoft.Compute/galleries/images/read",
      "Microsoft.Compute/galleries/images/versions/read",
      "Microsoft.Compute/galleries/images/versions/write",
      "Microsoft.Compute/images/write",
      "Microsoft.Compute/images/read",
      "Microsoft.Compute/images/delete"
    ]
    NotActions = []
    AssignableScopes = [
      "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_resource_group.main.name}"
    ]
  })
}