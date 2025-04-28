<#
.SYNOPSIS
    DÃ©tecte et gÃ¨re les tests instables (flaky).
.DESCRIPTION
    Ce script dÃ©tecte les tests instables (flaky) en exÃ©cutant les tests plusieurs fois
    et en analysant les rÃ©sultats. Il peut Ã©galement gÃ©nÃ©rer un rapport sur les tests
    instables et proposer des solutions pour les stabiliser.
.PARAMETER TestPath
    Chemin vers les tests Ã  exÃ©cuter.
.PARAMETER OutputPath
    Chemin oÃ¹ enregistrer les rÃ©sultats de l'analyse.
.PARAMETER Iterations
    Nombre d'itÃ©rations Ã  exÃ©cuter pour dÃ©tecter les tests instables.
.PARAMETER GenerateReport
    GÃ©nÃ¨re un rapport HTML des rÃ©sultats de l'analyse.
.PARAMETER FixMode
    Mode de correction des tests instables (None, Quarantine, Retry, Skip).
.PARAMETER MaxRetries
    Nombre maximum de tentatives pour les tests instables en mode Retry.
.EXAMPLE
    .\Manage-FlakyTests.ps1 -TestPath "D:\Tests" -Iterations 5 -GenerateReport
.EXAMPLE
    .\Manage-FlakyTests.ps1 -TestPath "D:\Tests" -Iterations 10 -FixMode Retry -MaxRetries 3
.NOTES
    Auteur: Augment Agent
    Date: 2025-04-12
    Version: 1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$TestPath,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $env:TEMP -ChildPath "TestOmnibus\FlakyTests"),

    [Parameter(Mandatory = $false)]
    [int]$Iterations = 5,

    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport,

    [Parameter(Mandatory = $false)]
    [ValidateSet("None", "Quarantine", "Retry", "Skip")]
    [string]$FixMode = "None",

    [Parameter(Mandatory = $false)]
    [int]$MaxRetries = 3
)

# VÃ©rifier que le chemin des tests existe
if (-not (Test-Path -Path $TestPath)) {
    Write-Error "Le chemin des tests n'existe pas: $TestPath"
    return 1
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Fonction pour exÃ©cuter les tests et collecter les rÃ©sultats
function Invoke-TestIteration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestPath,

        [Parameter(Mandatory = $true)]
        [int]$Iteration
    )

    try {
        # Chemin vers TestOmnibus
        $testOmnibusPath = Join-Path -Path $PSScriptRoot -ChildPath "Invoke-TestOmnibus.ps1"

        if (-not (Test-Path -Path $testOmnibusPath)) {
            Write-Error "TestOmnibus n'existe pas: $testOmnibusPath"
            return $null
        }

        # ExÃ©cuter TestOmnibus
        Write-Host "ExÃ©cution de l'itÃ©ration $Iteration..." -ForegroundColor Cyan

        $testOmnibusParams = @{
            Path = $TestPath
        }

        # ExÃ©cuter TestOmnibus et ignorer la sortie directe
        & $testOmnibusPath @testOmnibusParams | Out-Null

        # VÃ©rifier si des rÃ©sultats ont Ã©tÃ© gÃ©nÃ©rÃ©s
        $resultsPath = Join-Path -Path (Join-Path -Path $env:TEMP -ChildPath "TestOmnibus\Results") -ChildPath "results.xml"
        if (-not (Test-Path -Path $resultsPath)) {
            Write-Error "Aucun rÃ©sultat n'a Ã©tÃ© gÃ©nÃ©rÃ© par TestOmnibus."
            return $null
        }

        # Charger les rÃ©sultats
        $results = Import-Clixml -Path $resultsPath

        # Ajouter l'itÃ©ration aux rÃ©sultats
        foreach ($testResult in $results) {
            $testResult | Add-Member -MemberType NoteProperty -Name "Iteration" -Value $Iteration
        }

        return $results
    } catch {
        Write-Error "Erreur lors de l'execution de l'iteration ${Iteration}: $_"
        return $null
    }
}

