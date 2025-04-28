<#
.SYNOPSIS
    Adaptateur TestOmnibus pour les tests de dÃ©tection des erreurs d'encodage.
.DESCRIPTION
    Cet adaptateur permet d'exÃ©cuter les tests de dÃ©tection des erreurs d'encodage
    dans le cadre de TestOmnibus, en utilisant les mocks nÃ©cessaires.
.NOTES
    Auteur: Augment Agent
    Date: 2025-04-15
    Version: 1.0
#>

function Invoke-EncodingErrorDetectionTests {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$TestPath = (Join-Path -Path $PSScriptRoot -ChildPath "..\..\development\testing\tests\TestOmnibus"),

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = (Join-Path -Path $env:TEMP -ChildPath "TestOmnibus\Results\EncodingErrorDetection"),

        [Parameter(Mandatory = $false)]
        [switch]$GenerateHtmlReport,

        [Parameter(Mandatory = $false)]
        [switch]$ShowDetailedResults
    )

    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }

    # Importer Pester si nÃ©cessaire
    if (-not (Get-Module -Name Pester -ListAvailable)) {
        Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
        Install-Module -Name Pester -Force -SkipPublisherCheck
    }

    # Configurer Pester
    $pesterConfig = New-PesterConfiguration
    $pesterConfig.Run.Path = $TestPath
    $pesterConfig.Run.PassThru = $true
    $pesterConfig.Output.Verbosity = if ($ShowDetailedResults) { 'Detailed' } else { 'Normal' }
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputPath = Join-Path -Path $OutputPath -ChildPath "EncodingErrorDetection-TestResults.xml"

    # ExÃ©cuter les tests
    Write-Host "ExÃ©cution des tests de dÃ©tection des erreurs d'encodage..." -ForegroundColor Cyan
    $results = Invoke-Pester -Configuration $pesterConfig

    # GÃ©nÃ©rer un rapport HTML si demandÃ©
    if ($GenerateHtmlReport) {
        $reportPath = Join-Path -Path $OutputPath -ChildPath "EncodingErrorDetection-TestReport.html"
        
        # CrÃ©er un rapport HTML simple
        $htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport de tests - DÃ©tection des erreurs d'encodage</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        .summary { margin: 20px 0; padding: 10px; background-color: #f5f5f5; border-radius: 5px; }
        .success { color: green; }
        .failure { color: red; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .test-name { font-weight: bold; }
        .test-result { font-weight: bold; }
        .test-passed { color: green; }
        .test-failed { color: red; }
    </style>
</head>
<body>
    <h1>Rapport de tests - DÃ©tection des erreurs d'encodage</h1>
    
    <div class="summary">
        <h2>RÃ©sumÃ©</h2>
        <p>Tests exÃ©cutÃ©s : $($results.TotalCount)</p>
        <p>Tests rÃ©ussis : <span class="success">$($results.PassedCount)</span></p>
        <p>Tests Ã©chouÃ©s : <span class="failure">$($results.FailedCount)</span></p>
        <p>DurÃ©e totale : $($results.Duration.TotalSeconds) secondes</p>
    </div>
    
    <h2>DÃ©tails des tests</h2>
    <table>
        <tr>
            <th>Nom du test</th>
            <th>RÃ©sultat</th>
            <th>DurÃ©e (ms)</th>
        </tr>
"@

        foreach ($test in $results.Tests) {
            $resultClass = if ($test.Result -eq 'Passed') { 'test-passed' } else { 'test-failed' }
            $htmlReport += @"
        <tr>
            <td class="test-name">$($test.Name)</td>
            <td class="test-result $resultClass">$($test.Result)</td>
            <td>$($test.Duration.TotalMilliseconds)</td>
        </tr>
"@
        }

        $htmlReport += @"
    </table>
</body>
</html>
"@

        # Enregistrer le rapport HTML
        $htmlReport | Out-File -FilePath $reportPath -Encoding utf8
        Write-Host "Rapport HTML gÃ©nÃ©rÃ© : $reportPath" -ForegroundColor Green
    }

    # Afficher un rÃ©sumÃ© des rÃ©sultats
    Write-Host "`nRÃ©sumÃ© des tests :" -ForegroundColor Cyan
    Write-Host "Tests exÃ©cutÃ©s : $($results.TotalCount)" -ForegroundColor White
    Write-Host "Tests rÃ©ussis : $($results.PassedCount)" -ForegroundColor Green
    Write-Host "Tests Ã©chouÃ©s : $($results.FailedCount)" -ForegroundColor Red
    Write-Host "DurÃ©e totale : $($results.Duration.TotalSeconds) secondes" -ForegroundColor White

    # Retourner les rÃ©sultats
    return [PSCustomObject]@{
        Success     = $results.FailedCount -eq 0
        TestsRun    = $results.TotalCount
        TestsPassed = $results.PassedCount
        TestsFailed = $results.FailedCount
        Duration    = $results.Duration.TotalSeconds
        ReportPath  = if ($GenerateHtmlReport) { $reportPath } else { $null }
    }
}

# Exporter la fonction
Export-ModuleMember -Function Invoke-EncodingErrorDetectionTests
