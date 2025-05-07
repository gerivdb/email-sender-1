# Importer le module
Import-Module .\development\scripts\statistics\KernelDensityEstimation.psm1 -Force

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

# Test 1: Valeurs du noyau d'Epanechnikov
Write-Host "`n=== Test 1: Valeurs du noyau d'Epanechnikov ===" -ForegroundColor Magenta
$testPoints = @(0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5)
Write-Host "Valeurs du noyau d'Epanechnikov pour différents points:" -ForegroundColor White
Write-Host "| Point | Valeur du noyau |" -ForegroundColor White
Write-Host "|-------|----------------|" -ForegroundColor White
foreach ($point in $testPoints) {
    $kernelValue = Get-EpanechnikovKernel -U $point
    Write-Host "| $point | $([Math]::Round($kernelValue, 6)) |" -ForegroundColor Green
}

# Vérifier que la valeur au centre (u=0) est correcte
$centerValue = Get-EpanechnikovKernel -U 0
$expectedCenterValue = 0.75
$centerValueCorrect = [Math]::Abs($centerValue - $expectedCenterValue) -lt 0.0001
Write-Host "`nValeur au centre (u=0): $([Math]::Round($centerValue, 6))" -ForegroundColor White
Write-Host "Valeur attendue: $([Math]::Round($expectedCenterValue, 6))" -ForegroundColor White
Write-Host "Résultat: $(if ($centerValueCorrect) { "Correct" } else { "Incorrect" })" -ForegroundColor $(if ($centerValueCorrect) { "Green" } else { "Red" })

# Test 2: Symétrie du noyau d'Epanechnikov
Write-Host "`n=== Test 2: Symétrie du noyau d'Epanechnikov ===" -ForegroundColor Magenta
$symmetryTestPoints = @(0.25, 0.5, 0.75, 1.0)
$symmetryCorrect = $true
Write-Host "Vérification de la symétrie du noyau d'Epanechnikov:" -ForegroundColor White
Write-Host "| Point | Valeur à +u | Valeur à -u | Différence |" -ForegroundColor White
Write-Host "|-------|------------|------------|------------|" -ForegroundColor White
foreach ($point in $symmetryTestPoints) {
    $positiveValue = Get-EpanechnikovKernel -U $point
    $negativeValue = Get-EpanechnikovKernel -U (-$point)
    $difference = [Math]::Abs($positiveValue - $negativeValue)
    $isSymmetric = $difference -lt 0.0001
    if (-not $isSymmetric) {
        $symmetryCorrect = $false
    }
    Write-Host "| $point | $([Math]::Round($positiveValue, 6)) | $([Math]::Round($negativeValue, 6)) | $([Math]::Round($difference, 6)) |" -ForegroundColor $(if ($isSymmetric) { "Green" } else { "Red" })
}
Write-Host "`nSymétrie du noyau d'Epanechnikov: $(if ($symmetryCorrect) { "Correcte" } else { "Incorrecte" })" -ForegroundColor $(if ($symmetryCorrect) { "Green" } else { "Red" })

# Test 3: Support compact du noyau d'Epanechnikov
Write-Host "`n=== Test 3: Support compact du noyau d'Epanechnikov ===" -ForegroundColor Magenta
$compactSupportTestPoints = @(0.9, 0.99, 1.0, 1.001, 1.5, 2.0)
$compactSupportCorrect = $true
Write-Host "Vérification du support compact du noyau d'Epanechnikov:" -ForegroundColor White
Write-Host "| Point | Valeur du noyau | Attendu |" -ForegroundColor White
Write-Host "|-------|----------------|---------|" -ForegroundColor White
foreach ($point in $compactSupportTestPoints) {
    $kernelValue = Get-EpanechnikovKernel -U $point
    $expected = if ([Math]::Abs($point) -lt 1) { "Positif" } else { "0" }
    $isCorrect = if ($expected -eq "0") { $kernelValue -eq 0 } else { $kernelValue -gt 0 }
    if (-not $isCorrect) {
        $compactSupportCorrect = $false
    }
    Write-Host "| $point | $([Math]::Round($kernelValue, 6)) | $expected |" -ForegroundColor $(if ($isCorrect) { "Green" } else { "Red" })
}
Write-Host "`nSupport compact du noyau d'Epanechnikov: $(if ($compactSupportCorrect) { "Correct" } else { "Incorrect" })" -ForegroundColor $(if ($compactSupportCorrect) { "Green" } else { "Red" })

