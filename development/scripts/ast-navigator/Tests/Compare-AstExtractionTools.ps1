#Requires -Version 5.1
<#
.SYNOPSIS
    Compare les performances des outils d'extraction AST avec d'autres outils d'analyse de code PowerShell.
.DESCRIPTION
    Ce script compare les performances des fonctions d'extraction AST du module AstNavigator
    avec d'autres outils d'analyse de code PowerShell comme PSScriptAnalyzer, PSParser et
    des approches basées sur des expressions régulières.
.PARAMETER TestScriptSizes
    Tailles des scripts de test à générer (Small, Medium, Large).
.PARAMETER Iterations
    Nombre d'itérations pour chaque test.
.PARAMETER OutputPath
    Chemin où enregistrer les résultats des comparaisons.
.PARAMETER GenerateReport
    Indique si un rapport HTML doit être généré.
.EXAMPLE
    .\Compare-AstExtractionTools.ps1 -TestScriptSizes @("Small", "Medium") -Iterations 5
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2023-05-01
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("Small", "Medium", "Large", "ExtraLarge")]
    [string[]]$TestScriptSizes = @("Small", "Medium"),

    [Parameter(Mandatory = $false)]
    [int]$Iterations = 3,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "$PSScriptRoot\Results",

    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport
)

# Importer les modules nécessaires
$modulePath = Split-Path -Parent $PSScriptRoot
if (-not (Get-Module -Name "AstNavigator" -ErrorAction SilentlyContinue)) {
    Import-Module "$modulePath\AstNavigator.psd1" -Force -ErrorAction Stop
}

# Vérifier si PSScriptAnalyzer est installé
$psScriptAnalyzerInstalled = $null -ne (Get-Module -ListAvailable -Name "PSScriptAnalyzer" -ErrorAction SilentlyContinue)
if (-not $psScriptAnalyzerInstalled) {
    Write-Warning "Le module PSScriptAnalyzer n'est pas installé. Certains tests seront ignorés."
}

# Créer le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Fonction pour générer un script de test de taille spécifique (réutilisée de Measure-AstExtractionPerformance.ps1)
function New-TestScript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Small", "Medium", "Large", "ExtraLarge")]
        [string]$Size,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )

    # Définir les paramètres en fonction de la taille
    $scriptParams = @{
        Small      = @{
            FunctionCount         = 5
            ParametersPerFunction = 3
            CommandsPerFunction   = 10
            VariablesPerFunction  = 5
            NestedDepth           = 2
        }
        Medium     = @{
            FunctionCount         = 20
            ParametersPerFunction = 5
            CommandsPerFunction   = 30
            VariablesPerFunction  = 15
            NestedDepth           = 3
        }
        Large      = @{
            FunctionCount         = 50
            ParametersPerFunction = 8
            CommandsPerFunction   = 100
            VariablesPerFunction  = 30
            NestedDepth           = 4
        }
        ExtraLarge = @{
            FunctionCount         = 200
            ParametersPerFunction = 10
            CommandsPerFunction   = 500
            VariablesPerFunction  = 100
            NestedDepth           = 5
        }
    }

    $params = $scriptParams[$Size]

    # Générer le contenu du script
    $scriptContent = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test généré automatiquement ($Size).
.DESCRIPTION
    Ce script a été généré pour tester les performances des fonctions d'extraction AST.
    Taille: $Size
    Fonctions: $($params.FunctionCount)
    Paramètres par fonction: $($params.ParametersPerFunction)
    Commandes par fonction: $($params.CommandsPerFunction)
    Variables par fonction: $($params.VariablesPerFunction)
    Profondeur d'imbrication: $($params.NestedDepth)
.NOTES
    Généré le: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
#>

