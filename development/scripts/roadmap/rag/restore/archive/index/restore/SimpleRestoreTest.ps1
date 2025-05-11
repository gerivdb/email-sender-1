# SimpleRestoreTest.ps1
# Script de test simple pour le module de restauration
# Version: 1.0
# Date: 2025-05-15

# Importer le module
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path $scriptPath -ChildPath "RestoreManager.ps1"

if (Test-Path -Path $modulePath) {
    . $modulePath
} else {
    Write-Error "Le fichier RestoreManager.ps1 est introuvable."
    exit 1
}

# Creer un repertoire de test
$testPath = Join-Path -Path $env:TEMP -ChildPath "SimpleRestoreTest"
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
    Description = "Index pour les tests de restauration"
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

# Creer un repertoire cible
$targetPath = Join-Path -Path $testPath -ChildPath "Target"
New-Item -Path $targetPath -ItemType Directory | Out-Null

# Creer un fichier cible pour tester la resolution de conflits
$targetFile = Join-Path -Path $targetPath -ChildPath "restored.dat"

Write-Host "Donnees de test creees dans: $testPath"

# Test 1: Restauration vers un emplacement alternatif
Write-Host "`nTest 1: Restauration vers un emplacement alternatif" -ForegroundColor Yellow
$result = Restore-ToAlternateLocation -Id "archive1" -IndexPath $indexFile -TargetPath $targetFile -CreateTargetPath -Force
Write-Host "Resultat:"
$result | Format-List

# Verifier si le fichier a ete restaure
$exists = Test-Path -Path $targetFile -PathType Leaf
Write-Host "Fichier restaure existe: $exists"

if ($exists) {
    $content = Get-Content -Path $targetFile -Raw
    Write-Host "Contenu du fichier restaure: $content"
}

# Test 2: Transformation des chemins
Write-Host "`nTest 2: Transformation des chemins" -ForegroundColor Yellow
$result = Transform-RestorePath -SourcePath $archiveFile -SourceRoot $testPath -TargetRoot $targetPath -CreateTargetPath
Write-Host "Resultat:"
$result | Format-List

# Test 3: Resolution des conflits
Write-Host "`nTest 3: Resolution des conflits" -ForegroundColor Yellow
# Creer un fichier existant
"Existing content" | Set-Content -Path $targetFile -Force

$result = Resolve-RestoreConflict -SourcePath $archiveFile -TargetPath $targetFile -ConflictResolution "Rename"
Write-Host "Resultat: $result"

# Nettoyer les donnees de test
Remove-Item -Path $testPath -Recurse -Force

Write-Host "`nTests termines." -ForegroundColor Green
