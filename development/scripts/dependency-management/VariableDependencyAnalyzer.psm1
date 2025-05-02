#Requires -Version 5.1

<#
.SYNOPSIS
    Module pour l'analyse des dépendances de variables dans les scripts PowerShell.

.DESCRIPTION
    Ce module fournit des fonctions pour analyser les utilisations de variables dans les scripts PowerShell,
    détecter les variables définies vs. utilisées, et générer un graphe de dépendances de variables.

.NOTES
    Auteur: Dependency Management Team
    Version: 1.0
    Date de création: 2023-07-25
#>

# Aucun module externe requis pour ce module

function Get-VariableUsageAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Path')]
        [string]$ScriptPath,

        [Parameter(Mandatory = $true, ParameterSetName = 'Content')]
        [string]$ScriptContent,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeSystemVariables,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeEnvironmentVariables
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

    # Trouver toutes les utilisations de variables
    $variableExpressions = $ast.FindAll({
        param($node)
        $node.GetType().Name -eq 'VariableExpressionAst'
    }, $true)

    # Trouver toutes les assignations de variables
    $assignmentStatements = $ast.FindAll({
        param($node)
        $node.GetType().Name -eq 'AssignmentStatementAst'
    }, $true)

    # Collecter les résultats
    $results = @()

    # Variables système à exclure si demandé
    $systemVariables = @('_', 'PSItem', 'args', 'input', 'PSCmdlet', 'MyInvocation', 'PSBoundParameters', 'PSScriptRoot', 'PSCommandPath', 'error', 'foreach', 'this', 'null', 'true', 'false')

    # Traiter les assignations de variables
    foreach ($assignment in $assignmentStatements) {
        $variableName = $null
        
        # Extraire le nom de la variable assignée
        if ($assignment.Left.GetType().Name -eq 'VariableExpressionAst') {
            $variableName = $assignment.Left.VariablePath.UserPath
        }
        
        # Ignorer les variables système si demandé
        if (-not $IncludeSystemVariables -and $systemVariables -contains $variableName) {
            continue
        }
        
        # Ignorer les variables d'environnement si demandé
        if (-not $IncludeEnvironmentVariables -and $variableName -like 'env:*') {
            continue
        }
        
        if ($variableName) {
            $results += [PSCustomObject]@{
                ScriptName = $scriptName
                Type = "Assignment"
                Name = $variableName
                Line = $assignment.Extent.StartLineNumber
                Column = $assignment.Extent.StartColumnNumber
                Value = $assignment.Right.Extent.Text
                IsDefined = $true
                IsUsed = $false
            }
        }
    }

    # Traiter les utilisations de variables
    foreach ($varExpr in $variableExpressions) {
        $variableName = $varExpr.VariablePath.UserPath
        
        # Ignorer les variables système si demandé
        if (-not $IncludeSystemVariables -and $systemVariables -contains $variableName) {
            continue
        }
        
        # Ignorer les variables d'environnement si demandé
        if (-not $IncludeEnvironmentVariables -and $variableName -like 'env:*') {
            continue
        }
        
        # Vérifier si cette variable est déjà dans les résultats comme une assignation
        $existingAssignment = $results | Where-Object { 
            $_.Type -eq "Assignment" -and 
            $_.Name -eq $variableName -and 
            $_.Line -eq $varExpr.Extent.StartLineNumber -and 
            $_.Column -eq $varExpr.Extent.StartColumnNumber
        }
        
        # Si ce n'est pas une assignation déjà traitée, l'ajouter comme utilisation
        if (-not $existingAssignment) {
            $results += [PSCustomObject]@{
                ScriptName = $scriptName
                Type = "Usage"
                Name = $variableName
                Line = $varExpr.Extent.StartLineNumber
                Column = $varExpr.Extent.StartColumnNumber
                Value = $null
                IsDefined = $false
                IsUsed = $true
            }
        }
    }

    # Marquer les variables qui sont à la fois définies et utilisées
    $variableNames = $results | Select-Object -ExpandProperty Name -Unique
    foreach ($name in $variableNames) {
        $isDefined = $results | Where-Object { $_.Name -eq $name -and $_.Type -eq "Assignment" } | Select-Object -First 1
        $isUsed = $results | Where-Object { $_.Name -eq $name -and $_.Type -eq "Usage" } | Select-Object -First 1
        
        if ($isDefined) {
            $isDefined.IsUsed = $isUsed -ne $null
        }
        
        if ($isUsed) {
            $isUsed.IsDefined = $isDefined -ne $null
        }
    }

    return $results
}

