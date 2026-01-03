packer {
  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = "~> 2.0"
    }
    windows-update = {
      source  = "github.com/rgl/windows-update"
      version = "~> 0.14"
    }
  }
}

# Variables
variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name where the image will be stored"
}

variable "location" {
  type        = string
  default     = "uksouth"
  description = "Azure region"
}

variable "replication_region" {
  type        = string
  default     = "UK South"
  description = "Azure region display name for gallery image replication"
}

variable "managed_identity_client_id" {
  type        = string
  description = "Client ID of the user assigned managed identity"
}

variable "managed_identity_id" {
  type        = string
  description = "Full resource ID of the user assigned managed identity"
}

variable "gallery_name" {
  type        = string
  description = "Azure Compute Gallery name"
}

variable "image_definition_name" {
  type        = string
  description = "Image definition name in the gallery"
}

variable "image_version" {
  type        = string
  default     = "1.0.0"
  description = "Version number for the image"
}

variable "vm_size" {
  type        = string
  default     = "Standard_D2s_v3"
  description = "VM size for the build VM"
}

variable "os_disk_size_gb" {
  type        = number
  default     = 127
  description = "OS disk size in GB"
}

variable "source_image_publisher" {
  type        = string
  default     = "MicrosoftWindowsServer"
  description = "Source image publisher"
}

variable "source_image_offer" {
  type        = string
  default     = "WindowsServer"
  description = "Source image offer"
}

variable "source_image_sku" {
  type        = string
  default     = "2022-datacenter-azure-edition"
  description = "Source image SKU"
}

# Source block - defines the base image
source "azure-arm" "windows_2022" {
  # Authentication using managed identity
  use_azure_cli_auth = true

  # Subscription and resource group
  subscription_id = var.subscription_id

  # Managed identity for authentication
  user_assigned_managed_identities = [var.managed_identity_id]

  # Build VM configuration
  build_resource_group_name = var.resource_group_name
  vm_size                   = var.vm_size
  os_disk_size_gb           = var.os_disk_size_gb
  os_type                   = "Windows"

  # Source image
  image_publisher = var.source_image_publisher
  image_offer     = var.source_image_offer
  image_sku       = var.source_image_sku
  image_version   = "latest"

  # Output to Azure Compute Gallery
  shared_image_gallery_destination {
    subscription         = var.subscription_id
    resource_group       = var.resource_group_name
    gallery_name         = var.gallery_name
    image_name           = var.image_definition_name
    image_version        = var.image_version
    replication_regions  = [var.replication_region]
    storage_account_type = "Standard_LRS"
  }

  # Communicator configuration
  communicator   = "winrm"
  winrm_use_ssl  = true
  winrm_insecure = true
  winrm_timeout  = "5m"
  winrm_username = "packer"

  # Tags
  azure_tags = {
    source      = "packer"
    base_image  = "windows2022"
    environment = "dev"
  }
}

# Build block - defines the customization steps
build {
  sources = ["source.azure-arm.windows_2022"]

  # Step 1: Create build path
  provisioner "powershell" {
    inline = [
      "Write-Host 'Creating build artifacts directory'",
      "New-Item -Path C:\\buildArtifacts -ItemType Directory -Force",
      "Write-Host 'Build path created successfully'"
    ]
  }

  # Step 2: Windows restart
  provisioner "windows-restart" {
    restart_check_command = "powershell -command \"& {Write-Output 'Azure-Image-Builder-Restarted-the-VM' | Out-File -FilePath C:\\buildArtifacts\\azureImageBuilderRestart.txt}\""
    restart_timeout       = "5m"
  }

  # Step 3: Download build artifacts file
  provisioner "powershell" {
    inline = [
      "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/quickquickstarts/exampleArtifacts/buildArtifacts/index.html' -OutFile 'C:\\buildArtifacts\\index.html'"
    ]
  }

  # Step 4: Setup management agent path
  provisioner "powershell" {
    inline = [
      "New-Item -Path C:\\buildActions -ItemType Directory -Force",
      "Write-Output 'Azure-Image-Builder-Was-Here' | Out-File -FilePath C:\\buildActions\\buildActionsOutput.txt"
    ]
  }

  # Step 5: Windows Update
  provisioner "windows-update" {
    search_criteria = "IsInstalled=0"
    filters = [
      "exclude:$_.Title -like '*Preview*'",
      "include:$true"
    ]
    update_limit = 20
  }

  # Step 6: Generalize the VM (Sysprep)
  provisioner "powershell" {
    inline = [
      "Write-Host 'Running Sysprep to generalize the image'",
      "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit",
      "while($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; Start-Sleep -s 10 } else { break } }"
    ]
  }
}
