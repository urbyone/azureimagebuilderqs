az login --use-device-code
# az account set --subscription "your-subscription-id-or-name" or pick your subscription from the list on login.

# Check if ARM_SUBSCRIPTION_ID and ARM_TENANT_ID are set
if [ -z "$ARM_SUBSCRIPTION_ID" ]; then
    echo "ARM_SUBSCRIPTION_ID not set. Using subscription ID from the current Azure account."
    ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    echo "ARM_SUBSCRIPTION_ID set to $ARM_SUBSCRIPTION_ID"
fi

if [ -z "$ARM_TENANT_ID" ]; then
    echo "ARM_TENANT_ID not set. Using tenant ID from the current Azure account: $ARM_TENANT_ID"
    ARM_TENANT_ID=$(az account show --query tenantId -o tsv)
    echo "ARM_TENANT_ID set to $ARM_TENANT_ID"
    
fi

##################################################################################
# Create Storage for Terraform state file if required or Skip if already created.#
##################################################################################
region="uksouth"
mytfRSG="rg-${region}-terraform-$(date +%s)"
az group create -n $mytfRSG -l $region --tags Description="Terraform State File for Github Actions Image Builder Demo"

accountName=$(head /dev/urandom | tr -dc a-z0-9 | head -c 24)
echo $accountName

az storage account create --resource-group $mytfRSG --name $accountName --sku Standard_LRS --encryption-services blob
az storage container create --name "tfstate" --account-name $accountName

#############################################################
#Create a service principal for GitHub Actions Image Builder#
#############################################################
appName="GitHubActions-imagebuilder-$(date +%s)"
SP_OUTPUT=$(az ad sp create-for-rbac --name $appName --role Contributor --scopes /subscriptions/${ARM_SUBSCRIPTION_ID} --json-auth)
# Extract appId from the service principal output
APP_ID=$(echo "$SP_OUTPUT" | jq -r '.clientId')

#Assign Storage Blob Contributor role to the service principal for the storage account
az role assignment create --assignee $APP_ID --role "Storage Blob Data Contributor" --scope /subscriptions/${ARM_SUBSCRIPTION_ID}/resourceGroups/${mytfRSG}/providers/Microsoft.Storage/storageAccounts/${accountName}
# Secret for GitHub Actions
echo "$SP_OUTPUT"