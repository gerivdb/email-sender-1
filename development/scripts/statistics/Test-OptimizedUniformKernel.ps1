<#
.SYNOPSIS
    Script de test pour les fonctions optimisées du noyau uniforme (rectangular).

.DESCRIPTION
    Ce script teste les fonctions optimisées du noyau uniforme (rectangular) pour l'estimation de densité par noyau.
    Il compare les performances des fonctions optimisées avec les fonctions de base et vérifie que les résultats sont cohérents.

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

# Test 1: Comparaison des performances entre les fonctions de base et optimisées
Write-Host "`n=== Test 1: Comparaison des performances ===" -ForegroundColor Magenta

# Générer des données de test
$normalData = 1..1000 | ForEach-Object {
    # Méthode Box-Muller pour générer des variables aléatoires normales
    $u1 = Get-Random -Minimum 0.0001 -Maximum 0.9999
    $u2 = Get-Random -Minimum 0.0001 -Maximum 0.9999
    $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
    
    # Transformer pour obtenir une distribution normale avec moyenne 100 et écart-type 15
    100 + 15 * $z
}

# Points d'évaluation
$evalPoints = 50..150

# Mesurer le temps d'exécution de la fonction de base
$startTime = Get-Date
$densitiesBase = $evalPoints | ForEach-Object { 
    Get-UniformKernelDensity -X $_ -Data $normalData -Bandwidth 10
}
$endTime = Get-Date
$baseTime = ($endTime - $startTime).TotalMilliseconds

# Mesurer le temps d'exécution de la fonction optimisée
$startTime = Get-Date
$densitiesOptimized = $evalPoints | ForEach-Object { 
    Get-OptimizedUniformKernelDensity -X $_ -Data $normalData -Bandwidth 10
}
$endTime = Get-Date
$optimizedTime = ($endTime - $startTime).TotalMilliseconds

# Mesurer le temps d'exécution de la fonction optimisée pour plusieurs points
$startTime = Get-Date
$densitiesMultiplePoints = Get-OptimizedUniformKernelDensityMultiplePoints -EvaluationPoints $evalPoints -Data $normalData -Bandwidth 10
$endTime = Get-Date
$multiplePointsTime = ($endTime - $startTime).TotalMilliseconds

# Afficher les résultats
Write-Host "Temps d'exécution de la fonction de base: $([Math]::Round($baseTime, 2)) ms" -ForegroundColor White
Write-Host "Temps d'exécution de la fonction optimisée: $([Math]::Round($optimizedTime, 2)) ms" -ForegroundColor White
Write-Host "Temps d'exécution de la fonction optimisée pour plusieurs points: $([Math]::Round($multiplePointsTime, 2)) ms" -ForegroundColor White

# Calculer l'accélération
$speedupOptimized = $baseTime / $optimizedTime
$speedupMultiplePoints = $baseTime / $multiplePointsTime

Write-Host "Accélération de la fonction optimisée: $([Math]::Round($speedupOptimized, 2))x" -ForegroundColor $(if ($speedupOptimized -gt 1) { "Green" } else { "Red" })
Write-Host "Accélération de la fonction optimisée pour plusieurs points: $([Math]::Round($speedupMultiplePoints, 2))x" -ForegroundColor $(if ($speedupMultiplePoints -gt 1) { "Green" } else { "Red" })

# Test 2: Vérification de la cohérence des résultats
Write-Host "`n=== Test 2: Vérification de la cohérence des résultats ===" -ForegroundColor Magenta

# Comparer les résultats des fonctions de base et optimisées
$maxDifference = 0
for ($i = 0; $i -lt $evalPoints.Count; $i++) {
    $difference = [Math]::Abs($densitiesBase[$i] - $densitiesOptimized[$i])
    if ($difference -gt $maxDifference) {
        $maxDifference = $difference
    }
}

$maxDifferenceMultiplePoints = 0
for ($i = 0; $i -lt $evalPoints.Count; $i++) {
    $difference = [Math]::Abs($densitiesBase[$i] - $densitiesMultiplePoints[$i].Density)
    if ($difference -gt $maxDifferenceMultiplePoints) {
        $maxDifferenceMultiplePoints = $difference
    }
}

Write-Host "Différence maximale entre la fonction de base et la fonction optimisée: $([Math]::Round($maxDifference, 6))" -ForegroundColor White
Write-Host "Différence maximale entre la fonction de base et la fonction optimisée pour plusieurs points: $([Math]::Round($maxDifferenceMultiplePoints, 6))" -ForegroundColor White

$coherenceOptimized = $maxDifference -lt 0.0001
$coherenceMultiplePoints = $maxDifferenceMultiplePoints -lt 0.0001

Write-Host "Cohérence de la fonction optimisée: $(if ($coherenceOptimized) { "Correcte" } else { "Incorrecte" })" -ForegroundColor $(if ($coherenceOptimized) { "Green" } else { "Red" })
Write-Host "Cohérence de la fonction optimisée pour plusieurs points: $(if ($coherenceMultiplePoints) { "Correcte" } else { "Incorrecte" })" -ForegroundColor $(if ($coherenceMultiplePoints) { "Green" } else { "Red" })

