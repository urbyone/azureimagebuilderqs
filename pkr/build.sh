#!/bin/bash
set -e

echo "========================================="
echo "Packer Image Build Automation Script"
echo "========================================="
echo ""

# Check if running from pkr directory
if [ ! -f "windows-2022.pkr.hcl" ]; then
    echo "Error: Please run this script from the /pkr directory"
    exit 1
fi

# Step 1: Check if Terraform has been applied
echo "Step 1: Checking Terraform infrastructure..."
if [ ! -d "../infra-pkr/.terraform" ]; then
    echo "Error: Terraform not initialized. Please run:"
    echo "  cd ../infra-pkr && terraform init && terraform apply"
    exit 1
fi

# Step 2: Get Terraform outputs
echo "Step 2: Retrieving Terraform outputs..."
cd ../infra-pkr

SUBSCRIPTION_ID=$(terraform output -raw subscription_id 2>/dev/null || echo "")
RESOURCE_GROUP=$(terraform output -raw resource_group_name 2>/dev/null || echo "")
LOCATION=$(terraform output -raw location 2>/dev/null || echo "")
MANAGED_IDENTITY_CLIENT_ID=$(terraform output -raw managed_identity_client_id 2>/dev/null || echo "")
MANAGED_IDENTITY_ID=$(terraform output -raw managed_identity_id 2>/dev/null || echo "")
GALLERY_NAME=$(terraform output -raw gallery_name 2>/dev/null || echo "")
IMAGE_DEFINITION=$(terraform output -raw image_definition_name 2>/dev/null || echo "")
SOURCE_IMAGE_PUBLISHER=$(terraform output -raw source_image_publisher 2>/dev/null || echo "")
SOURCE_IMAGE_OFFER=$(terraform output -raw source_image_offer 2>/dev/null || echo "")
SOURCE_IMAGE_SKU=$(terraform output -raw source_image_sku 2>/dev/null || echo "")

if [ -z "$SUBSCRIPTION_ID" ] || [ -z "$RESOURCE_GROUP" ]; then
    echo "Error: Could not retrieve Terraform outputs. Has 'terraform apply' been run?"
    exit 1
fi

echo "  Subscription ID: $SUBSCRIPTION_ID"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Gallery Name: $GALLERY_NAME"
echo "  Image Definition: $IMAGE_DEFINITION"
echo ""

cd ../pkr

# Step 3: Convert location to display name format for replication regions
echo "Step 3: Converting location to display name format..."
case "$LOCATION" in
  "uksouth") REPLICATION_REGION="UK South" ;;
  "ukwest") REPLICATION_REGION="UK West" ;;
  "eastus") REPLICATION_REGION="East US" ;;
  "eastus2") REPLICATION_REGION="East US 2" ;;
  "westus") REPLICATION_REGION="West US" ;;
  "westus2") REPLICATION_REGION="West US 2" ;;
  "centralus") REPLICATION_REGION="Central US" ;;
  "northeurope") REPLICATION_REGION="North Europe" ;;
  "westeurope") REPLICATION_REGION="West Europe" ;;
  *) REPLICATION_REGION="UK South" ;;  # Default fallback
esac

echo "  Location: $LOCATION -> Replication Region: $REPLICATION_REGION"
echo ""

# Step 4: Set Packer environment variables
echo "Step 4: Setting Packer environment variables..."
export PKR_VAR_subscription_id="$SUBSCRIPTION_ID"
export PKR_VAR_resource_group_name="$RESOURCE_GROUP"
export PKR_VAR_location="$LOCATION"
export PKR_VAR_replication_region="$REPLICATION_REGION"
export PKR_VAR_managed_identity_client_id="$MANAGED_IDENTITY_CLIENT_ID"
export PKR_VAR_managed_identity_id="$MANAGED_IDENTITY_ID"
export PKR_VAR_gallery_name="$GALLERY_NAME"
export PKR_VAR_image_definition_name="$IMAGE_DEFINITION"
export PKR_VAR_source_image_publisher="$SOURCE_IMAGE_PUBLISHER"
export PKR_VAR_source_image_offer="$SOURCE_IMAGE_OFFER"
export PKR_VAR_source_image_sku="$SOURCE_IMAGE_SKU"
export PKR_VAR_image_version="1.0.0"
export PKR_VAR_vm_size="Standard_D2s_v3"
export PKR_VAR_os_disk_size_gb=127

echo "  Environment variables set successfully"
echo ""

# Step 5: Initialize Packer
echo "Step 5: Initializing Packer..."
packer init windows-2022.pkr.hcl
echo ""

# Step 6: Validate configuration
echo "Step 6: Validating Packer configuration..."
packer validate windows-2022.pkr.hcl
echo ""

# Step 7: Build image (optional - ask user)
read -p "Do you want to build the image now? This may take 30-60 minutes (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Step 7: Building image..."
    packer build windows-2022.pkr.hcl
    echo ""
    echo "========================================="
    echo "Image build completed successfully!"
    echo "========================================="
else
    echo ""
    echo "Skipping build. To build manually, run:"
    echo "  packer build windows-2022.pkr.hcl"
fi
