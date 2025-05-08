<#
.SYNOPSIS
    Script de test pour le noyau uniforme (rectangular) dans l'estimation de densité par noyau.

.DESCRIPTION
    Ce script teste les fonctions du noyau uniforme (rectangular) pour l'estimation de densité par noyau.
    Il vérifie que les valeurs du noyau sont correctes et que l'estimation de densité fonctionne correctement.

.NOTES
    Auteur: Augment AI
    Version: 1.0
    Date de création: 2023-05-16
#>

# Importer le module du noyau uniforme
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "UniformKernel.ps1"
if (Test-Path $modulePath) {
    . $modulePath
} else {
    Write-Error "Le module UniformKernel.ps1 n'a pas été trouvé dans le répertoire $PSScriptRoot."
    exit
}

# Test 1: Valeurs du noyau uniforme
Write-Host "`n=== Test 1: Valeurs du noyau uniforme ===" -ForegroundColor Magenta
$testPoints = @(0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5)
Write-Host "Valeurs du noyau uniforme pour différents points:" -ForegroundColor White
Write-Host "| Point | Valeur du noyau |" -ForegroundColor White
Write-Host "|-------|----------------|" -ForegroundColor White
foreach ($point in $testPoints) {
    $kernelValue = Get-UniformKernel -U $point
    Write-Host "| $point | $([Math]::Round($kernelValue, 6)) |" -ForegroundColor Green
}

# Vérifier que la valeur au centre (u=0) est correcte
$centerValue = Get-UniformKernel -U 0
$expectedCenterValue = 0.5
$centerValueCorrect = [Math]::Abs($centerValue - $expectedCenterValue) -lt 0.0001
Write-Host "`nValeur au centre (u=0): $([Math]::Round($centerValue, 6))" -ForegroundColor White
Write-Host "Valeur attendue: $([Math]::Round($expectedCenterValue, 6))" -ForegroundColor White
Write-Host "Résultat: $(if ($centerValueCorrect) { "Correct" } else { "Incorrect" })" -ForegroundColor $(if ($centerValueCorrect) { "Green" } else { "Red" })

# Vérifier que la valeur à la limite (u=1) est correcte
$boundaryValue = Get-UniformKernel -U 1
$expectedBoundaryValue = 0.5
$boundaryValueCorrect = [Math]::Abs($boundaryValue - $expectedBoundaryValue) -lt 0.0001
Write-Host "`nValeur à la limite (u=1): $([Math]::Round($boundaryValue, 6))" -ForegroundColor White
Write-Host "Valeur attendue: $([Math]::Round($expectedBoundaryValue, 6))" -ForegroundColor White
Write-Host "Résultat: $(if ($boundaryValueCorrect) { "Correct" } else { "Incorrect" })" -ForegroundColor $(if ($boundaryValueCorrect) { "Green" } else { "Red" })

# Vérifier que la valeur en dehors du support (u=1.5) est correcte
$outsideValue = Get-UniformKernel -U 1.5
$expectedOutsideValue = 0
$outsideValueCorrect = [Math]::Abs($outsideValue - $expectedOutsideValue) -lt 0.0001
Write-Host "`nValeur en dehors du support (u=1.5): $([Math]::Round($outsideValue, 6))" -ForegroundColor White
Write-Host "Valeur attendue: $([Math]::Round($expectedOutsideValue, 6))" -ForegroundColor White
Write-Host "Résultat: $(if ($outsideValueCorrect) { "Correct" } else { "Incorrect" })" -ForegroundColor $(if ($outsideValueCorrect) { "Green" } else { "Red" })

# Test 2: Intégration du noyau uniforme
Write-Host "`n=== Test 2: Intégration du noyau uniforme ===" -ForegroundColor Magenta

# Calculer l'intégrale numérique du noyau uniforme sur [-3, 3]
$stepSize = 0.01
$range = -3..3 | ForEach-Object { $_ * $stepSize }
$integral = 0

foreach ($x in $range) {
    $integral += Get-UniformKernel -U $x * $stepSize
}

$expectedIntegral = 1.0
$integralCorrect = [Math]::Abs($integral - $expectedIntegral) -lt 0.05  # Tolérance de 5%
Write-Host "Intégrale numérique du noyau uniforme sur [-3, 3]: $([Math]::Round($integral, 6))" -ForegroundColor White
Write-Host "Valeur attendue: $([Math]::Round($expectedIntegral, 6))" -ForegroundColor White
Write-Host "Résultat: $(if ($integralCorrect) { "Approximativement correct" } else { "Incorrect" })" -ForegroundColor $(if ($integralCorrect) { "Green" } else { "Red" })

# Test 3: Estimation de densité avec le noyau uniforme
Write-Host "`n=== Test 3: Estimation de densité avec le noyau uniforme ===" -ForegroundColor Magenta

# Générer des données normales
$normalData = 1..100 | ForEach-Object {
    # Méthode Box-Muller pour générer des variables aléatoires normales
    $u1 = Get-Random -Minimum 0.0001 -Maximum 0.9999
    $u2 = Get-Random -Minimum 0.0001 -Maximum 0.9999
    $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
    
    # Transformer pour obtenir une distribution normale avec moyenne 100 et écart-type 15
    100 + 15 * $z
}

# Calculer la largeur de bande optimale
$bandwidth = 0  # Utiliser la valeur par défaut (calculée automatiquement)
$actualBandwidth = 0

