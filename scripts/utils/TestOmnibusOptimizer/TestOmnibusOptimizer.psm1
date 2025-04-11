#Requires -Version 5.1

<#
.SYNOPSIS
    Module d'intégration entre TestOmnibus et le Système d'Optimisation Proactive.
.DESCRIPTION
    Ce module combine les fonctionnalités de TestOmnibus et du Système d'Optimisation Proactive
    pour créer une solution complète d'analyse, de test et d'optimisation des scripts PowerShell.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

# Importer les modules requis
$scriptPath = Split-Path -Parent $PSCommandPath
$parentPath = Split-Path -Parent $scriptPath
$usageMonitorPath = Join-Path -Path $parentPath -ChildPath "UsageMonitor\UsageMonitor.psm1"
$testOmnibusPath = Join-Path -Path $parentPath -ChildPath "TestOmnibus\Invoke-TestOmnibus.ps1"

if (Test-Path -Path $usageMonitorPath) {
    Import-Module $usageMonitorPath -Force
} else {
    Write-Error "Module UsageMonitor non trouvé: $usageMonitorPath"
}

# Fonction pour exécuter TestOmnibus avec des paramètres optimisés
function Invoke-OptimizedTestOmnibus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestPath,

        [Parameter(Mandatory = $false)]
        [string]$UsageDataPath = (Join-Path -Path $env:TEMP -ChildPath "UsageMonitor\usage_data.xml"),

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = (Join-Path -Path $env:TEMP -ChildPath "TestOmnibusOptimizer\Reports"),

        [Parameter(Mandatory = $false)]
        [switch]$GenerateCombinedReport
    )

    # Vérifier si TestOmnibus existe
    if (-not (Test-Path -Path $testOmnibusPath)) {
        Write-Error "TestOmnibus non trouvé: $testOmnibusPath"
        return
    }

    # Créer le répertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }

    # Initialiser le moniteur d'utilisation
    Initialize-UsageMonitor -DatabasePath $UsageDataPath

    # Récupérer les statistiques d'utilisation
    $usageStats = Get-ScriptUsageStatistics

    # Calculer le nombre optimal de threads
    $optimalThreads = 4  # Valeur par défaut

    # Si nous avons des données d'utilisation, ajuster le nombre de threads
    if ($usageStats -and $usageStats.TopUsedScripts.Count -gt 0) {
        # Obtenir les informations système
        $computerInfo = Get-CimInstance -ClassName Win32_ComputerSystem
        $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
        $processorInfo = Get-CimInstance -ClassName Win32_Processor

        # Calculer le nombre optimal de threads
        $baseThreads = $computerInfo.NumberOfLogicalProcessors
        $cpuFactor = 1 - ($processorInfo.LoadPercentage / 100)
        $memoryFactor = ($osInfo.FreePhysicalMemory / $osInfo.TotalVisibleMemorySize)

        $optimalThreads = [math]::Max(1, [math]::Round($baseThreads * [math]::Min($cpuFactor, $memoryFactor)))
    }

    # Créer un fichier de configuration temporaire pour TestOmnibus
    $configPath = Join-Path -Path $OutputPath -ChildPath "testomnibus_config.json"
    $config = @{
        MaxThreads             = $optimalThreads
        OutputPath             = Join-Path -Path $OutputPath -ChildPath "TestResults"
        GenerateHtmlReport     = $true
        CollectPerformanceData = $true
    }

    # Si nous avons des données d'utilisation, ajouter des priorités
    if ($usageStats -and $usageStats.TopUsedScripts.Count -gt 0) {
        $priorityScripts = @{}

        # Prioriser les scripts les plus utilisés
        foreach ($scriptPath in $usageStats.TopUsedScripts.Keys) {
            $scriptName = Split-Path -Path $scriptPath -Leaf
            $priorityScripts[$scriptName] = "High"
        }

        # Prioriser les scripts les plus lents
        foreach ($scriptPath in $usageStats.SlowestScripts.Keys) {
            $scriptName = Split-Path -Path $scriptPath -Leaf
            $priorityScripts[$scriptName] = "High"
        }

        # Prioriser les scripts avec le plus d'échecs
        foreach ($scriptPath in $usageStats.MostFailingScripts.Keys) {
            $scriptName = Split-Path -Path $scriptPath -Leaf
            $priorityScripts[$scriptName] = "Critical"
        }

        $config.PriorityScripts = $priorityScripts
    }

    # Sauvegarder la configuration
    $config | ConvertTo-Json -Depth 3 | Out-File -FilePath $configPath -Encoding utf8 -Force

    # Exécuter TestOmnibus avec la configuration optimisée
    Write-Host "Exécution de TestOmnibus avec $optimalThreads threads..." -ForegroundColor Cyan
    & $testOmnibusPath -Path $TestPath -ConfigPath $configPath

    # Générer un rapport combiné si demandé
    if ($GenerateCombinedReport) {
        $testResultsPath = Join-Path -Path $OutputPath -ChildPath "TestResults\report.html"
        $combinedReportPath = Join-Path -Path $OutputPath -ChildPath "combined_report.html"

        if (Test-Path -Path $testResultsPath) {
            Write-Host "Génération du rapport combiné..." -ForegroundColor Cyan
            New-CombinedReport -TestReportPath $testResultsPath -UsageStats $usageStats -OutputPath $combinedReportPath
        } else {
            Write-Warning "Rapport de test non trouvé: $testResultsPath"
        }
    }

    return $config
}

