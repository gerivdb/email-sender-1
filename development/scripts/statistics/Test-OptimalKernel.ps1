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

# Test 1: Sélection du noyau optimal pour une distribution normale
Write-Host "`n=== Test 1: Sélection du noyau optimal pour une distribution normale ===" -ForegroundColor Magenta
$normalOptimalKernel = Get-OptimalKernel -Data $normalData -Objective "Balance" -DataCharacteristics "Normal"
Write-Host "Noyau optimal pour une distribution normale: $normalOptimalKernel" -ForegroundColor Green

# Test 2: Sélection du noyau optimal pour une distribution asymétrique
Write-Host "`n=== Test 2: Sélection du noyau optimal pour une distribution asymétrique ===" -ForegroundColor Magenta
$skewedOptimalKernel = Get-OptimalKernel -Data $positiveSkewData -Objective "Balance" -DataCharacteristics "Skewed"
Write-Host "Noyau optimal pour une distribution asymétrique: $skewedOptimalKernel" -ForegroundColor Green

# Test 3: Sélection du noyau optimal pour une distribution multimodale
Write-Host "`n=== Test 3: Sélection du noyau optimal pour une distribution multimodale ===" -ForegroundColor Magenta
$multimodalOptimalKernel = Get-OptimalKernel -Data $multimodalData -Objective "Balance" -DataCharacteristics "Multimodal"
Write-Host "Noyau optimal pour une distribution multimodale: $multimodalOptimalKernel" -ForegroundColor Green

# Test 4: Sélection du noyau optimal pour un petit échantillon
Write-Host "`n=== Test 4: Sélection du noyau optimal pour un petit échantillon ===" -ForegroundColor Magenta
$smallSampleOptimalKernel = Get-OptimalKernel -Data $smallSampleData -Objective "Balance" -DataCharacteristics "Sparse"
Write-Host "Noyau optimal pour un petit échantillon: $smallSampleOptimalKernel" -ForegroundColor Green

# Test 5: Sélection du noyau optimal en fonction de l'objectif
Write-Host "`n=== Test 5: Sélection du noyau optimal en fonction de l'objectif ===" -ForegroundColor Magenta
$precisionKernel = Get-OptimalKernel -Data $normalData -Objective "Precision" -DataCharacteristics "Normal"
$smoothnessKernel = Get-OptimalKernel -Data $normalData -Objective "Smoothness" -DataCharacteristics "Normal"
$speedKernel = Get-OptimalKernel -Data $normalData -Objective "Speed" -DataCharacteristics "Normal"
$balanceKernel = Get-OptimalKernel -Data $normalData -Objective "Balance" -DataCharacteristics "Normal"

Write-Host "Noyau optimal pour la précision: $precisionKernel" -ForegroundColor Green
Write-Host "Noyau optimal pour le lissage: $smoothnessKernel" -ForegroundColor Green
Write-Host "Noyau optimal pour la vitesse: $speedKernel" -ForegroundColor Green
Write-Host "Noyau optimal pour l'équilibre: $balanceKernel" -ForegroundColor Green

# Test 6: Estimation de densité avec le noyau optimal
Write-Host "`n=== Test 6: Estimation de densité avec le noyau optimal ===" -ForegroundColor Magenta
$testPoint = 100
$optimalDensity = Get-OptimalKernelDensity -X $testPoint -Data $normalData -Objective "Balance"
$gaussianDensity = Get-GaussianKernelDensity -X $testPoint -Data $normalData
$epanechnikovDensity = Get-EpanechnikovKernelDensity -X $testPoint -Data $normalData
$triangularDensity = Get-TriangularKernelDensity -X $testPoint -Data $normalData

Write-Host "Densité au point $testPoint avec le noyau optimal: $([Math]::Round($optimalDensity, 6))" -ForegroundColor Green
Write-Host "Densité au point $testPoint avec le noyau gaussien: $([Math]::Round($gaussianDensity, 6))" -ForegroundColor Green
Write-Host "Densité au point $testPoint avec le noyau d'Epanechnikov: $([Math]::Round($epanechnikovDensity, 6))" -ForegroundColor Green
Write-Host "Densité au point $testPoint avec le noyau triangulaire: $([Math]::Round($triangularDensity, 6))" -ForegroundColor Green

# Résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
Write-Host "Tous les tests ont été exécutés." -ForegroundColor Green
Write-Host "Vérifiez les résultats pour vous assurer que la sélection du noyau optimal est appropriée." -ForegroundColor Green
