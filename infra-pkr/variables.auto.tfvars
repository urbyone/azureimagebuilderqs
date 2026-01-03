resource_group_name   = "rg-packerbuild-ado"
location              = "uksouth"
managed_identity_name = "uami-packerbuild-ado"
gallery_name          = "sigpackerimages" # Must be alphanumeric
image_definition_name = "windows-server-2022-custom"
vm_profile = {
  vmSize       = "Standard_D2s_v3"
  osDiskSizeGB = 127
}
source_image = {
  publisher = "MicrosoftWindowsServer"
  offer     = "WindowsServer"
  sku       = "2022-datacenter-azure-edition"
}