# Fonction pour générer un rapport combiné
function New-CombinedReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestReportPath,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$UsageStats,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    # Lire le rapport de test
    if (-not (Test-Path -Path $TestReportPath)) {
        Write-Error "Rapport de test non trouvé: $TestReportPath"
        return
    }

    $testReport = Get-Content -Path $TestReportPath -Raw

    # Créer la section d'utilisation
    $usageSection = @"
<div class="usage-section">
    <h2>Données d'utilisation réelle</h2>

    <h3>Scripts les plus utilisés</h3>
    <table class="usage-table">
        <tr>
            <th>Script</th>
            <th>Nombre d'exécutions</th>
        </tr>
"@

    foreach ($scriptPath in $UsageStats.TopUsedScripts.Keys) {
        $scriptName = Split-Path -Path $scriptPath -Leaf
        $count = $UsageStats.TopUsedScripts[$scriptPath]

        $usageSection += @"
        <tr>
            <td>$scriptName</td>
            <td>$count</td>
        </tr>
"@
    }

    $usageSection += @"
    </table>

    <h3>Scripts les plus lents</h3>
    <table class="usage-table">
        <tr>
            <th>Script</th>
            <th>Durée moyenne (ms)</th>
        </tr>
"@

    foreach ($scriptPath in $UsageStats.SlowestScripts.Keys) {
        $scriptName = Split-Path -Path $scriptPath -Leaf
        $duration = [math]::Round($UsageStats.SlowestScripts[$scriptPath], 2)

        $usageSection += @"
        <tr>
            <td>$scriptName</td>
            <td>$duration</td>
        </tr>
"@
    }

    $usageSection += @"
    </table>

    <h3>Scripts avec le plus d'échecs</h3>
    <table class="usage-table">
        <tr>
            <th>Script</th>
            <th>Taux d'échec (%)</th>
        </tr>
"@

    foreach ($scriptPath in $UsageStats.MostFailingScripts.Keys) {
        $scriptName = Split-Path -Path $scriptPath -Leaf
        $failRate = [math]::Round($UsageStats.MostFailingScripts[$scriptPath], 2)

        $usageSection += @"
        <tr>
            <td>$scriptName</td>
            <td>$failRate</td>
        </tr>
"@
    }

    $usageSection += @"
    </table>
</div>

<style>
    .usage-section {
        margin-top: 30px;
        padding: 20px;
        background-color: #f8f9fa;
        border-radius: 5px;
        box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
    }

    .usage-table {
        width: 100%;
        border-collapse: collapse;
        margin-bottom: 20px;
    }

    .usage-table th, .usage-table td {
        padding: 10px;
        text-align: left;
        border-bottom: 1px solid #ddd;
    }

    .usage-table th {
        background-color: #f2f2f2;
        font-weight: bold;
    }

    .usage-table tr:hover {
        background-color: #f1f1f1;
    }
