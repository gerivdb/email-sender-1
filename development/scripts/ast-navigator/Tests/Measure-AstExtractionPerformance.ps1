#Requires -Version 5.1
<#
.SYNOPSIS
    Mesure les performances des fonctions d'extraction AST.
.DESCRIPTION
    Ce script mesure les performances des différentes fonctions d'extraction AST
    avec différentes tailles de scripts et génère un rapport détaillé.
.PARAMETER TestScriptSizes
    Tailles des scripts de test à générer (Small, Medium, Large).
.PARAMETER Iterations
    Nombre d'itérations pour chaque test.
.PARAMETER OutputPath
    Chemin où enregistrer les résultats des benchmarks.
.PARAMETER GenerateReport
    Indique si un rapport HTML doit être généré.
.EXAMPLE
    .\Measure-AstExtractionPerformance.ps1 -TestScriptSizes @("Small", "Medium") -Iterations 5
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2023-05-01
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("Small", "Medium", "Large", "ExtraLarge")]
    [string[]]$TestScriptSizes = @("Small", "Medium", "Large"),

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

# Créer le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Fonction pour générer un script de test de taille spécifique
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

# Fonction pour mesurer les performances d'une fonction d'extraction
function Measure-ExtractionPerformance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $true)]
        [string]$FunctionName,

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{},

        [Parameter(Mandatory = $false)]
        [int]$Iterations = 3
    )

    # Charger le contenu du script
    $scriptContent = Get-Content -Path $ScriptPath -Raw

    # Analyser le script avec l'AST
    $tokens = $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($scriptContent, [ref]$tokens, [ref]$errors)

    if ($errors -and $errors.Count -gt 0) {
        Write-Warning "Erreurs d'analyse dans le script: $($errors.Count) erreurs"
    }

    # Préparer les résultats
    $results = @{
        FunctionName   = $FunctionName
        ScriptPath     = $ScriptPath
        ScriptSize     = (Get-Item -Path $ScriptPath).Length
        LineCount      = ($scriptContent -split "`n").Count
        Iterations     = $Iterations
        ExecutionTimes = @()
        MemoryUsage    = @()
        Success        = $true
        ErrorMessage   = $null
    }

    # Exécuter les itérations
    for ($i = 0; $i -lt $Iterations; $i++) {
        try {
            # Mesurer l'utilisation de la mémoire avant
            $processBeforeMemory = (Get-Process -Id $PID).WorkingSet64

            # Mesurer le temps d'exécution
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            # Exécuter la fonction avec les paramètres
            $functionParams = $Parameters.Clone()
            $functionParams["Ast"] = $ast

            $result = & $FunctionName @functionParams

            $stopwatch.Stop()

            # Mesurer l'utilisation de la mémoire après
            $processAfterMemory = (Get-Process -Id $PID).WorkingSet64
            $memoryUsage = $processAfterMemory - $processBeforeMemory

            # Enregistrer les résultats
            $results.ExecutionTimes += $stopwatch.ElapsedMilliseconds
            $results.MemoryUsage += $memoryUsage

            # Collecter des informations sur le résultat
            if ($i -eq 0) {
                if ($result -is [array]) {
                    $results["ResultCount"] = $result.Count
                } else {
                    $results["ResultCount"] = 1
                }
            }
        } catch {
            $results.Success = $false
            $results.ErrorMessage = $_.Exception.Message
            Write-Warning "Erreur lors de l'exécution de $FunctionName : $_"
            break
        }
    }

    # Calculer les statistiques
    if ($results.Success) {
        $results["AverageExecutionTime"] = ($results.ExecutionTimes | Measure-Object -Average).Average
        $results["MinExecutionTime"] = ($results.ExecutionTimes | Measure-Object -Minimum).Minimum
        $results["MaxExecutionTime"] = ($results.ExecutionTimes | Measure-Object -Maximum).Maximum
        $results["AverageMemoryUsage"] = ($results.MemoryUsage | Measure-Object -Average).Average
    }

    return [PSCustomObject]$results
}

# Fonction pour générer un rapport HTML
function New-PerformanceReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$Results,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    $reportPath = Join-Path -Path $OutputPath -ChildPath "AstExtractionPerformance_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"

    # Créer le contenu HTML
    $htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de performance d'extraction AST</title>
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
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <h1>Rapport de performance d'extraction AST</h1>
    <div class="summary">
        <p><strong>Date du rapport:</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        <p><strong>Nombre de tests:</strong> $($Results.Count)</p>
        <p><strong>Version PowerShell:</strong> $($PSVersionTable.PSVersion)</p>
        <p><strong>Système d'exploitation:</strong> $([System.Environment]::OSVersion.VersionString)</p>
    </div>

    <h2>Résumé des performances</h2>
    <div class="chart-container">
        <canvas id="executionTimeChart"></canvas>
    </div>
    <div class="chart-container">
        <canvas id="memoryUsageChart"></canvas>
    </div>

    <h2>Résultats détaillés</h2>
    <table>
        <tr>
            <th>Fonction</th>
            <th>Taille du script</th>
            <th>Lignes</th>
            <th>Temps moyen (ms)</th>
            <th>Temps min (ms)</th>
            <th>Temps max (ms)</th>
            <th>Mémoire moyenne (KB)</th>
            <th>Résultats</th>
            <th>Statut</th>
        </tr>
