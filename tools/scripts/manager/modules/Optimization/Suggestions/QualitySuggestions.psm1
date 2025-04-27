# Module de suggestions basÃ©es sur la qualitÃ© pour le Script Manager
# Ce module gÃ©nÃ¨re des suggestions basÃ©es sur les mÃ©triques de qualitÃ© du code
# Author: Script Manager
# Version: 1.0
# Tags: optimization, quality, suggestions

function Get-QualitySuggestions {
    <#
    .SYNOPSIS
        GÃ©nÃ¨re des suggestions basÃ©es sur la qualitÃ© du code
    .DESCRIPTION
        Analyse les mÃ©triques de qualitÃ© du code et gÃ©nÃ¨re des suggestions d'amÃ©lioration
    .PARAMETER Script
        Objet script Ã  analyser
    .EXAMPLE
        Get-QualitySuggestions -Script $script
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Script
    )
    
    # CrÃ©er un tableau pour stocker les suggestions
    $Suggestions = @()
    
    # VÃ©rifier le ratio de commentaires
    if ($Script.CodeQuality.Metrics.CommentRatio -lt 0.1) {
        $Suggestions += [PSCustomObject]@{
            Type = "Quality"
            Category = "Documentation"
            Severity = "Medium"
            Title = "Ratio de commentaires faible"
            Description = "Le script a un ratio de commentaires de seulement $([math]::Round($Script.CodeQuality.Metrics.CommentRatio * 100, 1))%. Un bon code devrait avoir au moins 15-20% de commentaires."
            Recommendation = "Ajouter des commentaires pour expliquer le but des fonctions, des sections complexes et des algorithmes."
            CodeSnippet = $null
            LineNumbers = $null
            AutoFixable = $false
        }
    }
    
    # VÃ©rifier la longueur des lignes
    if ($Script.CodeQuality.Metrics.MaxLineLength -gt 100) {
        $Suggestions += [PSCustomObject]@{
            Type = "Quality"
            Category = "Readability"
            Severity = "Low"
            Title = "Lignes trop longues"
            Description = "Le script contient des lignes de plus de 100 caractÃ¨res (max: $($Script.CodeQuality.Metrics.MaxLineLength)). Les lignes longues rÃ©duisent la lisibilitÃ©."
            Recommendation = "Diviser les longues lignes en plusieurs lignes plus courtes. Utiliser la continuation de ligne appropriÃ©e pour votre langage."
            CodeSnippet = $null
            LineNumbers = $null
            AutoFixable = $true
        }
    }
    
    # VÃ©rifier la complexitÃ©
    if ($Script.CodeQuality.Metrics.ComplexityScore -gt 10) {
        $Suggestions += [PSCustomObject]@{
            Type = "Quality"
            Category = "Complexity"
            Severity = "High"
            Title = "ComplexitÃ© Ã©levÃ©e"
            Description = "Le script a un score de complexitÃ© Ã©levÃ© ($($Script.CodeQuality.Metrics.ComplexityScore)). Une complexitÃ© Ã©levÃ©e rend le code difficile Ã  comprendre et Ã  maintenir."
            Recommendation = "Refactoriser le code en fonctions plus petites et plus simples. RÃ©duire la profondeur des imbrications."
            CodeSnippet = $null
            LineNumbers = $null
            AutoFixable = $false
        }
    }
    
    # VÃ©rifier le nombre de fonctions
    if ($Script.StaticAnalysis.FunctionCount -eq 0 -and $Script.StaticAnalysis.LineCount -gt 50) {
        $Suggestions += [PSCustomObject]@{
            Type = "Quality"
            Category = "Structure"
            Severity = "Medium"
            Title = "Script monolithique"
            Description = "Le script contient $($Script.StaticAnalysis.LineCount) lignes sans aucune fonction. Les scripts longs sans fonctions sont difficiles Ã  maintenir."
            Recommendation = "Diviser le script en fonctions logiques pour amÃ©liorer la modularitÃ© et la rÃ©utilisabilitÃ©."
            CodeSnippet = $null
            LineNumbers = $null
            AutoFixable = $false
        }
    }
    
    # VÃ©rifier le ratio de lignes vides
    if ($Script.CodeQuality.Metrics.EmptyLineRatio -gt 0.3) {
        $Suggestions += [PSCustomObject]@{
            Type = "Quality"
            Category = "Structure"
            Severity = "Low"
            Title = "Trop de lignes vides"
            Description = "Le script contient un ratio Ã©levÃ© de lignes vides ($([math]::Round($Script.CodeQuality.Metrics.EmptyLineRatio * 100, 1))%). Trop d'espaces vides peuvent rÃ©duire la densitÃ© d'information."
            Recommendation = "RÃ©duire le nombre de lignes vides tout en conservant une sÃ©paration claire entre les sections logiques."
            CodeSnippet = $null
            LineNumbers = $null
            AutoFixable = $true
        }
    } elseif ($Script.CodeQuality.Metrics.EmptyLineRatio -lt 0.05 -and $Script.StaticAnalysis.LineCount -gt 20) {
        $Suggestions += [PSCustomObject]@{
            Type = "Quality"
            Category = "Structure"
            Severity = "Low"
            Title = "Pas assez de lignes vides"
            Description = "Le script contient peu de lignes vides ($([math]::Round($Script.CodeQuality.Metrics.EmptyLineRatio * 100, 1))%). Un espacement adÃ©quat amÃ©liore la lisibilitÃ©."
            Recommendation = "Ajouter des lignes vides pour sÃ©parer les sections logiques du code."
            CodeSnippet = $null
            LineNumbers = $null
            AutoFixable = $true
        }
    }
    
    return $Suggestions
}

# Exporter les fonctions
Export-ModuleMember -Function Get-QualitySuggestions
