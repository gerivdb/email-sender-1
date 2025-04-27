# Test-MarkdownToRoadmap.ps1
# Script pour tester la fonction ConvertFrom-MarkdownToRoadmap

# Importer la fonction Ã  tester
$functionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\ConvertFrom-MarkdownToRoadmap.ps1"
. $functionPath

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier markdown de test
$testMarkdownPath = Join-Path -Path $testDir -ChildPath "test-roadmap.md"
$testMarkdown = @"
# Roadmap de Test

Ceci est une roadmap de test pour valider la fonction ConvertFrom-MarkdownToRoadmap.

## Section 1

- [ ] **1** TÃ¢che 1
  - [x] **1.1** TÃ¢che 1.1
  - [ ] **1.2** TÃ¢che 1.2
    - [~] **1.2.1** TÃ¢che 1.2.1 @john #important
    - [!] **1.2.2** TÃ¢che 1.2.2 P1

## Section 2

- [ ] **2** TÃ¢che 2
  - [ ] **2.1** TÃ¢che 2.1 @date:2023-12-31
"@

$testMarkdown | Out-File -FilePath $testMarkdownPath -Encoding UTF8

Write-Host "Fichier de test crÃ©Ã©: $testMarkdownPath" -ForegroundColor Green

try {
    # Test 1: Conversion de base
    Write-Host "`nTest 1: Conversion de base" -ForegroundColor Cyan
    $roadmap = ConvertFrom-MarkdownToRoadmap -FilePath $testMarkdownPath
    
    Write-Host "Titre: $($roadmap.Title)" -ForegroundColor Yellow
    Write-Host "Description: $($roadmap.Description)" -ForegroundColor Yellow
    Write-Host "Nombre de sections: $($roadmap.Sections.Count)" -ForegroundColor Yellow
    
    # VÃ©rifier les sections
    if ($roadmap.Sections.Count -eq 2) {
        Write-Host "âœ“ Nombre de sections correct" -ForegroundColor Green
    } else {
        Write-Host "âœ— Nombre de sections incorrect" -ForegroundColor Red
    }
    
    # VÃ©rifier le titre de la premiÃ¨re section
    if ($roadmap.Sections[0].Title -eq "Section 1") {
        Write-Host "âœ“ Titre de la premiÃ¨re section correct" -ForegroundColor Green
    } else {
        Write-Host "âœ— Titre de la premiÃ¨re section incorrect" -ForegroundColor Red
    }
    
    # VÃ©rifier les tÃ¢ches de la premiÃ¨re section
    $section1 = $roadmap.Sections[0]
    if ($section1.Tasks.Count -gt 0) {
        Write-Host "âœ“ La premiÃ¨re section contient des tÃ¢ches" -ForegroundColor Green
        
        # VÃ©rifier la premiÃ¨re tÃ¢che
        $task1 = $section1.Tasks[0]
        if ($task1.Id -eq "1" -and $task1.Status -eq "Incomplete") {
            Write-Host "âœ“ ID et statut de la premiÃ¨re tÃ¢che corrects" -ForegroundColor Green
        } else {
            Write-Host "âœ— ID ou statut de la premiÃ¨re tÃ¢che incorrect" -ForegroundColor Red
            Write-Host "  ID: $($task1.Id), Statut: $($task1.Status)" -ForegroundColor Red
        }
        
        # VÃ©rifier les sous-tÃ¢ches
        if ($task1.SubTasks.Count -eq 2) {
            Write-Host "âœ“ Nombre de sous-tÃ¢ches correct" -ForegroundColor Green
            
            # VÃ©rifier la premiÃ¨re sous-tÃ¢che
            $subtask1 = $task1.SubTasks[0]
            if ($subtask1.Id -eq "1.1" -and $subtask1.Status -eq "Complete") {
                Write-Host "âœ“ ID et statut de la premiÃ¨re sous-tÃ¢che corrects" -ForegroundColor Green
            } else {
                Write-Host "âœ— ID ou statut de la premiÃ¨re sous-tÃ¢che incorrect" -ForegroundColor Red
                Write-Host "  ID: $($subtask1.Id), Statut: $($subtask1.Status)" -ForegroundColor Red
            }
            
            # VÃ©rifier la deuxiÃ¨me sous-tÃ¢che
            $subtask2 = $task1.SubTasks[1]
            if ($subtask2.Id -eq "1.2" -and $subtask2.Status -eq "Incomplete") {
                Write-Host "âœ“ ID et statut de la deuxiÃ¨me sous-tÃ¢che corrects" -ForegroundColor Green
            } else {
                Write-Host "âœ— ID ou statut de la deuxiÃ¨me sous-tÃ¢che incorrect" -ForegroundColor Red
                Write-Host "  ID: $($subtask2.Id), Statut: $($subtask2.Status)" -ForegroundColor Red
            }
            
            # VÃ©rifier les sous-sous-tÃ¢ches
            if ($subtask2.SubTasks.Count -eq 2) {
                Write-Host "âœ“ Nombre de sous-sous-tÃ¢ches correct" -ForegroundColor Green
                
                # VÃ©rifier la premiÃ¨re sous-sous-tÃ¢che
                $subsubtask1 = $subtask2.SubTasks[0]
                if ($subsubtask1.Id -eq "1.2.1" -and $subsubtask1.Status -eq "InProgress") {
                    Write-Host "âœ“ ID et statut de la premiÃ¨re sous-sous-tÃ¢che corrects" -ForegroundColor Green
                } else {
                    Write-Host "âœ— ID ou statut de la premiÃ¨re sous-sous-tÃ¢che incorrect" -ForegroundColor Red
                    Write-Host "  ID: $($subsubtask1.Id), Statut: $($subsubtask1.Status)" -ForegroundColor Red
                }
            } else {
                Write-Host "âœ— Nombre de sous-sous-tÃ¢ches incorrect" -ForegroundColor Red
                Write-Host "  Nombre: $($subtask2.SubTasks.Count)" -ForegroundColor Red
            }
        } else {
            Write-Host "âœ— Nombre de sous-tÃ¢ches incorrect" -ForegroundColor Red
            Write-Host "  Nombre: $($task1.SubTasks.Count)" -ForegroundColor Red
        }
    } else {
        Write-Host "âœ— La premiÃ¨re section ne contient pas de tÃ¢ches" -ForegroundColor Red
    }
    
    # Test 2: Conversion avec mÃ©tadonnÃ©es
    Write-Host "`nTest 2: Conversion avec mÃ©tadonnÃ©es" -ForegroundColor Cyan
    $roadmapWithMetadata = ConvertFrom-MarkdownToRoadmap -FilePath $testMarkdownPath -IncludeMetadata
    
    # VÃ©rifier les mÃ©tadonnÃ©es
    $section1 = $roadmapWithMetadata.Sections[0]
    $task1 = $section1.Tasks[0]
    $subtask2 = $task1.SubTasks[1]
    $subsubtask1 = $subtask2.SubTasks[0]
    
    if ($subsubtask1.Metadata.ContainsKey("Assignee") -and $subsubtask1.Metadata["Assignee"] -eq "john") {
        Write-Host "âœ“ Assignation correcte" -ForegroundColor Green
    } else {
        Write-Host "âœ— Assignation incorrecte" -ForegroundColor Red
        if ($subsubtask1.Metadata.ContainsKey("Assignee")) {
            Write-Host "  Assignation: $($subsubtask1.Metadata['Assignee'])" -ForegroundColor Red
        } else {
            Write-Host "  Pas d'assignation trouvÃ©e" -ForegroundColor Red
        }
    }
    
    if ($subsubtask1.Metadata.ContainsKey("Tags") -and $subsubtask1.Metadata["Tags"] -contains "important") {
        Write-Host "âœ“ Tags corrects" -ForegroundColor Green
    } else {
        Write-Host "âœ— Tags incorrects" -ForegroundColor Red
        if ($subsubtask1.Metadata.ContainsKey("Tags")) {
            Write-Host "  Tags: $($subsubtask1.Metadata['Tags'] -join ', ')" -ForegroundColor Red
        } else {
            Write-Host "  Pas de tags trouvÃ©s" -ForegroundColor Red
        }
    }
    
    Write-Host "`nTous les tests sont terminÃ©s." -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors des tests: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}
finally {
    # Nettoyer les fichiers de test
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
        Write-Host "`nRÃ©pertoire de test nettoyÃ©: $testDir" -ForegroundColor Gray
    }
}
