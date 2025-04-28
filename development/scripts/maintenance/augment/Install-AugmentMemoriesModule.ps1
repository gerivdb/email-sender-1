<#
.SYNOPSIS
    Script d'installation du module AugmentMemoriesManager.

.DESCRIPTION
    Ce script installe le module AugmentMemoriesManager dans le dossier des modules PowerShell
    de l'utilisateur et exÃ©cute les tests pour vÃ©rifier son bon fonctionnement.

.NOTES
    Version: 1.0
    Date: 2025-04-20
    Auteur: Augment Agent
#>

[CmdletBinding()]
param (
    [Parameter()]
    [switch]$SkipTests,
    
    [Parameter()]
    [switch]$Force
)

# DÃ©finir les chemins
$scriptRoot = $PSScriptRoot
$moduleName = "AugmentMemoriesManager"
$modulePath = Join-Path -Path $scriptRoot -ChildPath "$moduleName.ps1"
$moduleDestination = Join-Path -Path $env:USERPROFILE -ChildPath "Documents\WindowsPowerShell\Modules\$moduleName"

# VÃ©rifier si le module existe
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module $moduleName.ps1 non trouvÃ© Ã  l'emplacement: $modulePath"
    exit 1
}

# CrÃ©er le dossier de destination si nÃ©cessaire
if (-not (Test-Path -Path $moduleDestination)) {
    Write-Host "CrÃ©ation du dossier de destination: $moduleDestination" -ForegroundColor Cyan
    New-Item -Path $moduleDestination -ItemType Directory -Force | Out-Null
}
elseif ((Test-Path -Path "$moduleDestination\$moduleName.ps1") -and -not $Force) {
    Write-Warning "Le module $moduleName existe dÃ©jÃ  Ã  l'emplacement: $moduleDestination"
    $confirmation = Read-Host "Voulez-vous le remplacer? (O/N)"
    if ($confirmation -ne "O") {
        Write-Host "Installation annulÃ©e." -ForegroundColor Yellow
        exit 0
    }
}

# Copier le module
Write-Host "Copie du module $moduleName vers: $moduleDestination" -ForegroundColor Cyan
Copy-Item -Path $modulePath -Destination "$moduleDestination\$moduleName.ps1" -Force

# CrÃ©er le fichier de manifeste
$manifestPath = "$moduleDestination\$moduleName.psd1"
Write-Host "CrÃ©ation du manifeste de module: $manifestPath" -ForegroundColor Cyan

$manifestParams = @{
    Path              = $manifestPath
    RootModule        = "$moduleName.ps1"
    ModuleVersion     = "1.0.0"
    Author            = "Augment Agent"
    Description       = "Module de gestion des MEMORIES d'Augment avec fonctionnalitÃ©s d'automate d'Ã©tat et de segmentation proactive."
    PowerShellVersion = "5.1"
    FunctionsToExport = @("Move-NextTask", "Split-LargeInput", "Update-AugmentMemories", "Export-MemoriesToVSCode", "Invoke-MemoriesManagerTests")
}

New-ModuleManifest @manifestParams

# ExÃ©cuter les tests si demandÃ©
if (-not $SkipTests) {
    Write-Host "ExÃ©cution des tests du module..." -ForegroundColor Cyan
    
    # VÃ©rifier si Pester est installÃ©
    if (-not (Get-Module -ListAvailable -Name Pester)) {
        Write-Warning "Module Pester non trouvÃ©. Installation en cours..."
        Install-Module -Name Pester -Force -SkipPublisherCheck
    }
    
    # Importer le module
    Import-Module $moduleName -Force
    
    # ExÃ©cuter les tests
    Invoke-MemoriesManagerTests
}

Write-Host "Installation du module $moduleName terminÃ©e avec succÃ¨s." -ForegroundColor Green
Write-Host "Pour utiliser le module, exÃ©cutez: Import-Module $moduleName" -ForegroundColor Green
