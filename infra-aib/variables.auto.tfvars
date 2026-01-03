resource_group_name   = "rg-imagebuilder-ghub"
location              = "uksouth"
managed_identity_name = "uami-imagebuilder-ghub"
vm_profile = {
  vmSize       = "Standard_D2s_v3"
  osDiskSizeGB = 127
}
source_image = {
  publisher = "MicrosoftWindowsServer"
  offer     = "WindowsServer"
  sku       = "2022-datacenter-azure-edition"
}