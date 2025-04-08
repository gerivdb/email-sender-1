# Module d'assistant de refactoring pour le Script Manager
# Ce module assiste dans le refactoring des scripts
# Author: Script Manager
# Version: 1.0
# Tags: optimization, refactoring, scripts

# Importer les sous-modules
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$SubModules = @(
    "Refactoring\RefactoringPlanner.psm1",
    "Refactoring\CodeTransformer.psm1",
    "Refactoring\RefactoringValidator.psm1"
)

foreach ($Module in $SubModules) {
    $ModulePath = Join-Path -Path $ScriptPath -ChildPath $Module
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -Force
    } else {
        Write-Warning "Module $Module not found at $ModulePath"
    }
}

function Invoke-CodeRefactoring {
    <#
    .SYNOPSIS
        Assiste dans le refactoring des scripts
    .DESCRIPTION
        Analyse les scripts, planifie et exécute des opérations de refactoring
    .PARAMETER Analysis
        Objet d'analyse des scripts
    .PARAMETER Suggestions
        Suggestions d'amélioration
    .PARAMETER Mode
        Mode de refactoring (Suggestion, Interactive, Automatic)
    .PARAMETER OutputPath
        Chemin où enregistrer les résultats du refactoring
    .EXAMPLE
        Invoke-CodeRefactoring -Analysis $analysis -Suggestions $suggestions -Mode "Interactive" -OutputPath "optimization"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Analysis,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Suggestions,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("Suggestion", "Interactive", "Automatic")]
        [string]$Mode,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    # Créer le dossier de refactoring
    $RefactoringPath = Join-Path -Path $OutputPath -ChildPath "refactoring"
    if (-not (Test-Path -Path $RefactoringPath)) {
        New-Item -ItemType Directory -Path $RefactoringPath -Force | Out-Null
    }
    
    Write-Host "Refactoring des scripts en mode $Mode..." -ForegroundColor Cyan
    
    # Créer un tableau pour stocker les résultats
    $Results = @()
    
    # Filtrer les suggestions auto-corrigeables si en mode Automatic
    $ScriptsToRefactor = @()
    
    if ($Mode -eq "Automatic") {
        foreach ($Script in $Suggestions.Results) {
            $AutoFixableSuggestions = $Script.Suggestions | Where-Object { $_.AutoFixable -eq $true }
            
            if ($AutoFixableSuggestions.Count -gt 0) {
                $ScriptsToRefactor += [PSCustomObject]@{
                    Script = $Analysis.Scripts | Where-Object { $_.Path -eq $Script.Path } | Select-Object -First 1
                    Suggestions = $AutoFixableSuggestions
                }
            }
        }
    } else {
        foreach ($Script in $Suggestions.Results) {
            $ScriptsToRefactor += [PSCustomObject]@{
                Script = $Analysis.Scripts | Where-Object { $_.Path -eq $Script.Path } | Select-Object -First 1
                Suggestions = $Script.Suggestions
            }
        }
    }
    
    # Traiter chaque script
    $Counter = 0
    $Total = $ScriptsToRefactor.Count
    
    foreach ($Item in $ScriptsToRefactor) {
        $Counter++
        $Progress = [math]::Round(($Counter / $Total) * 100)
        Write-Progress -Activity "Refactoring des scripts" -Status "$Counter / $Total ($Progress%)" -PercentComplete $Progress
        
        $Script = $Item.Script
        $ScriptSuggestions = $Item.Suggestions
        
        # Planifier le refactoring
        $Plan = New-RefactoringPlan -Script $Script -Suggestions $ScriptSuggestions
        
        # Exécuter le refactoring selon le mode
        $RefactoringResult = $null
        
        switch ($Mode) {
            "Suggestion" {
                # Générer des suggestions de refactoring
                $RefactoringResult = Get-RefactoringSuggestions -Script $Script -Plan $Plan -OutputPath $RefactoringPath
            }
            "Interactive" {
                # Exécuter le refactoring de manière interactive
                $RefactoringResult = Invoke-InteractiveRefactoring -Script $Script -Plan $Plan -OutputPath $RefactoringPath
            }
            "Automatic" {
                # Exécuter le refactoring automatiquement
                $RefactoringResult = Invoke-AutomaticRefactoring -Script $Script -Plan $Plan -OutputPath $RefactoringPath
            }
        }
        
        if ($RefactoringResult) {
            $Results += $RefactoringResult
        }
    }
    
    Write-Progress -Activity "Refactoring des scripts" -Completed
    
    # Enregistrer les résultats dans un fichier
    $ResultsPath = Join-Path -Path $RefactoringPath -ChildPath "refactoring_results.json"
    $ResultsObject = [PSCustomObject]@{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Mode = $Mode
        TotalScripts = $ScriptsToRefactor.Count
        SuccessCount = ($Results | Where-Object { $_.Success } | Measure-Object).Count
        Results = $Results
    }
    
    $ResultsObject | ConvertTo-Json -Depth 10 | Set-Content -Path $ResultsPath
    
    Write-Host "  Refactoring terminé pour $($ResultsObject.SuccessCount) scripts sur $($ResultsObject.TotalScripts)" -ForegroundColor Green
    Write-Host "  Résultats enregistrés dans: $ResultsPath" -ForegroundColor Green
    
    # Générer un rapport HTML
    $HtmlReportPath = Join-Path -Path $RefactoringPath -ChildPath "refactoring_report.html"
    New-RefactoringReport -Results $ResultsObject -OutputPath $HtmlReportPath
    
    Write-Host "  Rapport HTML généré: $HtmlReportPath" -ForegroundColor Green
    
    return $ResultsObject
}

# Exporter les fonctions
Export-ModuleMember -Function Invoke-CodeRefactoring
