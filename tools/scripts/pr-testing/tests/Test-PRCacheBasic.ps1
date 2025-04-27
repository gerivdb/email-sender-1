#Requires -Version 5.1
<#
.SYNOPSIS
    Test basique pour le module PRAnalysisCache.
.DESCRIPTION
    Ce script teste les fonctionnalitÃ©s de base du module PRAnalysisCache.
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
$testCachePath = Join-Path -Path $env:TEMP -ChildPath "PRCacheBasicTest"
if (-not (Test-Path -Path $testCachePath)) {
    New-Item -Path $testCachePath -ItemType Directory -Force | Out-Null
    Write-Host "RÃ©pertoire de test crÃ©Ã©: $testCachePath"
} else {
    # Nettoyer le rÃ©pertoire
    Get-ChildItem -Path $testCachePath -File | Remove-Item -Force
    Write-Host "RÃ©pertoire de test nettoyÃ©: $testCachePath"
}

# CrÃ©er un cache
$cache = New-PRAnalysisCache -MaxMemoryItems 10
if ($null -eq $cache) {
    Write-Error "Impossible de crÃ©er le cache."
    exit 1
}
Write-Host "Cache crÃ©Ã© avec succÃ¨s."

# Rediriger le chemin du cache vers le rÃ©pertoire de test
$cache.DiskCachePath = $testCachePath
Write-Host "Chemin du cache configurÃ©: $($cache.DiskCachePath)"

# Ajouter un Ã©lÃ©ment au cache
$cache.SetItem("TestKey", "TestValue", (New-TimeSpan -Hours 1))
Write-Host "Ã‰lÃ©ment ajoutÃ© au cache."

# VÃ©rifier que l'Ã©lÃ©ment a Ã©tÃ© ajoutÃ©
$value = $cache.GetItem("TestKey")
if ($value -eq "TestValue") {
    Write-Host "Ã‰lÃ©ment rÃ©cupÃ©rÃ© avec succÃ¨s: $value" -ForegroundColor Green
} else {
    Write-Error "Impossible de rÃ©cupÃ©rer l'Ã©lÃ©ment du cache."
    exit 1
}

# VÃ©rifier que le fichier de cache a Ã©tÃ© crÃ©Ã©
$cacheFile = Join-Path -Path $testCachePath -ChildPath "$($cache.NormalizeKey("TestKey")).xml"
if (Test-Path -Path $cacheFile) {
    Write-Host "Fichier de cache crÃ©Ã©: $cacheFile" -ForegroundColor Green
} else {
    Write-Error "Fichier de cache non crÃ©Ã©: $cacheFile"
    exit 1
}

# Supprimer l'Ã©lÃ©ment du cache
$cache.RemoveItem("TestKey")
Write-Host "Ã‰lÃ©ment supprimÃ© du cache."

# VÃ©rifier que l'Ã©lÃ©ment a Ã©tÃ© supprimÃ©
$value = $cache.GetItem("TestKey")
if ($null -eq $value) {
    Write-Host "Ã‰lÃ©ment correctement supprimÃ© du cache." -ForegroundColor Green
} else {
    Write-Error "L'Ã©lÃ©ment n'a pas Ã©tÃ© supprimÃ© du cache."
    exit 1
}

# VÃ©rifier que le fichier de cache a Ã©tÃ© supprimÃ©
if (-not (Test-Path -Path $cacheFile)) {
    Write-Host "Fichier de cache supprimÃ©." -ForegroundColor Green
} else {
    Write-Error "Le fichier de cache n'a pas Ã©tÃ© supprimÃ©."
    exit 1
}

# Ajouter plusieurs Ã©lÃ©ments au cache
for ($i = 1; $i -le 5; $i++) {
    $cache.SetItem("Key$i", "Value$i", (New-TimeSpan -Hours 1))
}
Write-Host "5 Ã©lÃ©ments ajoutÃ©s au cache."

# VÃ©rifier que les Ã©lÃ©ments ont Ã©tÃ© ajoutÃ©s
$allItemsFound = $true
for ($i = 1; $i -le 5; $i++) {
    $value = $cache.GetItem("Key$i")
    if ($value -ne "Value$i") {
        $allItemsFound = $false
        Write-Error "Ã‰lÃ©ment Key$i non trouvÃ© ou valeur incorrecte."
    }
}

if ($allItemsFound) {
    Write-Host "Tous les Ã©lÃ©ments ont Ã©tÃ© correctement ajoutÃ©s au cache." -ForegroundColor Green
}

# Vider le cache
$cache.Clear()
Write-Host "Cache vidÃ©."

# VÃ©rifier que le cache est vide
$cacheFiles = Get-ChildItem -Path $testCachePath -Filter "*.xml"
if ($cacheFiles.Count -eq 0) {
    Write-Host "Cache correctement vidÃ©." -ForegroundColor Green
} else {
    Write-Error "Le cache n'a pas Ã©tÃ© correctement vidÃ©. Nombre de fichiers restants: $($cacheFiles.Count)"
    exit 1
}

Write-Host "Tous les tests ont rÃ©ussi!" -ForegroundColor Green
