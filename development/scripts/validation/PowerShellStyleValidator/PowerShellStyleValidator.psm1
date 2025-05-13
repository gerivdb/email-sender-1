#Requires -Version 5.1
<#
.SYNOPSIS
    Module de validation du style de code PowerShell.
.DESCRIPTION
    Ce module fournit des fonctions pour valider que le code PowerShell respecte
    les conventions de style définies dans les guides de style du projet EMAIL_SENDER_1.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date de création: 2025-05-15
#>

# Variables globales du module
$script:StyleRules = @{
    # Règles de nommage
    NamingRules        = @{
        FunctionNaming       = @{
            Pattern = '^[A-Z][a-z]+\-[A-Z][a-zA-Z0-9]+$'
            Message = "Les noms de fonctions doivent suivre le format 'Verbe-Nom' en PascalCase avec un verbe approuvé."
        }
        GlobalVariableNaming = @{
            Pattern = '^\$global:[A-Z][a-zA-Z0-9]+$'
            Message = "Les variables globales doivent utiliser le PascalCase avec le préfixe `$global:."
        }
        ScriptVariableNaming = @{
            Pattern = '^\$script:[A-Z][a-zA-Z0-9]+$'
            Message = "Les variables de script doivent utiliser le PascalCase avec le préfixe `$script:."
        }
        LocalVariableNaming  = @{
            Pattern = '^\$[a-z][a-zA-Z0-9]+$'
            Message = "Les variables locales doivent utiliser le camelCase."
        }
        ConstantNaming       = @{
            Pattern = '^\$script:[A-Z][A-Z0-9_]+$'
            Message = "Les constantes doivent utiliser MAJUSCULES_AVEC_UNDERSCORES avec le préfixe `$script:."
        }
        ParameterNaming      = @{
            Pattern = '^[A-Z][a-zA-Z0-9]+$'
            Message = "Les paramètres doivent utiliser le PascalCase."
        }
    }

    # Règles de formatage
    FormattingRules    = @{
        MaxLineLength   = 120
        IndentationSize = 4
        RequireBraces   = $true
    }

    # Règles de documentation
    DocumentationRules = @{
        RequireSynopsis               = $true
        RequireDescription            = $true
        RequireParameterDocumentation = $true
        RequireExampleDocumentation   = $true
    }

    # Règles de gestion des erreurs
    ErrorHandlingRules = @{
        RequireTryCatch              = $true
        RequireErrorActionPreference = $true
    }
}

# Liste des verbes approuvés par PowerShell
$script:ApprovedVerbs = (Get-Verb).Verb

<#
.SYNOPSIS
    Valide le style d'un fichier PowerShell.
.DESCRIPTION
    Cette fonction analyse un fichier PowerShell et vérifie qu'il respecte les conventions
    de style définies dans les guides de style du projet.
.PARAMETER Path
    Chemin du fichier PowerShell à valider.
.PARAMETER Rules
    Règles de style à appliquer. Par défaut, toutes les règles sont appliquées.
.EXAMPLE
    Test-PowerShellStyle -Path ".\MyScript.ps1"
    Valide le style du fichier MyScript.ps1 avec toutes les règles par défaut.
.EXAMPLE
    Test-PowerShellStyle -Path ".\MyScript.ps1" -Rules @("NamingRules", "FormattingRules")
    Valide le style du fichier MyScript.ps1 avec uniquement les règles de nommage et de formatage.
#>
function Test-PowerShellStyle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string[]]$Rules = @("NamingRules", "FormattingRules", "DocumentationRules", "ErrorHandlingRules")
    )

    begin {
        Write-Verbose "Démarrage de la validation du style PowerShell"
        $results = @()
    }

    process {
        try {
            # Vérifier que le fichier existe
            if (-not (Test-Path -Path $Path -PathType Leaf)) {
                Write-Error "Le fichier '$Path' n'existe pas."
                return
            }

            # Vérifier que le fichier est un fichier PowerShell
            if (-not ($Path -match '\.(ps1|psm1|psd1)$')) {
                Write-Error "Le fichier '$Path' n'est pas un fichier PowerShell (.ps1, .psm1 ou .psd1)."
                return
            }

            # Lire le contenu du fichier
            $content = Get-Content -Path $Path -Raw

            # Analyser le contenu du fichier
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)

            # Valider les règles de style
            foreach ($ruleCategory in $Rules) {
                switch ($ruleCategory) {
                    "NamingRules" {
                        $results += Test-NamingRules -Ast $ast -Path $Path
                    }
                    "FormattingRules" {
                        $results += Test-FormattingRules -Content $content -Path $Path
                    }
                    "DocumentationRules" {
                        $results += Test-DocumentationRules -Ast $ast -Path $Path
                    }
                    "ErrorHandlingRules" {
                        $results += Test-ErrorHandlingRules -Ast $ast -Path $Path
                    }
                    default {
                        Write-Warning "Catégorie de règles inconnue : $ruleCategory"
                    }
                }
            }
        } catch {
            Write-Error "Erreur lors de la validation du style du fichier '$Path' : $_"
        }
    }

    end {
        Write-Verbose "Fin de la validation du style PowerShell"
        return $results
    }
}

<#
.SYNOPSIS
    Valide les règles de nommage dans un AST PowerShell.
.DESCRIPTION
    Cette fonction analyse un AST PowerShell et vérifie que les noms des fonctions,
    variables et paramètres respectent les conventions de nommage définies.
.PARAMETER Ast
    AST PowerShell à analyser.
