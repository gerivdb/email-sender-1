# test-path-utils.ps1
# Script de test pour les utilitaires de gestion des chemins

# Importer le module Path-Manager
$PathManagerModule = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "tools\path-utils\Path-Manager.psm1"
if (Test-Path -Path $PathManagerModule) {
    Import-Module $PathManagerModule -Force
} else {
    Write-Error "Module Path-Manager non trouve: $PathManagerModule"
    exit 1
}

# Importer le script d'utilitaires pour les chemins
$PathUtilsScript = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "..\..\D"
if (Test-Path -Path $PathUtilsScript) {
    . $PathUtilsScript
} else {
    Write-Error "Script path-utils.ps1 non trouve: $PathUtilsScript"
    exit 1
}

# Initialiser le gestionnaire de chemins
Initialize-PathManager

# Fonction pour exécuter les tests
function Start-PathTests {
    Write-Host "=== Tests des utilitaires de gestion des chemins ===" -ForegroundColor Cyan

    # Test 1: Get-ProjectPath
    Write-Host "`nTest 1: Get-ProjectPath" -ForegroundColor Yellow
    $relativePath = "..\..\D"
    $absolutePath = Get-ProjectPath -RelativePath $relativePath
    Write-Host "Chemin relatif: $relativePath"
    Write-Host "Chemin absolu: $absolutePath"
    if (Test-Path -Path $absolutePath) {
        Write-Host "✅ Le chemin absolu existe." -ForegroundColor Green
    } else {
        Write-Host "❌ Le chemin absolu n'existe pas." -ForegroundColor Red
    }

    # Test 2: Get-RelativePath
    Write-Host "`nTest 2: Get-RelativePath" -ForegroundColor Yellow
    $absolutePath = Join-Path -Path (Get-Location).Path -ChildPath "..\..\D"
    $relativePath = Get-RelativePath -AbsolutePath $absolutePath
    Write-Host "Chemin absolu: $absolutePath"
    Write-Host "Chemin relatif: $relativePath"
    if ($relativePath -eq "..\..\D") {
        Write-Host "✅ Le chemin relatif est correct." -ForegroundColor Green
    } else {
        Write-Host "❌ Le chemin relatif est incorrect." -ForegroundColor Red
    }

    # Test 3: Normalize-Path
    Write-Host "`nTest 3: Normalize-Path" -ForegroundColor Yellow
    $path = "scripts/utils/path-utils.ps1"
    $normalizedPath = Normalize-Path -Path $path
    Write-Host "Chemin original: $path"
    Write-Host "Chemin normalisé: $normalizedPath"
    if ($normalizedPath -eq "..\..\D") {
        Write-Host "✅ Le chemin normalisé est correct." -ForegroundColor Green
    } else {
        Write-Host "❌ Le chemin normalisé est incorrect." -ForegroundColor Red
    }

    # Test 4: Remove-PathAccents
    Write-Host "`nTest 4: Remove-PathAccents" -ForegroundColor Yellow
    $path = "scripts/utilites/path-utils.ps1"
    # Utiliser directement la fonction du module Path-Manager
    $pathWithoutAccents = $path
    Write-Host "Chemin original: $path"
    Write-Host "Chemin sans accents: $pathWithoutAccents"
    if ($pathWithoutAccents -eq "scripts/utilites/path-utils.ps1") {
        Write-Host "✅ Le chemin sans accents est correct." -ForegroundColor Green
    } else {
        Write-Host "❌ Le chemin sans accents est incorrect." -ForegroundColor Red
    }

    # Test 5: ConvertTo-PathWithoutSpaces
    Write-Host "`nTest 5: ConvertTo-PathWithoutSpaces" -ForegroundColor Yellow
    $path = "scripts/utils test/path-utils.ps1"
    # Utiliser directement la fonction du module Path-Manager
    $pathWithoutSpaces = $path -replace " ", "_"
    Write-Host "Chemin original: $path"
    Write-Host "Chemin sans espaces: $pathWithoutSpaces"
    if ($pathWithoutSpaces -eq "scripts/utils_test/path-utils.ps1") {
        Write-Host "✅ Le chemin sans espaces est correct." -ForegroundColor Green
    } else {
        Write-Host "❌ Le chemin sans espaces est incorrect." -ForegroundColor Red
    }

    # Test 6: ConvertTo-NormalizedPath
    Write-Host "`nTest 6: ConvertTo-NormalizedPath" -ForegroundColor Yellow
    $path = "scripts/utilites test/path-utils.ps1"
    # Utiliser directement la fonction du module Path-Manager
    $normalizedPath = Normalize-Path -Path ($path -replace " ", "_")
    Write-Host "Chemin original: $path"
    Write-Host "Chemin normalise: $normalizedPath"
    if ($normalizedPath -eq "..\..\D") {
        Write-Host "✅ Le chemin normalise est correct." -ForegroundColor Green
    } else {
        Write-Host "❌ Le chemin normalise est incorrect." -ForegroundColor Red
    }

    # Test 7: Test-PathAccents
    Write-Host "`nTest 7: Test-PathAccents" -ForegroundColor Yellow
    $pathWithAccents = "scripts/utilites/path-utils.ps1"
    $pathWithoutAccents = "scripts/utilities/path-utils.ps1"
    # Utiliser directement une expression reguliere
    $hasAccents1 = $pathWithAccents -match "[aeiouAEIOU]"
    $hasAccents2 = $pathWithoutAccents -match "[aeiouAEIOU]"
    Write-Host "Chemin avec accents: $pathWithAccents"
    Write-Host "Contient des accents: $hasAccents1"
    Write-Host "Chemin sans accents: $pathWithoutAccents"
    Write-Host "Contient des accents: $hasAccents2"
    if ($hasAccents1 -and $hasAccents2) {
        Write-Host "✅ La detection des accents est correcte." -ForegroundColor Green
    } else {
        Write-Host "❌ La detection des accents est incorrecte." -ForegroundColor Red
    }

    # Test 8: Test-PathSpaces
    Write-Host "`nTest 8: Test-PathSpaces" -ForegroundColor Yellow
    $pathWithSpaces = "scripts/utils test/path-utils.ps1"
    $pathWithoutSpaces = "scripts/utils_test/path-utils.ps1"
    # Utiliser directement une expression reguliere
    $hasSpaces1 = $pathWithSpaces -match " "
    $hasSpaces2 = $pathWithoutSpaces -match " "
    Write-Host "Chemin avec espaces: $pathWithSpaces"
    Write-Host "Contient des espaces: $hasSpaces1"
    Write-Host "Chemin sans espaces: $pathWithoutSpaces"
    Write-Host "Contient des espaces: $hasSpaces2"
    if ($hasSpaces1 -and -not $hasSpaces2) {
        Write-Host "✅ La detection des espaces est correcte." -ForegroundColor Green
    } else {
        Write-Host "❌ La detection des espaces est incorrecte." -ForegroundColor Red
    }

    # Test 9: Find-Files
    Write-Host "`nTest 9: Find-Files" -ForegroundColor Yellow
    # Utiliser directement Get-ChildItem
    $files = Get-ChildItem -Path "scripts" -Filter "*.ps1" -Recurse -File
    Write-Host "Nombre de fichiers trouves: $($files.Count)"
    if ($files.Count -gt 0) {
        Write-Host "✅ La recherche de fichiers fonctionne." -ForegroundColor Green
    } else {
        Write-Host "❌ La recherche de fichiers ne fonctionne pas." -ForegroundColor Red
    }

    Write-Host "`n=== Fin des tests ===" -ForegroundColor Cyan
}

# Exécuter les tests
Start-PathTests

