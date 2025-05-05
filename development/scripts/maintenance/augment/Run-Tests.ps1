<#
.SYNOPSIS
    ExÃ©cute tous les tests et gÃ©nÃ¨re un rapport complet pour l'intÃ©gration avec Augment Code.

.DESCRIPTION
    Ce script exÃ©cute tous les tests unitaires et gÃ©nÃ¨re un rapport complet pour l'intÃ©gration
    avec Augment Code, incluant les rÃ©sultats des tests et la couverture de code.

.PARAMETER GenerateCoverage
    Indique si un rapport de couverture de code doit Ãªtre gÃ©nÃ©rÃ©.

.PARAMETER OpenReports
    Indique si les rapports doivent Ãªtre ouverts automatiquement aprÃ¨s leur gÃ©nÃ©ration.

.EXAMPLE
    .\Run-Tests.ps1
    # ExÃ©cute tous les tests et gÃ©nÃ¨re un rapport de rÃ©sultats

.EXAMPLE
    .\Run-Tests.ps1 -GenerateCoverage
    # ExÃ©cute tous les tests et gÃ©nÃ¨re un rapport de rÃ©sultats et de couverture de code

.EXAMPLE
    .\Run-Tests.ps1 -GenerateCoverage -OpenReports
    # ExÃ©cute tous les tests, gÃ©nÃ¨re un rapport de rÃ©sultats et de couverture de code, et ouvre les rapports

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

# DÃ©terminer le chemin du projet
$projectRoot = $PSScriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    if (-not (Test-Path -Path $projectRoot -PathType Container)) {
        Write-Error "Impossible de dÃ©terminer le chemin du projet."
        exit 1
    }
}

# CrÃ©er le rÃ©pertoire des rapports s'il n'existe pas
$reportsDir = Join-Path -Path $projectRoot -ChildPath "reports\augment"
if (-not (Test-Path -Path $reportsDir -PathType Container)) {
    New-Item -Path $reportsDir -ItemType Directory -Force | Out-Null
}

# Chemin vers les scripts de test
$testsDir = Join-Path -Path $PSScriptRoot -ChildPath "tests"
$runAllTestsPath = Join-Path -Path $testsDir -ChildPath "Run-AllTests.ps1"
$generateCoverageReportPath = Join-Path -Path $testsDir -ChildPath "Generate-CoverageReport.ps1"

# VÃ©rifier que les scripts de test existent
if (-not (Test-Path -Path $runAllTestsPath)) {
    Write-Error "Script de test introuvable : $runAllTestsPath"
    exit 1
}

if ($GenerateCoverage -and -not (Test-Path -Path $generateCoverageReportPath)) {
    Write-Error "Script de couverture de code introuvable : $generateCoverageReportPath"
    exit 1
}

# Fonction pour convertir les rÃ©sultats XML en HTML
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

        # CrÃ©er le contenu HTML
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
        <p>GÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>

        <div class="card">
            <h2>RÃ©sumÃ©</h2>
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
                    <h3>Tests rÃ©ussis</h3>
                    <p>$passedTests / $totalTests</p>
                </div>
                <div class="summary-item $(if ($failedTests -eq 0) { "success" } else { "danger" })">
                    <h3>Tests Ã©chouÃ©s</h3>
                    <p>$failedTests / $totalTests</p>
                </div>
                <div class="summary-item $(if ($skippedTests -eq 0) { "success" } else { "warning" })">
                    <h3>Tests ignorÃ©s</h3>
                    <p>$skippedTests / $totalTests</p>
                </div>
                <div class="summary-item $(if ($successRate -ge 80) { "success" } elseif ($successRate -ge 60) { "warning" } else { "danger" })">
                    <h3>Taux de rÃ©ussite</h3>
                    <p>$successRate%</p>
                </div>
            </div>
        </div>

        <div class="card">
            <h2>DÃ©tail des tests</h2>
            <table>
                <thead>
                    <tr>
                        <th>Test</th>
                        <th>RÃ©sultat</th>
                        <th>DurÃ©e (ms)</th>
                    </tr>
                </thead>
                <tbody>
"@

        # Ajouter les dÃ©tails des tests au HTML
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

            # Ajouter les dÃ©tails de l'Ã©chec si le test a Ã©chouÃ©
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
        Write-Warning "Erreur lors de la conversion des rÃ©sultats de test en HTML : $_"
        return $false
    }
}

# ExÃ©cuter les tests
Write-Host "ExÃ©cution des tests..." -ForegroundColor Cyan
$testResultsPath = Join-Path -Path $reportsDir -ChildPath "test-results.xml"
& $runAllTestsPath -OutputPath $testResultsPath
$testExitCode = $LASTEXITCODE

# Convertir les rÃ©sultats des tests en HTML
$testResultsHtmlPath = Join-Path -Path $reportsDir -ChildPath "test-results.html"
$conversionSuccess = Convert-TestResultsToHtml -XmlPath $testResultsPath -HtmlPath $testResultsHtmlPath
if ($conversionSuccess) {
    Write-Host "Rapport HTML des rÃ©sultats de test gÃ©nÃ©rÃ© : $testResultsHtmlPath" -ForegroundColor Green
} else {
    Write-Warning "Ã‰chec de la gÃ©nÃ©ration du rapport HTML des rÃ©sultats de test."
}

# GÃ©nÃ©rer le rapport de couverture de code si demandÃ©
if ($GenerateCoverage) {
    Write-Host "`nGÃ©nÃ©ration du rapport de couverture de code..." -ForegroundColor Cyan
    $coveragePath = Join-Path -Path $reportsDir -ChildPath "coverage"
    & $generateCoverageReportPath -OutputPath $coveragePath
    $coverageExitCode = $LASTEXITCODE

    if ($coverageExitCode -eq 0) {
        Write-Host "Rapport de couverture de code gÃ©nÃ©rÃ© : $coveragePath" -ForegroundColor Green
    } else {
        Write-Warning "Ã‰chec de la gÃ©nÃ©ration du rapport de couverture de code."
    }
}

# Ouvrir les rapports si demandÃ©
if ($OpenReports) {
    if ($conversionSuccess) {
        Write-Host "`nOuverture du rapport des rÃ©sultats de test..." -ForegroundColor Cyan
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

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© de l'exÃ©cution des tests :" -ForegroundColor Cyan
if ($testExitCode -eq 0) {
    Write-Host "Tous les tests ont rÃ©ussi." -ForegroundColor Green
} else {
    Write-Host "$testExitCode tests ont Ã©chouÃ©." -ForegroundColor Red
}

# Afficher la liste des tests exÃ©cutÃ©s
Write-Host "`nTests exÃ©cutÃ©s :" -ForegroundColor Cyan
$testFiles | ForEach-Object {
    $name = (Split-Path -Path $_ -Leaf) -replace "Test-", "" -replace ".ps1", ""
    Write-Host "- $name" -ForegroundColor Gray
}

# Afficher des conseils pour exÃ©cuter des tests spÃ©cifiques
Write-Host "`nPour exÃ©cuter un test spÃ©cifique, utilisez :" -ForegroundColor Yellow
Write-Host "Invoke-Pester -Path `"development\scripts\maintenance\augment\tests\Test-<NomDuTest>.ps1`"" -ForegroundColor Yellow

# Retourner le code de sortie
exit $testExitCode
