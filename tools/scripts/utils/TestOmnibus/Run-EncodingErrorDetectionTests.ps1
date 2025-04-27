<#
.SYNOPSIS
    ExÃ©cute les tests de dÃ©tection des erreurs d'encodage avec TestOmnibus.
.DESCRIPTION
    Ce script exÃ©cute les tests de dÃ©tection des erreurs d'encodage en utilisant
    TestOmnibus et gÃ©nÃ¨re un rapport HTML des rÃ©sultats.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration de TestOmnibus.
.PARAMETER GenerateHtmlReport
    Indique si un rapport HTML doit Ãªtre gÃ©nÃ©rÃ©.
.PARAMETER ShowDetailedResults
    Indique si les rÃ©sultats dÃ©taillÃ©s doivent Ãªtre affichÃ©s.
.EXAMPLE
    .\Run-EncodingErrorDetectionTests.ps1 -GenerateHtmlReport
.NOTES
    Auteur: Augment Agent
    Date: 2025-04-15
    Version: 1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = (Join-Path -Path $PSScriptRoot -ChildPath "Config\testomnibus_config.json"),

    [Parameter(Mandatory = $false)]
    [switch]$GenerateHtmlReport,

    [Parameter(Mandatory = $false)]
    [switch]$ShowDetailedResults
)

# VÃ©rifier que le fichier de configuration existe
if (-not (Test-Path -Path $ConfigPath)) {
    Write-Error "Le fichier de configuration n'existe pas: $ConfigPath"
    return 1
}

# Chemin vers TestOmnibus
$testOmnibusPath = Join-Path -Path $PSScriptRoot -ChildPath "Invoke-TestOmnibus.ps1"

if (-not (Test-Path -Path $testOmnibusPath)) {
    Write-Error "TestOmnibus non trouvÃ©: $testOmnibusPath"
    return 1
}

# Charger la configuration
$config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json

# Filtrer les modules de test pour ne garder que ceux liÃ©s Ã  la dÃ©tection des erreurs d'encodage
$encodingErrorDetectionModules = $config.TestModules | Where-Object { $_.Name -eq "EncodingErrorDetection" }

if ($encodingErrorDetectionModules.Count -eq 0) {
    Write-Error "Aucun module de test de dÃ©tection des erreurs d'encodage trouvÃ© dans la configuration."
    return 1
}

# ExÃ©cuter les tests pour chaque module de dÃ©tection des erreurs d'encodage
$results = @()

foreach ($module in $encodingErrorDetectionModules) {
    Write-Host "ExÃ©cution des tests pour le module $($module.Name)..." -ForegroundColor Cyan
    
    # ExÃ©cuter TestOmnibus pour ce module
    $moduleResults = & $testOmnibusPath -Path $module.Path -ConfigPath $ConfigPath
    
    # Ajouter les rÃ©sultats Ã  la liste
    $results += [PSCustomObject]@{
        Module      = $module.Name
        Success     = $moduleResults.Success
        TestsRun    = $moduleResults.TestsRun
        TestsPassed = $moduleResults.TestsPassed
        TestsFailed = $moduleResults.TestsFailed
        Duration    = $moduleResults.Duration
    }
}

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© des tests de dÃ©tection des erreurs d'encodage :" -ForegroundColor Cyan
$totalTests = ($results | Measure-Object -Property TestsRun -Sum).Sum
$totalPassed = ($results | Measure-Object -Property TestsPassed -Sum).Sum
$totalFailed = ($results | Measure-Object -Property TestsFailed -Sum).Sum
$totalDuration = ($results | Measure-Object -Property Duration -Sum).Sum

Write-Host "Tests exÃ©cutÃ©s : $totalTests" -ForegroundColor White
Write-Host "Tests rÃ©ussis : $totalPassed" -ForegroundColor Green
Write-Host "Tests Ã©chouÃ©s : $totalFailed" -ForegroundColor Red
Write-Host "DurÃ©e totale : $totalDuration secondes" -ForegroundColor White

# GÃ©nÃ©rer un rapport HTML global si demandÃ©
if ($GenerateHtmlReport) {
    $reportDir = Join-Path -Path $config.OutputPath -ChildPath "EncodingErrorDetection"
    
    if (-not (Test-Path -Path $reportDir)) {
        New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
    }
    
    $reportPath = Join-Path -Path $reportDir -ChildPath "EncodingErrorDetection-GlobalReport.html"
    
    # CrÃ©er un rapport HTML simple
    $htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport global - Tests de dÃ©tection des erreurs d'encodage</title>
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
        .module-name { font-weight: bold; }
        .success-row { background-color: #dff0d8; }
        .failure-row { background-color: #f2dede; }
    </style>
</head>
<body>
    <h1>Rapport global - Tests de dÃ©tection des erreurs d'encodage</h1>
    
    <div class="summary">
        <h2>RÃ©sumÃ©</h2>
        <p>Tests exÃ©cutÃ©s : $totalTests</p>
        <p>Tests rÃ©ussis : <span class="success">$totalPassed</span></p>
        <p>Tests Ã©chouÃ©s : <span class="failure">$totalFailed</span></p>
        <p>DurÃ©e totale : $totalDuration secondes</p>
    </div>
    
    <h2>DÃ©tails par module</h2>
    <table>
        <tr>
            <th>Module</th>
            <th>Tests exÃ©cutÃ©s</th>
            <th>Tests rÃ©ussis</th>
            <th>Tests Ã©chouÃ©s</th>
            <th>DurÃ©e (s)</th>
            <th>Statut</th>
        </tr>
"@

    foreach ($result in $results) {
        $rowClass = if ($result.Success) { 'success-row' } else { 'failure-row' }
        $status = if ($result.Success) { 'SuccÃ¨s' } else { 'Ã‰chec' }
        
        $htmlReport += @"
        <tr class="$rowClass">
            <td class="module-name">$($result.Module)</td>
            <td>$($result.TestsRun)</td>
            <td>$($result.TestsPassed)</td>
            <td>$($result.TestsFailed)</td>
            <td>$($result.Duration)</td>
            <td>$status</td>
        </tr>
"@
    }

    $htmlReport += @"
    </table>
    
    <h2>Recommandations</h2>
    <ul>
        <li>ExÃ©cuter rÃ©guliÃ¨rement les tests de dÃ©tection des erreurs d'encodage pour identifier les problÃ¨mes potentiels.</li>
        <li>Utiliser l'outil de correction automatique des problÃ¨mes d'encodage pour rÃ©soudre les problÃ¨mes identifiÃ©s.</li>
        <li>Configurer les Ã©diteurs de code pour utiliser UTF-8 avec BOM pour les fichiers PowerShell.</li>
    </ul>
</body>
</html>
"@

    # Enregistrer le rapport HTML
    $htmlReport | Out-File -FilePath $reportPath -Encoding utf8
    Write-Host "Rapport HTML global gÃ©nÃ©rÃ© : $reportPath" -ForegroundColor Green
}

# Retourner les rÃ©sultats
return [PSCustomObject]@{
    TotalCount   = $totalTests
    PassedCount  = $totalPassed
    FailedCount  = $totalFailed
    Duration     = $totalDuration
    Results      = $results
    ReportPath   = if ($GenerateHtmlReport) { $reportPath } else { $null }
}
