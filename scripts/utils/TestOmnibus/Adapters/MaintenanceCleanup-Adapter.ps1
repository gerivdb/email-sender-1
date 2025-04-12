<#
.SYNOPSIS
    Adaptateur TestOmnibus pour les tests du module Maintenance Cleanup.
.DESCRIPTION
    Cet adaptateur permet d'exécuter les tests du module Maintenance Cleanup
    dans le cadre de TestOmnibus, en utilisant les mocks nécessaires.
.NOTES
    Auteur: Augment Agent
    Date: 2025-04-12
    Version: 1.0
#>

function Invoke-MaintenanceCleanupTests {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$TestPath = (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\maintenance\cleanup\tests"),

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = (Join-Path -Path $env:TEMP -ChildPath "TestOmnibus\Results\MaintenanceCleanup"),

        [Parameter(Mandatory = $false)]
        [switch]$GenerateHtmlReport,

        [Parameter(Mandatory = $false)]
        [switch]$ShowDetailedResults
    )

    # Vérifier que le chemin des tests existe
    if (-not (Test-Path -Path $TestPath)) {
        Write-Error "Le chemin des tests n'existe pas: $TestPath"
        return @{
            Success      = $false
            ErrorMessage = "Le chemin des tests n'existe pas: $TestPath"
            TestsRun     = 0
            TestsPassed  = 0
            TestsFailed  = 0
            Duration     = 0
        }
    }

    # Créer le répertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }

    # Importer Pester
    if (-not (Get-Module -ListAvailable -Name Pester)) {
        Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
        Install-Module -Name Pester -Force -SkipPublisherCheck
    }

    Import-Module Pester -Force

    # Configurer Pester
    $pesterConfig = New-PesterConfiguration
    $pesterConfig.Run.Path = $TestPath
    $pesterConfig.Run.PassThru = $true
    $pesterConfig.Output.Verbosity = if ($ShowDetailedResults) { 'Detailed' } else { 'Normal' }
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputPath = Join-Path -Path $OutputPath -ChildPath "TestResults.xml"
    $pesterConfig.TestResult.OutputFormat = 'NUnitXml'

    if ($GenerateHtmlReport) {
        $pesterConfig.CodeCoverage.Enabled = $true
        $pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $OutputPath -ChildPath "CodeCoverage.xml"
        $pesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'
    }

    # Mesurer le temps d'exécution
    $startTime = Get-Date

    # Exécuter les tests
    try {
        $results = Invoke-Pester -Configuration $pesterConfig
    } catch {
        Write-Error "Erreur lors de l'exécution des tests: $_"
        return @{
            Success      = $false
            ErrorMessage = "Erreur lors de l'exécution des tests: $_"
            TestsRun     = 0
            TestsPassed  = 0
            TestsFailed  = 0
            Duration     = 0
        }
    }

    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalMilliseconds

    # Générer un rapport HTML si demandé
    if ($GenerateHtmlReport) {
        $reportPath = Join-Path -Path $OutputPath -ChildPath "TestReport.html"
        
        # Créer un rapport HTML simple
        $htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport de tests - Maintenance Cleanup</title>
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
    </style>
</head>
<body>
    <h1>Rapport de tests - Maintenance Cleanup</h1>
    <div class="summary">
        <p>Tests exécutés: $($results.TotalCount)</p>
        <p>Tests réussis: <span class="success">$($results.PassedCount)</span></p>
        <p>Tests échoués: <span class="failure">$($results.FailedCount)</span></p>
        <p>Tests ignorés: $($results.SkippedCount)</p>
        <p>Durée totale: $([math]::Round($duration / 1000, 2)) secondes</p>
    </div>
    <h2>Détails des tests</h2>
    <table>
        <tr>
            <th>Nom</th>
            <th>Résultat</th>
            <th>Durée (ms)</th>
        </tr>
"@

        foreach ($test in $results.Tests) {
            $result = if ($test.Result -eq "Passed") { 
                "<span class='success'>Réussi</span>" 
            } else { 
                "<span class='failure'>Échoué</span>" 
            }
            
            $htmlReport += @"
        <tr>
            <td>$($test.Name)</td>
            <td>$result</td>
            <td>$([math]::Round($test.Duration.TotalMilliseconds, 2))</td>
        </tr>
"@
        }

        $htmlReport += @"
    </table>
</body>
</html>
"@

        $htmlReport | Out-File -FilePath $reportPath -Encoding utf8
        Write-Host "Rapport HTML généré: $reportPath" -ForegroundColor Green
    }

    # Retourner les résultats
    return @{
        Success      = ($results.FailedCount -eq 0)
        ErrorMessage = if ($results.FailedCount -gt 0) { "$($results.FailedCount) tests ont échoué" } else { "" }
        TestsRun     = $results.TotalCount
        TestsPassed  = $results.PassedCount
        TestsFailed  = $results.FailedCount
        TestsSkipped = $results.SkippedCount
        Duration     = $duration
    }
}

# Exporter la fonction
Export-ModuleMember -Function Invoke-MaintenanceCleanupTests
