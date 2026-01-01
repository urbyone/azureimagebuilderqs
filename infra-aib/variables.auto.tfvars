resource_group_name   = "rg-imagebuilder"
location              = "uksouth"
managed_identity_name = "uami-imagebuilder"
vm_profile = {
  vmSize       = "Standard_D2s_v3"
  osDiskSizeGB = 127
}
source_image = {
  publisher = "MicrosoftWindowsServer"
  offer     = "WindowsServer"
  sku       = "2022-datacenter-azure-edition"
}