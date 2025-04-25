# Module de transformation de code pour le Script Manager
# Ce module transforme le code selon les opérations de refactoring
# Author: Script Manager
# Version: 1.0
# Tags: optimization, refactoring, transformation

function Get-RefactoringSuggestions {
    <#
    .SYNOPSIS
        Génère des suggestions de refactoring
    .DESCRIPTION
        Génère des suggestions de refactoring basées sur le plan
    .PARAMETER Script
        Script à refactorer
    .PARAMETER Plan
        Plan de refactoring
    .PARAMETER OutputPath
        Chemin où enregistrer les suggestions
    .EXAMPLE
        Get-RefactoringSuggestions -Script $script -Plan $plan -OutputPath "refactoring"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Script,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Plan,

        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )

    # Créer un objet pour stocker les résultats
    $Result = [PSCustomObject]@{
        ScriptPath = $Script.Path
        ScriptName = $Script.Name
        ScriptType = $Script.Type
        Success = $true
        Suggestions = @()
        ErrorMessage = $null
    }

    # Lire le contenu du script
    $Content = Get-Content -Path $Script.Path -Raw -ErrorAction SilentlyContinue

    if ($null -eq $Content) {
        $Result.Success = $false
        $Result.ErrorMessage = "Impossible de lire le contenu du script"
        return $Result
    }

    # Générer des suggestions pour chaque opération
    foreach ($Operation in $Plan.Operations) {
        $Suggestion = [PSCustomObject]@{
            Title = $Operation.Title
            Description = $Operation.Description
            Recommendation = $Operation.Recommendation
            TransformationType = $Operation.Transformation.Type
            TransformationDescription = $Operation.Transformation.Description
            BeforeCode = $Operation.Transformation.BeforeCode
            AfterCode = $null
            LineNumbers = $Operation.LineNumbers
            EstimatedImpact = $Operation.EstimatedImpact
            AutoFixable = $Operation.AutoFixable
        }

        # Générer le code transformé
        if ($Operation.AutoFixable) {
            try {
                $Suggestion.AfterCode = Generate-TransformedCode -Script $Script -Operation $Operation -Content $Content
            } catch {
                $Suggestion.AfterCode = "# Erreur lors de la génération du code transformé: $_"
            }
        }

        $Result.Suggestions += $Suggestion
    }

    # Enregistrer les suggestions dans un fichier
    $SuggestionsPath = Join-Path -Path $OutputPath -ChildPath "$($Script.Name)_suggestions.json"
    $Result | ConvertTo-Json -Depth 10 | Set-Content -Path $SuggestionsPath

    return $Result
}

