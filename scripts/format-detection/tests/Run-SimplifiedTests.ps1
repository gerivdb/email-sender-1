#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute les tests unitaires simplifiés pour les fonctionnalités de détection de format.

.DESCRIPTION
    Ce script exécute les tests unitaires simplifiés pour valider le bon fonctionnement
    des fonctionnalités de détection de format et d'encodage.

.PARAMETER GenerateHtmlReport
    Indique si un rapport HTML doit être généré en plus du rapport XML.

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
        Write-Error "Impossible d'installer le module Pester. Les tests ne peuvent pas être exécutés."
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

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $outputDirectory -PathType Container)) {
    New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
    Write-Host "Répertoire de sortie créé : $outputDirectory" -ForegroundColor Green
}

# Générer les fichiers d'échantillon
$generateSamplesScript = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\tests\Generate-TestSamples.ps1"
if (Test-Path -Path $generateSamplesScript -PathType Leaf) {
    Write-Host "Génération des fichiers d'échantillon..." -ForegroundColor Cyan
    & $generateSamplesScript -Force
}
else {
    Write-Warning "Le script de génération des échantillons n'existe pas : $generateSamplesScript"
}

# Configurer Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = @($encodingTestScript, $formatTestScript)
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = 'Detailed'
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = $testResultsPath
$pesterConfig.TestResult.OutputFormat = 'NUnitXml'

# Exécuter les tests
Write-Host "Exécution des tests unitaires simplifiés..." -ForegroundColor Cyan
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher un résumé des résultats
Write-Host "`nRésumé des tests :" -ForegroundColor Cyan
Write-Host "  Tests exécutés : $($testResults.TotalCount)" -ForegroundColor White
Write-Host "  Tests réussis  : $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "  Tests échoués  : $($testResults.FailedCount)" -ForegroundColor $(if ($testResults.FailedCount -gt 0) { "Red" } else { "Green" })
Write-Host "  Tests ignorés  : $($testResults.SkippedCount)" -ForegroundColor Yellow
Write-Host "  Tests non exécutés : $($testResults.NotRunCount)" -ForegroundColor Yellow
Write-Host "  Durée totale   : $($testResults.Duration.TotalSeconds) secondes" -ForegroundColor White

# Générer un rapport HTML si demandé
if ($GenerateHtmlReport) {
    $htmlOutputPath = [System.IO.Path]::ChangeExtension($testResultsPath, "html")
    
    # Générer un rapport HTML simple
    $htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de tests unitaires simplifiés</title>
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
    <h1>Rapport de tests unitaires simplifiés</h1>
    <p>Date de génération : $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")</p>
    
    <div class="summary">
        <h2>Résumé</h2>
        <p>Tests exécutés : $($testResults.TotalCount)</p>
        <p>Tests réussis : <span class="passed">$($testResults.PassedCount)</span></p>
        <p>Tests échoués : <span class="failed">$($testResults.FailedCount)</span></p>
        <p>Tests ignorés : <span class="skipped">$($testResults.SkippedCount)</span></p>
        <p>Tests non exécutés : <span class="skipped">$($testResults.NotRunCount)</span></p>
        <p>Durée totale : $($testResults.Duration.TotalSeconds) secondes</p>
    </div>
    
    <h2>Détails des tests</h2>
    <table>
        <tr>
            <th>Nom du test</th>
            <th>Résultat</th>
            <th>Durée (ms)</th>
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
    
    Write-Host "`nRapport HTML généré : $htmlOutputPath" -ForegroundColor Green
}

# Retourner les résultats des tests
return $testResults
