# Importer le module
Import-Module .\development\scripts\statistics\ResolutionRecommendations.psm1 -Force

# Test 1: Valeurs critiques pour le coefficient d'asymétrie avec un échantillon moyen
Write-Host "`n=== Test 1: Valeurs critiques pour le coefficient d'asymétrie avec un échantillon moyen ===" -ForegroundColor Magenta
$mediumSampleSkewness = Get-SkewnessThreshold -SampleSize 200 -ConfidenceLevel "95%" -Application "Analyse statistique" -Direction "Bidirectionnelle"
Write-Host "Taille d'échantillon: $($mediumSampleSkewness.SampleSize) (Catégorie: $($mediumSampleSkewness.SizeCategory))" -ForegroundColor White
Write-Host "Niveau de confiance: $($mediumSampleSkewness.ConfidenceLevel)" -ForegroundColor White
Write-Host "Application: $($mediumSampleSkewness.Application)" -ForegroundColor White
Write-Host "Direction: $($mediumSampleSkewness.Direction)" -ForegroundColor White
Write-Host "Seuil de base par taille d'échantillon: $($mediumSampleSkewness.BaseThresholdCategory) ($($mediumSampleSkewness.BaseThreshold))" -ForegroundColor White
Write-Host "Facteur d'ajustement pour cette taille d'échantillon: $($mediumSampleSkewness.SizeAdjustmentFactor)" -ForegroundColor White
Write-Host "Seuil par niveau de confiance: $($mediumSampleSkewness.ConfidenceThresholdCategory) ($($mediumSampleSkewness.ConfidenceThreshold))" -ForegroundColor White
Write-Host "Seuil par application: $($mediumSampleSkewness.ApplicationThresholdCategory) ($($mediumSampleSkewness.ApplicationThreshold))" -ForegroundColor White
Write-Host "Seuil final: $($mediumSampleSkewness.FinalThreshold) ($($mediumSampleSkewness.FinalThresholdCategory))" -ForegroundColor Green
Write-Host "Seuil positif: $($mediumSampleSkewness.PositiveThreshold)" -ForegroundColor Green
Write-Host "Seuil négatif: $($mediumSampleSkewness.NegativeThreshold)" -ForegroundColor Green
Write-Host "Erreur standard: $([Math]::Round($mediumSampleSkewness.StandardError, 3))" -ForegroundColor White
Write-Host "Intervalle de confiance à 95%: ±$([Math]::Round($mediumSampleSkewness.ConfidenceInterval95, 2))" -ForegroundColor White
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $mediumSampleSkewness.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 2: Valeurs critiques pour le coefficient d'asymétrie avec un petit échantillon
Write-Host "`n=== Test 2: Valeurs critiques pour le coefficient d'asymétrie avec un petit échantillon ===" -ForegroundColor Magenta
$smallSampleSkewness = Get-SkewnessThreshold -SampleSize 25 -ConfidenceLevel "99%" -Application "Détection d'anomalies" -Direction "Positive"
Write-Host "Taille d'échantillon: $($smallSampleSkewness.SampleSize) (Catégorie: $($smallSampleSkewness.SizeCategory))" -ForegroundColor White
Write-Host "Niveau de confiance: $($smallSampleSkewness.ConfidenceLevel)" -ForegroundColor White
Write-Host "Application: $($smallSampleSkewness.Application)" -ForegroundColor White
Write-Host "Direction: $($smallSampleSkewness.Direction)" -ForegroundColor White
Write-Host "Seuil de base par taille d'échantillon: $($smallSampleSkewness.BaseThresholdCategory) ($($smallSampleSkewness.BaseThreshold))" -ForegroundColor White
Write-Host "Facteur d'ajustement pour cette taille d'échantillon: $($smallSampleSkewness.SizeAdjustmentFactor)" -ForegroundColor White
Write-Host "Seuil par niveau de confiance: $($smallSampleSkewness.ConfidenceThresholdCategory) ($($smallSampleSkewness.ConfidenceThreshold))" -ForegroundColor White
Write-Host "Seuil par application: $($smallSampleSkewness.ApplicationThresholdCategory) ($($smallSampleSkewness.ApplicationThreshold))" -ForegroundColor White
Write-Host "Seuil final: $($smallSampleSkewness.FinalThreshold) ($($smallSampleSkewness.FinalThresholdCategory))" -ForegroundColor Green
Write-Host "Seuil positif: $($smallSampleSkewness.PositiveThreshold)" -ForegroundColor Green
Write-Host "Seuil négatif: $($smallSampleSkewness.NegativeThreshold)" -ForegroundColor Green
Write-Host "Erreur standard: $([Math]::Round($smallSampleSkewness.StandardError, 3))" -ForegroundColor White
Write-Host "Intervalle de confiance à 95%: ±$([Math]::Round($smallSampleSkewness.ConfidenceInterval95, 2))" -ForegroundColor White
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $smallSampleSkewness.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 3: Rapport de valeurs critiques pour le coefficient d'asymétrie au format texte
Write-Host "`n=== Test 3: Rapport de valeurs critiques pour le coefficient d'asymétrie au format texte ===" -ForegroundColor Magenta
$skewnessReport = Get-SkewnessThresholdReport -ConfidenceLevel "95%" -Direction "Bidirectionnelle" -Format "Text"
Write-Host $skewnessReport -ForegroundColor White

# Test 4: Rapport de valeurs critiques pour le coefficient d'asymétrie au format HTML
Write-Host "`n=== Test 4: Rapport de valeurs critiques pour le coefficient d'asymétrie au format HTML ===" -ForegroundColor Magenta
$htmlSkewnessReport = Get-SkewnessThresholdReport -ConfidenceLevel "95%" -Direction "Bidirectionnelle" -Format "HTML"
$htmlSkewnessFilePath = Join-Path -Path $PSScriptRoot -ChildPath "SkewnessThresholdReport.html"
Set-Content -Path $htmlSkewnessFilePath -Value $htmlSkewnessReport -Encoding UTF8
Write-Host "Le rapport au format HTML a été sauvegardé dans le fichier: $htmlSkewnessFilePath" -ForegroundColor Green

# Résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
Write-Host "Tous les tests ont été exécutés." -ForegroundColor Green
Write-Host "Vérifiez les résultats pour vous assurer que les recommandations de valeurs critiques sont appropriées." -ForegroundColor Green
Write-Host "Les rapports HTML ont été générés et sauvegardés dans le dossier du script." -ForegroundColor Green
