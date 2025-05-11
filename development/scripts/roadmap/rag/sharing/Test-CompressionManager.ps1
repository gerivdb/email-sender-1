<#
.SYNOPSIS
    Test simple pour le gestionnaire de compression.

.DESCRIPTION
    Ce script teste les fonctionnalités de base du gestionnaire de compression.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2025-05-15
#>

#Requires -Version 5.1

# Importer les modules requis
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Path $scriptPath -Parent
$compressionManagerPath = Join-Path -Path $scriptDir -ChildPath "CompressionManager.ps1"

if (Test-Path -Path $compressionManagerPath) {
    . $compressionManagerPath
}
else {
    throw "Le module CompressionManager.ps1 est requis mais n'a pas été trouvé à l'emplacement: $compressionManagerPath"
}

# Créer un répertoire de test
$testDir = Join-Path -Path $env:TEMP -ChildPath "CompressionManagerTest_$(Get-Date -Format 'yyyyMMddHHmmss')"
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}
New-Item -Path $testDir -ItemType Directory -Force | Out-Null
Write-Host "Répertoire de test créé: $testDir" -ForegroundColor Cyan

# Test 1: Créer un gestionnaire de compression
Write-Host "Test 1: Création d'un gestionnaire de compression" -ForegroundColor Cyan
$compressionManager = New-CompressionManager -CompressionLevel 5 -EnableDebug

if ($null -ne $compressionManager) {
    Write-Host "Gestionnaire de compression créé avec succès" -ForegroundColor Green
}
else {
    Write-Host "Échec de la création du gestionnaire de compression" -ForegroundColor Red
    exit 1
}

# Créer un fichier de test
$testContent = "Ceci est un contenu de test pour la compression. " * 100
$testFilePath = Join-Path -Path $testDir -ChildPath "test_file.txt"
$testContent | Out-File -FilePath $testFilePath -Encoding utf8

if (Test-Path -Path $testFilePath) {
    $fileSize = (Get-Item -Path $testFilePath).Length
    Write-Host "Fichier de test créé avec succès: $testFilePath ($fileSize octets)" -ForegroundColor Green
}
else {
    Write-Host "Échec de la création du fichier de test" -ForegroundColor Red
    exit 1
}

# Test 2: Compresser des données en mémoire
Write-Host "Test 2: Compression de données en mémoire" -ForegroundColor Cyan
$testData = [System.Text.Encoding]::UTF8.GetBytes($testContent)
try {
    $compressedData = $compressionManager.CompressData($testData, "GZIP")
    
    if ($null -ne $compressedData -and $compressedData.Length -gt 0) {
        $compressionRatio = [math]::Round(($compressedData.Length / $testData.Length) * 100, 2)
        Write-Host "Données compressées avec succès: $($compressedData.Length) octets ($compressionRatio% de l'original)" -ForegroundColor Green
    }
    else {
        Write-Host "Échec de la compression des données" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "Erreur lors de la compression des données: $_" -ForegroundColor Red
    exit 1
}

# Test 3: Décompresser des données en mémoire
Write-Host "Test 3: Décompression de données en mémoire" -ForegroundColor Cyan
try {
    $decompressedData = $compressionManager.DecompressData($compressedData, "GZIP")
    
    if ($null -ne $decompressedData -and $decompressedData.Length -gt 0) {
        Write-Host "Données décompressées avec succès: $($decompressedData.Length) octets" -ForegroundColor Green
    }
    else {
        Write-Host "Échec de la décompression des données" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "Erreur lors de la décompression des données: $_" -ForegroundColor Red
    exit 1
}

# Test 4: Vérifier l'intégrité des données en mémoire
Write-Host "Test 4: Vérification de l'intégrité des données en mémoire" -ForegroundColor Cyan
$decompressedContent = [System.Text.Encoding]::UTF8.GetString($decompressedData)

if ($testContent -eq $decompressedContent) {
    Write-Host "Contenu identique après compression/décompression en mémoire" -ForegroundColor Green
}
else {
    Write-Host "Contenu différent après compression/décompression en mémoire" -ForegroundColor Red
    exit 1
}

# Test 5: Compresser un fichier
Write-Host "Test 5: Compression d'un fichier" -ForegroundColor Cyan
try {
    $compressedFilePath = $compressionManager.CompressFile($testFilePath, $null, "GZIP")
    
    if (-not [string]::IsNullOrEmpty($compressedFilePath) -and (Test-Path -Path $compressedFilePath)) {
        $compressedFileSize = (Get-Item -Path $compressedFilePath).Length
        $compressionRatio = [math]::Round(($compressedFileSize / $fileSize) * 100, 2)
        Write-Host "Fichier compressé avec succès: $compressedFilePath ($compressedFileSize octets, $compressionRatio% de l'original)" -ForegroundColor Green
    }
    else {
        Write-Host "Échec de la compression du fichier" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "Erreur lors de la compression du fichier: $_" -ForegroundColor Red
    exit 1
}

# Test 6: Décompresser un fichier
Write-Host "Test 6: Décompression d'un fichier" -ForegroundColor Cyan
try {
    $decompressedFilePath = $compressionManager.DecompressFile($compressedFilePath, "$testFilePath.decompressed", "GZIP")
    
    if (-not [string]::IsNullOrEmpty($decompressedFilePath) -and (Test-Path -Path $decompressedFilePath)) {
        $decompressedFileSize = (Get-Item -Path $decompressedFilePath).Length
        Write-Host "Fichier décompressé avec succès: $decompressedFilePath ($decompressedFileSize octets)" -ForegroundColor Green
    }
    else {
        Write-Host "Échec de la décompression du fichier" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "Erreur lors de la décompression du fichier: $_" -ForegroundColor Red
    exit 1
}

# Test 7: Vérifier l'intégrité des données du fichier
Write-Host "Test 7: Vérification de l'intégrité des données du fichier" -ForegroundColor Cyan
$originalContent = Get-Content -Path $testFilePath -Raw
$decompressedContent = Get-Content -Path $decompressedFilePath -Raw

if ($originalContent -eq $decompressedContent) {
    Write-Host "Contenu identique après compression/décompression du fichier" -ForegroundColor Green
}
else {
    Write-Host "Contenu différent après compression/décompression du fichier" -ForegroundColor Red
    exit 1
}

# Nettoyage
Remove-Item -Path $testDir -Recurse -Force
Write-Host "Tests terminés avec succès" -ForegroundColor Green
