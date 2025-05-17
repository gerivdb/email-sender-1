#Requires -Version 5.1
<#
.SYNOPSIS
    Teste le script de surveillance des fichiers Markdown.
.DESCRIPTION
    Ce script teste le script de surveillance des fichiers Markdown en créant
    un fichier temporaire et en simulant des modifications.
.NOTES
    Nom: Test-FileWatcher.ps1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de création: 2025-06-10
#>

# Chemin du script de surveillance
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$watcherScriptPath = Join-Path -Path $scriptPath -ChildPath "..\watcher\Watch-MarkdownFiles.ps1"

if (-not (Test-Path -Path $watcherScriptPath)) {
  Write-Error "Le script de surveillance n'existe pas: $watcherScriptPath"
  exit 1
}

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "MarkdownWatcherTest_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
if (-not (Test-Path -Path $testDir)) {
  New-Item -ItemType Directory -Path $testDir -Force | Out-Null
}

Write-Host "Répertoire de test: $testDir" -ForegroundColor Green

# Créer un fichier Markdown de test
$testFilePath = Join-Path -Path $testDir -ChildPath "test_plan.md"

$content = @"
# Plan de test
*Version 1.0 - $(Get-Date -Format "yyyy-MM-dd") - Progression globale : 0%*

Ce fichier est utilisé pour tester le script de surveillance des fichiers Markdown.

## 1. Section de test

- [ ] **1.1** Tâche de test 1
  - [ ] **1.1.1** Sous-tâche de test 1.1
  - [ ] **1.1.2** Sous-tâche de test 1.2
- [ ] **1.2** Tâche de test 2
  - [ ] **1.2.1** Sous-tâche de test 2.1
  - [ ] **1.2.2** Sous-tâche de test 2.2

## 2. Autre section de test

- [ ] **2.1** Tâche de test 3
  - [ ] **2.1.1** Sous-tâche de test 3.1
  - [ ] **2.1.2** Sous-tâche de test 3.2
- [ ] **2.2** Tâche de test 4
  - [ ] **2.2.1** Sous-tâche de test 4.1
  - [ ] **2.2.2** Sous-tâche de test 4.2
"@

$content | Set-Content -Path $testFilePath -Encoding UTF8

Write-Host "Fichier de test créé: $testFilePath" -ForegroundColor Green

# Démarrer le script de surveillance dans un nouveau processus
Write-Host "Démarrage du script de surveillance..." -ForegroundColor Yellow
$process = Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$watcherScriptPath`" -WatchPath `"$testDir`" -EnableVerboseLogging" -PassThru -WindowStyle Normal

Write-Host "Script de surveillance démarré avec PID: $($process.Id)" -ForegroundColor Green

# Attendre que le script de surveillance soit prêt
Write-Host "Attente de 5 secondes pour que le script de surveillance soit prêt..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Effectuer des modifications sur le fichier de test
Write-Host "Modification du fichier de test..." -ForegroundColor Yellow

# Modification 1: Ajouter une nouvelle tâche
$newContent = $content + "`n- [ ] **3.1** Nouvelle tâche de test"
$newContent | Set-Content -Path $testFilePath -Encoding UTF8
Write-Host "Modification 1: Ajout d'une nouvelle tâche" -ForegroundColor Green
Start-Sleep -Seconds 2

# Modification 2: Modifier le statut d'une tâche
$newContent = $newContent -replace "- \[ \] \*\*1\.1\*\*", "- [x] **1.1**"
$newContent | Set-Content -Path $testFilePath -Encoding UTF8
Write-Host "Modification 2: Modification du statut d'une tâche" -ForegroundColor Green
Start-Sleep -Seconds 2

# Modification 3: Modifier le titre d'une tâche
$newContent = $newContent -replace "Tâche de test 2", "Tâche de test 2 modifiée"
$newContent | Set-Content -Path $testFilePath -Encoding UTF8
Write-Host "Modification 3: Modification du titre d'une tâche" -ForegroundColor Green
Start-Sleep -Seconds 2

# Modification 4: Supprimer une tâche
$newContent = $newContent -replace "- \[ \] \*\*2\.2\*\*.*\r?\n  - \[ \] \*\*2\.2\.1\*\*.*\r?\n  - \[ \] \*\*2\.2\.2\*\*.*\r?\n", ""
$newContent | Set-Content -Path $testFilePath -Encoding UTF8
Write-Host "Modification 4: Suppression d'une tâche" -ForegroundColor Green
Start-Sleep -Seconds 2

# Modification 5: Créer un nouveau fichier
$newFilePath = Join-Path -Path $testDir -ChildPath "new_plan.md"
$content | Set-Content -Path $newFilePath -Encoding UTF8
Write-Host "Modification 5: Création d'un nouveau fichier" -ForegroundColor Green
Start-Sleep -Seconds 2

# Modification 6: Supprimer un fichier
Remove-Item -Path $newFilePath -Force
Write-Host "Modification 6: Suppression d'un fichier" -ForegroundColor Green
Start-Sleep -Seconds 2

# Attendre quelques secondes avant d'arrêter le test
Write-Host "Attente de 5 secondes avant d'arrêter le test..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Arrêter le script de surveillance
Stop-Process -Id $process.Id -Force
Write-Host "Script de surveillance arrêté" -ForegroundColor Green

# Nettoyer les fichiers de test
Remove-Item -Path $testDir -Recurse -Force
Write-Host "Fichiers de test nettoyés" -ForegroundColor Green

Write-Host "Test terminé avec succès" -ForegroundColor Green
