# Script de test très simple
Write-Host "Test très simple"
Write-Host "Vérification du chemin du module"
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Write-Host "Chemin du module: $modulePath"
$exists = Test-Path $modulePath
Write-Host "Le module existe: $exists"
