# Packer Build Script for Windows Server 2022

This directory contains Packer configuration to build a custom Windows Server 2022 image and store it in an Azure Compute Gallery.

## Prerequisites

1. Azure CLI installed and authenticated
2. Packer installed (v1.8.0 or later)
3. Terraform infrastructure deployed (from ../infra-pkr)

## Configuration Files

- `windows-2022.pkr.hcl` - Main Packer template
- `variables.pkrvars.hcl` - Variable definitions

## Build Steps

### 1. Deploy Infrastructure First

```bash
cd ../infra-pkr
terraform init
terraform plan
terraform apply
```

Note the outputs:
- subscription_id
- resource_group_name
- managed_identity_client_id
- gallery_name
- image_definition_name

### 2. Update Packer Variables

Edit `variables.pkrvars.hcl` and fill in the values from Terraform outputs.

### 3. Initialize Packer

```bash
cd ../pkr
packer init windows-2022.pkr.hcl
```

### 4. Validate Configuration

```bash
packer validate -var-file=variables.pkrvars.hcl windows-2022.pkr.hcl
```

### 5. Build Image

```bash
packer build -var-file=variables.pkrvars.hcl windows-2022.pkr.hcl
```

## What the Packer Template Does

This template replicates the AIB template functionality:

1. **Base Image**: Windows Server 2022 Datacenter Azure Edition
2. **Customizations**:
   - Creates build artifacts directory
   - Runs PowerShell test script
   - Performs Windows restart
   - Downloads index.html artifact
   - Creates build actions directory with marker file
   - Applies Windows Updates (excluding previews, limit 20)
   - Runs Sysprep to generalize the image
3. **Output**: Stores image in Azure Compute Gallery

## Customization

To add custom provisioning steps, add provisioner blocks in the build section of `windows-2022.pkr.hcl`.

### Example: Add software installation

```hcl
provisioner "powershell" {
  inline = [
    "choco install -y googlechrome",
    "choco install -y 7zip"
  ]
}
```

## Environment Variables (Alternative to variables file)

```bash
export PKR_VAR_subscription_id="your-subscription-id"
export PKR_VAR_managed_identity_client_id="your-client-id"
packer build windows-2022.pkr.hcl
```

## Troubleshooting

- **WinRM Timeout**: Increase `winrm_timeout` in source block
- **Sysprep Issues**: Check Windows event logs in Azure portal
- **Permission Errors**: Verify managed identity has Contributor role on resource group
