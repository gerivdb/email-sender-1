# Module de planification de refactoring pour le Script Manager
# Ce module planifie les opÃ©rations de refactoring
# Author: Script Manager
# Version: 1.0
# Tags: optimization, refactoring, planning

function New-RefactoringPlan {
    <#
    .SYNOPSIS
        CrÃ©e un plan de refactoring pour un script
    .DESCRIPTION
        Analyse les suggestions et crÃ©e un plan de refactoring
    .PARAMETER Script
        Script Ã  refactorer
    .PARAMETER Suggestions
        Suggestions d'amÃ©lioration pour le script
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

    # CrÃ©er un objet pour stocker le plan
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

    # Trier les suggestions par sÃ©vÃ©ritÃ© et auto-corrigeabilitÃ©
    $SortedSuggestions = $Suggestions | Sort-Object -Property {
        switch ($_.Severity) {
            "High" { 0 }
            "Medium" { 1 }
            "Low" { 2 }
            default { 3 }
        }
    }, { if ($_.AutoFixable) { 0 } else { 1 } }

    # CrÃ©er les opÃ©rations de refactoring
    foreach ($Suggestion in $SortedSuggestions) {
        $Operation = Create-RefactoringOperation -Script $Script -Suggestion $Suggestion -Content $Content

        if ($Operation) {
            $Plan.Operations += $Operation
        }
    }

    # DÃ©terminer les dÃ©pendances entre opÃ©rations
    $Plan.Dependencies = Find-OperationDependencies -Operations $Plan.Operations

    # Estimer la complexitÃ© du refactoring
    $Plan.EstimatedComplexity = Estimate-RefactoringComplexity -Operations $Plan.Operations

    # DÃ©terminer la prioritÃ© du refactoring
    $Plan.Priority = Determine-RefactoringPriority -Script $Script -Suggestions $Suggestions

    return $Plan
}

