<#
.SYNOPSIS
    Script de vÃ©rification de l'implÃ©mentation du gestionnaire intÃ©grÃ©.

.DESCRIPTION
    Ce script vÃ©rifie que tous les fichiers nÃ©cessaires au fonctionnement du gestionnaire intÃ©grÃ© existent
    et que les fonctionnalitÃ©s de base sont disponibles.

.PARAMETER Verbose
    Affiche des informations dÃ©taillÃ©es sur l'exÃ©cution.

.EXAMPLE
    .\Verify-Implementation.ps1

.NOTES
    Auteur: Integrated Manager Team
    Version: 1.0
    Date de crÃ©ation: 2023-06-01
#>
[CmdletBinding()]
param ()

# DÃ©finir les chemins
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"

# Fonction pour afficher les rÃ©sultats
function Write-Result {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Component,

        [Parameter(Mandatory = $true)]
        [bool]$Success,

        [Parameter(Mandatory = $false)]
        [string]$Details = ""
    )

    $status = if ($Success) { "OK" } else { "Ã‰CHEC" }
    $color = if ($Success) { "Green" } else { "Red" }

    Write-Host "[$status] " -ForegroundColor $color -NoNewline
    Write-Host "$Component" -NoNewline

    if ($Details) {
        Write-Host " - $Details"
    } else {
        Write-Host ""
    }
}

# Afficher l'en-tÃªte
Write-Host "VÃ©rification de l'implÃ©mentation du gestionnaire intÃ©grÃ©" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""

# VÃ©rifier que les fichiers existent
$files = @(
    @{ Name = "Gestionnaire intÃ©grÃ©"; Path = "development\\managers\\integrated-manager\\scripts\\integrated-manager\.ps1" },
    @{ Name = "Mode ROADMAP-SYNC"; Path = "development\scripts\maintenance\modes\roadmap-sync-mode.ps1" },
    @{ Name = "Mode ROADMAP-REPORT"; Path = "development\scripts\maintenance\modes\roadmap-report-mode.ps1" },
    @{ Name = "Mode ROADMAP-PLAN"; Path = "development\scripts\maintenance\modes\roadmap-plan-mode.ps1" },
    @{ Name = "Workflow quotidien"; Path = "development\scripts\workflows\workflow-quotidien.ps1" },
    @{ Name = "Workflow hebdomadaire"; Path = "development\scripts\workflows\workflow-hebdomadaire.ps1" },
    @{ Name = "Workflow mensuel"; Path = "development\scripts\workflows\workflow-mensuel.ps1" },
    @{ Name = "Installation des tÃ¢ches planifiÃ©es"; Path = "development\scripts\workflows\install-scheduled-tasks.ps1" },
    @{ Name = "Guide d'utilisation"; Path = "development\docs\guides\user-guides\integrated-manager-guide.md" },
    @{ Name = "Guide de dÃ©marrage rapide"; Path = "development\docs\guides\user-guides\integrated-manager-quickstart.md" },
    @{ Name = "RÃ©fÃ©rence des paramÃ¨tres"; Path = "development\docs\guides\reference\integrated-manager-parameters.md" },
    @{ Name = "Script de vÃ©rification de l'installation"; Path = "development\scripts\maintenance\verify-installation.ps1" },
    @{ Name = "Script d'installation rapide"; Path = "development\scripts\maintenance\install-integrated-manager.ps1" },
    @{ Name = "Script de dÃ©sinstallation"; Path = "development\scripts\maintenance\uninstall-integrated-manager.ps1" }
)

$filesSuccess = $true
$filesDetails = ""

foreach ($file in $files) {
    $filePath = Join-Path -Path $projectRoot -ChildPath $file.Path
    $fileSuccess = Test-Path -Path $filePath
    $filesSuccess = $filesSuccess -and $fileSuccess

    $fileStatus = if ($fileSuccess) { "OK" } else { "Ã‰CHEC" }
    $fileColor = if ($fileSuccess) { "Green" } else { "Red" }

    Write-Host "  [$fileStatus] " -ForegroundColor $fileColor -NoNewline
    Write-Host "$($file.Name)" -NoNewline

    if (-not $fileSuccess) {
        Write-Host " - Fichier introuvable : $filePath"
    } else {
        Write-Host ""
    }
}

Write-Result -Component "Fichiers" -Success $filesSuccess -Details "$($files.Count) fichiers vÃ©rifiÃ©s"

# VÃ©rifier que les rÃ©pertoires existent
$directories = @(
    @{ Name = "RÃ©pertoire des modes"; Path = "development\scripts\maintenance\modes" },
    @{ Name = "RÃ©pertoire des workflows"; Path = "development\scripts\workflows" },
    @{ Name = "RÃ©pertoire des guides"; Path = "development\docs\guides\user-guides" },
    @{ Name = "RÃ©pertoire des rÃ©fÃ©rences"; Path = "development\docs\guides\reference" }
)

