# Module de planification de refactoring pour le Script Manager
# Ce module planifie les opérations de refactoring
# Author: Script Manager
# Version: 1.0
# Tags: optimization, refactoring, planning

function New-RefactoringPlan {
    <#
    .SYNOPSIS
        Crée un plan de refactoring pour un script
    .DESCRIPTION
        Analyse les suggestions et crée un plan de refactoring
    .PARAMETER Script
        Script à refactorer
    .PARAMETER Suggestions
        Suggestions d'amélioration pour le script
    .EXAMPLE
        New-RefactoringPlan -Script $script -Suggestions $suggestions
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Script,

        [Parameter(Mandatory=$true)]
        [array]$Suggestions
    )

    # Créer un objet pour stocker le plan
    $Plan = [PSCustomObject]@{
        ScriptPath = $Script.Path
        ScriptName = $Script.Name
        ScriptType = $Script.Type
        Operations = @()
        Dependencies = @()
        EstimatedComplexity = "Low"
        Priority = "Medium"
    }

    # Lire le contenu du script
    $Content = Get-Content -Path $Script.Path -Raw -ErrorAction SilentlyContinue

    if ($null -eq $Content) {
        return $Plan
    }

    # Trier les suggestions par sévérité et auto-corrigeabilité
    $SortedSuggestions = $Suggestions | Sort-Object -Property {
        switch ($_.Severity) {
            "High" { 0 }
            "Medium" { 1 }
            "Low" { 2 }
            default { 3 }
        }
    }, { if ($_.AutoFixable) { 0 } else { 1 } }

    # Créer les opérations de refactoring
    foreach ($Suggestion in $SortedSuggestions) {
        $Operation = Create-RefactoringOperation -Script $Script -Suggestion $Suggestion -Content $Content

        if ($Operation) {
            $Plan.Operations += $Operation
        }
    }

    # Déterminer les dépendances entre opérations
    $Plan.Dependencies = Find-OperationDependencies -Operations $Plan.Operations

    # Estimer la complexité du refactoring
    $Plan.EstimatedComplexity = Estimate-RefactoringComplexity -Operations $Plan.Operations

    # Déterminer la priorité du refactoring
    $Plan.Priority = Determine-RefactoringPriority -Script $Script -Suggestions $Suggestions

    return $Plan
}

function Create-RefactoringOperation {
    <#
    .SYNOPSIS
        Crée une opération de refactoring
    .DESCRIPTION
        Crée une opération de refactoring basée sur une suggestion
    .PARAMETER Script
        Script à refactorer
    .PARAMETER Suggestion
        Suggestion d'amélioration
    .PARAMETER Content
        Contenu du script
    .EXAMPLE
        Create-RefactoringOperation -Script $script -Suggestion $suggestion -Content $content
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Script,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Suggestion,

        [Parameter(Mandatory=$true)]
        [string]$Content
    )

    # Créer un objet pour stocker l'opération
    $Operation = [PSCustomObject]@{
        Type = $Suggestion.Type
        Category = $Suggestion.Category
        Severity = $Suggestion.Severity
        Title = $Suggestion.Title
        Description = $Suggestion.Description
        Recommendation = $Suggestion.Recommendation
        LineNumbers = $Suggestion.LineNumbers
        CodeSnippet = $Suggestion.CodeSnippet
        AutoFixable = $Suggestion.AutoFixable
        Transformation = $null
        EstimatedImpact = "Low"
    }

    # Définir la transformation selon le type de suggestion
    switch ($Suggestion.Type) {
        "Quality" {
            $Operation.Transformation = Create-QualityTransformation -Script $Script -Suggestion $Suggestion -Content $Content
        }
        "AntiPattern" {
            $Operation.Transformation = Create-AntiPatternTransformation -Script $Script -Suggestion $Suggestion -Content $Content
        }
        "TypeSpecific" {
            $Operation.Transformation = Create-TypeSpecificTransformation -Script $Script -Suggestion $Suggestion -Content $Content
        }
        default {
            $Operation.Transformation = [PSCustomObject]@{
                Type = "Manual"
                Description = $Suggestion.Recommendation
                BeforeCode = $Suggestion.CodeSnippet
                AfterCode = $null
                LineNumbers = $Suggestion.LineNumbers
            }
        }
    }

    # Estimer l'impact du refactoring
    $Operation.EstimatedImpact = Estimate-OperationImpact -Operation $Operation

    return $Operation
}

