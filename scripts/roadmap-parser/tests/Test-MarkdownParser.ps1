# Test-MarkdownParser.ps1
# Script pour tester la fonction ConvertFrom-MarkdownToObject

# Importer la fonction à tester
$functionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\ConvertFrom-MarkdownToObject.ps1"
. $functionPath

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Créer un fichier markdown de test
$testMarkdownPath = Join-Path -Path $testDir -ChildPath "test-roadmap.md"
$testMarkdown = @"
# Roadmap de Test

Ceci est une roadmap de test pour valider la fonction ConvertFrom-MarkdownToObject.

## Section 1

- [ ] **1** Tâche 1
  - [x] **1.1** Tâche 1.1
  - [ ] **1.2** Tâche 1.2
    - [~] **1.2.1** Tâche 1.2.1 @john #important
    - [!] **1.2.2** Tâche 1.2.2 P1

## Section 2

- [ ] **2** Tâche 2
  - [ ] **2.1** Tâche 2.1 @date:2023-12-31
"@

$testMarkdown | Out-File -FilePath $testMarkdownPath -Encoding UTF8

Write-Host "Fichier de test créé: $testMarkdownPath" -ForegroundColor Green

try {
    # Test 1: Conversion de base
    Write-Host "`nTest 1: Conversion de base" -ForegroundColor Cyan
    $result = ConvertFrom-MarkdownToObject -FilePath $testMarkdownPath
    
    Write-Host "Titre: $($result.Title)" -ForegroundColor Yellow
    Write-Host "Description: $($result.Description)" -ForegroundColor Yellow
    Write-Host "Nombre de sections: $($result.Items.Count)" -ForegroundColor Yellow
    
    # Vérifier les sections
    if ($result.Items.Count -eq 2) {
        Write-Host "✓ Nombre de sections correct" -ForegroundColor Green
    } else {
        Write-Host "✗ Nombre de sections incorrect" -ForegroundColor Red
    }
    
    # Vérifier le titre de la première section
    if ($result.Items[0].Title -eq "Section 1") {
        Write-Host "✓ Titre de la première section correct" -ForegroundColor Green
    } else {
        Write-Host "✗ Titre de la première section incorrect" -ForegroundColor Red
    }
    
    # Vérifier les tâches de la première section
    $section1 = $result.Items[0]
    if ($section1.Items.Count -gt 0) {
        Write-Host "✓ La première section contient des tâches" -ForegroundColor Green
        
        # Vérifier la première tâche
        $task1 = $section1.Items[0]
        if ($task1.Id -eq "1" -and $task1.Status -eq "Incomplete") {
            Write-Host "✓ ID et statut de la première tâche corrects" -ForegroundColor Green
        } else {
            Write-Host "✗ ID ou statut de la première tâche incorrect" -ForegroundColor Red
        }
        
        # Vérifier les sous-tâches
        if ($task1.Items.Count -eq 2) {
            Write-Host "✓ Nombre de sous-tâches correct" -ForegroundColor Green
            
            # Vérifier la première sous-tâche
            $subtask1 = $task1.Items[0]
            if ($subtask1.Id -eq "1.1" -and $subtask1.Status -eq "Complete") {
                Write-Host "✓ ID et statut de la première sous-tâche corrects" -ForegroundColor Green
            } else {
                Write-Host "✗ ID ou statut de la première sous-tâche incorrect" -ForegroundColor Red
            }
        } else {
            Write-Host "✗ Nombre de sous-tâches incorrect" -ForegroundColor Red
        }
    } else {
        Write-Host "✗ La première section ne contient pas de tâches" -ForegroundColor Red
    }
    
    # Test 2: Conversion avec métadonnées
    Write-Host "`nTest 2: Conversion avec métadonnées" -ForegroundColor Cyan
    $resultWithMetadata = ConvertFrom-MarkdownToObject -FilePath $testMarkdownPath -IncludeMetadata
    
    # Vérifier les métadonnées
    $section1 = $resultWithMetadata.Items[0]
    $task1 = $section1.Items[0]
    $subtask2 = $task1.Items[1]
    $subsubtask1 = $subtask2.Items[0]
    
    if ($subsubtask1.Metadata.ContainsKey("Assignee") -and $subsubtask1.Metadata["Assignee"] -eq "john") {
        Write-Host "✓ Assignation correcte" -ForegroundColor Green
    } else {
        Write-Host "✗ Assignation incorrecte" -ForegroundColor Red
    }
    
    if ($subsubtask1.Metadata.ContainsKey("Tags") -and $subsubtask1.Metadata["Tags"] -contains "important") {
        Write-Host "✓ Tags corrects" -ForegroundColor Green
    } else {
        Write-Host "✗ Tags incorrects" -ForegroundColor Red
    }
    
    # Test 3: Marqueurs de statut personnalisés
    Write-Host "`nTest 3: Marqueurs de statut personnalisés" -ForegroundColor Cyan
    $customMarkers = @{
        "x" = "InProgress";  # Remplacer Complete par InProgress
        "~" = "Complete"     # Remplacer InProgress par Complete
    }
    
    $resultWithCustomMarkers = ConvertFrom-MarkdownToObject -FilePath $testMarkdownPath -CustomStatusMarkers $customMarkers
    
    $section1 = $resultWithCustomMarkers.Items[0]
    $task1 = $section1.Items[0]
    $subtask1 = $task1.Items[0]
    $subtask2 = $task1.Items[1]
    $subsubtask1 = $subtask2.Items[0]
    
    if ($subtask1.Status -eq "InProgress") {
        Write-Host "✓ Marqueur personnalisé 'x' correct" -ForegroundColor Green
    } else {
        Write-Host "✗ Marqueur personnalisé 'x' incorrect" -ForegroundColor Red
    }
    
    if ($subsubtask1.Status -eq "Complete") {
        Write-Host "✓ Marqueur personnalisé '~' correct" -ForegroundColor Green
    } else {
        Write-Host "✗ Marqueur personnalisé '~' incorrect" -ForegroundColor Red
    }
    
    Write-Host "`nTous les tests sont terminés." -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors des tests: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}
finally {
    # Nettoyer les fichiers de test
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
        Write-Host "`nRépertoire de test nettoyé: $testDir" -ForegroundColor Gray
    }
}
