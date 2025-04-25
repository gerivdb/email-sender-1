#Requires -Version 5.1
<#
.SYNOPSIS
    Test de performance pour le module PRAnalysisCache.
.DESCRIPTION
    Ce script teste les performances du module PRAnalysisCache.
.NOTES
    Author: Augment Agent
    Version: 1.0
#>

# Chemin du module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\PRAnalysisCache.psm1"
Write-Host "Chemin du module: $modulePath"

# Vérifier que le module existe
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module PRAnalysisCache.psm1 non trouvé à l'emplacement: $modulePath"
    exit 1
}

# Importer le module
Import-Module $modulePath -Force
Write-Host "Module importé avec succès."

# Créer un répertoire de test
$testCachePath = Join-Path -Path $env:TEMP -ChildPath "PRCachePerformanceTest"
if (-not (Test-Path -Path $testCachePath)) {
    New-Item -Path $testCachePath -ItemType Directory -Force | Out-Null
    Write-Host "Répertoire de test créé: $testCachePath"
} else {
    # Nettoyer le répertoire
    Get-ChildItem -Path $testCachePath -File | Remove-Item -Force
    Write-Host "Répertoire de test nettoyé: $testCachePath"
}

# Créer un cache
$cache = New-PRAnalysisCache -MaxMemoryItems 1000
if ($null -eq $cache) {
    Write-Error "Impossible de créer le cache."
    exit 1
}
Write-Host "Cache créé avec succès."

# Rediriger le chemin du cache vers le répertoire de test
$cache.DiskCachePath = $testCachePath
Write-Host "Chemin du cache configuré: $($cache.DiskCachePath)"

# Fonction pour mesurer le temps d'exécution
function Measure-ExecutionTime {
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock
    )

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    & $ScriptBlock
    $stopwatch.Stop()

    return $stopwatch.Elapsed
}

# Test 1: Mesurer le temps d'ajout d'éléments
Write-Host "`nTest 1: Temps d'ajout d'éléments" -ForegroundColor Cyan
$itemCount = 100
$addTime = Measure-ExecutionTime {
    for ($i = 1; $i -le $itemCount; $i++) {
        $cache.SetItem("Key$i", "Value$i", (New-TimeSpan -Hours 1))
    }
}
Write-Host "Temps pour ajouter $itemCount éléments: $($addTime.TotalSeconds) secondes"
Write-Host "Temps moyen par élément: $($addTime.TotalMilliseconds / $itemCount) ms"

# Test 2: Mesurer le temps de récupération d'éléments (première passe)
Write-Host "`nTest 2: Temps de récupération d'éléments (première passe)" -ForegroundColor Cyan
$getTime1 = Measure-ExecutionTime {
    for ($i = 1; $i -le $itemCount; $i++) {
        $null = $cache.GetItem("Key$i")
    }
}
Write-Host "Temps pour récupérer $itemCount éléments (première passe): $($getTime1.TotalSeconds) secondes"
Write-Host "Temps moyen par élément: $($getTime1.TotalMilliseconds / $itemCount) ms"

# Test 3: Mesurer le temps de récupération d'éléments (deuxième passe)
Write-Host "`nTest 3: Temps de récupération d'éléments (deuxième passe)" -ForegroundColor Cyan
$getTime2 = Measure-ExecutionTime {
    for ($i = 1; $i -le $itemCount; $i++) {
        $null = $cache.GetItem("Key$i")
    }
}
Write-Host "Temps pour récupérer $itemCount éléments (deuxième passe): $($getTime2.TotalSeconds) secondes"
Write-Host "Temps moyen par élément: $($getTime2.TotalMilliseconds / $itemCount) ms"

# Test 4: Mesurer le temps de suppression d'éléments
Write-Host "`nTest 4: Temps de suppression d'éléments" -ForegroundColor Cyan
$removeTime = Measure-ExecutionTime {
    for ($i = 1; $i -le $itemCount; $i++) {
        $cache.RemoveItem("Key$i")
    }
}
Write-Host "Temps pour supprimer $itemCount éléments: $($removeTime.TotalSeconds) secondes"
Write-Host "Temps moyen par élément: $($removeTime.TotalMilliseconds / $itemCount) ms"