.PARAMETER Path
    Chemin du fichier PowerShell analysé (pour les messages d'erreur).
#>
function Test-NamingRules {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$Ast,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $results = @()

    # Vérifier les noms de fonctions
    $functionDefinitions = $Ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
    foreach ($function in $functionDefinitions) {
        $functionName = $function.Name

        # Vérifier le format Verbe-Nom
        if ($functionName -notmatch $script:StyleRules.NamingRules.FunctionNaming.Pattern) {
            $results += [PSCustomObject]@{
                Path     = $Path
                Line     = $function.Extent.StartLineNumber
                Rule     = "FunctionNaming"
                Message  = "$($script:StyleRules.NamingRules.FunctionNaming.Message) Nom trouvé : '$functionName'."
                Severity = "Error"
            }
        } else {
            # Vérifier que le verbe est approuvé
            $verb = $functionName -split '-' | Select-Object -First 1
            if ($verb -notin $script:ApprovedVerbs) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $function.Extent.StartLineNumber
                    Rule     = "ApprovedVerb"
                    Message  = "Le verbe '$verb' n'est pas un verbe approuvé par PowerShell. Utilisez Get-Verb pour voir la liste des verbes approuvés."
                    Severity = "Error"
                }
            }
        }

        # Vérifier les noms de paramètres
        $parameters = $function.Body.ParamBlock.Parameters
        if ($parameters) {
            foreach ($parameter in $parameters) {
                $parameterName = $parameter.Name.VariablePath.UserPath
                if ($parameterName -notmatch $script:StyleRules.NamingRules.ParameterNaming.Pattern) {
                    $results += [PSCustomObject]@{
                        Path     = $Path
                        Line     = $parameter.Extent.StartLineNumber
                        Rule     = "ParameterNaming"
                        Message  = "$($script:StyleRules.NamingRules.ParameterNaming.Message) Nom trouvé : '$parameterName'."
                        Severity = "Error"
                    }
                }
            }
        }
    }

    # Vérifier les noms de variables
    $variableExpressions = $Ast.FindAll({ $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] }, $true)
    foreach ($variable in $variableExpressions) {
        $variableName = $variable.VariablePath.UserPath
        $fullVariableName = $variable.Extent.Text

        # Ignorer les variables spéciales et les variables de système
        if ($variableName -match '^(PSItem|_|PSCmdlet|PSBoundParameters|MyInvocation|args|input|PSScriptRoot|PSCommandPath|Error|null|true|false|PWD|HOME|PID|LASTEXITCODE|PSVersionTable|PSEdition|IsLinux|IsMacOS|IsWindows)$') {
            continue
        }

        # Vérifier les variables globales
        if ($fullVariableName -match '^\$global:') {
            if ($fullVariableName -notmatch $script:StyleRules.NamingRules.GlobalVariableNaming.Pattern) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $variable.Extent.StartLineNumber
                    Rule     = "GlobalVariableNaming"
                    Message  = "$($script:StyleRules.NamingRules.GlobalVariableNaming.Message) Nom trouvé : '$fullVariableName'."
                    Severity = "Error"
                }
            }
        }
        # Vérifier les variables de script
        elseif ($fullVariableName -match '^\$script:') {
            # Vérifier si c'est une constante (tout en majuscules avec underscores)
            if ($variableName -cmatch '^[A-Z][A-Z0-9_]+$') {
                if ($fullVariableName -notmatch $script:StyleRules.NamingRules.ConstantNaming.Pattern) {
                    $results += [PSCustomObject]@{
                        Path     = $Path
                        Line     = $variable.Extent.StartLineNumber
                        Rule     = "ConstantNaming"
                        Message  = "$($script:StyleRules.NamingRules.ConstantNaming.Message) Nom trouvé : '$fullVariableName'."
                        Severity = "Error"
                    }
                }
            } else {
                if ($fullVariableName -notmatch $script:StyleRules.NamingRules.ScriptVariableNaming.Pattern) {
                    $results += [PSCustomObject]@{
                        Path     = $Path
                        Line     = $variable.Extent.StartLineNumber
                        Rule     = "ScriptVariableNaming"
                        Message  = "$($script:StyleRules.NamingRules.ScriptVariableNaming.Message) Nom trouvé : '$fullVariableName'."
                        Severity = "Error"
                    }
                }
            }
        }
        # Vérifier les variables locales
        else {
            if ($fullVariableName -notmatch $script:StyleRules.NamingRules.LocalVariableNaming.Pattern) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $variable.Extent.StartLineNumber
                    Rule     = "LocalVariableNaming"
                    Message  = "$($script:StyleRules.NamingRules.LocalVariableNaming.Message) Nom trouvé : '$fullVariableName'."
                    Severity = "Warning"
                }
            }
        }
    }

    return $results
}

<#
.SYNOPSIS
    Valide les règles de formatage dans un fichier PowerShell.
.DESCRIPTION
    Cette fonction analyse le contenu d'un fichier PowerShell et vérifie qu'il respecte
    les conventions de formatage définies (longueur de ligne, indentation, etc.).
.PARAMETER Content
    Contenu du fichier PowerShell à analyser.
