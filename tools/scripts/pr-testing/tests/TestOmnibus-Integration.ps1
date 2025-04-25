#Requires -Version 5.1
<#
.SYNOPSIS
    Script d'intégration pour TestOmnibus.

.DESCRIPTION
    Ce script permet d'intégrer les tests unitaires des scripts de test de pull requests
    dans le système TestOmnibus pour une exécution automatisée et des rapports centralisés.

.PARAMETER OutputPath
    Le chemin où enregistrer les rapports de tests.
    Par défaut: "reports\pr-testing"

.PARAMETER DetailedReport
    Indique s'il faut générer un rapport détaillé.
    Par défaut: $true

.EXAMPLE
    .\TestOmnibus-Integration.ps1
    Exécute les tests et génère un rapport dans le dossier par défaut.

.EXAMPLE
    .\TestOmnibus-Integration.ps1 -OutputPath "D:\Reports\PR-Testing" -DetailedReport $true
    Exécute les tests et génère un rapport détaillé dans le dossier spécifié.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-14
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$OutputPath = "reports\pr-testing",

    [Parameter()]
    [bool]$DetailedReport = $true
)

# Définir les chemins
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$testScriptPath = Join-Path -Path $scriptPath -ChildPath "Test-PRScripts.ps1"
$outputPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) -ChildPath $OutputPath

# Créer le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
}

# Fonction pour exécuter les tests et capturer les résultats
function Invoke-PRTests {
    param(
        [string]$TestScriptPath,
        [string]$OutputPath
    )

    Write-Host "Exécution des tests unitaires pour les scripts de test de pull requests..." -ForegroundColor Cyan

    # Pas besoin de fichier temporaire car nous capturons directement la sortie

    # Exécuter les tests et capturer la sortie
    $startTime = Get-Date
    $output = & powershell -ExecutionPolicy Bypass -File $TestScriptPath *>&1
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds

    # Extraire les résultats
    $totalTests = 0
    $passedTests = 0
    $failedTests = 0

    foreach ($line in $output) {
        if ($line -match "Tests exécutés: (\d+)") {
            $totalTests = [int]$matches[1]
        } elseif ($line -match "Tests réussis: (\d+)") {
            $passedTests = [int]$matches[1]
        } elseif ($line -match "Tests échoués: (\d+)") {
            $failedTests = [int]$matches[1]
        }
    }

    # Créer l'objet de résultats
    $results = [PSCustomObject]@{
        TestSuite   = "PR-Testing"
        TotalTests  = $totalTests
        PassedTests = $passedTests
        FailedTests = $failedTests
        SuccessRate = if ($totalTests -gt 0) { [math]::Round(($passedTests / $totalTests) * 100, 2) } else { 0 }
        Duration    = [math]::Round($duration, 2)
        Timestamp   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Output      = $output
    }

    return $results
}

