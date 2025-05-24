<#
.SYNOPSIS
    Intègre Hygen dans le processus de développement MCP.

.DESCRIPTION
    Ce script intègre Hygen dans le processus de développement MCP en créant
    des alias, des raccourcis et des tâches VS Code.

.EXAMPLE
    .\Integrate-HygenWorkflow.ps1
    Intègre Hygen dans le processus de développement MCP.

.NOTES
    Version: 1.0.0
    Auteur: MCP Team
    Date de création: 2023-05-15
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param()

# Définir les couleurs pour les messages
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"
$warningColor = "Yellow"

# Fonction pour afficher un message de succès
function Write-Success {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "✓ $Message" -ForegroundColor $successColor
}

# Fonction pour afficher un message d'erreur
function Write-Error {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "✗ $Message" -ForegroundColor $errorColor
}

# Fonction pour afficher un message d'information
function Write-Info {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "ℹ $Message" -ForegroundColor $infoColor
}

# Fonction pour afficher un message d'avertissement
function Write-Warning {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "⚠ $Message" -ForegroundColor $warningColor
}

# Fonction pour obtenir le chemin du projet
function Get-ProjectPath {
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $projectRoot = (Get-Item $scriptPath).Parent.Parent.Parent.FullName
    return $projectRoot
}

# Fonction pour créer des alias PowerShell
function New-PowerShellAliases {
    $projectRoot = Get-ProjectPath
    $profilePath = $PROFILE
    
    # Vérifier si le profil existe
    if (-not (Test-Path -Path $profilePath)) {
        if ($PSCmdlet.ShouldProcess($profilePath, "New-Item -ItemType File")) {
            New-Item -Path $profilePath -ItemType File -Force | Out-Null
            Write-Info "Profil PowerShell créé : $profilePath"
        }
    }
    
    # Ajouter les alias au profil
    $aliases = @"
# Aliases pour Hygen MCP
function New-MCPServer { & '$projectRoot\mcp\scripts\utils\Generate-MCPComponent.ps1' -Type server @args }
function New-MCPClient { & '$projectRoot\mcp\scripts\utils\Generate-MCPComponent.ps1' -Type client @args }
function New-MCPModule { & '$projectRoot\mcp\scripts\utils\Generate-MCPComponent.ps1' -Type module @args }
function New-MCPDoc { & '$projectRoot\mcp\scripts\utils\Generate-MCPComponent.ps1' -Type doc @args }
Set-Alias -Name gmcps -Value New-MCPServer
Set-Alias -Name gmcpc -Value New-MCPClient
Set-Alias -Name gmcpm -Value New-MCPModule
Set-Alias -Name gmcpd -Value New-MCPDoc
"@
    
    # Vérifier si les alias existent déjà
    $profileContent = Get-Content -Path $profilePath -Raw -ErrorAction SilentlyContinue
    if ($profileContent -notmatch "Aliases pour Hygen MCP") {
        if ($PSCmdlet.ShouldProcess($profilePath, "Add-Content")) {
            Add-Content -Path $profilePath -Value $aliases
            Write-Success "Aliases PowerShell ajoutés au profil"
        }
    }
    else {
        Write-Info "Les aliases PowerShell existent déjà dans le profil"
    }
}

