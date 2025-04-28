<#
.SYNOPSIS
    ExÃ©cute tous les tests pour les modes et gÃ©nÃ¨re un rapport de couverture.

.DESCRIPTION
    Ce script exÃ©cute tous les tests unitaires et d'intÃ©gration pour les diffÃ©rents modes
    et gÃ©nÃ¨re un rapport de couverture global. Il permet de s'assurer que tous les modes
    fonctionnent correctement individuellement et ensemble.

.PARAMETER OutputPath
    Chemin oÃ¹ seront gÃ©nÃ©rÃ©s les rapports de test et de couverture.

.PARAMETER ShowResults
    Indique si les rÃ©sultats des tests doivent Ãªtre affichÃ©s dans la console.

.PARAMETER GenerateReport
    Indique si un rapport HTML doit Ãªtre gÃ©nÃ©rÃ©.

.EXAMPLE
    .\Invoke-AllTests.ps1 -OutputPath "test-reports" -ShowResults $true -GenerateReport $true

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "test-reports",
    
    [Parameter(Mandatory = $false)]
    [bool]$ShowResults = $true,
    
    [Parameter(Mandatory = $false)]
    [bool]$GenerateReport = $true
)

# VÃ©rifier si Pester est installÃ©
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    try {
        Install-Module -Name Pester -Force -SkipPublisherCheck
        Import-Module Pester
        Write-Host "Module Pester installÃ© avec succÃ¨s." -ForegroundColor Green
    } catch {
        Write-Error "Impossible d'installer le module Pester : $_"
        exit 1
    }
} else {
    Import-Module Pester
    Write-Host "Module Pester dÃ©jÃ  installÃ©." -ForegroundColor Green
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Host "RÃ©pertoire de sortie crÃ©Ã© : $OutputPath" -ForegroundColor Green
}

# Chemin vers les tests
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$testFiles = Get-ChildItem -Path $scriptPath -Filter "Test-*.ps1" | Where-Object { $_.Name -ne "Test-Template.ps1" }

Write-Host "Tests trouvÃ©s : $($testFiles.Count)" -ForegroundColor Green
foreach ($testFile in $testFiles) {
    Write-Host "  - $($testFile.Name)" -ForegroundColor Gray
}

# Configuration des tests
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $scriptPath
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = 'Detailed'
$pesterConfig.CodeCoverage.Enabled = $true
$pesterConfig.CodeCoverage.Path = Join-Path -Path $scriptPath -ChildPath "..\Functions\Public\*.ps1"
$pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $OutputPath -ChildPath "coverage.xml"
$pesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = Join-Path -Path $OutputPath -ChildPath "test-results.xml"
$pesterConfig.TestResult.OutputFormat = 'NUnitXml'

# ExÃ©cuter les tests
Write-Host "ExÃ©cution des tests..." -ForegroundColor Yellow
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher les rÃ©sultats
if ($ShowResults) {
    Write-Host "`nRÃ©sultats des tests :" -ForegroundColor Yellow
    Write-Host "  - Tests exÃ©cutÃ©s : $($testResults.TotalCount)" -ForegroundColor $(if ($testResults.TotalCount -gt 0) { "Green" } else { "Red" })
    Write-Host "  - Tests rÃ©ussis : $($testResults.PassedCount)" -ForegroundColor $(if ($testResults.PassedCount -eq $testResults.TotalCount) { "Green" } else { "Yellow" })
    Write-Host "  - Tests Ã©chouÃ©s : $($testResults.FailedCount)" -ForegroundColor $(if ($testResults.FailedCount -eq 0) { "Green" } else { "Red" })
    Write-Host "  - Tests ignorÃ©s : $($testResults.SkippedCount)" -ForegroundColor $(if ($testResults.SkippedCount -eq 0) { "Green" } else { "Yellow" })
    Write-Host "  - DurÃ©e totale : $($testResults.Duration.TotalSeconds) secondes" -ForegroundColor Gray
    
    if ($testResults.FailedCount -gt 0) {
        Write-Host "`nTests Ã©chouÃ©s :" -ForegroundColor Red
        foreach ($failedTest in $testResults.Failed) {
            Write-Host "  - $($failedTest.Name)" -ForegroundColor Red
            Write-Host "    $($failedTest.ErrorRecord)" -ForegroundColor Gray
        }
    }
}