</style>
"@

    # Insérer la section d'utilisation avant la fermeture du body
    $combinedReport = $testReport -replace "</body>", "$usageSection</body>"

    # Ajouter un titre combiné
    $combinedReport = $combinedReport -replace "<title>(.*?)</title>", "<title>Rapport Combiné: Tests et Utilisation</title>"

    # Sauvegarder le rapport combiné avec encodage UTF-8 avec BOM
    $utf8WithBom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($OutputPath, $combinedReport, $utf8WithBom)

    Write-Host "Rapport combiné généré: $OutputPath" -ForegroundColor Green
}

# Fonction pour générer des suggestions d'optimisation basées sur les résultats des tests et l'utilisation
function Get-CombinedOptimizationSuggestions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestResultsPath,

        [Parameter(Mandatory = $true)]
        [string]$UsageDataPath,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = (Join-Path -Path $env:TEMP -ChildPath "TestOmnibusOptimizer\Suggestions")
    )

    # Créer le répertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }

    # Initialiser le moniteur d'utilisation
    Initialize-UsageMonitor -DatabasePath $UsageDataPath

    # Récupérer les statistiques d'utilisation
    $usageStats = Get-ScriptUsageStatistics

    # Lire les résultats des tests
    if (-not (Test-Path -Path $TestResultsPath)) {
        Write-Error "Résultats de test non trouvés: $TestResultsPath"
        return
    }

    $testResults = Import-Clixml -Path $TestResultsPath

    # Créer une liste de suggestions
    $suggestions = @()

    # Analyser les scripts échouant à la fois en test et en production
    foreach ($testResult in $testResults) {
        $scriptName = $testResult.Name
        $scriptPath = $testResult.Path

        # Vérifier si le script est dans les statistiques d'utilisation
        $isInUsageStats = $false
        $usagePath = ""

        foreach ($path in $usageStats.MostFailingScripts.Keys) {
            if ((Split-Path -Path $path -Leaf) -eq $scriptName) {
                $isInUsageStats = $true
                $usagePath = $path
                break
            }
        }

        if ($isInUsageStats -and -not $testResult.Success) {
            # Le script échoue à la fois en test et en production
            $suggestion = [PSCustomObject]@{
                ScriptName    = $scriptName
                ScriptPath    = $scriptPath
                Priority      = "Critical"
                Type          = "Reliability"
                TestStatus    = "Failed"
                UsageFailRate = $usageStats.MostFailingScripts[$usagePath]
                Suggestion    = "Ce script echoue a la fois en test et en production. Priorite critique pour la correction."
            }

            $suggestions += $suggestion
        } elseif (-not $testResult.Success) {
            # Le script échoue en test mais pas en production
            $suggestion = [PSCustomObject]@{
                ScriptName    = $scriptName
                ScriptPath    = $scriptPath
                Priority      = "High"
                Type          = "Reliability"
                TestStatus    = "Failed"
                UsageFailRate = "N/A"
                Suggestion    = "Ce script echoue en test. Corriger avant qu'il n'affecte la production."
            }

            $suggestions += $suggestion
        }

        # Analyser les scripts lents
        if ($testResult.Duration -gt 1000) {
            # Plus d'une seconde
            $isSlowInProduction = $false

            foreach ($path in $usageStats.SlowestScripts.Keys) {
                if ((Split-Path -Path $path -Leaf) -eq $scriptName) {
                    $isSlowInProduction = $true
                    $usagePath = $path
                    break
                }
            }

            if ($isSlowInProduction) {
                # Le script est lent à la fois en test et en production
                $suggestion = [PSCustomObject]@{
                    ScriptName    = $scriptName
                    ScriptPath    = $scriptPath
                    Priority      = "High"
                    Type          = "Performance"
                    TestStatus    = "Slow"
                    TestDuration  = $testResult.Duration
                    UsageDuration = $usageStats.SlowestScripts[$usagePath]
                    Suggestion    = "Ce script est lent a la fois en test et en production. Optimiser pour ameliorer les performances."
                }

                $suggestions += $suggestion
            } elseif ($testResult.Duration -gt 2000) {
                # Plus de deux secondes
                # Le script est très lent en test
                $suggestion = [PSCustomObject]@{
                    ScriptName    = $scriptName
                    ScriptPath    = $scriptPath
                    Priority      = "Medium"
                    Type          = "Performance"
                    TestStatus    = "Very Slow"
                    TestDuration  = $testResult.Duration
                    UsageDuration = "N/A"
                    Suggestion    = "Ce script est tres lent en test. Optimiser pour ameliorer les performances des tests."
                }

                $suggestions += $suggestion
            }
        }
    }

    # Analyser les scripts fréquemment utilisés mais non testés
    foreach ($scriptPath in $usageStats.TopUsedScripts.Keys) {
        $scriptName = Split-Path -Path $scriptPath -Leaf

        # Vérifier si le script est dans les résultats de test
        $isInTestResults = $false

        foreach ($testResult in $testResults) {
            if ($testResult.Name -eq $scriptName) {
                $isInTestResults = $true
                break
            }
        }

        # Vérifier si un fichier de test correspondant existe
        $testFileName = "$($scriptName -replace '\.ps1$', '.Tests.ps1')"
        $testFilePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath $testFileName
        $hasTestFile = Test-Path -Path $testFilePath

        # Vérifier si le script est Example-Usage.ps1 et si son test existe dans le répertoire PSCacheManager
        $isExampleUsage = $scriptName -eq "Example-Usage.ps1"
        $exampleUsageTestPath = $null

        if ($isExampleUsage) {
            $psCacheManagerDir = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) -ChildPath "PSCacheManager"
            $exampleUsageTestPath = Join-Path -Path $psCacheManagerDir -ChildPath "Example-Usage.Tests.ps1"
            $hasTestFile = $hasTestFile -or (Test-Path -Path $exampleUsageTestPath)
        }

        if (-not $isInTestResults -and -not $hasTestFile) {
            # Le script est fréquemment utilisé mais non testé
            $suggestion = [PSCustomObject]@{
                ScriptName = $scriptName
                ScriptPath = $scriptPath
                Priority   = "High"
                Type       = "Coverage"
                UsageCount = $usageStats.TopUsedScripts[$scriptPath]
                Suggestion = "Ce script est frequemment utilise mais n'a pas de tests. Ajouter des tests pour assurer sa fiabilite."
            }

            $suggestions += $suggestion
        }
    }

    # Trier les suggestions par priorité
    $sortedSuggestions = $suggestions | Sort-Object -Property Priority, Type

    # Générer un rapport HTML
    $htmlPath = Join-Path -Path $OutputPath -ChildPath "optimization_suggestions.html"

    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Suggestions d&#39;Optimisation</title>
    <style>
        body {
            font-family: 'Segoe UI', Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 0;
            color: #333;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 20px auto;
            background-color: #fff;
            padding: 30px;
            box-shadow: 0 0 20px rgba(0, 0, 0, 0.1);
            border-radius: 8px;
        }
        h1, h2, h3 {
            color: #2c3e50;
            font-weight: 500;
        }
        h2::before {
            content: '';
            display: inline-block;
            width: 18px;
            height: 18px;
            margin-right: 10px;
            border-radius: 50%;
        }
        h2:nth-of-type(1)::before {
            background-color: #e74c3c;
        }
        h2:nth-of-type(2)::before {
            background-color: #f39c12;
        }
        h2:nth-of-type(3)::before {
            background-color: #2ecc71;
        }
        h1 {
            text-align: center;
            padding-bottom: 15px;
            border-bottom: 2px solid #eee;
            margin-bottom: 30px;
            font-size: 28px;
        }
        h2 {
            margin-top: 40px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
            font-size: 22px;
            display: flex;
            align-items: center;
        }
        h2::before {
            content: '';
            display: inline-block;
            width: 18px;
            height: 18px;
            margin-right: 10px;
            border-radius: 50%;
        }
        h2.critical::before {
            background-color: #e74c3c;
        }
        h2.high::before {
            background-color: #f39c12;
        }
        h2.medium::before {
            background-color: #2ecc71;
        }
        .date-info {
            text-align: center;
            color: #7f8c8d;
            margin-bottom: 30px;
            font-style: italic;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 30px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.05);
            border-radius: 5px;
            overflow: hidden;
        }
        th, td {
            padding: 15px;
            text-align: left;
        }
        th {
            background-color: #f8f9fa;
            font-weight: 500;
            color: #2c3e50;
            border-bottom: 2px solid #ddd;
        }
        td {
            border-bottom: 1px solid #eee;
        }
        tr:hover {
            background-color: #f9f9f9;
        }
        .critical {
            border-left: 4px solid #e74c3c;
        }
        .high {
            border-left: 4px solid #f39c12;
        }
        .medium {
            border-left: 4px solid #2ecc71;
        }
        .badge {
            display: inline-block;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: 500;
            color: white;
        }
        .type-reliability {
            background-color: #3498db;
        }
        .type-performance {
            background-color: #9b59b6;
        }
        .type-coverage {
            background-color: #1abc9c;
        }

        .badge-reliability {
            background-color: #3498db;
        }
        .badge-performance {
            background-color: #9b59b6;
        }
        .badge-coverage {
            background-color: #1abc9c;
        }
        .details-box {
            background-color: #f8f9fa;
            padding: 12px 15px;
            border-radius: 5px;
            margin-bottom: 5px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
        }
        .details-item {
            margin-bottom: 8px;
            line-height: 1.4;
        }
        .details-item strong {
            color: #2c3e50;
            margin-right: 5px;
        }
        .suggestion-text {
            line-height: 1.6;
        }
        .charts-container {
            display: flex;
            justify-content: space-between;
            margin-top: 40px;
            flex-wrap: wrap;
        }
        .chart-box {
            width: 48%;
            background-color: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.05);
            margin-bottom: 20px;
        }
        .footer {
            text-align: center;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            color: #7f8c8d;
            font-size: 0.9em;
        }
        @media (max-width: 768px) {
            .chart-box {
                width: 100%;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Suggestions d&#39;Optimisation</h1>
        <div class="date-info">G&#233;n&#233;r&#233; le $(Get-Date -Format "dd/MM/yyyy &#224; HH:mm:ss")</div>

        <h2 class="critical">Suggestions Critiques</h2>
        <table>
            <tr>
                <th>Script</th>
                <th>Type</th>
                <th>D&#233;tails</th>
                <th>Suggestion</th>
            </tr>
"@

    # Ajouter les suggestions critiques
    foreach ($suggestion in ($sortedSuggestions | Where-Object { $_.Priority -eq "Critical" })) {
        $html += @"
            <tr class="critical">
                <td>$($suggestion.ScriptName)</td>
                <td><span class="badge type-$($suggestion.Type.ToLower())">$($suggestion.Type)</span></td>
                <td>
                    <div class="details-box">
"@

        $detailsHtml = ""

        if ($suggestion.TestStatus) {
            $detailsHtml += "<div class='details-item'><strong>Test:</strong> $($suggestion.TestStatus)</div>"
        }

        if ($suggestion.UsageFailRate -and $suggestion.UsageFailRate -ne "N/A") {
            $detailsHtml += "<div class='details-item'><strong>Taux d&#39;&#233;chec:</strong> $($suggestion.UsageFailRate)%</div>"
        }

        if ($suggestion.TestDuration) {
            $detailsHtml += "<div class='details-item'><strong>Dur&#233;e de test:</strong> $($suggestion.TestDuration) ms</div>"
        }

        if ($suggestion.UsageDuration -and $suggestion.UsageDuration -ne "N/A") {
            $detailsHtml += "<div class='details-item'><strong>Dur&#233;e en production:</strong> $($suggestion.UsageDuration) ms</div>"
        }

        if ($suggestion.UsageCount) {
            $detailsHtml += "<div class='details-item'><strong>Nombre d'executions:</strong> $($suggestion.UsageCount)</div>"
        }

        $html += $detailsHtml

        $html += @"
                    </div>
                </td>
                <td class="suggestion-text">$($suggestion.Suggestion)</td>
            </tr>
"@
    }

    $html += @"
        </table>

        <h2>Suggestions Importantes</h2>
        <table>
            <tr>
                <th>Script</th>
                <th>Type</th>
                <th>D&#233;tails</th>
                <th>Suggestion</th>
            </tr>
"@

    # Ajouter les suggestions importantes
    foreach ($suggestion in ($sortedSuggestions | Where-Object { $_.Priority -eq "High" })) {
        $html += @"
            <tr class="high">
                <td>$($suggestion.ScriptName)</td>
                <td>$($suggestion.Type)</td>
                <td>
"@

        if ($suggestion.TestStatus) {
            $html += "Test: $($suggestion.TestStatus)<br>"
        }

        if ($suggestion.UsageFailRate -and $suggestion.UsageFailRate -ne "N/A") {
            $html += "Taux d'echec: $($suggestion.UsageFailRate)%<br>"
        }

        if ($suggestion.TestDuration) {
            $html += "Duree de test: $($suggestion.TestDuration) ms<br>"
        }

        if ($suggestion.UsageDuration -and $suggestion.UsageDuration -ne "N/A") {
            $html += "Duree en production: $($suggestion.UsageDuration) ms<br>"
        }

        if ($suggestion.UsageCount) {
            $html += "Nombre d'executions: $($suggestion.UsageCount)<br>"
        }

        $html += @"
                </td>
                <td>$($suggestion.Suggestion)</td>
            </tr>
"@
    }

    $html += @"
        </table>

        <h2>Suggestions Moyennes</h2>
        <table>
            <tr>
                <th>Script</th>
                <th>Type</th>
                <th>D&#233;tails</th>
                <th>Suggestion</th>
            </tr>
"@

    # Ajouter les suggestions moyennes
    foreach ($suggestion in ($sortedSuggestions | Where-Object { $_.Priority -eq "Medium" })) {
        $html += @"
            <tr class="medium">
                <td>$($suggestion.ScriptName)</td>
                <td>$($suggestion.Type)</td>
                <td>
"@

        if ($suggestion.TestStatus) {
            $html += "Test: $($suggestion.TestStatus)<br>"
        }

        if ($suggestion.UsageFailRate -and $suggestion.UsageFailRate -ne "N/A") {
            $html += "Taux d'echec: $($suggestion.UsageFailRate)%<br>"
        }

        if ($suggestion.TestDuration) {
            $html += "Duree de test: $($suggestion.TestDuration) ms<br>"
        }

        if ($suggestion.UsageDuration -and $suggestion.UsageDuration -ne "N/A") {
            $html += "Duree en production: $($suggestion.UsageDuration) ms<br>"
        }

        if ($suggestion.UsageCount) {
            $html += "Nombre d'executions: $($suggestion.UsageCount)<br>"
        }

        $html += @"
                </td>
                <td>$($suggestion.Suggestion)</td>
            </tr>
"@
    }

    $html += @"
        </table>

        <div class="footer">
            <p>G&#233;n&#233;r&#233; par TestOmnibusOptimizer</p>
        </div>
    </div>
</body>
</html>
"@

    # Sauvegarder le rapport HTML avec encodage UTF-8 avec BOM
    $utf8WithBom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($htmlPath, $html, $utf8WithBom)

    # Générer un rapport CSV
    $csvPath = Join-Path -Path $OutputPath -ChildPath "optimization_suggestions.csv"
    $sortedSuggestions | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

    Write-Host "Suggestions d'optimisation générées:" -ForegroundColor Green
    Write-Host "  - HTML: $htmlPath" -ForegroundColor Green
    Write-Host "  - CSV: $csvPath" -ForegroundColor Green

    return $sortedSuggestions
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Invoke-OptimizedTestOmnibus, New-CombinedReport, Get-CombinedOptimizationSuggestions
