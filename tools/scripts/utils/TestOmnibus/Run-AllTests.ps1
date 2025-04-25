<#
.SYNOPSIS
    Exécute tous les tests unitaires avec TestOmnibus.
.DESCRIPTION
    Ce script exécute tous les tests unitaires configurés dans TestOmnibus
    et génère un rapport global des résultats.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration de TestOmnibus.
.PARAMETER GenerateHtmlReport
    Génère un rapport HTML des résultats.
.PARAMETER ShowDetailedResults
    Affiche les résultats détaillés des tests.
.EXAMPLE
    .\Run-AllTests.ps1 -GenerateHtmlReport
.NOTES
    Auteur: Augment Agent
    Date: 2025-04-12
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

# Définir l'encodage de la console en UTF-8
$OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

# Exécuter les tests pour chaque module
$results = @()

foreach ($module in $config.TestModules) {
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
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
$totalTests = ($results | Measure-Object -Property TestsRun -Sum).Sum
$totalPassed = ($results | Measure-Object -Property TestsPassed -Sum).Sum
$totalFailed = ($results | Measure-Object -Property TestsFailed -Sum).Sum
$totalDuration = ($results | Measure-Object -Property Duration -Sum).Sum

Write-Host "  Tests exécutés: $totalTests" -ForegroundColor White
Write-Host "  Tests réussis: $totalPassed" -ForegroundColor Green
Write-Host "  Tests échoués: $totalFailed" -ForegroundColor Red
Write-Host "  Durée totale: $([math]::Round($totalDuration / 1000, 2)) secondes" -ForegroundColor White

# Afficher les résultats par module
Write-Host "`nRésultats par module:" -ForegroundColor Cyan
$results | ForEach-Object {
    $color = if ($_.Success) { "Green" } else { "Red" }
    Write-Host "  $($_.Module): $($_.TestsPassed)/$($_.TestsRun) tests réussis" -ForegroundColor $color
}

# Générer un rapport HTML global si demandé
if ($GenerateHtmlReport) {
    $reportPath = Join-Path -Path $config.OutputPath -ChildPath "GlobalTestReport.html"
    
    # Créer un rapport HTML simple
    $htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport global des tests</title>
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
    <h1>Rapport global des tests</h1>
    <div class="summary">
        <p>Tests exécutés: $totalTests</p>
        <p>Tests réussis: <span class="success">$totalPassed</span></p>
        <p>Tests échoués: <span class="failure">$totalFailed</span></p>
        <p>Durée totale: $([math]::Round($totalDuration / 1000, 2)) secondes</p>
    </div>
    <h2>Résultats par module</h2>
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
        $status = if ($result.Success) { 
            "<span class='success'>Réussi</span>" 
        } else { 
            "<span class='failure'>Échoué</span>" 
        }
        
        $htmlReport += @"
        <tr>
            <td>$($result.Module)</td>
            <td>$($result.TestsRun)</td>
            <td>$($result.TestsPassed)</td>
            <td>$($result.TestsFailed)</td>
            <td>$([math]::Round($result.Duration / 1000, 2))</td>
            <td>$status</td>
        </tr>
"@
    }

    $htmlReport += @"
    </table>
</body>
</html>
"@

    $htmlReport | Out-File -FilePath $reportPath -Encoding utf8
    Write-Host "`nRapport HTML global généré: $reportPath" -ForegroundColor Green
}

# Retourner un code de sortie
if ($totalFailed -gt 0) {
    return 1
} else {
    return 0
}
