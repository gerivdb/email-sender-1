#Requires -Version 5.1

<#
.SYNOPSIS
    Module pour l'analyse des appels de fonction dans les scripts PowerShell.

.DESCRIPTION
    Ce module fournit des fonctions pour analyser les appels de fonction dans les scripts PowerShell,
    détecter les fonctions définies vs. appelées, et générer un graphe de dépendances de fonctions.

.NOTES
    Auteur: Dependency Management Team
    Version: 1.0
    Date de création: 2023-07-20
#>

# Aucun module externe requis pour ce module

function Get-FunctionCallAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Path')]
        [string]$ScriptPath,

        [Parameter(Mandatory = $true, ParameterSetName = 'Content')]
        [string]$ScriptContent,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMethodCalls,

        [Parameter(Mandatory = $false)]
        [switch]$ExcludeCommonCmdlets
    )

    # Définir les cmdlets communs à exclure si demandé
    $commonCmdlets = @(
        'Write-Host', 'Write-Output', 'Write-Verbose', 'Write-Debug', 'Write-Error', 'Write-Warning',
        'Get-Item', 'Set-Item', 'Remove-Item', 'Test-Path', 'Get-ChildItem', 'Set-Location',
        'Get-Content', 'Set-Content', 'Out-File', 'Select-Object', 'Where-Object', 'ForEach-Object',
        'Sort-Object', 'Group-Object', 'Measure-Object', 'ConvertTo-Json', 'ConvertFrom-Json'
    )

    # Analyser le script pour obtenir l'AST
    $tokens = $errors = $null
    if ($PSCmdlet.ParameterSetName -eq 'Path') {
        if (-not (Test-Path -Path $ScriptPath -PathType Leaf)) {
            throw "Le fichier spécifié n'existe pas: $ScriptPath"
        }
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$tokens, [ref]$errors)
        $scriptName = Split-Path -Path $ScriptPath -Leaf
    } else {
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($ScriptContent, [ref]$tokens, [ref]$errors)
        $scriptName = "ScriptContent"
    }

    # Vérifier les erreurs de parsing
    if ($errors -and $errors.Count -gt 0) {
        Write-Warning "Des erreurs de parsing ont été détectées dans le script:"
        foreach ($error in $errors) {
            Write-Warning "Ligne $($error.Extent.StartLineNumber), Colonne $($error.Extent.StartColumnNumber): $($error.Message)"
        }
    }

    # Trouver tous les appels de commandes (fonctions, cmdlets, etc.)
    $commandCalls = $ast.FindAll({
            param($node)
            $node.GetType().Name -eq 'CommandAst'
        }, $true)

    # Trouver tous les appels de méthodes si demandé
    $methodCalls = @()
    if ($IncludeMethodCalls) {
        $methodCalls = $ast.FindAll({
                param($node)
                $node.GetType().Name -eq 'InvocationExpressionAst' -and
                $node.Expression.GetType().Name -eq 'MemberExpressionAst'
            }, $true)
    }

    # Collecter les résultats
    $results = @()

    # Traiter les appels de commandes
    foreach ($call in $commandCalls) {
        $commandName = $call.CommandElements[0].Value

        # Exclure les cmdlets communs si demandé
        if ($ExcludeCommonCmdlets -and $commonCmdlets -contains $commandName) {
            continue
        }

        $results += [PSCustomObject]@{
            ScriptName = $scriptName
            Type       = "Command"
            Name       = $commandName
            Line       = $call.Extent.StartLineNumber
            Column     = $call.Extent.StartColumnNumber
            Parameters = ($call.CommandElements | Select-Object -Skip 1 | ForEach-Object { $_.Extent.Text }) -join ", "
        }
    }

    # Traiter les appels de méthodes
    foreach ($call in $methodCalls) {
        $memberExpr = $call.Expression
        $methodName = $memberExpr.Member.Value
        $targetObject = $memberExpr.Expression.Extent.Text

        $results += [PSCustomObject]@{
            ScriptName = $scriptName
            Type       = "Method"
            Name       = "$targetObject.$methodName"
            Line       = $call.Extent.StartLineNumber
            Column     = $call.Extent.StartColumnNumber
            Parameters = ($call.ArgumentList | ForEach-Object { $_.Extent.Text }) -join ", "
        }
    }

    return $results
}

