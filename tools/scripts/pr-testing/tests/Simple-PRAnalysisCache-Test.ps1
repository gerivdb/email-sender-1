#Requires -Version 5.1
<#
.SYNOPSIS
    Test simple pour le module PRAnalysisCache.
.DESCRIPTION
    Ce script teste les fonctionnalités de base du module PRAnalysisCache.
.NOTES
    Author: Augment Agent
    Version: 1.0
#>

# Rechercher le module PRAnalysisCache.psm1
$modulePaths = @(
    (Join-Path -Path $PSScriptRoot -ChildPath "..\modules\PRAnalysisCache.psm1"),
    (Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\PRAnalysisCache.psm1"),
    (Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\pr-testing\modules\PRAnalysisCache.psm1")
)

$modulePath = $null
foreach ($path in $modulePaths) {
    if (Test-Path -Path $path) {
        $modulePath = $path
        break
    }
}

if ($null -eq $modulePath) {
    Write-Error "Module PRAnalysisCache.psm1 non trouvé."
    exit 1
}

Write-Host "Module trouvé: $modulePath" -ForegroundColor Green

# Importer le module
Import-Module $modulePath -Force

# Créer un répertoire de test
$testCachePath = Join-Path -Path $env:TEMP -ChildPath "PRAnalysisCacheTest"
if (-not (Test-Path -Path $testCachePath)) {
    New-Item -Path $testCachePath -ItemType Directory -Force | Out-Null
}

Write-Host "Répertoire de test: $testCachePath" -ForegroundColor Green

# Créer un cache
$cache = New-PRAnalysisCache -MaxMemoryItems 10
if ($null -eq $cache) {
    Write-Error "Impossible de créer le cache."
    exit 1
}

Write-Host "Cache créé avec succès." -ForegroundColor Green

# Rediriger le chemin du cache vers le répertoire de test
$cache.DiskCachePath = $testCachePath

# Ajouter un élément au cache
try {
    $cache.SetItem("TestKey", "TestValue", (New-TimeSpan -Hours 1))
    Write-Host "Élément ajouté au cache." -ForegroundColor Green
} catch {
    Write-Host "Erreur lors de l'ajout de l'élément au cache: $_" -ForegroundColor Red
    # Afficher les méthodes disponibles
    Write-Host "Méthodes disponibles:" -ForegroundColor Yellow
    $cache | Get-Member -MemberType Method | Format-Table -Property Name, Definition
}

# Vérifier que l'élément a été ajouté
$value = $cache.GetItem("TestKey")
if ($value -eq "TestValue") {
    Write-Host "Élément récupéré avec succès: $value" -ForegroundColor Green
} else {
    Write-Error "Impossible de récupérer l'élément du cache."
    exit 1
}

# Supprimer l'élément du cache
$cache.RemoveItem("TestKey")
Write-Host "Élément supprimé du cache." -ForegroundColor Green

# Vérifier que l'élément a été supprimé
$value = $cache.GetItem("TestKey")
if ($null -eq $value) {
    Write-Host "Élément correctement supprimé du cache." -ForegroundColor Green
} else {
    Write-Error "L'élément n'a pas été supprimé du cache."
    exit 1
}

# Ajouter plusieurs éléments au cache
for ($i = 1; $i -le 5; $i++) {
    $cache.SetItem("Key$i", "Value$i", (New-TimeSpan -Hours 1))
}
Write-Host "5 éléments ajoutés au cache." -ForegroundColor Green

# Vider le cache
$cache.Clear()
Write-Host "Cache vidé." -ForegroundColor Green

# Vérifier que le cache est vide
$diskCacheFiles = Get-ChildItem -Path $testCachePath -Filter "*.xml"
if ($diskCacheFiles.Count -eq 0) {
    Write-Host "Cache correctement vidé." -ForegroundColor Green
} else {
    Write-Error "Le cache n'a pas été correctement vidé."
    exit 1
}

Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
