<#
.SYNOPSIS
    Phase 2 du Script Manager - Analyse et organisation avancÃ©es
.DESCRIPTION
    Ce script exÃ©cute la Phase 2 du Script Manager, qui comprend l'analyse
    approfondie des scripts et l'organisation intelligente selon les principes
    SOLID, DRY, KISS et Clean Code.
.PARAMETER InventoryPath
    Chemin vers le fichier d'inventaire (par dÃ©faut : ..\D)
.PARAMETER RulesPath
    Chemin vers le fichier de rÃ¨gles (par dÃ©faut : ..\D)
.PARAMETER AnalysisDepth
    Niveau de profondeur de l'analyse (Basic, Standard, Advanced)
.PARAMETER AutoApply
    Applique automatiquement les recommandations d'organisation
.EXAMPLE
    .\Phase2-AnalyzeAndOrganize.ps1
    ExÃ©cute la Phase 2 en mode simulation (sans appliquer les changements)
.EXAMPLE
    .\Phase2-AnalyzeAndOrganize.ps1 -AnalysisDepth Advanced -AutoApply
    ExÃ©cute la Phase 2 avec une analyse approfondie et applique les changements
#>

param (
    [string]$InventoryPath = "..\D",
    [string]$RulesPath = "..\D",
    [ValidateSet("Basic", "Standard", "Advanced")]
    [string]$AnalysisDepth = "Standard",
    [switch]$AutoApply
)

# VÃ©rifier si l'inventaire existe
if (-not (Test-Path -Path $InventoryPath)) {
    Write-Host "Inventaire non trouvÃ©. Veuillez d'abord exÃ©cuter la Phase 1 (Inventory-Scripts.ps1)." -ForegroundColor Red
    exit 1
}

# VÃ©rifier si le fichier de rÃ¨gles existe
if (-not (Test-Path -Path $RulesPath)) {
    Write-Host "Fichier de rÃ¨gles non trouvÃ©: $RulesPath" -ForegroundColor Red
    exit 1
}

# DÃ©finir les chemins des modules
$ModulesPath = Join-Path -Path $PSScriptRoot -ChildPath "modules"
$AnalysisModulePath = Join-Path -Path $ModulesPath -ChildPath "Analysis\AnalysisModule.psm1"
$OrganizationModulePath = Join-Path -Path $ModulesPath -ChildPath "Organization\OrganizationModule.psm1"

# VÃ©rifier si les modules existent
if (-not (Test-Path -Path $AnalysisModulePath)) {
    Write-Host "Module d'analyse non trouvÃ©: $AnalysisModulePath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path -Path $OrganizationModulePath)) {
    Write-Host "Module d'organisation non trouvÃ©: $OrganizationModulePath" -ForegroundColor Red
    exit 1
}

# Importer les modules
Import-Module $AnalysisModulePath -Force
Import-Module $OrganizationModulePath -Force

# DÃ©finir les chemins de sortie
$AnalysisPath = "scripts\manager\data\analysis_advanced.json"
$OrganizationPath = "scripts\manager\data\organization_advanced.json"

# Afficher la banniÃ¨re
Write-Host "=== Phase 2: Analyse et organisation avancÃ©es ===" -ForegroundColor Cyan
Write-Host "Inventaire: $InventoryPath" -ForegroundColor Yellow
Write-Host "RÃ¨gles: $RulesPath" -ForegroundColor Yellow
Write-Host "Niveau d'analyse: $AnalysisDepth" -ForegroundColor Yellow
Write-Host "Mode: $(if ($AutoApply) { 'Application automatique' } else { 'Simulation' })" -ForegroundColor Yellow
Write-Host ""

# Ã‰tape 1: Analyse approfondie des scripts
Write-Host "Ã‰tape 1: Analyse approfondie des scripts" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host ""

$Analysis = Invoke-ScriptAnalysis -InventoryPath $InventoryPath -OutputPath $AnalysisPath -Depth $AnalysisDepth

if ($null -eq $Analysis) {
    Write-Host "Erreur lors de l'analyse des scripts." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Analyse terminÃ©e. RÃ©sultats enregistrÃ©s dans: $AnalysisPath" -ForegroundColor Green
Write-Host "Nombre de scripts analysÃ©s: $($Analysis.TotalScripts)" -ForegroundColor Cyan
Write-Host "Scripts avec problÃ¨mes: $($Analysis.ScriptsWithProblems)" -ForegroundColor $(if ($Analysis.ScriptsWithProblems -gt 0) { "Yellow" } else { "Green" })
Write-Host "Scripts avec dÃ©pendances: $($Analysis.ScriptsWithDependencies)" -ForegroundColor Cyan
Write-Host "Score de qualitÃ© moyen: $([math]::Round($Analysis.AverageCodeQuality, 2))" -ForegroundColor $(if ($Analysis.AverageCodeQuality -lt 70) { "Yellow" } elseif ($Analysis.AverageCodeQuality -lt 50) { "Red" } else { "Green" })
Write-Host ""

# Ã‰tape 2: Organisation intelligente des scripts
Write-Host "Ã‰tape 2: Organisation intelligente des scripts" -ForegroundColor Cyan
Write-Host "---------------------------------------------" -ForegroundColor Cyan
Write-Host ""

$Organization = Invoke-ScriptOrganization -AnalysisPath $AnalysisPath -RulesPath $RulesPath -OutputPath $OrganizationPath -AutoApply:$AutoApply

if ($null -eq $Organization) {
    Write-Host "Erreur lors de l'organisation des scripts." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Organisation terminÃ©e. RÃ©sultats enregistrÃ©s dans: $OrganizationPath" -ForegroundColor Green
Write-Host "Nombre total de scripts: $($Organization.TotalScripts)" -ForegroundColor Cyan
Write-Host "Scripts Ã  dÃ©placer: $($Organization.ScriptsToMove)" -ForegroundColor Yellow
Write-Host "Scripts dÃ©placÃ©s: $($Organization.ScriptsMoved)" -ForegroundColor $(if ($Organization.ScriptsMoved -gt 0) { "Green" } else { "Cyan" })
Write-Host ""

# RÃ©sumÃ©
Write-Host "=== RÃ©sumÃ© de la Phase 2 ===" -ForegroundColor Cyan
Write-Host "Analyse approfondie: $($Analysis.TotalScripts) scripts analysÃ©s" -ForegroundColor Cyan
Write-Host "Organisation intelligente: $($Organization.ScriptsToMove) scripts Ã  organiser" -ForegroundColor Cyan
Write-Host ""

if (-not $AutoApply) {
    Write-Host "Pour appliquer les recommandations d'organisation, exÃ©cutez la commande suivante:" -ForegroundColor Yellow
    Write-Host ".\Phase2-AnalyzeAndOrganize.ps1 -AnalysisDepth $AnalysisDepth -AutoApply" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Phase 2 terminÃ©e avec succÃ¨s!" -ForegroundColor Green