function Invoke-InteractiveRefactoring {
    <#
    .SYNOPSIS
        Exécute un refactoring interactif
    .DESCRIPTION
        Exécute un refactoring interactif basé sur le plan
    .PARAMETER Script
        Script à refactorer
    .PARAMETER Plan
        Plan de refactoring
    .PARAMETER OutputPath
        Chemin où enregistrer les résultats
    .EXAMPLE
        Invoke-InteractiveRefactoring -Script $script -Plan $plan -OutputPath "refactoring"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Script,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Plan,

        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )

    # Créer un objet pour stocker les résultats
    $Result = [PSCustomObject]@{
        ScriptPath = $Script.Path
        ScriptName = $Script.Name
        ScriptType = $Script.Type
        Success = $true
        Operations = @()
        ErrorMessage = $null
    }

    # Lire le contenu du script
    $Content = Get-Content -Path $Script.Path -Raw -ErrorAction SilentlyContinue

    if ($null -eq $Content) {
        $Result.Success = $false
        $Result.ErrorMessage = "Impossible de lire le contenu du script"
        return $Result
    }

    # Créer une copie du script
    $RefactoredScriptPath = Join-Path -Path $OutputPath -ChildPath "$($Script.Name)_refactored$($Script.Extension)"
    Set-Content -Path $RefactoredScriptPath -Value $Content

    # Exécuter les opérations de refactoring
    foreach ($Operation in $Plan.Operations) {
        $OperationResult = [PSCustomObject]@{
            Title = $Operation.Title
            TransformationType = $Operation.Transformation.Type
            Success = $false
            BeforeCode = $Operation.Transformation.BeforeCode
            AfterCode = $null
            LineNumbers = $Operation.LineNumbers
            ErrorMessage = $null
        }

        # Générer le code transformé
        try {
            $TransformedCode = Generate-TransformedCode -Script $Script -Operation $Operation -Content $Content
            $OperationResult.AfterCode = $TransformedCode

            # Demander confirmation à l'utilisateur
            Write-Host "`n=== Opération de refactoring: $($Operation.Title) ===" -ForegroundColor Cyan
            Write-Host "Description: $($Operation.Description)" -ForegroundColor Yellow
            Write-Host "Recommandation: $($Operation.Recommendation)" -ForegroundColor Yellow
            Write-Host "Impact estimé: $($Operation.EstimatedImpact)" -ForegroundColor Yellow
            Write-Host "`nCode avant:" -ForegroundColor Magenta
            Write-Host $Operation.Transformation.BeforeCode -ForegroundColor Gray
            Write-Host "`nCode après:" -ForegroundColor Magenta
            Write-Host $TransformedCode -ForegroundColor Gray

            $Confirmation = Read-Host "`nAppliquer cette transformation? (O/N)"

            if ($Confirmation -eq "O" -or $Confirmation -eq "o") {
                # Appliquer la transformation
                $Content = Apply-Transformation -Script $Script -Operation $Operation -Content $Content -TransformedCode $TransformedCode
                Set-Content -Path $RefactoredScriptPath -Value $Content
                $OperationResult.Success = $true
            } else {
                $OperationResult.ErrorMessage = "Transformation refusée par l'utilisateur"
            }
        } catch {
            $OperationResult.ErrorMessage = "Erreur lors de la transformation: $_"
        }

        $Result.Operations += $OperationResult
    }

    # Enregistrer les résultats dans un fichier
    $ResultsPath = Join-Path -Path $OutputPath -ChildPath "$($Script.Name)_results.json"
    $Result | ConvertTo-Json -Depth 10 | Set-Content -Path $ResultsPath

    return $Result
}

function Invoke-AutomaticRefactoring {
    <#
    .SYNOPSIS
        Exécute un refactoring automatique
    .DESCRIPTION
        Exécute un refactoring automatique basé sur le plan
    .PARAMETER Script
        Script à refactorer
    .PARAMETER Plan
        Plan de refactoring
    .PARAMETER OutputPath
        Chemin où enregistrer les résultats
    .EXAMPLE
        Invoke-AutomaticRefactoring -Script $script -Plan $plan -OutputPath "refactoring"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Script,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Plan,

        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )

    # Créer un objet pour stocker les résultats
    $Result = [PSCustomObject]@{
        ScriptPath = $Script.Path
        ScriptName = $Script.Name
        ScriptType = $Script.Type
        Success = $true
        Operations = @()
        ErrorMessage = $null
    }

    # Lire le contenu du script
    $Content = Get-Content -Path $Script.Path -Raw -ErrorAction SilentlyContinue

    if ($null -eq $Content) {
        $Result.Success = $false
        $Result.ErrorMessage = "Impossible de lire le contenu du script"
        return $Result
    }

    # Créer une copie du script
    $RefactoredScriptPath = Join-Path -Path $OutputPath -ChildPath "$($Script.Name)_refactored$($Script.Extension)"
    Set-Content -Path $RefactoredScriptPath -Value $Content

    # Filtrer les opérations auto-corrigeables
    $AutoFixableOperations = $Plan.Operations | Where-Object { $_.AutoFixable -eq $true }

    # Exécuter les opérations de refactoring
    foreach ($Operation in $AutoFixableOperations) {
        $OperationResult = [PSCustomObject]@{
            Title = $Operation.Title
            TransformationType = $Operation.Transformation.Type
            Success = $false
            BeforeCode = $Operation.Transformation.BeforeCode
            AfterCode = $null
            LineNumbers = $Operation.LineNumbers
            ErrorMessage = $null
        }

        # Générer le code transformé
        try {
            $TransformedCode = Generate-TransformedCode -Script $Script -Operation $Operation -Content $Content
            $OperationResult.AfterCode = $TransformedCode

            # Appliquer la transformation
            $Content = Apply-Transformation -Script $Script -Operation $Operation -Content $Content -TransformedCode $TransformedCode
            Set-Content -Path $RefactoredScriptPath -Value $Content
            $OperationResult.Success = $true
        } catch {
            $OperationResult.ErrorMessage = "Erreur lors de la transformation: $_"
        }

        $Result.Operations += $OperationResult
    }

    # Enregistrer les résultats dans un fichier
    $ResultsPath = Join-Path -Path $OutputPath -ChildPath "$($Script.Name)_results.json"
    $Result | ConvertTo-Json -Depth 10 | Set-Content -Path $ResultsPath

    return $Result
}

