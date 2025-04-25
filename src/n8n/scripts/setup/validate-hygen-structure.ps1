<#
.SYNOPSIS
    Script de validation de la structure de dossiers pour Hygen.

.DESCRIPTION
    Ce script vérifie que la structure de dossiers nécessaire pour Hygen est en place
    et que tous les fichiers requis sont présents.

.PARAMETER Fix
    Si spécifié, le script tentera de corriger les problèmes détectés.

.EXAMPLE
    .\validate-hygen-structure.ps1
    Vérifie la structure de dossiers pour Hygen.

.EXAMPLE
    .\validate-hygen-structure.ps1 -Fix
    Vérifie la structure de dossiers pour Hygen et tente de corriger les problèmes.

.NOTES
    Auteur: Équipe n8n
    Date de création: 2023-05-08
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [switch]$Fix = $false
)

# Définir les couleurs pour les messages
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"
$warningColor = "Yellow"

# Fonction pour afficher un message de succès
function Write-Success {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "✓ $Message" -ForegroundColor $successColor
}

# Fonction pour afficher un message d'erreur
function Write-Error {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "✗ $Message" -ForegroundColor $errorColor
}

# Fonction pour afficher un message d'information
function Write-Info {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "ℹ $Message" -ForegroundColor $infoColor
}

# Fonction pour afficher un message d'avertissement
function Write-Warning {
    param (
        [Parameter(Mandatory = $true)]
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

# Fonction pour vérifier et créer un dossier
function Test-AndCreateFolder {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$Fix = $false
    )

    if (Test-Path -Path $Path) {
        Write-Success "Le dossier existe: $Path"
        return $true
    } else {
        Write-Error "Le dossier n'existe pas: $Path"

        if ($Fix) {
            if ($PSCmdlet.ShouldProcess($Path, "Créer le dossier")) {
                try {
                    New-Item -Path $Path -ItemType Directory -Force | Out-Null
                    Write-Success "Dossier créé: $Path"
                    return $true
                } catch {
                    Write-Error "Erreur lors de la création du dossier: $_"
                    return $false
                }
            }
        }

        return $false
    }
}

# Fonction pour vérifier et créer un fichier
function Test-AndCreateFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $false)]
        [switch]$Fix = $false
    )

    if (Test-Path -Path $Path) {
        Write-Success "Le fichier existe: $Path"
        return $true
    } else {
        Write-Error "Le fichier n'existe pas: $Path"

        if ($Fix) {
            if ($PSCmdlet.ShouldProcess($Path, "Créer le fichier")) {
                try {
                    if (Test-Path -Path $SourcePath) {
                        Copy-Item -Path $SourcePath -Destination $Path -Force
                        Write-Success "Fichier créé: $Path"
                        return $true
                    } else {
                        Write-Error "Le fichier source n'existe pas: $SourcePath"
                        return $false
                    }
                } catch {
                    Write-Error "Erreur lors de la création du fichier: $_"
                    return $false
                }
            }
        }

        return $false
    }
}

# Fonction pour vérifier la structure de dossiers
function Test-FolderStructure {
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Fix = $false
    )

    $projectRoot = Get-ProjectPath
    $n8nRoot = Join-Path -Path $projectRoot -ChildPath "n8n"
    $templatesRoot = Join-Path -Path $projectRoot -ChildPath "n8n/_templates"

    $success = $true

    # Vérifier si le dossier _templates existe
    $templatesExists = Test-AndCreateFolder -Path $templatesRoot -Fix:$Fix
    $success = $success -and $templatesExists

    # Vérifier si les dossiers de templates existent
    $templateFolders = @(
        "n8n-script",
        "n8n-workflow",
        "n8n-doc",
        "n8n-integration"
    )

    foreach ($folder in $templateFolders) {
        $folderPath = Join-Path -Path $templatesRoot -ChildPath $folder
        $folderExists = Test-AndCreateFolder -Path $folderPath -Fix:$Fix
        $success = $success -and $folderExists

        # Vérifier si les sous-dossiers existent
        $subFolderPath = Join-Path -Path $folderPath -ChildPath "new"
        $subFolderExists = Test-AndCreateFolder -Path $subFolderPath -Fix:$Fix
        $success = $success -and $subFolderExists
    }

    # Vérifier si le dossier n8n existe
    $n8nExists = Test-AndCreateFolder -Path $n8nRoot -Fix:$Fix
    $success = $success -and $n8nExists

    # Vérifier si les dossiers nécessaires existent
    $n8nFolders = @(
        "automation",
        "automation/deployment",
        "automation/monitoring",
        "automation/diagnostics",
        "automation/notification",
        "automation/maintenance",
        "automation/dashboard",
        "automation/tests",
        "core",
        "core/workflows",
        "core/workflows/local",
        "core/workflows/ide",
        "core/workflows/archive",
        "integrations",
        "integrations/mcp",
        "integrations/ide",
        "integrations/api",
        "integrations/augment",
        "docs",
        "docs/architecture",
        "docs/workflows",
        "docs/api",
        "docs/guides",
        "docs/installation",
        "config",
        "data",
        "scripts",
        "scripts/utils",
        "scripts/setup",
        "scripts/sync",
        "cmd",
        "cmd/utils",
        "cmd/start",
        "cmd/stop",
        "tests",
        "tests/unit"
    )

    foreach ($folder in $n8nFolders) {
        $folderPath = Join-Path -Path $n8nRoot -ChildPath $folder
        $folderExists = Test-AndCreateFolder -Path $folderPath -Fix:$Fix
        $success = $success -and $folderExists
    }

    return $success
}

