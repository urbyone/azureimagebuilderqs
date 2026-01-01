#!/bin/bash

# Container Setup Script
# Run this script inside the container to set up proper permissions and initial configuration

echo "🔧 Setting up development environment..."

# Create necessary directories with proper permissions
mkdir -p ~/.azure
mkdir -p ~/.terraform.d
mkdir -p ~/.kube

# Set proper ownership
sudo chown -R devuser:devuser ~/.azure ~/.terraform.d ~/.kube

# Create initial Azure config files
touch ~/.azure/azureProfile.json
touch ~/.azure/config

# Set up git configuration (you can modify these)
git config --global user.name "Docker Developer"
git config --global user.email "developer@example.com"
git config --global init.defaultBranch main

# Check tool versions
echo ""
echo "📋 Installed tools:"
echo "=================="
echo "Azure CLI:"
az --version | head -1
echo ""
echo "Terraform:"
terraform version
echo ""
echo "kubectl:"
kubectl version --client
echo ""
echo "PowerShell:"
pwsh --version
echo ""
echo "Git:"
git --version

echo ""
echo "✅ Setup complete! You can now use:"
echo "   • az login (to authenticate with Azure)"
echo "   • terraform init (in a directory with .tf files)"
echo "   • kubectl (for Kubernetes management)"
echo ""