# Introduction 
Lab for creating Azure Image Builder VMs

# Getting Started
Ensure the required providers are registered in the sub
```ps
az provider register -n Microsoft.VirtualMachineImages
az provider register -n Microsoft.Compute
az provider register -n Microsoft.KeyVault
az provider register -n Microsoft.Storage
az provider register -n Microsoft.Network
az provider register -n Microsoft.ContainerInstance

az provider show -n Microsoft.VirtualMachineImages --query registrationState
az provider show -n Microsoft.Compute --query registrationState
az provider show -n Microsoft.KeyVault --query registrationState
az provider show -n Microsoft.Storage --query registrationState
az provider show -n Microsoft.Network --query registrationState
az provider show -n Microsoft.ContainerInstance --query registrationState
```
# Build and Test
TODO: Describe and show how to build your code and run the tests.