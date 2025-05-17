#Requires -Version 5.1
<#
.SYNOPSIS
    Test simplifié du système de détection des modifications en temps réel.
.DESCRIPTION
    Ce script teste de manière simple et ciblée le système de détection des 
    modifications en temps réel des fichiers Markdown.
.NOTES
    Nom: Test-SimpleWatcher.ps1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
#>

# Chemin du script de surveillance
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$watcherScriptPath = Join-Path -Path $scriptPath -ChildPath "..\watcher\Watch-MarkdownFiles.ps1"

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "MDWatcherTest_$(Get-Date -Format 'yyyyMMddHHmmss')"
New-Item -ItemType Directory -Path $testDir -Force | Out-Null
Write-Host "Répertoire de test: $testDir" -ForegroundColor Cyan

# Créer un fichier Markdown de test simple
$testFilePath = Join-Path -Path $testDir -ChildPath "test.md"
@"
# Test
- [ ] **1.1** Tâche 1
- [ ] **1.2** Tâche 2
"@ | Set-Content -Path $testFilePath -Encoding UTF8
Write-Host "Fichier de test créé: $testFilePath" -ForegroundColor Green

# Démarrer le watcher en arrière-plan
Write-Host "Démarrage du watcher..." -ForegroundColor Yellow
$process = Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$watcherScriptPath`" -WatchPath `"$testDir`" -EnableVerboseLogging" -PassThru -WindowStyle Normal
Start-Sleep -Seconds 3

try {
    # Test 1: Modification du fichier
    Write-Host "Test 1: Modification du fichier..." -ForegroundColor Magenta
    @"
# Test
- [ ] **1.1** Tâche 1
- [x] **1.2** Tâche 2
- [ ] **1.3** Nouvelle tâche
"@ | Set-Content -Path $testFilePath -Encoding UTF8
    Start-Sleep -Seconds 2
    
    # Test 2: Création d'un nouveau fichier
    Write-Host "Test 2: Création d'un nouveau fichier..." -ForegroundColor Magenta
    $newFilePath = Join-Path -Path $testDir -ChildPath "nouveau.md"
    @"
# Nouveau fichier
- [ ] **1.1** Tâche A
- [ ] **1.2** Tâche B
"@ | Set-Content -Path $newFilePath -Encoding UTF8
    Start-Sleep -Seconds 2
    
    # Test 3: Suppression d'un fichier
    Write-Host "Test 3: Suppression d'un fichier..." -ForegroundColor Magenta
    Remove-Item -Path $newFilePath -Force
    Start-Sleep -Seconds 2
    
    # Test 4: Renommage d'un fichier
    Write-Host "Test 4: Renommage d'un fichier..." -ForegroundColor Magenta
    $renamedPath = Join-Path -Path $testDir -ChildPath "renamed.md"
    Rename-Item -Path $testFilePath -NewName "renamed.md"
    Start-Sleep -Seconds 2
    
    Write-Host "Tests terminés avec succès" -ForegroundColor Green
}
finally {
    # Arrêter le watcher
    if ($process -and !$process.HasExited) {
        Write-Host "Arrêt du watcher..." -ForegroundColor Yellow
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
    }
    
    # Nettoyer les fichiers de test
    if (Test-Path -Path $testDir) {
        Write-Host "Nettoyage des fichiers de test..." -ForegroundColor Yellow
        Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
