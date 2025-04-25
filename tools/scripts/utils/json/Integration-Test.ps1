# Integration-Test.ps1
# Script de test d'integration pour les utilitaires de gestion des chemins

# Importer le module Path-Manager
$PathManagerModule = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "path-utils\Path-Manager.psm1"
if (Test-Path -Path $PathManagerModule) {
    Import-Module $PathManagerModule -Force
} else {
    Write-Error "Module Path-Manager non trouve: $PathManagerModule"
    exit 1
}

# Initialiser le gestionnaire de chemins
Initialize-PathManager

# Fonction pour tester les fonctionnalites du module Path-Manager
function Test-PathManagerIntegration {
    Write-Host "=== Test d'integration du module Path-Manager ===" -ForegroundColor Cyan
    Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
    Write-Host "Repertoire de travail: $(Get-Location)" -ForegroundColor Cyan
    Write-Host ""

    # Test 1: Get-ProjectPath
    $relativePath = "..\..\D"
    $absolutePath = Get-ProjectPath -RelativePath $relativePath
    Write-Host "Test 1: Get-ProjectPath" -ForegroundColor Yellow
    Write-Host "Chemin relatif: $relativePath"
    Write-Host "Chemin absolu: $absolutePath"
    if (Test-Path -Path $absolutePath) {
        Write-Host "[OK] Le chemin absolu existe." -ForegroundColor Green
    } else {
        Write-Host "[KO] Le chemin absolu n'existe pas." -ForegroundColor Red
    }
    Write-Host ""

    # Test 2: Get-RelativePath
    $absolutePath = Join-Path -Path (Get-Location).Path -ChildPath "..\..\D"
    $relativePath = Get-RelativePath -AbsolutePath $absolutePath
    Write-Host "Test 2: Get-RelativePath" -ForegroundColor Yellow
    Write-Host "Chemin absolu: $absolutePath"
    Write-Host "Chemin relatif: $relativePath"
    if ($relativePath -eq "..\..\D") {
        Write-Host "[OK] Le chemin relatif est correct." -ForegroundColor Green
    } else {
        Write-Host "[KO] Le chemin relatif est incorrect." -ForegroundColor Red
    }
    Write-Host ""

    # Test 3: Normalize-Path
    $path = "scripts/utils/path-utils.ps1"
    $normalizedPath = Normalize-Path -Path $path
    Write-Host "Test 3: Normalize-Path" -ForegroundColor Yellow
    Write-Host "Chemin original: $path"
    Write-Host "Chemin normalise: $normalizedPath"
    if ($normalizedPath -eq "..\..\D") {
        Write-Host "[OK] Le chemin normalise est correct." -ForegroundColor Green
    } else {
        Write-Host "[KO] Le chemin normalise est incorrect." -ForegroundColor Red
    }
    Write-Host ""

    # Test 4: Normalize-Path avec ForceWindowsStyle
    $path = "scripts/utils/path-utils.ps1"
    $normalizedPath = Normalize-Path -Path $path -ForceWindowsStyle
    Write-Host "Test 4: Normalize-Path avec ForceWindowsStyle" -ForegroundColor Yellow
    Write-Host "Chemin original: $path"
    Write-Host "Chemin normalise: $normalizedPath"
    if ($normalizedPath -eq "..\..\D") {
        Write-Host "[OK] Le chemin normalise est correct." -ForegroundColor Green
    } else {
        Write-Host "[KO] Le chemin normalise est incorrect." -ForegroundColor Red
    }
    Write-Host ""

    # Test 5: Normalize-Path avec ForceUnixStyle
    $path = "..\..\D"
    $normalizedPath = Normalize-Path -Path $path -ForceUnixStyle
    Write-Host "Test 5: Normalize-Path avec ForceUnixStyle" -ForegroundColor Yellow
    Write-Host "Chemin original: $path"
    Write-Host "Chemin normalise: $normalizedPath"
    if ($normalizedPath -eq "scripts/utils/path-utils.ps1") {
        Write-Host "[OK] Le chemin normalise est correct." -ForegroundColor Green
    } else {
        Write-Host "[KO] Le chemin normalise est incorrect." -ForegroundColor Red
    }
    Write-Host ""

    # Test 6: Add-PathMapping
    Add-PathMapping -Name "test-mapping" -Path "tests\path-utils"
    $mappings = Get-PathMappings
    Write-Host "Test 6: Add-PathMapping" -ForegroundColor Yellow
    Write-Host "Mapping ajoute: test-mapping -> tests\path-utils"
    Write-Host "Valeur du mapping: $($mappings['test-mapping'])"
    if ($mappings["test-mapping"] -like "*\tests\path-utils") {
        Write-Host "[OK] Le mapping a ete ajoute correctement." -ForegroundColor Green
    } else {
        Write-Host "[KO] Le mapping n'a pas ete ajoute correctement." -ForegroundColor Red
    }
    Write-Host ""

    # Test 7: Test-RelativePath avec chemin relatif
    $relativePath = "..\..\D"
    $isRelative = Test-RelativePath -Path $relativePath
    Write-Host "Test 7: Test-RelativePath avec chemin relatif" -ForegroundColor Yellow
    Write-Host "Chemin: $relativePath"
    Write-Host "Est relatif: $isRelative"
    if ($isRelative) {
        Write-Host "[OK] Le chemin est correctement identifie comme relatif." -ForegroundColor Green
    } else {
        Write-Host "[KO] Le chemin n'est pas correctement identifie comme relatif." -ForegroundColor Red
    }
    Write-Host ""

    # Test 8: Test-RelativePath avec chemin absolu
    $absolutePath = "C:\Windows\System32\notepad.exe"
    $isRelative = Test-RelativePath -Path $absolutePath
    Write-Host "Test 8: Test-RelativePath avec chemin absolu" -ForegroundColor Yellow
    Write-Host "Chemin: $absolutePath"
    Write-Host "Est relatif: $isRelative"
    if (-not $isRelative) {
        Write-Host "[OK] Le chemin est correctement identifie comme absolu." -ForegroundColor Green
    } else {
        Write-Host "[KO] Le chemin n'est pas correctement identifie comme absolu." -ForegroundColor Red
    }
    Write-Host ""

    # Test 9: Recherche de fichiers
    $files = Get-ChildItem -Path "scripts" -Filter "*.ps1" -Recurse -File
    Write-Host "Test 9: Recherche de fichiers" -ForegroundColor Yellow
    Write-Host "Nombre de fichiers trouves: $($files.Count)"
    if ($files.Count -gt 0) {
        Write-Host "[OK] La recherche de fichiers fonctionne." -ForegroundColor Green
    } else {
        Write-Host "[KO] La recherche de fichiers ne fonctionne pas." -ForegroundColor Red
    }
    Write-Host ""

    Write-Host "=== Fin du test d'integration ===" -ForegroundColor Cyan
}

# Executer le test d'integration
Test-PathManagerIntegration

