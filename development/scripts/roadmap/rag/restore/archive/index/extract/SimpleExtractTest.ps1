# SimpleExtractTest.ps1
# Script de test simple pour le module d'extraction selective
# Version: 1.0
# Date: 2025-05-15

# Importer le module
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path $scriptPath -ChildPath "ExtractManager.ps1"

if (Test-Path -Path $modulePath) {
    . $modulePath
} else {
    Write-Error "Le fichier ExtractManager.ps1 est introuvable."
    exit 1
}

# Creer un repertoire de test
$testPath = Join-Path -Path $env:TEMP -ChildPath "SimpleExtractTest"
if (-not (Test-Path -Path $testPath)) {
    New-Item -Path $testPath -ItemType Directory | Out-Null
}

# Creer un sous-repertoire pour l'archive
$archivePath = Join-Path -Path $testPath -ChildPath "Archive"
New-Item -Path $archivePath -ItemType Directory | Out-Null

# Creer un fichier d'archive
$archiveFile = Join-Path -Path $archivePath -ChildPath "archive.dat"
"Test content" | Set-Content -Path $archiveFile -Force

# Creer un fichier d'index
$indexFile = Join-Path -Path $testPath -ChildPath "index.json"

$index = @{
    Name = "Index de test"
    Description = "Index pour les tests d'extraction"
    Archives = @(
        @{
            Id = "archive1"
            Name = "Archive 1"
            Description = "Archive de test"
            ArchivePath = "Archive\archive.dat"
            Type = "Document"
            Category = "Test"
            Tags = @("test", "document")
            Status = "Active"
        }
    )
}

$index | ConvertTo-Json -Depth 10 | Set-Content -Path $indexFile -Force

# Creer un repertoire de sortie
$outputPath = Join-Path -Path $testPath -ChildPath "Output"
New-Item -Path $outputPath -ItemType Directory | Out-Null

Write-Host "Donnees de test creees dans: $testPath"

# Test 1: Extraction d'un element par ID
Write-Host "`nTest 1: Extraction d'un element par ID" -ForegroundColor Yellow
$result = Extract-ArchiveItem -Id "archive1" -IndexPath $indexFile -OutputPath $outputPath -CreateOutputPath
Write-Host "Resultat:"
$result | Format-List

# Verifier si le fichier a ete extrait
$outputFile = Join-Path -Path $outputPath -ChildPath "archive.dat"
$exists = Test-Path -Path $outputFile -PathType Leaf
Write-Host "Fichier extrait existe: $exists"

if ($exists) {
    $content = Get-Content -Path $outputFile -Raw
    Write-Host "Contenu du fichier extrait: $content"
}

# Test 2: Validation de restauration
Write-Host "`nTest 2: Validation de restauration" -ForegroundColor Yellow
$targetPath = Join-Path -Path $testPath -ChildPath "Target"
New-Item -Path $targetPath -ItemType Directory -Force | Out-Null
$targetFile = Join-Path -Path $targetPath -ChildPath "restored.dat"

$result = Test-RestoreValidity -Id "archive1" -IndexPath $indexFile -TargetPath $targetFile
Write-Host "Resultat:"
$result | Format-List

# Nettoyer les donnees de test
Remove-Item -Path $testPath -Recurse -Force

Write-Host "`nTests termines." -ForegroundColor Green
