# If you are not mounting .azure from local:
# az login --use-device-code
# az account set --subscription "your-subscription-id-or-name" or pick your subscription from the list on login.

# Check if ARM_SUBSCRIPTION_ID and ARM_TENANT_ID are set
if [ -z "$ARM_SUBSCRIPTION_ID" ]; then
    echo "ARM_SUBSCRIPTION_ID not set. Using subscription ID from the current Azure account."
    export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    echo "ARM_SUBSCRIPTION_ID set to $ARM_SUBSCRIPTION_ID"
else
    export ARM_SUBSCRIPTION_ID
fi

if [ -z "$ARM_TENANT_ID" ]; then
    echo "ARM_TENANT_ID not set. Using tenant ID from the current Azure account: $ARM_TENANT_ID"
    export ARM_TENANT_ID=$(az account show --query tenantId -o tsv)
    echo "ARM_TENANT_ID set to $ARM_TENANT_ID"
else
    export ARM_TENANT_ID
fi

##################################################################################
# Create Storage for Terraform state file if required or Skip if already created.#
##################################################################################
export REGION="uksouth"
export TF_RESOURCE_GROUP="$(grep 'resource_group_name' infra-aib/variables.auto.tfvars | awk -F '"' '{print $2}')-temp-tfstate"
az group create -n $TF_RESOURCE_GROUP -l $REGION --tags Description="Terraform State File for Github Actions Image Builder Demo"

export TF_STORAGE_ACCOUNT=$(head /dev/urandom | tr -dc a-z0-9 | head -c 24)
echo $TF_STORAGE_ACCOUNT

az storage account create --resource-group $TF_RESOURCE_GROUP --name $TF_STORAGE_ACCOUNT --sku Standard_LRS --encryption-services blob
export TF_CONTAINER_NAME="tfstate"
az storage container create --name "$TF_CONTAINER_NAME" --account-name $TF_STORAGE_ACCOUNT

#############################################################
#Create a service principal for GitHub Actions Image Builder#
#############################################################
export SP_NAME="GitHubActions-imagebuilder-$(date +%s)"
export SP_OUTPUT=$(az ad sp create-for-rbac --name $SP_NAME --role Owner --scopes /subscriptions/${ARM_SUBSCRIPTION_ID} --json-auth)
# Extract appId from the service principal output
export SP_APP_ID=$(echo "$SP_OUTPUT" | jq -r '.clientId')

#Assign Storage Blob Contributor role to the service principal for the storage account
az role assignment create --assignee $SP_APP_ID --role "Storage Blob Data Contributor" --scope /subscriptions/${ARM_SUBSCRIPTION_ID}/resourceGroups/${TF_RESOURCE_GROUP}/providers/Microsoft.Storage/storageAccounts/${TF_STORAGE_ACCOUNT}

#########
#OUTPUTS#
#########
echo "=========================================="
echo "Environment Variables Set:"
echo "=========================================="
echo "ARM_SUBSCRIPTION_ID: $ARM_SUBSCRIPTION_ID"
echo "ARM_TENANT_ID: $ARM_TENANT_ID"
echo "REGION: $REGION"
echo "TF_RESOURCE_GROUP: $TF_RESOURCE_GROUP"
echo "TF_STORAGE_ACCOUNT: $TF_STORAGE_ACCOUNT"
echo "TF_CONTAINER_NAME: $TF_CONTAINER_NAME"
echo "SP_NAME: $SP_NAME"
echo "SP_APP_ID: $SP_APP_ID"
echo "=========================================="
echo ""
echo "GitHub Actions Secret (SP_OUTPUT):"
echo "$SP_OUTPUT"
echo ""
echo "NOTE: To use these variables in your current shell, run:"
echo "source .github/scripts/setup.sh"