.PARAMETER Path
    Chemin du fichier PowerShell analysé (pour les messages d'erreur).
#>
function Test-FormattingRules {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $results = @()
    $lines = $Content -split "`n"

    # Vérifier la longueur des lignes
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $lineNumber = $i + 1
        $line = $lines[$i]

        # Vérifier la longueur maximale de ligne
        if ($line.Length -gt $script:StyleRules.FormattingRules.MaxLineLength) {
            $results += [PSCustomObject]@{
                Path     = $Path
                Line     = $lineNumber
                Rule     = "MaxLineLength"
                Message  = "La ligne dépasse la longueur maximale de $($script:StyleRules.FormattingRules.MaxLineLength) caractères. Longueur actuelle : $($line.Length)."
                Severity = "Warning"
            }
        }

        # Vérifier l'indentation (espaces vs tabulations)
        if ($line -match "`t") {
            $results += [PSCustomObject]@{
                Path     = $Path
                Line     = $lineNumber
                Rule     = "NoTabs"
                Message  = "Utilisez des espaces au lieu des tabulations pour l'indentation."
                Severity = "Warning"
            }
        }

        # Vérifier l'indentation correcte (multiple de 4 espaces)
        if ($line -match '^ +') {
            $indentation = $Matches[0].Length
            if ($indentation % $script:StyleRules.FormattingRules.IndentationSize -ne 0) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $lineNumber
                    Rule     = "IndentationSize"
                    Message  = "L'indentation doit être un multiple de $($script:StyleRules.FormattingRules.IndentationSize) espaces. Indentation actuelle : $indentation."
                    Severity = "Warning"
                }
            }
        }
    }

    # Vérifier l'utilisation des accolades
    if ($script:StyleRules.FormattingRules.RequireBraces) {
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$null, [ref]$null)

        # Vérifier les instructions if sans accolades
        $ifStatements = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.IfStatementAst] }, $true)
        foreach ($if in $ifStatements) {
            if ($if.Clauses) {
                foreach ($clause in $if.Clauses) {
                    if ($clause.Item2 -isnot [System.Management.Automation.Language.StatementBlockAst]) {
                        $results += [PSCustomObject]@{
                            Path     = $Path
                            Line     = $clause.Item2.Extent.StartLineNumber
                            Rule     = "RequireBraces"
                            Message  = "Utilisez des accolades pour toutes les instructions if, même pour les blocs à une seule instruction."
                            Severity = "Warning"
                        }
                    }
                }
            }

            if ($if.ElseClause -and $if.ElseClause -isnot [System.Management.Automation.Language.StatementBlockAst]) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $if.ElseClause.Extent.StartLineNumber
                    Rule     = "RequireBraces"
                    Message  = "Utilisez des accolades pour toutes les instructions else, même pour les blocs à une seule instruction."
                    Severity = "Warning"
                }
            }
        }

        # Vérifier les boucles foreach sans accolades
        $foreachStatements = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.ForEachStatementAst] }, $true)
        foreach ($foreach in $foreachStatements) {
            if ($foreach.Body -isnot [System.Management.Automation.Language.StatementBlockAst]) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $foreach.Body.Extent.StartLineNumber
                    Rule     = "RequireBraces"
                    Message  = "Utilisez des accolades pour toutes les boucles foreach, même pour les blocs à une seule instruction."
                    Severity = "Warning"
                }
            }
        }

        # Vérifier les boucles for sans accolades
        $forStatements = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.ForStatementAst] }, $true)
        foreach ($for in $forStatements) {
            if ($for.Body -isnot [System.Management.Automation.Language.StatementBlockAst]) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $for.Body.Extent.StartLineNumber
                    Rule     = "RequireBraces"
                    Message  = "Utilisez des accolades pour toutes les boucles for, même pour les blocs à une seule instruction."
                    Severity = "Warning"
                }
            }
        }

        # Vérifier les boucles while sans accolades
        $whileStatements = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.WhileStatementAst] }, $true)
        foreach ($while in $whileStatements) {
            if ($while.Body -isnot [System.Management.Automation.Language.StatementBlockAst]) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $while.Body.Extent.StartLineNumber
                    Rule     = "RequireBraces"
                    Message  = "Utilisez des accolades pour toutes les boucles while, même pour les blocs à une seule instruction."
                    Severity = "Warning"
                }
            }
        }
    }

    return $results
}

<#
.SYNOPSIS
    Valide les règles de documentation dans un AST PowerShell.
.DESCRIPTION
    Cette fonction analyse un AST PowerShell et vérifie que les fonctions et scripts
    sont correctement documentés selon les conventions définies.
.PARAMETER Ast
    AST PowerShell à analyser.
.PARAMETER Path
    Chemin du fichier PowerShell analysé (pour les messages d'erreur).
#>
function Test-DocumentationRules {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$Ast,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $results = @()

    # Vérifier la documentation des fonctions
    $functionDefinitions = $Ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
    foreach ($function in $functionDefinitions) {
        $functionName = $function.Name
        $helpContent = $function.GetHelpContent()

        # Vérifier la présence de la documentation
        if ($null -eq $helpContent -or [string]::IsNullOrWhiteSpace($helpContent.Synopsis)) {
            if ($script:StyleRules.DocumentationRules.RequireSynopsis) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $function.Extent.StartLineNumber
                    Rule     = "RequireSynopsis"
                    Message  = "La fonction '$functionName' doit avoir un bloc de documentation avec au moins une section SYNOPSIS."
                    Severity = "Warning"
                }
            }
        } else {
            # Vérifier la présence de la description
            if ($script:StyleRules.DocumentationRules.RequireDescription -and [string]::IsNullOrWhiteSpace($helpContent.Description)) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $function.Extent.StartLineNumber
                    Rule     = "RequireDescription"
                    Message  = "La fonction '$functionName' doit avoir une section DESCRIPTION dans son bloc de documentation."
                    Severity = "Warning"
                }
            }

            # Vérifier la documentation des paramètres
            if ($script:StyleRules.DocumentationRules.RequireParameterDocumentation) {
                $parameters = $function.Body.ParamBlock.Parameters
                if ($parameters) {
                    foreach ($parameter in $parameters) {
                        $parameterName = $parameter.Name.VariablePath.UserPath
                        if (-not $helpContent.Parameters.ContainsKey($parameterName)) {
                            $results += [PSCustomObject]@{
                                Path     = $Path
                                Line     = $parameter.Extent.StartLineNumber
                                Rule     = "RequireParameterDocumentation"
                                Message  = "Le paramètre '$parameterName' de la fonction '$functionName' doit être documenté."
                                Severity = "Warning"
                            }
                        }
                    }
                }
            }

            # Vérifier la présence d'exemples
            if ($script:StyleRules.DocumentationRules.RequireExampleDocumentation -and $helpContent.Examples.Count -eq 0) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $function.Extent.StartLineNumber
                    Rule     = "RequireExampleDocumentation"
                    Message  = "La fonction '$functionName' doit avoir au moins un exemple dans son bloc de documentation."
                    Severity = "Warning"
                }
            }
        }
    }

    return $results
}

<#
.SYNOPSIS
    Valide les règles de gestion des erreurs dans un AST PowerShell.
.DESCRIPTION
    Cette fonction analyse un AST PowerShell et vérifie que les fonctions
    gèrent correctement les erreurs selon les conventions définies.
.PARAMETER Ast
    AST PowerShell à analyser.
