<#
.SYNOPSIS
    Exécute tous les tests et génère un rapport complet pour l'intégration avec Augment Code.

.DESCRIPTION
    Ce script exécute tous les tests unitaires et génère un rapport complet pour l'intégration
    avec Augment Code, incluant les résultats des tests et la couverture de code.

.PARAMETER GenerateCoverage
    Indique si un rapport de couverture de code doit être généré.

.PARAMETER OpenReports
    Indique si les rapports doivent être ouverts automatiquement après leur génération.

.EXAMPLE
    .\Run-Tests.ps1
    # Exécute tous les tests et génère un rapport de résultats

.EXAMPLE
    .\Run-Tests.ps1 -GenerateCoverage
    # Exécute tous les tests et génère un rapport de résultats et de couverture de code

.EXAMPLE
    .\Run-Tests.ps1 -GenerateCoverage -OpenReports
    # Exécute tous les tests, génère un rapport de résultats et de couverture de code, et ouvre les rapports

.NOTES
    Version: 1.0
    Date: 2025-06-01
    Auteur: Augment Agent
#>

[CmdletBinding()]
param (
    [Parameter()]
    [switch]$GenerateCoverage,

    [Parameter()]
    [switch]$OpenReports
)

# Déterminer le chemin du projet
$projectRoot = $PSScriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    if (-not (Test-Path -Path $projectRoot -PathType Container)) {
        Write-Error "Impossible de déterminer le chemin du projet."
        exit 1
    }
}

# Créer le répertoire des rapports s'il n'existe pas
$reportsDir = Join-Path -Path $projectRoot -ChildPath "reports\augment"
if (-not (Test-Path -Path $reportsDir -PathType Container)) {
    New-Item -Path $reportsDir -ItemType Directory -Force | Out-Null
}

# Chemin vers les scripts de test
$testsDir = Join-Path -Path $PSScriptRoot -ChildPath "tests"
$runAllTestsPath = Join-Path -Path $testsDir -ChildPath "Run-AllTests.ps1"
$generateCoverageReportPath = Join-Path -Path $testsDir -ChildPath "Generate-CoverageReport.ps1"

# Vérifier que les scripts de test existent
if (-not (Test-Path -Path $runAllTestsPath)) {
    Write-Error "Script de test introuvable : $runAllTestsPath"
    exit 1
}

if ($GenerateCoverage -and -not (Test-Path -Path $generateCoverageReportPath)) {
    Write-Error "Script de couverture de code introuvable : $generateCoverageReportPath"
    exit 1
}

# Fonction pour convertir les résultats XML en HTML
function Convert-TestResultsToHtml {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$XmlPath,

        [Parameter(Mandatory = $true)]
        [string]$HtmlPath
    )

    if (-not (Test-Path -Path $XmlPath)) {
        Write-Warning "Fichier XML introuvable : $XmlPath"
        return $false
    }

    try {
        # Charger le fichier XML
        [xml]$xml = Get-Content -Path $XmlPath -Encoding UTF8

        # Créer le contenu HTML
        $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de tests - Augment Code</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        .card {
            background-color: #fff;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            padding: 20px;
            margin-bottom: 20px;
        }
        .summary {
            display: flex;
            justify-content: space-between;
            flex-wrap: wrap;
        }
        .summary-item {
            flex: 1;
            min-width: 200px;
            margin: 10px;
            padding: 15px;
            border-radius: 5px;
            text-align: center;
        }
        .success {
            background-color: #d4edda;
            color: #155724;
        }
        .warning {
            background-color: #fff3cd;
            color: #856404;
        }
        .danger {
            background-color: #f8d7da;
            color: #721c24;
        }
        .info {
            background-color: #d1ecf1;
            color: #0c5460;
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
            background-color: #f5f5f5;
        }
        .success-row {
            background-color: #d4edda;
        }
        .failure-row {
            background-color: #f8d7da;
        }
        .details {
            margin-top: 10px;
            padding: 10px;
            background-color: #f8f9fa;
            border-radius: 5px;
            font-family: monospace;
            white-space: pre-wrap;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Rapport de tests - Augment Code</h1>
        <p>Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>

        <div class="card">
            <h2>Résumé</h2>
            <div class="summary">
"@

        # Calculer les statistiques
        $totalTests = $xml.SelectNodes("//test-case").Count
        $passedTests = $xml.SelectNodes("//test-case[@result='Success']").Count
        $failedTests = $xml.SelectNodes("//test-case[@result='Failure']").Count
        $skippedTests = $xml.SelectNodes("//test-case[@result='Skipped']").Count
        $successRate = if ($totalTests -gt 0) { [math]::Round(($passedTests / $totalTests) * 100, 2) } else { 0 }

        # Ajouter les statistiques au HTML
        $html += @"
                <div class="summary-item success">
                    <h3>Tests réussis</h3>
                    <p>$passedTests / $totalTests</p>
                </div>
                <div class="summary-item $(if ($failedTests -eq 0) { "success" } else { "danger" })">
                    <h3>Tests échoués</h3>
                    <p>$failedTests / $totalTests</p>
                </div>
                <div class="summary-item $(if ($skippedTests -eq 0) { "success" } else { "warning" })">
                    <h3>Tests ignorés</h3>
                    <p>$skippedTests / $totalTests</p>
                </div>
                <div class="summary-item $(if ($successRate -ge 80) { "success" } elseif ($successRate -ge 60) { "warning" } else { "danger" })">
                    <h3>Taux de réussite</h3>
                    <p>$successRate%</p>
                </div>
            </div>
        </div>

        <div class="card">
            <h2>Détail des tests</h2>
            <table>
                <thead>
                    <tr>
                        <th>Test</th>
                        <th>Résultat</th>
                        <th>Durée (ms)</th>
                    </tr>
                </thead>
                <tbody>
"@

        # Ajouter les détails des tests au HTML
        foreach ($testCase in $xml.SelectNodes("//test-case")) {
            $name = $testCase.name
            $result = $testCase.result
            $duration = [math]::Round([double]$testCase.time * 1000, 2)
            $rowClass = if ($result -eq "Success") { "success-row" } elseif ($result -eq "Failure") { "failure-row" } else { "" }

            $html += @"
                    <tr class="$rowClass">
                        <td>$name</td>
                        <td>$result</td>
                        <td>$duration</td>
                    </tr>
"@

            # Ajouter les détails de l'échec si le test a échoué
            if ($result -eq "Failure") {
                $message = $testCase.failure.message
                $errorStackTrace = $testCase.failure.'stack-trace'

                $html += @"
                    <tr>
                        <td colspan="3">
                            <div class="details">
                                <strong>Message :</strong> $message
                                <strong>Stack trace :</strong> $errorStackTrace
                            </div>
                        </td>
                    </tr>
"@
            }
        }

        $html += @"
                </tbody>
            </table>
        </div>
    </div>
</body>
</html>
"@

        # Enregistrer le fichier HTML
        $html | Out-File -FilePath $HtmlPath -Encoding UTF8
        return $true
    } catch {
        Write-Warning "Erreur lors de la conversion des résultats de test en HTML : $_"
        return $false
    }
}

