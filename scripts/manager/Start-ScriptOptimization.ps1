<#
.SYNOPSIS
    Démarre l'optimisation des scripts
.DESCRIPTION
    Ce script exécute l'optimisation des scripts en utilisant le module d'optimisation
.PARAMETER AnalysisPath
    Chemin vers le fichier d'analyse JSON
.PARAMETER OutputPath
    Chemin où enregistrer les résultats de l'optimisation
.PARAMETER LearningEnabled
    Active l'apprentissage des modèles de code
.PARAMETER RefactoringMode
    Mode de refactoring (Suggestion, Interactive, Automatic)
.EXAMPLE
    .\Start-ScriptOptimization.ps1 -AnalysisPath "data\analysis.json" -OutputPath "optimization"
.EXAMPLE
    .\Start-ScriptOptimization.ps1 -AnalysisPath "data\analysis.json" -OutputPath "optimization" -LearningEnabled -RefactoringMode "Interactive"
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$AnalysisPath,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "optimization",
    
    [Parameter(Mandatory=$false)]
    [switch]$LearningEnabled,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Suggestion", "Interactive", "Automatic")]
    [string]$RefactoringMode = "Suggestion"
)

# Vérifier si le fichier d'analyse existe
if (-not (Test-Path -Path $AnalysisPath)) {
    Write-Host "Fichier d'analyse non trouvé: $AnalysisPath" -ForegroundColor Red
    exit 1
}

# Importer le module d'optimisation
$ModulePath = Join-Path -Path $PSScriptRoot -ChildPath "modules\Optimization\OptimizationModule.psm1"

if (-not (Test-Path -Path $ModulePath)) {
    Write-Host "Module d'optimisation non trouvé: $ModulePath" -ForegroundColor Red
    exit 1
}

Import-Module $ModulePath -Force

# Créer le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

# Afficher les informations de démarrage
Write-Host "=== Démarrage de l'optimisation des scripts ===" -ForegroundColor Cyan
Write-Host "Fichier d'analyse: $AnalysisPath" -ForegroundColor Cyan
Write-Host "Dossier de sortie: $OutputPath" -ForegroundColor Cyan
Write-Host "Mode de refactoring: $RefactoringMode" -ForegroundColor Cyan
Write-Host "Apprentissage: $(if ($LearningEnabled) { 'Activé' } else { 'Désactivé' })" -ForegroundColor Cyan
Write-Host ""

# Exécuter l'optimisation
try {
    $Optimization = Invoke-ScriptOptimization -AnalysisPath $AnalysisPath -OutputPath $OutputPath -LearningEnabled:$LearningEnabled -RefactoringMode $RefactoringMode
    
    # Afficher les résultats
    Write-Host ""
    Write-Host "=== Résultats de l'optimisation ===" -ForegroundColor Green
    Write-Host "Nombre de scripts analysés: $($Optimization.TotalScripts)" -ForegroundColor Green
    Write-Host "Anti-patterns détectés: $($Optimization.AntiPatterns.TotalAntiPatterns)" -ForegroundColor Green
    Write-Host "Suggestions générées: $($Optimization.Suggestions.TotalSuggestions)" -ForegroundColor Green
    
    if ($Optimization.RefactoringResults) {
        Write-Host "Opérations de refactoring réussies: $($Optimization.RefactoringResults.SuccessCount) sur $($Optimization.RefactoringResults.TotalScripts)" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Résultats enregistrés dans: $OutputPath" -ForegroundColor Green
    
    # Ouvrir le rapport HTML si disponible
    $SuggestionsReportPath = Join-Path -Path $OutputPath -ChildPath "suggestions\suggestions_report.html"
    if (Test-Path -Path $SuggestionsReportPath) {
        Write-Host "Rapport des suggestions: $SuggestionsReportPath" -ForegroundColor Green
        
        $OpenReport = Read-Host "Voulez-vous ouvrir le rapport des suggestions? (O/N)"
        if ($OpenReport -eq "O" -or $OpenReport -eq "o") {
            Start-Process $SuggestionsReportPath
        }
    }
    
    $RefactoringReportPath = Join-Path -Path $OutputPath -ChildPath "refactoring\refactoring_report.html"
    if (Test-Path -Path $RefactoringReportPath) {
        Write-Host "Rapport de refactoring: $RefactoringReportPath" -ForegroundColor Green
        
        $OpenReport = Read-Host "Voulez-vous ouvrir le rapport de refactoring? (O/N)"
        if ($OpenReport -eq "O" -or $OpenReport -eq "o") {
            Start-Process $RefactoringReportPath
        }
    }
} catch {
    Write-Host "Erreur lors de l'optimisation: $_" -ForegroundColor Red
    exit 1
}