# Fonction pour analyser les rÃ©sultats et dÃ©tecter les tests instables
function Get-FlakyTests {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$AllResults
    )

    try {
        # Regrouper les rÃ©sultats par test
        $testGroups = $AllResults | Group-Object -Property Name

        # Analyser chaque groupe pour dÃ©tecter les tests instables
        $flakyTests = @()

        foreach ($group in $testGroups) {
            $testName = $group.Name
            $testResults = $group.Group

            # Calculer le taux de rÃ©ussite
            $successCount = ($testResults | Where-Object { $_.Success } | Measure-Object).Count
            $successRate = $successCount / $testResults.Count

            # VÃ©rifier si le test est instable
            $isFlaky = $successRate -gt 0 -and $successRate -lt 1

            if ($isFlaky) {
                # CrÃ©er un objet pour le test instable
                $flakyTest = [PSCustomObject]@{
                    Name              = $testName
                    SuccessRate       = $successRate
                    SuccessCount      = $successCount
                    FailureCount      = $testResults.Count - $successCount
                    TotalCount        = $testResults.Count
                    Results           = $testResults
                    SuccessIterations = ($testResults | Where-Object { $_.Success } | Select-Object -ExpandProperty Iteration)
                    FailureIterations = ($testResults | Where-Object { -not $_.Success } | Select-Object -ExpandProperty Iteration)
                    ErrorMessages     = ($testResults | Where-Object { -not $_.Success } | Select-Object -ExpandProperty ErrorMessage -Unique)
                }

                $flakyTests += $flakyTest
            }
        }

        return $flakyTests
    } catch {
        Write-Error "Erreur lors de l'analyse des rÃ©sultats: $_"
        return @()
    }
}