function Find-OperationDependencies {
    <#
    .SYNOPSIS
        Trouve les dépendances entre opérations de refactoring
    .DESCRIPTION
        Analyse les opérations pour déterminer leurs dépendances
    .PARAMETER Operations
        Opérations de refactoring
    .EXAMPLE
        Find-OperationDependencies -Operations $operations
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [array]$Operations
    )

    # Créer un tableau pour stocker les dépendances
    $Dependencies = @()

    # Parcourir les opérations
    for ($i = 0; $i -lt $Operations.Count; $i++) {
        $Operation1 = $Operations[$i]

        for ($j = 0; $j -lt $Operations.Count; $j++) {
            if ($i -eq $j) {
                continue
            }

            $Operation2 = $Operations[$j]

            # Vérifier si les opérations se chevauchent
            if ($Operation1.LineNumbers -and $Operation2.LineNumbers) {
                $Overlap = $false

                foreach ($Line1 in $Operation1.LineNumbers) {
                    if ($Operation2.LineNumbers -contains $Line1) {
                        $Overlap = $true
                        break
                    }
                }

                if ($Overlap) {
                    # Déterminer l'ordre des opérations
                    $FirstOperation = if ($Operation1.Severity -eq "High" -or ($Operation1.Severity -eq "Medium" -and $Operation2.Severity -eq "Low")) {
                        $i
                    } else {
                        $j
                    }

                    $SecondOperation = if ($FirstOperation -eq $i) { $j } else { $i }

                    $Dependencies += [PSCustomObject]@{
                        FirstOperation = $FirstOperation
                        SecondOperation = $SecondOperation
                        Reason = "Overlap"
                    }
                }
            }

            # Vérifier les dépendances logiques
            if ($Operation1.Type -eq "AntiPattern" -and $Operation2.Type -eq "Quality" -and $Operation1.Category -eq $Operation2.Category) {
                $Dependencies += [PSCustomObject]@{
                    FirstOperation = $i
                    SecondOperation = $j
                    Reason = "Logical"
                }
            }
        }
    }

    return $Dependencies
}

function Estimate-RefactoringComplexity {
    <#
    .SYNOPSIS
        Estime la complexité du refactoring
    .DESCRIPTION
        Analyse les opérations pour estimer la complexité globale du refactoring
    .PARAMETER Operations
        Opérations de refactoring
    .EXAMPLE
        Estimate-RefactoringComplexity -Operations $operations
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [array]$Operations
    )

    # Compter les opérations par sévérité
    $HighCount = ($Operations | Where-Object { $_.Severity -eq "High" } | Measure-Object).Count
    $MediumCount = ($Operations | Where-Object { $_.Severity -eq "Medium" } | Measure-Object).Count
    $LowCount = ($Operations | Where-Object { $_.Severity -eq "Low" } | Measure-Object).Count

    # Compter les opérations auto-corrigeables
    $AutoFixableCount = ($Operations | Where-Object { $_.AutoFixable -eq $true } | Measure-Object).Count

    # Estimer la complexité
    if ($HighCount -gt 3 -or ($HighCount -gt 0 -and $MediumCount -gt 5)) {
        return "High"
    } elseif ($HighCount -gt 0 -or $MediumCount -gt 3 -or ($MediumCount -gt 0 -and $LowCount -gt 5)) {
        return "Medium"
    } else {
        return "Low"
    }
}