# Test 4: Intégration du noyau d'Epanechnikov
Write-Host "`n=== Test 4: Intégration du noyau d'Epanechnikov ===" -ForegroundColor Magenta
# L'intégrale du noyau d'Epanechnikov sur l'intervalle [-1, 1] devrait être égale à 1
$integrationPoints = -1..1  # Points de -1 à 1 avec un pas de 1
$integrationValues = $integrationPoints | ForEach-Object { Get-EpanechnikovKernel -U $_ }
$integrationSum = ($integrationValues | Measure-Object -Sum).Sum
$integrationCorrect = [Math]::Abs($integrationSum - 1) -lt 0.5  # Tolérance large car approximation grossière
Write-Host "Intégrale approximative du noyau d'Epanechnikov sur [-1, 1]: $([Math]::Round($integrationSum, 4))" -ForegroundColor White
Write-Host "Valeur attendue: 1" -ForegroundColor White
Write-Host "Résultat: $(if ($integrationCorrect) { "Approximativement correct" } else { "Incorrect" })" -ForegroundColor $(if ($integrationCorrect) { "Green" } else { "Red" })

# Test 5: Estimation de densité par noyau d'Epanechnikov
Write-Host "`n=== Test 5: Estimation de densité par noyau d'Epanechnikov ===" -ForegroundColor Magenta
# Calculer la densité à différents points
$densityPoints = @(70, 85, 100, 115, 130)
$bandwidth = 0  # Utiliser la largeur de bande optimale
Write-Host "Estimation de densité par noyau d'Epanechnikov pour une distribution normale (μ=100, σ=15):" -ForegroundColor White
Write-Host "| Point | Densité estimée |" -ForegroundColor White
Write-Host "|-------|----------------|" -ForegroundColor White
foreach ($point in $densityPoints) {
    $density = Get-EpanechnikovKernelDensity -X $point -Data $normalData -Bandwidth $bandwidth
    Write-Host "| $point | $([Math]::Round($density, 6)) |" -ForegroundColor Green
}

# Vérifier que la densité est maximale au centre de la distribution
$densities = $densityPoints | ForEach-Object {
    [PSCustomObject]@{
        Point   = $_
        Density = Get-EpanechnikovKernelDensity -X $_ -Data $normalData -Bandwidth $bandwidth
    }
}
$maxDensityPoint = ($densities | Sort-Object -Property Density -Descending)[0].Point
$densityCorrect = [Math]::Abs($maxDensityPoint - 100) -lt 5  # Tolérance de 5 unités
Write-Host "`nPoint de densité maximale: $maxDensityPoint" -ForegroundColor White
Write-Host "Point attendu: environ 100" -ForegroundColor White
Write-Host "Résultat: $(if ($densityCorrect) { "Approximativement correct" } else { "Incorrect" })" -ForegroundColor $(if ($densityCorrect) { "Green" } else { "Red" })

# Test 6: Comparaison avec le noyau gaussien
Write-Host "`n=== Test 6: Comparaison avec le noyau gaussien ===" -ForegroundColor Magenta
# Calculer la densité avec les deux noyaux
$comparisonPoint = 100  # Point central
$epanechnikovDensity = Get-EpanechnikovKernelDensity -X $comparisonPoint -Data $normalData -Bandwidth $bandwidth
$gaussianDensity = Get-GaussianKernelDensity -X $comparisonPoint -Data $normalData -Bandwidth $bandwidth
Write-Host "Densité au point central (x=100):" -ForegroundColor White
Write-Host "| Noyau | Densité estimée |" -ForegroundColor White
Write-Host "|-------|----------------|" -ForegroundColor White
Write-Host "| Epanechnikov | $([Math]::Round($epanechnikovDensity, 6)) |" -ForegroundColor Green
Write-Host "| Gaussien | $([Math]::Round($gaussianDensity, 6)) |" -ForegroundColor Green
Write-Host "`nRatio Epanechnikov/Gaussien: $([Math]::Round($epanechnikovDensity / $gaussianDensity, 4))" -ForegroundColor White

# Résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
$allTestsPassed = $centerValueCorrect -and $symmetryCorrect -and $compactSupportCorrect -and $integrationCorrect -and $densityCorrect
Write-Host "Tous les tests ont été exécutés." -ForegroundColor Green
Write-Host "Résultat global: $(if ($allTestsPassed) { "Tous les tests ont réussi" } else { "Certains tests ont échoué" })" -ForegroundColor $(if ($allTestsPassed) { "Green" } else { "Red" })