# Fonction pour gÃ©nÃ©rer un rapport HTML des tests instables
function New-FlakyTestReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$FlakyTests,

        [Parameter(Mandatory = $true)]
        [array]$AllResults,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $true)]
        [int]$Iterations
    )

    try {
        # CrÃ©er le chemin du rapport
        $reportPath = Join-Path -Path $OutputPath -ChildPath "flaky_tests_report.html"

        # Calculer des statistiques globales
        $totalTests = ($AllResults | Group-Object -Property Name).Count
        $totalFlakyTests = $FlakyTests.Count
        $flakyTestsPercent = if ($totalTests -gt 0) { [math]::Round(($totalFlakyTests / $totalTests) * 100, 2) } else { 0 }

        # GÃ©nÃ©rer le contenu HTML
        $htmlReport = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport des tests instables (flaky)</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: #fff;
            padding: 20px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
            border-radius: 5px;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        h1 {
            text-align: center;
            padding-bottom: 10px;
            border-bottom: 2px solid #eee;
        }
        h2 {
            margin-top: 30px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f8f9fa;
            font-weight: bold;
        }
        tr:hover {
            background-color: #f1f1f1;
        }
        .success {
            color: #2ecc71;
        }
        .failure {
            color: #e74c3c;
        }
        .warning {
            color: #f39c12;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 10px;
            border-top: 1px solid #eee;
            color: #7f8c8d;
            font-size: 0.9em;
        }
        .chart-container {
            width: 100%;
            height: 300px;
            margin-bottom: 20px;
        }
        .flaky-summary {
            display: flex;
            justify-content: space-between;
            margin-bottom: 20px;
        }
        .flaky-item {
            flex: 1;
            text-align: center;
            padding: 15px;
            background-color: #f8f9fa;
            border-radius: 5px;
            margin: 0 5px;
        }
        .flaky-item h3 {
            margin-top: 0;
        }
        .flaky-value {
            font-size: 2em;
            font-weight: bold;
        }
        .flaky-good {
            color: #2ecc71;
        }
        .flaky-warning {
            color: #f39c12;
        }
        .flaky-bad {
            color: #e74c3c;
        }
        .progress {
            height: 20px;
            background-color: #f1f1f1;
            border-radius: 5px;
            overflow: hidden;
            margin-bottom: 10px;
        }
        .progress-bar {
            height: 100%;
            color: white;
            text-align: center;
            line-height: 20px;
        }
        .progress-bar-success {
            background-color: #2ecc71;
        }
        .progress-bar-warning {
            background-color: #f39c12;
        }
        .progress-bar-danger {
            background-color: #e74c3c;
        }
        .error-message {
            background-color: #f8d7da;
            color: #721c24;
            padding: 10px;
            border-radius: 5px;
            margin-bottom: 10px;
            font-family: monospace;
            white-space: pre-wrap;
        }
        .recommendation {
            background-color: #d1ecf1;
            color: #0c5460;
            padding: 10px;
            border-radius: 5px;
            margin-bottom: 10px;
        }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <div class="container">
        <h1>Rapport des tests instables (flaky)</h1>
        <p>GÃ©nÃ©rÃ© le $(Get-Date -Format "dd/MM/yyyy Ã  HH:mm:ss")</p>

        <div class="flaky-summary">
            <div class="flaky-item">
                <h3>Tests instables</h3>
                <div class="flaky-value $((if ($flakyTestsPercent -lt 5) { "flaky-good" } elseif ($flakyTestsPercent -lt 15) { "flaky-warning" } else { "flaky-bad" }))">
                    $totalFlakyTests
                </div>
                <p>sur $totalTests tests ($flakyTestsPercent%)</p>
            </div>
            <div class="flaky-item">
                <h3>ItÃ©rations</h3>
                <div class="flaky-value flaky-neutral">
                    $Iterations
                </div>
                <p>exÃ©cutions par test</p>
            </div>
        </div>

        <div class="chart-container">
            <canvas id="flakyTestsChart"></canvas>
        </div>
"@

        if ($FlakyTests.Count -gt 0) {
            $htmlReport += @"
        <h2>Tests instables dÃ©tectÃ©s</h2>
        <table>
            <tr>
                <th>Test</th>
                <th>Taux de rÃ©ussite</th>
                <th>RÃ©ussites / Ã‰checs</th>
                <th>ItÃ©rations en Ã©chec</th>
                <th>Recommandation</th>
            </tr>
"@

            foreach ($test in ($FlakyTests | Sort-Object -Property SuccessRate)) {
                $successRatePercent = [math]::Round($test.SuccessRate * 100, 2)
                $failureIterations = $test.FailureIterations -join ", "

                # DÃ©terminer la recommandation
                $recommendation = if ($test.SuccessRate -ge 0.8) {
                    "Retry: Ce test rÃ©ussit la plupart du temps, il est recommandÃ© d'utiliser une stratÃ©gie de nouvelle tentative."
                } elseif ($test.SuccessRate -ge 0.5) {
                    "Quarantine: Ce test est modÃ©rÃ©ment instable, il est recommandÃ© de le mettre en quarantaine et d'investiguer."
                } else {
                    "Skip: Ce test Ã©choue souvent, il est recommandÃ© de le dÃ©sactiver temporairement et de le refactoriser."
                }

                $htmlReport += @"
            <tr>
                <td>$($test.Name)</td>
                <td>
                    <div class="progress">
                        <div class="progress-bar $((if ($successRatePercent -ge 80) { "progress-bar-success" } elseif ($successRatePercent -ge 50) { "progress-bar-warning" } else { "progress-bar-danger" }))" style="width: $successRatePercent%">
                            $successRatePercent%
                        </div>
                    </div>
                </td>
                <td>$($test.SuccessCount) / $($test.FailureCount)</td>
                <td>$failureIterations</td>
                <td>$recommendation</td>
            </tr>
"@
            }

            $htmlReport += @"
        </table>
"@

            # Ajouter les dÃ©tails des erreurs pour chaque test instable
            $htmlReport += @"
        <h2>DÃ©tails des erreurs</h2>
"@

            foreach ($test in $FlakyTests) {
                $htmlReport += @"
        <h3>$($test.Name)</h3>
        <p>Taux de rÃ©ussite: $([math]::Round($test.SuccessRate * 100, 2))% ($($test.SuccessCount) / $($test.TotalCount))</p>
        <p>ItÃ©rations en Ã©chec: $($test.FailureIterations -join ", ")</p>
        <h4>Messages d'erreur:</h4>
"@

                foreach ($errorMessage in $test.ErrorMessages) {
                    $htmlReport += @"
        <div class="error-message">$errorMessage</div>
"@
                }

                # Ajouter des recommandations spÃ©cifiques
                $htmlReport += @"
        <h4>Recommandations:</h4>
        <div class="recommendation">
"@

                if ($test.SuccessRate -ge 0.8) {
                    $htmlReport += @"
            <p><strong>StratÃ©gie recommandÃ©e: Retry</strong></p>
            <p>Ce test rÃ©ussit la plupart du temps ($([math]::Round($test.SuccessRate * 100, 2))%), ce qui suggÃ¨re qu'il est affectÃ© par des conditions temporaires. ConsidÃ©rez les actions suivantes:</p>
            <ul>
                <li>Configurez le test pour qu'il soit rÃ©exÃ©cutÃ© automatiquement en cas d'Ã©chec (jusqu'Ã  $MaxRetries fois).</li>
                <li>Ajoutez des dÃ©lais d'attente plus longs pour les opÃ©rations asynchrones.</li>
                <li>VÃ©rifiez si le test dÃ©pend de ressources externes qui peuvent Ãªtre temporairement indisponibles.</li>
                <li>Assurez-vous que l'Ã©tat initial est correctement rÃ©initialisÃ© entre les exÃ©cutions.</li>
            </ul>
"@
                } elseif ($test.SuccessRate -ge 0.5) {
                    $htmlReport += @"
            <p><strong>StratÃ©gie recommandÃ©e: Quarantine</strong></p>
            <p>Ce test est modÃ©rÃ©ment instable ($([math]::Round($test.SuccessRate * 100, 2))% de rÃ©ussite), ce qui suggÃ¨re des problÃ¨mes plus profonds. ConsidÃ©rez les actions suivantes:</p>
            <ul>
                <li>Mettez le test en quarantaine pour qu'il n'affecte pas les builds de production.</li>
                <li>Analysez les conditions qui font Ã©chouer le test.</li>
                <li>VÃ©rifiez les dÃ©pendances entre les tests qui pourraient causer des interfÃ©rences.</li>
                <li>Recherchez les conditions de concurrence ou les problÃ¨mes de synchronisation.</li>
                <li>Refactorisez le test pour le rendre plus dÃ©terministe.</li>
            </ul>
"@
                } else {
                    $htmlReport += @"
            <p><strong>StratÃ©gie recommandÃ©e: Skip</strong></p>
            <p>Ce test Ã©choue souvent ($([math]::Round((1 - $test.SuccessRate) * 100, 2))% d'Ã©checs), ce qui suggÃ¨re des problÃ¨mes fondamentaux. ConsidÃ©rez les actions suivantes:</p>
            <ul>
                <li>DÃ©sactivez temporairement le test pour qu'il n'affecte pas les builds.</li>
                <li>RÃ©Ã©crivez complÃ¨tement le test en utilisant une approche diffÃ©rente.</li>
                <li>VÃ©rifiez si le test est toujours pertinent ou s'il teste des fonctionnalitÃ©s obsolÃ¨tes.</li>
                <li>Divisez le test en plusieurs tests plus petits et plus ciblÃ©s.</li>
                <li>Utilisez des mocks pour isoler le test des dÃ©pendances externes.</li>
            </ul>
"@
                }

                $htmlReport += @"
        </div>
"@
            }
        } else {
            $htmlReport += @"
        <h2>Aucun test instable dÃ©tectÃ©</h2>
        <p>FÃ©licitations! Aucun test instable n'a Ã©tÃ© dÃ©tectÃ© aprÃ¨s $Iterations itÃ©rations.</p>
"@
        }

        $htmlReport += @"
        <script>
            // CrÃ©er un graphique des tests instables
            const ctx = document.getElementById('flakyTestsChart').getContext('2d');
            const flakyTestsChart = new Chart(ctx, {
                type: 'pie',
                data: {
                    labels: ['Tests stables', 'Tests instables'],
                    datasets: [{
                        label: 'Tests',
                        data: [$($totalTests - $totalFlakyTests), $totalFlakyTests],
                        backgroundColor: [
                            '#2ecc71',
                            '#e74c3c'
                        ],
                        borderColor: [
                            '#27ae60',
                            '#c0392b'
                        ],
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    plugins: {
                        legend: {
                            position: 'top',
                        },
                        title: {
                            display: true,
                            text: 'RÃ©partition des tests'
                        }
                    }
                }
            });
        </script>

        <div class="footer">
            <p>GÃ©nÃ©rÃ© par TestOmnibus Flaky Test Manager</p>
        </div>
    </div>
</body>
</html>
"@

        # Enregistrer le rapport HTML
        $utf8WithBom = New-Object System.Text.UTF8Encoding($true)
        [System.IO.File]::WriteAllText($reportPath, $htmlReport, $utf8WithBom)

        return $reportPath
    } catch {
        Write-Error "Erreur lors de la gÃ©nÃ©ration du rapport des tests instables: $_"
        return $null
    }
}

# Fonction pour crÃ©er un fichier de configuration pour les tests instables
function New-FlakyTestConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$FlakyTests,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $true)]
        [string]$FixMode,

        [Parameter(Mandatory = $true)]
        [int]$MaxRetries
    )

    try {
        # CrÃ©er le chemin du fichier de configuration
        $configPath = Join-Path -Path $OutputPath -ChildPath "flaky_tests_config.json"

        # CrÃ©er la configuration
        $config = @{
            FlakyTests  = @{}
            FixMode     = $FixMode
            MaxRetries  = $MaxRetries
            GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }

        # Ajouter les tests instables Ã  la configuration
        foreach ($test in $FlakyTests) {
            $config.FlakyTests[$test.Name] = @{
                SuccessRate        = $test.SuccessRate
                SuccessCount       = $test.SuccessCount
                FailureCount       = $test.FailureCount
                TotalCount         = $test.TotalCount
                RecommendedFixMode = if ($test.SuccessRate -ge 0.8) {
                    "Retry"
                } elseif ($test.SuccessRate -ge 0.5) {
                    "Quarantine"
                } else {
                    "Skip"
                }
            }
        }

        # Enregistrer la configuration
        $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding utf8 -Force

        return $configPath
    } catch {
        Write-Error "Erreur lors de la crÃ©ation du fichier de configuration pour les tests instables: $_"
        return $null
    }
}

