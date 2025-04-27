# Script de test simple pour la fonction ConvertFrom-MarkdownToObject

# Importer la fonction Ã  tester
$functionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\ConvertFrom-MarkdownToObject.ps1"
. $functionPath

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier markdown de test simple
$simpleMarkdownPath = Join-Path -Path $testDir -ChildPath "simple.md"
@"
# Roadmap Simple

Ceci est une roadmap simple pour les tests.

## Section 1

- [ ] TÃ¢che 1
  - [x] **1.1** TÃ¢che 1.1
  - [ ] **1.2** TÃ¢che 1.2
    - [~] **1.2.1** TÃ¢che 1.2.1 @john #important
    - [!] **1.2.2** TÃ¢che 1.2.2 P1

## Section 2

- [ ] **2** TÃ¢che 2
  - [ ] **2.1** TÃ¢che 2.1 @date:2023-12-31
"@ | Out-File -FilePath $simpleMarkdownPath -Encoding UTF8

Write-Host "Fichier markdown de test crÃ©Ã©: $simpleMarkdownPath" -ForegroundColor Green

# Tester la fonction
try {
    Write-Host "Test 1: Conversion simple" -ForegroundColor Cyan
    $result = ConvertFrom-MarkdownToObject -FilePath $simpleMarkdownPath
    
    Write-Host "Titre: $($result.Title)" -ForegroundColor Yellow
    Write-Host "Description: $($result.Description)" -ForegroundColor Yellow
    Write-Host "Nombre de sections: $($result.Items.Count)" -ForegroundColor Yellow
    
    Write-Host "Test 1 rÃ©ussi!" -ForegroundColor Green
    
    Write-Host "Test 2: Conversion avec mÃ©tadonnÃ©es" -ForegroundColor Cyan
    $resultWithMetadata = ConvertFrom-MarkdownToObject -FilePath $simpleMarkdownPath -IncludeMetadata
    
    $section1 = $resultWithMetadata.Items[0]
    $task1_2_1 = $section1.Items[0].Items[1].Items[0]
    
    Write-Host "TÃ¢che 1.2.1 - AssignÃ©e Ã : $($task1_2_1.Metadata.Assignee)" -ForegroundColor Yellow
    Write-Host "TÃ¢che 1.2.1 - Tags: $($task1_2_1.Metadata.Tags -join ', ')" -ForegroundColor Yellow
    
    Write-Host "Test 2 rÃ©ussi!" -ForegroundColor Green
    
    Write-Host "Tous les tests ont rÃ©ussi!" -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors des tests: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}
finally {
    # Nettoyer les fichiers de test
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
        Write-Host "RÃ©pertoire de test nettoyÃ©: $testDir" -ForegroundColor Gray
    }
}