function Determine-RefactoringPriority {
    <#
    .SYNOPSIS
        Détermine la priorité du refactoring
    .DESCRIPTION
        Analyse le script et les suggestions pour déterminer la priorité du refactoring
    .PARAMETER Script
        Script à refactorer
    .PARAMETER Suggestions
        Suggestions d'amélioration
    .EXAMPLE
        Determine-RefactoringPriority -Script $script -Suggestions $suggestions
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Script,

        [Parameter(Mandatory=$true)]
        [array]$Suggestions
    )

    # Compter les suggestions par sévérité
    $HighCount = ($Suggestions | Where-Object { $_.Severity -eq "High" } | Measure-Object).Count
    $MediumCount = ($Suggestions | Where-Object { $_.Severity -eq "Medium" } | Measure-Object).Count

    # Vérifier si le script a des problèmes critiques
    $HasCriticalProblems = $Script.Problems | Where-Object { $_.Severity -eq "Critical" }

    # Vérifier si le script est utilisé par d'autres scripts
    $IsUsedByOthers = $Script.UsedBy -and $Script.UsedBy.Count -gt 0

    # Déterminer la priorité
    if ($HasCriticalProblems -or $HighCount -gt 2 -or ($IsUsedByOthers -and $HighCount -gt 0)) {
        return "High"
    } elseif ($HighCount -gt 0 -or $MediumCount -gt 3 -or $IsUsedByOthers) {
        return "Medium"
    } else {
        return "Low"
    }
}

function Create-QualityTransformation {
    <#
    .SYNOPSIS
        Crée une transformation pour une suggestion de qualité
    .DESCRIPTION
        Crée une transformation basée sur une suggestion de qualité
    .PARAMETER Script
        Script à refactorer
    .PARAMETER Suggestion
        Suggestion d'amélioration
    .PARAMETER Content
        Contenu du script
    .EXAMPLE
        Create-QualityTransformation -Script $script -Suggestion $suggestion -Content $content
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Script,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Suggestion,

        [Parameter(Mandatory=$true)]
        [string]$Content
    )

    # Créer un objet pour stocker la transformation
    $Transformation = [PSCustomObject]@{
        Type = "Quality"
        Description = $Suggestion.Recommendation
        BeforeCode = $Suggestion.CodeSnippet
        AfterCode = $null
        LineNumbers = $Suggestion.LineNumbers
    }

    # Définir la transformation selon le titre de la suggestion
    switch -Regex ($Suggestion.Title) {
        "Ratio de commentaires faible" {
            $Transformation.Type = "AddComments"
            $Transformation.Description = "Ajouter des commentaires pour expliquer le code"
        }
        "Lignes trop longues" {
            $Transformation.Type = "SplitLines"
            $Transformation.Description = "Diviser les longues lignes en plusieurs lignes plus courtes"
        }
        "Complexité élevée" {
            $Transformation.Type = "ExtractMethod"
            $Transformation.Description = "Extraire des parties du code dans des méthodes séparées"
        }
        "Script monolithique" {
            $Transformation.Type = "Modularize"
            $Transformation.Description = "Diviser le script en fonctions logiques"
        }
        "Trop de lignes vides" {
            $Transformation.Type = "RemoveEmptyLines"
            $Transformation.Description = "Réduire le nombre de lignes vides"
        }
        "Pas assez de lignes vides" {
            $Transformation.Type = "AddEmptyLines"
            $Transformation.Description = "Ajouter des lignes vides pour séparer les sections logiques"
        }
        default {
            $Transformation.Type = "Manual"
            $Transformation.Description = $Suggestion.Recommendation
        }
    }

    return $Transformation
}