function Create-RefactoringOperation {
    <#
    .SYNOPSIS
        CrÃ©e une opÃ©ration de refactoring
    .DESCRIPTION
        CrÃ©e une opÃ©ration de refactoring basÃ©e sur une suggestion
    .PARAMETER Script
        Script Ã  refactorer
    .PARAMETER Suggestion
        Suggestion d'amÃ©lioration
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

    # CrÃ©er un objet pour stocker l'opÃ©ration
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

    # DÃ©finir la transformation selon le type de suggestion
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
        Trouve les dÃ©pendances entre opÃ©rations de refactoring
    .DESCRIPTION
        Analyse les opÃ©rations pour dÃ©terminer leurs dÃ©pendances
    .PARAMETER Operations
        OpÃ©rations de refactoring
    .EXAMPLE
        Find-OperationDependencies -Operations $operations
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [array]$Operations
    )

    # CrÃ©er un tableau pour stocker les dÃ©pendances
    $Dependencies = @()

    # Parcourir les opÃ©rations
    for ($i = 0; $i -lt $Operations.Count; $i++) {
        $Operation1 = $Operations[$i]

        for ($j = 0; $j -lt $Operations.Count; $j++) {
            if ($i -eq $j) {
                continue
            }

            $Operation2 = $Operations[$j]

            # VÃ©rifier si les opÃ©rations se chevauchent
            if ($Operation1.LineNumbers -and $Operation2.LineNumbers) {
                $Overlap = $false

                foreach ($Line1 in $Operation1.LineNumbers) {
                    if ($Operation2.LineNumbers -contains $Line1) {
                        $Overlap = $true
                        break
                    }
                }

                if ($Overlap) {
                    # DÃ©terminer l'ordre des opÃ©rations
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

            # VÃ©rifier les dÃ©pendances logiques
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
        Estime la complexitÃ© du refactoring
    .DESCRIPTION
        Analyse les opÃ©rations pour estimer la complexitÃ© globale du refactoring
    .PARAMETER Operations
        OpÃ©rations de refactoring
    .EXAMPLE
        Estimate-RefactoringComplexity -Operations $operations
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [array]$Operations
    )

    # Compter les opÃ©rations par sÃ©vÃ©ritÃ©
    $HighCount = ($Operations | Where-Object { $_.Severity -eq "High" } | Measure-Object).Count
    $MediumCount = ($Operations | Where-Object { $_.Severity -eq "Medium" } | Measure-Object).Count
    $LowCount = ($Operations | Where-Object { $_.Severity -eq "Low" } | Measure-Object).Count

    # Compter les opÃ©rations auto-corrigeables
    $AutoFixableCount = ($Operations | Where-Object { $_.AutoFixable -eq $true } | Measure-Object).Count

    # Estimer la complexitÃ©
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
        DÃ©termine la prioritÃ© du refactoring
    .DESCRIPTION
        Analyse le script et les suggestions pour dÃ©terminer la prioritÃ© du refactoring
    .PARAMETER Script
        Script Ã  refactorer
    .PARAMETER Suggestions
        Suggestions d'amÃ©lioration
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

    # Compter les suggestions par sÃ©vÃ©ritÃ©
    $HighCount = ($Suggestions | Where-Object { $_.Severity -eq "High" } | Measure-Object).Count
    $MediumCount = ($Suggestions | Where-Object { $_.Severity -eq "Medium" } | Measure-Object).Count

    # VÃ©rifier si le script a des problÃ¨mes critiques
    $HasCriticalProblems = $Script.Problems | Where-Object { $_.Severity -eq "Critical" }

    # VÃ©rifier si le script est utilisÃ© par d'autres scripts
    $IsUsedByOthers = $Script.UsedBy -and $Script.UsedBy.Count -gt 0

    # DÃ©terminer la prioritÃ©
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
        CrÃ©e une transformation pour une suggestion de qualitÃ©
    .DESCRIPTION
        CrÃ©e une transformation basÃ©e sur une suggestion de qualitÃ©
    .PARAMETER Script
        Script Ã  refactorer
    .PARAMETER Suggestion
        Suggestion d'amÃ©lioration
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

    # CrÃ©er un objet pour stocker la transformation
    $Transformation = [PSCustomObject]@{
        Type = "Quality"
        Description = $Suggestion.Recommendation
        BeforeCode = $Suggestion.CodeSnippet
        AfterCode = $null
        LineNumbers = $Suggestion.LineNumbers
    }

    # DÃ©finir la transformation selon le titre de la suggestion
    switch -Regex ($Suggestion.Title) {
        "Ratio de commentaires faible" {
            $Transformation.Type = "AddComments"
            $Transformation.Description = "Ajouter des commentaires pour expliquer le code"
        }
        "Lignes trop longues" {
            $Transformation.Type = "SplitLines"
            $Transformation.Description = "Diviser les longues lignes en plusieurs lignes plus courtes"
        }
        "ComplexitÃ© Ã©levÃ©e" {
            $Transformation.Type = "ExtractMethod"
            $Transformation.Description = "Extraire des parties du code dans des mÃ©thodes sÃ©parÃ©es"
        }
        "Script monolithique" {
            $Transformation.Type = "Modularize"
            $Transformation.Description = "Diviser le script en fonctions logiques"
        }
        "Trop de lignes vides" {
            $Transformation.Type = "RemoveEmptyLines"
            $Transformation.Description = "RÃ©duire le nombre de lignes vides"
        }
        "Pas assez de lignes vides" {
            $Transformation.Type = "AddEmptyLines"
            $Transformation.Description = "Ajouter des lignes vides pour sÃ©parer les sections logiques"
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
        CrÃ©e une transformation pour une suggestion d'anti-pattern
    .DESCRIPTION
        CrÃ©e une transformation basÃ©e sur une suggestion d'anti-pattern
    .PARAMETER Script
        Script Ã  refactorer
    .PARAMETER Suggestion
        Suggestion d'amÃ©lioration
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

    # CrÃ©er un objet pour stocker la transformation
    $Transformation = [PSCustomObject]@{
        Type = "AntiPattern"
        Description = $Suggestion.Recommendation
        BeforeCode = $Suggestion.CodeSnippet
        AfterCode = $null
        LineNumbers = $Suggestion.LineNumbers
    }

    # DÃ©finir la transformation selon le type d'anti-pattern
    switch ($Suggestion.Type) {
        "DeadCode" {
            $Transformation.Type = "RemoveCode"
            $Transformation.Description = "Supprimer le code mort"
        }
        "DuplicateCode" {
            $Transformation.Type = "ExtractMethod"
            $Transformation.Description = "Extraire le code dupliquÃ© dans une fonction rÃ©utilisable"
        }
        "MagicNumber" {
            $Transformation.Type = "ExtractConstant"
            $Transformation.Description = "Remplacer les nombres magiques par des constantes nommÃ©es"
        }
        "LongMethod" {
            $Transformation.Type = "SplitMethod"
            $Transformation.Description = "Diviser la mÃ©thode en plusieurs mÃ©thodes plus petites"
        }
        "DeepNesting" {
            $Transformation.Type = "ReduceNesting"
            $Transformation.Description = "RÃ©duire la profondeur d'imbrication"
        }
        "GlobalVariable" {
            $Transformation.Type = "ParameterizeVariable"
            $Transformation.Description = "Passer les variables en paramÃ¨tres aux fonctions"
        }
        "HardcodedPath" {
            $Transformation.Type = "ExtractPath"
            $Transformation.Description = "Remplacer les chemins codÃ©s en dur par des variables"
        }
        "CatchAll" {
            $Transformation.Type = "SpecifyException"
            $Transformation.Description = "SpÃ©cifier les exceptions Ã  capturer"
        }
        "NoErrorHandling" {
            $Transformation.Type = "AddErrorHandling"
            $Transformation.Description = "Ajouter des blocs try-catch pour gÃ©rer les erreurs"
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
        CrÃ©e une transformation pour une suggestion spÃ©cifique au type
    .DESCRIPTION
        CrÃ©e une transformation basÃ©e sur une suggestion spÃ©cifique au type de script
    .PARAMETER Script
        Script Ã  refactorer
    .PARAMETER Suggestion
        Suggestion d'amÃ©lioration
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

    # CrÃ©er un objet pour stocker la transformation
    $Transformation = [PSCustomObject]@{
        Type = "TypeSpecific"
        Description = $Suggestion.Recommendation
        BeforeCode = $Suggestion.CodeSnippet
        AfterCode = $null
        LineNumbers = $Suggestion.LineNumbers
    }

    # DÃ©finir la transformation selon le titre de la suggestion et le type de script
    switch ($Script.Type) {
        "PowerShell" {
            switch -Regex ($Suggestion.Title) {
                "Comparaison avec \`$null du mauvais cÃ´tÃ©" {
                    $Transformation.Type = "FixNullComparison"
                    $Transformation.Description = "Placer `$null Ã  gauche des comparaisons"
                }
                "Verbes non approuvÃ©s" {
                    $Transformation.Type = "RenameFunction"
                    $Transformation.Description = "Renommer les fonctions avec des verbes approuvÃ©s"
                }
                "Write-Host sans couleur" {
                    $Transformation.Type = "AddForegroundColor"
                    $Transformation.Description = "Ajouter le paramÃ¨tre -ForegroundColor aux appels Ã  Write-Host"
                }
                "ParamÃ¨tre switch avec valeur par dÃ©faut" {
                    $Transformation.Type = "FixSwitchParameter"
                    $Transformation.Description = "Supprimer la valeur par dÃ©faut des paramÃ¨tres switch"
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
                "Bloc except gÃ©nÃ©rique" {
                    $Transformation.Type = "SpecifyException"
                    $Transformation.Description = "SpÃ©cifier le type d'exception Ã  capturer"
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
                    $Transformation.Description = "Ajouter @ECHO OFF au dÃ©but du script"
                }
                "Absence de SETLOCAL" {
                    $Transformation.Type = "AddSetlocal"
                    $Transformation.Description = "Ajouter SETLOCAL au dÃ©but du script"
                }
                "Absence de vÃ©rification des erreurs" {
                    $Transformation.Type = "AddErrorCheck"
                    $Transformation.Description = "Ajouter des vÃ©rifications IF %ERRORLEVEL% NEQ 0"
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
                    $Transformation.Description = "Ajouter #!/bin/bash en premiÃ¨re ligne du script"
                }
                "Absence de set -e" {
                    $Transformation.Type = "AddSetE"
                    $Transformation.Description = "Ajouter set -e au dÃ©but du script"
                }
                "Utilisation de \[ \] au lieu de \[\[ \]\]" {
                    $Transformation.Type = "ReplaceTestOperator"
                    $Transformation.Description = "Remplacer [ ] par [[ ]]"
                }
                "Variables non entourÃ©es de guillemets" {
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
        Estime l'impact d'une opÃ©ration de refactoring
    .DESCRIPTION
        Analyse l'opÃ©ration pour estimer son impact sur le code
    .PARAMETER Operation
        OpÃ©ration de refactoring
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