# Fonction pour générer un rapport HTML
function New-TestReport {
    param(
        [PSCustomObject]$Results,
        [string]$OutputPath,
        [bool]$DetailedReport
    )

    Write-Host "Génération du rapport de tests..." -ForegroundColor Cyan

    # Créer le chemin du rapport
    $reportPath = Join-Path -Path $OutputPath -ChildPath "PR-Testing-Report-$(Get-Date -Format 'yyyyMMdd-HHmmss').html"

    # Définir le contenu HTML
    $htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de tests - PR-Testing</title>
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
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        .summary {
            display: flex;
            justify-content: space-between;
            margin-bottom: 20px;
            padding: 15px;
            background-color: #f8f9fa;
            border-radius: 5px;
        }
        .summary-item {
            text-align: center;
            padding: 10px;
        }
        .summary-item h3 {
            margin: 0;
            font-size: 16px;
        }
        .summary-item p {
            margin: 5px 0 0;
            font-size: 24px;
            font-weight: bold;
        }
        .success { color: #28a745; }
        .warning { color: #ffc107; }
        .danger { color: #dc3545; }
        .output {
            background-color: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            white-space: pre-wrap;
            font-family: Consolas, monospace;
            font-size: 14px;
            overflow-x: auto;
        }
        .test-result {
            margin-bottom: 10px;
            padding: 10px;
            border-radius: 5px;
        }
        .test-result.success { background-color: #d4edda; }
        .test-result.failure { background-color: #f8d7da; }
        .timestamp {
            font-size: 14px;
            color: #6c757d;
            margin-bottom: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Rapport de tests - PR-Testing</h1>
        <div class="timestamp">Généré le $($Results.Timestamp)</div>

        <div class="summary">
            <div class="summary-item">
                <h3>Tests exécutés</h3>
                <p>$($Results.TotalTests)</p>
            </div>
            <div class="summary-item">
                <h3>Tests réussis</h3>
                <p class="success">$($Results.PassedTests)</p>
            </div>
            <div class="summary-item">
                <h3>Tests échoués</h3>
                <p class="danger">$($Results.FailedTests)</p>
            </div>
            <div class="summary-item">
                <h3>Taux de réussite</h3>
                <p class="$(if ($Results.SuccessRate -ge 90) { 'success' } elseif ($Results.SuccessRate -ge 70) { 'warning' } else { 'danger' })">$($Results.SuccessRate)%</p>
            </div>
            <div class="summary-item">
                <h3>Durée</h3>
                <p>$($Results.Duration) s</p>
            </div>
        </div>

        <h2>Résultats détaillés</h2>
"@

    # Ajouter les résultats détaillés si demandé
    if ($DetailedReport) {
        $htmlContent += @"
        <div class="output">
$($Results.Output -join "`n")
        </div>
"@
    } else {
        $htmlContent += @"
        <p>Pour voir les résultats détaillés, exécutez le script avec le paramètre -DetailedReport $true.</p>
"@
    }

    $htmlContent += @"
    </div>
</body>
</html>
"@

    # Enregistrer le rapport
    Set-Content -Path $reportPath -Value $htmlContent

    return $reportPath
}

# Fonction pour intégrer les résultats dans TestOmnibus
function Register-TestOmnibusResults {
    param(
        [PSCustomObject]$Results,
        [string]$ReportPath
    )

    Write-Host "Enregistrement des résultats dans TestOmnibus..." -ForegroundColor Cyan

    # Vérifier si TestOmnibus est disponible
    $testOmnibusPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $scriptPath))) -ChildPath "TestOmnibus\Register-TestResults.ps1"

    if (Test-Path -Path $testOmnibusPath) {
        # Créer l'objet de résultats pour TestOmnibus
        $testOmnibusResults = [PSCustomObject]@{
            TestSuite    = "PR-Testing"
            Category     = "UnitTests"
            TotalTests   = $Results.TotalTests
            PassedTests  = $Results.PassedTests
            FailedTests  = $Results.FailedTests
            SkippedTests = 0
            Duration     = $Results.Duration
            Timestamp    = $Results.Timestamp
            ReportPath   = $ReportPath
            Tags         = @("PR", "Testing", "UnitTests")
        }

        # Enregistrer les résultats
        & $testOmnibusPath -TestResults $testOmnibusResults

        Write-Host "Résultats enregistrés dans TestOmnibus." -ForegroundColor Green
    } else {
        Write-Warning "TestOmnibus n'est pas disponible. Les résultats n'ont pas été enregistrés."
    }
}

# Exécuter les tests
$results = Invoke-PRTests -TestScriptPath $testScriptPath -OutputPath $outputPath

# Générer le rapport
$reportPath = New-TestReport -Results $results -OutputPath $outputPath -DetailedReport $DetailedReport

# Afficher le résumé
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "  Tests exécutés: $($results.TotalTests)" -ForegroundColor White
Write-Host "  Tests réussis: $($results.PassedTests)" -ForegroundColor Green
Write-Host "  Tests échoués: $($results.FailedTests)" -ForegroundColor Red
Write-Host "  Taux de réussite: $($results.SuccessRate)%" -ForegroundColor $(if ($results.SuccessRate -ge 90) { "Green" } elseif ($results.SuccessRate -ge 70) { "Yellow" } else { "Red" })
Write-Host "  Durée: $($results.Duration) secondes" -ForegroundColor White
Write-Host "`nRapport généré: $reportPath" -ForegroundColor Green

# Intégrer les résultats dans TestOmnibus
Register-TestOmnibusResults -Results $results -ReportPath $reportPath

# Retourner un code de sortie en fonction des résultats
if ($results.FailedTests -gt 0) {
    exit 1
} else {
    exit 0
}