function Create-AntiPatternTransformation {
    <#
    .SYNOPSIS
        Crée une transformation pour une suggestion d'anti-pattern
    .DESCRIPTION
        Crée une transformation basée sur une suggestion d'anti-pattern
    .PARAMETER Script
        Script à refactorer
    .PARAMETER Suggestion
        Suggestion d'amélioration
    .PARAMETER Content
        Contenu du script
    .EXAMPLE
        Create-AntiPatternTransformation -Script $script -Suggestion $suggestion -Content $content
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Script,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Suggestion,

        [Parameter(Mandatory=$true)]
        [string]$Content
    )

    # Créer un objet pour stocker la transformation
    $Transformation = [PSCustomObject]@{
        Type = "AntiPattern"
        Description = $Suggestion.Recommendation
        BeforeCode = $Suggestion.CodeSnippet
        AfterCode = $null
        LineNumbers = $Suggestion.LineNumbers
    }

    # Définir la transformation selon le type d'anti-pattern
    switch ($Suggestion.Type) {
        "DeadCode" {
            $Transformation.Type = "RemoveCode"
            $Transformation.Description = "Supprimer le code mort"
        }
        "DuplicateCode" {
            $Transformation.Type = "ExtractMethod"
            $Transformation.Description = "Extraire le code dupliqué dans une fonction réutilisable"
        }
        "MagicNumber" {
            $Transformation.Type = "ExtractConstant"
            $Transformation.Description = "Remplacer les nombres magiques par des constantes nommées"
        }
        "LongMethod" {
            $Transformation.Type = "SplitMethod"
            $Transformation.Description = "Diviser la méthode en plusieurs méthodes plus petites"
        }
        "DeepNesting" {
            $Transformation.Type = "ReduceNesting"
            $Transformation.Description = "Réduire la profondeur d'imbrication"
        }
        "GlobalVariable" {
            $Transformation.Type = "ParameterizeVariable"
            $Transformation.Description = "Passer les variables en paramètres aux fonctions"
        }
        "HardcodedPath" {
            $Transformation.Type = "ExtractPath"
            $Transformation.Description = "Remplacer les chemins codés en dur par des variables"
        }
        "CatchAll" {
            $Transformation.Type = "SpecifyException"
            $Transformation.Description = "Spécifier les exceptions à capturer"
        }
        "NoErrorHandling" {
            $Transformation.Type = "AddErrorHandling"
            $Transformation.Description = "Ajouter des blocs try-catch pour gérer les erreurs"
        }
        default {
            $Transformation.Type = "Manual"
            $Transformation.Description = $Suggestion.Recommendation
        }
    }

    return $Transformation
}

