#Requires -Version 5.1
<#
.SYNOPSIS
    Teste la détection des modifications dans les fichiers Markdown.
.DESCRIPTION
    Ce script teste la détection des modifications entre deux versions d'un fichier Markdown.
.NOTES
    Nom: Test-MarkdownChanges.ps1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
#>

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesPath = Join-Path -Path $scriptPath -ChildPath "..\modules"
$parserModulePath = Join-Path -Path $modulesPath -ChildPath "MarkdownParser.psm1"

if (Test-Path -Path $parserModulePath) {
    Import-Module $parserModulePath -Force
} else {
    Write-Error "Module MarkdownParser non trouvé: $parserModulePath"
    exit 1
}

# Chemin du script de détection des modifications
$detectScriptPath = Join-Path -Path $scriptPath -ChildPath "..\watcher\Detect-MarkdownChanges.ps1"

if (-not (Test-Path -Path $detectScriptPath)) {
    Write-Error "Script de détection des modifications non trouvé: $detectScriptPath"
    exit 1
}

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "MDChangesTest_$(Get-Date -Format 'yyyyMMddHHmmss')"
New-Item -ItemType Directory -Path $testDir -Force | Out-Null
Write-Host "Répertoire de test: $testDir" -ForegroundColor Cyan

# Créer la version originale du fichier
$originalFilePath = Join-Path -Path $testDir -ChildPath "original.md"
@"
# Plan de test
*Version 1.0 - $(Get-Date -Format "yyyy-MM-dd") - Progression globale : 0%*

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
"@ | Set-Content -Path $originalFilePath -Encoding UTF8

# Créer la version modifiée du fichier
$modifiedFilePath = Join-Path -Path $testDir -ChildPath "modified.md"
@"
# Plan de test
*Version 1.0 - $(Get-Date -Format "yyyy-MM-dd") - Progression globale : 25%*

## 1. Section de test

- [x] **1.1** Tâche de test 1 modifiée
  - [x] **1.1.1** Sous-tâche de test 1.1
  - [ ] **1.1.2** Sous-tâche de test 1.2
- [ ] **1.2** Tâche de test 2
  - [ ] **1.2.1** Sous-tâche de test 2.1
  - [ ] **1.2.2** Sous-tâche de test 2.2

## 2. Autre section de test

- [ ] **2.1** Tâche de test 3
  - [ ] **2.1.1** Sous-tâche de test 3.1
  - [ ] **2.1.2** Sous-tâche de test 3.2
- [ ] **3.1** Nouvelle tâche de test
  - [ ] **3.1.1** Nouvelle sous-tâche de test
"@ | Set-Content -Path $modifiedFilePath -Encoding UTF8

# Tester la détection des modifications
Write-Host "Test de la détection des modifications..." -ForegroundColor Yellow

# Exécuter le script de détection des modifications
$outputPath = Join-Path -Path $testDir -ChildPath "changes.json"
& $detectScriptPath -FilePath $modifiedFilePath -PreviousVersion $originalFilePath -OutputPath $outputPath -OutputFormat "JSON"

# Vérifier que le fichier de sortie existe
if (Test-Path -Path $outputPath) {
    Write-Host "Fichier de sortie créé: $outputPath" -ForegroundColor Green
    
    # Lire le contenu du fichier de sortie
    $changes = Get-Content -Path $outputPath -Raw | ConvertFrom-Json
    
    # Afficher les modifications détectées
    Write-Host "Modifications détectées:" -ForegroundColor Magenta
    Write-Host "  Tâches ajoutées: $($changes.Added.Count)" -ForegroundColor Cyan
    Write-Host "  Tâches supprimées: $($changes.Removed.Count)" -ForegroundColor Cyan
    Write-Host "  Tâches modifiées: $($changes.Modified.Count)" -ForegroundColor Cyan
    Write-Host "  Statuts changés: $($changes.StatusChanged.Count)" -ForegroundColor Cyan
    
    # Vérifier que les modifications attendues ont été détectées
    $success = $true
    
    # Vérifier les tâches ajoutées
    if ($changes.Added.Count -eq 2) {
        Write-Host "✓ Tâches ajoutées correctement détectées" -ForegroundColor Green
    } else {
        Write-Host "✗ Erreur dans la détection des tâches ajoutées" -ForegroundColor Red
        $success = $false
    }
    
    # Vérifier les tâches supprimées
    if ($changes.Removed.Count -eq 3) {
        Write-Host "✓ Tâches supprimées correctement détectées" -ForegroundColor Green
    } else {
        Write-Host "✗ Erreur dans la détection des tâches supprimées" -ForegroundColor Red
        $success = $false
    }
    
    # Vérifier les tâches modifiées
    if ($changes.Modified.Count -eq 1) {
        Write-Host "✓ Tâches modifiées correctement détectées" -ForegroundColor Green
    } else {
        Write-Host "✗ Erreur dans la détection des tâches modifiées" -ForegroundColor Red
        $success = $false
    }
    
    # Vérifier les statuts changés
    if ($changes.StatusChanged.Count -eq 2) {
        Write-Host "✓ Statuts changés correctement détectés" -ForegroundColor Green
    } else {
        Write-Host "✗ Erreur dans la détection des statuts changés" -ForegroundColor Red
        $success = $false
    }
    
    # Afficher le résultat global
    if ($success) {
        Write-Host "Test réussi: Toutes les modifications ont été correctement détectées" -ForegroundColor Green
    } else {
        Write-Host "Test échoué: Certaines modifications n'ont pas été correctement détectées" -ForegroundColor Red
    }
} else {
    Write-Host "Erreur: Le fichier de sortie n'a pas été créé" -ForegroundColor Red
}

# Nettoyer les fichiers de test
Remove-Item -Path $testDir -Recurse -Force
Write-Host "Fichiers de test nettoyés" -ForegroundColor Yellow
