#!/bin/bash

# Cleanup script for Azure resources created by setup.sh
# This script removes the Terraform resource group, storage account, and service principal

set -e

#########################################
# Check if required environment variables are set
#########################################
echo "Checking for required environment variables..."
echo ""

MISSING_VARS=false

if [ -z "$TF_RESOURCE_GROUP" ]; then
    echo "ERROR: TF_RESOURCE_GROUP is not set"
    MISSING_VARS=true
fi

if [ -z "$TF_STORAGE_ACCOUNT" ]; then
    echo "ERROR: TF_STORAGE_ACCOUNT is not set"
    MISSING_VARS=true
fi

if [ -z "$SP_APP_ID" ]; then
    echo "ERROR: SP_APP_ID is not set"
    MISSING_VARS=true
fi

if [ -z "$ARM_SUBSCRIPTION_ID" ]; then
    echo "ERROR: ARM_SUBSCRIPTION_ID is not set"
    MISSING_VARS=true
fi

if [ "$MISSING_VARS" = true ]; then
    echo ""
    echo "Missing required environment variables."
    echo "Please run 'source .github/scripts/setup.sh' first to set up the environment."
    exit 1
fi

#########################################
# Read Image Builder Resource Group from tfvars
#########################################
TFVARS_FILE="infra-aib/variables.auto.tfvars"
IMAGE_RESOURCE_GROUP=""

if [ -f "$TFVARS_FILE" ]; then
    IMAGE_RESOURCE_GROUP=$(grep 'resource_group_name' "$TFVARS_FILE" | awk -F '"' '{print $2}')
    echo "Found Image Builder resource group in tfvars: $IMAGE_RESOURCE_GROUP"
else
    echo "Warning: Could not find $TFVARS_FILE"
fi

#########################################
# Display what will be deleted
#########################################
echo "=========================================="
echo "CLEANUP SUMMARY"
echo "=========================================="
echo "The following resources will be deleted:"
echo ""
echo "1. Resource Group: $TF_RESOURCE_GROUP"
echo "   - This will also delete the storage account: $TF_STORAGE_ACCOUNT"
echo "   - And the container: $TF_CONTAINER_NAME"
echo ""
echo "2. Service Principal App ID: $SP_APP_ID"
if [ -n "$SP_NAME" ]; then
    echo "   Name: $SP_NAME"
fi
echo "   - All role assignments will be removed"
echo ""
echo "Subscription: $ARM_SUBSCRIPTION_ID"
echo "=========================================="
echo ""

#########################################
# Request confirmation
#########################################
read -p "Are you sure you want to delete these resources? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
read -p "Type 'DELETE' to confirm deletion: " CONFIRM2

if [ "$CONFIRM2" != "DELETE" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""

#########################################
# Ask about Image Builder Resource Group
#########################################
DELETE_IMAGE_RG=false

if [ -n "$IMAGE_RESOURCE_GROUP" ]; then
    echo "=========================================="
    echo "IMAGE BUILDER RESOURCE GROUP"
    echo "=========================================="
    echo "An Image Builder resource group was found in tfvars:"
    echo "  Resource Group: $IMAGE_RESOURCE_GROUP"
    echo ""
    echo "This resource group contains the Image Builder resources"
    echo "created by Terraform (managed identity, image templates, etc.)"
    echo ""
    read -p "Do you also want to delete this resource group? (yes/no): " DELETE_IMAGE_RG_CONFIRM
    echo ""
    
    if [ "$DELETE_IMAGE_RG_CONFIRM" = "yes" ]; then
        DELETE_IMAGE_RG=true
        echo "✓ Image Builder resource group will be deleted"
    else
        echo "Image Builder resource group will NOT be deleted"
    fi
    echo ""
fi

echo "Starting cleanup process..."
echo ""

#########################################
# Delete Role Assignments
#########################################
echo "Step 1: Removing role assignments for service principal..."
echo "----------------------------------------"

# Get all role assignments for the service principal
ROLE_ASSIGNMENTS=$(az role assignment list --assignee $SP_APP_ID --query "[].id" -o tsv 2>/dev/null || true)

if [ -n "$ROLE_ASSIGNMENTS" ]; then
    echo "Found role assignments to delete:"
    for ASSIGNMENT_ID in $ROLE_ASSIGNMENTS; do
        echo "  - Deleting: $ASSIGNMENT_ID"
        az role assignment delete --ids "$ASSIGNMENT_ID"
    done
    echo "✓ Role assignments removed successfully"
else
    echo "No role assignments found for service principal"
fi

echo ""

#########################################
# Delete Service Principal
#########################################
echo "Step 2: Deleting service principal..."
echo "----------------------------------------"

# Get the app object ID using the app ID
APP_OBJECT_ID=$(az ad app show --id "$SP_APP_ID" --query id -o tsv 2>/dev/null || true)

if [ -n "$APP_OBJECT_ID" ]; then
    az ad app delete --id "$APP_OBJECT_ID"
    echo "✓ Service principal and app registration deleted successfully"
else
    echo "Service principal not found (may have been already deleted)"
fi

echo ""

#########################################
# Delete Resource Group (includes storage account)
#########################################
echo "Step 3: Deleting resource group (this may take a few minutes)..."
echo "----------------------------------------"

RG_EXISTS=$(az group exists -n $TF_RESOURCE_GROUP)

if [ "$RG_EXISTS" = "true" ]; then
    az group delete -n $TF_RESOURCE_GROUP --yes --no-wait
    echo "✓ Resource group deletion initiated"
    echo "  Note: Deletion is running in the background and may take several minutes to complete"
else
    echo "Resource group not found (may have been already deleted)"
fi

echo ""

#########################################
# Delete Image Builder Resource Group (if confirmed)
#########################################
if [ "$DELETE_IMAGE_RG" = true ]; then
    echo "Step 4: Deleting Image Builder resource group..."
    echo "----------------------------------------"
    
    IMAGE_RG_EXISTS=$(az group exists -n $IMAGE_RESOURCE_GROUP)
    
    if [ "$IMAGE_RG_EXISTS" = "true" ]; then
        az group delete -n $IMAGE_RESOURCE_GROUP --yes
        echo "✓ Image Builder resource group deletion initiated"
        echo "  Note: Deletion is running in the background and may take several minutes to complete"
    else
        echo "Image Builder resource group not found (may have been already deleted)"
    fi
    
    echo ""
fi

#########################################
# Summary
#########################################
echo "=========================================="
echo "CLEANUP COMPLETED"
echo "=========================================="
echo "✓ Role assignments removed"
echo "✓ Service principal deleted"
echo "✓ Resource group deletion initiated"
if [ "$DELETE_IMAGE_RG" = true ]; then
    echo "✓ Image Builder resource group deletion initiated"
fi
echo ""
echo "The resource group deletion(s) are running in the background."
echo "You can check the status with:"
echo "  az group show -n $TF_RESOURCE_GROUP"
if [ "$DELETE_IMAGE_RG" = true ]; then
    echo "  az group show -n $IMAGE_RESOURCE_GROUP"
fi
echo ""
echo "To unset environment variables from your shell, run:"
echo "  unset ARM_SUBSCRIPTION_ID ARM_TENANT_ID REGION TF_RESOURCE_GROUP"
echo "  unset TF_STORAGE_ACCOUNT TF_CONTAINER_NAME SP_NAME SP_APP_ID SP_OUTPUT"
echo "=========================================="