function Create-TypeSpecificTransformation {
    <#
    .SYNOPSIS
        Crée une transformation pour une suggestion spécifique au type
    .DESCRIPTION
        Crée une transformation basée sur une suggestion spécifique au type de script
    .PARAMETER Script
        Script à refactorer
    .PARAMETER Suggestion
        Suggestion d'amélioration
    .PARAMETER Content
        Contenu du script
    .EXAMPLE
        Create-TypeSpecificTransformation -Script $script -Suggestion $suggestion -Content $content
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Script,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Suggestion,

        [Parameter(Mandatory=$true)]
        [string]$Content
    )

    # Créer un objet pour stocker la transformation
    $Transformation = [PSCustomObject]@{
        Type = "TypeSpecific"
        Description = $Suggestion.Recommendation
        BeforeCode = $Suggestion.CodeSnippet
        AfterCode = $null
        LineNumbers = $Suggestion.LineNumbers
    }

    # Définir la transformation selon le titre de la suggestion et le type de script
    switch ($Script.Type) {
        "PowerShell" {
            switch -Regex ($Suggestion.Title) {
                "Comparaison avec \`$null du mauvais côté" {
                    $Transformation.Type = "FixNullComparison"
                    $Transformation.Description = "Placer `$null à gauche des comparaisons"
                }
                "Verbes non approuvés" {
                    $Transformation.Type = "RenameFunction"
                    $Transformation.Description = "Renommer les fonctions avec des verbes approuvés"
                }
                "Write-Host sans couleur" {
                    $Transformation.Type = "AddForegroundColor"
                    $Transformation.Description = "Ajouter le paramètre -ForegroundColor aux appels à Write-Host"
                }
                "Paramètre switch avec valeur par défaut" {
                    $Transformation.Type = "FixSwitchParameter"
                    $Transformation.Description = "Supprimer la valeur par défaut des paramètres switch"
                }
                default {
                    $Transformation.Type = "Manual"
                    $Transformation.Description = $Suggestion.Recommendation
                }
            }
        }
        "Python" {
            switch -Regex ($Suggestion.Title) {
                "Utilisation de print au lieu de logging" {
                    $Transformation.Type = "ReplaceWithLogging"
                    $Transformation.Description = "Remplacer print() par logging.info()"
                }
                "Bloc except générique" {
                    $Transformation.Type = "SpecifyException"
                    $Transformation.Description = "Spécifier le type d'exception à capturer"
                }
                "Absence de if __name__ == main" {
                    $Transformation.Type = "AddMainGuard"
                    $Transformation.Description = "Ajouter un bloc if __name__ == main:"
                }
                "Fonctions sans docstrings" {
                    $Transformation.Type = "AddDocstrings"
                    $Transformation.Description = "Ajouter des docstrings aux fonctions"
                }
                default {
                    $Transformation.Type = "Manual"
                    $Transformation.Description = $Suggestion.Recommendation
                }
            }
        }
        "Batch" {
            switch -Regex ($Suggestion.Title) {
                "Absence de @ECHO OFF" {
                    $Transformation.Type = "AddEchoOff"
                    $Transformation.Description = "Ajouter @ECHO OFF au début du script"
                }
                "Absence de SETLOCAL" {
                    $Transformation.Type = "AddSetlocal"
                    $Transformation.Description = "Ajouter SETLOCAL au début du script"
                }
                "Absence de vérification des erreurs" {
                    $Transformation.Type = "AddErrorCheck"
                    $Transformation.Description = "Ajouter des vérifications IF %ERRORLEVEL% NEQ 0"
                }
                default {
                    $Transformation.Type = "Manual"
                    $Transformation.Description = $Suggestion.Recommendation
                }
            }
        }
        "Shell" {
            switch -Regex ($Suggestion.Title) {
                "Absence de shebang" {
                    $Transformation.Type = "AddShebang"
                    $Transformation.Description = "Ajouter #!/bin/bash en première ligne du script"
                }
                "Absence de set -e" {
                    $Transformation.Type = "AddSetE"
                    $Transformation.Description = "Ajouter set -e au début du script"
                }
                "Utilisation de \[ \] au lieu de \[\[ \]\]" {
                    $Transformation.Type = "ReplaceTestOperator"
                    $Transformation.Description = "Remplacer [ ] par [[ ]]"
                }
                "Variables non entourées de guillemets" {
                    $Transformation.Type = "QuoteVariables"
                    $Transformation.Description = "Entourer les variables de guillemets"
                }
                default {
                    $Transformation.Type = "Manual"
                    $Transformation.Description = $Suggestion.Recommendation
                }
            }
        }
        default {
            $Transformation.Type = "Manual"
            $Transformation.Description = $Suggestion.Recommendation
        }
    }

    return $Transformation
}

function Estimate-OperationImpact {
    <#
    .SYNOPSIS
        Estime l'impact d'une opération de refactoring
    .DESCRIPTION
        Analyse l'opération pour estimer son impact sur le code
    .PARAMETER Operation
        Opération de refactoring
    .EXAMPLE
        Estimate-OperationImpact -Operation $operation
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Operation
    )

    # Estimer l'impact selon le type de transformation
    switch ($Operation.Transformation.Type) {
        { $_ -in "ExtractMethod", "SplitMethod", "Modularize" } {
            return "High"
        }
        { $_ -in "ReduceNesting", "ParameterizeVariable", "AddErrorHandling", "SpecifyException" } {
            return "Medium"
        }
        { $_ -in "RemoveCode", "ExtractConstant", "ExtractPath", "FixNullComparison", "AddForegroundColor", "FixSwitchParameter", "ReplaceWithLogging", "AddMainGuard", "AddDocstrings", "AddEchoOff", "AddSetlocal", "AddErrorCheck", "AddShebang", "AddSetE", "ReplaceTestOperator", "QuoteVariables" } {
            return "Low"
        }
        default {
            return "Medium"
        }
    }
}

# Exporter les fonctions
Export-ModuleMember -Function New-RefactoringPlan