# Fonction pour créer des tâches VS Code
function New-VSCodeTasks {
    $projectRoot = Get-ProjectPath
    $vscodePath = Join-Path -Path $projectRoot -ChildPath ".vscode"
    $tasksPath = Join-Path -Path $vscodePath -ChildPath "tasks.json"
    
    # Vérifier si le dossier .vscode existe
    if (-not (Test-Path -Path $vscodePath)) {
        if ($PSCmdlet.ShouldProcess($vscodePath, "New-Item -ItemType Directory")) {
            New-Item -Path $vscodePath -ItemType Directory -Force | Out-Null
            Write-Info "Dossier .vscode créé : $vscodePath"
        }
    }
    
    # Vérifier si le fichier tasks.json existe
    $tasksExists = Test-Path -Path $tasksPath
    if ($tasksExists) {
        # Lire le fichier tasks.json existant
        $tasksJson = Get-Content -Path $tasksPath -Raw | ConvertFrom-Json
        
        # Vérifier si les tâches Hygen existent déjà
        $hygenTaskExists = $tasksJson.tasks | Where-Object { $_.label -match "Hygen" }
        if ($hygenTaskExists) {
            Write-Info "Les tâches VS Code pour Hygen existent déjà"
            return
        }
        
        # Ajouter les tâches Hygen
        $hygenTasks = @(
            @{
                label = "Hygen: Generate MCP Server"
                type = "shell"
                command = "powershell"
                args = @(
                    "-ExecutionPolicy",
                    "Bypass",
                    "-File",
                    "`${workspaceFolder}/mcp/scripts/utils/Generate-MCPComponent.ps1",
                    "-Type",
                    "server",
                    "-Name",
                    "`${input:mcpServerName}",
                    "-Description",
                    "`${input:mcpServerDescription}",
                    "-Author",
                    "`${input:mcpAuthor}"
                )
                problemMatcher = @()
                group = "build"
            },
            @{
                label = "Hygen: Generate MCP Client"
                type = "shell"
                command = "powershell"
                args = @(
                    "-ExecutionPolicy",
                    "Bypass",
                    "-File",
                    "`${workspaceFolder}/mcp/scripts/utils/Generate-MCPComponent.ps1",
                    "-Type",
                    "client",
                    "-Name",
                    "`${input:mcpClientName}",
                    "-Description",
                    "`${input:mcpClientDescription}",
                    "-Author",
                    "`${input:mcpAuthor}"
                )
                problemMatcher = @()
                group = "build"
            },
            @{
                label = "Hygen: Generate MCP Module"
                type = "shell"
                command = "powershell"
                args = @(
                    "-ExecutionPolicy",
                    "Bypass",
                    "-File",
                    "`${workspaceFolder}/mcp/scripts/utils/Generate-MCPComponent.ps1",
                    "-Type",
                    "module",
                    "-Name",
                    "`${input:mcpModuleName}",
                    "-Description",
                    "`${input:mcpModuleDescription}",
                    "-Author",
                    "`${input:mcpAuthor}"
                )
                problemMatcher = @()
                group = "build"
            },
            @{
                label = "Hygen: Generate MCP Doc"
                type = "shell"
                command = "powershell"
                args = @(
                    "-ExecutionPolicy",
                    "Bypass",
                    "-File",
                    "`${workspaceFolder}/mcp/scripts/utils/Generate-MCPComponent.ps1",
                    "-Type",
                    "doc",
                    "-Name",
                    "`${input:mcpDocName}",
                    "-Category",
                    "`${input:mcpDocCategory}",
                    "-Description",
                    "`${input:mcpDocDescription}",
                    "-Author",
                    "`${input:mcpAuthor}"
                )
                problemMatcher = @()
                group = "build"
            }
        )
        
        # Ajouter les inputs
        $hygenInputs = @(
            @{
                id = "mcpServerName"
                description = "Nom du serveur MCP"
                default = "new-server"
                type = "promptString"
            },
            @{
                id = "mcpServerDescription"
                description = "Description du serveur MCP"
                default = "Nouveau serveur MCP"
                type = "promptString"
            },
            @{
                id = "mcpClientName"
                description = "Nom du client MCP"
                default = "new-client"
                type = "promptString"
            },
            @{
                id = "mcpClientDescription"
                description = "Description du client MCP"
                default = "Nouveau client MCP"
                type = "promptString"
            },
            @{
                id = "mcpModuleName"
                description = "Nom du module MCP"
                default = "NewModule"
                type = "promptString"
            },
            @{
                id = "mcpModuleDescription"
                description = "Description du module MCP"
                default = "Nouveau module MCP"
                type = "promptString"
            },
            @{
                id = "mcpDocName"
                description = "Nom de la documentation MCP"
                default = "new-doc"
                type = "promptString"
            },
            @{
                id = "mcpDocCategory"
                description = "Catégorie de la documentation MCP"
                default = "guides"
                type = "promptString"
            },
            @{
                id = "mcpDocDescription"
                description = "Description de la documentation MCP"
                default = "Nouvelle documentation MCP"
                type = "promptString"
            },
            @{
                id = "mcpAuthor"
                description = "Auteur du composant MCP"
                default = "MCP Team"
                type = "promptString"
            }
        )
        
        # Ajouter les tâches et les inputs au fichier tasks.json
        $tasksJson.tasks += $hygenTasks
        
        # Vérifier si la propriété inputs existe
        if (-not $tasksJson.inputs) {
            $tasksJson | Add-Member -MemberType NoteProperty -Name "inputs" -Value @()
        }
        
        $tasksJson.inputs += $hygenInputs
        
        # Écrire le fichier tasks.json
        if ($PSCmdlet.ShouldProcess($tasksPath, "Set-Content")) {
            $tasksJson | ConvertTo-Json -Depth 10 | Set-Content -Path $tasksPath
            Write-Success "Tâches VS Code pour Hygen ajoutées"
        }
    }
    else {
        # Créer un nouveau fichier tasks.json
        $tasksJson = @{
            version = "2.0.0"
            tasks = @(
                @{
                    label = "Hygen: Generate MCP Server"
                    type = "shell"
                    command = "powershell"
                    args = @(
                        "-ExecutionPolicy",
                        "Bypass",
                        "-File",
                        "`${workspaceFolder}/mcp/scripts/utils/Generate-MCPComponent.ps1",
                        "-Type",
                        "server",
                        "-Name",
                        "`${input:mcpServerName}",
                        "-Description",
                        "`${input:mcpServerDescription}",
                        "-Author",
                        "`${input:mcpAuthor}"
                    )
                    problemMatcher = @()
                    group = "build"
                },
                @{
                    label = "Hygen: Generate MCP Client"
                    type = "shell"
                    command = "powershell"
                    args = @(
                        "-ExecutionPolicy",
                        "Bypass",
                        "-File",
                        "`${workspaceFolder}/mcp/scripts/utils/Generate-MCPComponent.ps1",
                        "-Type",
                        "client",
                        "-Name",
                        "`${input:mcpClientName}",
                        "-Description",
                        "`${input:mcpClientDescription}",
                        "-Author",
                        "`${input:mcpAuthor}"
                    )
                    problemMatcher = @()
                    group = "build"
                },
                @{
                    label = "Hygen: Generate MCP Module"
                    type = "shell"
                    command = "powershell"
                    args = @(
                        "-ExecutionPolicy",
                        "Bypass",
                        "-File",
                        "`${workspaceFolder}/mcp/scripts/utils/Generate-MCPComponent.ps1",
                        "-Type",
                        "module",
                        "-Name",
                        "`${input:mcpModuleName}",
                        "-Description",
                        "`${input:mcpModuleDescription}",
                        "-Author",
                        "`${input:mcpAuthor}"
                    )
                    problemMatcher = @()
                    group = "build"
                },
                @{
                    label = "Hygen: Generate MCP Doc"
                    type = "shell"
                    command = "powershell"
                    args = @(
                        "-ExecutionPolicy",
                        "Bypass",
                        "-File",
                        "`${workspaceFolder}/mcp/scripts/utils/Generate-MCPComponent.ps1",
                        "-Type",
                        "doc",
                        "-Name",
                        "`${input:mcpDocName}",
                        "-Category",
                        "`${input:mcpDocCategory}",
                        "-Description",
                        "`${input:mcpDocDescription}",
                        "-Author",
                        "`${input:mcpAuthor}"
                    )
                    problemMatcher = @()
                    group = "build"
                }
            )
            inputs = @(
                @{
                    id = "mcpServerName"
                    description = "Nom du serveur MCP"
                    default = "new-server"
                    type = "promptString"
                },
                @{
                    id = "mcpServerDescription"
                    description = "Description du serveur MCP"
                    default = "Nouveau serveur MCP"
                    type = "promptString"
                },
                @{
                    id = "mcpClientName"
                    description = "Nom du client MCP"
                    default = "new-client"
                    type = "promptString"
                },
                @{
                    id = "mcpClientDescription"
                    description = "Description du client MCP"
                    default = "Nouveau client MCP"
                    type = "promptString"
                },
                @{
                    id = "mcpModuleName"
                    description = "Nom du module MCP"
                    default = "NewModule"
                    type = "promptString"
                },
                @{
                    id = "mcpModuleDescription"
                    description = "Description du module MCP"
                    default = "Nouveau module MCP"
                    type = "promptString"
                },
                @{
                    id = "mcpDocName"
                    description = "Nom de la documentation MCP"
                    default = "new-doc"
                    type = "promptString"
                },
                @{
                    id = "mcpDocCategory"
                    description = "Catégorie de la documentation MCP"
                    default = "guides"
                    type = "promptString"
                },
                @{
                    id = "mcpDocDescription"
                    description = "Description de la documentation MCP"
                    default = "Nouvelle documentation MCP"
                    type = "promptString"
                },
                @{
                    id = "mcpAuthor"
                    description = "Auteur du composant MCP"
                    default = "MCP Team"
                    type = "promptString"
                }
            )
        }
        
        # Écrire le fichier tasks.json
        if ($PSCmdlet.ShouldProcess($tasksPath, "Set-Content")) {
            $tasksJson | ConvertTo-Json -Depth 10 | Set-Content -Path $tasksPath
            Write-Success "Fichier tasks.json créé avec les tâches Hygen"
        }
    }
}

