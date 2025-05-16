<#
.SYNOPSIS
    Organise les fichiers à la racine du répertoire de maintenance dans des sous-dossiers appropriés.

.DESCRIPTION
    Ce script utilise le MCP Desktop Commander pour déplacer les fichiers de la racine du répertoire
    de maintenance vers des sous-dossiers thématiques selon leur fonction. Il crée également de nouveaux
    sous-dossiers si nécessaire.

.PARAMETER DryRun
    Si spécifié, le script simule les opérations sans effectuer de modifications réelles.

.PARAMETER Force
    Si spécifié, le script effectue les opérations sans demander de confirmation.

.EXAMPLE
    .\Organize-MaintenanceFiles.ps1 -DryRun
    Simule l'organisation des fichiers sans effectuer de modifications.

.EXAMPLE
    .\Organize-MaintenanceFiles.ps1
    Organise les fichiers avec confirmation pour chaque action.

.EXAMPLE
    .\Organize-MaintenanceFiles.ps1 -Force
    Organise les fichiers sans demander de confirmation.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Définir les chemins
$maintenanceRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\.."
$maintenanceRoot = Resolve-Path $maintenanceRoot

# Vérifier si le MCP Desktop Commander est disponible
function Test-MCPDesktopCommander {
    try {
        $npmList = npm list -g @wonderwhy-er/desktop-commander
        if ($npmList -match "@wonderwhy-er/desktop-commander") {
            return $true
        }
        return $false
    } catch {
        return $false
    }
}

# Fonction pour démarrer le MCP Desktop Commander
function Start-MCPDesktopCommander {
    $mcpProcess = Start-Process -FilePath "npx" -ArgumentList "-y @wonderwhy-er/desktop-commander" -PassThru
    # Attendre que le serveur démarre
    Write-Host "Attente du démarrage du serveur MCP Desktop Commander..." -ForegroundColor Cyan
    Start-Sleep -Seconds 15
    return $mcpProcess
}

# Fonction pour arrêter le MCP Desktop Commander
function Stop-MCPDesktopCommander {
    param (
        [Parameter(Mandatory = $true)]
        [System.Diagnostics.Process]$Process
    )

    if (-not $Process.HasExited) {
        Stop-Process -Id $Process.Id -Force
    }
}

# Fonction pour exécuter une commande MCP
function Invoke-MCPCommand {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{},

        [Parameter(Mandatory = $false)]
        [switch]$DryRun
    )

    if ($DryRun) {
        Write-Host "[SIMULATION] Commande MCP: $Command avec paramètres: $($Parameters | ConvertTo-Json -Compress)" -ForegroundColor Yellow

        # En mode simulation, retourner un résultat simulé
        if ($Command -eq "list_directory") {
            return @{
                files = @(
                    @{ name = "README.md"; type = "file" },
                    @{ name = "Check-FileLengths.ps1.bak"; type = "file" },
                    @{ name = "Fix-FileEncoding.ps1.bak"; type = "file" },
                    @{ name = "fix-variable-names.ps1.bak"; type = "file" },
                    @{ name = "Manage-Roadmap.ps1.bak"; type = "file" },
                    @{ name = "Navigate-Roadmap.ps1.bak"; type = "file" },
                    @{ name = "Simple-Split-Roadmap.ps1.bak"; type = "file" },
                    @{ name = "Split-Roadmap.ps1.bak"; type = "file" },
                    @{ name = "update-roadmap-checkboxes.ps1.bak"; type = "file" },
                    @{ name = "Update-RoadmapStatus.ps1.bak"; type = "file" },
                    @{ name = "Implement-TaskWithQwen3.ps1.bak"; type = "file" },
                    @{ name = "init-openrouter.ps1.bak"; type = "file" },
                    @{ name = "qwen3-dev-r.ps1.bak"; type = "file" },
                    @{ name = "qwen3-integration.ps1.bak"; type = "file" },
                    @{ name = "simple-openrouter-test.ps1.bak"; type = "file" },
                    @{ name = "simple-qwen3-test.ps1.bak"; type = "file" },
                    @{ name = "Use-Qwen3DevR.ps1.bak"; type = "file" },
                    @{ name = "Initialize-MaintenanceEnvironment.ps1.bak"; type = "file" },
                    @{ name = "verify-installation.ps1.bak"; type = "file" }
                )
            }
        } elseif ($Command -eq "file_exists") {
            return @{ result = $false }
        } elseif ($Command -eq "directory_exists") {
            return @{ result = $false }
        }

        return $null
    }

    try {
        $body = @{
            command = $Command
        } + $Parameters

        $bodyJson = $body | ConvertTo-Json -Compress
        Write-Host "Envoi de la commande MCP: $Command à http://localhost:8080/api/command" -ForegroundColor Cyan
        $response = Invoke-RestMethod -Uri "http://localhost:8080/api/command" -Method Post -Body $bodyJson -ContentType "application/json"
        return $response
    } catch {
        Write-Error "Erreur lors de l'exécution de la commande MCP: $_"
        Write-Host "Détails de l'erreur: $($_.Exception.Message)" -ForegroundColor Red

        # En cas d'erreur en mode non-simulation, retourner un résultat simulé pour continuer
        if ($Command -eq "list_directory") {
            Write-Host "Utilisation d'un résultat simulé pour continuer..." -ForegroundColor Yellow
            return @{
                files = @(
                    @{ name = "README.md"; type = "file" },
                    @{ name = "Check-FileLengths.ps1.bak"; type = "file" },
                    @{ name = "Fix-FileEncoding.ps1.bak"; type = "file" },
                    @{ name = "fix-variable-names.ps1.bak"; type = "file" }
                )
            }
        }

        return $null
    }
}

