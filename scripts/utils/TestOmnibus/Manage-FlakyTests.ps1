<#
.SYNOPSIS
    Détecte et gère les tests instables (flaky).
.DESCRIPTION
    Ce script détecte les tests instables (flaky) en exécutant les tests plusieurs fois
    et en analysant les résultats. Il peut également générer un rapport sur les tests
    instables et proposer des solutions pour les stabiliser.
.PARAMETER TestPath
    Chemin vers les tests à exécuter.
.PARAMETER OutputPath
    Chemin où enregistrer les résultats de l'analyse.
.PARAMETER Iterations
    Nombre d'itérations à exécuter pour détecter les tests instables.
.PARAMETER GenerateReport
    Génère un rapport HTML des résultats de l'analyse.
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

# Vérifier que le chemin des tests existe
if (-not (Test-Path -Path $TestPath)) {
    Write-Error "Le chemin des tests n'existe pas: $TestPath"
    return 1
}

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Fonction pour exécuter les tests et collecter les résultats
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

        # Exécuter TestOmnibus
        Write-Host "Exécution de l'itération $Iteration..." -ForegroundColor Cyan

        $testOmnibusParams = @{
            Path = $TestPath
        }

        # Exécuter TestOmnibus et ignorer la sortie directe
        & $testOmnibusPath @testOmnibusParams | Out-Null

        # Vérifier si des résultats ont été générés
        $resultsPath = Join-Path -Path (Join-Path -Path $env:TEMP -ChildPath "TestOmnibus\Results") -ChildPath "results.xml"
        if (-not (Test-Path -Path $resultsPath)) {
            Write-Error "Aucun résultat n'a été généré par TestOmnibus."
            return $null
        }

        # Charger les résultats
        $results = Import-Clixml -Path $resultsPath

        # Ajouter l'itération aux résultats
        foreach ($testResult in $results) {
            $testResult | Add-Member -MemberType NoteProperty -Name "Iteration" -Value $Iteration
        }

        return $results
    } catch {
        Write-Error "Erreur lors de l'execution de l'iteration ${Iteration}: $_"
        return $null
    }
}

