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

# Chemin du module Ã  tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\PRAnalysisCache.psm1"
Write-Host "Chemin du module: $modulePath"

# VÃ©rifier que le module existe
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module PRAnalysisCache.psm1 non trouvÃ© Ã  l'emplacement: $modulePath"
    exit 1
}

# Importer le module
Import-Module $modulePath -Force
Write-Host "Module importÃ© avec succÃ¨s."

# CrÃ©er un rÃ©pertoire de test
$testCachePath = Join-Path -Path $env:TEMP -ChildPath "PRCachePerformanceTest"
if (-not (Test-Path -Path $testCachePath)) {
    New-Item -Path $testCachePath -ItemType Directory -Force | Out-Null
    Write-Host "RÃ©pertoire de test crÃ©Ã©: $testCachePath"
} else {
    # Nettoyer le rÃ©pertoire
    Get-ChildItem -Path $testCachePath -File | Remove-Item -Force
    Write-Host "RÃ©pertoire de test nettoyÃ©: $testCachePath"
}

# CrÃ©er un cache
$cache = New-PRAnalysisCache -MaxMemoryItems 1000
if ($null -eq $cache) {
    Write-Error "Impossible de crÃ©er le cache."
    exit 1
}
Write-Host "Cache crÃ©Ã© avec succÃ¨s."

# Rediriger le chemin du cache vers le rÃ©pertoire de test
$cache.DiskCachePath = $testCachePath
Write-Host "Chemin du cache configurÃ©: $($cache.DiskCachePath)"

# Fonction pour mesurer le temps d'exÃ©cution
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

# Test 1: Mesurer le temps d'ajout d'Ã©lÃ©ments
Write-Host "`nTest 1: Temps d'ajout d'Ã©lÃ©ments" -ForegroundColor Cyan
$itemCount = 100
$addTime = Measure-ExecutionTime {
    for ($i = 1; $i -le $itemCount; $i++) {
        $cache.SetItem("Key$i", "Value$i", (New-TimeSpan -Hours 1))
    }
}
Write-Host "Temps pour ajouter $itemCount Ã©lÃ©ments: $($addTime.TotalSeconds) secondes"
Write-Host "Temps moyen par Ã©lÃ©ment: $($addTime.TotalMilliseconds / $itemCount) ms"

# Test 2: Mesurer le temps de rÃ©cupÃ©ration d'Ã©lÃ©ments (premiÃ¨re passe)
Write-Host "`nTest 2: Temps de rÃ©cupÃ©ration d'Ã©lÃ©ments (premiÃ¨re passe)" -ForegroundColor Cyan
$getTime1 = Measure-ExecutionTime {
    for ($i = 1; $i -le $itemCount; $i++) {
        $null = $cache.GetItem("Key$i")
    }
}
Write-Host "Temps pour rÃ©cupÃ©rer $itemCount Ã©lÃ©ments (premiÃ¨re passe): $($getTime1.TotalSeconds) secondes"
Write-Host "Temps moyen par Ã©lÃ©ment: $($getTime1.TotalMilliseconds / $itemCount) ms"

# Test 3: Mesurer le temps de rÃ©cupÃ©ration d'Ã©lÃ©ments (deuxiÃ¨me passe)
Write-Host "`nTest 3: Temps de rÃ©cupÃ©ration d'Ã©lÃ©ments (deuxiÃ¨me passe)" -ForegroundColor Cyan
$getTime2 = Measure-ExecutionTime {
    for ($i = 1; $i -le $itemCount; $i++) {
        $null = $cache.GetItem("Key$i")
    }
}
Write-Host "Temps pour rÃ©cupÃ©rer $itemCount Ã©lÃ©ments (deuxiÃ¨me passe): $($getTime2.TotalSeconds) secondes"
Write-Host "Temps moyen par Ã©lÃ©ment: $($getTime2.TotalMilliseconds / $itemCount) ms"

# Test 4: Mesurer le temps de suppression d'Ã©lÃ©ments
Write-Host "`nTest 4: Temps de suppression d'Ã©lÃ©ments" -ForegroundColor Cyan
$removeTime = Measure-ExecutionTime {
    for ($i = 1; $i -le $itemCount; $i++) {
        $cache.RemoveItem("Key$i")
    }
}
Write-Host "Temps pour supprimer $itemCount Ã©lÃ©ments: $($removeTime.TotalSeconds) secondes"
Write-Host "Temps moyen par Ã©lÃ©ment: $($removeTime.TotalMilliseconds / $itemCount) ms"

# Test 5: Mesurer les performances avec des donnÃ©es de diffÃ©rentes tailles
Write-Host "`nTest 5: Performances avec des donnÃ©es de diffÃ©rentes tailles" -ForegroundColor Cyan

