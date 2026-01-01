# Dev Container Setup

This folder contains the configuration for VS Code Dev Containers.

## How to Use

1. **Install the Dev Containers extension** in VS Code:
   - Extension ID: `ms-vscode-remote.remote-containers`

2. **Open in Dev Container**:
   - Open the `terradev` folder in VS Code
   - Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
   - Type "Dev Containers: Reopen in Container"
   - Select it and wait for the container to build/start

3. **Alternative method**:
   - VS Code should show a notification asking if you want to reopen in container
   - Click "Reopen in Container"

## What This Provides

- **Automatic container setup** using your existing `docker.yml` configuration
- **Pre-installed extensions** for Azure and Terraform development
- **Persistent volumes** for Azure credentials and Terraform state
- **Integrated terminal** with all tools available (Azure CLI, Terraform, kubectl, PowerShell)

## Benefits over Manual Docker

- **Integrated development**: VS Code runs inside the container
- **Extension support**: All extensions work seamlessly
- **IntelliSense**: Full code completion for Terraform and Azure
- **Debugging**: Integrated debugging capabilities
- **Git integration**: Works with your existing Git workflow

## Workspace Structure

When opened in the dev container:
- Your local files are mounted at `/workspace`
- Azure credentials persist between sessions
- Terraform state is maintained
- VS Code settings and extensions are pre-configured

## Troubleshooting

If the dev container doesn't start:

### Image doesn't exist
The container will automatically build the image if it doesn't exist, but if you want to build manually:
```powershell
.\build.ps1 build
```

### Container issues
1. Make sure Docker is running
2. Try rebuilding the dev container: `Ctrl+Shift+P` → "Dev Containers: Rebuild Container"
3. Check Docker Desktop for any error messages
4. If all else fails, clean and rebuild:
   ```powershell
   .\build.ps1 clean
   .\build.ps1 build
   ```

### Dev Container vs Manual Method
- **Dev Container**: Automatic, integrated with VS Code
- **Manual Method**: Use `.\build.ps1 start` and `.\build.ps1 connect`