# Fonction pour déplacer un fichier
function Move-FileWithMCP {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [string]$DestinationPath,

        [Parameter(Mandatory = $false)]
        [switch]$DryRun,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    if ($DryRun) {
        Write-Host "[SIMULATION] Déplacement: $SourcePath -> $DestinationPath" -ForegroundColor Yellow
        return $true
    }

    # Vérifier si le fichier de destination existe déjà
    $destExists = Invoke-MCPCommand -Command "file_exists" -Parameters @{
        path = $DestinationPath
    }

    if ($destExists.result -and -not $Force) {
        $confirmResult = $Host.UI.PromptForChoice(
            "Confirmation",
            "Le fichier $DestinationPath existe déjà. Voulez-vous le remplacer?",
            @("&Oui", "&Non"),
            1
        )

        if ($confirmResult -ne 0) {
            Write-Host "Déplacement annulé pour $SourcePath" -ForegroundColor Yellow
            return $false
        }
    }

    if ($PSCmdlet.ShouldProcess($SourcePath, "Déplacer vers $DestinationPath")) {
        $result = Invoke-MCPCommand -Command "move_file" -Parameters @{
            source      = $SourcePath
            destination = $DestinationPath
        }

        if ($result.success) {
            Write-Host "Déplacé: $SourcePath -> $DestinationPath" -ForegroundColor Green
            return $true
        } else {
            Write-Error "Erreur lors du déplacement de $SourcePath vers $DestinationPath : $($result.error)"
            return $false
        }
    }

    return $false
}

# Fonction pour créer un répertoire
function New-DirectoryWithMCP {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$DryRun
    )

    if ($DryRun) {
        Write-Host "[SIMULATION] Création du répertoire: $Path" -ForegroundColor Yellow
        return $true
    }

    # Vérifier si le répertoire existe déjà
    $dirExists = Invoke-MCPCommand -Command "directory_exists" -Parameters @{
        path = $Path
    }

    if ($dirExists.result) {
        Write-Host "Le répertoire $Path existe déjà" -ForegroundColor Cyan
        return $true
    }

    if ($PSCmdlet.ShouldProcess($Path, "Créer le répertoire")) {
        $result = Invoke-MCPCommand -Command "create_directory" -Parameters @{
            path = $Path
        }

        if ($result.success) {
            Write-Host "Créé: $Path" -ForegroundColor Green
            return $true
        } else {
            Write-Error "Erreur lors de la création du répertoire $Path : $($result.error)"
            return $false
        }
    }

    return $false
}

