<#
.SYNOPSIS
    Exécute tous les tests unitaires pour le système de cache prédictif.
.DESCRIPTION
    Ce script exécute tous les tests unitaires pour le système de cache prédictif
    et génère un rapport de couverture de code.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 12/04/2025
#>

# Importer Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -MinimumVersion 5.0

# Importer le module de types simulés
$mockTypesPath = Join-Path -Path $PSScriptRoot -ChildPath "MockTypes.psm1"
Import-Module $mockTypesPath -Force

# Définir le répertoire des tests
$testDirectory = $PSScriptRoot
$moduleDirectory = Split-Path -Path $testDirectory -Parent

# Créer le répertoire de rapport s'il n'existe pas
$reportDirectory = Join-Path -Path $testDirectory -ChildPath "Reports"
if (-not (Test-Path -Path $reportDirectory)) {
    New-Item -Path $reportDirectory -ItemType Directory -Force | Out-Null
}

# Configurer les options de Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $testDirectory
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = 'Detailed'
$pesterConfig.CodeCoverage.Enabled = $true
$pesterConfig.CodeCoverage.Path = Join-Path -Path $moduleDirectory -ChildPath "*.psm1"
$pesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'
$pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $reportDirectory -ChildPath "coverage.xml"
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputFormat = 'NUnitXml'
$pesterConfig.TestResult.OutputPath = Join-Path -Path $reportDirectory -ChildPath "testResults.xml"

# Exécuter les tests avec analyse de couverture
Write-Host "Exécution des tests avec analyse de couverture..." -ForegroundColor Cyan
$testResults = Invoke-Pester -Configuration $pesterConfig

# Analyser les résultats de couverture
$coverageReport = [xml](Get-Content -Path $pesterConfig.CodeCoverage.OutputPath -ErrorAction SilentlyContinue)