function Get-FunctionDefinitionAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Path')]
        [string]$ScriptPath,

        [Parameter(Mandatory = $true, ParameterSetName = 'Content')]
        [string]$ScriptContent,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeParameters
    )

    # Analyser le script pour obtenir l'AST
    $tokens = $errors = $null
    if ($PSCmdlet.ParameterSetName -eq 'Path') {
        if (-not (Test-Path -Path $ScriptPath -PathType Leaf)) {
            throw "Le fichier spécifié n'existe pas: $ScriptPath"
        }
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$tokens, [ref]$errors)
        $scriptName = Split-Path -Path $ScriptPath -Leaf
    } else {
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($ScriptContent, [ref]$tokens, [ref]$errors)
        $scriptName = "ScriptContent"
    }

    # Vérifier les erreurs de parsing
    if ($errors -and $errors.Count -gt 0) {
        Write-Warning "Des erreurs de parsing ont été détectées dans le script:"
        foreach ($error in $errors) {
            Write-Warning "Ligne $($error.Extent.StartLineNumber), Colonne $($error.Extent.StartColumnNumber): $($error.Message)"
        }
    }

    # Trouver toutes les définitions de fonctions
    $functionDefinitions = $ast.FindAll({
            param($node)
            $node.GetType().Name -eq 'FunctionDefinitionAst'
        }, $true)

    # Collecter les résultats
    $results = @()

    foreach ($function in $functionDefinitions) {
        $functionInfo = [PSCustomObject]@{
            ScriptName = $scriptName
            Name       = $function.Name
            Line       = $function.Extent.StartLineNumber
            Column     = $function.Extent.StartColumnNumber
            EndLine    = $function.Extent.EndLineNumber
            IsExported = $false # Par défaut, on considère que la fonction n'est pas exportée
            Visibility = "Unknown" # Par défaut, visibilité inconnue
        }

        # Déterminer la visibilité de la fonction (Public/Private) en fonction du chemin
        if ($PSCmdlet.ParameterSetName -eq 'Path') {
            $directory = Split-Path -Path $ScriptPath -Parent
            $directoryName = Split-Path -Path $directory -Leaf
            if ($directoryName -eq "Public") {
                $functionInfo.Visibility = "Public"
                $functionInfo.IsExported = $true
            } elseif ($directoryName -eq "Private") {
                $functionInfo.Visibility = "Private"
            }
        }

        # Ajouter les paramètres si demandé
        if ($IncludeParameters) {
            $parameters = @()
            if ($function.Parameters) {
                foreach ($param in $function.Parameters) {
                    $paramName = $param.Name.ToString().TrimStart('$')
                    $paramType = if ($param.StaticType) { $param.StaticType.ToString() } else { "Object" }
                    $isMandatory = $false

                    # Rechercher l'attribut Parameter et la propriété Mandatory
                    foreach ($attr in $param.Attributes) {
                        if ($attr.TypeName.ToString() -eq "Parameter") {
                            foreach ($namedArg in $attr.NamedArguments) {
                                if ($namedArg.ArgumentName -eq "Mandatory") {
                                    $isMandatory = $true
                                    break
                                }
                            }
                        }
                    }

                    $parameters += [PSCustomObject]@{
                        Name      = $paramName
                        Type      = $paramType
                        Mandatory = $isMandatory
                    }
                }
            }
            $functionInfo | Add-Member -MemberType NoteProperty -Name "Parameters" -Value $parameters
        }

        $results += $functionInfo
    }

    return $results
}

function Compare-FunctionDefinitionsAndCalls {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMethodCalls,

        [Parameter(Mandatory = $false)]
        [switch]$ExcludeCommonCmdlets,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeParameters
    )

    # Obtenir les définitions de fonctions
    $definitions = Get-FunctionDefinitionAnalysis -ScriptPath $ScriptPath -IncludeParameters:$IncludeParameters

    # Obtenir les appels de fonctions
    $calls = Get-FunctionCallAnalysis -ScriptPath $ScriptPath -IncludeMethodCalls:$IncludeMethodCalls -ExcludeCommonCmdlets:$ExcludeCommonCmdlets

    # Créer un dictionnaire des fonctions définies
    $definedFunctions = @{}
    foreach ($def in $definitions) {
        $definedFunctions[$def.Name] = $def
    }

    # Créer un dictionnaire des fonctions appelées
    $calledFunctions = @{}
    foreach ($call in $calls) {
        if ($call.Type -eq "Command") {
            if (-not $calledFunctions.ContainsKey($call.Name)) {
                $calledFunctions[$call.Name] = @()
            }
            $calledFunctions[$call.Name] += $call
        }
    }

    # Analyser les résultats
    $results = [PSCustomObject]@{
        ScriptPath          = $ScriptPath
        DefinedFunctions    = $definitions
        CalledFunctions     = $calls | Where-Object { $_.Type -eq "Command" }
        MethodCalls         = $calls | Where-Object { $_.Type -eq "Method" }
        DefinedButNotCalled = @()
        CalledButNotDefined = @()
    }

    # Trouver les fonctions définies mais non appelées
    foreach ($defName in $definedFunctions.Keys) {
        if (-not $calledFunctions.ContainsKey($defName)) {
            $results.DefinedButNotCalled += $definedFunctions[$defName]
        }
    }

    # Trouver les fonctions appelées mais non définies
    foreach ($callName in $calledFunctions.Keys) {
        if (-not $definedFunctions.ContainsKey($callName)) {
            $results.CalledButNotDefined += $calledFunctions[$callName]
        }
    }

    return $results
}

