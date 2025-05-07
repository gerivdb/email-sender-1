# Importer le module
Import-Module .\development\scripts\statistics\ResolutionRecommendations.psm1 -Force

# Test 1: Séparation minimale entre les modes dans une distribution normale
Write-Host "`n=== Test 1: Séparation minimale entre les modes dans une distribution normale ===" -ForegroundColor Magenta
$normalModeSeparation = Get-ModeSeparationThreshold -SampleSize 200 -DataDistribution "Normale" -NoiseLevel "Faible" -SmoothingMethod "Noyau gaussien" -Application "Analyse statistique" -StandardDeviation 2.5
Write-Host "Taille d'échantillon: $($normalModeSeparation.SampleSize) (Catégorie: $($normalModeSeparation.SizeCategory))" -ForegroundColor White
Write-Host "Type de distribution: $($normalModeSeparation.DataDistribution) (Facteur: $($normalModeSeparation.DistributionFactor))" -ForegroundColor White
Write-Host "Niveau de bruit: $($normalModeSeparation.NoiseLevel)" -ForegroundColor White
Write-Host "Méthode de lissage: $($normalModeSeparation.SmoothingMethod)" -ForegroundColor White
Write-Host "Application: $($normalModeSeparation.Application)" -ForegroundColor White
Write-Host "Écart-type: $($normalModeSeparation.StandardDeviation)" -ForegroundColor White
Write-Host "Séparation de base par taille d'échantillon: $($normalModeSeparation.BaseSeparationCategory) ($($normalModeSeparation.BaseSeparation))" -ForegroundColor White
Write-Host "Séparation par niveau de bruit: $($normalModeSeparation.NoiseSeparationCategory) ($($normalModeSeparation.NoiseSeparation))" -ForegroundColor White
Write-Host "Séparation par méthode de lissage: $($normalModeSeparation.SmoothingSeparationCategory) ($($normalModeSeparation.SmoothingSeparation))" -ForegroundColor White
Write-Host "Séparation par application: $($normalModeSeparation.ApplicationSeparationCategory) ($($normalModeSeparation.ApplicationSeparation))" -ForegroundColor White
Write-Host "Séparation finale: $($normalModeSeparation.FinalSeparation) écarts-types ($($normalModeSeparation.FinalSeparationCategory))" -ForegroundColor Green
Write-Host "Séparation en unités originales: $($normalModeSeparation.SeparationInOriginalUnits)" -ForegroundColor Green
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $normalModeSeparation.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 2: Rapport de séparation minimale entre les modes au format texte
Write-Host "`n=== Test 2: Rapport de séparation minimale entre les modes au format texte ===" -ForegroundColor Magenta
$modeSeparationReport = Get-ModeSeparationReport -DataDistribution "Asymétrique" -NoiseLevel "Faible" -SmoothingMethod "Spline" -StandardDeviation 1.2 -Format "Text"
Write-Host $modeSeparationReport -ForegroundColor White
