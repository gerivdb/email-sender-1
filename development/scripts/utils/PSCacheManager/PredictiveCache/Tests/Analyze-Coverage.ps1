<#
.SYNOPSIS
    Analyse la couverture de code des tests du cache prÃ©dictif.
.DESCRIPTION
    Ce script analyse la couverture de code des tests du cache prÃ©dictif
    et gÃ©nÃ¨re un rapport dÃ©taillÃ©.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 12/04/2025
#>

# Importer Pester si nÃ©cessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -MinimumVersion 5.0

# DÃ©finir le rÃ©pertoire des tests et des modules
$testDirectory = $PSScriptRoot
$moduleDirectory = Split-Path -Path $testDirectory -Parent

# CrÃ©er le rÃ©pertoire de rapport s'il n'existe pas
$reportDirectory = Join-Path -Path $testDirectory -ChildPath "Reports"
if (-not (Test-Path -Path $reportDirectory)) {
    New-Item -Path $reportDirectory -ItemType Directory -Force | Out-Null
}

# Configurer les options de Pester pour l'analyse de couverture
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

# ExÃ©cuter les tests avec analyse de couverture
Write-Host "ExÃ©cution des tests avec analyse de couverture..." -ForegroundColor Cyan
$testResults = Invoke-Pester -Configuration $pesterConfig

# Analyser les rÃ©sultats de couverture
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
                
                # Ajouter Ã  la liste des fonctions non couvertes si la couverture est infÃ©rieure Ã  100%
                if ($methodCoverage -lt 1) {
                    $uncoveredFunctions += [PSCustomObject]@{
                        Module = $className
                        Function = $methodName
                        Lines = $methodLines
                        Covered = $methodCovered
                        Coverage = [Math]::Round($methodCoverage * 100, 2)
                    }
                }
            }
        }
    }
    
    # Calculer la couverture globale
    $totalCoverage = if ($totalLines -gt 0) { $coveredLines / $totalLines } else { 0 }
    
    # GÃ©nÃ©rer un rapport HTML
    $htmlReportPath = Join-Path -Path $reportDirectory -ChildPath "coverage_report.html"
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de couverture de code - Cache PrÃ©dictif</title>
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
    <h1>Rapport de couverture de code - Cache PrÃ©dictif</h1>
    
    <div class="tests-summary">
        <div class="test-stat passed">
            <h3>Tests rÃ©ussis</h3>
            <p>$($testResults.PassedCount)</p>
        </div>
        <div class="test-stat failed">
            <h3>Tests Ã©chouÃ©s</h3>
            <p>$($testResults.FailedCount)</p>
        </div>
        <div class="test-stat skipped">
            <h3>Tests ignorÃ©s</h3>
            <p>$($testResults.SkippedCount)</p>
        </div>
    </div>
    
    <div class="summary">
        <h2>RÃ©sumÃ© de la couverture</h2>
        <p>Lignes totales: $totalLines</p>
        <p>Lignes couvertes: $coveredLines</p>
        <p>Couverture globale: <span class="$(if ($totalCoverage -ge 0.9) { 'good' } elseif ($totalCoverage -ge 0.7) { 'warning' } else { 'bad' })">$([Math]::Round($totalCoverage * 100, 2))%</span></p>
        
        <div class="progress-bar-container">
            <div class="progress-bar" style="width: $([Math]::Round($totalCoverage * 100))%; background-color: $(if ($totalCoverage -ge 0.9) { '#4CAF50' } elseif ($totalCoverage -ge 0.7) { '#FF9800' } else { '#F44336' });"></div>
        </div>
    </div>
    
    <h2>Fonctions non couvertes Ã  100%</h2>
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
    <p class="good">Toutes les fonctions sont couvertes Ã  100% !</p>
"@
    }

    $htmlContent += @"
    
    <h2>Recommandations pour amÃ©liorer la couverture</h2>
    <ul>
"@

    if ($uncoveredFunctions.Count -gt 0) {
        # GÃ©nÃ©rer des recommandations spÃ©cifiques pour les fonctions les moins couvertes
        foreach ($function in ($uncoveredFunctions | Sort-Object -Property Coverage | Select-Object -First 5)) {
            $htmlContent += @"
        <li>Ajouter des tests pour la fonction <strong>$($function.Function)</strong> dans le module <strong>$($function.Module)</strong> (couverture actuelle: $($function.Coverage)%)</li>
"@
        }
    } else {
        $htmlContent += @"
        <li>Maintenir la couverture Ã  100% lors de l'ajout de nouvelles fonctionnalitÃ©s</li>
        <li>Ajouter des tests pour les cas limites et les scÃ©narios d'erreur</li>
"@
    }

    $htmlContent += @"
    </ul>
    
    <h2>Prochaines Ã©tapes</h2>
    <ul>
        <li>IntÃ©grer les tests au systÃ¨me TestOmnibus</li>
        <li>Automatiser l'exÃ©cution des tests dans le pipeline CI/CD</li>
        <li>Mettre en place une alerte en cas de baisse de la couverture</li>
    </ul>
    
    <p><em>Rapport gÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</em></p>
</body>
</html>
"@

    # Enregistrer le rapport HTML
    $htmlContent | Out-File -FilePath $htmlReportPath -Encoding utf8
    
    # Afficher un rÃ©sumÃ©
    Write-Host "`nRÃ©sumÃ© de la couverture de code:" -ForegroundColor Cyan
    Write-Host "Lignes totales: $totalLines" -ForegroundColor White
    Write-Host "Lignes couvertes: $coveredLines" -ForegroundColor White
    Write-Host "Couverture globale: $([Math]::Round($totalCoverage * 100, 2))%" -ForegroundColor $(if ($totalCoverage -ge 0.9) { 'Green' } elseif ($totalCoverage -ge 0.7) { 'Yellow' } else { 'Red' })
    
    if ($uncoveredFunctions.Count -gt 0) {
        Write-Host "`nFonctions non couvertes Ã  100%:" -ForegroundColor Yellow
        $uncoveredFunctions | Sort-Object -Property Coverage | Format-Table -AutoSize
    } else {
        Write-Host "`nToutes les fonctions sont couvertes Ã  100% !" -ForegroundColor Green
    }
    
    Write-Host "`nRapports gÃ©nÃ©rÃ©s:" -ForegroundColor Cyan
    Write-Host "Rapport XML: $($pesterConfig.CodeCoverage.OutputPath)" -ForegroundColor White
    Write-Host "Rapport HTML: $htmlReportPath" -ForegroundColor White
    
    # Ouvrir le rapport HTML
    if (Test-Path -Path $htmlReportPath) {
        Write-Host "`nOuverture du rapport HTML..." -ForegroundColor Cyan
        Start-Process $htmlReportPath
    }
} else {
    Write-Warning "Aucun rapport de couverture n'a Ã©tÃ© gÃ©nÃ©rÃ©."
}

# Retourner le code de sortie en fonction des rÃ©sultats
exit $testResults.FailedCount
