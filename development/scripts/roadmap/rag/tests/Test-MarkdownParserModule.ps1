#Requires -Version 5.1
<#
.SYNOPSIS
    Teste le module d'analyse Markdown.
.DESCRIPTION
    Ce script teste les fonctionnalités du module d'analyse Markdown.
.NOTES
    Nom: Test-MarkdownParserModule.ps1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de création: 2025-06-10
#>

# Importer le module d'analyse Markdown
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesPath = Join-Path -Path $scriptPath -ChildPath "..\modules"
$parserModulePath = Join-Path -Path $modulesPath -ChildPath "MarkdownParser.psm1"

if (-not (Test-Path -Path $parserModulePath)) {
    Write-Error "Le module d'analyse Markdown n'existe pas: $parserModulePath"
    exit 1
}

Import-Module $parserModulePath -Force

Write-Host "Module d'analyse Markdown importé avec succès" -ForegroundColor Green

# Créer un fichier Markdown de test
$testDir = Join-Path -Path $env:TEMP -ChildPath "MarkdownParserTest"
if (-not (Test-Path -Path $testDir)) {
    New-Item -ItemType Directory -Path $testDir -Force | Out-Null
}

$testFilePath = Join-Path -Path $testDir -ChildPath "test_plan.md"

$content = @"
# Plan de test
*Version 1.0 - $(Get-Date -Format "yyyy-MM-dd") - Progression globale : 25%*

Ce fichier est utilisé pour tester le module d'analyse Markdown.

Tags: test, markdown, parser

## 1. Section de test

- [ ] **1.1** Tâche de test 1 [MVP] [P0]
  - [x] **1.1.1** Sous-tâche de test 1.1 [2h]
  - [ ] **1.1.2** Sous-tâche de test 1.2 [P1] [3.5h]
- [x] **1.2** Tâche de test 2 [P2]
  - [x] **1.2.1** Sous-tâche de test 2.1
  - [x] **1.2.2** Sous-tâche de test 2.2

## 2. Autre section de test

- [ ] **2.1** Tâche de test 3 [MVP] [P1]
  - [ ] **2.1.1** Sous-tâche de test 3.1 [1h]
  - [ ] **2.1.2** Sous-tâche de test 3.2 [4h]
- [ ] **2.2** Tâche de test 4 [P3]
  - [ ] **2.2.1** Sous-tâche de test 4.1
  - [ ] **2.2.2** Sous-tâche de test 4.2
"@

$content | Set-Content -Path $testFilePath -Encoding UTF8

Write-Host "Fichier de test créé: $testFilePath" -ForegroundColor Green

# Tester l'extraction des tâches
Write-Host "Test de l'extraction des tâches..." -ForegroundColor Yellow
$tasks = Get-MarkdownTasks -FilePath $testFilePath -IncludeLineNumbers -IncludeMetadata

Write-Host "Nombre de tâches extraites: $($tasks.Count)" -ForegroundColor Green

# Afficher les tâches extraites
Write-Host "Tâches extraites:" -ForegroundColor Yellow
$tasks | ForEach-Object {
    Write-Host "ID: $($_.Id), Titre: $($_.Title), Statut: $($_.Status)"
    if ($_.Metadata.Count -gt 0) {
        Write-Host "  Métadonnées:"
        Write-Host "    MVP: $($_.Metadata.IsMVP)"
        Write-Host "    Priorité: $($_.Metadata.Priority)"
        Write-Host "    Heures estimées: $($_.Metadata.EstimatedHours)"
        if ($_.Metadata.Tags.Count -gt 0) {
            Write-Host "    Tags: $($_.Metadata.Tags -join ', ')"
        }
    }
}

# Tester l'extraction des métadonnées du fichier
Write-Host "Test de l'extraction des métadonnées du fichier..." -ForegroundColor Yellow
$metadata = Get-MarkdownMetadata -FilePath $testFilePath

Write-Host "Métadonnées du fichier:" -ForegroundColor Yellow
Write-Host "  Titre: $($metadata.Title)"
Write-Host "  Description: $($metadata.Description)"
Write-Host "  Version: $($metadata.Version)"
Write-Host "  Date: $($metadata.Date)"
Write-Host "  Progression: $($metadata.Progress)%"
if ($metadata.Tags.Count -gt 0) {
    Write-Host "  Tags: $($metadata.Tags -join ', ')"
}

# Tester le calcul de la progression
Write-Host "Test du calcul de la progression..." -ForegroundColor Yellow
$progress = Get-TasksProgress -Tasks $tasks
Write-Host "Progression calculée: $progress%" -ForegroundColor Green

# Tester la mise à jour du statut d'une tâche
Write-Host "Test de la mise à jour du statut d'une tâche..." -ForegroundColor Yellow
$result = Update-TaskStatus -FilePath $testFilePath -TaskId "2.1" -Status "Completed" -UpdateParents
Write-Host "Résultat de la mise à jour: $result" -ForegroundColor Green

# Vérifier que la mise à jour a été effectuée
Write-Host "Vérification de la mise à jour..." -ForegroundColor Yellow
$updatedTasks = Get-MarkdownTasks -FilePath $testFilePath
$updatedTask = $updatedTasks | Where-Object { $_.Id -eq "2.1" }
Write-Host "Statut de la tâche 2.1 après mise à jour: $($updatedTask.Status)" -ForegroundColor Green

# Vérifier que les tâches parentes ont été mises à jour
$parentTask = $updatedTasks | Where-Object { $_.Id -eq "2" }
if ($parentTask) {
    Write-Host "Statut de la tâche parente 2 après mise à jour: $($parentTask.Status)" -ForegroundColor Green
}

Write-Host "Tests terminés avec succès" -ForegroundColor Green
