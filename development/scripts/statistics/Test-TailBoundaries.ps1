# Importer le module
Import-Module .\development\scripts\statistics\ResolutionRecommendations.psm1 -Force

# Générer des données de test
# 1. Distribution normale (symétrique)
$normalData = @()
for ($i = 0; $i -lt 1000; $i++) {
    # Méthode Box-Muller pour générer des nombres aléatoires suivant une loi normale
    $u1 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
    $u2 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
    if ($u1 -eq 0) { $u1 = 0.0001 }
    
    $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
    $normalData += 100 + 15 * $z  # Moyenne 100, écart-type 15
}

# 2. Distribution asymétrique positive (queue à droite)
$positiveSkewData = @()
for ($i = 0; $i -lt 1000; $i++) {
    # Générer une distribution log-normale
    $u1 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
    $u2 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
    if ($u1 -eq 0) { $u1 = 0.0001 }
    
    $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
    $positiveSkewData += 100 + 15 * [Math]::Exp($z / 2)
}

# 3. Distribution asymétrique négative (queue à gauche)
$negativeSkewData = @()
for ($i = 0; $i -lt 1000; $i++) {
    # Générer une distribution log-normale inversée
    $u1 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
    $u2 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
    if ($u1 -eq 0) { $u1 = 0.0001 }
    
    $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
    $negativeSkewData += 100 - 15 * [Math]::Exp($z / 2)
}

# 4. Petit échantillon
$smallSampleData = @()
for ($i = 0; $i -lt 20; $i++) {
    # Méthode Box-Muller pour générer des nombres aléatoires suivant une loi normale
    $u1 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
    $u2 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
    if ($u1 -eq 0) { $u1 = 0.0001 }
    
    $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
    $smallSampleData += 100 + 15 * $z  # Moyenne 100, écart-type 15
}