.PARAMETER Path
    Chemin du fichier PowerShell analysé (pour les messages d'erreur).
#>
function Test-ErrorHandlingRules {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$Ast,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $results = @()

    # Vérifier la gestion des erreurs dans les fonctions
    $functionDefinitions = $Ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
    foreach ($function in $functionDefinitions) {
        $functionName = $function.Name

        # Vérifier la présence de try/catch
        if ($script:StyleRules.ErrorHandlingRules.RequireTryCatch) {
            $tryCatchStatements = $function.FindAll({ $args[0] -is [System.Management.Automation.Language.TryStatementAst] }, $true)
            if ($tryCatchStatements.Count -eq 0) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $function.Extent.StartLineNumber
                    Rule     = "RequireTryCatch"
                    Message  = "La fonction '$functionName' devrait utiliser try/catch pour gérer les erreurs."
                    Severity = "Warning"
                }
            }
        }

        # Vérifier la présence de $ErrorActionPreference
        if ($script:StyleRules.ErrorHandlingRules.RequireErrorActionPreference) {
            $errorActionPreferenceAssignments = $function.FindAll({
                    $args[0] -is [System.Management.Automation.Language.AssignmentStatementAst] -and
                    $args[0].Left.Extent.Text -eq '$ErrorActionPreference'
                }, $true)

            if ($errorActionPreferenceAssignments.Count -eq 0) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $function.Extent.StartLineNumber
                    Rule     = "RequireErrorActionPreference"
                    Message  = "La fonction '$functionName' devrait définir `$ErrorActionPreference au début du bloc de fonction."
                    Severity = "Warning"
                }
            }
        }
    }

    return $results
}

<#
.SYNOPSIS
    Génère un rapport de validation du style PowerShell.
.DESCRIPTION
    Cette fonction génère un rapport détaillé des résultats de validation du style PowerShell.
.PARAMETER Results
    Résultats de la validation du style PowerShell.
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le rapport. Si non spécifié, le rapport est affiché dans la console.
.PARAMETER Format
    Format du rapport (Text, CSV, HTML). Par défaut, Text.
.EXAMPLE
    $results = Test-PowerShellStyle -Path ".\MyScript.ps1"
    New-PowerShellStyleReport -Results $results -Format HTML -OutputPath ".\StyleReport.html"
    Génère un rapport HTML des résultats de validation du style PowerShell.