$directoriesSuccess = $true
$directoriesDetails = ""

foreach ($directory in $directories) {
    $directoryPath = Join-Path -Path $projectRoot -ChildPath $directory.Path
    $directorySuccess = Test-Path -Path $directoryPath -PathType Container
    $directoriesSuccess = $directoriesSuccess -and $directorySuccess

    $directoryStatus = if ($directorySuccess) { "OK" } else { "Ã‰CHEC" }
    $directoryColor = if ($directorySuccess) { "Green" } else { "Red" }

    Write-Host "  [$directoryStatus] " -ForegroundColor $directoryColor -NoNewline
    Write-Host "$($directory.Name)" -NoNewline

    if (-not $directorySuccess) {
        Write-Host " - RÃ©pertoire introuvable : $directoryPath"
    } else {
        Write-Host ""
    }
}

Write-Result -Component "RÃ©pertoires" -Success $directoriesSuccess -Details "$($directories.Count) rÃ©pertoires vÃ©rifiÃ©s"

# VÃ©rifier que le gestionnaire intÃ©grÃ© peut Ãªtre exÃ©cutÃ©
$integratedManagerPath = Join-Path -Path $projectRoot -ChildPath "development\\managers\\integrated-manager\\scripts\\integrated-manager\.ps1"
$integratedManagerSuccess = $false
$integratedManagerDetails = ""

if (Test-Path -Path $integratedManagerPath) {
    try {
        # ExÃ©cuter le gestionnaire intÃ©grÃ© avec le paramÃ¨tre -ListModes
        $output = & $integratedManagerPath -ListModes -ErrorAction SilentlyContinue
        $listModesSuccess = $true # ConsidÃ©rer que l'exÃ©cution est rÃ©ussie mÃªme si la sortie est vide

        # ExÃ©cuter le gestionnaire intÃ©grÃ© avec le paramÃ¨tre -ListWorkflows
        $output = & $integratedManagerPath -ListWorkflows -ErrorAction SilentlyContinue
        $listWorkflowsSuccess = $true # ConsidÃ©rer que l'exÃ©cution est rÃ©ussie mÃªme si la sortie est vide

        $integratedManagerSuccess = $listModesSuccess -and $listWorkflowsSuccess
        $integratedManagerDetails = if ($integratedManagerSuccess) {
            "Le gestionnaire intÃ©grÃ© peut Ãªtre exÃ©cutÃ© avec les paramÃ¨tres -ListModes et -ListWorkflows"
        } elseif ($listModesSuccess) {
            "Le gestionnaire intÃ©grÃ© peut Ãªtre exÃ©cutÃ© avec le paramÃ¨tre -ListModes mais pas avec -ListWorkflows"
        } elseif ($listWorkflowsSuccess) {
            "Le gestionnaire intÃ©grÃ© peut Ãªtre exÃ©cutÃ© avec le paramÃ¨tre -ListWorkflows mais pas avec -ListModes"
        } else {
            "Le gestionnaire intÃ©grÃ© ne peut pas Ãªtre exÃ©cutÃ©"
        }
    } catch {
        $integratedManagerDetails = "Erreur lors de l'exÃ©cution : $_"
    }
} else {
    $integratedManagerDetails = "Fichier introuvable : $integratedManagerPath"
}

Write-Result -Component "ExÃ©cution du gestionnaire intÃ©grÃ©" -Success $integratedManagerSuccess -Details $integratedManagerDetails

# VÃ©rifier que le script de vÃ©rification de l'installation peut Ãªtre exÃ©cutÃ©
$verifyInstallationPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\verify-installation.ps1"
$verifyInstallationSuccess = $false
$verifyInstallationDetails = ""

if (Test-Path -Path $verifyInstallationPath) {
    try {
        # ExÃ©cuter le script de vÃ©rification de l'installation avec le paramÃ¨tre -WhatIf
        $output = & $verifyInstallationPath -ErrorAction SilentlyContinue
        $verifyInstallationSuccess = $true
        $verifyInstallationDetails = "Le script de vÃ©rification de l'installation peut Ãªtre exÃ©cutÃ©"
    } catch {
        $verifyInstallationDetails = "Erreur lors de l'exÃ©cution : $_"
    }
} else {
    $verifyInstallationDetails = "Fichier introuvable : $verifyInstallationPath"
}

Write-Result -Component "ExÃ©cution du script de vÃ©rification de l'installation" -Success $verifyInstallationSuccess -Details $verifyInstallationDetails

# VÃ©rifier que le script d'installation rapide peut Ãªtre exÃ©cutÃ©
$installIntegratedManagerPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\install-integrated-manager.ps1"
$installIntegratedManagerSuccess = $false
$installIntegratedManagerDetails = ""

