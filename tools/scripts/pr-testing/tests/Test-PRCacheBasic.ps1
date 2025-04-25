#Requires -Version 5.1
<#
.SYNOPSIS
    Test basique pour le module PRAnalysisCache.
.DESCRIPTION
    Ce script teste les fonctionnalités de base du module PRAnalysisCache.
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
$testCachePath = Join-Path -Path $env:TEMP -ChildPath "PRCacheBasicTest"
if (-not (Test-Path -Path $testCachePath)) {
    New-Item -Path $testCachePath -ItemType Directory -Force | Out-Null
    Write-Host "Répertoire de test créé: $testCachePath"
} else {
    # Nettoyer le répertoire
    Get-ChildItem -Path $testCachePath -File | Remove-Item -Force
    Write-Host "Répertoire de test nettoyé: $testCachePath"
}

# Créer un cache
$cache = New-PRAnalysisCache -MaxMemoryItems 10
if ($null -eq $cache) {
    Write-Error "Impossible de créer le cache."
    exit 1
}
Write-Host "Cache créé avec succès."

# Rediriger le chemin du cache vers le répertoire de test
$cache.DiskCachePath = $testCachePath
Write-Host "Chemin du cache configuré: $($cache.DiskCachePath)"

# Ajouter un élément au cache
$cache.SetItem("TestKey", "TestValue", (New-TimeSpan -Hours 1))
Write-Host "Élément ajouté au cache."

# Vérifier que l'élément a été ajouté
$value = $cache.GetItem("TestKey")
if ($value -eq "TestValue") {
    Write-Host "Élément récupéré avec succès: $value" -ForegroundColor Green
} else {
    Write-Error "Impossible de récupérer l'élément du cache."
    exit 1
}

# Vérifier que le fichier de cache a été créé
$cacheFile = Join-Path -Path $testCachePath -ChildPath "$($cache.NormalizeKey("TestKey")).xml"
if (Test-Path -Path $cacheFile) {
    Write-Host "Fichier de cache créé: $cacheFile" -ForegroundColor Green
} else {
    Write-Error "Fichier de cache non créé: $cacheFile"
    exit 1
}

# Supprimer l'élément du cache
$cache.RemoveItem("TestKey")
Write-Host "Élément supprimé du cache."

# Vérifier que l'élément a été supprimé
$value = $cache.GetItem("TestKey")
if ($null -eq $value) {
    Write-Host "Élément correctement supprimé du cache." -ForegroundColor Green
} else {
    Write-Error "L'élément n'a pas été supprimé du cache."
    exit 1
}

# Vérifier que le fichier de cache a été supprimé
if (-not (Test-Path -Path $cacheFile)) {
    Write-Host "Fichier de cache supprimé." -ForegroundColor Green
} else {
    Write-Error "Le fichier de cache n'a pas été supprimé."
    exit 1
}

# Ajouter plusieurs éléments au cache
for ($i = 1; $i -le 5; $i++) {
    $cache.SetItem("Key$i", "Value$i", (New-TimeSpan -Hours 1))
}
Write-Host "5 éléments ajoutés au cache."

# Vérifier que les éléments ont été ajoutés
$allItemsFound = $true
for ($i = 1; $i -le 5; $i++) {
    $value = $cache.GetItem("Key$i")
    if ($value -ne "Value$i") {
        $allItemsFound = $false
        Write-Error "Élément Key$i non trouvé ou valeur incorrecte."
    }
}

if ($allItemsFound) {
    Write-Host "Tous les éléments ont été correctement ajoutés au cache." -ForegroundColor Green
}

# Vider le cache
$cache.Clear()
Write-Host "Cache vidé."

# Vérifier que le cache est vide
$cacheFiles = Get-ChildItem -Path $testCachePath -Filter "*.xml"
if ($cacheFiles.Count -eq 0) {
    Write-Host "Cache correctement vidé." -ForegroundColor Green
} else {
    Write-Error "Le cache n'a pas été correctement vidé. Nombre de fichiers restants: $($cacheFiles.Count)"
    exit 1
}

Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