function Compare-VariableDefinitionsAndUsages {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeSystemVariables,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeEnvironmentVariables
    )

    # Obtenir les utilisations de variables
    $variableUsages = Get-VariableUsageAnalysis -ScriptPath $ScriptPath -IncludeSystemVariables:$IncludeSystemVariables -IncludeEnvironmentVariables:$IncludeEnvironmentVariables

    # Créer des dictionnaires pour les variables définies et utilisées
    $definedVariables = @{}
    $usedVariables = @{}

    # Remplir les dictionnaires
    foreach ($usage in $variableUsages) {
        if ($usage.Type -eq "Assignment") {
            if (-not $definedVariables.ContainsKey($usage.Name)) {
                $definedVariables[$usage.Name] = @()
            }
            $definedVariables[$usage.Name] += $usage
        } elseif ($usage.Type -eq "Usage") {
            if (-not $usedVariables.ContainsKey($usage.Name)) {
                $usedVariables[$usage.Name] = @()
            }
            $usedVariables[$usage.Name] += $usage
        }
    }

    # Analyser les résultats
    $results = [PSCustomObject]@{
        ScriptPath = $ScriptPath
        DefinedVariables = $variableUsages | Where-Object { $_.Type -eq "Assignment" }
        UsedVariables = $variableUsages | Where-Object { $_.Type -eq "Usage" }
        DefinedButNotUsed = @()
        UsedButNotDefined = @()
    }

    # Trouver les variables définies mais non utilisées
    foreach ($name in $definedVariables.Keys) {
        $isUsed = $usedVariables.ContainsKey($name)
        if (-not $isUsed) {
            $results.DefinedButNotUsed += $definedVariables[$name]
        }
    }

    # Trouver les variables utilisées mais non définies
    foreach ($name in $usedVariables.Keys) {
        $isDefined = $definedVariables.ContainsKey($name)
        if (-not $isDefined) {
            $results.UsedButNotDefined += $usedVariables[$name]
        }
    }

    return $results
}

function New-VariableDependencyGraph {
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
        [switch]$IncludeSystemVariables,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeEnvironmentVariables
    )

    # Obtenir les utilisations de variables
    $variableUsages = Get-VariableUsageAnalysis -ScriptPath $ScriptPath -IncludeSystemVariables:$IncludeSystemVariables -IncludeEnvironmentVariables:$IncludeEnvironmentVariables

    # Créer le graphe de dépendances
    $graph = @{}
    
    # Initialiser le graphe avec toutes les variables définies
    $definedVariables = $variableUsages | Where-Object { $_.Type -eq "Assignment" } | Select-Object -ExpandProperty Name -Unique
    foreach ($variable in $definedVariables) {
        $graph[$variable] = @()
    }

    # Ajouter les dépendances
    foreach ($assignment in ($variableUsages | Where-Object { $_.Type -eq "Assignment" })) {
        $variableName = $assignment.Name
        $assignmentLine = $assignment.Line
        
        # Trouver toutes les variables utilisées dans cette assignation
        $usedInAssignment = $variableUsages | Where-Object { 
            $_.Type -eq "Usage" -and 
            $_.Line -eq $assignmentLine -and 
            $_.Name -ne $variableName
        }
        
        foreach ($usage in $usedInAssignment) {
            if ($graph.ContainsKey($variableName) -and $definedVariables -contains $usage.Name) {
                $graph[$variableName] += $usage.Name
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
        Graph = $graph
        Variables = $variableUsages
    }

    # Exporter le résultat si demandé
    if ($OutputPath) {
        switch ($OutputFormat) {
            "Text" {
                $output = "Graphe de dépendances de variables pour $ScriptPath`n`n"
                foreach ($variable in $graph.Keys | Sort-Object) {
                    $output += "$variable dépend de: $($graph[$variable] -join ', ')`n"
                }
                $output | Out-File -FilePath $OutputPath -Encoding UTF8
            }
            
            "JSON" {
                $result | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
            }
            
            "DOT" {
                $dot = "digraph VariableDependencies {`n"
                $dot += "  node [shape=box];`n"
                
                foreach ($variable in $graph.Keys | Sort-Object) {
                    $dot += "  `"$variable`";`n"
                    foreach ($dependency in $graph[$variable]) {
                        $dot += "  `"$variable`" -> `"$dependency`";`n"
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
    <title>Graphe de dépendances de variables</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        .variable { margin-bottom: 10px; }
        .variable-name { font-weight: bold; }
        .dependencies { margin-left: 20px; }
    </style>
</head>
<body>
    <h1>Graphe de dépendances de variables pour $ScriptPath</h1>
    <div class="graph">
"@
                
                foreach ($variable in $graph.Keys | Sort-Object) {
                    $html += @"
        <div class="variable">
            <span class="variable-name">$variable</span> dépend de:
            <div class="dependencies">
"@
                    if ($graph[$variable].Count -gt 0) {
                        foreach ($dependency in $graph[$variable]) {
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
Export-ModuleMember -Function Get-VariableUsageAnalysis, Compare-VariableDefinitionsAndUsages, New-VariableDependencyGraph
