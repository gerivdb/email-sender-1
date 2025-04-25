# Script de test simple pour la fonction ConvertFrom-MarkdownToObject

# Importer la fonction à tester
$functionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\ConvertFrom-MarkdownToObject.ps1"
. $functionPath

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Créer un fichier markdown de test simple
$simpleMarkdownPath = Join-Path -Path $testDir -ChildPath "simple.md"
@"
# Roadmap Simple

Ceci est une roadmap simple pour les tests.

## Section 1

- [ ] Tâche 1
  - [x] **1.1** Tâche 1.1
  - [ ] **1.2** Tâche 1.2
    - [~] **1.2.1** Tâche 1.2.1 @john #important
    - [!] **1.2.2** Tâche 1.2.2 P1

## Section 2

- [ ] **2** Tâche 2
  - [ ] **2.1** Tâche 2.1 @date:2023-12-31
"@ | Out-File -FilePath $simpleMarkdownPath -Encoding UTF8

Write-Host "Fichier markdown de test créé: $simpleMarkdownPath" -ForegroundColor Green

# Tester la fonction
try {
    Write-Host "Test 1: Conversion simple" -ForegroundColor Cyan
    $result = ConvertFrom-MarkdownToObject -FilePath $simpleMarkdownPath
    
    Write-Host "Titre: $($result.Title)" -ForegroundColor Yellow
    Write-Host "Description: $($result.Description)" -ForegroundColor Yellow
    Write-Host "Nombre de sections: $($result.Items.Count)" -ForegroundColor Yellow
    
    Write-Host "Test 1 réussi!" -ForegroundColor Green
    
    Write-Host "Test 2: Conversion avec métadonnées" -ForegroundColor Cyan
    $resultWithMetadata = ConvertFrom-MarkdownToObject -FilePath $simpleMarkdownPath -IncludeMetadata
    
    $section1 = $resultWithMetadata.Items[0]
    $task1_2_1 = $section1.Items[0].Items[1].Items[0]
    
    Write-Host "Tâche 1.2.1 - Assignée à: $($task1_2_1.Metadata.Assignee)" -ForegroundColor Yellow
    Write-Host "Tâche 1.2.1 - Tags: $($task1_2_1.Metadata.Tags -join ', ')" -ForegroundColor Yellow
    
    Write-Host "Test 2 réussi!" -ForegroundColor Green
    
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors des tests: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}
finally {
    # Nettoyer les fichiers de test
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
        Write-Host "Répertoire de test nettoyé: $testDir" -ForegroundColor Gray
    }
}
