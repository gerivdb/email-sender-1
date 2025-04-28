# Module de suggestions d'amÃ©lioration pour le Script Manager
# Ce module gÃ©nÃ¨re des suggestions pour amÃ©liorer les scripts
# Author: Script Manager
# Version: 1.0
# Tags: optimization, suggestions, scripts

function Get-CodeImprovementSuggestions {
    <#
    .SYNOPSIS
        GÃ©nÃ¨re des suggestions d'amÃ©lioration pour les scripts
    .DESCRIPTION
        Analyse les scripts et gÃ©nÃ¨re des suggestions contextuelles pour amÃ©liorer le code
    .PARAMETER Analysis
        Objet d'analyse des scripts
    .PARAMETER AntiPatterns
        RÃ©sultats de la dÃ©tection des anti-patterns
    .PARAMETER OutputPath
        Chemin oÃ¹ enregistrer les suggestions
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
    
    # CrÃ©er le dossier de suggestions
    $SuggestionsPath = Join-Path -Path $OutputPath -ChildPath "suggestions"
    if (-not (Test-Path -Path $SuggestionsPath)) {
        New-Item -ItemType Directory -Path $SuggestionsPath -Force | Out-Null
    }
    
    Write-Host "GÃ©nÃ©ration des suggestions d'amÃ©lioration..." -ForegroundColor Cyan
    
    # CrÃ©er un tableau pour stocker les suggestions
    $Suggestions = @()
    
    # Traiter chaque script
    $Counter = 0
    $Total = $Analysis.Scripts.Count
    
    foreach ($Script in $Analysis.Scripts) {
        $Counter++
        $Progress = [math]::Round(($Counter / $Total) * 100)
        Write-Progress -Activity "GÃ©nÃ©ration des suggestions" -Status "$Counter / $Total ($Progress%)" -PercentComplete $Progress
        
        # Obtenir les anti-patterns pour ce script
        $ScriptAntiPatterns = $AntiPatterns.ScriptResults | Where-Object { $_.Path -eq $Script.Path }
        
        # GÃ©nÃ©rer des suggestions basÃ©es sur l'analyse et les anti-patterns
        $ScriptSuggestions = @()
        
        # Suggestions basÃ©es sur la qualitÃ© du code
        $ScriptSuggestions += Get-QualitySuggestions -Script $Script
        
        # Suggestions basÃ©es sur les anti-patterns
        if ($ScriptAntiPatterns) {
            $ScriptSuggestions += Get-AntiPatternSuggestions -Script $Script -AntiPatterns $ScriptAntiPatterns
        }
        
        # Suggestions spÃ©cifiques au type de script
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
    
    Write-Progress -Activity "GÃ©nÃ©ration des suggestions" -Completed
    
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
    
    Write-Host "  Suggestions gÃ©nÃ©rÃ©es pour $($Suggestions.Count) scripts" -ForegroundColor Green
    Write-Host "  Total des suggestions: $($SuggestionsObject.TotalSuggestions)" -ForegroundColor Green
    Write-Host "  Suggestions enregistrÃ©es dans: $SuggestionsFilePath" -ForegroundColor Green
    
    # GÃ©nÃ©rer un rapport HTML des suggestions
    $HtmlReportPath = Join-Path -Path $SuggestionsPath -ChildPath "suggestions_report.html"
    New-SuggestionsReport -Suggestions $SuggestionsObject -OutputPath $HtmlReportPath
    
    Write-Host "  Rapport HTML gÃ©nÃ©rÃ©: $HtmlReportPath" -ForegroundColor Green
    
    return $SuggestionsObject
}

# Exporter les fonctions
Export-ModuleMember -Function Get-CodeImprovementSuggestions
