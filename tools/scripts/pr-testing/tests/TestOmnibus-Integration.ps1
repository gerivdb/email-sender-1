#Requires -Version 5.1
<#
.SYNOPSIS
    Script d'intÃ©gration pour TestOmnibus.

.DESCRIPTION
    Ce script permet d'intÃ©grer les tests unitaires des scripts de test de pull requests
    dans le systÃ¨me TestOmnibus pour une exÃ©cution automatisÃ©e et des rapports centralisÃ©s.

.PARAMETER OutputPath
    Le chemin oÃ¹ enregistrer les rapports de tests.
    Par dÃ©faut: "reports\pr-testing"

.PARAMETER DetailedReport
    Indique s'il faut gÃ©nÃ©rer un rapport dÃ©taillÃ©.
    Par dÃ©faut: $true

.EXAMPLE
    .\TestOmnibus-Integration.ps1
    ExÃ©cute les tests et gÃ©nÃ¨re un rapport dans le dossier par dÃ©faut.

.EXAMPLE
    .\TestOmnibus-Integration.ps1 -OutputPath "D:\Reports\PR-Testing" -DetailedReport $true
    ExÃ©cute les tests et gÃ©nÃ¨re un rapport dÃ©taillÃ© dans le dossier spÃ©cifiÃ©.

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

# DÃ©finir les chemins
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$testScriptPath = Join-Path -Path $scriptPath -ChildPath "Test-PRScripts.ps1"
$outputPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) -ChildPath $OutputPath

# CrÃ©er le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
}

# Fonction pour exÃ©cuter les tests et capturer les rÃ©sultats
function Invoke-PRTests {
    param(
        [string]$TestScriptPath,
        [string]$OutputPath
    )

    Write-Host "ExÃ©cution des tests unitaires pour les scripts de test de pull requests..." -ForegroundColor Cyan

    # Pas besoin de fichier temporaire car nous capturons directement la sortie

    # ExÃ©cuter les tests et capturer la sortie
    $startTime = Get-Date
    $output = & powershell -ExecutionPolicy Bypass -File $TestScriptPath *>&1
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds

    # Extraire les rÃ©sultats
    $totalTests = 0
    $passedTests = 0
    $failedTests = 0

    foreach ($line in $output) {
        if ($line -match "Tests exÃ©cutÃ©s: (\d+)") {
            $totalTests = [int]$matches[1]
        } elseif ($line -match "Tests rÃ©ussis: (\d+)") {
            $passedTests = [int]$matches[1]
        } elseif ($line -match "Tests Ã©chouÃ©s: (\d+)") {
            $failedTests = [int]$matches[1]
        }
    }

    # CrÃ©er l'objet de rÃ©sultats
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

# Fonction pour gÃ©nÃ©rer un rapport HTML
function New-TestReport {
    param(
        [PSCustomObject]$Results,
        [string]$OutputPath,
        [bool]$DetailedReport
    )

    Write-Host "GÃ©nÃ©ration du rapport de tests..." -ForegroundColor Cyan

    # CrÃ©er le chemin du rapport
    $reportPath = Join-Path -Path $OutputPath -ChildPath "PR-Testing-Report-$(Get-Date -Format 'yyyyMMdd-HHmmss').html"

    # DÃ©finir le contenu HTML
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
        <div class="timestamp">GÃ©nÃ©rÃ© le $($Results.Timestamp)</div>

        <div class="summary">
            <div class="summary-item">
                <h3>Tests exÃ©cutÃ©s</h3>
                <p>$($Results.TotalTests)</p>
            </div>
            <div class="summary-item">
                <h3>Tests rÃ©ussis</h3>
                <p class="success">$($Results.PassedTests)</p>
            </div>
            <div class="summary-item">
                <h3>Tests Ã©chouÃ©s</h3>
                <p class="danger">$($Results.FailedTests)</p>
            </div>
            <div class="summary-item">
                <h3>Taux de rÃ©ussite</h3>
                <p class="$(if ($Results.SuccessRate -ge 90) { 'success' } elseif ($Results.SuccessRate -ge 70) { 'warning' } else { 'danger' })">$($Results.SuccessRate)%</p>
            </div>
            <div class="summary-item">
                <h3>DurÃ©e</h3>
                <p>$($Results.Duration) s</p>
            </div>
        </div>

        <h2>RÃ©sultats dÃ©taillÃ©s</h2>
"@

    # Ajouter les rÃ©sultats dÃ©taillÃ©s si demandÃ©
    if ($DetailedReport) {
        $htmlContent += @"
        <div class="output">
$($Results.Output -join "`n")
        </div>
"@
    } else {
        $htmlContent += @"
        <p>Pour voir les rÃ©sultats dÃ©taillÃ©s, exÃ©cutez le script avec le paramÃ¨tre -DetailedReport $true.</p>
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

# Fonction pour intÃ©grer les rÃ©sultats dans TestOmnibus
function Register-TestOmnibusResults {
    param(
        [PSCustomObject]$Results,
        [string]$ReportPath
    )

    Write-Host "Enregistrement des rÃ©sultats dans TestOmnibus..." -ForegroundColor Cyan

    # VÃ©rifier si TestOmnibus est disponible
    $testOmnibusPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $scriptPath))) -ChildPath "TestOmnibus\Register-TestResults.ps1"

    if (Test-Path -Path $testOmnibusPath) {
        # CrÃ©er l'objet de rÃ©sultats pour TestOmnibus
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

        # Enregistrer les rÃ©sultats
        & $testOmnibusPath -TestResults $testOmnibusResults

        Write-Host "RÃ©sultats enregistrÃ©s dans TestOmnibus." -ForegroundColor Green
    } else {
        Write-Warning "TestOmnibus n'est pas disponible. Les rÃ©sultats n'ont pas Ã©tÃ© enregistrÃ©s."
    }
}

# ExÃ©cuter les tests
$results = Invoke-PRTests -TestScriptPath $testScriptPath -OutputPath $outputPath

# GÃ©nÃ©rer le rapport
$reportPath = New-TestReport -Results $results -OutputPath $outputPath -DetailedReport $DetailedReport

# Afficher le rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© des tests:" -ForegroundColor Cyan
Write-Host "  Tests exÃ©cutÃ©s: $($results.TotalTests)" -ForegroundColor White
Write-Host "  Tests rÃ©ussis: $($results.PassedTests)" -ForegroundColor Green
Write-Host "  Tests Ã©chouÃ©s: $($results.FailedTests)" -ForegroundColor Red
Write-Host "  Taux de rÃ©ussite: $($results.SuccessRate)%" -ForegroundColor $(if ($results.SuccessRate -ge 90) { "Green" } elseif ($results.SuccessRate -ge 70) { "Yellow" } else { "Red" })
Write-Host "  DurÃ©e: $($results.Duration) secondes" -ForegroundColor White
Write-Host "`nRapport gÃ©nÃ©rÃ©: $reportPath" -ForegroundColor Green

# IntÃ©grer les rÃ©sultats dans TestOmnibus
Register-TestOmnibusResults -Results $results -ReportPath $reportPath

# Retourner un code de sortie en fonction des rÃ©sultats
if ($results.FailedTests -gt 0) {
    exit 1
} else {
    exit 0
}