#>
function New-PowerShellStyleReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [PSObject[]]$Results,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "CSV", "HTML")]
        [string]$Format = "Text"
    )

    begin {
        $allResults = @()
    }

    process {
        $allResults += $Results
    }

    end {
        # Trier les résultats par chemin, ligne et règle
        $sortedResults = $allResults | Sort-Object -Property Path, Line, Rule

        # Générer le rapport selon le format spécifié
        switch ($Format) {
            "Text" {
                $report = "Rapport de validation du style PowerShell`n"
                $report += "=====================================`n`n"

                $report += "Résumé :`n"
                $report += "- Nombre total de problèmes : $($sortedResults.Count)`n"
                $report += "- Erreurs : $($sortedResults | Where-Object { $_.Severity -eq 'Error' } | Measure-Object | Select-Object -ExpandProperty Count)`n"
                $report += "- Avertissements : $($sortedResults | Where-Object { $_.Severity -eq 'Warning' } | Measure-Object | Select-Object -ExpandProperty Count)`n`n"

                $report += "Détails :`n"
                foreach ($result in $sortedResults) {
                    $report += "[$($result.Severity)] $($result.Path):$($result.Line) - $($result.Rule): $($result.Message)`n"
                }
            }
            "CSV" {
                $report = $sortedResults | ConvertTo-Csv -NoTypeInformation
            }
            "HTML" {
                $htmlHeader = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de validation du style PowerShell</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #0066cc; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .error { color: #cc0000; }
        .warning { color: #ff9900; }
        .summary { margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1>Rapport de validation du style PowerShell</h1>
    <div class="summary">
        <h2>Résumé</h2>
        <p>Nombre total de problèmes : $($sortedResults.Count)</p>
        <p>Erreurs : $($sortedResults | Where-Object { $_.Severity -eq 'Error' } | Measure-Object | Select-Object -ExpandProperty Count)</p>
        <p>Avertissements : $($sortedResults | Where-Object { $_.Severity -eq 'Warning' } | Measure-Object | Select-Object -ExpandProperty Count)</p>
    </div>
    <h2>Détails</h2>
    <table>
        <tr>
            <th>Sévérité</th>
            <th>Fichier</th>
            <th>Ligne</th>
            <th>Règle</th>
            <th>Message</th>
        </tr>
"@

                $htmlRows = foreach ($result in $sortedResults) {
                    $severityClass = if ($result.Severity -eq 'Error') { 'error' } else { 'warning' }
                    "<tr><td class='$severityClass'>$($result.Severity)</td><td>$($result.Path)</td><td>$($result.Line)</td><td>$($result.Rule)</td><td>$($result.Message)</td></tr>"
                }

                $htmlFooter = @"
    </table>
</body>
</html>
"@

                $report = $htmlHeader + [string]::Join("`n", $htmlRows) + $htmlFooter
            }
        }

        # Afficher ou enregistrer le rapport
        if ($OutputPath) {
            $report | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Verbose "Rapport enregistré dans '$OutputPath'"
        } else {
            return $report
        }
    }
}

<#
.SYNOPSIS
    Valide les règles de formatage dans un fichier PowerShell.
.DESCRIPTION
    Cette fonction analyse le contenu d'un fichier PowerShell et vérifie qu'il respecte
    les conventions de formatage définies (longueur de ligne, indentation, etc.).
.PARAMETER Content
    Contenu du fichier PowerShell à analyser.
.PARAMETER Path
    Chemin du fichier PowerShell analysé (pour les messages d'erreur).
#>
function Test-FormattingRules {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $results = @()
    $lines = $Content -split "`n"

    # Vérifier la longueur des lignes
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $lineNumber = $i + 1
        $line = $lines[$i]

        # Vérifier la longueur maximale de ligne
        if ($line.Length -gt $script:StyleRules.FormattingRules.MaxLineLength) {
            $results += [PSCustomObject]@{
                Path     = $Path
                Line     = $lineNumber
                Rule     = "MaxLineLength"
                Message  = "La ligne dépasse la longueur maximale de $($script:StyleRules.FormattingRules.MaxLineLength) caractères. Longueur actuelle : $($line.Length)."
                Severity = "Warning"
            }
        }

        # Vérifier l'indentation (espaces vs tabulations)
        if ($line -match "`t") {
            $results += [PSCustomObject]@{
                Path     = $Path
                Line     = $lineNumber
                Rule     = "NoTabs"
                Message  = "Utilisez des espaces au lieu des tabulations pour l'indentation."
                Severity = "Warning"
            }
        }

        # Vérifier l'indentation correcte (multiple de 4 espaces)
        if ($line -match '^ +') {
            $indentation = $Matches[0].Length
            if ($indentation % $script:StyleRules.FormattingRules.IndentationSize -ne 0) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $lineNumber
                    Rule     = "IndentationSize"
                    Message  = "L'indentation doit être un multiple de $($script:StyleRules.FormattingRules.IndentationSize) espaces. Indentation actuelle : $indentation."
                    Severity = "Warning"
                }
            }
        }
    }

    # Vérifier l'utilisation des accolades
    if ($script:StyleRules.FormattingRules.RequireBraces) {
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$null, [ref]$null)

        # Vérifier les instructions if sans accolades
        $ifStatements = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.IfStatementAst] }, $true)
        foreach ($if in $ifStatements) {
            if ($if.Clauses) {
                foreach ($clause in $if.Clauses) {
                    if ($clause.Item2 -isnot [System.Management.Automation.Language.StatementBlockAst]) {
                        $results += [PSCustomObject]@{
                            Path     = $Path
                            Line     = $clause.Item2.Extent.StartLineNumber
                            Rule     = "RequireBraces"
                            Message  = "Utilisez des accolades pour toutes les instructions if, même pour les blocs à une seule instruction."
                            Severity = "Warning"
                        }
                    }
                }
            }

            if ($if.ElseClause -and $if.ElseClause -isnot [System.Management.Automation.Language.StatementBlockAst]) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $if.ElseClause.Extent.StartLineNumber
                    Rule     = "RequireBraces"
                    Message  = "Utilisez des accolades pour toutes les instructions else, même pour les blocs à une seule instruction."
                    Severity = "Warning"
                }
            }
        }

        # Vérifier les boucles foreach sans accolades
        $foreachStatements = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.ForEachStatementAst] }, $true)
        foreach ($foreach in $foreachStatements) {
            if ($foreach.Body -isnot [System.Management.Automation.Language.StatementBlockAst]) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $foreach.Body.Extent.StartLineNumber
                    Rule     = "RequireBraces"
                    Message  = "Utilisez des accolades pour toutes les boucles foreach, même pour les blocs à une seule instruction."
                    Severity = "Warning"
                }
            }
        }

        # Vérifier les boucles for sans accolades
        $forStatements = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.ForStatementAst] }, $true)
        foreach ($for in $forStatements) {
            if ($for.Body -isnot [System.Management.Automation.Language.StatementBlockAst]) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $for.Body.Extent.StartLineNumber
                    Rule     = "RequireBraces"
                    Message  = "Utilisez des accolades pour toutes les boucles for, même pour les blocs à une seule instruction."
                    Severity = "Warning"
                }
            }
        }

        # Vérifier les boucles while sans accolades
        $whileStatements = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.WhileStatementAst] }, $true)
        foreach ($while in $whileStatements) {
            if ($while.Body -isnot [System.Management.Automation.Language.StatementBlockAst]) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $while.Body.Extent.StartLineNumber
                    Rule     = "RequireBraces"
                    Message  = "Utilisez des accolades pour toutes les boucles while, même pour les blocs à une seule instruction."
                    Severity = "Warning"
                }
            }
        }
    }

    return $results
}

<#
.SYNOPSIS
    Valide les règles de documentation dans un AST PowerShell.
.DESCRIPTION
    Cette fonction analyse un AST PowerShell et vérifie que les fonctions et scripts
    sont correctement documentés selon les conventions définies.
.PARAMETER Ast
    AST PowerShell à analyser.
.PARAMETER Path
    Chemin du fichier PowerShell analysé (pour les messages d'erreur).
#>
function Test-DocumentationRules {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$Ast,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $results = @()

    # Vérifier la documentation des fonctions
    $functionDefinitions = $Ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
    foreach ($function in $functionDefinitions) {
        $functionName = $function.Name
        $helpContent = $function.GetHelpContent()

        # Vérifier la présence de la documentation
        if ($null -eq $helpContent -or [string]::IsNullOrWhiteSpace($helpContent.Synopsis)) {
            if ($script:StyleRules.DocumentationRules.RequireSynopsis) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $function.Extent.StartLineNumber
                    Rule     = "RequireSynopsis"
                    Message  = "La fonction '$functionName' doit avoir un bloc de documentation avec au moins une section SYNOPSIS."
                    Severity = "Warning"
                }
            }
        } else {
            # Vérifier la présence de la description
            if ($script:StyleRules.DocumentationRules.RequireDescription -and [string]::IsNullOrWhiteSpace($helpContent.Description)) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $function.Extent.StartLineNumber
                    Rule     = "RequireDescription"
                    Message  = "La fonction '$functionName' doit avoir une section DESCRIPTION dans son bloc de documentation."
                    Severity = "Warning"
                }
            }

            # Vérifier la documentation des paramètres
            if ($script:StyleRules.DocumentationRules.RequireParameterDocumentation) {
                $parameters = $function.Body.ParamBlock.Parameters
                if ($parameters) {
                    foreach ($parameter in $parameters) {
                        $parameterName = $parameter.Name.VariablePath.UserPath
                        if (-not $helpContent.Parameters.ContainsKey($parameterName)) {
                            $results += [PSCustomObject]@{
                                Path     = $Path
                                Line     = $parameter.Extent.StartLineNumber
                                Rule     = "RequireParameterDocumentation"
                                Message  = "Le paramètre '$parameterName' de la fonction '$functionName' doit être documenté."
                                Severity = "Warning"
                            }
                        }
                    }
                }
            }

            # Vérifier la présence d'exemples
            if ($script:StyleRules.DocumentationRules.RequireExampleDocumentation -and $helpContent.Examples.Count -eq 0) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $function.Extent.StartLineNumber
                    Rule     = "RequireExampleDocumentation"
                    Message  = "La fonction '$functionName' doit avoir au moins un exemple dans son bloc de documentation."
                    Severity = "Warning"
                }
            }
        }
    }

    return $results
}

