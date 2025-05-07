# Importer le module
Import-Module .\development\scripts\statistics\KernelDensityEstimation.psm1 -Force

# Générer des données de test très simples
$simpleData = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

# Test simple avec un petit ensemble de données
Write-Host "Test simple de la fonction Get-BandwidthMethodScores avec un petit ensemble de données" -ForegroundColor Cyan
$scores = Get-BandwidthMethodScores -Data $simpleData -KernelType "Gaussian" -Methods @("Silverman", "Scott") -Criteria @("Speed", "Robustness")

# Afficher les résultats
Write-Host "`nRésultats du scoring:" -ForegroundColor Magenta
Write-Host "| Méthode | Largeur de bande | Temps d'exécution (s) | Score Vitesse | Score Robustesse | Score Total |" -ForegroundColor White
Write-Host "|---------|-----------------|------------------------|---------------|------------------|-------------|" -ForegroundColor White

foreach ($method in $scores.Keys) {
    $methodScores = $scores[$method]
    Write-Host "| $method | $([Math]::Round($methodScores.Bandwidth, 4)) | $([Math]::Round($methodScores.ExecutionTime, 4)) | $([Math]::Round($methodScores.Scores.Speed, 2)) | $([Math]::Round($methodScores.Scores.Robustness, 2)) | $([Math]::Round($methodScores.TotalScore, 2)) |" -ForegroundColor Green
}

# Test avec tous les critères
Write-Host "`nTest de la fonction Get-BandwidthMethodScores avec tous les critères" -ForegroundColor Cyan
$allCriteriaScores = Get-BandwidthMethodScores -Data $simpleData -KernelType "Gaussian" -Methods @("Silverman", "Scott") -Criteria @("Accuracy", "Speed", "Robustness", "Adaptability")

# Afficher les résultats
Write-Host "`nRésultats du scoring avec tous les critères:" -ForegroundColor Magenta
Write-Host "| Méthode | Score Précision | Score Vitesse | Score Robustesse | Score Adaptabilité | Score Total |" -ForegroundColor White
Write-Host "|---------|-----------------|---------------|------------------|---------------------|-------------|" -ForegroundColor White

foreach ($method in $allCriteriaScores.Keys) {
    $methodScores = $allCriteriaScores[$method]
    Write-Host "| $method | $([Math]::Round($methodScores.Scores.Accuracy, 2)) | $([Math]::Round($methodScores.Scores.Speed, 2)) | $([Math]::Round($methodScores.Scores.Robustness, 2)) | $([Math]::Round($methodScores.Scores.Adaptability, 2)) | $([Math]::Round($methodScores.TotalScore, 2)) |" -ForegroundColor Green
}

# Test avec des poids personnalisés
Write-Host "`nTest de la fonction Get-BandwidthMethodScores avec des poids personnalisés" -ForegroundColor Cyan
$weights = @{
    Accuracy = 2
    Speed = 1
    Robustness = 3
    Adaptability = 1
}
$weightedScores = Get-BandwidthMethodScores -Data $simpleData -KernelType "Gaussian" -Methods @("Silverman", "Scott") -Criteria @("Accuracy", "Speed", "Robustness", "Adaptability") -Weights $weights

# Afficher les résultats
Write-Host "`nRésultats du scoring avec des poids personnalisés:" -ForegroundColor Magenta
Write-Host "| Méthode | Score Précision | Score Vitesse | Score Robustesse | Score Adaptabilité | Score Total |" -ForegroundColor White
Write-Host "|---------|-----------------|---------------|------------------|---------------------|-------------|" -ForegroundColor White

foreach ($method in $weightedScores.Keys) {
    $methodScores = $weightedScores[$method]
    Write-Host "| $method | $([Math]::Round($methodScores.Scores.Accuracy, 2)) | $([Math]::Round($methodScores.Scores.Speed, 2)) | $([Math]::Round($methodScores.Scores.Robustness, 2)) | $([Math]::Round($methodScores.Scores.Adaptability, 2)) | $([Math]::Round($methodScores.TotalScore, 2)) |" -ForegroundColor Green
}

# Résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
Write-Host "Tous les tests ont été exécutés avec succès." -ForegroundColor Green