function Generate-TransformedCode {
    <#
    .SYNOPSIS
        Génère le code transformé
    .DESCRIPTION
        Génère le code transformé selon l'opération de refactoring
    .PARAMETER Script
        Script à refactorer
    .PARAMETER Operation
        Opération de refactoring
    .PARAMETER Content
        Contenu du script
    .EXAMPLE
        Generate-TransformedCode -Script $script -Operation $operation -Content $content
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Script,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Operation,

        [Parameter(Mandatory=$true)]
        [string]$Content
    )

    # Générer le code transformé selon le type de transformation
    switch ($Operation.Transformation.Type) {
        # Transformations communes
        "RemoveCode" {
            return "# Code supprimé"
        }
        "ExtractConstant" {
            return Transform-ExtractConstant -Script $Script -Operation $Operation -Content $Content
        }
        "ExtractPath" {
            return Transform-ExtractPath -Script $Script -Operation $Operation -Content $Content
        }

        # Transformations PowerShell
        "FixNullComparison" {
            return Transform-FixNullComparison -Script $Script -Operation $Operation -Content $Content
        }
        "AddForegroundColor" {
            return Transform-AddForegroundColor -Script $Script -Operation $Operation -Content $Content
        }
        "FixSwitchParameter" {
            return Transform-FixSwitchParameter -Script $Script -Operation $Operation -Content $Content
        }

        # Transformations Python
        "ReplaceWithLogging" {
            return Transform-ReplaceWithLogging -Script $Script -Operation $Operation -Content $Content
        }
        "SpecifyException" {
            return Transform-SpecifyException -Script $Script -Operation $Operation -Content $Content
        }
        "AddMainGuard" {
            return Transform-AddMainGuard -Script $Script -Operation $Operation -Content $Content
        }

        # Transformations Batch
        "AddEchoOff" {
            return "@ECHO OFF`n" + $Operation.Transformation.BeforeCode
        }
        "AddSetlocal" {
            return "SETLOCAL`n" + $Operation.Transformation.BeforeCode
        }
        "AddErrorCheck" {
            return Transform-AddErrorCheck -Script $Script -Operation $Operation -Content $Content
        }

        # Transformations Shell
        "AddShebang" {
            return "#!/bin/bash`n" + $Operation.Transformation.BeforeCode
        }
        "AddSetE" {
            return "set -e`n" + $Operation.Transformation.BeforeCode
        }
        "ReplaceTestOperator" {
            return Transform-ReplaceTestOperator -Script $Script -Operation $Operation -Content $Content
        }
        "QuoteVariables" {
            return Transform-QuoteVariables -Script $Script -Operation $Operation -Content $Content
        }

        # Transformation par défaut
        default {
            return $Operation.Transformation.BeforeCode
        }
    }
}

