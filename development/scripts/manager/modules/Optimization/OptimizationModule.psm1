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
        Optimise les scripts et fournit des suggestions d'amÃ©lioration intelligentes
    .DESCRIPTION
        Analyse les scripts, dÃ©tecte les anti-patterns, suggÃ¨re des amÃ©liorations
        et assiste dans le refactoring du code
    .PARAMETER AnalysisPath
        Chemin vers le fichier d'analyse JSON
    .PARAMETER OutputPath
        Chemin oÃ¹ enregistrer les rÃ©sultats de l'optimisation
    .PARAMETER LearningEnabled
        Active l'apprentissage des modÃ¨les de code
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
    
    # VÃ©rifier si le fichier d'analyse existe
    if (-not (Test-Path -Path $AnalysisPath)) {
        Write-Error "Fichier d'analyse non trouvÃ©: $AnalysisPath"
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
    Write-Host "Nombre de scripts Ã  optimiser: $($Analysis.TotalScripts)" -ForegroundColor Cyan
    Write-Host "Mode de refactoring: $RefactoringMode" -ForegroundColor Cyan
    Write-Host "Apprentissage: $(if ($LearningEnabled) { 'ActivÃ©' } else { 'DÃ©sactivÃ©' })" -ForegroundColor Cyan
    
    # CrÃ©er le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    # CrÃ©er un tableau pour stocker les rÃ©sultats de l'optimisation
    $OptimizationResults = @()
    
    # Ã‰tape 1: DÃ©tecter les anti-patterns
    Write-Host "Ã‰tape 1: DÃ©tection des anti-patterns..." -ForegroundColor Yellow
    $AntiPatterns = Find-CodeAntiPatterns -Analysis $Analysis -OutputPath $OutputPath
    
    # Ã‰tape 2: GÃ©nÃ©rer des suggestions d'amÃ©lioration
    Write-Host "Ã‰tape 2: GÃ©nÃ©ration des suggestions d'amÃ©lioration..." -ForegroundColor Yellow
    $Suggestions = Get-CodeImprovementSuggestions -Analysis $Analysis -AntiPatterns $AntiPatterns -OutputPath $OutputPath
    
    # Ã‰tape 3: Apprentissage des modÃ¨les de code (si activÃ©)
    if ($LearningEnabled) {
        Write-Host "Ã‰tape 3: Apprentissage des modÃ¨les de code..." -ForegroundColor Yellow
        $LearningModel = Start-CodeLearning -Analysis $Analysis -OutputPath $OutputPath
    }
    
    # Ã‰tape 4: Assistance au refactoring
    Write-Host "Ã‰tape 4: Assistance au refactoring..." -ForegroundColor Yellow
    $RefactoringResults = Invoke-CodeRefactoring -Analysis $Analysis -Suggestions $Suggestions -Mode $RefactoringMode -OutputPath $OutputPath
    
    # CrÃ©er un objet avec les rÃ©sultats de l'optimisation
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
    
    Write-Host "Optimisation terminÃ©e. RÃ©sultats enregistrÃ©s dans: $OptimizationPath" -ForegroundColor Green
    
    return $Optimization
}

# Exporter les fonctions
Export-ModuleMember -Function Invoke-ScriptOptimization