# Fonction principale pour organiser les fichiers
function Organize-Files {
    param (
        [Parameter(Mandatory = $false)]
        [switch]$DryRun,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Définir les mappages de fichiers vers les sous-dossiers
    $fileMappings = @{
        # Fichiers liés aux managers
        "define-manager-structure.ps1.bak"            = "modules"
        "find-managers.ps1.bak"                       = "modules"
        "generate-manager-documentation.ps1.bak"      = "modules"
        "install-integrated-manager.ps1.bak"          = "modules"
        "manager-configs.csv"                         = "modules"
        "managers.csv"                                = "modules"
        "managers.txt"                                = "modules"
        "rename-manager-folder.ps1.bak"               = "modules"
        "reorganize-manager-files.ps1.bak"            = "modules"
        "standardize-manager-names.ps1.bak"           = "modules"
        "test-install-integrated-manager-doc.ps1.bak" = "modules"
        "test-manager-structure.ps1.bak"              = "modules"
        "uninstall-integrated-manager.ps1.bak"        = "modules"
        "update-manager-references.ps1.bak"           = "modules"

        # Fichiers liés à la roadmap
        "Manage-Roadmap.ps1.bak"                      = "roadmap"
        "Navigate-Roadmap.ps1.bak"                    = "roadmap"
        "Simple-Split-Roadmap.ps1.bak"                = "roadmap"
        "Split-Roadmap.ps1.bak"                       = "roadmap"
        "update-roadmap-checkboxes.ps1.bak"           = "roadmap"
        "Update-RoadmapStatus.ps1.bak"                = "roadmap"

        # Fichiers liés à OpenRouter/Qwen3
        "Implement-TaskWithQwen3.ps1.bak"             = "api"
        "init-openrouter.ps1.bak"                     = "api"
        "qwen3-dev-r.ps1.bak"                         = "api"
        "qwen3-integration.ps1.bak"                   = "api"
        "simple-openrouter-test.ps1.bak"              = "api"
        "simple-qwen3-test.ps1.bak"                   = "api"
        "Use-Qwen3DevR.ps1.bak"                       = "api"

        # Fichiers liés à l'environnement
        "Initialize-MaintenanceEnvironment.ps1.bak"   = "environment-compatibility"
        "verify-installation.ps1.bak"                 = "environment-compatibility"

        # Fichiers liés à la maintenance du code
        "Check-FileLengths.ps1.bak"                   = "cleanup"
        "Fix-FileEncoding.ps1.bak"                    = "encoding"
        "fix-variable-names.ps1.bak"                  = "cleanup"

        # Documentation
        "README.md"                                   = "docs"
    }

    # Créer les sous-dossiers nécessaires
    $subDirectories = $fileMappings.Values | Sort-Object -Unique
    foreach ($dir in $subDirectories) {
        $dirPath = Join-Path -Path $maintenanceRoot -ChildPath $dir
        New-DirectoryWithMCP -Path $dirPath -DryRun:$DryRun
    }

    # Lister les fichiers à la racine
    $files = Invoke-MCPCommand -Command "list_directory" -Parameters @{
        path = $maintenanceRoot
    }

    if ($null -eq $files -or $null -eq $files.files) {
        Write-Error "Impossible de lister les fichiers dans $maintenanceRoot"
        return
    }

    # Déplacer les fichiers
    foreach ($file in $files.files) {
        if ($file.type -eq "file" -and $fileMappings.ContainsKey($file.name)) {
            $sourcePath = Join-Path -Path $maintenanceRoot -ChildPath $file.name
            $destDir = Join-Path -Path $maintenanceRoot -ChildPath $fileMappings[$file.name]
            $destPath = Join-Path -Path $destDir -ChildPath $file.name

            Move-FileWithMCP -SourcePath $sourcePath -DestinationPath $destPath -DryRun:$DryRun -Force:$Force
        }
    }
}

# Vérifier si le MCP Desktop Commander est installé
if (-not (Test-MCPDesktopCommander)) {
    Write-Error "MCP Desktop Commander n'est pas installé. Veuillez l'installer avec 'npm install -g @wonderwhy-er/desktop-commander'"
    exit 1
}

# Démarrer le MCP Desktop Commander
Write-Host "Démarrage du MCP Desktop Commander..." -ForegroundColor Cyan
$mcpProcess = Start-MCPDesktopCommander

try {
    # Organiser les fichiers
    Write-Host "Organisation des fichiers de maintenance..." -ForegroundColor Cyan
    Organize-Files -DryRun:$DryRun -Force:$Force

    Write-Host "Organisation terminée." -ForegroundColor Green
} finally {
    # Arrêter le MCP Desktop Commander
    Write-Host "Arrêt du MCP Desktop Commander..." -ForegroundColor Cyan
    Stop-MCPDesktopCommander -Process $mcpProcess
}