<#
.SYNOPSIS
    Valide les règles de gestion des erreurs dans un AST PowerShell.
.DESCRIPTION
    Cette fonction analyse un AST PowerShell et vérifie que les fonctions
    gèrent correctement les erreurs selon les conventions définies.
.PARAMETER Ast
    AST PowerShell à analyser.
.PARAMETER Path
    Chemin du fichier PowerShell analysé (pour les messages d'erreur).
#>
function Test-ErrorHandlingRules {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$Ast,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $results = @()

    # Vérifier la gestion des erreurs dans les fonctions
    $functionDefinitions = $Ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
    foreach ($function in $functionDefinitions) {
        $functionName = $function.Name

        # Vérifier la présence de try/catch
        if ($script:StyleRules.ErrorHandlingRules.RequireTryCatch) {
            $tryCatchStatements = $function.FindAll({ $args[0] -is [System.Management.Automation.Language.TryStatementAst] }, $true)
            if ($tryCatchStatements.Count -eq 0) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $function.Extent.StartLineNumber
                    Rule     = "RequireTryCatch"
                    Message  = "La fonction '$functionName' devrait utiliser try/catch pour gérer les erreurs."
                    Severity = "Warning"
                }
            }
        }

        # Vérifier la présence de $ErrorActionPreference
        if ($script:StyleRules.ErrorHandlingRules.RequireErrorActionPreference) {
            $errorActionPreferenceAssignments = $function.FindAll({
                    $args[0] -is [System.Management.Automation.Language.AssignmentStatementAst] -and
                    $args[0].Left.Extent.Text -eq '$ErrorActionPreference'
                }, $true)

            if ($errorActionPreferenceAssignments.Count -eq 0) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $function.Extent.StartLineNumber
                    Rule     = "RequireErrorActionPreference"
                    Message  = "La fonction '$functionName' devrait définir `$ErrorActionPreference au début du bloc de fonction."
                    Severity = "Warning"
                }
            }
        }
    }

    return $results
}

<#
.SYNOPSIS
    Génère un rapport de validation du style PowerShell.
.DESCRIPTION
    Cette fonction génère un rapport détaillé des résultats de validation du style PowerShell.
.PARAMETER Results
    Résultats de la validation du style PowerShell.
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le rapport. Si non spécifié, le rapport est affiché dans la console.
.PARAMETER Format
    Format du rapport (Text, CSV, HTML). Par défaut, Text.
.EXAMPLE
    $results = Test-PowerShellStyle -Path ".\MyScript.ps1"
    New-PowerShellStyleReport -Results $results -Format HTML -OutputPath ".\StyleReport.html"
    Génère un rapport HTML des résultats de validation du style PowerShell.