# Test 5: Mesurer les performances avec des données de différentes tailles
Write-Host "`nTest 5: Performances avec des données de différentes tailles" -ForegroundColor Cyan

# Créer des données de test de différentes tailles
$smallData = "Small test data"
$mediumData = "A" * 10KB
$largeData = "B" * 100KB
$veryLargeData = "C" * 1MB

# Mesurer le temps d'ajout d'un petit élément
$smallTime = Measure-ExecutionTime { $cache.SetItem("SmallKey", $smallData, (New-TimeSpan -Hours 1)) }
Write-Host "Temps d'ajout d'un petit élément ($(($smallData.Length) / 1KB) KB): $($smallTime.TotalMilliseconds) ms"

# Mesurer le temps d'ajout d'un élément moyen
$mediumTime = Measure-ExecutionTime { $cache.SetItem("MediumKey", $mediumData, (New-TimeSpan -Hours 1)) }
Write-Host "Temps d'ajout d'un élément moyen ($(($mediumData.Length) / 1KB) KB): $($mediumTime.TotalMilliseconds) ms"

# Mesurer le temps d'ajout d'un grand élément
$largeTime = Measure-ExecutionTime { $cache.SetItem("LargeKey", $largeData, (New-TimeSpan -Hours 1)) }
Write-Host "Temps d'ajout d'un grand élément ($(($largeData.Length) / 1KB) KB): $($largeTime.TotalMilliseconds) ms"

# Mesurer le temps d'ajout d'un très grand élément
$veryLargeTime = Measure-ExecutionTime { $cache.SetItem("VeryLargeKey", $veryLargeData, (New-TimeSpan -Hours 1)) }
Write-Host "Temps d'ajout d'un très grand élément ($(($veryLargeData.Length) / 1KB) KB): $($veryLargeTime.TotalMilliseconds) ms"

# Test 6: Mesurer les performances du nettoyage du cache
Write-Host "`nTest 6: Performances du nettoyage du cache" -ForegroundColor Cyan

# Créer un cache avec une limite de 500 éléments
$cleanupCache = New-PRAnalysisCache -MaxMemoryItems 500
$cleanupCache.DiskCachePath = $testCachePath

# Ajouter plus d'éléments que la limite
for ($i = 1; $i -le 1000; $i++) {
    $cleanupCache.SetItem("CleanupKey$i", "Value$i", (New-TimeSpan -Hours 1))
}

# Mesurer le temps de nettoyage du cache
$cleanupTime = Measure-ExecutionTime {
    $cleanupCache.CleanMemoryCache()
}
Write-Host "Temps de nettoyage du cache avec 1000 éléments: $($cleanupTime.TotalMilliseconds) ms"

# Vérifier que le cache a été nettoyé
Write-Host "Nombre d'éléments en mémoire après nettoyage: $($cleanupCache.MemoryCache.Count)"

# Résumé des performances
Write-Host "`nRésumé des performances:" -ForegroundColor Green
Write-Host "Temps d'ajout de $itemCount éléments: $($addTime.TotalSeconds) secondes"
Write-Host "Temps de récupération de $itemCount éléments (première passe): $($getTime1.TotalSeconds) secondes"
Write-Host "Temps de récupération de $itemCount éléments (deuxième passe): $($getTime2.TotalSeconds) secondes"
Write-Host "Temps de suppression de $itemCount éléments: $($removeTime.TotalSeconds) secondes"
Write-Host "Temps d'ajout d'un petit élément ($(($smallData.Length) / 1KB) KB): $($smallTime.TotalMilliseconds) ms"
Write-Host "Temps d'ajout d'un élément moyen ($(($mediumData.Length) / 1KB) KB): $($mediumTime.TotalMilliseconds) ms"
Write-Host "Temps d'ajout d'un grand élément ($(($largeData.Length) / 1KB) KB): $($largeTime.TotalMilliseconds) ms"
Write-Host "Temps d'ajout d'un très grand élément ($(($veryLargeData.Length) / 1KB) KB): $($veryLargeTime.TotalMilliseconds) ms"
Write-Host "Temps de nettoyage du cache avec 1000 éléments: $($cleanupTime.TotalMilliseconds) ms"

Write-Host "`nTous les tests de performance ont été exécutés avec succès!" -ForegroundColor Green
