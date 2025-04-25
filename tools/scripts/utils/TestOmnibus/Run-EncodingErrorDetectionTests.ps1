<#
.SYNOPSIS
    Exécute les tests de détection des erreurs d'encodage avec TestOmnibus.
.DESCRIPTION
    Ce script exécute les tests de détection des erreurs d'encodage en utilisant
    TestOmnibus et génère un rapport HTML des résultats.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration de TestOmnibus.
.PARAMETER GenerateHtmlReport
    Indique si un rapport HTML doit être généré.
.PARAMETER ShowDetailedResults
    Indique si les résultats détaillés doivent être affichés.
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

# Vérifier que le fichier de configuration existe
if (-not (Test-Path -Path $ConfigPath)) {
    Write-Error "Le fichier de configuration n'existe pas: $ConfigPath"
    return 1
}

# Chemin vers TestOmnibus
$testOmnibusPath = Join-Path -Path $PSScriptRoot -ChildPath "Invoke-TestOmnibus.ps1"

if (-not (Test-Path -Path $testOmnibusPath)) {
    Write-Error "TestOmnibus non trouvé: $testOmnibusPath"
    return 1
}

# Charger la configuration
$config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json

# Filtrer les modules de test pour ne garder que ceux liés à la détection des erreurs d'encodage
$encodingErrorDetectionModules = $config.TestModules | Where-Object { $_.Name -eq "EncodingErrorDetection" }

if ($encodingErrorDetectionModules.Count -eq 0) {
    Write-Error "Aucun module de test de détection des erreurs d'encodage trouvé dans la configuration."
    return 1
}

# Exécuter les tests pour chaque module de détection des erreurs d'encodage
$results = @()

foreach ($module in $encodingErrorDetectionModules) {
    Write-Host "Exécution des tests pour le module $($module.Name)..." -ForegroundColor Cyan
    
    # Exécuter TestOmnibus pour ce module
    $moduleResults = & $testOmnibusPath -Path $module.Path -ConfigPath $ConfigPath
    
    # Ajouter les résultats à la liste
    $results += [PSCustomObject]@{
        Module      = $module.Name
        Success     = $moduleResults.Success
        TestsRun    = $moduleResults.TestsRun
        TestsPassed = $moduleResults.TestsPassed
        TestsFailed = $moduleResults.TestsFailed
        Duration    = $moduleResults.Duration
    }
}

# Afficher un résumé des résultats
Write-Host "`nRésumé des tests de détection des erreurs d'encodage :" -ForegroundColor Cyan
$totalTests = ($results | Measure-Object -Property TestsRun -Sum).Sum
$totalPassed = ($results | Measure-Object -Property TestsPassed -Sum).Sum
$totalFailed = ($results | Measure-Object -Property TestsFailed -Sum).Sum
$totalDuration = ($results | Measure-Object -Property Duration -Sum).Sum

Write-Host "Tests exécutés : $totalTests" -ForegroundColor White
Write-Host "Tests réussis : $totalPassed" -ForegroundColor Green
Write-Host "Tests échoués : $totalFailed" -ForegroundColor Red
Write-Host "Durée totale : $totalDuration secondes" -ForegroundColor White

# Générer un rapport HTML global si demandé
if ($GenerateHtmlReport) {
    $reportDir = Join-Path -Path $config.OutputPath -ChildPath "EncodingErrorDetection"
    
    if (-not (Test-Path -Path $reportDir)) {
        New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
    }
    
    $reportPath = Join-Path -Path $reportDir -ChildPath "EncodingErrorDetection-GlobalReport.html"
    
    # Créer un rapport HTML simple
    $htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport global - Tests de détection des erreurs d'encodage</title>
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
    <h1>Rapport global - Tests de détection des erreurs d'encodage</h1>
    
    <div class="summary">
        <h2>Résumé</h2>
        <p>Tests exécutés : $totalTests</p>
        <p>Tests réussis : <span class="success">$totalPassed</span></p>
        <p>Tests échoués : <span class="failure">$totalFailed</span></p>
        <p>Durée totale : $totalDuration secondes</p>
    </div>
    
    <h2>Détails par module</h2>
    <table>
        <tr>
            <th>Module</th>
            <th>Tests exécutés</th>
            <th>Tests réussis</th>
            <th>Tests échoués</th>
            <th>Durée (s)</th>
            <th>Statut</th>
        </tr>
"@

    foreach ($result in $results) {
        $rowClass = if ($result.Success) { 'success-row' } else { 'failure-row' }
        $status = if ($result.Success) { 'Succès' } else { 'Échec' }
        
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
        <li>Exécuter régulièrement les tests de détection des erreurs d'encodage pour identifier les problèmes potentiels.</li>
        <li>Utiliser l'outil de correction automatique des problèmes d'encodage pour résoudre les problèmes identifiés.</li>
        <li>Configurer les éditeurs de code pour utiliser UTF-8 avec BOM pour les fichiers PowerShell.</li>
    </ul>
</body>
</html>
"@

    # Enregistrer le rapport HTML
    $htmlReport | Out-File -FilePath $reportPath -Encoding utf8
    Write-Host "Rapport HTML global généré : $reportPath" -ForegroundColor Green
}

# Retourner les résultats
return [PSCustomObject]@{
    TotalCount   = $totalTests
    PassedCount  = $totalPassed
    FailedCount  = $totalFailed
    Duration     = $totalDuration
    Results      = $results
    ReportPath   = if ($GenerateHtmlReport) { $reportPath } else { $null }
}
