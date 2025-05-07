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

# Test 1: Valeurs du noyau gaussien
Write-Host "`n=== Test 1: Valeurs du noyau gaussien ===" -ForegroundColor Magenta
$testPoints = @(0, 0.5, 1, 1.5, 2, 2.5, 3)
Write-Host "Valeurs du noyau gaussien pour différents points:" -ForegroundColor White
Write-Host "| Point | Valeur du noyau |" -ForegroundColor White
Write-Host "|-------|----------------|" -ForegroundColor White
foreach ($point in $testPoints) {
    $kernelValue = Get-GaussianKernel -U $point
    Write-Host "| $point | $([Math]::Round($kernelValue, 6)) |" -ForegroundColor Green
}

# Vérifier que la valeur au centre (u=0) est correcte
$centerValue = Get-GaussianKernel -U 0
$expectedCenterValue = 1 / [Math]::Sqrt(2 * [Math]::PI)
$centerValueCorrect = [Math]::Abs($centerValue - $expectedCenterValue) -lt 0.0001
Write-Host "`nValeur au centre (u=0): $([Math]::Round($centerValue, 6))" -ForegroundColor White
Write-Host "Valeur attendue: $([Math]::Round($expectedCenterValue, 6))" -ForegroundColor White
Write-Host "Résultat: $(if ($centerValueCorrect) { "Correct" } else { "Incorrect" })" -ForegroundColor $(if ($centerValueCorrect) { "Green" } else { "Red" })

# Test 2: Symétrie du noyau gaussien
Write-Host "`n=== Test 2: Symétrie du noyau gaussien ===" -ForegroundColor Magenta
$symmetryTestPoints = @(0.5, 1, 1.5, 2, 2.5)
$symmetryCorrect = $true
Write-Host "Vérification de la symétrie du noyau gaussien:" -ForegroundColor White
Write-Host "| Point | Valeur à +u | Valeur à -u | Différence |" -ForegroundColor White
Write-Host "|-------|------------|------------|------------|" -ForegroundColor White
foreach ($point in $symmetryTestPoints) {
    $positiveValue = Get-GaussianKernel -U $point
    $negativeValue = Get-GaussianKernel -U (-$point)
    $difference = [Math]::Abs($positiveValue - $negativeValue)
    $isSymmetric = $difference -lt 0.0001
    if (-not $isSymmetric) {
        $symmetryCorrect = $false
    }
    Write-Host "| $point | $([Math]::Round($positiveValue, 6)) | $([Math]::Round($negativeValue, 6)) | $([Math]::Round($difference, 6)) |" -ForegroundColor $(if ($isSymmetric) { "Green" } else { "Red" })
}
Write-Host "`nSymétrie du noyau gaussien: $(if ($symmetryCorrect) { "Correcte" } else { "Incorrecte" })" -ForegroundColor $(if ($symmetryCorrect) { "Green" } else { "Red" })

# Test 3: Intégration du noyau gaussien
Write-Host "`n=== Test 3: Intégration du noyau gaussien ===" -ForegroundColor Magenta
# L'intégrale du noyau gaussien sur l'intervalle [-3, 3] devrait être proche de 1 (environ 0.9973)
$integrationPoints = -3..3  # Points de -3 à 3 avec un pas de 1
$integrationValues = $integrationPoints | ForEach-Object { Get-GaussianKernel -U $_ }
$integrationSum = ($integrationValues | Measure-Object -Sum).Sum
$integrationCorrect = [Math]::Abs($integrationSum - 0.9973) -lt 0.1  # Tolérance large car approximation grossière
Write-Host "Intégrale approximative du noyau gaussien sur [-3, 3]: $([Math]::Round($integrationSum, 4))" -ForegroundColor White
Write-Host "Valeur attendue: environ 0.9973" -ForegroundColor White
Write-Host "Résultat: $(if ($integrationCorrect) { "Approximativement correct" } else { "Incorrect" })" -ForegroundColor $(if ($integrationCorrect) { "Green" } else { "Red" })

