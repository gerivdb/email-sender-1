<#
.SYNOPSIS
    Adaptateur TestOmnibus pour les tests de résolution de chemins.
.DESCRIPTION
    Cet adaptateur permet d'exécuter les tests de résolution de chemins
    dans le cadre de TestOmnibus, en utilisant les mocks nécessaires.
.NOTES
    Auteur: Augment Agent
    Date: 2025-04-15
    Version: 1.0
#>

function Invoke-PathResolverTests {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$TestPath = (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\tests"),

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = (Join-Path -Path $env:TEMP -ChildPath "TestOmnibus\Results\PathResolver"),

        [Parameter(Mandatory = $false)]
        [switch]$GenerateHtmlReport,

        [Parameter(Mandatory = $false)]
        [switch]$ShowDetailedResults
    )

    # Créer le répertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }

    # Importer Pester si nécessaire
    if (-not (Get-Module -Name Pester -ListAvailable)) {
        Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
        Install-Module -Name Pester -Force -SkipPublisherCheck
    }

    # Configurer Pester
    $pesterConfig = New-PesterConfiguration
    $pesterConfig.Run.Path = Join-Path -Path $TestPath -ChildPath "PathResolver.Tests.ps1"
    $pesterConfig.Run.PassThru = $true
    $pesterConfig.Output.Verbosity = if ($ShowDetailedResults) { 'Detailed' } else { 'Normal' }
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputPath = Join-Path -Path $OutputPath -ChildPath "PathResolver-TestResults.xml"

    # Exécuter les tests
    Write-Host "Exécution des tests de résolution de chemins..." -ForegroundColor Cyan
    $results = Invoke-Pester -Configuration $pesterConfig

    # Générer un rapport HTML si demandé
    if ($GenerateHtmlReport) {
        $reportPath = Join-Path -Path $OutputPath -ChildPath "PathResolver-TestReport.html"
        
        # Créer un rapport HTML simple
        $htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport de tests - Résolution de chemins</title>
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
    <h1>Rapport de tests - Résolution de chemins</h1>
    
    <div class="summary">
        <h2>Résumé</h2>
        <p>Tests exécutés : $($results.TotalCount)</p>
        <p>Tests réussis : <span class="success">$($results.PassedCount)</span></p>
        <p>Tests échoués : <span class="failure">$($results.FailedCount)</span></p>
        <p>Durée totale : $($results.Duration.TotalSeconds) secondes</p>
    </div>
    
    <h2>Détails des tests</h2>
    <table>
        <tr>
            <th>Nom du test</th>
            <th>Résultat</th>
            <th>Durée (ms)</th>
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
        Write-Host "Rapport HTML généré : $reportPath" -ForegroundColor Green
    }

    # Afficher un résumé des résultats
    Write-Host "`nRésumé des tests :" -ForegroundColor Cyan
    Write-Host "Tests exécutés : $($results.TotalCount)" -ForegroundColor White
    Write-Host "Tests réussis : $($results.PassedCount)" -ForegroundColor Green
    Write-Host "Tests échoués : $($results.FailedCount)" -ForegroundColor Red
    Write-Host "Durée totale : $($results.Duration.TotalSeconds) secondes" -ForegroundColor White

    # Retourner les résultats
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
Export-ModuleMember -Function Invoke-PathResolverTests
