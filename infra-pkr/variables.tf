variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string

}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "uksouth"
}

variable "managed_identity_name" {
  description = "Name of the user assigned managed identity"
  type        = string

}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Dev"
    ManagedBy   = "Terraform"
  }
}

variable "image_template_name" {
  description = "Name for the image template"
  type        = string
  default     = "win2022ImageTemplate"
}

variable "image_template_resource_name" {
  description = "Name for the Azure Image Builder resource"
  type        = string
  default     = "ImageTemplateWin01"
}

variable "image_template_json_filename" {
  description = "Filename for the image template JSON file"
  type        = string
  default     = "ImageTemplateWin.json"
}

variable "output_image_name" {
  description = "Name for the output managed image"
  type        = string
  default     = "win2022-custom"
}

variable "run_output_name" {
  description = "Name for the image builder run output"
  type        = string
  default     = "win2022-runOutput"
}

variable "source_image" {
  description = "Source image configuration for the image builder"
  type = object({
    publisher = string
    offer     = string
    sku       = string
  })
  default = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
  }
}

variable "vm_profile" {
  description = "VM profile configuration for the image builder"
  type = object({
    vmSize       = string
    osDiskSizeGB = number
  })
  default = {
    vmSize       = "Standard_D2s_v3"
    osDiskSizeGB = 127
  }
}

variable "gallery_name" {
  description = "Name of the Azure Compute Gallery"
  type        = string
  default     = "acg_packer_images"
}

variable "image_definition_name" {
  description = "Name of the image definition in the gallery"
  type        = string
  default     = "windows-server-2022-custom"
}

variable "storage_account_name" {
  description = "Name of the storage account for Packer artifacts"
  type        = string
  default     = "stpackerartifacts"
}
