#Requires -Version 5.1
<#
.SYNOPSIS
    Test simple pour le module PRAnalysisCache.
.DESCRIPTION
    Ce script teste les fonctionnalitÃ©s de base du module PRAnalysisCache.
.NOTES
    Author: Augment Agent
    Version: 1.0
#>

# Rechercher le module PRAnalysisCache.psm1
$modulePaths = @(
    (Join-Path -Path $PSScriptRoot -ChildPath "..\modules\PRAnalysisCache.psm1"),
    (Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\PRAnalysisCache.psm1"),
    (Join-Path -Path $PSScriptRoot -ChildPath "..\development\scripts\pr-testing\modules\PRAnalysisCache.psm1")
)

$modulePath = $null
foreach ($path in $modulePaths) {
    if (Test-Path -Path $path) {
        $modulePath = $path
        break
    }
}

if ($null -eq $modulePath) {
    Write-Error "Module PRAnalysisCache.psm1 non trouvÃ©."
    exit 1
}

Write-Host "Module trouvÃ©: $modulePath" -ForegroundColor Green

# Importer le module
Import-Module $modulePath -Force

# CrÃ©er un rÃ©pertoire de test
$testCachePath = Join-Path -Path $env:TEMP -ChildPath "PRAnalysisCacheTest"
if (-not (Test-Path -Path $testCachePath)) {
    New-Item -Path $testCachePath -ItemType Directory -Force | Out-Null
}

Write-Host "RÃ©pertoire de test: $testCachePath" -ForegroundColor Green

# CrÃ©er un cache
$cache = New-PRAnalysisCache -MaxMemoryItems 10
if ($null -eq $cache) {
    Write-Error "Impossible de crÃ©er le cache."
    exit 1
}

Write-Host "Cache crÃ©Ã© avec succÃ¨s." -ForegroundColor Green

# Rediriger le chemin du cache vers le rÃ©pertoire de test
$cache.DiskCachePath = $testCachePath

# Ajouter un Ã©lÃ©ment au cache
try {
    $cache.SetItem("TestKey", "TestValue", (New-TimeSpan -Hours 1))
    Write-Host "Ã‰lÃ©ment ajoutÃ© au cache." -ForegroundColor Green
} catch {
    Write-Host "Erreur lors de l'ajout de l'Ã©lÃ©ment au cache: $_" -ForegroundColor Red
    # Afficher les mÃ©thodes disponibles
    Write-Host "MÃ©thodes disponibles:" -ForegroundColor Yellow
    $cache | Get-Member -MemberType Method | Format-Table -Property Name, Definition
}

# VÃ©rifier que l'Ã©lÃ©ment a Ã©tÃ© ajoutÃ©
$value = $cache.GetItem("TestKey")
if ($value -eq "TestValue") {
    Write-Host "Ã‰lÃ©ment rÃ©cupÃ©rÃ© avec succÃ¨s: $value" -ForegroundColor Green
} else {
    Write-Error "Impossible de rÃ©cupÃ©rer l'Ã©lÃ©ment du cache."
    exit 1
}

# Supprimer l'Ã©lÃ©ment du cache
$cache.RemoveItem("TestKey")
Write-Host "Ã‰lÃ©ment supprimÃ© du cache." -ForegroundColor Green

# VÃ©rifier que l'Ã©lÃ©ment a Ã©tÃ© supprimÃ©
$value = $cache.GetItem("TestKey")
if ($null -eq $value) {
    Write-Host "Ã‰lÃ©ment correctement supprimÃ© du cache." -ForegroundColor Green
} else {
    Write-Error "L'Ã©lÃ©ment n'a pas Ã©tÃ© supprimÃ© du cache."
    exit 1
}

# Ajouter plusieurs Ã©lÃ©ments au cache
for ($i = 1; $i -le 5; $i++) {
    $cache.SetItem("Key$i", "Value$i", (New-TimeSpan -Hours 1))
}
Write-Host "5 Ã©lÃ©ments ajoutÃ©s au cache." -ForegroundColor Green

# Vider le cache
$cache.Clear()
Write-Host "Cache vidÃ©." -ForegroundColor Green

# VÃ©rifier que le cache est vide
$diskCacheFiles = Get-ChildItem -Path $testCachePath -Filter "*.xml"
if ($diskCacheFiles.Count -eq 0) {
    Write-Host "Cache correctement vidÃ©." -ForegroundColor Green
} else {
    Write-Error "Le cache n'a pas Ã©tÃ© correctement vidÃ©."
    exit 1
}

Write-Host "Tous les tests ont rÃ©ussi!" -ForegroundColor Green