if ($null -ne $coverageReport) {
    # Extraire les statistiques de couverture
    $packages = $coverageReport.report.package
    $totalLines = 0
    $coveredLines = 0
    $uncoveredFunctions = @()

    foreach ($package in $packages) {
        foreach ($class in $package.class) {
            $className = $class.name -replace ".*\\", ""

            foreach ($method in $class.method) {
                $methodName = $method.name
                $methodLines = [int]$method.line.count
                $methodCovered = ($method.line | Where-Object { [int]$_.ci -gt 0 }).Count
                $methodCoverage = if ($methodLines -gt 0) { $methodCovered / $methodLines } else { 1 }

                $totalLines += $methodLines
                $coveredLines += $methodCovered

                # Ajouter à la liste des fonctions non couvertes si la couverture est inférieure à 100%
                if ($methodCoverage -lt 1) {
                    $uncoveredFunctions += [PSCustomObject]@{
                        Module   = $className
                        Function = $methodName
                        Lines    = $methodLines
                        Covered  = $methodCovered
                        Coverage = [Math]::Round($methodCoverage * 100, 2)
                    }
                }
            }
        }
    }

    # Calculer la couverture globale
    $totalCoverage = if ($totalLines -gt 0) { $coveredLines / $totalLines } else { 0 }

    # Générer un rapport HTML
    $htmlReportPath = Join-Path -Path $reportDirectory -ChildPath "coverage_report.html"
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de couverture de code - Cache Prédictif</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #333; }
        .summary { background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
        .good { color: green; }
        .warning { color: orange; }
        .bad { color: red; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .progress-bar-container { width: 100%; background-color: #e0e0e0; border-radius: 4px; }
        .progress-bar { height: 20px; border-radius: 4px; }
        .tests-summary { display: flex; justify-content: space-between; }
        .test-stat { flex: 1; margin: 10px; padding: 15px; border-radius: 5px; text-align: center; }
        .passed { background-color: #dff0d8; }
        .failed { background-color: #f2dede; }
        .skipped { background-color: #fcf8e3; }
    </style>
</head>
<body>
    <h1>Rapport de couverture de code - Cache Prédictif</h1>

    <div class="tests-summary">
        <div class="test-stat passed">
            <h3>Tests réussis</h3>
            <p>$($testResults.PassedCount)</p>
        </div>
        <div class="test-stat failed">
            <h3>Tests échoués</h3>
            <p>$($testResults.FailedCount)</p>
        </div>
        <div class="test-stat skipped">
            <h3>Tests ignorés</h3>
            <p>$($testResults.SkippedCount)</p>
        </div>
    </div>

    <div class="summary">
        <h2>Résumé de la couverture</h2>
        <p>Lignes totales: $totalLines</p>
        <p>Lignes couvertes: $coveredLines</p>
        <p>Couverture globale: <span class="$(if ($totalCoverage -ge 0.9) { 'good' } elseif ($totalCoverage -ge 0.7) { 'warning' } else { 'bad' })">$([Math]::Round($totalCoverage * 100, 2))%</span></p>

        <div class="progress-bar-container">
            <div class="progress-bar" style="width: $([Math]::Round($totalCoverage * 100))%; background-color: $(if ($totalCoverage -ge 0.9) { '#4CAF50' } elseif ($totalCoverage -ge 0.7) { '#FF9800' } else { '#F44336' });"></div>
        </div>
    </div>

    <h2>Fonctions non couvertes à 100%</h2>
"@

    if ($uncoveredFunctions.Count -gt 0) {
        $htmlContent += @"
    <table>
        <tr>
            <th>Module</th>
            <th>Fonction</th>
            <th>Lignes</th>
            <th>Couvertes</th>
            <th>Couverture</th>
        </tr>
"@

        foreach ($function in ($uncoveredFunctions | Sort-Object -Property Coverage)) {
            $coverageClass = if ($function.Coverage -ge 90) { 'good' } elseif ($function.Coverage -ge 70) { 'warning' } else { 'bad' }

            $htmlContent += @"
        <tr>
            <td>$($function.Module)</td>
            <td>$($function.Function)</td>
            <td>$($function.Lines)</td>
            <td>$($function.Covered)</td>
            <td class="$coverageClass">$($function.Coverage)%</td>
        </tr>
"@
        }

        $htmlContent += @"
    </table>
"@
    } else {
        $htmlContent += @"
    <p class="good">Toutes les fonctions sont couvertes à 100% !</p>
"@
    }

    $htmlContent += @"

    <h2>Recommandations pour améliorer la couverture</h2>
    <ul>
"@

    if ($uncoveredFunctions.Count -gt 0) {
        # Générer des recommandations spécifiques pour les fonctions les moins couvertes
        foreach ($function in ($uncoveredFunctions | Sort-Object -Property Coverage | Select-Object -First 5)) {
            $htmlContent += @"
        <li>Ajouter des tests pour la fonction <strong>$($function.Function)</strong> dans le module <strong>$($function.Module)</strong> (couverture actuelle: $($function.Coverage)%)</li>
"@
        }
    } else {
        $htmlContent += @"
        <li>Maintenir la couverture à 100% lors de l'ajout de nouvelles fonctionnalités</li>
        <li>Ajouter des tests pour les cas limites et les scénarios d'erreur</li>
"@
    }

    $htmlContent += @"
    </ul>

    <h2>Prochaines étapes</h2>
    <ul>
        <li>Intégrer les tests au système TestOmnibus</li>
        <li>Automatiser l'exécution des tests dans le pipeline CI/CD</li>
        <li>Mettre en place une alerte en cas de baisse de la couverture</li>
    </ul>

    <p><em>Rapport généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</em></p>
</body>
</html>
"@

    # Enregistrer le rapport HTML
    $htmlContent | Out-File -FilePath $htmlReportPath -Encoding utf8

    # Afficher un résumé
    Write-Host "`nRésumé de la couverture de code:" -ForegroundColor Cyan
    Write-Host "Lignes totales: $totalLines" -ForegroundColor White
    Write-Host "Lignes couvertes: $coveredLines" -ForegroundColor White
    Write-Host "Couverture globale: $([Math]::Round($totalCoverage * 100, 2))%" -ForegroundColor $(if ($totalCoverage -ge 0.9) { 'Green' } elseif ($totalCoverage -ge 0.7) { 'Yellow' } else { 'Red' })

    if ($uncoveredFunctions.Count -gt 0) {
        Write-Host "`nFonctions non couvertes à 100%:" -ForegroundColor Yellow
        $uncoveredFunctions | Sort-Object -Property Coverage | Format-Table -AutoSize
    } else {
        Write-Host "`nToutes les fonctions sont couvertes à 100% !" -ForegroundColor Green
    }

    Write-Host "`nRapports générés:" -ForegroundColor Cyan
    Write-Host "Rapport XML: $($pesterConfig.CodeCoverage.OutputPath)" -ForegroundColor White
    Write-Host "Rapport HTML: $htmlReportPath" -ForegroundColor White

    # Ouvrir le rapport HTML
    if (Test-Path -Path $htmlReportPath) {
        Write-Host "`nOuverture du rapport HTML..." -ForegroundColor Cyan
        Start-Process $htmlReportPath
    }
} else {
    Write-Warning "Aucun rapport de couverture n'a été généré."
}

# Afficher un résumé des résultats des tests
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "Tests exécutés: $($testResults.TotalCount)" -ForegroundColor White
Write-Host "Tests réussis: $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "Tests échoués: $($testResults.FailedCount)" -ForegroundColor Red
Write-Host "Tests ignorés: $($testResults.SkippedCount)" -ForegroundColor Yellow
Write-Host "Durée totale: $([Math]::Round($testResults.Duration.TotalSeconds, 2)) secondes" -ForegroundColor White

# Retourner le code de sortie en fonction des résultats
exit $testResults.FailedCount