function New-FunctionDependencyGraph {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "JSON", "DOT", "HTML")]
        [string]$OutputFormat = "Text",

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMethodCalls,

        [Parameter(Mandatory = $false)]
        [switch]$ExcludeCommonCmdlets
    )

    # Obtenir les définitions et appels de fonctions
    $analysis = Compare-FunctionDefinitionsAndCalls -ScriptPath $ScriptPath -IncludeMethodCalls:$IncludeMethodCalls -ExcludeCommonCmdlets:$ExcludeCommonCmdlets -IncludeParameters

    # Créer le graphe de dépendances
    $graph = @{}

    # Initialiser le graphe avec toutes les fonctions définies
    foreach ($function in $analysis.DefinedFunctions) {
        $graph[$function.Name] = @()
    }

    # Ajouter les dépendances
    foreach ($call in $analysis.CalledFunctions) {
        $callerFunction = $null

        # Trouver la fonction qui contient cet appel
        foreach ($function in $analysis.DefinedFunctions) {
            if ($call.Line -ge $function.Line -and $call.Line -le $function.EndLine) {
                $callerFunction = $function.Name
                break
            }
        }

        # Si l'appel est dans une fonction définie et la fonction appelée est également définie
        if ($callerFunction -and $graph.ContainsKey($callerFunction) -and $graph.ContainsKey($call.Name)) {
            # Éviter les auto-références
            if ($callerFunction -ne $call.Name) {
                $graph[$callerFunction] += $call.Name
            }
        }
    }

    # Éliminer les doublons dans les dépendances
    $graphKeys = $graph.Keys.Clone()
    foreach ($key in $graphKeys) {
        $graph[$key] = $graph[$key] | Select-Object -Unique
    }

    # Préparer le résultat
    $result = [PSCustomObject]@{
        ScriptPath = $ScriptPath
        Graph      = $graph
        Functions  = $analysis.DefinedFunctions
        Calls      = $analysis.CalledFunctions
    }

    # Exporter le résultat si demandé
    if ($OutputPath) {
        switch ($OutputFormat) {
            "Text" {
                $output = "Graphe de dépendances de fonctions pour $ScriptPath`n`n"
                foreach ($function in $graph.Keys | Sort-Object) {
                    $output += "$function dépend de: $($graph[$function] -join ', ')`n"
                }
                $output | Out-File -FilePath $OutputPath -Encoding UTF8
            }

            "JSON" {
                $result | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
            }

            "DOT" {
                $dot = "digraph FunctionDependencies {`n"
                $dot += "  node [shape=box];`n"

                foreach ($function in $graph.Keys | Sort-Object) {
                    $dot += "  `"$function`";`n"
                    foreach ($dependency in $graph[$function]) {
                        $dot += "  `"$function`" -> `"$dependency`";`n"
                    }
                }

                $dot += "}`n"
                $dot | Out-File -FilePath $OutputPath -Encoding UTF8
            }

            "HTML" {
                $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Graphe de dépendances de fonctions</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        .function { margin-bottom: 10px; }
        .function-name { font-weight: bold; }
        .dependencies { margin-left: 20px; }
    </style>
</head>
<body>
    <h1>Graphe de dépendances de fonctions pour $ScriptPath</h1>
    <div class="graph">
"@

                foreach ($function in $graph.Keys | Sort-Object) {
                    $html += @"
        <div class="function">
            <span class="function-name">$function</span> dépend de:
            <div class="dependencies">
"@
                    if ($graph[$function].Count -gt 0) {
                        foreach ($dependency in $graph[$function]) {
                            $html += "                <div>$dependency</div>`n"
                        }
                    } else {
                        $html += "                <div>(aucune dépendance)</div>`n"
                    }

                    $html += @"
            </div>
        </div>
"@
                }

                $html += @"
    </div>
</body>
</html>
"@
                $html | Out-File -FilePath $OutputPath -Encoding UTF8
            }
        }

        Write-Verbose "Graphe de dépendances exporté vers: $OutputPath"
    }

    return $result
}

# Exporter les fonctions du module
Export-ModuleMember -Function Get-FunctionCallAnalysis, Get-FunctionDefinitionAnalysis, Compare-FunctionDefinitionsAndCalls, New-FunctionDependencyGraph
