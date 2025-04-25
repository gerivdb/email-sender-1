# Module de suggestions d'amélioration pour le Script Manager
# Ce module génère des suggestions pour améliorer les scripts
# Author: Script Manager
# Version: 1.0
# Tags: optimization, suggestions, scripts

function Get-CodeImprovementSuggestions {
    <#
    .SYNOPSIS
        Génère des suggestions d'amélioration pour les scripts
    .DESCRIPTION
        Analyse les scripts et génère des suggestions contextuelles pour améliorer le code
    .PARAMETER Analysis
        Objet d'analyse des scripts
    .PARAMETER AntiPatterns
        Résultats de la détection des anti-patterns
    .PARAMETER OutputPath
        Chemin où enregistrer les suggestions
    .EXAMPLE
        Get-CodeImprovementSuggestions -Analysis $analysis -AntiPatterns $antiPatterns -OutputPath "optimization"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Analysis,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$AntiPatterns,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    # Créer le dossier de suggestions
    $SuggestionsPath = Join-Path -Path $OutputPath -ChildPath "suggestions"
    if (-not (Test-Path -Path $SuggestionsPath)) {
        New-Item -ItemType Directory -Path $SuggestionsPath -Force | Out-Null
    }
    
    Write-Host "Génération des suggestions d'amélioration..." -ForegroundColor Cyan
    
    # Créer un tableau pour stocker les suggestions
    $Suggestions = @()
    
    # Traiter chaque script
    $Counter = 0
    $Total = $Analysis.Scripts.Count
    
    foreach ($Script in $Analysis.Scripts) {
        $Counter++
        $Progress = [math]::Round(($Counter / $Total) * 100)
        Write-Progress -Activity "Génération des suggestions" -Status "$Counter / $Total ($Progress%)" -PercentComplete $Progress
        
        # Obtenir les anti-patterns pour ce script
        $ScriptAntiPatterns = $AntiPatterns.ScriptResults | Where-Object { $_.Path -eq $Script.Path }
        
        # Générer des suggestions basées sur l'analyse et les anti-patterns
        $ScriptSuggestions = @()
        
        # Suggestions basées sur la qualité du code
        $ScriptSuggestions += Get-QualitySuggestions -Script $Script
        
        # Suggestions basées sur les anti-patterns
        if ($ScriptAntiPatterns) {
            $ScriptSuggestions += Get-AntiPatternSuggestions -Script $Script -AntiPatterns $ScriptAntiPatterns
        }
        
        # Suggestions spécifiques au type de script
        $ScriptSuggestions += Get-TypeSpecificSuggestions -Script $Script
        
        # Ajouter les suggestions au tableau global
        if ($ScriptSuggestions.Count -gt 0) {
            $Suggestions += [PSCustomObject]@{
                Path = $Script.Path
                Name = $Script.Name
                Type = $Script.Type
                SuggestionCount = $ScriptSuggestions.Count
                Suggestions = $ScriptSuggestions
            }
        }
    }
    
    Write-Progress -Activity "Génération des suggestions" -Completed
    
    # Enregistrer les suggestions dans un fichier
    $SuggestionsFilePath = Join-Path -Path $SuggestionsPath -ChildPath "suggestions.json"
    $SuggestionsObject = [PSCustomObject]@{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TotalScripts = $Analysis.TotalScripts
        ScriptsWithSuggestions = $Suggestions.Count
        TotalSuggestions = ($Suggestions | Measure-Object -Property SuggestionCount -Sum).Sum
        Results = $Suggestions
    }
    
    $SuggestionsObject | ConvertTo-Json -Depth 10 | Set-Content -Path $SuggestionsFilePath
    
    Write-Host "  Suggestions générées pour $($Suggestions.Count) scripts" -ForegroundColor Green
    Write-Host "  Total des suggestions: $($SuggestionsObject.TotalSuggestions)" -ForegroundColor Green
    Write-Host "  Suggestions enregistrées dans: $SuggestionsFilePath" -ForegroundColor Green
    
    # Générer un rapport HTML des suggestions
    $HtmlReportPath = Join-Path -Path $SuggestionsPath -ChildPath "suggestions_report.html"
    New-SuggestionsReport -Suggestions $SuggestionsObject -OutputPath $HtmlReportPath
    
    Write-Host "  Rapport HTML généré: $HtmlReportPath" -ForegroundColor Green
    
    return $SuggestionsObject
}

# Exporter les fonctions
Export-ModuleMember -Function Get-CodeImprovementSuggestions
