# MinimalRestoreTest.ps1
# Script de test minimal pour le module de restauration
# Version: 1.0
# Date: 2025-05-15

# Importer le module
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host "Script path: $scriptPath"

$modulePath = Join-Path -Path $scriptPath -ChildPath "RestoreManager.ps1"
Write-Host "Module path: $modulePath"

$extractPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "extract\ExtractManager.ps1"
Write-Host "Extract path: $extractPath"

$pathResolverPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "path\PathResolver.ps1"
Write-Host "Path resolver path: $pathResolverPath"

# Verifier si les fichiers existent
Write-Host "RestoreManager.ps1 exists: $(Test-Path -Path $modulePath)"
Write-Host "ExtractManager.ps1 exists: $(Test-Path -Path $extractPath)"
Write-Host "PathResolver.ps1 exists: $(Test-Path -Path $pathResolverPath)"

# Importer les modules
if (Test-Path -Path $pathResolverPath) {
    Write-Host "Importing PathResolver.ps1..."
    . $pathResolverPath
    Write-Host "PathResolver.ps1 imported."
} else {
    Write-Error "Le fichier PathResolver.ps1 est introuvable."
    exit 1
}

if (Test-Path -Path $extractPath) {
    Write-Host "Importing ExtractManager.ps1..."
    . $extractPath
    Write-Host "ExtractManager.ps1 imported."
} else {
    Write-Error "Le fichier ExtractManager.ps1 est introuvable."
    exit 1
}

if (Test-Path -Path $modulePath) {
    Write-Host "Importing RestoreManager.ps1..."
    . $modulePath
    Write-Host "RestoreManager.ps1 imported."
} else {
    Write-Error "Le fichier RestoreManager.ps1 est introuvable."
    exit 1
}

# Verifier si les fonctions sont disponibles
Write-Host "Function Resolve-ArchivePath available: $([bool](Get-Command -Name Resolve-ArchivePath -ErrorAction SilentlyContinue))"
Write-Host "Function Extract-ArchiveItem available: $([bool](Get-Command -Name Extract-ArchiveItem -ErrorAction SilentlyContinue))"
Write-Host "Function Restore-ToAlternateLocation available: $([bool](Get-Command -Name Restore-ToAlternateLocation -ErrorAction SilentlyContinue))"
Write-Host "Function ConvertTo-RestorePath available: $([bool](Get-Command -Name ConvertTo-RestorePath -ErrorAction SilentlyContinue))"

# Creer un repertoire de test
$testPath = Join-Path -Path $env:TEMP -ChildPath "MinimalRestoreTest"
Write-Host "Creating test directory: $testPath"
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
    Name        = "Index de test"
    Description = "Index pour les tests de restauration"
    Archives    = @(
        @{
            Id          = "archive1"
            Name        = "Archive 1"
            Description = "Archive de test"
            ArchivePath = "Archive\archive.dat"
            Type        = "Document"
            Category    = "Test"
            Tags        = @("test", "document")
            Status      = "Active"
        }
    )
}

$index | ConvertTo-Json -Depth 10 | Set-Content -Path $indexFile -Force

# Creer un repertoire cible
$targetPath = Join-Path -Path $testPath -ChildPath "Target"
New-Item -Path $targetPath -ItemType Directory | Out-Null

# Creer un fichier cible
$targetFile = Join-Path -Path $targetPath -ChildPath "restored.dat"

Write-Host "Donnees de test creees dans: $testPath"

# Test de transformation des chemins
Write-Host "`nTest 1: Transformation des chemins" -ForegroundColor Yellow
try {
    $result = ConvertTo-RestorePath -SourcePath $archiveFile -SourceRoot $testPath -TargetRoot $targetPath -CreateTargetPath
    Write-Host "Resultat:"
    $result | Format-List
} catch {
    Write-Host "Erreur: $($_.Exception.Message)" -ForegroundColor Red
}

# Test de restauration vers un emplacement alternatif
Write-Host "`nTest 2: Restauration vers un emplacement alternatif" -ForegroundColor Yellow
try {
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
} catch {
    Write-Host "Erreur: $($_.Exception.Message)" -ForegroundColor Red
}

# Nettoyer les donnees de test
Remove-Item -Path $testPath -Recurse -Force

Write-Host "`nTests termines." -ForegroundColor Green