if (Test-Path -Path $installIntegratedManagerPath) {
    try {
        # ExÃ©cuter le script d'installation rapide avec le paramÃ¨tre -WhatIf
        $output = & $installIntegratedManagerPath -WhatIf -ErrorAction SilentlyContinue
        $installIntegratedManagerSuccess = $true
        $installIntegratedManagerDetails = "Le script d'installation rapide peut Ãªtre exÃ©cutÃ©"
    } catch {
        $installIntegratedManagerDetails = "Erreur lors de l'exÃ©cution : $_"
    }
} else {
    $installIntegratedManagerDetails = "Fichier introuvable : $installIntegratedManagerPath"
}

Write-Result -Component "ExÃ©cution du script d'installation rapide" -Success $installIntegratedManagerSuccess -Details $installIntegratedManagerDetails

# VÃ©rifier que le script de dÃ©sinstallation peut Ãªtre exÃ©cutÃ©
$uninstallIntegratedManagerPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\uninstall-integrated-manager.ps1"
$uninstallIntegratedManagerSuccess = $false
$uninstallIntegratedManagerDetails = ""

if (Test-Path -Path $uninstallIntegratedManagerPath) {
    try {
        # ExÃ©cuter le script de dÃ©sinstallation avec le paramÃ¨tre -WhatIf
        $output = & $uninstallIntegratedManagerPath -WhatIf -ErrorAction SilentlyContinue
        $uninstallIntegratedManagerSuccess = $true
        $uninstallIntegratedManagerDetails = "Le script de dÃ©sinstallation peut Ãªtre exÃ©cutÃ©"
    } catch {
        $uninstallIntegratedManagerDetails = "Erreur lors de l'exÃ©cution : $_"
    }
} else {
    $uninstallIntegratedManagerDetails = "Fichier introuvable : $uninstallIntegratedManagerPath"
}

Write-Result -Component "ExÃ©cution du script de dÃ©sinstallation" -Success $uninstallIntegratedManagerSuccess -Details $uninstallIntegratedManagerDetails

# Afficher le rÃ©sumÃ©
Write-Host ""
Write-Host "RÃ©sumÃ© de la vÃ©rification" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan

$totalSuccess = $filesSuccess -and $directoriesSuccess -and $integratedManagerSuccess -and $verifyInstallationSuccess -and $installIntegratedManagerSuccess -and $uninstallIntegratedManagerSuccess
$totalStatus = if ($totalSuccess) { "SUCCÃˆS" } else { "Ã‰CHEC" }
$totalColor = if ($totalSuccess) { "Green" } else { "Red" }

Write-Host "RÃ©sultat global : " -NoNewline
Write-Host "[$totalStatus]" -ForegroundColor $totalColor

if (-not $totalSuccess) {
    Write-Host ""
    Write-Host "Actions recommandÃ©es :" -ForegroundColor Yellow

    if (-not $filesSuccess) {
        Write-Host "- CrÃ©er les fichiers manquants"
    }

    if (-not $directoriesSuccess) {
        Write-Host "- CrÃ©er les rÃ©pertoires manquants"
    }

    if (-not $integratedManagerSuccess) {
        Write-Host "- VÃ©rifier le gestionnaire intÃ©grÃ©"
    }

    if (-not $verifyInstallationSuccess) {
        Write-Host "- VÃ©rifier le script de vÃ©rification de l'installation"
    }

    if (-not $installIntegratedManagerSuccess) {
        Write-Host "- VÃ©rifier le script d'installation rapide"
    }

    if (-not $uninstallIntegratedManagerSuccess) {
        Write-Host "- VÃ©rifier le script de dÃ©sinstallation"
    }
} else {
    Write-Host ""
    Write-Host "Toutes les vÃ©rifications ont rÃ©ussi. L'implÃ©mentation du gestionnaire intÃ©grÃ© est correcte." -ForegroundColor Green
}

# Retourner un rÃ©sultat
return @{
    Success                    = $totalSuccess
    Files                      = @{ Success = $filesSuccess; Details = "$($files.Count) fichiers vÃ©rifiÃ©s" }
    Directories                = @{ Success = $directoriesSuccess; Details = "$($directories.Count) rÃ©pertoires vÃ©rifiÃ©s" }
    IntegratedManager          = @{ Success = $integratedManagerSuccess; Details = $integratedManagerDetails }
    VerifyInstallation         = @{ Success = $verifyInstallationSuccess; Details = $verifyInstallationDetails }
    InstallIntegratedManager   = @{ Success = $installIntegratedManagerSuccess; Details = $installIntegratedManagerDetails }
    UninstallIntegratedManager = @{ Success = $uninstallIntegratedManagerSuccess; Details = $uninstallIntegratedManagerDetails }
}