# Exécuter les tests
Write-Host "Exécution des tests..." -ForegroundColor Cyan
$testResultsPath = Join-Path -Path $reportsDir -ChildPath "test-results.xml"
& $runAllTestsPath -OutputPath $testResultsPath
$testExitCode = $LASTEXITCODE

# Convertir les résultats des tests en HTML
$testResultsHtmlPath = Join-Path -Path $reportsDir -ChildPath "test-results.html"
$conversionSuccess = Convert-TestResultsToHtml -XmlPath $testResultsPath -HtmlPath $testResultsHtmlPath
if ($conversionSuccess) {
    Write-Host "Rapport HTML des résultats de test généré : $testResultsHtmlPath" -ForegroundColor Green
} else {
    Write-Warning "Échec de la génération du rapport HTML des résultats de test."
}

# Générer le rapport de couverture de code si demandé
if ($GenerateCoverage) {
    Write-Host "`nGénération du rapport de couverture de code..." -ForegroundColor Cyan
    $coveragePath = Join-Path -Path $reportsDir -ChildPath "coverage"
    & $generateCoverageReportPath -OutputPath $coveragePath
    $coverageExitCode = $LASTEXITCODE

    if ($coverageExitCode -eq 0) {
        Write-Host "Rapport de couverture de code généré : $coveragePath" -ForegroundColor Green
    } else {
        Write-Warning "Échec de la génération du rapport de couverture de code."
    }
}

# Ouvrir les rapports si demandé
if ($OpenReports) {
    if ($conversionSuccess) {
        Write-Host "`nOuverture du rapport des résultats de test..." -ForegroundColor Cyan
        Start-Process $testResultsHtmlPath
    }

    if ($GenerateCoverage -and $coverageExitCode -eq 0) {
        $coverageHtmlPath = Join-Path -Path $coveragePath -ChildPath "index.html"
        if (Test-Path -Path $coverageHtmlPath) {
            Write-Host "Ouverture du rapport de couverture de code..." -ForegroundColor Cyan
            Start-Process $coverageHtmlPath
        }
    }
}

# Afficher un résumé
Write-Host "`nRésumé de l'exécution des tests :" -ForegroundColor Cyan
if ($testExitCode -eq 0) {
    Write-Host "Tous les tests ont réussi." -ForegroundColor Green
} else {
    Write-Host "$testExitCode tests ont échoué." -ForegroundColor Red
}

# Afficher la liste des tests exécutés
Write-Host "`nTests exécutés :" -ForegroundColor Cyan
$testFiles | ForEach-Object {
    $name = (Split-Path -Path $_ -Leaf) -replace "Test-", "" -replace ".ps1", ""
    Write-Host "- $name" -ForegroundColor Gray
}

# Afficher des conseils pour exécuter des tests spécifiques
Write-Host "`nPour exécuter un test spécifique, utilisez :" -ForegroundColor Yellow
Write-Host "Invoke-Pester -Path `"development\scripts\maintenance\augment\tests\Test-<NomDuTest>.ps1`"" -ForegroundColor Yellow

# Retourner le code de sortie
exit $testExitCode