# GÃ©nÃ©rer un rapport HTML
if ($GenerateReport) {
    Write-Host "`nGÃ©nÃ©ration du rapport HTML..." -ForegroundColor Yellow
    
    # CrÃ©er le rapport HTML
    $reportPath = Join-Path -Path $OutputPath -ChildPath "test-report.html"
    
    $htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport de tests - Modes RoadmapParser</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        .summary {
            background-color: #f8f9fa;
            border-radius: 5px;
            padding: 15px;
            margin-bottom: 20px;
        }
        .success {
            color: #28a745;
        }
        .warning {
            color: #ffc107;
        }
        .danger {
            color: #dc3545;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 10px;
            border: 1px solid #ddd;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        .progress-container {
            width: 100%;
            height: 20px;
            background-color: #f1f1f1;
            border-radius: 5px;
            margin-bottom: 10px;
        }
        .progress-bar {
            height: 20px;
            background-color: #4CAF50;
            border-radius: 5px;
            text-align: center;
            line-height: 20px;
            color: white;
        }
    </style>
</head>
<body>
    <h1>Rapport de tests - Modes RoadmapParser</h1>
    <div class="summary">
        <h2>RÃ©sumÃ©</h2>
        <p>Date d'exÃ©cution : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        <div class="progress-container">
            <div class="progress-bar" style="width: $([Math]::Round(($testResults.PassedCount / $testResults.TotalCount) * 100))%">
                $([Math]::Round(($testResults.PassedCount / $testResults.TotalCount) * 100))%
            </div>
        </div>
        <p>Tests exÃ©cutÃ©s : <strong>$($testResults.TotalCount)</strong></p>
        <p>Tests rÃ©ussis : <span class="success"><strong>$($testResults.PassedCount)</strong></span></p>
        <p>Tests Ã©chouÃ©s : <span class="danger"><strong>$($testResults.FailedCount)</strong></span></p>
        <p>Tests ignorÃ©s : <span class="warning"><strong>$($testResults.SkippedCount)</strong></span></p>
        <p>DurÃ©e totale : <strong>$($testResults.Duration.TotalSeconds) secondes</strong></p>
    </div>
    
    <h2>DÃ©tails des tests</h2>
    <table>
        <tr>
            <th>Nom</th>
            <th>RÃ©sultat</th>
            <th>DurÃ©e (ms)</th>
        </tr>
"@

    foreach ($test in $testResults.Tests) {
        $resultClass = switch ($test.Result) {
            "Passed" { "success" }
            "Failed" { "danger" }
            "Skipped" { "warning" }
            default { "" }
        }
        
        $htmlReport += @"
        <tr>
            <td>$($test.Name)</td>
            <td class="$resultClass">$($test.Result)</td>
            <td>$($test.Duration.TotalMilliseconds)</td>
        </tr>
"@
    }

    $htmlReport += @"
    </table>
    
    <h2>Tests Ã©chouÃ©s</h2>
"@

    if ($testResults.FailedCount -gt 0) {
        $htmlReport += @"
    <table>
        <tr>
            <th>Nom</th>
            <th>Message d'erreur</th>
        </tr>
"@

        foreach ($failedTest in $testResults.Failed) {
            $htmlReport += @"
        <tr>
            <td>$($failedTest.Name)</td>
            <td>$($failedTest.ErrorRecord)</td>
        </tr>
"@
        }

        $htmlReport += @"
    </table>
"@
    } else {
        $htmlReport += @"
    <p class="success">Aucun test n'a Ã©chouÃ©.</p>
"@
    }

    $htmlReport += @"
</body>
</html>
"@

    $htmlReport | Set-Content -Path $reportPath -Encoding UTF8
    Write-Host "Rapport HTML gÃ©nÃ©rÃ© : $reportPath" -ForegroundColor Green
}

# Afficher le chemin des rapports
Write-Host "`nRapports gÃ©nÃ©rÃ©s :" -ForegroundColor Yellow
Write-Host "  - Rapport de tests : $(Join-Path -Path $OutputPath -ChildPath "test-results.xml")" -ForegroundColor Gray
Write-Host "  - Rapport de couverture : $(Join-Path -Path $OutputPath -ChildPath "coverage.xml")" -ForegroundColor Gray
if ($GenerateReport) {
    Write-Host "  - Rapport HTML : $(Join-Path -Path $OutputPath -ChildPath "test-report.html")" -ForegroundColor Gray
}

# Retourner les rÃ©sultats
return $testResults
