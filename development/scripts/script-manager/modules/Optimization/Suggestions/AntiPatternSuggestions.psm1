# Module de suggestions basÃ©es sur les anti-patterns pour le Script Manager
# Ce module gÃ©nÃ¨re des suggestions basÃ©es sur les anti-patterns dÃ©tectÃ©s
# Author: Script Manager
# Version: 1.0
# Tags: optimization, anti-patterns, suggestions

function Get-AntiPatternSuggestions {
    <#
    .SYNOPSIS
        GÃ©nÃ¨re des suggestions basÃ©es sur les anti-patterns dÃ©tectÃ©s
    .DESCRIPTION
        Analyse les anti-patterns dÃ©tectÃ©s et gÃ©nÃ¨re des suggestions d'amÃ©lioration
    .PARAMETER Script
        Objet script Ã  analyser
    .PARAMETER AntiPatterns
        Anti-patterns dÃ©tectÃ©s pour ce script
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
    
    # CrÃ©er un tableau pour stocker les suggestions
    $Suggestions = @()
    
    # Traiter chaque anti-pattern
    foreach ($AntiPattern in $AntiPatterns.Patterns) {
        # GÃ©nÃ©rer une suggestion basÃ©e sur le type d'anti-pattern
        switch ($AntiPattern.Type) {
            "DeadCode" {
                $Suggestions += [PSCustomObject]@{
                    Type = "AntiPattern"
                    Category = "Maintenance"
                    Severity = "Medium"
                    Title = "Code mort dÃ©tectÃ©"
                    Description = "Le script contient du code qui n'est jamais exÃ©cutÃ© (lignes $($AntiPattern.LineNumbers -join ', '))."
                    Recommendation = "Supprimer le code mort pour amÃ©liorer la lisibilitÃ© et rÃ©duire la taille du script."
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
                    Title = "Code dupliquÃ© dÃ©tectÃ©"
                    Description = "Le script contient du code dupliquÃ© (lignes $($AntiPattern.LineNumbers -join ', ')). La duplication viole le principe DRY (Don't Repeat Yourself)."
                    Recommendation = "Extraire le code dupliquÃ© dans une fonction rÃ©utilisable."
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
                    Title = "Nombres magiques dÃ©tectÃ©s"
                    Description = "Le script utilise des nombres magiques (lignes $($AntiPattern.LineNumbers -join ', ')). Les nombres codÃ©s en dur rÃ©duisent la maintenabilitÃ©."
                    Recommendation = "Remplacer les nombres magiques par des constantes nommÃ©es qui expliquent leur signification."
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
                    Title = "MÃ©thode trop longue"
                    Description = "Le script contient une mÃ©thode trÃ¨s longue ($($AntiPattern.Details.Length) lignes). Les mÃ©thodes longues sont difficiles Ã  comprendre et Ã  maintenir."
                    Recommendation = "Diviser la mÃ©thode en plusieurs mÃ©thodes plus petites, chacune avec une responsabilitÃ© unique."
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
                    Description = "Le script contient une imbrication profonde (niveau $($AntiPattern.Details.Depth)). Une imbrication excessive rend le code difficile Ã  suivre."
                    Recommendation = "RÃ©duire la profondeur d'imbrication en extrayant des mÃ©thodes ou en utilisant des clauses de garde."
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
                    Description = "Le script utilise des variables globales. Les variables globales crÃ©ent des dÃ©pendances cachÃ©es et rendent le code difficile Ã  tester."
                    Recommendation = "Passer les variables en paramÃ¨tres aux fonctions plutÃ´t que d'utiliser des variables globales."
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
                    Title = "Chemins codÃ©s en dur"
                    Description = "Le script contient des chemins codÃ©s en dur. Cela rÃ©duit la portabilitÃ© du script."
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
                    Title = "Bloc catch gÃ©nÃ©rique"
                    Description = "Le script utilise un bloc catch gÃ©nÃ©rique qui capture toutes les exceptions. Cela peut masquer des erreurs importantes."
                    Recommendation = "Capturer uniquement les exceptions spÃ©cifiques que vous pouvez gÃ©rer correctement."
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
                    Description = "Le script ne contient pas de gestion des erreurs pour des opÃ©rations critiques."
                    Recommendation = "Ajouter des blocs try-catch pour gÃ©rer les erreurs potentielles et fournir des messages d'erreur utiles."
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
