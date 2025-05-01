<#
.SYNOPSIS
    Installe le module d'intégration Augment.

.DESCRIPTION
    Ce script installe le module d'intégration Augment dans le répertoire des modules PowerShell
    de l'utilisateur, permettant de l'utiliser facilement dans n'importe quel script PowerShell.

.PARAMETER Force
    Force la réinstallation du module même s'il est déjà installé.

.EXAMPLE
    .\Install-AugmentIntegration.ps1
    # Installe le module d'intégration Augment

.EXAMPLE
    .\Install-AugmentIntegration.ps1 -Force
    # Force la réinstallation du module d'intégration Augment

.NOTES
    Version: 1.0
    Date: 2025-06-01
    Auteur: Augment Agent
#>

[CmdletBinding()]
param (
    [Parameter()]
    [switch]$Force
)

# Déterminer le chemin du projet
$projectRoot = $PSScriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    if (-not (Test-Path -Path $projectRoot -PathType Container)) {
        Write-Error "Impossible de déterminer le chemin du projet."
        exit 1
    }
}

# Chemin vers le module d'intégration Augment
$modulePath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\augment\AugmentIntegration.psm1"
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module d'intégration Augment introuvable : $modulePath"
    exit 1
}

# Chemin vers le répertoire des modules PowerShell de l'utilisateur
$userModulesPath = $env:PSModulePath -split ';' | Where-Object { $_ -like "$env:USERPROFILE*" } | Select-Object -First 1
if (-not $userModulesPath) {
    $userModulesPath = Join-Path -Path $env:USERPROFILE -ChildPath "Documents\WindowsPowerShell\Modules"
}

# Créer le répertoire des modules s'il n'existe pas
if (-not (Test-Path -Path $userModulesPath -PathType Container)) {
    New-Item -Path $userModulesPath -ItemType Directory -Force | Out-Null
    Write-Host "Répertoire des modules PowerShell créé : $userModulesPath" -ForegroundColor Green
}

# Chemin vers le répertoire du module AugmentIntegration
$moduleDir = Join-Path -Path $userModulesPath -ChildPath "AugmentIntegration"
if (-not (Test-Path -Path $moduleDir -PathType Container)) {
    New-Item -Path $moduleDir -ItemType Directory -Force | Out-Null
    Write-Host "Répertoire du module AugmentIntegration créé : $moduleDir" -ForegroundColor Green
}

# Vérifier si le module est déjà installé
$installedModulePath = Join-Path -Path $moduleDir -ChildPath "AugmentIntegration.psm1"
if (Test-Path -Path $installedModulePath) {
    if (-not $Force) {
        Write-Host "Le module AugmentIntegration est déjà installé." -ForegroundColor Yellow
        Write-Host "Utilisez le paramètre -Force pour forcer la réinstallation." -ForegroundColor Yellow
        exit 0
    } else {
        Write-Host "Réinstallation du module AugmentIntegration..." -ForegroundColor Cyan
    }
}

# Copier le module et les fichiers associés
try {
    # Copier le module principal
    Copy-Item -Path $modulePath -Destination $moduleDir -Force
    Write-Host "Module AugmentIntegration copié vers : $installedModulePath" -ForegroundColor Green
    
    # Copier les fichiers associés
    $associatedFiles = @(
        "AugmentMemoriesManager.ps1",
        "mcp-memories-server.ps1",
        "mcp-mode-manager-adapter.ps1",
        "mode-manager-augment-integration.ps1",
        "optimize-augment-memories.ps1",
        "configure-augment-mcp.ps1",
        "start-mcp-servers.ps1",
        "analyze-augment-performance.ps1",
        "sync-memories-with-n8n.ps1"
    )
    
    foreach ($file in $associatedFiles) {
        $sourcePath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\augment\$file"
        if (Test-Path -Path $sourcePath) {
            Copy-Item -Path $sourcePath -Destination $moduleDir -Force
            Write-Host "Fichier associé copié : $file" -ForegroundColor Gray
        } else {
            Write-Warning "Fichier associé introuvable : $file"
        }
    }
    
    # Créer le manifeste du module
    $manifestPath = Join-Path -Path $moduleDir -ChildPath "AugmentIntegration.psd1"
    $manifestParams = @{
        Path              = $manifestPath
        RootModule        = "AugmentIntegration.psm1"
        ModuleVersion     = "1.0.0"
        Author            = "Augment Agent"
        Description       = "Module d'intégration avec Augment Code"
        PowerShellVersion = "5.1"
        FunctionsToExport = @(
            "Invoke-AugmentMode",
            "Start-AugmentMCPServers",
            "Stop-AugmentMCPServers",
            "Update-AugmentMemoriesForMode",
            "Split-AugmentInput",
            "Measure-AugmentInputSize",
            "Get-AugmentModeDescription",
            "Initialize-AugmentIntegration",
            "Analyze-AugmentPerformance"
        )
    }
    
    New-ModuleManifest @manifestParams
    Write-Host "Manifeste du module créé : $manifestPath" -ForegroundColor Green
    
    # Créer un script d'exemple
    $examplePath = Join-Path -Path $moduleDir -ChildPath "Example.ps1"
    $exampleContent = @"
# Exemple d'utilisation du module AugmentIntegration

# Importer le module
Import-Module AugmentIntegration

# Initialiser l'intégration avec Augment Code
Initialize-AugmentIntegration -StartServers

# Exécuter un mode spécifique
Invoke-AugmentMode -Mode GRAN -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3" -UpdateMemories

# Mettre à jour les Memories pour un mode spécifique
Update-AugmentMemoriesForMode -Mode GRAN

# Mesurer la taille d'un input
`$inputSize = Measure-AugmentInputSize -Input "Votre texte ici"
if (`$inputSize.IsOverLimit) {
    Write-Warning "Input trop volumineux: `$(`$inputSize.KiloBytes) KB"
}

# Diviser un input volumineux
`$segments = Split-AugmentInput -Input "Votre texte volumineux ici" -MaxSize 3000

# Analyser les performances d'Augment Code
Analyze-AugmentPerformance

# Arrêter les serveurs MCP
Stop-AugmentMCPServers
"@
    
    $exampleContent | Out-File -FilePath $examplePath -Encoding UTF8
    Write-Host "Script d'exemple créé : $examplePath" -ForegroundColor Green
    
    Write-Host "`nModule AugmentIntegration installé avec succès." -ForegroundColor Green
    Write-Host "Pour l'utiliser, exécutez : Import-Module AugmentIntegration" -ForegroundColor Yellow
} catch {
    Write-Error "Erreur lors de l'installation du module : $_"
    exit 1
}
