<#
.SYNOPSIS
    Installe le module d'intÃ©gration Augment.

.DESCRIPTION
    Ce script installe le module d'intÃ©gration Augment dans le rÃ©pertoire des modules PowerShell
    de l'utilisateur, permettant de l'utiliser facilement dans n'importe quel script PowerShell.

.PARAMETER Force
    Force la rÃ©installation du module mÃªme s'il est dÃ©jÃ  installÃ©.

.EXAMPLE
    .\Install-AugmentIntegration.ps1
    # Installe le module d'intÃ©gration Augment

.EXAMPLE
    .\Install-AugmentIntegration.ps1 -Force
    # Force la rÃ©installation du module d'intÃ©gration Augment

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

# DÃ©terminer le chemin du projet
$projectRoot = $PSScriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    if (-not (Test-Path -Path $projectRoot -PathType Container)) {
        Write-Error "Impossible de dÃ©terminer le chemin du projet."
        exit 1
    }
}

# Chemin vers le module d'intÃ©gration Augment
$modulePath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\augment\AugmentIntegration.psm1"
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module d'intÃ©gration Augment introuvable : $modulePath"
    exit 1
}

# Chemin vers le rÃ©pertoire des modules PowerShell de l'utilisateur
$userModulesPath = $env:PSModulePath -split ';' | Where-Object { $_ -like "$env:USERPROFILE*" } | Select-Object -First 1
if (-not $userModulesPath) {
    $userModulesPath = Join-Path -Path $env:USERPROFILE -ChildPath "Documents\WindowsPowerShell\Modules"
}

# CrÃ©er le rÃ©pertoire des modules s'il n'existe pas
if (-not (Test-Path -Path $userModulesPath -PathType Container)) {
    New-Item -Path $userModulesPath -ItemType Directory -Force | Out-Null
    Write-Host "RÃ©pertoire des modules PowerShell crÃ©Ã© : $userModulesPath" -ForegroundColor Green
}

# Chemin vers le rÃ©pertoire du module AugmentIntegration
$moduleDir = Join-Path -Path $userModulesPath -ChildPath "AugmentIntegration"
if (-not (Test-Path -Path $moduleDir -PathType Container)) {
    New-Item -Path $moduleDir -ItemType Directory -Force | Out-Null
    Write-Host "RÃ©pertoire du module AugmentIntegration crÃ©Ã© : $moduleDir" -ForegroundColor Green
}

# VÃ©rifier si le module est dÃ©jÃ  installÃ©
$installedModulePath = Join-Path -Path $moduleDir -ChildPath "AugmentIntegration.psm1"
if (Test-Path -Path $installedModulePath) {
    if (-not $Force) {
        Write-Host "Le module AugmentIntegration est dÃ©jÃ  installÃ©." -ForegroundColor Yellow
        Write-Host "Utilisez le paramÃ¨tre -Force pour forcer la rÃ©installation." -ForegroundColor Yellow
        exit 0
    } else {
        Write-Host "RÃ©installation du module AugmentIntegration..." -ForegroundColor Cyan
    }
}

# Copier le module et les fichiers associÃ©s
try {
    # Copier le module principal
    Copy-Item -Path $modulePath -Destination $moduleDir -Force
    Write-Host "Module AugmentIntegration copiÃ© vers : $installedModulePath" -ForegroundColor Green
    
    # Copier les fichiers associÃ©s
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
            Write-Host "Fichier associÃ© copiÃ© : $file" -ForegroundColor Gray
        } else {
            Write-Warning "Fichier associÃ© introuvable : $file"
        }
    }
    
    # CrÃ©er le manifeste du module
    $manifestPath = Join-Path -Path $moduleDir -ChildPath "AugmentIntegration.psd1"
    $manifestParams = @{
        Path              = $manifestPath
        RootModule        = "AugmentIntegration.psm1"
        ModuleVersion     = "1.0.0"
        Author            = "Augment Agent"
        Description       = "Module d'intÃ©gration avec Augment Code"
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
    Write-Host "Manifeste du module crÃ©Ã© : $manifestPath" -ForegroundColor Green
    
    # CrÃ©er un script d'exemple
    $examplePath = Join-Path -Path $moduleDir -ChildPath "Example.ps1"
    $exampleContent = @"
# Exemple d'utilisation du module AugmentIntegration

# Importer le module
Import-Module AugmentIntegration

# Initialiser l'intÃ©gration avec Augment Code
Initialize-AugmentIntegration -StartServers

# ExÃ©cuter un mode spÃ©cifique
Invoke-AugmentMode -Mode GRAN -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3" -UpdateMemories

# Mettre Ã  jour les Memories pour un mode spÃ©cifique
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

# ArrÃªter les serveurs MCP
Stop-AugmentMCPServers
"@
    
    $exampleContent | Out-File -FilePath $examplePath -Encoding UTF8
    Write-Host "Script d'exemple crÃ©Ã© : $examplePath" -ForegroundColor Green
    
    Write-Host "`nModule AugmentIntegration installÃ© avec succÃ¨s." -ForegroundColor Green
    Write-Host "Pour l'utiliser, exÃ©cutez : Import-Module AugmentIntegration" -ForegroundColor Yellow
} catch {
    Write-Error "Erreur lors de l'installation du module : $_"
    exit 1
}
