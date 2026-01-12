#!/bin/bash

# Parse values from variables.auto.tfvars
TFVARS_FILE="variables.auto.tfvars"

if [ ! -f "$TFVARS_FILE" ]; then
    echo "Error: $TFVARS_FILE not found"
    exit 1
fi

# Extract values from tfvars file
RESOURCE_GROUP=$(grep 'resource_group_name' "$TFVARS_FILE" | sed 's/.*=\s*"\(.*\)".*/\1/')
GALLERY_NAME=$(grep 'gallery_name' "$TFVARS_FILE" | sed 's/.*=\s*"\(.*\)".*/\1/' | sed 's/\s*#.*//')
IMAGE_DEFINITION=$(grep 'image_definition_name' "$TFVARS_FILE" | sed 's/.*=\s*"\(.*\)".*/\1/')

# Validate that we got all the values
if [ -z "$RESOURCE_GROUP" ] || [ -z "$GALLERY_NAME" ] || [ -z "$IMAGE_DEFINITION" ]; then
    echo "Error: Failed to extract one or more required values from $TFVARS_FILE"
    echo "  Resource Group: $RESOURCE_GROUP"
    echo "  Gallery Name: $GALLERY_NAME"
    echo "  Image Definition: $IMAGE_DEFINITION"
    exit 1
fi

echo "Using values from $TFVARS_FILE:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Gallery Name: $GALLERY_NAME"
echo "  Image Definition: $IMAGE_DEFINITION"
echo ""

# List existing image versions
echo "Listing existing image versions..."
IMAGE_VERSIONS=$(az sig image-version list \
    --gallery-name "$GALLERY_NAME" \
    --gallery-image-definition "$IMAGE_DEFINITION" \
    --resource-group "$RESOURCE_GROUP" \
    --query "[].name" \
    -o tsv)

if [ -z "$IMAGE_VERSIONS" ]; then
    echo "No image versions found to delete."
else
    echo "Found image versions:"
    echo "$IMAGE_VERSIONS"
    echo ""
    
    # Delete each image version
    echo "Deleting image versions..."
    while IFS= read -r VERSION; do
        if [ -n "$VERSION" ]; then
            echo "  Deleting version: $VERSION"
            az sig image-version delete \
                --gallery-name "$GALLERY_NAME" \
                --gallery-image-definition "$IMAGE_DEFINITION" \
                --resource-group "$RESOURCE_GROUP" \
                --gallery-image-version "$VERSION" \
                --no-wait
        fi
    done <<< "$IMAGE_VERSIONS"
    
    # Wait for all deletions to complete
    echo ""
    echo "Waiting for all image version deletions to complete..."
    while IFS= read -r VERSION; do
        if [ -n "$VERSION" ]; then
            echo "  Waiting for $VERSION..."
            while az sig image-version show \
                --gallery-name "$GALLERY_NAME" \
                --gallery-image-definition "$IMAGE_DEFINITION" \
                --resource-group "$RESOURCE_GROUP" \
                --gallery-image-version "$VERSION" \
                &>/dev/null; do
                sleep 5
            done
            echo "  ✓ $VERSION deleted"
        fi
    done <<< "$IMAGE_VERSIONS"
    
    echo ""
    echo "All image versions deleted successfully."
fi

# Run terraform destroy
echo ""
echo "Running terraform destroy..."
terraform destroy