# Fonction pour vérifier les fichiers nécessaires
function Test-RequiredFiles {
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Fix = $false
    )

    $projectRoot = Get-ProjectPath
    $n8nRoot = Join-Path -Path $projectRoot -ChildPath "n8n"
    $templatesRoot = Join-Path -Path $projectRoot -ChildPath "n8n/_templates"

    $success = $true

    # Liste des fichiers nécessaires
    $requiredFiles = @(
        @{
            Path   = Join-Path -Path $n8nRoot -ChildPath "scripts/setup/install-hygen.ps1"
            Source = Join-Path -Path $n8nRoot -ChildPath "scripts/setup/install-hygen.ps1"
        },
        @{
            Path   = Join-Path -Path $n8nRoot -ChildPath "scripts/setup/ensure-hygen-structure.ps1"
            Source = Join-Path -Path $n8nRoot -ChildPath "scripts/setup/ensure-hygen-structure.ps1"
        },
        @{
            Path   = Join-Path -Path $n8nRoot -ChildPath "scripts/utils/Generate-N8nComponent.ps1"
            Source = Join-Path -Path $n8nRoot -ChildPath "scripts/utils/Generate-N8nComponent.ps1"
        },
        @{
            Path   = Join-Path -Path $n8nRoot -ChildPath "cmd/utils/generate-component.cmd"
            Source = Join-Path -Path $n8nRoot -ChildPath "cmd/utils/generate-component.cmd"
        },
        @{
            Path   = Join-Path -Path $n8nRoot -ChildPath "cmd/utils/install-hygen.cmd"
            Source = Join-Path -Path $n8nRoot -ChildPath "cmd/utils/install-hygen.cmd"
        },
        @{
            Path   = Join-Path -Path $n8nRoot -ChildPath "tests/Run-HygenTests.ps1"
            Source = Join-Path -Path $n8nRoot -ChildPath "tests/Run-HygenTests.ps1"
        },
        @{
            Path   = Join-Path -Path $n8nRoot -ChildPath "docs/hygen-guide.md"
            Source = Join-Path -Path $n8nRoot -ChildPath "docs/hygen-guide.md"
        }
    )

    foreach ($file in $requiredFiles) {
        $fileExists = Test-AndCreateFile -Path $file.Path -SourcePath $file.Source -Fix:$Fix
        $success = $success -and $fileExists
    }

    # Vérifier les fichiers de templates
    $templateFiles = @(
        @{
            Path   = Join-Path -Path $templatesRoot -ChildPath "n8n-script/new/hello.ejs.t"
            Source = Join-Path -Path $templatesRoot -ChildPath "n8n-script/new/hello.ejs.t"
        },
        @{
            Path   = Join-Path -Path $templatesRoot -ChildPath "n8n-script/new/prompt.js"
            Source = Join-Path -Path $templatesRoot -ChildPath "n8n-script/new/prompt.js"
        },
        @{
            Path   = Join-Path -Path $templatesRoot -ChildPath "n8n-workflow/new/hello.ejs.t"
            Source = Join-Path -Path $templatesRoot -ChildPath "n8n-workflow/new/hello.ejs.t"
        },
        @{
            Path   = Join-Path -Path $templatesRoot -ChildPath "n8n-workflow/new/prompt.js"
            Source = Join-Path -Path $templatesRoot -ChildPath "n8n-workflow/new/prompt.js"
        },
        @{
            Path   = Join-Path -Path $templatesRoot -ChildPath "n8n-doc/new/hello.ejs.t"
            Source = Join-Path -Path $templatesRoot -ChildPath "n8n-doc/new/hello.ejs.t"
        },
        @{
            Path   = Join-Path -Path $templatesRoot -ChildPath "n8n-doc/new/prompt.js"
            Source = Join-Path -Path $templatesRoot -ChildPath "n8n-doc/new/prompt.js"
        },
        @{
            Path   = Join-Path -Path $templatesRoot -ChildPath "n8n-integration/new/hello.ejs.t"
            Source = Join-Path -Path $templatesRoot -ChildPath "n8n-integration/new/hello.ejs.t"
        },
        @{
            Path   = Join-Path -Path $templatesRoot -ChildPath "n8n-integration/new/prompt.js"
            Source = Join-Path -Path $templatesRoot -ChildPath "n8n-integration/new/prompt.js"
        }
    )

    foreach ($file in $templateFiles) {
        $fileExists = Test-AndCreateFile -Path $file.Path -SourcePath $file.Source -Fix:$Fix
        $success = $success -and $fileExists
    }

    return $success
}

# Fonction principale
function Start-Validation {
    Write-Info "Validation de la structure de dossiers pour Hygen..."

    $folderStructureValid = Test-FolderStructure -Fix:$Fix
    $filesValid = Test-RequiredFiles -Fix:$Fix

    # Afficher le résultat global
    Write-Host "`nRésultat de la validation:" -ForegroundColor $infoColor
    if ($folderStructureValid -and $filesValid) {
        Write-Success "La structure de dossiers et les fichiers sont valides"
        return $true
    } else {
        Write-Error "La structure de dossiers ou les fichiers sont invalides"

        # Afficher les recommandations
        Write-Info "`nRecommandations:"
        if (-not $folderStructureValid) {
            Write-Info "- Exécutez 'n8n\scripts\setup\ensure-hygen-structure.ps1' pour créer la structure de dossiers"
        }
        if (-not $filesValid) {
            Write-Info "- Exécutez 'n8n\scripts\setup\install-hygen.ps1' pour installer tous les fichiers nécessaires"
        }

        return $false
    }
}

# Exécuter la validation
Start-Validation
