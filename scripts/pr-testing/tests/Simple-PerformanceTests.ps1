# Tests unitaires simplifiés pour les fonctionnalités de performance

# Importer le module simplifié
$moduleToTest = Join-Path -Path $PSScriptRoot -ChildPath "SimpleFileContentIndexer.psm1"
Import-Module $moduleToTest -Force

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "SimplePerformanceTests_$(Get-Random)"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null

# Fonction pour créer des fichiers de test
function New-TestFile {
    param(
        [string]$Path,
        [string]$Content
    )

    $fullPath = Join-Path -Path $testDir -ChildPath $Path
    $directory = Split-Path -Path $fullPath -Parent

    if (-not (Test-Path -Path $directory)) {
        New-Item -Path $directory -ItemType Directory -Force | Out-Null
    }

    Set-Content -Path $fullPath -Value $Content -Encoding UTF8
    return $fullPath
}

# Créer des fichiers de test
$testContent = @"
# Test PowerShell Script
function Test-Function {
    param(
        [string]`$param1,
        [int]`$param2 = 0
    )

    `$testVariable = "Test value"
    Write-Output `$testVariable
}

Test-Function -param1 "Test" -param2 42
"@

$testFile = New-TestFile -Path "test.ps1" -Content $testContent

# Créer un indexeur
$indexer = New-SimpleFileContentIndexer -IndexPath $testDir -PersistIndices $false

# Test 1: Indexer un fichier et mesurer les performances
Write-Host "Test 1: Indexation d'un fichier" -ForegroundColor Cyan
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$index = New-SimpleFileIndex -Indexer $indexer -FilePath $testFile
$stopwatch.Stop()
$time = $stopwatch.ElapsedMilliseconds

Write-Host "Fichier indexé en $time ms" -ForegroundColor Green
Write-Host "Taille du fichier: $($index.FileSize) octets" -ForegroundColor Green
Write-Host "Nombre de lignes: $($index.LineCount)" -ForegroundColor Green

# Test 2: Indexer plusieurs fichiers
Write-Host "`nTest 2: Indexation de plusieurs fichiers" -ForegroundColor Cyan
$files = @()
for ($i = 1; $i -le 5; $i++) {
    $content = $testContent.Replace("Test-Function", "Test-Function$i")
    $files += New-TestFile -Path "test_$i.ps1" -Content $content
}

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
foreach ($file in $files) {
    New-SimpleFileIndex -Indexer $indexer -FilePath $file | Out-Null
}
$stopwatch.Stop()
$time = $stopwatch.ElapsedMilliseconds

Write-Host "$($files.Count) fichiers indexés en $time ms" -ForegroundColor Green
Write-Host "Temps moyen par fichier: $([Math]::Round($time / $files.Count, 2)) ms" -ForegroundColor Green

# Test 3: Utiliser le cache pour améliorer les performances
Write-Host "`nTest 3: Utilisation du cache" -ForegroundColor Cyan
$stopwatch1 = [System.Diagnostics.Stopwatch]::StartNew()
New-SimpleFileIndex -Indexer $indexer -FilePath $testFile | Out-Null
$stopwatch1.Stop()
$time1 = $stopwatch1.ElapsedMilliseconds

$stopwatch2 = [System.Diagnostics.Stopwatch]::StartNew()
New-SimpleFileIndex -Indexer $indexer -FilePath $testFile | Out-Null
$stopwatch2.Stop()
$time2 = $stopwatch2.ElapsedMilliseconds

Write-Host "Première indexation: $time1 ms" -ForegroundColor Green
Write-Host "Deuxième indexation: $time2 ms" -ForegroundColor Green
if ($time2 -lt $time1) {
    Write-Host "La deuxième indexation est plus rapide (utilisation du cache)" -ForegroundColor Green
} else {
    Write-Host "La deuxième indexation n'est pas plus rapide" -ForegroundColor Yellow
}

# Nettoyer
Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`nTests terminés avec succès!" -ForegroundColor Green