function Apply-Transformation {
    <#
    .SYNOPSIS
        Applique une transformation au contenu du script
    .DESCRIPTION
        Remplace le code original par le code transformé
    .PARAMETER Script
        Script à refactorer
    .PARAMETER Operation
        Opération de refactoring
    .PARAMETER Content
        Contenu du script
    .PARAMETER TransformedCode
        Code transformé
    .EXAMPLE
        Apply-Transformation -Script $script -Operation $operation -Content $content -TransformedCode $transformedCode
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Script,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Operation,

        [Parameter(Mandatory=$true)]
        [string]$Content,

        [Parameter(Mandatory=$true)]
        [string]$TransformedCode
    )

    # Si aucun numéro de ligne n'est spécifié, retourner le contenu inchangé
    if (-not $Operation.LineNumbers -or $Operation.LineNumbers.Count -eq 0) {
        return $Content
    }

    # Diviser le contenu en lignes
    $Lines = $Content -split "`n"

    # Déterminer les lignes à remplacer
    $StartLine = $Operation.LineNumbers[0] - 1
    $EndLine = $Operation.LineNumbers[-1] - 1

    # Vérifier que les lignes sont valides
    if ($StartLine -lt 0 -or $EndLine -ge $Lines.Count) {
        throw "Numéros de ligne invalides: $StartLine-$EndLine (total: $($Lines.Count))"
    }

    # Remplacer les lignes
    $BeforeLines = $Lines[0..$StartLine]
    $AfterLines = $Lines[($EndLine + 1)..($Lines.Count - 1)]

    # Diviser le code transformé en lignes
    $TransformedLines = $TransformedCode -split "`n"

    # Reconstruire le contenu
    $NewContent = ($BeforeLines + $TransformedLines + $AfterLines) -join "`n"

    return $NewContent
}

# Fonctions de transformation spécifiques

function Transform-ExtractConstant {
    param ($Script, $Operation, $Content)

    # Extraire le nombre magique
    $Number = $Operation.Transformation.BeforeCode -match "(\d+)" | Out-Null
    $Number = $Matches[1]

    # Générer un nom de constante
    $ConstantName = "CONSTANT_$Number"

    # Remplacer le nombre par la constante
    $TransformedCode = $Operation.Transformation.BeforeCode -replace $Number, $ConstantName

    # Ajouter la définition de la constante
    $TransformedCode = "# Constante extraite`n$ConstantName = $Number`n`n" + $TransformedCode

    return $TransformedCode
}

function Transform-ExtractPath {
    param ($Script, $Operation, $Content)

    # Extraire le chemin
    $Path = $Operation.Transformation.BeforeCode -match "((?:[A-Z]:\\|\/(?:home|usr|var|etc|opt)\/)[^\s\""\'\r\n]+)" | Out-Null
    $Path = $Matches[1]

    # Générer un nom de variable
    $PathName = "PATH_" + ($Path -replace "[\\\/\.\:]", "_")

    # Remplacer le chemin par la variable
    $TransformedCode = $Operation.Transformation.BeforeCode -replace [regex]::Escape($Path), $PathName

    # Ajouter la définition de la variable
    if ($Script.Type -eq "PowerShell") {
        $TransformedCode = "# Chemin extrait`n`$$PathName = `"$Path`"`n`n" + $TransformedCode
    } elseif ($Script.Type -eq "Python") {
        $TransformedCode = "# Chemin extrait`n$PathName = '$Path'`n`n" + $TransformedCode
    } elseif ($Script.Type -eq "Batch") {
        $TransformedCode = "REM Chemin extrait`nSET $PathName=$Path`n`n" + $TransformedCode
    } elseif ($Script.Type -eq "Shell") {
        $TransformedCode = "# Chemin extrait`n$PathName='$Path'`n`n" + $TransformedCode
    }

    return $TransformedCode
}