# Test 4: Estimation de densité par noyau gaussien
Write-Host "`n=== Test 4: Estimation de densité par noyau gaussien ===" -ForegroundColor Magenta
# Calculer la densité à différents points
$densityPoints = @(70, 85, 100, 115, 130)
$bandwidth = 0  # Utiliser la largeur de bande optimale
Write-Host "Estimation de densité par noyau gaussien pour une distribution normale (μ=100, σ=15):" -ForegroundColor White
Write-Host "| Point | Densité estimée |" -ForegroundColor White
Write-Host "|-------|----------------|" -ForegroundColor White
foreach ($point in $densityPoints) {
    $density = Get-GaussianKernelDensity -X $point -Data $normalData -Bandwidth $bandwidth
    Write-Host "| $point | $([Math]::Round($density, 6)) |" -ForegroundColor Green
}

# Vérifier que la densité est maximale au centre de la distribution
$densities = $densityPoints | ForEach-Object { 
    [PSCustomObject]@{
        Point = $_
        Density = Get-GaussianKernelDensity -X $_ -Data $normalData -Bandwidth $bandwidth
    }
}
$maxDensityPoint = ($densities | Sort-Object -Property Density -Descending)[0].Point
$densityCorrect = [Math]::Abs($maxDensityPoint - 100) -lt 5  # Tolérance de 5 unités
Write-Host "`nPoint de densité maximale: $maxDensityPoint" -ForegroundColor White
Write-Host "Point attendu: environ 100" -ForegroundColor White
Write-Host "Résultat: $(if ($densityCorrect) { "Approximativement correct" } else { "Incorrect" })" -ForegroundColor $(if ($densityCorrect) { "Green" } else { "Red" })

# Test 5: Largeur de bande optimale
Write-Host "`n=== Test 5: Largeur de bande optimale ===" -ForegroundColor Magenta
# Calculer la densité avec différentes largeurs de bande
$bandwidths = @(1, 5, 10, 15, 20)
$testPoint = 100  # Point central
Write-Host "Estimation de densité au point central (x=100) avec différentes largeurs de bande:" -ForegroundColor White
Write-Host "| Largeur de bande | Densité estimée |" -ForegroundColor White
Write-Host "|------------------|----------------|" -ForegroundColor White
foreach ($bw in $bandwidths) {
    $density = Get-GaussianKernelDensity -X $testPoint -Data $normalData -Bandwidth $bw
    Write-Host "| $bw | $([Math]::Round($density, 6)) |" -ForegroundColor Green
}

# Calculer la largeur de bande optimale (règle de Silverman)
$stdDev = [Math]::Sqrt(($normalData | ForEach-Object { [Math]::Pow($_ - ($normalData | Measure-Object -Average).Average, 2) } | Measure-Object -Average).Average)
$sortedData = $normalData | Sort-Object
$q1Index = [Math]::Floor($sortedData.Count * 0.25)
$q3Index = [Math]::Floor($sortedData.Count * 0.75)
$q1 = $sortedData[$q1Index]
$q3 = $sortedData[$q3Index]
$iqr = $q3 - $q1
$minValue = [Math]::Min($stdDev, $iqr / 1.34)
$optimalBandwidth = 0.9 * $minValue * [Math]::Pow($normalData.Count, -0.2)
Write-Host "`nLargeur de bande optimale (règle de Silverman): $([Math]::Round($optimalBandwidth, 2))" -ForegroundColor White
$optimalDensity = Get-GaussianKernelDensity -X $testPoint -Data $normalData -Bandwidth $optimalBandwidth
Write-Host "Densité estimée avec largeur de bande optimale: $([Math]::Round($optimalDensity, 6))" -ForegroundColor Green

# Résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
$allTestsPassed = $centerValueCorrect -and $symmetryCorrect -and $integrationCorrect -and $densityCorrect
Write-Host "Tous les tests ont été exécutés." -ForegroundColor Green
Write-Host "Résultat global: $(if ($allTestsPassed) { "Tous les tests ont réussi" } else { "Certains tests ont échoué" })" -ForegroundColor $(if ($allTestsPassed) { "Green" } else { "Red" })
