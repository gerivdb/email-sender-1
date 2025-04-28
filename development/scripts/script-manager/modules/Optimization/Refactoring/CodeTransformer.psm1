# Module de transformation de code pour le Script Manager
# Ce module transforme le code selon les opÃ©rations de refactoring
# Author: Script Manager
# Version: 1.0
# Tags: optimization, refactoring, transformation

function Get-RefactoringSuggestions {
    <#
    .SYNOPSIS
        GÃ©nÃ¨re des suggestions de refactoring
    .DESCRIPTION
        GÃ©nÃ¨re des suggestions de refactoring basÃ©es sur le plan
    .PARAMETER Script
        Script Ã  refactorer
    .PARAMETER Plan
        Plan de refactoring
    .PARAMETER OutputPath
        Chemin oÃ¹ enregistrer les suggestions
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

    # CrÃ©er un objet pour stocker les rÃ©sultats
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

    # GÃ©nÃ©rer des suggestions pour chaque opÃ©ration
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

        # GÃ©nÃ©rer le code transformÃ©
        if ($Operation.AutoFixable) {
            try {
                $Suggestion.AfterCode = Generate-TransformedCode -Script $Script -Operation $Operation -Content $Content
            } catch {
                $Suggestion.AfterCode = "# Erreur lors de la gÃ©nÃ©ration du code transformÃ©: $_"
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
        ExÃ©cute un refactoring interactif
    .DESCRIPTION
        ExÃ©cute un refactoring interactif basÃ© sur le plan
    .PARAMETER Script
        Script Ã  refactorer
    .PARAMETER Plan
        Plan de refactoring
    .PARAMETER OutputPath
        Chemin oÃ¹ enregistrer les rÃ©sultats
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

    # CrÃ©er un objet pour stocker les rÃ©sultats
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

    # CrÃ©er une copie du script
    $RefactoredScriptPath = Join-Path -Path $OutputPath -ChildPath "$($Script.Name)_refactored$($Script.Extension)"
    Set-Content -Path $RefactoredScriptPath -Value $Content

    # ExÃ©cuter les opÃ©rations de refactoring
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

        # GÃ©nÃ©rer le code transformÃ©
        try {
            $TransformedCode = Generate-TransformedCode -Script $Script -Operation $Operation -Content $Content
            $OperationResult.AfterCode = $TransformedCode

            # Demander confirmation Ã  l'utilisateur
            Write-Host "`n=== OpÃ©ration de refactoring: $($Operation.Title) ===" -ForegroundColor Cyan
            Write-Host "Description: $($Operation.Description)" -ForegroundColor Yellow
            Write-Host "Recommandation: $($Operation.Recommendation)" -ForegroundColor Yellow
            Write-Host "Impact estimÃ©: $($Operation.EstimatedImpact)" -ForegroundColor Yellow
            Write-Host "`nCode avant:" -ForegroundColor Magenta
            Write-Host $Operation.Transformation.BeforeCode -ForegroundColor Gray
            Write-Host "`nCode aprÃ¨s:" -ForegroundColor Magenta
            Write-Host $TransformedCode -ForegroundColor Gray

            $Confirmation = Read-Host "`nAppliquer cette transformation? (O/N)"

            if ($Confirmation -eq "O" -or $Confirmation -eq "o") {
                # Appliquer la transformation
                $Content = Apply-Transformation -Script $Script -Operation $Operation -Content $Content -TransformedCode $TransformedCode
                Set-Content -Path $RefactoredScriptPath -Value $Content
                $OperationResult.Success = $true
            } else {
                $OperationResult.ErrorMessage = "Transformation refusÃ©e par l'utilisateur"
            }
        } catch {
            $OperationResult.ErrorMessage = "Erreur lors de la transformation: $_"
        }

        $Result.Operations += $OperationResult
    }

    # Enregistrer les rÃ©sultats dans un fichier
    $ResultsPath = Join-Path -Path $OutputPath -ChildPath "$($Script.Name)_results.json"
    $Result | ConvertTo-Json -Depth 10 | Set-Content -Path $ResultsPath

    return $Result
}

function Invoke-AutomaticRefactoring {
    <#
    .SYNOPSIS
        ExÃ©cute un refactoring automatique
    .DESCRIPTION
        ExÃ©cute un refactoring automatique basÃ© sur le plan
    .PARAMETER Script
        Script Ã  refactorer
    .PARAMETER Plan
        Plan de refactoring
    .PARAMETER OutputPath
        Chemin oÃ¹ enregistrer les rÃ©sultats
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

    # CrÃ©er un objet pour stocker les rÃ©sultats
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

    # CrÃ©er une copie du script
    $RefactoredScriptPath = Join-Path -Path $OutputPath -ChildPath "$($Script.Name)_refactored$($Script.Extension)"
    Set-Content -Path $RefactoredScriptPath -Value $Content

    # Filtrer les opÃ©rations auto-corrigeables
    $AutoFixableOperations = $Plan.Operations | Where-Object { $_.AutoFixable -eq $true }

    # ExÃ©cuter les opÃ©rations de refactoring
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

        # GÃ©nÃ©rer le code transformÃ©
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

    # Enregistrer les rÃ©sultats dans un fichier
    $ResultsPath = Join-Path -Path $OutputPath -ChildPath "$($Script.Name)_results.json"
    $Result | ConvertTo-Json -Depth 10 | Set-Content -Path $ResultsPath

    return $Result
}

function Generate-TransformedCode {
    <#
    .SYNOPSIS
        GÃ©nÃ¨re le code transformÃ©
    .DESCRIPTION
        GÃ©nÃ¨re le code transformÃ© selon l'opÃ©ration de refactoring
    .PARAMETER Script
        Script Ã  refactorer
    .PARAMETER Operation
        OpÃ©ration de refactoring
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

    # GÃ©nÃ©rer le code transformÃ© selon le type de transformation
    switch ($Operation.Transformation.Type) {
        # Transformations communes
        "RemoveCode" {
            return "# Code supprimÃ©"
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

        # Transformation par dÃ©faut
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
        Remplace le code original par le code transformÃ©
    .PARAMETER Script
        Script Ã  refactorer
    .PARAMETER Operation
        OpÃ©ration de refactoring
    .PARAMETER Content
        Contenu du script
    .PARAMETER TransformedCode
        Code transformÃ©
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

    # Si aucun numÃ©ro de ligne n'est spÃ©cifiÃ©, retourner le contenu inchangÃ©
    if (-not $Operation.LineNumbers -or $Operation.LineNumbers.Count -eq 0) {
        return $Content
    }

    # Diviser le contenu en lignes
    $Lines = $Content -split "`n"

    # DÃ©terminer les lignes Ã  remplacer
    $StartLine = $Operation.LineNumbers[0] - 1
    $EndLine = $Operation.LineNumbers[-1] - 1

    # VÃ©rifier que les lignes sont valides
    if ($StartLine -lt 0 -or $EndLine -ge $Lines.Count) {
        throw "NumÃ©ros de ligne invalides: $StartLine-$EndLine (total: $($Lines.Count))"
    }

    # Remplacer les lignes
    $BeforeLines = $Lines[0..$StartLine]
    $AfterLines = $Lines[($EndLine + 1)..($Lines.Count - 1)]

    # Diviser le code transformÃ© en lignes
    $TransformedLines = $TransformedCode -split "`n"

    # Reconstruire le contenu
    $NewContent = ($BeforeLines + $TransformedLines + $AfterLines) -join "`n"

    return $NewContent
}

# Fonctions de transformation spÃ©cifiques

function Transform-ExtractConstant {
    param ($Script, $Operation, $Content)

    # Extraire le nombre magique
    $Number = $Operation.Transformation.BeforeCode -match "(\d+)" | Out-Null
    $Number = $Matches[1]

    # GÃ©nÃ©rer un nom de constante
    $ConstantName = "CONSTANT_$Number"

    # Remplacer le nombre par la constante
    $TransformedCode = $Operation.Transformation.BeforeCode -replace $Number, $ConstantName

    # Ajouter la dÃ©finition de la constante
    $TransformedCode = "# Constante extraite`n$ConstantName = $Number`n`n" + $TransformedCode

    return $TransformedCode
}

function Transform-ExtractPath {
    param ($Script, $Operation, $Content)

    # Extraire le chemin
    $Path = $Operation.Transformation.BeforeCode -match "((?:[A-Z]:\\|\/(?:home|usr|var|etc|opt)\/)[^\s\""\'\r\n]+)" | Out-Null
    $Path = $Matches[1]

    # GÃ©nÃ©rer un nom de variable
    $PathName = "PATH_" + ($Path -replace "[\\\/\.\:]", "_")

    # Remplacer le chemin par la variable
    $TransformedCode = $Operation.Transformation.BeforeCode -replace [regex]::Escape($Path), $PathName

    # Ajouter la dÃ©finition de la variable
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

    # Ajouter le paramÃ¨tre -ForegroundColor
    $TransformedCode = $Operation.Transformation.BeforeCode -replace "Write-Host\s+([^-]+)(?!-ForegroundColor)", "Write-Host `$1 -ForegroundColor Green"

    return $TransformedCode
}

function Transform-FixSwitchParameter {
    param ($Script, $Operation, $Content)

    # Supprimer la valeur par dÃ©faut des paramÃ¨tres switch
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

    # Ajouter des vÃ©rifications d'erreur
    $Lines = $Operation.Transformation.BeforeCode -split "`n"
    $TransformedLines = @()

    foreach ($Line in $Lines) {
        $TransformedLines += $Line

        # Ajouter une vÃ©rification d'erreur aprÃ¨s les commandes
        if ($Line -match "^\s*(call|copy|move|del|mkdir|rmdir|xcopy|robocopy|start|net|reg|sc)") {
            $TransformedLines += "IF %ERRORLEVEL% NEQ 0 ("
            $TransformedLines += "    ECHO Erreur lors de l'exÃ©cution de la commande"
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
