resource_group_name   = "rg-imagebuilder-cu"
location              = "uksouth"
managed_identity_name = "uami-imagebuilder-cu"
vm_profile = {
  vmSize       = "Standard_D2s_v3"
  osDiskSizeGB = 127
}
source_image = {
  publisher = "MicrosoftWindowsServer"
  offer     = "WindowsServer"
  sku       = "2022-datacenter-azure-edition"
}