"@

    # Ajouter des variables globales
    $scriptContent += "`n# Variables globales`n"
    for ($i = 1; $i -le $params.VariablesPerFunction; $i++) {
        $scriptContent += "`$global:Variable$i = '$i'`n"
    }

    # Générer les fonctions
    for ($funcIndex = 1; $funcIndex -le $params.FunctionCount; $funcIndex++) {
        $functionName = "Test-Function$funcIndex"

        # Début de la fonction
        $scriptContent += @"

function $functionName {
    [CmdletBinding()]
    param(
"@

        # Ajouter les paramètres
        for ($paramIndex = 1; $paramIndex -le $params.ParametersPerFunction; $paramIndex++) {
            $paramName = "Parameter$paramIndex"
            $paramType = @("string", "int", "bool", "array", "hashtable", "object")[$paramIndex % 6]
            $mandatory = if ($paramIndex -le 2) { "true" } else { "false" }

            $scriptContent += @"
        [Parameter(Mandatory = `$$mandatory)]
        [$paramType]`$$paramName$(if ($paramIndex -lt $params.ParametersPerFunction) { "," } else { "" })
"@
        }

        # Corps de la fonction
        $scriptContent += @"
    )

    begin {
        Write-Verbose "Début de la fonction $functionName"
"@

        # Ajouter des variables locales
        for ($varIndex = 1; $varIndex -le $params.VariablesPerFunction; $varIndex++) {
            $scriptContent += "        `$local$varIndex = `$Parameter1 + '$varIndex'`n"
        }

        $scriptContent += @"
    }

    process {
        # Traitement principal
"@

        # Ajouter des commandes
        for ($cmdIndex = 1; $cmdIndex -le $params.CommandsPerFunction; $cmdIndex++) {
            $cmdType = $cmdIndex % 5

            switch ($cmdType) {
                0 {
                    # Commande simple
                    $scriptContent += "        Write-Verbose `"Exécution de la commande $cmdIndex`"`n"
                }
                1 {
                    # Condition if
                    $scriptContent += @"
        if (`$Parameter1 -eq 'Test$cmdIndex') {
            Write-Verbose "Condition $cmdIndex vraie"
        } else {
            Write-Verbose "Condition $cmdIndex fausse"
        }
"@
                }
                2 {
                    # Boucle foreach
                    $scriptContent += @"
        foreach (`$item in @(1, 2, 3)) {
            Write-Verbose "Traitement de l'élément `$item dans la boucle $cmdIndex"
        }
"@
                }
                3 {
                    # Try/catch
                    $scriptContent += @"
        try {
            Write-Verbose "Tentative d'opération $cmdIndex"
        } catch {
            Write-Error "Erreur dans l'opération $cmdIndex : `$_"
        }
"@
                }
                4 {
                    # Structure imbriquée (selon la profondeur)
                    $nestedContent = "            Write-Verbose `"Niveau le plus profond atteint`"`n"

                    for ($depth = $params.NestedDepth; $depth -gt 0; $depth--) {
                        $nestedContent = @"
        if (`$Parameter1 -eq 'Niveau$depth') {
$nestedContent        }
"@
                    }

                    $scriptContent += $nestedContent
                }
            }
        }

        $scriptContent += @"
    }

    end {
        Write-Verbose "Fin de la fonction $functionName"
        return `$Parameter1
    }
}
"@
    }

    # Ajouter un appel à chaque fonction
    $scriptContent += "`n# Appels de fonctions`n"
    for ($funcIndex = 1; $funcIndex -le $params.FunctionCount; $funcIndex++) {
        $functionName = "Test-Function$funcIndex"
        $scriptContent += "$functionName -Parameter1 'TestValue$funcIndex' -Parameter2 $funcIndex`n"
    }

    # Enregistrer le script si un chemin est spécifié
    if ($OutputPath) {
        $scriptPath = Join-Path -Path $OutputPath -ChildPath "TestScript_$Size.ps1"
        Set-Content -Path $scriptPath -Value $scriptContent -Encoding UTF8
        return $scriptPath
    } else {
        return $scriptContent
    }
}

# Fonction pour mesurer les performances d'un outil d'analyse
function Measure-ToolPerformance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $true)]
        [string]$ToolName,

        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{},

        [Parameter(Mandatory = $false)]
        [int]$Iterations = 3
    )

    # Préparer les résultats
    $results = @{
        ToolName       = $ToolName
        ScriptPath     = $ScriptPath
        ScriptSize     = (Get-Item -Path $ScriptPath).Length
        LineCount      = (Get-Content -Path $ScriptPath).Count
        Iterations     = $Iterations
        ExecutionTimes = @()
        MemoryUsage    = @()
        CPUUsage       = @()
        Success        = $true
        ErrorMessage   = $null
    }

    # Exécuter les itérations
    for ($i = 0; $i -lt $Iterations; $i++) {
        try {
            # Mesurer l'utilisation de la mémoire et du CPU avant
            $processBeforeMemory = (Get-Process -Id $PID).WorkingSet64
            $processBeforeCPU = (Get-Process -Id $PID).CPU

            # Mesurer le temps d'exécution
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            # Exécuter le script block avec les paramètres
            $scriptParams = $Parameters.Clone()
            $scriptParams["ScriptPath"] = $ScriptPath

            $result = & $ScriptBlock @scriptParams

            $stopwatch.Stop()

            # Mesurer l'utilisation de la mémoire et du CPU après
            $processAfterMemory = (Get-Process -Id $PID).WorkingSet64
            $processAfterCPU = (Get-Process -Id $PID).CPU

            $memoryUsage = $processAfterMemory - $processBeforeMemory
            $cpuUsage = $processAfterCPU - $processBeforeCPU

            # Enregistrer les résultats
            $results.ExecutionTimes += $stopwatch.ElapsedMilliseconds
            $results.MemoryUsage += $memoryUsage
            $results.CPUUsage += $cpuUsage

            # Collecter des informations sur le résultat
            if ($i -eq 0) {
                if ($result -is [array]) {
                    $results["ResultCount"] = $result.Count
                } else {
                    $results["ResultCount"] = 1
                }
            }

            # Forcer le garbage collection entre les itérations
            [System.GC]::Collect()
            Start-Sleep -Milliseconds 100
        } catch {
            $results.Success = $false
            $results.ErrorMessage = $_.Exception.Message
            Write-Warning "Erreur lors de l'exécution de $ToolName : $_"
            break
        }
    }

    # Calculer les statistiques
    if ($results.Success) {
        $results["AverageExecutionTime"] = ($results.ExecutionTimes | Measure-Object -Average).Average
        $results["MinExecutionTime"] = ($results.ExecutionTimes | Measure-Object -Minimum).Minimum
        $results["MaxExecutionTime"] = ($results.ExecutionTimes | Measure-Object -Maximum).Maximum
        $results["AverageMemoryUsage"] = ($results.MemoryUsage | Measure-Object -Average).Average
        $results["AverageCPUUsage"] = ($results.CPUUsage | Measure-Object -Average).Average
    }

    return [PSCustomObject]$results
}

# Fonction pour générer un rapport HTML de comparaison
function New-ComparisonReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$Results,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    $reportPath = Join-Path -Path $OutputPath -ChildPath "AstExtractionToolsComparison_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"

    # Créer le contenu HTML
    $htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Comparaison des outils d'analyse de code PowerShell</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2, h3 { color: #333; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .chart-container { width: 100%; height: 400px; margin-bottom: 30px; }
        .summary { background-color: #e7f3fe; padding: 15px; border-left: 5px solid #2196F3; margin-bottom: 20px; }
        .error { color: red; }
        .success { color: green; }
        .winner { background-color: #dff0d8; }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <h1>Comparaison des outils d'analyse de code PowerShell</h1>
    <div class="summary">
        <p><strong>Date du rapport:</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        <p><strong>Nombre d'outils comparés:</strong> $($Results | Select-Object -ExpandProperty ToolName -Unique | Measure-Object | Select-Object -ExpandProperty Count)</p>
        <p><strong>Tailles de scripts testées:</strong> $($Results | ForEach-Object { (Split-Path -Leaf $_.ScriptPath) -replace 'TestScript_(.+)\.ps1', '$1' } | Select-Object -Unique | Join-String -Separator ', ')</p>
        <p><strong>Version PowerShell:</strong> $($PSVersionTable.PSVersion)</p>
        <p><strong>Système d'exploitation:</strong> $([System.Environment]::OSVersion.VersionString)</p>
    </div>

    <h2>Graphiques de comparaison</h2>
"@

    # Créer un graphique pour chaque taille de script
    $scriptSizes = $Results | ForEach-Object { (Split-Path -Leaf $_.ScriptPath) -replace 'TestScript_(.+)\.ps1', '$1' } | Select-Object -Unique

    foreach ($size in $scriptSizes) {
        $sizeResults = $Results | Where-Object { (Split-Path -Leaf $_.ScriptPath) -like "TestScript_$size.ps1" }

        $htmlContent += @"
    <h3>Script de taille $size</h3>
    <div class="chart-container">
        <canvas id="executionTimeChart_$size"></canvas>
    </div>
    <div class="chart-container">
        <canvas id="memoryUsageChart_$size"></canvas>
    </div>
"@
    }

    # Tableau récapitulatif
    $htmlContent += @"
    <h2>Résultats détaillés</h2>
    <table>
        <tr>
            <th>Outil</th>
            <th>Taille du script</th>
            <th>Temps moyen (ms)</th>
            <th>Temps min (ms)</th>
            <th>Temps max (ms)</th>
            <th>Mémoire moyenne (KB)</th>
            <th>CPU moyen</th>
            <th>Résultats</th>
            <th>Statut</th>
        </tr>
"@

    # Ajouter les résultats au tableau
    foreach ($size in $scriptSizes) {
        $sizeResults = $Results | Where-Object { (Split-Path -Leaf $_.ScriptPath) -like "TestScript_$size.ps1" }

        # Trouver l'outil le plus rapide pour cette taille
        $fastestTool = $sizeResults |
            Where-Object { $_.Success } |
            Sort-Object -Property AverageExecutionTime |
            Select-Object -First 1 -ExpandProperty ToolName

        foreach ($result in $sizeResults) {
            $statusClass = if ($result.Success) { "success" } else { "error" }
            $statusText = if ($result.Success) { "Succès" } else { "Échec: $($result.ErrorMessage)" }
            $winnerClass = if ($result.ToolName -eq $fastestTool) { "winner" } else { "" }

            $htmlContent += @"
        <tr class="$winnerClass">
            <td>$($result.ToolName)</td>
            <td>$((Split-Path -Leaf $result.ScriptPath) -replace 'TestScript_(.+)\.ps1', '$1')</td>
            <td>$('{0:N2}' -f $result.AverageExecutionTime)</td>
            <td>$('{0:N2}' -f $result.MinExecutionTime)</td>
            <td>$('{0:N2}' -f $result.MaxExecutionTime)</td>
            <td>$('{0:N2}' -f ($result.AverageMemoryUsage / 1KB))</td>
            <td>$('{0:N2}' -f $result.AverageCPUUsage)</td>
            <td>$($result.ResultCount)</td>
            <td class="$statusClass">$statusText</td>
        </tr>
"@
        }
    }

    # Fermer le tableau et préparer les données pour les graphiques
    $htmlContent += @"
    </table>

    <script>
"@

    # Ajouter les scripts pour chaque graphique
    foreach ($size in $scriptSizes) {
        $sizeResults = $Results | Where-Object { (Split-Path -Leaf $_.ScriptPath) -like "TestScript_$size.ps1" }

        $htmlContent += @"
        // Données pour les graphiques de taille $size
        const tools_$size = [$(($sizeResults | ForEach-Object { "'$($_.ToolName)'" }) -join ', ')];
        const executionTimes_$size = [$(($sizeResults | ForEach-Object { $_.AverageExecutionTime }) -join ', ')];
        const memoryUsages_$size = [$(($sizeResults | ForEach-Object { $_.AverageMemoryUsage / 1KB }) -join ', ')];

        // Graphique des temps d'exécution pour $size
        const executionTimeCtx_$size = document.getElementById('executionTimeChart_$size').getContext('2d');
        new Chart(executionTimeCtx_$size, {
            type: 'bar',
            data: {
                labels: tools_$size,
                datasets: [{
                    label: 'Temps d\'exécution moyen (ms)',
                    data: executionTimes_$size,
                    backgroundColor: 'rgba(54, 162, 235, 0.5)',
                    borderColor: 'rgba(54, 162, 235, 1)',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Millisecondes'
                        }
                    }
                }
            }
        });

        // Graphique de l'utilisation de la mémoire pour $size
        const memoryUsageCtx_$size = document.getElementById('memoryUsageChart_$size').getContext('2d');
        new Chart(memoryUsageCtx_$size, {
            type: 'bar',
            data: {
                labels: tools_$size,
                datasets: [{
                    label: 'Utilisation moyenne de la mémoire (KB)',
                    data: memoryUsages_$size,
                    backgroundColor: 'rgba(75, 192, 192, 0.5)',
                    borderColor: 'rgba(75, 192, 192, 1)',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Kilooctets (KB)'
                        }
                    }
                }
            }
        });
"@
    }

    $htmlContent += @"
    </script>
</body>
</html>
"@

    # Enregistrer le rapport
    Set-Content -Path $reportPath -Value $htmlContent -Encoding UTF8

    return $reportPath
}

# Fonction principale pour exécuter les comparaisons
function Start-ToolsComparison {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$TestScriptSizes,

        [Parameter(Mandatory = $true)]
        [int]$Iterations,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    $results = @()
    $testScripts = @{}

    # Générer les scripts de test
    Write-Host "Génération des scripts de test..." -ForegroundColor Cyan
    foreach ($size in $TestScriptSizes) {
        Write-Host "  Création du script de test de taille $size..." -ForegroundColor Yellow
        $scriptPath = New-TestScript -Size $size -OutputPath $OutputPath
        $testScripts[$size] = $scriptPath
        Write-Host "  Script créé: $scriptPath" -ForegroundColor Green
    }

    # Définir les outils à comparer
    $toolsToCompare = @(
        @{
            Name        = "AstNavigator (Get-AstFunctions)"
            ScriptBlock = {
                param($ScriptPath)

                $scriptContent = Get-Content -Path $ScriptPath -Raw
                $tokens = $errors = $null
                $ast = [System.Management.Automation.Language.Parser]::ParseInput($scriptContent, [ref]$tokens, [ref]$errors)

                return Get-AstFunctions -Ast $ast
            }
        },
        @{
            Name        = "AstNavigator (Optimize-AstExtraction)"
            ScriptBlock = {
                param($ScriptPath)

                $scriptContent = Get-Content -Path $ScriptPath -Raw
                $tokens = $errors = $null
                $ast = [System.Management.Automation.Language.Parser]::ParseInput($scriptContent, [ref]$tokens, [ref]$errors)

                return Optimize-AstExtraction -Ast $ast -NodeType "FunctionDefinition" -UseCache
            }
        },
        @{
            Name        = "AST natif (FindAll)"
            ScriptBlock = {
                param($ScriptPath)

                $scriptContent = Get-Content -Path $ScriptPath -Raw
                $tokens = $errors = $null
                $ast = [System.Management.Automation.Language.Parser]::ParseInput($scriptContent, [ref]$tokens, [ref]$errors)

                return $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
            }
        },
        @{
            Name        = "Expressions régulières"
            ScriptBlock = {
                param($ScriptPath)

                $scriptContent = Get-Content -Path $ScriptPath -Raw
                $functionPattern = 'function\s+([a-zA-Z0-9_-]+)\s*\{'

                $regexMatches = [regex]::Matches($scriptContent, $functionPattern)

                return $regexMatches | ForEach-Object {
                    [PSCustomObject]@{
                        Name      = $_.Groups[1].Value
                        StartLine = ($scriptContent.Substring(0, $_.Index).Split("`n")).Count
                    }
                }
            }
        }
    )

    # Ajouter PSScriptAnalyzer si disponible
    if ($psScriptAnalyzerInstalled) {
        $toolsToCompare += @{
            Name        = "PSScriptAnalyzer"
            ScriptBlock = {
                param($ScriptPath)

                $rules = @('PSUseCompatibleSyntax', 'PSAvoidUsingCmdletAliases', 'PSAvoidUsingPositionalParameters')
                return Invoke-ScriptAnalyzer -Path $ScriptPath -IncludeRule $rules
            }
        }
    }

    # Exécuter les comparaisons
    Write-Host "`nExécution des comparaisons..." -ForegroundColor Cyan

    foreach ($size in $TestScriptSizes) {
        $scriptPath = $testScripts[$size]
        Write-Host "  Tests pour le script de taille $size..." -ForegroundColor Yellow

        foreach ($tool in $toolsToCompare) {
            Write-Host "    Mesure des performances de $($tool.Name)..." -ForegroundColor Yellow
            $result = Measure-ToolPerformance -ScriptPath $scriptPath -ToolName $tool.Name -ScriptBlock $tool.ScriptBlock -Iterations $Iterations

            $results += $result

            if ($result.Success) {
                Write-Host "      Temps moyen: $([math]::Round($result.AverageExecutionTime, 2)) ms, Mémoire: $([math]::Round($result.AverageMemoryUsage / 1KB, 2)) KB" -ForegroundColor Green
            } else {
                Write-Host "      Échec: $($result.ErrorMessage)" -ForegroundColor Red
            }
        }
    }

    # Enregistrer les résultats bruts
    $resultsPath = Join-Path -Path $OutputPath -ChildPath "AstExtractionToolsComparison_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $results | ConvertTo-Json -Depth 5 | Set-Content -Path $resultsPath -Encoding UTF8

    Write-Host "`nRésultats enregistrés: $resultsPath" -ForegroundColor Green

    return $results
}

# Exécuter les comparaisons
$comparisonResults = Start-ToolsComparison -TestScriptSizes $TestScriptSizes -Iterations $Iterations -OutputPath $OutputPath

# Générer le rapport HTML si demandé
if ($GenerateReport) {
    Write-Host "`nGénération du rapport HTML..." -ForegroundColor Cyan
    $reportPath = New-ComparisonReport -Results $comparisonResults -OutputPath $OutputPath
    Write-Host "Rapport généré: $reportPath" -ForegroundColor Green

    # Ouvrir le rapport dans le navigateur par défaut
    Start-Process $reportPath
}

# Afficher un résumé
Write-Host "`nRésumé des comparaisons:" -ForegroundColor Cyan
foreach ($size in $TestScriptSizes) {
    $sizeResults = $comparisonResults | Where-Object { (Split-Path -Leaf $_.ScriptPath) -like "TestScript_$size.ps1" }
    Write-Host "  Script de taille $($size):" -ForegroundColor Yellow

    # Trouver l'outil le plus rapide
    $fastestTool = $sizeResults |
        Where-Object { $_.Success } |
        Sort-Object -Property AverageExecutionTime |
        Select-Object -First 1

    foreach ($result in ($sizeResults | Sort-Object -Property AverageExecutionTime)) {
        $isFastest = $result.ToolName -eq $fastestTool.ToolName
        $fastestIndicator = if ($isFastest) { " (le plus rapide)" } else { "" }

        if ($result.Success) {
            $color = if ($isFastest) { "Green" } else { "White" }
            Write-Host "    $($result.ToolName): $([math]::Round($result.AverageExecutionTime, 2)) ms$fastestIndicator" -ForegroundColor $color
        } else {
            Write-Host "    $($result.ToolName): Échec - $($result.ErrorMessage)" -ForegroundColor Red
        }
    }
}