"@

    # Ajouter les résultats au tableau
    foreach ($result in $Results) {
        $statusClass = if ($result.Success) { "success" } else { "error" }
        $statusText = if ($result.Success) { "Succès" } else { "Échec: $($result.ErrorMessage)" }

        $htmlContent += @"
        <tr>
            <td>$($result.FunctionName)</td>
            <td>$('{0:N0}' -f $result.ScriptSize) octets</td>
            <td>$($result.LineCount)</td>
            <td>$('{0:N2}' -f $result.AverageExecutionTime)</td>
            <td>$('{0:N2}' -f $result.MinExecutionTime)</td>
            <td>$('{0:N2}' -f $result.MaxExecutionTime)</td>
            <td>$('{0:N2}' -f ($result.AverageMemoryUsage / 1KB))</td>
            <td>$($result.ResultCount)</td>
            <td class="$statusClass">$statusText</td>
        </tr>
"@
    }

    # Fermer le tableau et préparer les données pour les graphiques
    $htmlContent += @"
    </table>

    <script>
        // Données pour les graphiques
        const functions = [$(($Results | ForEach-Object { "'$($_.FunctionName)'" }) -join ', ')];
        const scriptSizes = [$(($Results | ForEach-Object { "'$(Split-Path -Leaf $_.ScriptPath)'" }) -join ', ')];
        const executionTimes = [$(($Results | ForEach-Object { $_.AverageExecutionTime }) -join ', ')];
        const memoryUsages = [$(($Results | ForEach-Object { $_.AverageMemoryUsage / 1KB }) -join ', ')];

        // Graphique des temps d'exécution
        const executionTimeCtx = document.getElementById('executionTimeChart').getContext('2d');
        new Chart(executionTimeCtx, {
            type: 'bar',
            data: {
                labels: functions,
                datasets: [{
                    label: 'Temps d\'exécution moyen (ms)',
                    data: executionTimes,
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

        // Graphique de l'utilisation de la mémoire
        const memoryUsageCtx = document.getElementById('memoryUsageChart').getContext('2d');
        new Chart(memoryUsageCtx, {
            type: 'bar',
            data: {
                labels: functions,
                datasets: [{
                    label: 'Utilisation moyenne de la mémoire (KB)',
                    data: memoryUsages,
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
    </script>
</body>
</html>
"@

    # Enregistrer le rapport
    Set-Content -Path $reportPath -Value $htmlContent -Encoding UTF8

    return $reportPath
}

# Fonction principale pour exécuter les benchmarks
function Start-AstExtractionBenchmark {
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

    # Définir les fonctions à tester
    $functionsToTest = @(
        @{
            Name       = "Get-AstFunctions"
            Parameters = @{}
        },
        @{
            Name        = "Get-AstFunctions"
            Parameters  = @{ Detailed = $true }
            DisplayName = "Get-AstFunctions -Detailed"
        },
        @{
            Name       = "Get-AstParameters"
            Parameters = @{}
        },
        @{
            Name       = "Get-AstVariables"
            Parameters = @{}
        },
        @{
            Name       = "Get-AstCommands"
            Parameters = @{}
        }
    )

    # Exécuter les benchmarks
    Write-Host "`nExécution des benchmarks..." -ForegroundColor Cyan

    foreach ($size in $TestScriptSizes) {
        $scriptPath = $testScripts[$size]
        Write-Host "  Tests pour le script de taille $size..." -ForegroundColor Yellow

        foreach ($function in $functionsToTest) {
            $functionName = $function.Name
            $displayName = if ($function.DisplayName) { $function.DisplayName } else { $functionName }

            Write-Host "    Mesure des performances de $displayName..." -ForegroundColor Yellow
            $result = Measure-ExtractionPerformance -ScriptPath $scriptPath -FunctionName $functionName -Parameters $function.Parameters -Iterations $Iterations

            # Ajouter des informations supplémentaires
            $result | Add-Member -MemberType NoteProperty -Name "ScriptSizeCategory" -Value $size
            $result | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value $displayName

            $results += $result

            if ($result.Success) {
                Write-Host "      Temps moyen: $([math]::Round($result.AverageExecutionTime, 2)) ms, Mémoire: $([math]::Round($result.AverageMemoryUsage / 1KB, 2)) KB" -ForegroundColor Green
            } else {
                Write-Host "      Échec: $($result.ErrorMessage)" -ForegroundColor Red
            }
        }
    }

    # Enregistrer les résultats bruts
    $resultsPath = Join-Path -Path $OutputPath -ChildPath "AstExtractionPerformance_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $results | ConvertTo-Json -Depth 5 | Set-Content -Path $resultsPath -Encoding UTF8

    Write-Host "`nRésultats enregistrés: $resultsPath" -ForegroundColor Green

    return $results
}

# Exécuter les benchmarks
$benchmarkResults = Start-AstExtractionBenchmark -TestScriptSizes $TestScriptSizes -Iterations $Iterations -OutputPath $OutputPath

# Générer le rapport HTML si demandé
if ($GenerateReport) {
    Write-Host "`nGénération du rapport HTML..." -ForegroundColor Cyan
    $reportPath = New-PerformanceReport -Results $benchmarkResults -OutputPath $OutputPath
    Write-Host "Rapport généré: $reportPath" -ForegroundColor Green

    # Ouvrir le rapport dans le navigateur par défaut
    Start-Process $reportPath
}

# Afficher un résumé
Write-Host "`nRésumé des performances:" -ForegroundColor Cyan
foreach ($size in $TestScriptSizes) {
    $sizeResults = $benchmarkResults | Where-Object { $_.ScriptSizeCategory -eq $size }
    Write-Host "  Script de taille $($size):" -ForegroundColor Yellow

    foreach ($result in $sizeResults) {
        if ($result.Success) {
            Write-Host "    $($result.DisplayName): $([math]::Round($result.AverageExecutionTime, 2)) ms" -ForegroundColor Green
        } else {
            Write-Host "    $($result.DisplayName): Échec - $($result.ErrorMessage)" -ForegroundColor Red
        }
    }
}
