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

# Test 1: Ratio des longueurs de queue pour une distribution normale
Write-Host "`n=== Test 1: Ratio des longueurs de queue pour une distribution normale ===" -ForegroundColor Magenta
$normalRatio = Get-TailLengthRatio -Data $normalData -Method "Percentile" -PercentileThreshold 10
Write-Host "Méthode: $($normalRatio.Method)" -ForegroundColor White
Write-Host "Seuil de percentile: $($normalRatio.PercentileThreshold)%" -ForegroundColor White
Write-Host "Moyenne: $([Math]::Round($normalRatio.Mean, 2))" -ForegroundColor White
Write-Host "Médiane: $([Math]::Round($normalRatio.Median, 2))" -ForegroundColor White
Write-Host "Écart-type: $([Math]::Round($normalRatio.StdDev, 2))" -ForegroundColor White
Write-Host "Longueur de la queue gauche: $([Math]::Round($normalRatio.LeftTailLength, 2))" -ForegroundColor Green
Write-Host "Longueur de la queue droite: $([Math]::Round($normalRatio.RightTailLength, 2))" -ForegroundColor Green
Write-Host "Ratio des longueurs de queue (droite/gauche): $([Math]::Round($normalRatio.TailRatio, 2))" -ForegroundColor Green
Write-Host "Nombre de points dans la queue gauche: $($normalRatio.LeftTailPoints)" -ForegroundColor White
Write-Host "Nombre de points dans la queue droite: $($normalRatio.RightTailPoints)" -ForegroundColor White
Write-Host "Ratio des points dans les queues (droite/gauche): $([Math]::Round($normalRatio.PointsRatio, 2))" -ForegroundColor White
Write-Host "Direction de l'asymétrie: $($normalRatio.AsymmetryDirection)" -ForegroundColor Green
Write-Host "Intensité de l'asymétrie: $($normalRatio.AsymmetryIntensity)" -ForegroundColor Green
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $normalRatio.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 2: Ratio des longueurs de queue pour une distribution asymétrique positive
Write-Host "`n=== Test 2: Ratio des longueurs de queue pour une distribution asymétrique positive ===" -ForegroundColor Magenta
$positiveSkewRatio = Get-TailLengthRatio -Data $positiveSkewData -Method "Percentile" -PercentileThreshold 10
Write-Host "Méthode: $($positiveSkewRatio.Method)" -ForegroundColor White
Write-Host "Seuil de percentile: $($positiveSkewRatio.PercentileThreshold)%" -ForegroundColor White
Write-Host "Moyenne: $([Math]::Round($positiveSkewRatio.Mean, 2))" -ForegroundColor White
Write-Host "Médiane: $([Math]::Round($positiveSkewRatio.Median, 2))" -ForegroundColor White
Write-Host "Écart-type: $([Math]::Round($positiveSkewRatio.StdDev, 2))" -ForegroundColor White
Write-Host "Longueur de la queue gauche: $([Math]::Round($positiveSkewRatio.LeftTailLength, 2))" -ForegroundColor Green
Write-Host "Longueur de la queue droite: $([Math]::Round($positiveSkewRatio.RightTailLength, 2))" -ForegroundColor Green
Write-Host "Ratio des longueurs de queue (droite/gauche): $([Math]::Round($positiveSkewRatio.TailRatio, 2))" -ForegroundColor Green
Write-Host "Nombre de points dans la queue gauche: $($positiveSkewRatio.LeftTailPoints)" -ForegroundColor White
Write-Host "Nombre de points dans la queue droite: $($positiveSkewRatio.RightTailPoints)" -ForegroundColor White
Write-Host "Ratio des points dans les queues (droite/gauche): $([Math]::Round($positiveSkewRatio.PointsRatio, 2))" -ForegroundColor White
Write-Host "Direction de l'asymétrie: $($positiveSkewRatio.AsymmetryDirection)" -ForegroundColor Green
Write-Host "Intensité de l'asymétrie: $($positiveSkewRatio.AsymmetryIntensity)" -ForegroundColor Green
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $positiveSkewRatio.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 3: Ratio des longueurs de queue pour une distribution asymétrique négative
Write-Host "`n=== Test 3: Ratio des longueurs de queue pour une distribution asymétrique négative ===" -ForegroundColor Magenta
$negativeSkewRatio = Get-TailLengthRatio -Data $negativeSkewData -Method "Percentile" -PercentileThreshold 10
Write-Host "Méthode: $($negativeSkewRatio.Method)" -ForegroundColor White
Write-Host "Seuil de percentile: $($negativeSkewRatio.PercentileThreshold)%" -ForegroundColor White
Write-Host "Moyenne: $([Math]::Round($negativeSkewRatio.Mean, 2))" -ForegroundColor White
Write-Host "Médiane: $([Math]::Round($negativeSkewRatio.Median, 2))" -ForegroundColor White
Write-Host "Écart-type: $([Math]::Round($negativeSkewRatio.StdDev, 2))" -ForegroundColor White
Write-Host "Longueur de la queue gauche: $([Math]::Round($negativeSkewRatio.LeftTailLength, 2))" -ForegroundColor Green
Write-Host "Longueur de la queue droite: $([Math]::Round($negativeSkewRatio.RightTailLength, 2))" -ForegroundColor Green
Write-Host "Ratio des longueurs de queue (droite/gauche): $([Math]::Round($negativeSkewRatio.TailRatio, 2))" -ForegroundColor Green
Write-Host "Nombre de points dans la queue gauche: $($negativeSkewRatio.LeftTailPoints)" -ForegroundColor White
Write-Host "Nombre de points dans la queue droite: $($negativeSkewRatio.RightTailPoints)" -ForegroundColor White
Write-Host "Ratio des points dans les queues (droite/gauche): $([Math]::Round($negativeSkewRatio.PointsRatio, 2))" -ForegroundColor White
Write-Host "Direction de l'asymétrie: $($negativeSkewRatio.AsymmetryDirection)" -ForegroundColor Green
Write-Host "Intensité de l'asymétrie: $($negativeSkewRatio.AsymmetryIntensity)" -ForegroundColor Green
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $negativeSkewRatio.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 4: Rapport d'évaluation de l'asymétrie au format texte
Write-Host "`n=== Test 4: Rapport d'évaluation de l'asymétrie au format texte ===" -ForegroundColor Magenta
$tailRatioReport = Get-TailLengthRatioReport -Data $positiveSkewData -Methods "All" -Format "Text"
Write-Host $tailRatioReport -ForegroundColor White

# Test 5: Rapport d'évaluation de l'asymétrie au format HTML
Write-Host "`n=== Test 5: Rapport d'évaluation de l'asymétrie au format HTML ===" -ForegroundColor Magenta
$htmlTailRatioReport = Get-TailLengthRatioReport -Data $positiveSkewData -Methods "All" -Format "HTML"
$htmlTailRatioFilePath = Join-Path -Path $PSScriptRoot -ChildPath "TailLengthRatioReport.html"
Set-Content -Path $htmlTailRatioFilePath -Value $htmlTailRatioReport -Encoding UTF8
Write-Host "Le rapport au format HTML a été sauvegardé dans le fichier: $htmlTailRatioFilePath" -ForegroundColor Green

# Résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
Write-Host "Tous les tests ont été exécutés." -ForegroundColor Green
Write-Host "Vérifiez les résultats pour vous assurer que les évaluations d'asymétrie sont appropriées." -ForegroundColor Green
Write-Host "Les rapports HTML ont été générés et sauvegardés dans le dossier du script." -ForegroundColor Green
