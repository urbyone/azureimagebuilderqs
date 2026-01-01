# Build and Setup Script for Azure Development Environment (PowerShell)
# This script builds the Docker image and sets up the development environment

param(
    [Parameter(Position=0)]
    [ValidateSet("build", "start", "connect", "stop", "clean", "help")]
    [string]$Command = "build",
    
    [Parameter()]
    [switch]$All
)

function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    } else {
        $input | Write-Output
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Check-Docker {
    Write-ColorOutput Yellow "🔍 Checking Docker status..."
    try {
        docker info | Out-Null
        Write-ColorOutput Green "✅ Docker is running"
        return $true
    }
    catch {
        Write-ColorOutput Red "❌ Docker is not running. Please start Docker Desktop."
        return $false
    }
}

function Build-Image {
    Write-ColorOutput Yellow "🔨 Building custom Azure development image..."
    docker build -t terradev:latest .
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput Green "✅ Image built successfully!"
    } else {
        Write-ColorOutput Red "❌ Failed to build image"
        exit 1
    }
}

function Start-Environment {
    Write-ColorOutput Yellow "🌟 Starting development environment..."
    docker-compose -f docker.yml up -d azure-dev
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput Green "✅ Environment started successfully!"
        Write-ColorOutput Cyan "📝 To connect to your container, run:"
        Write-ColorOutput Cyan "   .\build.ps1 connect"
    } else {
        Write-ColorOutput Red "❌ Failed to start environment"
        exit 1
    }
}

function Connect-Container {
    Write-ColorOutput Yellow "🔗 Connecting to container..."
    docker exec -it terradev /bin/bash
}

function Stop-Environment {
    Write-ColorOutput Yellow "🛑 Stopping development environment..."
    docker-compose -f docker.yml down
}

function Clean-Environment {
    if ($All) {
        Write-ColorOutput Yellow "🧹 Performing complete environment cleanup..."
        Write-ColorOutput Yellow "⚠️ This will remove ALL containers, images, and volumes!"
        
        # First, stop and remove docker-compose services
        Write-ColorOutput Yellow "🛑 Stopping docker-compose services..."
        docker-compose -f docker.yml down --volumes
        
        # Remove all containers (stopped and running)
        Write-ColorOutput Yellow "🗑️ Removing all containers..."
        $containers = docker ps -aq
        if ($containers) {
            docker rm -f $containers
        }
        
        # Remove all images
        Write-ColorOutput Yellow "🗑️ Removing all images..."
        $images = docker images -q
        if ($images) {
            docker rmi -f $images
        }
        
        # Remove all volumes
        Write-ColorOutput Yellow "🗑️ Removing all volumes..."
        $volumes = docker volume ls -q
        if ($volumes) {
            docker volume rm -f $volumes
        }
        
        # Remove all networks (except default ones)
        Write-ColorOutput Yellow "🗑️ Removing custom networks..."
        $networks = docker network ls --filter type=custom -q
        if ($networks) {
            docker network rm $networks
        }
        
        # Prune everything for good measure
        Write-ColorOutput Yellow "🧹 Running system prune..."
        docker system prune -af --volumes
        
        Write-ColorOutput Green "✅ Complete environment cleanup completed!"
    } else {
        Write-ColorOutput Yellow "🧹 Cleaning up terradev containers and images..."
        
        # Stop and remove only the specific terradev container
        Write-ColorOutput Yellow "🛑 Stopping terradev container..."
        docker stop terradev 2>$null
        docker rm terradev 2>$null
        
        # Remove the specific terradev image
        Write-ColorOutput Yellow "🗑️ Removing terradev image..."
        docker rmi terradev:latest -f 2>$null
        
        # Remove terradev-specific volumes
        Write-ColorOutput Yellow "🗑️ Removing terradev volumes..."
        docker volume rm terradev_azure-credentials 2>$null
        docker volume rm terradev_terraform-config 2>$null
        
        # Remove terradev network if it exists and no other containers are using it
        Write-ColorOutput Yellow "🗑️ Removing terradev network..."
        docker network rm terradev_default 2>$null
        
        Write-ColorOutput Green "✅ Terradev cleanup completed!"
    }
}

function Show-Usage {
    Write-Host ""
    Write-ColorOutput Cyan "📋 Available commands:"
    Write-Host "  .\build.ps1 build     - Build the Docker image"
    Write-Host "  .\build.ps1 start     - Start the development environment"
    Write-Host "  .\build.ps1 connect   - Connect to the running container"
    Write-Host "  .\build.ps1 stop      - Stop the development environment"
    Write-Host "  .\build.ps1 clean     - Remove terradev containers and images"
    Write-Host "  .\build.ps1 clean -all - Remove ALL containers, images, and volumes"
    Write-Host ""
}

# Main script logic
if (-not (Check-Docker)) {
    exit 1
}

switch ($Command) {
    "build" {
        Build-Image
    }
    "start" {
        Start-Environment
    }
    "connect" {
        Connect-Container
    }
    "stop" {
        Stop-Environment
    }
    "clean" {
        Clean-Environment
    }
    "help" {
        Show-Usage
    }
    default {
        Write-ColorOutput Red "❓ Unknown command: $Command"
        Show-Usage
        exit 1
    }
}