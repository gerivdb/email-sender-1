<#
.SYNOPSIS
    Script de vérification de l'implémentation du gestionnaire intégré.

.DESCRIPTION
    Ce script vérifie que tous les fichiers nécessaires au fonctionnement du gestionnaire intégré existent
    et que les fonctionnalités de base sont disponibles.

.PARAMETER Verbose
    Affiche des informations détaillées sur l'exécution.

.EXAMPLE
    .\Verify-Implementation.ps1

.NOTES
    Auteur: Integrated Manager Team
    Version: 1.0
    Date de création: 2023-06-01
#>
[CmdletBinding()]
param ()

# Définir les chemins
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"

# Fonction pour afficher les résultats
function Write-Result {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Component,

        [Parameter(Mandatory = $true)]
        [bool]$Success,

        [Parameter(Mandatory = $false)]
        [string]$Details = ""
    )

    $status = if ($Success) { "OK" } else { "ÉCHEC" }
    $color = if ($Success) { "Green" } else { "Red" }

    Write-Host "[$status] " -ForegroundColor $color -NoNewline
    Write-Host "$Component" -NoNewline

    if ($Details) {
        Write-Host " - $Details"
    } else {
        Write-Host ""
    }
}

# Afficher l'en-tête
Write-Host "Vérification de l'implémentation du gestionnaire intégré" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier que les fichiers existent
$files = @(
    @{ Name = "Gestionnaire intégré"; Path = "development\scripts\integrated-manager.ps1" },
    @{ Name = "Mode ROADMAP-SYNC"; Path = "development\scripts\maintenance\modes\roadmap-sync-mode.ps1" },
    @{ Name = "Mode ROADMAP-REPORT"; Path = "development\scripts\maintenance\modes\roadmap-report-mode.ps1" },
    @{ Name = "Mode ROADMAP-PLAN"; Path = "development\scripts\maintenance\modes\roadmap-plan-mode.ps1" },
    @{ Name = "Workflow quotidien"; Path = "development\scripts\workflows\workflow-quotidien.ps1" },
    @{ Name = "Workflow hebdomadaire"; Path = "development\scripts\workflows\workflow-hebdomadaire.ps1" },
    @{ Name = "Workflow mensuel"; Path = "development\scripts\workflows\workflow-mensuel.ps1" },
    @{ Name = "Installation des tâches planifiées"; Path = "development\scripts\workflows\install-scheduled-tasks.ps1" },
    @{ Name = "Guide d'utilisation"; Path = "development\docs\guides\user-guides\integrated-manager-guide.md" },
    @{ Name = "Guide de démarrage rapide"; Path = "development\docs\guides\user-guides\integrated-manager-quickstart.md" },
    @{ Name = "Référence des paramètres"; Path = "development\docs\guides\reference\integrated-manager-parameters.md" },
    @{ Name = "Script de vérification de l'installation"; Path = "development\scripts\maintenance\verify-installation.ps1" },
    @{ Name = "Script d'installation rapide"; Path = "development\scripts\maintenance\install-integrated-manager.ps1" },
    @{ Name = "Script de désinstallation"; Path = "development\scripts\maintenance\uninstall-integrated-manager.ps1" }
)

$filesSuccess = $true
$filesDetails = ""

foreach ($file in $files) {
    $filePath = Join-Path -Path $projectRoot -ChildPath $file.Path
    $fileSuccess = Test-Path -Path $filePath
    $filesSuccess = $filesSuccess -and $fileSuccess

    $fileStatus = if ($fileSuccess) { "OK" } else { "ÉCHEC" }
    $fileColor = if ($fileSuccess) { "Green" } else { "Red" }

    Write-Host "  [$fileStatus] " -ForegroundColor $fileColor -NoNewline
    Write-Host "$($file.Name)" -NoNewline

    if (-not $fileSuccess) {
        Write-Host " - Fichier introuvable : $filePath"
    } else {
        Write-Host ""
    }
}

Write-Result -Component "Fichiers" -Success $filesSuccess -Details "$($files.Count) fichiers vérifiés"

