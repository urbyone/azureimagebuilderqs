# Generate the helloImageTemplateWin.json file with dynamic values
resource "local_file" "image_template_json" {
  filename = "${path.module}/${var.image_template_json_filename}"
  content = jsonencode({
    type       = "Microsoft.VirtualMachineImages/imageTemplates"
    apiVersion = "2022-02-14"
    location   = azurerm_resource_group.main.location
    dependsOn  = []
    tags = {
      imagebuilderTemplate = "windows2022"
      userIdentity         = "enabled"
    }
    identity = {
      type = "UserAssigned"
      userAssignedIdentities = {
        "${azurerm_user_assigned_identity.main.id}" = {}
      }
    }
    properties = {
      buildTimeoutInMinutes = 100
      vmProfile = {
        vmSize       = var.vm_profile.vmSize
        osDiskSizeGB = var.vm_profile.osDiskSizeGB
      }
      source = {
        type      = "PlatformImage"
        publisher = var.source_image.publisher
        offer     = var.source_image.offer
        sku       = var.source_image.sku
        version   = "latest"
      }
      customize = [
        {
          type        = "PowerShell"
          name        = "CreateBuildPath"
          runElevated = false
          scriptUri   = "https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/testPsScript.ps1"
        },
        {
          type                = "WindowsRestart"
          restartCheckCommand = "echo Azure-Image-Builder-Restarted-the-VM  > c:\\buildArtifacts\\azureImageBuilderRestart.txt"
          restartTimeout      = "5m"
        },
        {
          type        = "File"
          name        = "downloadBuildArtifacts"
          sourceUri   = "https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/quickquickstarts/exampleArtifacts/buildArtifacts/index.html"
          destination = "c:\\buildArtifacts\\index.html"
        },
        {
          type        = "PowerShell"
          name        = "settingUpMgmtAgtPath"
          runElevated = false
          inline = [
            "mkdir c:\\buildActions",
            "echo Azure-Image-Builder-Was-Here  > c:\\buildActions\\buildActionsOutput.txt"
          ]
        },
        {
          type           = "WindowsUpdate"
          searchCriteria = "IsInstalled=0"
          filters = [
            "exclude:$_.Title -like '*Preview*'",
            "include:$true"
          ]
          updateLimit = 20
        }
      ]
      distribute = [
        {
          type          = "ManagedImage"
          imageId       = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_resource_group.main.name}/providers/Microsoft.Compute/images/${var.output_image_name}"
          location      = azurerm_resource_group.main.location
          runOutputName = var.run_output_name
          artifactTags = {
            source    = "azVmImageBuilder"
            baseosimg = "windows2022"
          }
        }
      ]
    }
  })
}