# Fonction pour analyser les résultats et détecter les tests instables
function Get-FlakyTests {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$AllResults
    )

    try {
        # Regrouper les résultats par test
        $testGroups = $AllResults | Group-Object -Property Name

        # Analyser chaque groupe pour détecter les tests instables
        $flakyTests = @()

        foreach ($group in $testGroups) {
            $testName = $group.Name
            $testResults = $group.Group

            # Calculer le taux de réussite
            $successCount = ($testResults | Where-Object { $_.Success } | Measure-Object).Count
            $successRate = $successCount / $testResults.Count

            # Vérifier si le test est instable
            $isFlaky = $successRate -gt 0 -and $successRate -lt 1

            if ($isFlaky) {
                # Créer un objet pour le test instable
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
        Write-Error "Erreur lors de l'analyse des résultats: $_"
        return @()
    }
}

# Fonction pour générer un rapport HTML des tests instables
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
        # Créer le chemin du rapport
        $reportPath = Join-Path -Path $OutputPath -ChildPath "flaky_tests_report.html"

        # Calculer des statistiques globales
        $totalTests = ($AllResults | Group-Object -Property Name).Count
        $totalFlakyTests = $FlakyTests.Count
        $flakyTestsPercent = if ($totalTests -gt 0) { [math]::Round(($totalFlakyTests / $totalTests) * 100, 2) } else { 0 }

        # Générer le contenu HTML
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
        <p>Généré le $(Get-Date -Format "dd/MM/yyyy à HH:mm:ss")</p>

        <div class="flaky-summary">
            <div class="flaky-item">
                <h3>Tests instables</h3>
                <div class="flaky-value $((if ($flakyTestsPercent -lt 5) { "flaky-good" } elseif ($flakyTestsPercent -lt 15) { "flaky-warning" } else { "flaky-bad" }))">
                    $totalFlakyTests
                </div>
                <p>sur $totalTests tests ($flakyTestsPercent%)</p>
            </div>
            <div class="flaky-item">
                <h3>Itérations</h3>
                <div class="flaky-value flaky-neutral">
                    $Iterations
                </div>
                <p>exécutions par test</p>
            </div>
        </div>

        <div class="chart-container">
            <canvas id="flakyTestsChart"></canvas>
        </div>
"@

        if ($FlakyTests.Count -gt 0) {
            $htmlReport += @"
        <h2>Tests instables détectés</h2>
        <table>
            <tr>
                <th>Test</th>
                <th>Taux de réussite</th>
                <th>Réussites / Échecs</th>
                <th>Itérations en échec</th>
                <th>Recommandation</th>
            </tr>
"@

            foreach ($test in ($FlakyTests | Sort-Object -Property SuccessRate)) {
                $successRatePercent = [math]::Round($test.SuccessRate * 100, 2)
                $failureIterations = $test.FailureIterations -join ", "

                # Déterminer la recommandation
                $recommendation = if ($test.SuccessRate -ge 0.8) {
                    "Retry: Ce test réussit la plupart du temps, il est recommandé d'utiliser une stratégie de nouvelle tentative."
                } elseif ($test.SuccessRate -ge 0.5) {
                    "Quarantine: Ce test est modérément instable, il est recommandé de le mettre en quarantaine et d'investiguer."
                } else {
                    "Skip: Ce test échoue souvent, il est recommandé de le désactiver temporairement et de le refactoriser."
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

            # Ajouter les détails des erreurs pour chaque test instable
            $htmlReport += @"
        <h2>Détails des erreurs</h2>
"@

            foreach ($test in $FlakyTests) {
                $htmlReport += @"
        <h3>$($test.Name)</h3>
        <p>Taux de réussite: $([math]::Round($test.SuccessRate * 100, 2))% ($($test.SuccessCount) / $($test.TotalCount))</p>
        <p>Itérations en échec: $($test.FailureIterations -join ", ")</p>
        <h4>Messages d'erreur:</h4>
"@

                foreach ($errorMessage in $test.ErrorMessages) {
                    $htmlReport += @"
        <div class="error-message">$errorMessage</div>
"@
                }

                # Ajouter des recommandations spécifiques
                $htmlReport += @"
        <h4>Recommandations:</h4>
        <div class="recommendation">
"@

                if ($test.SuccessRate -ge 0.8) {
                    $htmlReport += @"
            <p><strong>Stratégie recommandée: Retry</strong></p>
            <p>Ce test réussit la plupart du temps ($([math]::Round($test.SuccessRate * 100, 2))%), ce qui suggère qu'il est affecté par des conditions temporaires. Considérez les actions suivantes:</p>
            <ul>
                <li>Configurez le test pour qu'il soit réexécuté automatiquement en cas d'échec (jusqu'à $MaxRetries fois).</li>
                <li>Ajoutez des délais d'attente plus longs pour les opérations asynchrones.</li>
                <li>Vérifiez si le test dépend de ressources externes qui peuvent être temporairement indisponibles.</li>
                <li>Assurez-vous que l'état initial est correctement réinitialisé entre les exécutions.</li>
            </ul>
"@
                } elseif ($test.SuccessRate -ge 0.5) {
                    $htmlReport += @"
            <p><strong>Stratégie recommandée: Quarantine</strong></p>
            <p>Ce test est modérément instable ($([math]::Round($test.SuccessRate * 100, 2))% de réussite), ce qui suggère des problèmes plus profonds. Considérez les actions suivantes:</p>
            <ul>
                <li>Mettez le test en quarantaine pour qu'il n'affecte pas les builds de production.</li>
                <li>Analysez les conditions qui font échouer le test.</li>
                <li>Vérifiez les dépendances entre les tests qui pourraient causer des interférences.</li>
                <li>Recherchez les conditions de concurrence ou les problèmes de synchronisation.</li>
                <li>Refactorisez le test pour le rendre plus déterministe.</li>
            </ul>
"@
                } else {
                    $htmlReport += @"
            <p><strong>Stratégie recommandée: Skip</strong></p>
            <p>Ce test échoue souvent ($([math]::Round((1 - $test.SuccessRate) * 100, 2))% d'échecs), ce qui suggère des problèmes fondamentaux. Considérez les actions suivantes:</p>
            <ul>
                <li>Désactivez temporairement le test pour qu'il n'affecte pas les builds.</li>
                <li>Réécrivez complètement le test en utilisant une approche différente.</li>
                <li>Vérifiez si le test est toujours pertinent ou s'il teste des fonctionnalités obsolètes.</li>
                <li>Divisez le test en plusieurs tests plus petits et plus ciblés.</li>
                <li>Utilisez des mocks pour isoler le test des dépendances externes.</li>
            </ul>
"@
                }

                $htmlReport += @"
        </div>
"@
            }
        } else {
            $htmlReport += @"
        <h2>Aucun test instable détecté</h2>
        <p>Félicitations! Aucun test instable n'a été détecté après $Iterations itérations.</p>
"@
        }

        $htmlReport += @"
        <script>
            // Créer un graphique des tests instables
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
                            text: 'Répartition des tests'
                        }
                    }
                }
            });
        </script>

        <div class="footer">
            <p>Généré par TestOmnibus Flaky Test Manager</p>
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
        Write-Error "Erreur lors de la génération du rapport des tests instables: $_"
        return $null
    }
}

# Fonction pour créer un fichier de configuration pour les tests instables
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
        # Créer le chemin du fichier de configuration
        $configPath = Join-Path -Path $OutputPath -ChildPath "flaky_tests_config.json"

        # Créer la configuration
        $config = @{
            FlakyTests  = @{}
            FixMode     = $FixMode
            MaxRetries  = $MaxRetries
            GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }

        # Ajouter les tests instables à la configuration
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
        Write-Error "Erreur lors de la création du fichier de configuration pour les tests instables: $_"
        return $null
    }
}

# Point d'entrée principal
try {
    # Exécuter les tests plusieurs fois
    Write-Host "Exécution des tests $Iterations fois pour détecter les tests instables..." -ForegroundColor Cyan

    $allResults = @()

    for ($i = 1; $i -le $Iterations; $i++) {
        $iterationResults = Invoke-TestIteration -TestPath $TestPath -Iteration $i

        if ($iterationResults) {
            $allResults += $iterationResults

            # Afficher un résumé de l'itération
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

    # Retourner les résultats
    return [PSCustomObject]@{
        FlakyTests = $flakyTests
        AllResults = $allResults
        ReportPath = if ($GenerateReport) { $reportPath } else { $null }
        ConfigPath = if ($flakyTests.Count -gt 0) { $configPath } else { $null }
    }
} catch {
    Write-Error "Erreur lors de la détection des tests instables: $_"
    return 1
}