# CrÃ©er des donnÃ©es de test de diffÃ©rentes tailles
$smallData = "Small test data"
$mediumData = "A" * 10KB
$largeData = "B" * 100KB
$veryLargeData = "C" * 1MB

# Mesurer le temps d'ajout d'un petit Ã©lÃ©ment
$smallTime = Measure-ExecutionTime { $cache.SetItem("SmallKey", $smallData, (New-TimeSpan -Hours 1)) }
Write-Host "Temps d'ajout d'un petit Ã©lÃ©ment ($(($smallData.Length) / 1KB) KB): $($smallTime.TotalMilliseconds) ms"

# Mesurer le temps d'ajout d'un Ã©lÃ©ment moyen
$mediumTime = Measure-ExecutionTime { $cache.SetItem("MediumKey", $mediumData, (New-TimeSpan -Hours 1)) }
Write-Host "Temps d'ajout d'un Ã©lÃ©ment moyen ($(($mediumData.Length) / 1KB) KB): $($mediumTime.TotalMilliseconds) ms"

# Mesurer le temps d'ajout d'un grand Ã©lÃ©ment
$largeTime = Measure-ExecutionTime { $cache.SetItem("LargeKey", $largeData, (New-TimeSpan -Hours 1)) }
Write-Host "Temps d'ajout d'un grand Ã©lÃ©ment ($(($largeData.Length) / 1KB) KB): $($largeTime.TotalMilliseconds) ms"

# Mesurer le temps d'ajout d'un trÃ¨s grand Ã©lÃ©ment
$veryLargeTime = Measure-ExecutionTime { $cache.SetItem("VeryLargeKey", $veryLargeData, (New-TimeSpan -Hours 1)) }
Write-Host "Temps d'ajout d'un trÃ¨s grand Ã©lÃ©ment ($(($veryLargeData.Length) / 1KB) KB): $($veryLargeTime.TotalMilliseconds) ms"

# Test 6: Mesurer les performances du nettoyage du cache
Write-Host "`nTest 6: Performances du nettoyage du cache" -ForegroundColor Cyan

# CrÃ©er un cache avec une limite de 500 Ã©lÃ©ments
$cleanupCache = New-PRAnalysisCache -MaxMemoryItems 500
$cleanupCache.DiskCachePath = $testCachePath

# Ajouter plus d'Ã©lÃ©ments que la limite
for ($i = 1; $i -le 1000; $i++) {
    $cleanupCache.SetItem("CleanupKey$i", "Value$i", (New-TimeSpan -Hours 1))
}

# Mesurer le temps de nettoyage du cache
$cleanupTime = Measure-ExecutionTime {
    $cleanupCache.CleanMemoryCache()
}
Write-Host "Temps de nettoyage du cache avec 1000 Ã©lÃ©ments: $($cleanupTime.TotalMilliseconds) ms"

# VÃ©rifier que le cache a Ã©tÃ© nettoyÃ©
Write-Host "Nombre d'Ã©lÃ©ments en mÃ©moire aprÃ¨s nettoyage: $($cleanupCache.MemoryCache.Count)"

# RÃ©sumÃ© des performances
Write-Host "`nRÃ©sumÃ© des performances:" -ForegroundColor Green
Write-Host "Temps d'ajout de $itemCount Ã©lÃ©ments: $($addTime.TotalSeconds) secondes"
Write-Host "Temps de rÃ©cupÃ©ration de $itemCount Ã©lÃ©ments (premiÃ¨re passe): $($getTime1.TotalSeconds) secondes"
Write-Host "Temps de rÃ©cupÃ©ration de $itemCount Ã©lÃ©ments (deuxiÃ¨me passe): $($getTime2.TotalSeconds) secondes"
Write-Host "Temps de suppression de $itemCount Ã©lÃ©ments: $($removeTime.TotalSeconds) secondes"
Write-Host "Temps d'ajout d'un petit Ã©lÃ©ment ($(($smallData.Length) / 1KB) KB): $($smallTime.TotalMilliseconds) ms"
Write-Host "Temps d'ajout d'un Ã©lÃ©ment moyen ($(($mediumData.Length) / 1KB) KB): $($mediumTime.TotalMilliseconds) ms"
Write-Host "Temps d'ajout d'un grand Ã©lÃ©ment ($(($largeData.Length) / 1KB) KB): $($largeTime.TotalMilliseconds) ms"
Write-Host "Temps d'ajout d'un trÃ¨s grand Ã©lÃ©ment ($(($veryLargeData.Length) / 1KB) KB): $($veryLargeTime.TotalMilliseconds) ms"
Write-Host "Temps de nettoyage du cache avec 1000 Ã©lÃ©ments: $($cleanupTime.TotalMilliseconds) ms"

Write-Host "`nTous les tests de performance ont Ã©tÃ© exÃ©cutÃ©s avec succÃ¨s!" -ForegroundColor Green