# Fonction pour créer un script d'intégration Git
function New-GitIntegration {
    $projectRoot = Get-ProjectPath
    $gitHooksPath = Join-Path -Path $projectRoot -ChildPath ".git\hooks"
    $postCommitPath = Join-Path -Path $gitHooksPath -ChildPath "post-commit"
    
    # Vérifier si le dossier .git/hooks existe
    if (-not (Test-Path -Path $gitHooksPath)) {
        Write-Warning "Le dossier .git/hooks n'existe pas. Assurez-vous que le projet est un dépôt Git."
        return
    }
    
    # Créer le hook post-commit
    $postCommitContent = @"
#!/bin/sh
# Hook post-commit pour Hygen MCP
# Vérifie si des fichiers générés par Hygen ont été modifiés

echo "Vérification des fichiers générés par Hygen..."
git diff --name-only HEAD~1 HEAD | grep -E 'mcp/(core|modules|docs)/' > /dev/null

if [ \$? -eq 0 ]; then
    echo "Des fichiers générés par Hygen ont été modifiés."
    echo "N'oubliez pas de mettre à jour la documentation si nécessaire."
fi

exit 0
"@
    
    # Écrire le hook post-commit
    if ($PSCmdlet.ShouldProcess($postCommitPath, "Set-Content")) {
        $postCommitContent | Set-Content -Path $postCommitPath -Encoding ASCII
        
        # Rendre le hook exécutable
        if ($IsLinux -or $IsMacOS) {
            chmod +x $postCommitPath
        }
        
        Write-Success "Hook Git post-commit créé"
    }
}

# Fonction principale
function Start-HygenWorkflowIntegration {
    Write-Info "Intégration de Hygen dans le processus de développement MCP..."
    
    # Créer des alias PowerShell
    New-PowerShellAliases
    
    # Créer des tâches VS Code
    New-VSCodeTasks
    
    # Créer un script d'intégration Git
    New-GitIntegration
    
    Write-Success "Intégration de Hygen dans le processus de développement MCP terminée"
    return $true
}

# Exécuter l'intégration du workflow
Start-HygenWorkflowIntegration

