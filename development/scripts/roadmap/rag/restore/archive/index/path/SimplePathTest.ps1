# SimplePathTest.ps1
# Script de test simple pour le module de resolution des chemins d'archives
# Version: 1.0
# Date: 2025-05-15

# Importer le module
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path $scriptPath -ChildPath "PathResolver.ps1"

if (Test-Path -Path $modulePath) {
    . $modulePath
} else {
    Write-Error "Le fichier PathResolver.ps1 est introuvable."
    exit 1
}

# Creer un repertoire de test
$testPath = Join-Path -Path $env:TEMP -ChildPath "SimplePathTest"
if (-not (Test-Path -Path $testPath)) {
    New-Item -Path $testPath -ItemType Directory | Out-Null
}

# Creer un fichier de test
$testFile = Join-Path -Path $testPath -ChildPath "test.txt"
"Test content" | Set-Content -Path $testFile -Force

Write-Host "Fichier de test cree: $testFile"

# Test 1: Resolution d'un chemin absolu
Write-Host "`nTest 1: Resolution d'un chemin absolu" -ForegroundColor Yellow
$result = Resolve-ArchivePath -Path $testFile
Write-Host "Resultat:"
$result | Format-List

# Test 2: Resolution d'un chemin relatif
Write-Host "`nTest 2: Resolution d'un chemin relatif" -ForegroundColor Yellow
$relativePath = "test.txt"
$result = Resolve-ArchivePath -Path $relativePath -BasePath $testPath
Write-Host "Resultat:"
$result | Format-List

# Test 3: Test d'un chemin valide
Write-Host "`nTest 3: Test d'un chemin valide" -ForegroundColor Yellow
$result = Test-ArchivePath -Path $testFile
Write-Host "Resultat: $result"

# Test 4: Conversion d'un chemin relatif en absolu
Write-Host "`nTest 4: Conversion d'un chemin relatif en absolu" -ForegroundColor Yellow
$result = Convert-ArchivePath -Path $relativePath -ConversionType "ToAbsolute" -BasePath $testPath
Write-Host "Resultat: $result"

# Test 5: Conversion d'un chemin absolu en relatif
Write-Host "`nTest 5: Conversion d'un chemin absolu en relatif" -ForegroundColor Yellow
$result = Convert-ArchivePath -Path $testFile -ConversionType "ToRelative" -BasePath $testPath
Write-Host "Resultat: $result"

# Nettoyer les donnees de test
Remove-Item -Path $testPath -Recurse -Force

Write-Host "`nTests termines." -ForegroundColor Green