# Test 3: Test de la fonction multidimensionnelle
Write-Host "`n=== Test 3: Test de la fonction multidimensionnelle ===" -ForegroundColor Magenta

# Générer des données de test bidimensionnelles
$data2D = 1..100 | ForEach-Object {
    # Générer des variables aléatoires normales
    $u1 = Get-Random -Minimum 0.0001 -Maximum 0.9999
    $u2 = Get-Random -Minimum 0.0001 -Maximum 0.9999
    $z1 = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
    
    $u3 = Get-Random -Minimum 0.0001 -Maximum 0.9999
    $u4 = Get-Random -Minimum 0.0001 -Maximum 0.9999
    $z2 = [Math]::Sqrt(-2 * [Math]::Log($u3)) * [Math]::Cos(2 * [Math]::PI * $u4)
    
    # Transformer pour obtenir une distribution normale bidimensionnelle
    [PSCustomObject]@{
        X = 100 + 15 * $z1
        Y = 100 + 15 * $z2
    }
}

# Point d'évaluation
$point = [PSCustomObject]@{
    X = 100
    Y = 100
}

# Calculer la densité
$density2D = Get-UniformKernelDensityND -Point $point -Data $data2D

Write-Host "Densité au point (100, 100): $([Math]::Round($density2D, 6))" -ForegroundColor White

# Vérifier que la densité est positive
$density2DCorrect = $density2D -gt 0
Write-Host "Densité positive: $(if ($density2DCorrect) { "Oui" } else { "Non" })" -ForegroundColor $(if ($density2DCorrect) { "Green" } else { "Red" })

# Test 4: Test avec différentes largeurs de bande
Write-Host "`n=== Test 4: Test avec différentes largeurs de bande ===" -ForegroundColor Magenta

# Largeur de bande unique
$bandwidth = 10
$density2DUnique = Get-UniformKernelDensityND -Point $point -Data $data2D -Bandwidth $bandwidth

# Largeur de bande par dimension
$bandwidthByDimension = [PSCustomObject]@{
    X = 10
    Y = 20
}
$density2DByDimension = Get-UniformKernelDensityND -Point $point -Data $data2D -Bandwidth $bandwidthByDimension

Write-Host "Densité avec largeur de bande unique: $([Math]::Round($density2DUnique, 6))" -ForegroundColor White
Write-Host "Densité avec largeur de bande par dimension: $([Math]::Round($density2DByDimension, 6))" -ForegroundColor White

# Test 5: Test avec des données tridimensionnelles
Write-Host "`n=== Test 5: Test avec des données tridimensionnelles ===" -ForegroundColor Magenta

# Générer des données de test tridimensionnelles
$data3D = 1..100 | ForEach-Object {
    # Générer des variables aléatoires normales
    $u1 = Get-Random -Minimum 0.0001 -Maximum 0.9999
    $u2 = Get-Random -Minimum 0.0001 -Maximum 0.9999
    $z1 = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
    
    $u3 = Get-Random -Minimum 0.0001 -Maximum 0.9999
    $u4 = Get-Random -Minimum 0.0001 -Maximum 0.9999
    $z2 = [Math]::Sqrt(-2 * [Math]::Log($u3)) * [Math]::Cos(2 * [Math]::PI * $u4)
    
    $u5 = Get-Random -Minimum 0.0001 -Maximum 0.9999
    $u6 = Get-Random -Minimum 0.0001 -Maximum 0.9999
    $z3 = [Math]::Sqrt(-2 * [Math]::Log($u5)) * [Math]::Cos(2 * [Math]::PI * $u6)
    
    # Transformer pour obtenir une distribution normale tridimensionnelle
    [PSCustomObject]@{
        X = 100 + 15 * $z1
        Y = 100 + 15 * $z2
        Z = 100 + 15 * $z3
    }
}

# Point d'évaluation
$point3D = [PSCustomObject]@{
    X = 100
    Y = 100
    Z = 100
}

# Calculer la densité
$density3D = Get-UniformKernelDensityND -Point $point3D -Data $data3D

Write-Host "Densité au point (100, 100, 100): $([Math]::Round($density3D, 6))" -ForegroundColor White

# Vérifier que la densité est positive
$density3DCorrect = $density3D -gt 0
Write-Host "Densité positive: $(if ($density3DCorrect) { "Oui" } else { "Non" })" -ForegroundColor $(if ($density3DCorrect) { "Green" } else { "Red" })

# Résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Magenta
$testsPassed = 0
$testsTotal = 5

if ($speedupOptimized -gt 1) { $testsPassed++ }
if ($speedupMultiplePoints -gt 1) { $testsPassed++ }
if ($coherenceOptimized) { $testsPassed++ }
if ($density2DCorrect) { $testsPassed++ }
if ($density3DCorrect) { $testsPassed++ }

Write-Host "Tests réussis: $testsPassed / $testsTotal" -ForegroundColor White
Write-Host "Résultat global: $(if ($testsPassed -eq $testsTotal) { "Tous les tests ont réussi" } else { "Certains tests ont échoué" })" -ForegroundColor $(if ($testsPassed -eq $testsTotal) { "Green" } else { "Yellow" })
