resource_group_name   = "rg-packerbuild-ghub"
location              = "uksouth"
managed_identity_name = "uami-packerbuild-ghub"
gallery_name          = "sigpackerimagesghub01" # Must be alphanumeric
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