# Point d'entrÃ©e principal
try {
    # ExÃ©cuter les tests plusieurs fois
    Write-Host "ExÃ©cution des tests $Iterations fois pour dÃ©tecter les tests instables..." -ForegroundColor Cyan

    $allResults = @()

    for ($i = 1; $i -le $Iterations; $i++) {
        $iterationResults = Invoke-TestIteration -TestPath $TestPath -Iteration $i

        if ($iterationResults) {
            $allResults += $iterationResults

            # Afficher un rÃ©sumÃ© de l'itÃ©ration
            $passedCount = ($iterationResults | Where-Object { $_.Success } | Measure-Object).Count
            $failedCount = ($iterationResults | Where-Object { -not $_.Success } | Measure-Object).Count
            $totalCount = $iterationResults.Count

            Write-Host "Iteration ${i}: ${passedCount} reussis, ${failedCount} echoues sur ${totalCount} tests" -ForegroundColor Cyan
        } else {
            Write-Warning "L'iteration ${i} n'a pas produit de resultats."
        }
    }

    # Analyser les resultats pour detecter les tests instables
    Write-Host "Analyse des resultats pour detecter les tests instables..." -ForegroundColor Cyan
    $flakyTests = Get-FlakyTests -AllResults $allResults

    # Afficher les tests instables detectes
    if ($flakyTests.Count -gt 0) {
        Write-Host "Tests instables detectes: $($flakyTests.Count)" -ForegroundColor Yellow

        foreach ($test in $flakyTests) {
            Write-Host "  - $($test.Name) (taux de reussite: $([math]::Round($test.SuccessRate * 100, 2))%)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Aucun test instable detecte." -ForegroundColor Green
    }

    # Generer un rapport si demande
    if ($GenerateReport) {
        Write-Host "Generation du rapport des tests instables..." -ForegroundColor Cyan
        if ($flakyTests -and $flakyTests.Count -gt 0) {
            $reportPath = New-FlakyTestReport -FlakyTests $flakyTests -AllResults $allResults -OutputPath $OutputPath -Iterations $Iterations

            if ($reportPath) {
                Write-Host "Rapport des tests instables genere: $reportPath" -ForegroundColor Green
            }
        } else {
            Write-Host "Aucun test instable detecte, pas de rapport genere." -ForegroundColor Green
        }
    }

    # Creer un fichier de configuration pour les tests instables
    if ($flakyTests.Count -gt 0) {
        Write-Host "Creation du fichier de configuration pour les tests instables..." -ForegroundColor Cyan
        $configPath = New-FlakyTestConfig -FlakyTests $flakyTests -OutputPath $OutputPath -FixMode $FixMode -MaxRetries $MaxRetries

        if ($configPath) {
            Write-Host "Fichier de configuration pour les tests instables cree: $configPath" -ForegroundColor Green
        }
    }

    # Retourner les rÃ©sultats
    return [PSCustomObject]@{
        FlakyTests = $flakyTests
        AllResults = $allResults
        ReportPath = if ($GenerateReport) { $reportPath } else { $null }
        ConfigPath = if ($flakyTests.Count -gt 0) { $configPath } else { $null }
    }
} catch {
    Write-Error "Erreur lors de la dÃ©tection des tests instables: $_"
    return 1
}
