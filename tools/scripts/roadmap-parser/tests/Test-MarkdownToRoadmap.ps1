# Test-MarkdownToRoadmap.ps1
# Script pour tester la fonction ConvertFrom-MarkdownToRoadmap

# Importer la fonction à tester
$functionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\ConvertFrom-MarkdownToRoadmap.ps1"
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

Ceci est une roadmap de test pour valider la fonction ConvertFrom-MarkdownToRoadmap.

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
    $roadmap = ConvertFrom-MarkdownToRoadmap -FilePath $testMarkdownPath
    
    Write-Host "Titre: $($roadmap.Title)" -ForegroundColor Yellow
    Write-Host "Description: $($roadmap.Description)" -ForegroundColor Yellow
    Write-Host "Nombre de sections: $($roadmap.Sections.Count)" -ForegroundColor Yellow
    
    # Vérifier les sections
    if ($roadmap.Sections.Count -eq 2) {
        Write-Host "✓ Nombre de sections correct" -ForegroundColor Green
    } else {
        Write-Host "✗ Nombre de sections incorrect" -ForegroundColor Red
    }
    
    # Vérifier le titre de la première section
    if ($roadmap.Sections[0].Title -eq "Section 1") {
        Write-Host "✓ Titre de la première section correct" -ForegroundColor Green
    } else {
        Write-Host "✗ Titre de la première section incorrect" -ForegroundColor Red
    }
    
    # Vérifier les tâches de la première section
    $section1 = $roadmap.Sections[0]
    if ($section1.Tasks.Count -gt 0) {
        Write-Host "✓ La première section contient des tâches" -ForegroundColor Green
        
        # Vérifier la première tâche
        $task1 = $section1.Tasks[0]
        if ($task1.Id -eq "1" -and $task1.Status -eq "Incomplete") {
            Write-Host "✓ ID et statut de la première tâche corrects" -ForegroundColor Green
        } else {
            Write-Host "✗ ID ou statut de la première tâche incorrect" -ForegroundColor Red
            Write-Host "  ID: $($task1.Id), Statut: $($task1.Status)" -ForegroundColor Red
        }
        
        # Vérifier les sous-tâches
        if ($task1.SubTasks.Count -eq 2) {
            Write-Host "✓ Nombre de sous-tâches correct" -ForegroundColor Green
            
            # Vérifier la première sous-tâche
            $subtask1 = $task1.SubTasks[0]
            if ($subtask1.Id -eq "1.1" -and $subtask1.Status -eq "Complete") {
                Write-Host "✓ ID et statut de la première sous-tâche corrects" -ForegroundColor Green
            } else {
                Write-Host "✗ ID ou statut de la première sous-tâche incorrect" -ForegroundColor Red
                Write-Host "  ID: $($subtask1.Id), Statut: $($subtask1.Status)" -ForegroundColor Red
            }
            
            # Vérifier la deuxième sous-tâche
            $subtask2 = $task1.SubTasks[1]
            if ($subtask2.Id -eq "1.2" -and $subtask2.Status -eq "Incomplete") {
                Write-Host "✓ ID et statut de la deuxième sous-tâche corrects" -ForegroundColor Green
            } else {
                Write-Host "✗ ID ou statut de la deuxième sous-tâche incorrect" -ForegroundColor Red
                Write-Host "  ID: $($subtask2.Id), Statut: $($subtask2.Status)" -ForegroundColor Red
            }
            
            # Vérifier les sous-sous-tâches
            if ($subtask2.SubTasks.Count -eq 2) {
                Write-Host "✓ Nombre de sous-sous-tâches correct" -ForegroundColor Green
                
                # Vérifier la première sous-sous-tâche
                $subsubtask1 = $subtask2.SubTasks[0]
                if ($subsubtask1.Id -eq "1.2.1" -and $subsubtask1.Status -eq "InProgress") {
                    Write-Host "✓ ID et statut de la première sous-sous-tâche corrects" -ForegroundColor Green
                } else {
                    Write-Host "✗ ID ou statut de la première sous-sous-tâche incorrect" -ForegroundColor Red
                    Write-Host "  ID: $($subsubtask1.Id), Statut: $($subsubtask1.Status)" -ForegroundColor Red
                }
            } else {
                Write-Host "✗ Nombre de sous-sous-tâches incorrect" -ForegroundColor Red
                Write-Host "  Nombre: $($subtask2.SubTasks.Count)" -ForegroundColor Red
            }
        } else {
            Write-Host "✗ Nombre de sous-tâches incorrect" -ForegroundColor Red
            Write-Host "  Nombre: $($task1.SubTasks.Count)" -ForegroundColor Red
        }
    } else {
        Write-Host "✗ La première section ne contient pas de tâches" -ForegroundColor Red
    }
    
    # Test 2: Conversion avec métadonnées
    Write-Host "`nTest 2: Conversion avec métadonnées" -ForegroundColor Cyan
    $roadmapWithMetadata = ConvertFrom-MarkdownToRoadmap -FilePath $testMarkdownPath -IncludeMetadata
    
    # Vérifier les métadonnées
    $section1 = $roadmapWithMetadata.Sections[0]
    $task1 = $section1.Tasks[0]
    $subtask2 = $task1.SubTasks[1]
    $subsubtask1 = $subtask2.SubTasks[0]
    
    if ($subsubtask1.Metadata.ContainsKey("Assignee") -and $subsubtask1.Metadata["Assignee"] -eq "john") {
        Write-Host "✓ Assignation correcte" -ForegroundColor Green
    } else {
        Write-Host "✗ Assignation incorrecte" -ForegroundColor Red
        if ($subsubtask1.Metadata.ContainsKey("Assignee")) {
            Write-Host "  Assignation: $($subsubtask1.Metadata['Assignee'])" -ForegroundColor Red
        } else {
            Write-Host "  Pas d'assignation trouvée" -ForegroundColor Red
        }
    }
    
    if ($subsubtask1.Metadata.ContainsKey("Tags") -and $subsubtask1.Metadata["Tags"] -contains "important") {
        Write-Host "✓ Tags corrects" -ForegroundColor Green
    } else {
        Write-Host "✗ Tags incorrects" -ForegroundColor Red
        if ($subsubtask1.Metadata.ContainsKey("Tags")) {
            Write-Host "  Tags: $($subsubtask1.Metadata['Tags'] -join ', ')" -ForegroundColor Red
        } else {
            Write-Host "  Pas de tags trouvés" -ForegroundColor Red
        }
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