#>
function New-PowerShellStyleReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [PSObject[]]$Results,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "CSV", "HTML")]
        [string]$Format = "Text"
    )

    begin {
        $allResults = @()
    }

    process {
        $allResults += $Results
    }

    end {
        # Trier les résultats par chemin, ligne et règle
        $sortedResults = $allResults | Sort-Object -Property Path, Line, Rule

        # Générer le rapport selon le format spécifié
        switch ($Format) {
            "Text" {
                $report = "Rapport de validation du style PowerShell`n"
                $report += "=====================================`n`n"

                $report += "Résumé :`n"
                $report += "- Nombre total de problèmes : $($sortedResults.Count)`n"
                $report += "- Erreurs : $($sortedResults | Where-Object { $_.Severity -eq 'Error' } | Measure-Object | Select-Object -ExpandProperty Count)`n"
                $report += "- Avertissements : $($sortedResults | Where-Object { $_.Severity -eq 'Warning' } | Measure-Object | Select-Object -ExpandProperty Count)`n`n"

                $report += "Détails :`n"
                foreach ($result in $sortedResults) {
                    $report += "[$($result.Severity)] $($result.Path):$($result.Line) - $($result.Rule): $($result.Message)`n"
                }
            }
            "CSV" {
                $report = $sortedResults | ConvertTo-Csv -NoTypeInformation
            }
            "HTML" {
                $htmlHeader = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de validation du style PowerShell</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #0066cc; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .error { color: #cc0000; }
        .warning { color: #ff9900; }
        .summary { margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1>Rapport de validation du style PowerShell</h1>
    <div class="summary">
        <h2>Résumé</h2>
        <p>Nombre total de problèmes : $($sortedResults.Count)</p>
        <p>Erreurs : $($sortedResults | Where-Object { $_.Severity -eq 'Error' } | Measure-Object | Select-Object -ExpandProperty Count)</p>
        <p>Avertissements : $($sortedResults | Where-Object { $_.Severity -eq 'Warning' } | Measure-Object | Select-Object -ExpandProperty Count)</p>
    </div>
    <h2>Détails</h2>
    <table>
        <tr>
            <th>Sévérité</th>
            <th>Fichier</th>
            <th>Ligne</th>
            <th>Règle</th>
            <th>Message</th>
        </tr>
"@

                $htmlRows = foreach ($result in $sortedResults) {
                    $severityClass = if ($result.Severity -eq 'Error') { 'error' } else { 'warning' }
                    "<tr><td class='$severityClass'>$($result.Severity)</td><td>$($result.Path)</td><td>$($result.Line)</td><td>$($result.Rule)</td><td>$($result.Message)</td></tr>"
                }

                $htmlFooter = @"
    </table>
</body>
</html>
"@

                $report = $htmlHeader + [string]::Join("`n", $htmlRows) + $htmlFooter
            }
        }

        # Afficher ou enregistrer le rapport
        if ($OutputPath) {
            $report | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Verbose "Rapport enregistré dans '$OutputPath'"
        } else {
            return $report
        }
    }
}

<#
.SYNOPSIS
    Valide les règles de formatage dans un fichier PowerShell.
.DESCRIPTION
    Cette fonction analyse le contenu d'un fichier PowerShell et vérifie qu'il respecte
    les conventions de formatage définies (longueur de ligne, indentation, etc.).
.PARAMETER Content
    Contenu du fichier PowerShell à analyser.
.PARAMETER Path
    Chemin du fichier PowerShell analysé (pour les messages d'erreur).
#>
function Test-FormattingRules {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $results = @()
    $lines = $Content -split "`n"

    # Vérifier la longueur des lignes
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $lineNumber = $i + 1
        $line = $lines[$i]

        # Vérifier la longueur maximale de ligne
        if ($line.Length -gt $script:StyleRules.FormattingRules.MaxLineLength) {
            $results += [PSCustomObject]@{
                Path     = $Path
                Line     = $lineNumber
                Rule     = "MaxLineLength"
                Message  = "La ligne dépasse la longueur maximale de $($script:StyleRules.FormattingRules.MaxLineLength) caractères. Longueur actuelle : $($line.Length)."
                Severity = "Warning"
            }
        }

        # Vérifier l'indentation (espaces vs tabulations)
        if ($line -match "`t") {
            $results += [PSCustomObject]@{
                Path     = $Path
                Line     = $lineNumber
                Rule     = "NoTabs"
                Message  = "Utilisez des espaces au lieu des tabulations pour l'indentation."
                Severity = "Warning"
            }
        }

        # Vérifier l'indentation correcte (multiple de 4 espaces)
        if ($line -match '^ +') {
            $indentation = $Matches[0].Length
            if ($indentation % $script:StyleRules.FormattingRules.IndentationSize -ne 0) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $lineNumber
                    Rule     = "IndentationSize"
                    Message  = "L'indentation doit être un multiple de $($script:StyleRules.FormattingRules.IndentationSize) espaces. Indentation actuelle : $indentation."
                    Severity = "Warning"
                }
            }
        }
    }

    # Vérifier l'utilisation des accolades
    if ($script:StyleRules.FormattingRules.RequireBraces) {
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$null, [ref]$null)

        # Vérifier les instructions if sans accolades
        $ifStatements = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.IfStatementAst] }, $true)
        foreach ($if in $ifStatements) {
            if ($if.Clauses) {
                foreach ($clause in $if.Clauses) {
                    if ($clause.Item2 -isnot [System.Management.Automation.Language.StatementBlockAst]) {
                        $results += [PSCustomObject]@{
                            Path     = $Path
                            Line     = $clause.Item2.Extent.StartLineNumber
                            Rule     = "RequireBraces"
                            Message  = "Utilisez des accolades pour toutes les instructions if, même pour les blocs à une seule instruction."
                            Severity = "Warning"
                        }
                    }
                }
            }

            if ($if.ElseClause -and $if.ElseClause -isnot [System.Management.Automation.Language.StatementBlockAst]) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $if.ElseClause.Extent.StartLineNumber
                    Rule     = "RequireBraces"
                    Message  = "Utilisez des accolades pour toutes les instructions else, même pour les blocs à une seule instruction."
                    Severity = "Warning"
                }
            }
        }
    }

    return $results
}

<#
.SYNOPSIS
    Valide les règles de documentation dans un AST PowerShell.
.DESCRIPTION
    Cette fonction analyse un AST PowerShell et vérifie que les fonctions et scripts
    sont correctement documentés selon les conventions définies.
.PARAMETER Ast
    AST PowerShell à analyser.
.PARAMETER Path
    Chemin du fichier PowerShell analysé (pour les messages d'erreur).
#>
function Test-DocumentationRules {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$Ast,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $results = @()

    # Vérifier la documentation des fonctions
    $functionDefinitions = $Ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
    foreach ($function in $functionDefinitions) {
        $functionName = $function.Name
        $helpContent = $function.GetHelpContent()

        # Vérifier la présence de la documentation
        if ($null -eq $helpContent -or [string]::IsNullOrWhiteSpace($helpContent.Synopsis)) {
            if ($script:StyleRules.DocumentationRules.RequireSynopsis) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $function.Extent.StartLineNumber
                    Rule     = "RequireSynopsis"
                    Message  = "La fonction '$functionName' doit avoir un bloc de documentation avec au moins une section SYNOPSIS."
                    Severity = "Warning"
                }
            }
        } else {
            # Vérifier la présence de la description
            if ($script:StyleRules.DocumentationRules.RequireDescription -and [string]::IsNullOrWhiteSpace($helpContent.Description)) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $function.Extent.StartLineNumber
                    Rule     = "RequireDescription"
                    Message  = "La fonction '$functionName' doit avoir une section DESCRIPTION dans son bloc de documentation."
                    Severity = "Warning"
                }
            }

            # Vérifier la documentation des paramètres
            if ($script:StyleRules.DocumentationRules.RequireParameterDocumentation) {
                $parameters = $function.Body.ParamBlock.Parameters
                if ($parameters) {
                    foreach ($parameter in $parameters) {
                        $parameterName = $parameter.Name.VariablePath.UserPath
                        if (-not $helpContent.Parameters.ContainsKey($parameterName)) {
                            $results += [PSCustomObject]@{
                                Path     = $Path
                                Line     = $parameter.Extent.StartLineNumber
                                Rule     = "RequireParameterDocumentation"
                                Message  = "Le paramètre '$parameterName' de la fonction '$functionName' doit être documenté."
                                Severity = "Warning"
                            }
                        }
                    }
                }
            }

            # Vérifier la présence d'exemples
            if ($script:StyleRules.DocumentationRules.RequireExampleDocumentation -and $helpContent.Examples.Count -eq 0) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $function.Extent.StartLineNumber
                    Rule     = "RequireExampleDocumentation"
                    Message  = "La fonction '$functionName' doit avoir au moins un exemple dans son bloc de documentation."
                    Severity = "Warning"
                }
            }
        }
    }

    return $results
}

