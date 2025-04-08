<#
.SYNOPSIS
    Phase 2 du Script Manager - Analyse et organisation avancées
.DESCRIPTION
    Ce script exécute la Phase 2 du Script Manager, qui comprend l'analyse
    approfondie des scripts et l'organisation intelligente selon les principes
    SOLID, DRY, KISS et Clean Code.
.PARAMETER InventoryPath
    Chemin vers le fichier d'inventaire (par défaut : scripts\manager\data\inventory.json)
.PARAMETER RulesPath
    Chemin vers le fichier de règles (par défaut : scripts\manager\config\rules.json)
.PARAMETER AnalysisDepth
    Niveau de profondeur de l'analyse (Basic, Standard, Advanced)
.PARAMETER AutoApply
    Applique automatiquement les recommandations d'organisation
.EXAMPLE
    .\Phase2-AnalyzeAndOrganize.ps1
    Exécute la Phase 2 en mode simulation (sans appliquer les changements)
.EXAMPLE
    .\Phase2-AnalyzeAndOrganize.ps1 -AnalysisDepth Advanced -AutoApply
    Exécute la Phase 2 avec une analyse approfondie et applique les changements
#>

param (
    [string]$InventoryPath = "scripts\manager\data\inventory.json",
    [string]$RulesPath = "scripts\manager\config\rules.json",
    [ValidateSet("Basic", "Standard", "Advanced")]
    [string]$AnalysisDepth = "Standard",
    [switch]$AutoApply
)

# Vérifier si l'inventaire existe
if (-not (Test-Path -Path $InventoryPath)) {
    Write-Host "Inventaire non trouvé. Veuillez d'abord exécuter la Phase 1 (Inventory-Scripts.ps1)." -ForegroundColor Red
    exit 1
}

# Vérifier si le fichier de règles existe
if (-not (Test-Path -Path $RulesPath)) {
    Write-Host "Fichier de règles non trouvé: $RulesPath" -ForegroundColor Red
    exit 1
}

# Définir les chemins des modules
$ModulesPath = Join-Path -Path $PSScriptRoot -ChildPath "modules"
$AnalysisModulePath = Join-Path -Path $ModulesPath -ChildPath "Analysis\AnalysisModule.psm1"
$OrganizationModulePath = Join-Path -Path $ModulesPath -ChildPath "Organization\OrganizationModule.psm1"

# Vérifier si les modules existent
if (-not (Test-Path -Path $AnalysisModulePath)) {
    Write-Host "Module d'analyse non trouvé: $AnalysisModulePath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path -Path $OrganizationModulePath)) {
    Write-Host "Module d'organisation non trouvé: $OrganizationModulePath" -ForegroundColor Red
    exit 1
}

# Importer les modules
Import-Module $AnalysisModulePath -Force
Import-Module $OrganizationModulePath -Force

# Définir les chemins de sortie
$AnalysisPath = "scripts\manager\data\analysis_advanced.json"
$OrganizationPath = "scripts\manager\data\organization_advanced.json"

# Afficher la bannière
Write-Host "=== Phase 2: Analyse et organisation avancées ===" -ForegroundColor Cyan
Write-Host "Inventaire: $InventoryPath" -ForegroundColor Yellow
Write-Host "Règles: $RulesPath" -ForegroundColor Yellow
Write-Host "Niveau d'analyse: $AnalysisDepth" -ForegroundColor Yellow
Write-Host "Mode: $(if ($AutoApply) { 'Application automatique' } else { 'Simulation' })" -ForegroundColor Yellow
Write-Host ""

# Étape 1: Analyse approfondie des scripts
Write-Host "Étape 1: Analyse approfondie des scripts" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host ""

$Analysis = Invoke-ScriptAnalysis -InventoryPath $InventoryPath -OutputPath $AnalysisPath -Depth $AnalysisDepth

if ($null -eq $Analysis) {
    Write-Host "Erreur lors de l'analyse des scripts." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Analyse terminée. Résultats enregistrés dans: $AnalysisPath" -ForegroundColor Green
Write-Host "Nombre de scripts analysés: $($Analysis.TotalScripts)" -ForegroundColor Cyan
Write-Host "Scripts avec problèmes: $($Analysis.ScriptsWithProblems)" -ForegroundColor $(if ($Analysis.ScriptsWithProblems -gt 0) { "Yellow" } else { "Green" })
Write-Host "Scripts avec dépendances: $($Analysis.ScriptsWithDependencies)" -ForegroundColor Cyan
Write-Host "Score de qualité moyen: $([math]::Round($Analysis.AverageCodeQuality, 2))" -ForegroundColor $(if ($Analysis.AverageCodeQuality -lt 70) { "Yellow" } elseif ($Analysis.AverageCodeQuality -lt 50) { "Red" } else { "Green" })
Write-Host ""

# Étape 2: Organisation intelligente des scripts
Write-Host "Étape 2: Organisation intelligente des scripts" -ForegroundColor Cyan
Write-Host "---------------------------------------------" -ForegroundColor Cyan
Write-Host ""

$Organization = Invoke-ScriptOrganization -AnalysisPath $AnalysisPath -RulesPath $RulesPath -OutputPath $OrganizationPath -AutoApply:$AutoApply

if ($null -eq $Organization) {
    Write-Host "Erreur lors de l'organisation des scripts." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Organisation terminée. Résultats enregistrés dans: $OrganizationPath" -ForegroundColor Green
Write-Host "Nombre total de scripts: $($Organization.TotalScripts)" -ForegroundColor Cyan
Write-Host "Scripts à déplacer: $($Organization.ScriptsToMove)" -ForegroundColor Yellow
Write-Host "Scripts déplacés: $($Organization.ScriptsMoved)" -ForegroundColor $(if ($Organization.ScriptsMoved -gt 0) { "Green" } else { "Cyan" })
Write-Host ""

# Résumé
Write-Host "=== Résumé de la Phase 2 ===" -ForegroundColor Cyan
Write-Host "Analyse approfondie: $($Analysis.TotalScripts) scripts analysés" -ForegroundColor Cyan
Write-Host "Organisation intelligente: $($Organization.ScriptsToMove) scripts à organiser" -ForegroundColor Cyan
Write-Host ""

if (-not $AutoApply) {
    Write-Host "Pour appliquer les recommandations d'organisation, exécutez la commande suivante:" -ForegroundColor Yellow
    Write-Host ".\Phase2-AnalyzeAndOrganize.ps1 -AnalysisDepth $AnalysisDepth -AutoApply" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Phase 2 terminée avec succès!" -ForegroundColor Green
