# Script de test pour vérifier la fonction Get-UnifiedParallelVersion
#Requires -Version 5.1

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Initialiser le module
Initialize-UnifiedParallel

# Tester la fonction Get-UnifiedParallelVersion
Write-Host "=== Test de Get-UnifiedParallelVersion ===" -ForegroundColor Cyan

# Test 1: Version simple
$version = Get-UnifiedParallelVersion
Write-Host "Version du module: $version" -ForegroundColor Yellow

# Test 2: Informations détaillées
$detailedInfo = Get-UnifiedParallelVersion -Detailed
Write-Host "Informations détaillées:" -ForegroundColor Yellow
Write-Host "  Version: $($detailedInfo.Version)" -ForegroundColor Yellow
Write-Host "  PSVersion: $($detailedInfo.PSVersion)" -ForegroundColor Yellow
Write-Host "  IsInitialized: $($detailedInfo.IsInitialized)" -ForegroundColor Yellow
Write-Host "  BuildDate: $($detailedInfo.BuildDate)" -ForegroundColor Yellow
Write-Host "  Path: $($detailedInfo.Path)" -ForegroundColor Yellow

# Test 3: Vérifier les fonctionnalités
Write-Host "Fonctionnalités disponibles:" -ForegroundColor Yellow
Write-Host "  BackpressureEnabled: $($detailedInfo.Features.BackpressureEnabled)" -ForegroundColor Yellow
Write-Host "  ThrottlingEnabled: $($detailedInfo.Features.ThrottlingEnabled)" -ForegroundColor Yellow
Write-Host "  ResourceMonitoring: $($detailedInfo.Features.ResourceMonitoring)" -ForegroundColor Yellow
Write-Host "  ErrorHandling: $($detailedInfo.Features.ErrorHandling)" -ForegroundColor Yellow
Write-Host "  RunspacePoolCache: $($detailedInfo.Features.RunspacePoolCache)" -ForegroundColor Yellow

# Test 4: Vérifier que la version est correcte
if ($version -eq "1.1.0") {
    Write-Host "La version est correcte: $version" -ForegroundColor Green
} else {
    Write-Host "La version est incorrecte. Attendu: 1.1.0, Obtenu: $version" -ForegroundColor Red
}

# Test 5: Vérifier que les informations détaillées sont cohérentes
$isValid = $true
$errors = @()

if ($detailedInfo.Version -ne $version) {
    $isValid = $false
    $errors += "La version dans les informations détaillées ne correspond pas à la version simple"
}

if (-not $detailedInfo.IsInitialized) {
    $isValid = $false
    $errors += "Le module devrait être initialisé"
}

if ($null -eq $detailedInfo.BuildDate) {
    $isValid = $false
    $errors += "La date de compilation est manquante"
}

if ($null -eq $detailedInfo.Path -or -not (Test-Path -Path $detailedInfo.Path)) {
    $isValid = $false
    $errors += "Le chemin du module est invalide"
}

# Afficher le résultat du test
if ($isValid) {
    Write-Host "Les informations détaillées sont cohérentes" -ForegroundColor Green
} else {
    Write-Host "Les informations détaillées sont incohérentes:" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "  - $error" -ForegroundColor Red
    }
}

# Nettoyer les ressources
Clear-UnifiedParallel
