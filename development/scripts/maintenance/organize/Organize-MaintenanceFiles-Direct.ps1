<#
.SYNOPSIS
    Organise les fichiers à la racine du répertoire de maintenance dans des sous-dossiers appropriés.

.DESCRIPTION
    Ce script déplace les fichiers de la racine du répertoire de maintenance vers des sous-dossiers
    thématiques selon leur fonction. Il crée également de nouveaux sous-dossiers si nécessaire.

.PARAMETER DryRun
    Si spécifié, le script simule les opérations sans effectuer de modifications réelles.

.PARAMETER Force
    Si spécifié, le script effectue les opérations sans demander de confirmation.

.EXAMPLE
    .\Organize-MaintenanceFiles-Direct.ps1 -DryRun
    Simule l'organisation des fichiers sans effectuer de modifications.

.EXAMPLE
    .\Organize-MaintenanceFiles-Direct.ps1
    Organise les fichiers avec confirmation pour chaque action.

.EXAMPLE
    .\Organize-MaintenanceFiles-Direct.ps1 -Force
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
$maintenanceRoot = Join-Path -Path $PSScriptRoot -ChildPath ".."
$maintenanceRoot = Resolve-Path $maintenanceRoot

# Fonction pour déplacer un fichier
function Move-FileToDirectory {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [string]$DestinationDirectory,

        [Parameter(Mandatory = $false)]
        [switch]$DryRun,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    $fileName = Split-Path -Path $SourcePath -Leaf
    $destinationPath = Join-Path -Path $DestinationDirectory -ChildPath $fileName

    if ($DryRun) {
        Write-Host "[SIMULATION] Déplacement: $SourcePath -> $destinationPath" -ForegroundColor Yellow
        return $true
    }

    # Vérifier si le fichier de destination existe déjà
    if (Test-Path -Path $destinationPath) {
        if ($Force) {
            $shouldContinue = $true
        } else {
            $shouldContinue = $PSCmdlet.ShouldContinue("Le fichier existe déjà : $destinationPath. Voulez-vous le remplacer ?", "Confirmation")
        }

        if (-not $shouldContinue) {
            Write-Host "Déplacement annulé pour $SourcePath" -ForegroundColor Yellow
            return $false
        }
    }

    if ($PSCmdlet.ShouldProcess($SourcePath, "Déplacer vers $destinationPath")) {
        try {
            Move-Item -Path $SourcePath -Destination $destinationPath -Force
            Write-Host "Déplacé: $SourcePath -> $destinationPath" -ForegroundColor Green
            return $true
        } catch {
            Write-Error "Erreur lors du déplacement de $SourcePath vers $destinationPath : $_"
            return $false
        }
    }

    return $false
}

# Fonction principale pour organiser les fichiers
function Start-FileOrganization {
    [CmdletBinding(SupportsShouldProcess = $true)]
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

        if (-not (Test-Path -Path $dirPath)) {
            if ($DryRun) {
                Write-Host "[SIMULATION] Création du répertoire: $dirPath" -ForegroundColor Yellow
            } else {
                if ($PSCmdlet.ShouldProcess($dirPath, "Créer le répertoire")) {
                    try {
                        New-Item -Path $dirPath -ItemType Directory -Force | Out-Null
                        Write-Host "Créé: $dirPath" -ForegroundColor Green
                    } catch {
                        Write-Error "Erreur lors de la création du répertoire $dirPath : $_"
                    }
                }
            }
        } else {
            Write-Host "Le répertoire $dirPath existe déjà" -ForegroundColor Cyan
        }
    }

    # Lister les fichiers à la racine
    $files = Get-ChildItem -Path $maintenanceRoot -File

    # Déplacer les fichiers
    foreach ($file in $files) {
        if ($fileMappings.ContainsKey($file.Name)) {
            $destDir = Join-Path -Path $maintenanceRoot -ChildPath $fileMappings[$file.Name]
            Move-FileToDirectory -SourcePath $file.FullName -DestinationDirectory $destDir -DryRun:$DryRun -Force:$Force
        }
    }
}

# Organiser les fichiers
Write-Host "Organisation des fichiers de maintenance..." -ForegroundColor Cyan
Write-Host "Répertoire racine: $maintenanceRoot" -ForegroundColor Cyan

# Lister les fichiers à la racine pour vérification
Write-Host "Fichiers à la racine:" -ForegroundColor Cyan
Get-ChildItem -Path $maintenanceRoot -File | Select-Object Name | ForEach-Object { Write-Host "- $($_.Name)" -ForegroundColor Gray }

Start-FileOrganization -DryRun:$DryRun -Force:$Force

Write-Host "Organisation terminée." -ForegroundColor Green