# Test 1: Limites des queues pour une distribution normale avec la méthode des percentiles
Write-Host "`n=== Test 1: Limites des queues pour une distribution normale avec la méthode des percentiles ===" -ForegroundColor Magenta
$normalPercentile = Get-DistributionTailBoundaries -Data $normalData -Method "Percentile" -PercentileThreshold 10
Write-Host "Méthode: $($normalPercentile.Method)" -ForegroundColor White
Write-Host "Description de la méthode: $($normalPercentile.MethodDescription)" -ForegroundColor White
Write-Host "Moyenne: $([Math]::Round($normalPercentile.Mean, 2))" -ForegroundColor White
Write-Host "Médiane: $([Math]::Round($normalPercentile.Median, 2))" -ForegroundColor White
Write-Host "Écart-type: $([Math]::Round($normalPercentile.StdDev, 2))" -ForegroundColor White
Write-Host "Limite inférieure (queue gauche): $([Math]::Round($normalPercentile.LowerBound, 2))" -ForegroundColor Green
Write-Host "Limite supérieure (queue droite): $([Math]::Round($normalPercentile.UpperBound, 2))" -ForegroundColor Green
Write-Host "Longueur de la queue gauche: $([Math]::Round($normalPercentile.LeftTailLength, 2))" -ForegroundColor Green
Write-Host "Longueur de la queue droite: $([Math]::Round($normalPercentile.RightTailLength, 2))" -ForegroundColor Green
Write-Host "Ratio des longueurs de queue (droite/gauche): $([Math]::Round($normalPercentile.TailRatio, 2))" -ForegroundColor Green
Write-Host "Nombre de points dans la queue gauche: $($normalPercentile.LeftTailPoints)" -ForegroundColor White
Write-Host "Nombre de points dans la queue droite: $($normalPercentile.RightTailPoints)" -ForegroundColor White
Write-Host "Direction de l'asymétrie: $($normalPercentile.AsymmetryDirection)" -ForegroundColor Green
Write-Host "Intensité de l'asymétrie: $($normalPercentile.AsymmetryIntensity)" -ForegroundColor Green
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $normalPercentile.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 2: Limites des queues pour une distribution asymétrique positive avec la méthode de l'écart-type
Write-Host "`n=== Test 2: Limites des queues pour une distribution asymétrique positive avec la méthode de l'écart-type ===" -ForegroundColor Magenta
$positiveSkewStdDev = Get-DistributionTailBoundaries -Data $positiveSkewData -Method "StdDev" -StdDevMultiplier 1.5
Write-Host "Méthode: $($positiveSkewStdDev.Method)" -ForegroundColor White
Write-Host "Description de la méthode: $($positiveSkewStdDev.MethodDescription)" -ForegroundColor White
Write-Host "Moyenne: $([Math]::Round($positiveSkewStdDev.Mean, 2))" -ForegroundColor White
Write-Host "Médiane: $([Math]::Round($positiveSkewStdDev.Median, 2))" -ForegroundColor White
Write-Host "Écart-type: $([Math]::Round($positiveSkewStdDev.StdDev, 2))" -ForegroundColor White
Write-Host "Limite inférieure (queue gauche): $([Math]::Round($positiveSkewStdDev.LowerBound, 2))" -ForegroundColor Green
Write-Host "Limite supérieure (queue droite): $([Math]::Round($positiveSkewStdDev.UpperBound, 2))" -ForegroundColor Green
Write-Host "Longueur de la queue gauche: $([Math]::Round($positiveSkewStdDev.LeftTailLength, 2))" -ForegroundColor Green
Write-Host "Longueur de la queue droite: $([Math]::Round($positiveSkewStdDev.RightTailLength, 2))" -ForegroundColor Green
Write-Host "Ratio des longueurs de queue (droite/gauche): $([Math]::Round($positiveSkewStdDev.TailRatio, 2))" -ForegroundColor Green
Write-Host "Nombre de points dans la queue gauche: $($positiveSkewStdDev.LeftTailPoints)" -ForegroundColor White
Write-Host "Nombre de points dans la queue droite: $($positiveSkewStdDev.RightTailPoints)" -ForegroundColor White
Write-Host "Direction de l'asymétrie: $($positiveSkewStdDev.AsymmetryDirection)" -ForegroundColor Green
Write-Host "Intensité de l'asymétrie: $($positiveSkewStdDev.AsymmetryIntensity)" -ForegroundColor Green
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $positiveSkewStdDev.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 3: Limites des queues pour une distribution asymétrique négative avec la méthode de l'IQR
Write-Host "`n=== Test 3: Limites des queues pour une distribution asymétrique négative avec la méthode de l'IQR ===" -ForegroundColor Magenta
$negativeSkewIQR = Get-DistributionTailBoundaries -Data $negativeSkewData -Method "IQR" -IQRMultiplier 1.5
Write-Host "Méthode: $($negativeSkewIQR.Method)" -ForegroundColor White
Write-Host "Description de la méthode: $($negativeSkewIQR.MethodDescription)" -ForegroundColor White
Write-Host "Moyenne: $([Math]::Round($negativeSkewIQR.Mean, 2))" -ForegroundColor White
Write-Host "Médiane: $([Math]::Round($negativeSkewIQR.Median, 2))" -ForegroundColor White
Write-Host "Écart-type: $([Math]::Round($negativeSkewIQR.StdDev, 2))" -ForegroundColor White
Write-Host "Q1: $([Math]::Round($negativeSkewIQR.Q1, 2))" -ForegroundColor White
Write-Host "Q3: $([Math]::Round($negativeSkewIQR.Q3, 2))" -ForegroundColor White
Write-Host "IQR: $([Math]::Round($negativeSkewIQR.IQR, 2))" -ForegroundColor White
Write-Host "Limite inférieure (queue gauche): $([Math]::Round($negativeSkewIQR.LowerBound, 2))" -ForegroundColor Green
Write-Host "Limite supérieure (queue droite): $([Math]::Round($negativeSkewIQR.UpperBound, 2))" -ForegroundColor Green
Write-Host "Longueur de la queue gauche: $([Math]::Round($negativeSkewIQR.LeftTailLength, 2))" -ForegroundColor Green
Write-Host "Longueur de la queue droite: $([Math]::Round($negativeSkewIQR.RightTailLength, 2))" -ForegroundColor Green
Write-Host "Ratio des longueurs de queue (droite/gauche): $([Math]::Round($negativeSkewIQR.TailRatio, 2))" -ForegroundColor Green
Write-Host "Nombre de points dans la queue gauche: $($negativeSkewIQR.LeftTailPoints)" -ForegroundColor White
Write-Host "Nombre de points dans la queue droite: $($negativeSkewIQR.RightTailPoints)" -ForegroundColor White
Write-Host "Direction de l'asymétrie: $($negativeSkewIQR.AsymmetryDirection)" -ForegroundColor Green
Write-Host "Intensité de l'asymétrie: $($negativeSkewIQR.AsymmetryIntensity)" -ForegroundColor Green
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $negativeSkewIQR.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 4: Limites des queues pour un petit échantillon avec la méthode MAD
Write-Host "`n=== Test 4: Limites des queues pour un petit échantillon avec la méthode MAD ===" -ForegroundColor Magenta
$smallSampleMAD = Get-DistributionTailBoundaries -Data $smallSampleData -Method "MAD" -MADMultiplier 2.0
Write-Host "Méthode: $($smallSampleMAD.Method)" -ForegroundColor White
Write-Host "Description de la méthode: $($smallSampleMAD.MethodDescription)" -ForegroundColor White
Write-Host "Moyenne: $([Math]::Round($smallSampleMAD.Mean, 2))" -ForegroundColor White
Write-Host "Médiane: $([Math]::Round($smallSampleMAD.Median, 2))" -ForegroundColor White
Write-Host "Écart-type: $([Math]::Round($smallSampleMAD.StdDev, 2))" -ForegroundColor White
Write-Host "MAD: $([Math]::Round($smallSampleMAD.MAD, 2))" -ForegroundColor White
Write-Host "MAD normalisée: $([Math]::Round($smallSampleMAD.MADNormalized, 2))" -ForegroundColor White
Write-Host "Limite inférieure (queue gauche): $([Math]::Round($smallSampleMAD.LowerBound, 2))" -ForegroundColor Green
Write-Host "Limite supérieure (queue droite): $([Math]::Round($smallSampleMAD.UpperBound, 2))" -ForegroundColor Green
Write-Host "Longueur de la queue gauche: $([Math]::Round($smallSampleMAD.LeftTailLength, 2))" -ForegroundColor Green
Write-Host "Longueur de la queue droite: $([Math]::Round($smallSampleMAD.RightTailLength, 2))" -ForegroundColor Green
Write-Host "Ratio des longueurs de queue (droite/gauche): $([Math]::Round($smallSampleMAD.TailRatio, 2))" -ForegroundColor Green
Write-Host "Nombre de points dans la queue gauche: $($smallSampleMAD.LeftTailPoints)" -ForegroundColor White
Write-Host "Nombre de points dans la queue droite: $($smallSampleMAD.RightTailPoints)" -ForegroundColor White
Write-Host "Direction de l'asymétrie: $($smallSampleMAD.AsymmetryDirection)" -ForegroundColor Green
Write-Host "Intensité de l'asymétrie: $($smallSampleMAD.AsymmetryIntensity)" -ForegroundColor Green
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $smallSampleMAD.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 5: Limites des queues pour une distribution asymétrique positive avec la méthode adaptative
Write-Host "`n=== Test 5: Limites des queues pour une distribution asymétrique positive avec la méthode adaptative ===" -ForegroundColor Magenta
$positiveSkewAdaptive = Get-DistributionTailBoundaries -Data $positiveSkewData -Method "Adaptive"
Write-Host "Méthode: $($positiveSkewAdaptive.Method)" -ForegroundColor White
Write-Host "Description de la méthode: $($positiveSkewAdaptive.MethodDescription)" -ForegroundColor White
Write-Host "Moyenne: $([Math]::Round($positiveSkewAdaptive.Mean, 2))" -ForegroundColor White
Write-Host "Médiane: $([Math]::Round($positiveSkewAdaptive.Median, 2))" -ForegroundColor White
Write-Host "Écart-type: $([Math]::Round($positiveSkewAdaptive.StdDev, 2))" -ForegroundColor White
Write-Host "Limite inférieure (queue gauche): $([Math]::Round($positiveSkewAdaptive.LowerBound, 2))" -ForegroundColor Green
Write-Host "Limite supérieure (queue droite): $([Math]::Round($positiveSkewAdaptive.UpperBound, 2))" -ForegroundColor Green
Write-Host "Longueur de la queue gauche: $([Math]::Round($positiveSkewAdaptive.LeftTailLength, 2))" -ForegroundColor Green
Write-Host "Longueur de la queue droite: $([Math]::Round($positiveSkewAdaptive.RightTailLength, 2))" -ForegroundColor Green
Write-Host "Ratio des longueurs de queue (droite/gauche): $([Math]::Round($positiveSkewAdaptive.TailRatio, 2))" -ForegroundColor Green
Write-Host "Nombre de points dans la queue gauche: $($positiveSkewAdaptive.LeftTailPoints)" -ForegroundColor White
Write-Host "Nombre de points dans la queue droite: $($positiveSkewAdaptive.RightTailPoints)" -ForegroundColor White
Write-Host "Direction de l'asymétrie: $($positiveSkewAdaptive.AsymmetryDirection)" -ForegroundColor Green
Write-Host "Intensité de l'asymétrie: $($positiveSkewAdaptive.AsymmetryIntensity)" -ForegroundColor Green
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $positiveSkewAdaptive.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 6: Comparaison des méthodes pour une distribution asymétrique positive
Write-Host "`n=== Test 6: Comparaison des méthodes pour une distribution asymétrique positive ===" -ForegroundColor Magenta
$positiveSkewComparison = Compare-TailBoundaryMethods -Data $positiveSkewData
Write-Host "Méthodes comparées: $($positiveSkewComparison.Methods -join ', ')" -ForegroundColor White
Write-Host "Moyenne: $([Math]::Round($positiveSkewComparison.Mean, 2))" -ForegroundColor White
Write-Host "Médiane: $([Math]::Round($positiveSkewComparison.Median, 2))" -ForegroundColor White
Write-Host "Écart-type: $([Math]::Round($positiveSkewComparison.StdDev, 2))" -ForegroundColor White
Write-Host "Coefficient d'asymétrie (skewness): $([Math]::Round($positiveSkewComparison.Skewness, 2))" -ForegroundColor White
Write-Host "Coefficient d'aplatissement (kurtosis): $([Math]::Round($positiveSkewComparison.Kurtosis, 2))" -ForegroundColor White
Write-Host "Méthode recommandée: $($positiveSkewComparison.RecommendedMethod)" -ForegroundColor Green
Write-Host "Raison: $($positiveSkewComparison.RecommendationReason)" -ForegroundColor Green
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $positiveSkewComparison.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
Write-Host "Tous les tests ont été exécutés." -ForegroundColor Green
Write-Host "Vérifiez les résultats pour vous assurer que les limites des queues sont détectées correctement." -ForegroundColor Green
