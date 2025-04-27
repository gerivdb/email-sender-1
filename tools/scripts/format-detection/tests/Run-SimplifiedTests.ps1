#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute les tests unitaires simplifiÃ©s pour les fonctionnalitÃ©s de dÃ©tection de format.

.DESCRIPTION
    Ce script exÃ©cute les tests unitaires simplifiÃ©s pour valider le bon fonctionnement
    des fonctionnalitÃ©s de dÃ©tection de format et d'encodage.

.PARAMETER GenerateHtmlReport
    Indique si un rapport HTML doit Ãªtre gÃ©nÃ©rÃ© en plus du rapport XML.

.EXAMPLE
    .\Run-SimplifiedTests.ps1 -GenerateHtmlReport

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$GenerateHtmlReport
)

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas disponible. Installation..."
    try {
        Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
    }
    catch {
        Write-Error "Impossible d'installer le module Pester. Les tests ne peuvent pas Ãªtre exÃ©cutÃ©s."
        return
    }
}

# Importer le module Pester
Import-Module Pester

# Chemins des scripts de test
$encodingTestScript = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\tests\Simple-EncodingDetection.Tests.ps1"
$formatTestScript = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\tests\Simplified-FormatDetection.Tests.ps1"

# Chemins des rapports
$outputDirectory = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\tests\reports"
$testResultsPath = Join-Path -Path $outputDirectory -ChildPath "SimplifiedTestResults.xml"

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $outputDirectory -PathType Container)) {
    New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
    Write-Host "RÃ©pertoire de sortie crÃ©Ã© : $outputDirectory" -ForegroundColor Green
}

# GÃ©nÃ©rer les fichiers d'Ã©chantillon
$generateSamplesScript = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\tests\Generate-TestSamples.ps1"
if (Test-Path -Path $generateSamplesScript -PathType Leaf) {
    Write-Host "GÃ©nÃ©ration des fichiers d'Ã©chantillon..." -ForegroundColor Cyan
    & $generateSamplesScript -Force
}
else {
    Write-Warning "Le script de gÃ©nÃ©ration des Ã©chantillons n'existe pas : $generateSamplesScript"
}

# Configurer Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = @($encodingTestScript, $formatTestScript)
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = 'Detailed'
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = $testResultsPath
$pesterConfig.TestResult.OutputFormat = 'NUnitXml'

# ExÃ©cuter les tests
Write-Host "ExÃ©cution des tests unitaires simplifiÃ©s..." -ForegroundColor Cyan
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© des tests :" -ForegroundColor Cyan
Write-Host "  Tests exÃ©cutÃ©s : $($testResults.TotalCount)" -ForegroundColor White
Write-Host "  Tests rÃ©ussis  : $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "  Tests Ã©chouÃ©s  : $($testResults.FailedCount)" -ForegroundColor $(if ($testResults.FailedCount -gt 0) { "Red" } else { "Green" })
Write-Host "  Tests ignorÃ©s  : $($testResults.SkippedCount)" -ForegroundColor Yellow
Write-Host "  Tests non exÃ©cutÃ©s : $($testResults.NotRunCount)" -ForegroundColor Yellow
Write-Host "  DurÃ©e totale   : $($testResults.Duration.TotalSeconds) secondes" -ForegroundColor White

# GÃ©nÃ©rer un rapport HTML si demandÃ©
if ($GenerateHtmlReport) {
    $htmlOutputPath = [System.IO.Path]::ChangeExtension($testResultsPath, "html")
    
    # GÃ©nÃ©rer un rapport HTML simple
    $htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de tests unitaires simplifiÃ©s</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1, h2, h3 {
            color: #0078D4;
        }
        .summary {
            background-color: #f5f5f5;
            padding: 20px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .passed {
            color: green;
            font-weight: bold;
        }
        .failed {
            color: red;
            font-weight: bold;
        }
        .skipped {
            color: orange;
            font-weight: bold;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 10px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #0078D4;
            color: white;
        }
        tr:nth-child(even) {
            background-color: #f2f2f2;
        }
    </style>
</head>
<body>
    <h1>Rapport de tests unitaires simplifiÃ©s</h1>
    <p>Date de gÃ©nÃ©ration : $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")</p>
    
    <div class="summary">
        <h2>RÃ©sumÃ©</h2>
        <p>Tests exÃ©cutÃ©s : $($testResults.TotalCount)</p>
        <p>Tests rÃ©ussis : <span class="passed">$($testResults.PassedCount)</span></p>
        <p>Tests Ã©chouÃ©s : <span class="failed">$($testResults.FailedCount)</span></p>
        <p>Tests ignorÃ©s : <span class="skipped">$($testResults.SkippedCount)</span></p>
        <p>Tests non exÃ©cutÃ©s : <span class="skipped">$($testResults.NotRunCount)</span></p>
        <p>DurÃ©e totale : $($testResults.Duration.TotalSeconds) secondes</p>
    </div>
    
    <h2>DÃ©tails des tests</h2>
    <table>
        <tr>
            <th>Nom du test</th>
            <th>RÃ©sultat</th>
            <th>DurÃ©e (ms)</th>
        </tr>
"@
    
    foreach ($container in $testResults.Tests) {
        $testName = $container.Name
        $testResult = $container.Result
        $testDuration = $container.Duration.TotalMilliseconds
        
        $resultClass = switch ($testResult) {
            "Passed" { "passed" }
            "Failed" { "failed" }
            "Skipped" { "skipped" }
            default { "" }
        }
        
        $htmlContent += @"
        <tr>
            <td>$testName</td>
            <td class="$resultClass">$testResult</td>
            <td>$testDuration</td>
        </tr>
"@
    }
    
    $htmlContent += @"
    </table>
</body>
</html>
"@
    
    # Enregistrer le rapport HTML
    $htmlContent | Out-File -FilePath $htmlOutputPath -Encoding utf8
    
    Write-Host "`nRapport HTML gÃ©nÃ©rÃ© : $htmlOutputPath" -ForegroundColor Green
}

# Retourner les rÃ©sultats des tests
return $testResults