<#
.SYNOPSIS
    Valide les règles de gestion des erreurs dans un AST PowerShell.
.DESCRIPTION
    Cette fonction analyse un AST PowerShell et vérifie que les fonctions
    gèrent correctement les erreurs selon les conventions définies.
.PARAMETER Ast
    AST PowerShell à analyser.
.PARAMETER Path
    Chemin du fichier PowerShell analysé (pour les messages d'erreur).
#>
function Test-ErrorHandlingRules {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$Ast,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $results = @()

    # Vérifier la gestion des erreurs dans les fonctions
    $functionDefinitions = $Ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
    foreach ($function in $functionDefinitions) {
        $functionName = $function.Name

        # Vérifier la présence de try/catch
        if ($script:StyleRules.ErrorHandlingRules.RequireTryCatch) {
            $tryCatchStatements = $function.FindAll({ $args[0] -is [System.Management.Automation.Language.TryStatementAst] }, $true)
            if ($tryCatchStatements.Count -eq 0) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $function.Extent.StartLineNumber
                    Rule     = "RequireTryCatch"
                    Message  = "La fonction '$functionName' devrait utiliser try/catch pour gérer les erreurs."
                    Severity = "Warning"
                }
            }
        }

        # Vérifier la présence de $ErrorActionPreference
        if ($script:StyleRules.ErrorHandlingRules.RequireErrorActionPreference) {
            $errorActionPreferenceAssignments = $function.FindAll({
                    $args[0] -is [System.Management.Automation.Language.AssignmentStatementAst] -and
                    $args[0].Left.Extent.Text -eq '$ErrorActionPreference'
                }, $true)

            if ($errorActionPreferenceAssignments.Count -eq 0) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $function.Extent.StartLineNumber
                    Rule     = "RequireErrorActionPreference"
                    Message  = "La fonction '$functionName' devrait définir `$ErrorActionPreference au début du bloc de fonction."
                    Severity = "Warning"
                }
            }
        }
    }

    return $results
}

<#
.SYNOPSIS
    Génère un rapport de validation du style PowerShell.
.DESCRIPTION
    Cette fonction génère un rapport détaillé des résultats de validation du style PowerShell.
.PARAMETER Results
    Résultats de la validation du style PowerShell.
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le rapport. Si non spécifié, le rapport est affiché dans la console.
.PARAMETER Format
    Format du rapport (Text, CSV, HTML). Par défaut, Text.
.EXAMPLE
    $results = Test-PowerShellStyle -Path ".\MyScript.ps1"
    New-PowerShellStyleReport -Results $results -Format HTML -OutputPath ".\StyleReport.html"
    Génère un rapport HTML des résultats de validation du style PowerShell.
#>
function New-PowerShellStyleReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [PSObject[]]$Results,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "CSV", "HTML")]
        [string]$Format = "Text"
    )

    begin {
        $allResults = @()
    }

    process {
        $allResults += $Results
    }

    end {
        # Trier les résultats par chemin, ligne et règle
        $sortedResults = $allResults | Sort-Object -Property Path, Line, Rule

        # Générer le rapport selon le format spécifié
        switch ($Format) {
            "Text" {
                $report = "Rapport de validation du style PowerShell`n"
                $report += "=====================================`n`n"

                $report += "Résumé :`n"
                $report += "- Nombre total de problèmes : $($sortedResults.Count)`n"
                $report += "- Erreurs : $($sortedResults | Where-Object { $_.Severity -eq 'Error' } | Measure-Object | Select-Object -ExpandProperty Count)`n"
                $report += "- Avertissements : $($sortedResults | Where-Object { $_.Severity -eq 'Warning' } | Measure-Object | Select-Object -ExpandProperty Count)`n`n"

                $report += "Détails :`n"
                foreach ($result in $sortedResults) {
                    $report += "[$($result.Severity)] $($result.Path):$($result.Line) - $($result.Rule): $($result.Message)`n"
                }
            }
            "CSV" {
                $report = $sortedResults | ConvertTo-Csv -NoTypeInformation
            }
            "HTML" {
                $htmlHeader = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de validation du style PowerShell</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #0066cc; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .error { color: #cc0000; }
        .warning { color: #ff9900; }
        .summary { margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1>Rapport de validation du style PowerShell</h1>
    <div class="summary">
        <h2>Résumé</h2>
        <p>Nombre total de problèmes : $($sortedResults.Count)</p>
        <p>Erreurs : $($sortedResults | Where-Object { $_.Severity -eq 'Error' } | Measure-Object | Select-Object -ExpandProperty Count)</p>
        <p>Avertissements : $($sortedResults | Where-Object { $_.Severity -eq 'Warning' } | Measure-Object | Select-Object -ExpandProperty Count)</p>
    </div>
    <h2>Détails</h2>
    <table>
        <tr>
            <th>Sévérité</th>
            <th>Fichier</th>
            <th>Ligne</th>
            <th>Règle</th>
            <th>Message</th>
        </tr>
"@

                $htmlRows = foreach ($result in $sortedResults) {
                    $severityClass = if ($result.Severity -eq 'Error') { 'error' } else { 'warning' }
                    "<tr><td class='$severityClass'>$($result.Severity)</td><td>$($result.Path)</td><td>$($result.Line)</td><td>$($result.Rule)</td><td>$($result.Message)</td></tr>"
                }

                $htmlFooter = @"
    </table>
</body>
</html>
"@

                $report = $htmlHeader + [string]::Join("`n", $htmlRows) + $htmlFooter
            }
        }

        # Afficher ou enregistrer le rapport
        if ($OutputPath) {
            $report | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Verbose "Rapport enregistré dans '$OutputPath'"
        } else {
            return $report
        }
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Test-PowerShellStyle, New-PowerShellStyleReport
