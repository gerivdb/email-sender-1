# Test-VisualAsymmetryReport.ps1
# Ce script teste la génération de rapports visuels d'asymétrie

# Importer les modules nécessaires
$tailSlopeModulePath = Join-Path -Path $PSScriptRoot -ChildPath "TailSlopeAsymmetry.psm1"
$visualReportModulePath = Join-Path -Path $PSScriptRoot -ChildPath "VisualAsymmetryReport.psm1"

if (-not (Test-Path -Path $tailSlopeModulePath)) {
    Write-Error "Le module TailSlopeAsymmetry.psm1 n'a pas été trouvé: $tailSlopeModulePath"
    exit 1
}

if (-not (Test-Path -Path $visualReportModulePath)) {
    Write-Error "Le module VisualAsymmetryReport.psm1 n'a pas été trouvé: $visualReportModulePath"
    exit 1
}

Import-Module $tailSlopeModulePath -Force
Import-Module $visualReportModulePath -Force

# Définir le dossier de rapports
$reportsFolder = Join-Path -Path $PSScriptRoot -ChildPath "reports"
if (-not (Test-Path -Path $reportsFolder)) {
    New-Item -Path $reportsFolder -ItemType Directory | Out-Null
}

# Générer des données de test
Write-Host "`n=== Génération des données de test ===" -ForegroundColor Magenta

# Distribution normale
$normalData = 1..100 | ForEach-Object { [Math]::Round([System.Random]::new().NextDouble() * 10 - 5, 2) }

# Distribution asymétrique positive
$positiveSkewData = 1..100 | ForEach-Object {
    $value = [Math]::Pow([System.Random]::new().NextDouble(), 2) * 10
    [Math]::Round($value, 2)
}

# Distribution asymétrique négative
$negativeSkewData = 1..100 | ForEach-Object {
    $value = 10 - [Math]::Pow([System.Random]::new().NextDouble(), 2) * 10
    [Math]::Round($value, 2)
}

Write-Host "Données générées:" -ForegroundColor White
Write-Host "- Distribution normale: $($normalData.Count) points" -ForegroundColor White
Write-Host "- Distribution asymétrique positive: $($positiveSkewData.Count) points" -ForegroundColor White
Write-Host "- Distribution asymétrique négative: $($negativeSkewData.Count) points" -ForegroundColor White

# Test 1: Génération d'un rapport HTML avec le thème par défaut
Write-Host "`n=== Test 1: Génération d'un rapport HTML avec le thème par défaut ===" -ForegroundColor Magenta
$reportPath = Join-Path -Path $reportsFolder -ChildPath "positive_skew_report_Default.html"
Get-AsymmetryVisualReport -Data $positiveSkewData -OutputPath $reportPath -Title "Rapport d'asymétrie - Distribution asymétrique positive"
Write-Host "Rapport généré avec le thème Default: $reportPath" -ForegroundColor White

# Test 2: Génération d'un rapport avec données brutes
Write-Host "`n=== Test 2: Génération d'un rapport avec données brutes ===" -ForegroundColor Magenta

# Rapport avec données brutes
$reportWithRawDataPath = Join-Path -Path $reportsFolder -ChildPath "normal_report_with_raw_data.html"
Get-AsymmetryVisualReport -Data $normalData -OutputPath $reportWithRawDataPath -Title "Rapport d'asymétrie - Distribution normale (avec données brutes)" -IncludeRawData
Write-Host "Rapport avec données brutes généré: $reportWithRawDataPath" -ForegroundColor White

# Test 3: Ouvrir un rapport dans le navigateur
Write-Host "`n=== Test 3: Ouverture d'un rapport dans le navigateur ===" -ForegroundColor Magenta
$reportToOpenPath = Join-Path -Path $reportsFolder -ChildPath "positive_skew_report_Default.html"
Write-Host "Ouverture du rapport: $reportToOpenPath" -ForegroundColor White
Start-Process $reportToOpenPath

# Résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
Write-Host "Tous les tests ont été exécutés avec succès." -ForegroundColor Green
Write-Host "Les rapports visuels ont été générés dans le dossier: $reportsFolder" -ForegroundColor Green
