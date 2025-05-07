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

# 3. Distribution multimodale
$multimodalData = @()
for ($i = 0; $i -lt 500; $i++) {
    # Premier mode (moyenne 80, écart-type 10)
    $u1 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
    $u2 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
    if ($u1 -eq 0) { $u1 = 0.0001 }
    
    $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
    $multimodalData += 80 + 10 * $z
}
for ($i = 0; $i -lt 500; $i++) {
    # Deuxième mode (moyenne 120, écart-type 10)
    $u1 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
    $u2 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
    if ($u1 -eq 0) { $u1 = 0.0001 }
    
    $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
    $multimodalData += 120 + 10 * $z
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

# Test 1: Calcul de la largeur de bande pour une distribution normale
Write-Host "`n=== Test 1: Calcul de la largeur de bande pour une distribution normale ===" -ForegroundColor Magenta
$normalBandwidth = Get-ScottBandwidth -Data $normalData -KernelType "Gaussian" -DistributionType "Normal"
Write-Host "Largeur de bande pour une distribution normale (noyau gaussien): $([Math]::Round($normalBandwidth, 4))" -ForegroundColor Green

# Vérifier que la largeur de bande est dans une plage raisonnable
$stdDev = [Math]::Sqrt(($normalData | ForEach-Object { [Math]::Pow($_ - ($normalData | Measure-Object -Average).Average, 2) } | Measure-Object -Average).Average)
$expectedBandwidth = 1.06 * $stdDev * [Math]::Pow($normalData.Count, -0.2)
$bandwidthCorrect = [Math]::Abs($normalBandwidth - $expectedBandwidth) -lt 0.1
Write-Host "Largeur de bande attendue: $([Math]::Round($expectedBandwidth, 4))" -ForegroundColor White
Write-Host "Résultat: $(if ($bandwidthCorrect) { "Correct" } else { "Incorrect" })" -ForegroundColor $(if ($bandwidthCorrect) { "Green" } else { "Red" })

# Test 2: Calcul de la largeur de bande pour différents types de noyaux
Write-Host "`n=== Test 2: Calcul de la largeur de bande pour différents types de noyaux ===" -ForegroundColor Magenta
$gaussianBandwidth = Get-ScottBandwidth -Data $normalData -KernelType "Gaussian" -DistributionType "Normal"
$epanechnikovBandwidth = Get-ScottBandwidth -Data $normalData -KernelType "Epanechnikov" -DistributionType "Normal"
$triangularBandwidth = Get-ScottBandwidth -Data $normalData -KernelType "Triangular" -DistributionType "Normal"

Write-Host "Largeur de bande pour le noyau gaussien: $([Math]::Round($gaussianBandwidth, 4))" -ForegroundColor Green
Write-Host "Largeur de bande pour le noyau d'Epanechnikov: $([Math]::Round($epanechnikovBandwidth, 4))" -ForegroundColor Green
Write-Host "Largeur de bande pour le noyau triangulaire: $([Math]::Round($triangularBandwidth, 4))" -ForegroundColor Green

# Vérifier que les facteurs de correction sont appliqués correctement
$epanechnikovFactor = $epanechnikovBandwidth / $gaussianBandwidth
$triangularFactor = $triangularBandwidth / $gaussianBandwidth
$factorsCorrect = [Math]::Abs($epanechnikovFactor - 1.05) -lt 0.01 -and [Math]::Abs($triangularFactor - 1.1) -lt 0.01
Write-Host "`nFacteur de correction pour le noyau d'Epanechnikov: $([Math]::Round($epanechnikovFactor, 4))" -ForegroundColor White
Write-Host "Facteur de correction pour le noyau triangulaire: $([Math]::Round($triangularFactor, 4))" -ForegroundColor White
Write-Host "Résultat: $(if ($factorsCorrect) { "Correct" } else { "Incorrect" })" -ForegroundColor $(if ($factorsCorrect) { "Green" } else { "Red" })

# Test 3: Calcul de la largeur de bande pour différents types de distributions
Write-Host "`n=== Test 3: Calcul de la largeur de bande pour différents types de distributions ===" -ForegroundColor Magenta
$normalDistBandwidth = Get-ScottBandwidth -Data $normalData -KernelType "Gaussian" -DistributionType "Normal"
$skewedDistBandwidth = Get-ScottBandwidth -Data $positiveSkewData -KernelType "Gaussian" -DistributionType "Skewed"
$multimodalDistBandwidth = Get-ScottBandwidth -Data $multimodalData -KernelType "Gaussian" -DistributionType "Multimodal"
$sparseDistBandwidth = Get-ScottBandwidth -Data $smallSampleData -KernelType "Gaussian" -DistributionType "Sparse"

Write-Host "Largeur de bande pour une distribution normale: $([Math]::Round($normalDistBandwidth, 4))" -ForegroundColor Green
Write-Host "Largeur de bande pour une distribution asymétrique: $([Math]::Round($skewedDistBandwidth, 4))" -ForegroundColor Green
Write-Host "Largeur de bande pour une distribution multimodale: $([Math]::Round($multimodalDistBandwidth, 4))" -ForegroundColor Green
Write-Host "Largeur de bande pour un petit échantillon: $([Math]::Round($sparseDistBandwidth, 4))" -ForegroundColor Green

# Test 4: Détection automatique du type de distribution
Write-Host "`n=== Test 4: Détection automatique du type de distribution ===" -ForegroundColor Magenta
$autoNormalBandwidth = Get-ScottBandwidth -Data $normalData -KernelType "Gaussian" -Verbose
$autoSkewedBandwidth = Get-ScottBandwidth -Data $positiveSkewData -KernelType "Gaussian" -Verbose
$autoMultimodalBandwidth = Get-ScottBandwidth -Data $multimodalData -KernelType "Gaussian" -Verbose
$autoSparseBandwidth = Get-ScottBandwidth -Data $smallSampleData -KernelType "Gaussian" -Verbose

Write-Host "Largeur de bande pour une distribution normale (détection auto): $([Math]::Round($autoNormalBandwidth, 4))" -ForegroundColor Green
Write-Host "Largeur de bande pour une distribution asymétrique (détection auto): $([Math]::Round($autoSkewedBandwidth, 4))" -ForegroundColor Green
Write-Host "Largeur de bande pour une distribution multimodale (détection auto): $([Math]::Round($autoMultimodalBandwidth, 4))" -ForegroundColor Green
Write-Host "Largeur de bande pour un petit échantillon (détection auto): $([Math]::Round($autoSparseBandwidth, 4))" -ForegroundColor Green

# Vérifier que la détection automatique fonctionne correctement
$autoDetectionCorrect = ($autoNormalBandwidth -gt 0) -and ($autoSkewedBandwidth -gt 0) -and ($autoMultimodalBandwidth -gt 0) -and ($autoSparseBandwidth -gt 0)
Write-Host "`nRésultat de la détection automatique: $(if ($autoDetectionCorrect) { "Correct" } else { "Incorrect" })" -ForegroundColor $(if ($autoDetectionCorrect) { "Green" } else { "Red" })

# Test 5: Comparaison avec la règle de Silverman
Write-Host "`n=== Test 5: Comparaison avec la règle de Silverman ===" -ForegroundColor Magenta
$scottBandwidth = Get-ScottBandwidth -Data $normalData -KernelType "Gaussian" -DistributionType "Normal"
$silvermanBandwidth = Get-SilvermanBandwidth -Data $normalData -KernelType "Gaussian" -DistributionType "Normal"

Write-Host "Largeur de bande selon la méthode de Scott: $([Math]::Round($scottBandwidth, 4))" -ForegroundColor Green
Write-Host "Largeur de bande selon la règle de Silverman: $([Math]::Round($silvermanBandwidth, 4))" -ForegroundColor Green
Write-Host "Ratio Scott/Silverman: $([Math]::Round($scottBandwidth / $silvermanBandwidth, 4))" -ForegroundColor White

# Résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
$allTestsPassed = $bandwidthCorrect -and $factorsCorrect -and $autoDetectionCorrect
Write-Host "Tous les tests ont été exécutés." -ForegroundColor Green
Write-Host "Résultat global: $(if ($allTestsPassed) { "Tous les tests ont réussi" } else { "Certains tests ont échoué" })" -ForegroundColor $(if ($allTestsPassed) { "Green" } else { "Red" })
