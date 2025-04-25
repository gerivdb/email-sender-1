<#
.SYNOPSIS
    Script d'installation du module AugmentMemoriesManager.

.DESCRIPTION
    Ce script installe le module AugmentMemoriesManager dans le dossier des modules PowerShell
    de l'utilisateur et exécute les tests pour vérifier son bon fonctionnement.

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

# Définir les chemins
$scriptRoot = $PSScriptRoot
$moduleName = "AugmentMemoriesManager"
$modulePath = Join-Path -Path $scriptRoot -ChildPath "$moduleName.ps1"
$moduleDestination = Join-Path -Path $env:USERPROFILE -ChildPath "Documents\WindowsPowerShell\Modules\$moduleName"

# Vérifier si le module existe
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module $moduleName.ps1 non trouvé à l'emplacement: $modulePath"
    exit 1
}

# Créer le dossier de destination si nécessaire
if (-not (Test-Path -Path $moduleDestination)) {
    Write-Host "Création du dossier de destination: $moduleDestination" -ForegroundColor Cyan
    New-Item -Path $moduleDestination -ItemType Directory -Force | Out-Null
}
elseif ((Test-Path -Path "$moduleDestination\$moduleName.ps1") -and -not $Force) {
    Write-Warning "Le module $moduleName existe déjà à l'emplacement: $moduleDestination"
    $confirmation = Read-Host "Voulez-vous le remplacer? (O/N)"
    if ($confirmation -ne "O") {
        Write-Host "Installation annulée." -ForegroundColor Yellow
        exit 0
    }
}

# Copier le module
Write-Host "Copie du module $moduleName vers: $moduleDestination" -ForegroundColor Cyan
Copy-Item -Path $modulePath -Destination "$moduleDestination\$moduleName.ps1" -Force

# Créer le fichier de manifeste
$manifestPath = "$moduleDestination\$moduleName.psd1"
Write-Host "Création du manifeste de module: $manifestPath" -ForegroundColor Cyan

$manifestParams = @{
    Path              = $manifestPath
    RootModule        = "$moduleName.ps1"
    ModuleVersion     = "1.0.0"
    Author            = "Augment Agent"
    Description       = "Module de gestion des MEMORIES d'Augment avec fonctionnalités d'automate d'état et de segmentation proactive."
    PowerShellVersion = "5.1"
    FunctionsToExport = @("Move-NextTask", "Split-LargeInput", "Update-AugmentMemories", "Export-MemoriesToVSCode", "Invoke-MemoriesManagerTests")
}

New-ModuleManifest @manifestParams

# Exécuter les tests si demandé
if (-not $SkipTests) {
    Write-Host "Exécution des tests du module..." -ForegroundColor Cyan
    
    # Vérifier si Pester est installé
    if (-not (Get-Module -ListAvailable -Name Pester)) {
        Write-Warning "Module Pester non trouvé. Installation en cours..."
        Install-Module -Name Pester -Force -SkipPublisherCheck
    }
    
    # Importer le module
    Import-Module $moduleName -Force
    
    # Exécuter les tests
    Invoke-MemoriesManagerTests
}

Write-Host "Installation du module $moduleName terminée avec succès." -ForegroundColor Green
Write-Host "Pour utiliser le module, exécutez: Import-Module $moduleName" -ForegroundColor Green