function Transform-FixNullComparison {
    param ($Script, $Operation, $Content)

    # Remplacer les comparaisons avec $null
    $TransformedCode = $Operation.Transformation.BeforeCode -replace "(\`$\w+)\s*-eq\s*\`$null", "`$null -eq `$1"
    $TransformedCode = $TransformedCode -replace "(\`$\w+)\s*-ne\s*\`$null", "`$null -ne `$1"

    return $TransformedCode
}

function Transform-AddForegroundColor {
    param ($Script, $Operation, $Content)

    # Ajouter le paramètre -ForegroundColor
    $TransformedCode = $Operation.Transformation.BeforeCode -replace "Write-Host\s+([^-]+)(?!-ForegroundColor)", "Write-Host `$1 -ForegroundColor Green"

    return $TransformedCode
}

function Transform-FixSwitchParameter {
    param ($Script, $Operation, $Content)

    # Supprimer la valeur par défaut des paramètres switch
    $TransformedCode = $Operation.Transformation.BeforeCode -replace "\[switch\]\`$(\w+)\s*=\s*\`$true", "[switch]`$`$1"

    return $TransformedCode
}

function Transform-ReplaceWithLogging {
    param ($Script, $Operation, $Content)

    # Remplacer print() par logging.info()
    $TransformedCode = $Operation.Transformation.BeforeCode -replace "print\s*\(([^)]*)\)", "logging.info(`$1)"

    # Ajouter l'import de logging s'il n'existe pas
    if (-not ($Content -match "import\s+logging")) {
        $TransformedCode = "import logging`n`n" + $TransformedCode
    }

    return $TransformedCode
}

function Transform-SpecifyException {
    param ($Script, $Operation, $Content)

    # Remplacer except: par except Exception:
    if ($Script.Type -eq "Python") {
        $TransformedCode = $Operation.Transformation.BeforeCode -replace "except\s*:", "except Exception:"
    } else {
        $TransformedCode = $Operation.Transformation.BeforeCode -replace "catch\s*{", "catch [System.Exception] {"
    }

    return $TransformedCode
}

function Transform-AddMainGuard {
    param ($Script, $Operation, $Content)

    # Ajouter le bloc if __name__ == "__main__":
    $TransformedCode = $Operation.Transformation.BeforeCode + "`n`nif __name__ == '__main__':`n    # Code principal ici`n    pass"

    return $TransformedCode
}

function Transform-AddErrorCheck {
    param ($Script, $Operation, $Content)

    # Ajouter des vérifications d'erreur
    $Lines = $Operation.Transformation.BeforeCode -split "`n"
    $TransformedLines = @()

    foreach ($Line in $Lines) {
        $TransformedLines += $Line

        # Ajouter une vérification d'erreur après les commandes
        if ($Line -match "^\s*(call|copy|move|del|mkdir|rmdir|xcopy|robocopy|start|net|reg|sc)") {
            $TransformedLines += "IF %ERRORLEVEL% NEQ 0 ("
            $TransformedLines += "    ECHO Erreur lors de l'exécution de la commande"
            $TransformedLines += "    EXIT /B %ERRORLEVEL%"
            $TransformedLines += ")"
        }
    }

    return $TransformedLines -join "`n"
}

function Transform-ReplaceTestOperator {
    param ($Script, $Operation, $Content)

    # Remplacer [ ] par [[ ]]
    $TransformedCode = $Operation.Transformation.BeforeCode -replace "\[ ", "[[ " -replace " \]", " ]]"

    return $TransformedCode
}

function Transform-QuoteVariables {
    param ($Script, $Operation, $Content)

    # Entourer les variables de guillemets
    $TransformedCode = $Operation.Transformation.BeforeCode -replace "(\$\w+)", "'`$1'"

    return $TransformedCode
}

# Exporter les fonctions
Export-ModuleMember -Function Get-RefactoringSuggestions, Invoke-InteractiveRefactoring, Invoke-AutomaticRefactoring
