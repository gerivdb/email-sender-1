<#
.SYNOPSIS
    Script de vérification de l'installation de Hygen.

.DESCRIPTION
    Ce script vérifie que Hygen est correctement installé et accessible.
    Il vérifie également que la structure de dossiers nécessaire est en place.

.PARAMETER Verbose
    Affiche des informations détaillées sur l'exécution.

.EXAMPLE
    .\verify-hygen-installation.ps1
    Vérifie l'installation de Hygen.

.NOTES
    Auteur: Équipe n8n
    Date de création: 2023-05-08
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param ()

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

# Fonction pour vérifier si Hygen est installé
function Test-HygenInstallation {
    try {
        $output = npx hygen --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Hygen est installé (version: $output)"
            return $true
        } else {
            Write-Error "Hygen n'est pas installé ou n'est pas accessible"
            return $false
        }
    } catch {
        Write-Error "Erreur lors de la vérification de l'installation de Hygen: $_"
        return $false
    }
}

# Fonction pour vérifier si la structure de dossiers est en place
function Test-FolderStructure {
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $projectRoot = (Get-Item $scriptPath).Parent.Parent.Parent.FullName
    $n8nRoot = Join-Path -Path $projectRoot -ChildPath "n8n"
    $templatesRoot = Join-Path -Path $projectRoot -ChildPath "n8n/_templates"

    $success = $true

    # Vérifier si le dossier _templates existe
    if (Test-Path -Path $templatesRoot) {
        Write-Success "Le dossier _templates existe"

        # Vérifier si les dossiers de templates existent
        $templateFolders = @(
            "n8n-script",
            "n8n-workflow",
            "n8n-doc",
            "n8n-integration"
        )

        foreach ($folder in $templateFolders) {
            $folderPath = Join-Path -Path $templatesRoot -ChildPath $folder
            if (Test-Path -Path $folderPath) {
                Write-Success "Le dossier de template $folder existe"
            } else {
                Write-Error "Le dossier de template $folder n'existe pas"
                $success = $false
            }
        }
    } else {
        Write-Error "Le dossier _templates n'existe pas"
        $success = $false
    }

    # Vérifier si le dossier n8n existe
    if (Test-Path -Path $n8nRoot) {
        Write-Success "Le dossier n8n existe"

        # Vérifier si les dossiers nécessaires existent
        $n8nFolders = @(
            "automation",
            "core/workflows",
            "integrations",
            "docs",
            "scripts/setup",
            "scripts/utils",
            "cmd/utils",
            "tests/unit"
        )

        foreach ($folder in $n8nFolders) {
            $folderPath = Join-Path -Path $n8nRoot -ChildPath $folder
            if (Test-Path -Path $folderPath) {
                Write-Success "Le dossier n8n/$folder existe"
            } else {
                Write-Error "Le dossier n8n/$folder n'existe pas"
                $success = $false
            }
        }
    } else {
        Write-Error "Le dossier n8n n'existe pas"
        $success = $false
    }

    return $success
}

# Fonction pour vérifier si les scripts nécessaires existent
function Test-RequiredScripts {
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $projectRoot = (Get-Item $scriptPath).Parent.Parent.Parent.FullName
    $n8nRoot = Join-Path -Path $projectRoot -ChildPath "n8n"

    $success = $true

    # Liste des scripts nécessaires
    $requiredScripts = @(
        "scripts/setup/install-hygen.ps1",
        "scripts/setup/ensure-hygen-structure.ps1",
        "scripts/utils/Generate-N8nComponent.ps1",
        "cmd/utils/generate-component.cmd",
        "cmd/utils/install-hygen.cmd",
        "tests/Run-HygenTests.ps1"
    )

    foreach ($script in $requiredScripts) {
        $scriptPath = Join-Path -Path $n8nRoot -ChildPath $script
        if (Test-Path -Path $scriptPath) {
            Write-Success "Le script $script existe"
        } else {
            Write-Error "Le script $script n'existe pas"
            $success = $false
        }
    }

    return $success
}

# Fonction principale
function Start-Verification {
    Write-Info "Vérification de l'installation de Hygen..."
    $hygenInstalled = Test-HygenInstallation

    Write-Info "Vérification de la structure de dossiers..."
    $folderStructureValid = Test-FolderStructure

    Write-Info "Vérification des scripts nécessaires..."
    $scriptsValid = Test-RequiredScripts

    # Afficher le résultat global
    Write-Host "`nRésultat de la vérification:" -ForegroundColor $infoColor
    if ($hygenInstalled -and $folderStructureValid -and $scriptsValid) {
        Write-Success "L'installation de Hygen est complète et valide"
        return $true
    } else {
        Write-Error "L'installation de Hygen est incomplète ou invalide"

        # Afficher les recommandations
        Write-Info "`nRecommandations:"
        if (-not $hygenInstalled) {
            Write-Info "- Exécutez 'npm install --save-dev hygen' pour installer Hygen"
        }
        if (-not $folderStructureValid) {
            Write-Info "- Exécutez 'n8n\scripts\setup\ensure-hygen-structure.ps1' pour créer la structure de dossiers"
        }
        if (-not $scriptsValid) {
            Write-Info "- Exécutez 'n8n\scripts\setup\install-hygen.ps1' pour installer tous les scripts nécessaires"
        }

        return $false
    }
}

# Exécuter la vérification
Start-Verification
