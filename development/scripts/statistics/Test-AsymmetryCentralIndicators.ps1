# Importer le module
Import-Module .\development\scripts\statistics\ResolutionRecommendations.psm1 -Force

# Test 1: Évaluation de l'asymétrie avec une différence positive entre moyenne et médiane
Write-Host "`n=== Test 1: Évaluation de l'asymétrie avec une différence positive entre moyenne et médiane ===" -ForegroundColor Magenta
$positiveAsymmetry = Get-AsymmetryCentralIndicators -Mean 105.0 -Median 100.0 -StandardDeviation 10.0 -SampleSize 200 -ConfidenceLevel "95%"
Write-Host "Moyenne: $($positiveAsymmetry.Mean)" -ForegroundColor White
Write-Host "Médiane: $($positiveAsymmetry.Median)" -ForegroundColor White
Write-Host "Écart-type: $($positiveAsymmetry.StandardDeviation)" -ForegroundColor White
Write-Host "Taille d'échantillon: $($positiveAsymmetry.SampleSize)" -ForegroundColor White
Write-Host "Niveau de confiance: $($positiveAsymmetry.ConfidenceLevel)" -ForegroundColor White
Write-Host "Différence moyenne-médiane: $([Math]::Round($positiveAsymmetry.MeanMedianDifference, 2))" -ForegroundColor Green
Write-Host "Différence normalisée: $([Math]::Round($positiveAsymmetry.NormalizedDifference, 2)) écarts-types" -ForegroundColor Green
Write-Host "Coefficient de Pearson: $([Math]::Round($positiveAsymmetry.PearsonCoefficient, 2))" -ForegroundColor White
Write-Host "Z-score: $([Math]::Round($positiveAsymmetry.ZScore, 2))" -ForegroundColor White
Write-Host "Valeur critique (95%): $($positiveAsymmetry.CriticalValue)" -ForegroundColor White
Write-Host "Statistiquement significatif: $($positiveAsymmetry.IsSignificant)" -ForegroundColor Green
Write-Host "Direction de l'asymétrie: $($positiveAsymmetry.SkewnessDirection)" -ForegroundColor Green
Write-Host "Intensité de l'asymétrie: $($positiveAsymmetry.SkewnessIntensity)" -ForegroundColor Green
Write-Host "Intervalle de confiance: [$([Math]::Round($positiveAsymmetry.ConfidenceIntervalLower, 2)), $([Math]::Round($positiveAsymmetry.ConfidenceIntervalUpper, 2))]" -ForegroundColor White
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $positiveAsymmetry.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 2: Évaluation de l'asymétrie avec une différence négative entre moyenne et médiane
Write-Host "`n=== Test 2: Évaluation de l'asymétrie avec une différence négative entre moyenne et médiane ===" -ForegroundColor Magenta
$negativeAsymmetry = Get-AsymmetryCentralIndicators -Mean 95.0 -Median 100.0 -StandardDeviation 10.0 -SampleSize 200 -ConfidenceLevel "95%"
Write-Host "Moyenne: $($negativeAsymmetry.Mean)" -ForegroundColor White
Write-Host "Médiane: $($negativeAsymmetry.Median)" -ForegroundColor White
Write-Host "Écart-type: $($negativeAsymmetry.StandardDeviation)" -ForegroundColor White
Write-Host "Taille d'échantillon: $($negativeAsymmetry.SampleSize)" -ForegroundColor White
Write-Host "Niveau de confiance: $($negativeAsymmetry.ConfidenceLevel)" -ForegroundColor White
Write-Host "Différence moyenne-médiane: $([Math]::Round($negativeAsymmetry.MeanMedianDifference, 2))" -ForegroundColor Green
Write-Host "Différence normalisée: $([Math]::Round($negativeAsymmetry.NormalizedDifference, 2)) écarts-types" -ForegroundColor Green
Write-Host "Coefficient de Pearson: $([Math]::Round($negativeAsymmetry.PearsonCoefficient, 2))" -ForegroundColor White
Write-Host "Z-score: $([Math]::Round($negativeAsymmetry.ZScore, 2))" -ForegroundColor White
Write-Host "Valeur critique (95%): $($negativeAsymmetry.CriticalValue)" -ForegroundColor White
Write-Host "Statistiquement significatif: $($negativeAsymmetry.IsSignificant)" -ForegroundColor Green
Write-Host "Direction de l'asymétrie: $($negativeAsymmetry.SkewnessDirection)" -ForegroundColor Green
Write-Host "Intensité de l'asymétrie: $($negativeAsymmetry.SkewnessIntensity)" -ForegroundColor Green
Write-Host "Intervalle de confiance: [$([Math]::Round($negativeAsymmetry.ConfidenceIntervalLower, 2)), $([Math]::Round($negativeAsymmetry.ConfidenceIntervalUpper, 2))]" -ForegroundColor White
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $negativeAsymmetry.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 3: Évaluation de l'asymétrie avec une différence non significative entre moyenne et médiane
Write-Host "`n=== Test 3: Évaluation de l'asymétrie avec une différence non significative entre moyenne et médiane ===" -ForegroundColor Magenta
$nonSignificantAsymmetry = Get-AsymmetryCentralIndicators -Mean 100.5 -Median 100.0 -StandardDeviation 10.0 -SampleSize 200 -ConfidenceLevel "95%"
Write-Host "Moyenne: $($nonSignificantAsymmetry.Mean)" -ForegroundColor White
Write-Host "Médiane: $($nonSignificantAsymmetry.Median)" -ForegroundColor White
Write-Host "Écart-type: $($nonSignificantAsymmetry.StandardDeviation)" -ForegroundColor White
Write-Host "Taille d'échantillon: $($nonSignificantAsymmetry.SampleSize)" -ForegroundColor White
Write-Host "Niveau de confiance: $($nonSignificantAsymmetry.ConfidenceLevel)" -ForegroundColor White
Write-Host "Différence moyenne-médiane: $([Math]::Round($nonSignificantAsymmetry.MeanMedianDifference, 2))" -ForegroundColor Green
Write-Host "Différence normalisée: $([Math]::Round($nonSignificantAsymmetry.NormalizedDifference, 2)) écarts-types" -ForegroundColor Green
Write-Host "Coefficient de Pearson: $([Math]::Round($nonSignificantAsymmetry.PearsonCoefficient, 2))" -ForegroundColor White
Write-Host "Z-score: $([Math]::Round($nonSignificantAsymmetry.ZScore, 2))" -ForegroundColor White
Write-Host "Valeur critique (95%): $($nonSignificantAsymmetry.CriticalValue)" -ForegroundColor White
Write-Host "Statistiquement significatif: $($nonSignificantAsymmetry.IsSignificant)" -ForegroundColor Green
Write-Host "Direction de l'asymétrie: $($nonSignificantAsymmetry.SkewnessDirection)" -ForegroundColor Green
Write-Host "Intensité de l'asymétrie: $($nonSignificantAsymmetry.SkewnessIntensity)" -ForegroundColor Green
Write-Host "Intervalle de confiance: [$([Math]::Round($nonSignificantAsymmetry.ConfidenceIntervalLower, 2)), $([Math]::Round($nonSignificantAsymmetry.ConfidenceIntervalUpper, 2))]" -ForegroundColor White
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $nonSignificantAsymmetry.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 4: Rapport d'évaluation de l'asymétrie au format texte
Write-Host "`n=== Test 4: Rapport d'évaluation de l'asymétrie au format texte ===" -ForegroundColor Magenta
$asymmetryReport = Get-AsymmetryCentralIndicatorsReport -StandardDeviation 10.0 -SampleSize 200 -ConfidenceLevel "95%" -Format "Text"
Write-Host $asymmetryReport -ForegroundColor White

# Test 5: Rapport d'évaluation de l'asymétrie au format HTML
Write-Host "`n=== Test 5: Rapport d'évaluation de l'asymétrie au format HTML ===" -ForegroundColor Magenta
$htmlAsymmetryReport = Get-AsymmetryCentralIndicatorsReport -StandardDeviation 10.0 -SampleSize 200 -ConfidenceLevel "95%" -Format "HTML"
$htmlAsymmetryFilePath = Join-Path -Path $PSScriptRoot -ChildPath "AsymmetryCentralIndicatorsReport.html"
Set-Content -Path $htmlAsymmetryFilePath -Value $htmlAsymmetryReport -Encoding UTF8
Write-Host "Le rapport au format HTML a été sauvegardé dans le fichier: $htmlAsymmetryFilePath" -ForegroundColor Green

# Résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
Write-Host "Tous les tests ont été exécutés." -ForegroundColor Green
Write-Host "Vérifiez les résultats pour vous assurer que les évaluations d'asymétrie sont appropriées." -ForegroundColor Green
Write-Host "Les rapports HTML ont été générés et sauvegardés dans le dossier du script." -ForegroundColor Green
