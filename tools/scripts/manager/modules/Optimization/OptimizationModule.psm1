# Module d'optimisation pour le Script Manager
# Ce module coordonne l'optimisation et l'intelligence des scripts
# Author: Script Manager
# Version: 1.0
# Tags: optimization, intelligence, scripts, manager

# Importer les sous-modules
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$SubModules = @(
    "SuggestionEngine.psm1",
    "CodeLearning.psm1",
    "RefactoringAssistant.psm1",
    "AntiPatternDetector.psm1"
)

foreach ($Module in $SubModules) {
    $ModulePath = Join-Path -Path $ScriptPath -ChildPath $Module
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -Force
    } else {
        Write-Warning "Module $Module not found at $ModulePath"
    }
}

function Invoke-ScriptOptimization {
    <#
    .SYNOPSIS
        Optimise les scripts et fournit des suggestions d'amélioration intelligentes
    .DESCRIPTION
        Analyse les scripts, détecte les anti-patterns, suggère des améliorations
        et assiste dans le refactoring du code
    .PARAMETER AnalysisPath
        Chemin vers le fichier d'analyse JSON
    .PARAMETER OutputPath
        Chemin où enregistrer les résultats de l'optimisation
    .PARAMETER LearningEnabled
        Active l'apprentissage des modèles de code
    .PARAMETER RefactoringMode
        Mode de refactoring (Suggestion, Interactive, Automatic)
    .EXAMPLE
        Invoke-ScriptOptimization -AnalysisPath "data\analysis.json" -OutputPath "optimization" -LearningEnabled
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$AnalysisPath,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [switch]$LearningEnabled,
        
        [ValidateSet("Suggestion", "Interactive", "Automatic")]
        [string]$RefactoringMode = "Suggestion"
    )
    
    # Vérifier si le fichier d'analyse existe
    if (-not (Test-Path -Path $AnalysisPath)) {
        Write-Error "Fichier d'analyse non trouvé: $AnalysisPath"
        return $null
    }
    
    # Charger l'analyse
    try {
        $Analysis = Get-Content -Path $AnalysisPath -Raw | ConvertFrom-Json
    } catch {
        Write-Error "Erreur lors du chargement de l'analyse: $_"
        return $null
    }
    
    Write-Host "Optimisation des scripts en cours..." -ForegroundColor Cyan
    Write-Host "Nombre de scripts à optimiser: $($Analysis.TotalScripts)" -ForegroundColor Cyan
    Write-Host "Mode de refactoring: $RefactoringMode" -ForegroundColor Cyan
    Write-Host "Apprentissage: $(if ($LearningEnabled) { 'Activé' } else { 'Désactivé' })" -ForegroundColor Cyan
    
    # Créer le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    # Créer un tableau pour stocker les résultats de l'optimisation
    $OptimizationResults = @()
    
    # Étape 1: Détecter les anti-patterns
    Write-Host "Étape 1: Détection des anti-patterns..." -ForegroundColor Yellow
    $AntiPatterns = Find-CodeAntiPatterns -Analysis $Analysis -OutputPath $OutputPath
    
    # Étape 2: Générer des suggestions d'amélioration
    Write-Host "Étape 2: Génération des suggestions d'amélioration..." -ForegroundColor Yellow
    $Suggestions = Get-CodeImprovementSuggestions -Analysis $Analysis -AntiPatterns $AntiPatterns -OutputPath $OutputPath
    
    # Étape 3: Apprentissage des modèles de code (si activé)
    if ($LearningEnabled) {
        Write-Host "Étape 3: Apprentissage des modèles de code..." -ForegroundColor Yellow
        $LearningModel = Start-CodeLearning -Analysis $Analysis -OutputPath $OutputPath
    }
    
    # Étape 4: Assistance au refactoring
    Write-Host "Étape 4: Assistance au refactoring..." -ForegroundColor Yellow
    $RefactoringResults = Invoke-CodeRefactoring -Analysis $Analysis -Suggestions $Suggestions -Mode $RefactoringMode -OutputPath $OutputPath
    
    # Créer un objet avec les résultats de l'optimisation
    $Optimization = [PSCustomObject]@{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TotalScripts = $Analysis.TotalScripts
        AntiPatterns = $AntiPatterns
        Suggestions = $Suggestions
        RefactoringResults = $RefactoringResults
        LearningEnabled = $LearningEnabled
        LearningModel = if ($LearningEnabled) { $LearningModel } else { $null }
    }
    
    # Convertir l'objet en JSON et l'enregistrer dans un fichier
    $OptimizationPath = Join-Path -Path $OutputPath -ChildPath "optimization.json"
    $Optimization | ConvertTo-Json -Depth 10 | Set-Content -Path $OptimizationPath
    
    Write-Host "Optimisation terminée. Résultats enregistrés dans: $OptimizationPath" -ForegroundColor Green
    
    return $Optimization
}

# Exporter les fonctions
Export-ModuleMember -Function Invoke-ScriptOptimization