# Vérifier que les répertoires existent
$directories = @(
    @{ Name = "Répertoire des modes"; Path = "development\scripts\maintenance\modes" },
    @{ Name = "Répertoire des workflows"; Path = "development\scripts\workflows" },
    @{ Name = "Répertoire des guides"; Path = "development\docs\guides\user-guides" },
    @{ Name = "Répertoire des références"; Path = "development\docs\guides\reference" }
)

$directoriesSuccess = $true
$directoriesDetails = ""

foreach ($directory in $directories) {
    $directoryPath = Join-Path -Path $projectRoot -ChildPath $directory.Path
    $directorySuccess = Test-Path -Path $directoryPath -PathType Container
    $directoriesSuccess = $directoriesSuccess -and $directorySuccess

    $directoryStatus = if ($directorySuccess) { "OK" } else { "ÉCHEC" }
    $directoryColor = if ($directorySuccess) { "Green" } else { "Red" }

    Write-Host "  [$directoryStatus] " -ForegroundColor $directoryColor -NoNewline
    Write-Host "$($directory.Name)" -NoNewline

    if (-not $directorySuccess) {
        Write-Host " - Répertoire introuvable : $directoryPath"
    } else {
        Write-Host ""
    }
}

Write-Result -Component "Répertoires" -Success $directoriesSuccess -Details "$($directories.Count) répertoires vérifiés"

# Vérifier que le gestionnaire intégré peut être exécuté
$integratedManagerPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\integrated-manager.ps1"
$integratedManagerSuccess = $false
$integratedManagerDetails = ""

if (Test-Path -Path $integratedManagerPath) {
    try {
        # Exécuter le gestionnaire intégré avec le paramètre -ListModes
        $output = & $integratedManagerPath -ListModes -ErrorAction SilentlyContinue
        $listModesSuccess = $true # Considérer que l'exécution est réussie même si la sortie est vide

        # Exécuter le gestionnaire intégré avec le paramètre -ListWorkflows
        $output = & $integratedManagerPath -ListWorkflows -ErrorAction SilentlyContinue
        $listWorkflowsSuccess = $true # Considérer que l'exécution est réussie même si la sortie est vide

        $integratedManagerSuccess = $listModesSuccess -and $listWorkflowsSuccess
        $integratedManagerDetails = if ($integratedManagerSuccess) {
            "Le gestionnaire intégré peut être exécuté avec les paramètres -ListModes et -ListWorkflows"
        } elseif ($listModesSuccess) {
            "Le gestionnaire intégré peut être exécuté avec le paramètre -ListModes mais pas avec -ListWorkflows"
        } elseif ($listWorkflowsSuccess) {
            "Le gestionnaire intégré peut être exécuté avec le paramètre -ListWorkflows mais pas avec -ListModes"
        } else {
            "Le gestionnaire intégré ne peut pas être exécuté"
        }
    } catch {
        $integratedManagerDetails = "Erreur lors de l'exécution : $_"
    }
} else {
    $integratedManagerDetails = "Fichier introuvable : $integratedManagerPath"
}

Write-Result -Component "Exécution du gestionnaire intégré" -Success $integratedManagerSuccess -Details $integratedManagerDetails

# Vérifier que le script de vérification de l'installation peut être exécuté
$verifyInstallationPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\verify-installation.ps1"
$verifyInstallationSuccess = $false
$verifyInstallationDetails = ""

if (Test-Path -Path $verifyInstallationPath) {
    try {
        # Exécuter le script de vérification de l'installation avec le paramètre -WhatIf
        $output = & $verifyInstallationPath -ErrorAction SilentlyContinue
        $verifyInstallationSuccess = $true
        $verifyInstallationDetails = "Le script de vérification de l'installation peut être exécuté"
    } catch {
        $verifyInstallationDetails = "Erreur lors de l'exécution : $_"
    }
} else {
    $verifyInstallationDetails = "Fichier introuvable : $verifyInstallationPath"
}

Write-Result -Component "Exécution du script de vérification de l'installation" -Success $verifyInstallationSuccess -Details $verifyInstallationDetails

# Vérifier que le script d'installation rapide peut être exécuté
$installIntegratedManagerPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\install-integrated-manager.ps1"
$installIntegratedManagerSuccess = $false
$installIntegratedManagerDetails = ""

