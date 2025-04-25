# Module de suggestions basées sur la qualité pour le Script Manager
# Ce module génère des suggestions basées sur les métriques de qualité du code
# Author: Script Manager
# Version: 1.0
# Tags: optimization, quality, suggestions

function Get-QualitySuggestions {
    <#
    .SYNOPSIS
        Génère des suggestions basées sur la qualité du code
    .DESCRIPTION
        Analyse les métriques de qualité du code et génère des suggestions d'amélioration
    .PARAMETER Script
        Objet script à analyser
    .EXAMPLE
        Get-QualitySuggestions -Script $script
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Script
    )
    
    # Créer un tableau pour stocker les suggestions
    $Suggestions = @()
    
    # Vérifier le ratio de commentaires
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
    
    # Vérifier la longueur des lignes
    if ($Script.CodeQuality.Metrics.MaxLineLength -gt 100) {
        $Suggestions += [PSCustomObject]@{
            Type = "Quality"
            Category = "Readability"
            Severity = "Low"
            Title = "Lignes trop longues"
            Description = "Le script contient des lignes de plus de 100 caractères (max: $($Script.CodeQuality.Metrics.MaxLineLength)). Les lignes longues réduisent la lisibilité."
            Recommendation = "Diviser les longues lignes en plusieurs lignes plus courtes. Utiliser la continuation de ligne appropriée pour votre langage."
            CodeSnippet = $null
            LineNumbers = $null
            AutoFixable = $true
        }
    }
    
    # Vérifier la complexité
    if ($Script.CodeQuality.Metrics.ComplexityScore -gt 10) {
        $Suggestions += [PSCustomObject]@{
            Type = "Quality"
            Category = "Complexity"
            Severity = "High"
            Title = "Complexité élevée"
            Description = "Le script a un score de complexité élevé ($($Script.CodeQuality.Metrics.ComplexityScore)). Une complexité élevée rend le code difficile à comprendre et à maintenir."
            Recommendation = "Refactoriser le code en fonctions plus petites et plus simples. Réduire la profondeur des imbrications."
            CodeSnippet = $null
            LineNumbers = $null
            AutoFixable = $false
        }
    }
    
    # Vérifier le nombre de fonctions
    if ($Script.StaticAnalysis.FunctionCount -eq 0 -and $Script.StaticAnalysis.LineCount -gt 50) {
        $Suggestions += [PSCustomObject]@{
            Type = "Quality"
            Category = "Structure"
            Severity = "Medium"
            Title = "Script monolithique"
            Description = "Le script contient $($Script.StaticAnalysis.LineCount) lignes sans aucune fonction. Les scripts longs sans fonctions sont difficiles à maintenir."
            Recommendation = "Diviser le script en fonctions logiques pour améliorer la modularité et la réutilisabilité."
            CodeSnippet = $null
            LineNumbers = $null
            AutoFixable = $false
        }
    }
    
    # Vérifier le ratio de lignes vides
    if ($Script.CodeQuality.Metrics.EmptyLineRatio -gt 0.3) {
        $Suggestions += [PSCustomObject]@{
            Type = "Quality"
            Category = "Structure"
            Severity = "Low"
            Title = "Trop de lignes vides"
            Description = "Le script contient un ratio élevé de lignes vides ($([math]::Round($Script.CodeQuality.Metrics.EmptyLineRatio * 100, 1))%). Trop d'espaces vides peuvent réduire la densité d'information."
            Recommendation = "Réduire le nombre de lignes vides tout en conservant une séparation claire entre les sections logiques."
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
            Description = "Le script contient peu de lignes vides ($([math]::Round($Script.CodeQuality.Metrics.EmptyLineRatio * 100, 1))%). Un espacement adéquat améliore la lisibilité."
            Recommendation = "Ajouter des lignes vides pour séparer les sections logiques du code."
            CodeSnippet = $null
            LineNumbers = $null
            AutoFixable = $true
        }
    }
    
    return $Suggestions
}

# Exporter les fonctions
Export-ModuleMember -Function Get-QualitySuggestions