# Calculer la densité pour différents points
$densityPoints = 50..150
$densities = $densityPoints | ForEach-Object { 
    if ($actualBandwidth -eq 0) {
        $density = Get-UniformKernelDensity -X $_ -Data $normalData -Bandwidth $bandwidth
        # Capturer la largeur de bande calculée automatiquement
        $actualBandwidth = $bandwidth
    } else {
        $density = Get-UniformKernelDensity -X $_ -Data $normalData -Bandwidth $actualBandwidth
    }
    [PSCustomObject]@{
        Point = $_
        Density = $density
    }
}

# Afficher les résultats
Write-Host "Largeur de bande optimale calculée: $actualBandwidth" -ForegroundColor White
Write-Host "Densités calculées pour quelques points:" -ForegroundColor White
Write-Host "| Point | Densité |" -ForegroundColor White
Write-Host "|-------|---------|" -ForegroundColor White
foreach ($density in $densities | Select-Object -First 5) {
    Write-Host "| $($density.Point) | $([Math]::Round($density.Density, 6)) |" -ForegroundColor Green
}
Write-Host "..." -ForegroundColor White
foreach ($density in $densities | Select-Object -Last 5) {
    Write-Host "| $($density.Point) | $([Math]::Round($density.Density, 6)) |" -ForegroundColor Green
}

# Vérifier que la densité est maximale au centre de la distribution
$maxDensityPoint = ($densities | Sort-Object -Property Density -Descending)[0].Point
$densityCorrect = [Math]::Abs($maxDensityPoint - 100) -lt 10  # Tolérance de 10 unités
Write-Host "`nPoint de densité maximale: $maxDensityPoint" -ForegroundColor White
Write-Host "Point attendu: environ 100" -ForegroundColor White
Write-Host "Résultat: $(if ($densityCorrect) { "Approximativement correct" } else { "Incorrect" })" -ForegroundColor $(if ($densityCorrect) { "Green" } else { "Red" })

# Test 4: Comparaison avec une distribution uniforme
Write-Host "`n=== Test 4: Comparaison avec une distribution uniforme ===" -ForegroundColor Magenta

# Générer des données uniformes
$uniformData = 1..100 | ForEach-Object { Get-Random -Minimum 50 -Maximum 150 }

# Calculer la largeur de bande optimale
$uniformBandwidth = 0  # Utiliser la valeur par défaut (calculée automatiquement)
$actualUniformBandwidth = 0

# Calculer la densité pour différents points
$uniformDensities = $densityPoints | ForEach-Object { 
    if ($actualUniformBandwidth -eq 0) {
        $density = Get-UniformKernelDensity -X $_ -Data $uniformData -Bandwidth $uniformBandwidth
        # Capturer la largeur de bande calculée automatiquement
        $actualUniformBandwidth = $uniformBandwidth
    } else {
        $density = Get-UniformKernelDensity -X $_ -Data $uniformData -Bandwidth $actualUniformBandwidth
    }
    [PSCustomObject]@{
        Point = $_
        Density = $density
    }
}

# Afficher les résultats
Write-Host "Largeur de bande optimale calculée pour la distribution uniforme: $actualUniformBandwidth" -ForegroundColor White
Write-Host "Densités calculées pour quelques points:" -ForegroundColor White
Write-Host "| Point | Densité |" -ForegroundColor White
Write-Host "|-------|---------|" -ForegroundColor White
foreach ($density in $uniformDensities | Select-Object -First 5) {
    Write-Host "| $($density.Point) | $([Math]::Round($density.Density, 6)) |" -ForegroundColor Green
}
Write-Host "..." -ForegroundColor White
foreach ($density in $uniformDensities | Select-Object -Last 5) {
    Write-Host "| $($density.Point) | $([Math]::Round($density.Density, 6)) |" -ForegroundColor Green
}

# Vérifier que la densité est approximativement constante pour la distribution uniforme
$maxUniformDensity = ($uniformDensities | Measure-Object -Property Density -Maximum).Maximum
$minUniformDensity = ($uniformDensities | Where-Object { $_.Point -ge 60 -and $_.Point -le 140 } | Measure-Object -Property Density -Minimum).Minimum
$uniformityCorrect = ($maxUniformDensity - $minUniformDensity) / $maxUniformDensity -lt 0.5  # Tolérance de 50%
Write-Host "`nDensité maximale: $([Math]::Round($maxUniformDensity, 6))" -ForegroundColor White
Write-Host "Densité minimale (entre 60 et 140): $([Math]::Round($minUniformDensity, 6))" -ForegroundColor White
Write-Host "Variation relative: $([Math]::Round(($maxUniformDensity - $minUniformDensity) / $maxUniformDensity * 100, 2))%" -ForegroundColor White
Write-Host "Résultat: $(if ($uniformityCorrect) { "Approximativement uniforme" } else { "Non uniforme" })" -ForegroundColor $(if ($uniformityCorrect) { "Green" } else { "Red" })

# Résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Magenta
$testsPassed = 0
$testsTotal = 5

if ($centerValueCorrect) { $testsPassed++ }
if ($boundaryValueCorrect) { $testsPassed++ }
if ($outsideValueCorrect) { $testsPassed++ }
if ($integralCorrect) { $testsPassed++ }
if ($densityCorrect) { $testsPassed++ }

Write-Host "Tests réussis: $testsPassed / $testsTotal" -ForegroundColor White
Write-Host "Résultat global: $(if ($testsPassed -eq $testsTotal) { "Tous les tests ont réussi" } else { "Certains tests ont échoué" })" -ForegroundColor $(if ($testsPassed -eq $testsTotal) { "Green" } else { "Yellow" })