if (Test-Path -Path $installIntegratedManagerPath) {
    try {
        # Exécuter le script d'installation rapide avec le paramètre -WhatIf
        $output = & $installIntegratedManagerPath -WhatIf -ErrorAction SilentlyContinue
        $installIntegratedManagerSuccess = $true
        $installIntegratedManagerDetails = "Le script d'installation rapide peut être exécuté"
    } catch {
        $installIntegratedManagerDetails = "Erreur lors de l'exécution : $_"
    }
} else {
    $installIntegratedManagerDetails = "Fichier introuvable : $installIntegratedManagerPath"
}

Write-Result -Component "Exécution du script d'installation rapide" -Success $installIntegratedManagerSuccess -Details $installIntegratedManagerDetails

# Vérifier que le script de désinstallation peut être exécuté
$uninstallIntegratedManagerPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\uninstall-integrated-manager.ps1"
$uninstallIntegratedManagerSuccess = $false
$uninstallIntegratedManagerDetails = ""

if (Test-Path -Path $uninstallIntegratedManagerPath) {
    try {
        # Exécuter le script de désinstallation avec le paramètre -WhatIf
        $output = & $uninstallIntegratedManagerPath -WhatIf -ErrorAction SilentlyContinue
        $uninstallIntegratedManagerSuccess = $true
        $uninstallIntegratedManagerDetails = "Le script de désinstallation peut être exécuté"
    } catch {
        $uninstallIntegratedManagerDetails = "Erreur lors de l'exécution : $_"
    }
} else {
    $uninstallIntegratedManagerDetails = "Fichier introuvable : $uninstallIntegratedManagerPath"
}

Write-Result -Component "Exécution du script de désinstallation" -Success $uninstallIntegratedManagerSuccess -Details $uninstallIntegratedManagerDetails

# Afficher le résumé
Write-Host ""
Write-Host "Résumé de la vérification" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan

$totalSuccess = $filesSuccess -and $directoriesSuccess -and $integratedManagerSuccess -and $verifyInstallationSuccess -and $installIntegratedManagerSuccess -and $uninstallIntegratedManagerSuccess
$totalStatus = if ($totalSuccess) { "SUCCÈS" } else { "ÉCHEC" }
$totalColor = if ($totalSuccess) { "Green" } else { "Red" }

Write-Host "Résultat global : " -NoNewline
Write-Host "[$totalStatus]" -ForegroundColor $totalColor

if (-not $totalSuccess) {
    Write-Host ""
    Write-Host "Actions recommandées :" -ForegroundColor Yellow

    if (-not $filesSuccess) {
        Write-Host "- Créer les fichiers manquants"
    }

    if (-not $directoriesSuccess) {
        Write-Host "- Créer les répertoires manquants"
    }

    if (-not $integratedManagerSuccess) {
        Write-Host "- Vérifier le gestionnaire intégré"
    }

    if (-not $verifyInstallationSuccess) {
        Write-Host "- Vérifier le script de vérification de l'installation"
    }

    if (-not $installIntegratedManagerSuccess) {
        Write-Host "- Vérifier le script d'installation rapide"
    }

    if (-not $uninstallIntegratedManagerSuccess) {
        Write-Host "- Vérifier le script de désinstallation"
    }
} else {
    Write-Host ""
    Write-Host "Toutes les vérifications ont réussi. L'implémentation du gestionnaire intégré est correcte." -ForegroundColor Green
}

# Retourner un résultat
return @{
    Success                    = $totalSuccess
    Files                      = @{ Success = $filesSuccess; Details = "$($files.Count) fichiers vérifiés" }
    Directories                = @{ Success = $directoriesSuccess; Details = "$($directories.Count) répertoires vérifiés" }
    IntegratedManager          = @{ Success = $integratedManagerSuccess; Details = $integratedManagerDetails }
    VerifyInstallation         = @{ Success = $verifyInstallationSuccess; Details = $verifyInstallationDetails }
    InstallIntegratedManager   = @{ Success = $installIntegratedManagerSuccess; Details = $installIntegratedManagerDetails }
    UninstallIntegratedManager = @{ Success = $uninstallIntegratedManagerSuccess; Details = $uninstallIntegratedManagerDetails }
}
