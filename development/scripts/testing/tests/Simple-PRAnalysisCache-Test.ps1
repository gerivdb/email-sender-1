#Requires -Version 5.1
<#
.SYNOPSIS
    Test simple pour le module PRAnalysisCache.
.DESCRIPTION
    Ce script teste les fonctionnalitÃƒÂ©s de base du module PRAnalysisCache.
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
    Write-Error "Module PRAnalysisCache.psm1 non trouvÃƒÂ©."
    exit 1
}

Write-Host "Module trouvÃƒÂ©: $modulePath" -ForegroundColor Green

# Importer le module
Import-Module $modulePath -Force

# CrÃƒÂ©er un rÃƒÂ©pertoire de test
$testCachePath = Join-Path -Path $env:TEMP -ChildPath "PRAnalysisCacheTest"
if (-not (Test-Path -Path $testCachePath)) {
    New-Item -Path $testCachePath -ItemType Directory -Force | Out-Null
}

Write-Host "RÃƒÂ©pertoire de test: $testCachePath" -ForegroundColor Green

# CrÃƒÂ©er un cache
$cache = New-PRAnalysisCache -MaxMemoryItems 10
if ($null -eq $cache) {
    Write-Error "Impossible de crÃƒÂ©er le cache."
    exit 1
}

Write-Host "Cache crÃƒÂ©ÃƒÂ© avec succÃƒÂ¨s." -ForegroundColor Green

# Rediriger le chemin du cache vers le rÃƒÂ©pertoire de test
$cache.DiskCachePath = $testCachePath

# Ajouter un ÃƒÂ©lÃƒÂ©ment au cache
try {
    $cache.SetItem("TestKey", "TestValue", (New-TimeSpan -Hours 1))
    Write-Host "Ãƒâ€°lÃƒÂ©ment ajoutÃƒÂ© au cache." -ForegroundColor Green
} catch {
    Write-Host "Erreur lors de l'ajout de l'ÃƒÂ©lÃƒÂ©ment au cache: $_" -ForegroundColor Red
    # Afficher les mÃƒÂ©thodes disponibles
    Write-Host "MÃƒÂ©thodes disponibles:" -ForegroundColor Yellow
    $cache | Get-Member -MemberType Method | Format-Table -Property Name, Definition
}

# VÃƒÂ©rifier que l'ÃƒÂ©lÃƒÂ©ment a ÃƒÂ©tÃƒÂ© ajoutÃƒÂ©
$value = $cache.GetItem("TestKey")
if ($value -eq "TestValue") {
    Write-Host "Ãƒâ€°lÃƒÂ©ment rÃƒÂ©cupÃƒÂ©rÃƒÂ© avec succÃƒÂ¨s: $value" -ForegroundColor Green
} else {
    Write-Error "Impossible de rÃƒÂ©cupÃƒÂ©rer l'ÃƒÂ©lÃƒÂ©ment du cache."
    exit 1
}

# Supprimer l'ÃƒÂ©lÃƒÂ©ment du cache
$cache.RemoveItem("TestKey")
Write-Host "Ãƒâ€°lÃƒÂ©ment supprimÃƒÂ© du cache." -ForegroundColor Green

# VÃƒÂ©rifier que l'ÃƒÂ©lÃƒÂ©ment a ÃƒÂ©tÃƒÂ© supprimÃƒÂ©
$value = $cache.GetItem("TestKey")
if ($null -eq $value) {
    Write-Host "Ãƒâ€°lÃƒÂ©ment correctement supprimÃƒÂ© du cache." -ForegroundColor Green
} else {
    Write-Error "L'ÃƒÂ©lÃƒÂ©ment n'a pas ÃƒÂ©tÃƒÂ© supprimÃƒÂ© du cache."
    exit 1
}

# Ajouter plusieurs ÃƒÂ©lÃƒÂ©ments au cache
for ($i = 1; $i -le 5; $i++) {
    $cache.SetItem("Key$i", "Value$i", (New-TimeSpan -Hours 1))
}
Write-Host "5 ÃƒÂ©lÃƒÂ©ments ajoutÃƒÂ©s au cache." -ForegroundColor Green

# Vider le cache
$cache.Clear()
Write-Host "Cache vidÃƒÂ©." -ForegroundColor Green

# VÃƒÂ©rifier que le cache est vide
$diskCacheFiles = Get-ChildItem -Path $testCachePath -Filter "*.xml"
if ($diskCacheFiles.Count -eq 0) {
    Write-Host "Cache correctement vidÃƒÂ©." -ForegroundColor Green
} else {
    Write-Error "Le cache n'a pas ÃƒÂ©tÃƒÂ© correctement vidÃƒÂ©."
    exit 1
}

Write-Host "Tous les tests ont rÃƒÂ©ussi!" -ForegroundColor Green
