# Module de suggestions basées sur les anti-patterns pour le Script Manager
# Ce module génère des suggestions basées sur les anti-patterns détectés
# Author: Script Manager
# Version: 1.0
# Tags: optimization, anti-patterns, suggestions

function Get-AntiPatternSuggestions {
    <#
    .SYNOPSIS
        Génère des suggestions basées sur les anti-patterns détectés
    .DESCRIPTION
        Analyse les anti-patterns détectés et génère des suggestions d'amélioration
    .PARAMETER Script
        Objet script à analyser
    .PARAMETER AntiPatterns
        Anti-patterns détectés pour ce script
    .EXAMPLE
        Get-AntiPatternSuggestions -Script $script -AntiPatterns $antiPatterns
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Script,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$AntiPatterns
    )
    
    # Créer un tableau pour stocker les suggestions
    $Suggestions = @()
    
    # Traiter chaque anti-pattern
    foreach ($AntiPattern in $AntiPatterns.Patterns) {
        # Générer une suggestion basée sur le type d'anti-pattern
        switch ($AntiPattern.Type) {
            "DeadCode" {
                $Suggestions += [PSCustomObject]@{
                    Type = "AntiPattern"
                    Category = "Maintenance"
                    Severity = "Medium"
                    Title = "Code mort détecté"
                    Description = "Le script contient du code qui n'est jamais exécuté (lignes $($AntiPattern.LineNumbers -join ', '))."
                    Recommendation = "Supprimer le code mort pour améliorer la lisibilité et réduire la taille du script."
                    CodeSnippet = $AntiPattern.CodeSnippet
                    LineNumbers = $AntiPattern.LineNumbers
                    AutoFixable = $true
                }
            }
            "DuplicateCode" {
                $Suggestions += [PSCustomObject]@{
                    Type = "AntiPattern"
                    Category = "Maintenance"
                    Severity = "High"
                    Title = "Code dupliqué détecté"
                    Description = "Le script contient du code dupliqué (lignes $($AntiPattern.LineNumbers -join ', ')). La duplication viole le principe DRY (Don't Repeat Yourself)."
                    Recommendation = "Extraire le code dupliqué dans une fonction réutilisable."
                    CodeSnippet = $AntiPattern.CodeSnippet
                    LineNumbers = $AntiPattern.LineNumbers
                    AutoFixable = $false
                }
            }
            "MagicNumber" {
                $Suggestions += [PSCustomObject]@{
                    Type = "AntiPattern"
                    Category = "Maintenance"
                    Severity = "Medium"
                    Title = "Nombres magiques détectés"
                    Description = "Le script utilise des nombres magiques (lignes $($AntiPattern.LineNumbers -join ', ')). Les nombres codés en dur réduisent la maintenabilité."
                    Recommendation = "Remplacer les nombres magiques par des constantes nommées qui expliquent leur signification."
                    CodeSnippet = $AntiPattern.CodeSnippet
                    LineNumbers = $AntiPattern.LineNumbers
                    AutoFixable = $true
                }
            }
            "LongMethod" {
                $Suggestions += [PSCustomObject]@{
                    Type = "AntiPattern"
                    Category = "Structure"
                    Severity = "High"
                    Title = "Méthode trop longue"
                    Description = "Le script contient une méthode très longue ($($AntiPattern.Details.Length) lignes). Les méthodes longues sont difficiles à comprendre et à maintenir."
                    Recommendation = "Diviser la méthode en plusieurs méthodes plus petites, chacune avec une responsabilité unique."
                    CodeSnippet = $AntiPattern.CodeSnippet
                    LineNumbers = $AntiPattern.LineNumbers
                    AutoFixable = $false
                }
            }
            "DeepNesting" {
                $Suggestions += [PSCustomObject]@{
                    Type = "AntiPattern"
                    Category = "Complexity"
                    Severity = "High"
                    Title = "Imbrication profonde"
                    Description = "Le script contient une imbrication profonde (niveau $($AntiPattern.Details.Depth)). Une imbrication excessive rend le code difficile à suivre."
                    Recommendation = "Réduire la profondeur d'imbrication en extrayant des méthodes ou en utilisant des clauses de garde."
                    CodeSnippet = $AntiPattern.CodeSnippet
                    LineNumbers = $AntiPattern.LineNumbers
                    AutoFixable = $false
                }
            }
            "GlobalVariable" {
                $Suggestions += [PSCustomObject]@{
                    Type = "AntiPattern"
                    Category = "Structure"
                    Severity = "Medium"
                    Title = "Variables globales"
                    Description = "Le script utilise des variables globales. Les variables globales créent des dépendances cachées et rendent le code difficile à tester."
                    Recommendation = "Passer les variables en paramètres aux fonctions plutôt que d'utiliser des variables globales."
                    CodeSnippet = $AntiPattern.CodeSnippet
                    LineNumbers = $AntiPattern.LineNumbers
                    AutoFixable = $false
                }
            }
            "HardcodedPath" {
                $Suggestions += [PSCustomObject]@{
                    Type = "AntiPattern"
                    Category = "Portability"
                    Severity = "Medium"
                    Title = "Chemins codés en dur"
                    Description = "Le script contient des chemins codés en dur. Cela réduit la portabilité du script."
                    Recommendation = "Utiliser des chemins relatifs ou des variables d'environnement pour les chemins de fichiers."
                    CodeSnippet = $AntiPattern.CodeSnippet
                    LineNumbers = $AntiPattern.LineNumbers
                    AutoFixable = $true
                }
            }
            "CatchAll" {
                $Suggestions += [PSCustomObject]@{
                    Type = "AntiPattern"
                    Category = "ErrorHandling"
                    Severity = "Medium"
                    Title = "Bloc catch générique"
                    Description = "Le script utilise un bloc catch générique qui capture toutes les exceptions. Cela peut masquer des erreurs importantes."
                    Recommendation = "Capturer uniquement les exceptions spécifiques que vous pouvez gérer correctement."
                    CodeSnippet = $AntiPattern.CodeSnippet
                    LineNumbers = $AntiPattern.LineNumbers
                    AutoFixable = $false
                }
            }
            "NoErrorHandling" {
                $Suggestions += [PSCustomObject]@{
                    Type = "AntiPattern"
                    Category = "ErrorHandling"
                    Severity = "High"
                    Title = "Absence de gestion des erreurs"
                    Description = "Le script ne contient pas de gestion des erreurs pour des opérations critiques."
                    Recommendation = "Ajouter des blocs try-catch pour gérer les erreurs potentielles et fournir des messages d'erreur utiles."
                    CodeSnippet = $AntiPattern.CodeSnippet
                    LineNumbers = $AntiPattern.LineNumbers
                    AutoFixable = $false
                }
            }
            default {
                $Suggestions += [PSCustomObject]@{
                    Type = "AntiPattern"
                    Category = "General"
                    Severity = "Medium"
                    Title = "Anti-pattern: $($AntiPattern.Type)"
                    Description = $AntiPattern.Description
                    Recommendation = $AntiPattern.Recommendation
                    CodeSnippet = $AntiPattern.CodeSnippet
                    LineNumbers = $AntiPattern.LineNumbers
                    AutoFixable = $false
                }
            }
        }
    }
    
    return $Suggestions
}

# Exporter les fonctions
Export-ModuleMember -Function Get-AntiPatternSuggestions
