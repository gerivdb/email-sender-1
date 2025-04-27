# Test-MarkdownToRoadmapExtended.ps1
# Script pour tester la fonction ConvertFrom-MarkdownToRoadmapExtended

# Importer la fonction Ã  tester
$functionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\ConvertFrom-MarkdownToRoadmapExtended.ps1"
. $functionPath

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier markdown de test avec des fonctionnalitÃ©s avancÃ©es
$testMarkdownPath = Join-Path -Path $testDir -ChildPath "test-roadmap-extended.md"
$testMarkdown = @"
# Roadmap AvancÃ©e

Ceci est une roadmap avancÃ©e pour tester les fonctionnalitÃ©s Ã©tendues.

## Planification

- [ ] **PLAN-1** Analyse des besoins @john #important @estimate:3d
  - [x] **PLAN-1.1** Recueillir les exigences @sarah #urgent @date:2023-07-01
  - [ ] **PLAN-1.2** Analyser la faisabilitÃ© @depends:PLAN-1.1
    - [~] **PLAN-1.2.1** Ã‰tude technique @start:2023-07-05 @end:2023-07-10
    - [!] **PLAN-1.2.2** Ã‰valuation des coÃ»ts P1 ref:PLAN-1.1

## DÃ©veloppement

- [ ] **DEV-1** ImplÃ©mentation @depends:PLAN-1
  - [ ] **DEV-1.1** DÃ©velopper le backend @sarah @estimate:5d
  - [ ] **DEV-1.2** CrÃ©er l'interface utilisateur ref:DEV-1.1
"@

$testMarkdown | Out-File -FilePath $testMarkdownPath -Encoding UTF8

Write-Host "Fichier de test crÃ©Ã©: $testMarkdownPath" -ForegroundColor Green

try {
    # Test 1: Conversion de base
    Write-Host "`nTest 1: Conversion de base" -ForegroundColor Cyan
    $roadmap = ConvertFrom-MarkdownToRoadmapExtended -FilePath $testMarkdownPath
    
    Write-Host "Titre: $($roadmap.Title)" -ForegroundColor Yellow
    Write-Host "Description: $($roadmap.Description)" -ForegroundColor Yellow
    Write-Host "Nombre de sections: $($roadmap.Sections.Count)" -ForegroundColor Yellow
    Write-Host "Nombre de tÃ¢ches: $($roadmap.AllTasks.Count)" -ForegroundColor Yellow
    
    # VÃ©rifier les sections
    if ($roadmap.Sections.Count -eq 2) {
        Write-Host "âœ“ Nombre de sections correct" -ForegroundColor Green
    } else {
        Write-Host "âœ— Nombre de sections incorrect" -ForegroundColor Red
    }
    
    # VÃ©rifier le dictionnaire de tÃ¢ches
    if ($roadmap.AllTasks.Count -eq 7) {
        Write-Host "âœ“ Nombre de tÃ¢ches dans le dictionnaire correct" -ForegroundColor Green
    } else {
        Write-Host "âœ— Nombre de tÃ¢ches dans le dictionnaire incorrect" -ForegroundColor Red
        Write-Host "  Nombre: $($roadmap.AllTasks.Count)" -ForegroundColor Red
    }
    
    # Test 2: Conversion avec mÃ©tadonnÃ©es
    Write-Host "`nTest 2: Conversion avec mÃ©tadonnÃ©es" -ForegroundColor Cyan
    $roadmapWithMetadata = ConvertFrom-MarkdownToRoadmapExtended -FilePath $testMarkdownPath -IncludeMetadata
    
    # VÃ©rifier les mÃ©tadonnÃ©es
    $task = $roadmapWithMetadata.AllTasks["PLAN-1"]
    if ($task.Metadata.ContainsKey("Assignee") -and $task.Metadata["Assignee"] -eq "john") {
        Write-Host "âœ“ Assignation correcte" -ForegroundColor Green
    } else {
        Write-Host "âœ— Assignation incorrecte" -ForegroundColor Red
    }
    
    if ($task.Metadata.ContainsKey("Tags") -and $task.Metadata["Tags"] -contains "important") {
        Write-Host "âœ“ Tags corrects" -ForegroundColor Green
    } else {
        Write-Host "âœ— Tags incorrects" -ForegroundColor Red
    }
    
    if ($task.Metadata.ContainsKey("Estimate") -and $task.Metadata["Estimate"] -eq "3d") {
        Write-Host "âœ“ Estimation correcte" -ForegroundColor Green
    } else {
        Write-Host "âœ— Estimation incorrecte" -ForegroundColor Red
    }
    
    # Test 3: DÃ©tection des dÃ©pendances
    Write-Host "`nTest 3: DÃ©tection des dÃ©pendances" -ForegroundColor Cyan
    $roadmapWithDependencies = ConvertFrom-MarkdownToRoadmapExtended -FilePath $testMarkdownPath -IncludeMetadata -DetectDependencies
    
    # VÃ©rifier les dÃ©pendances explicites
    $task = $roadmapWithDependencies.AllTasks["PLAN-1.2"]
    if ($task.Dependencies.Count -eq 1 -and $task.Dependencies[0].Id -eq "PLAN-1.1") {
        Write-Host "âœ“ DÃ©pendance explicite correcte" -ForegroundColor Green
    } else {
        Write-Host "âœ— DÃ©pendance explicite incorrecte" -ForegroundColor Red
        Write-Host "  Nombre de dÃ©pendances: $($task.Dependencies.Count)" -ForegroundColor Red
        if ($task.Dependencies.Count -gt 0) {
            Write-Host "  PremiÃ¨re dÃ©pendance: $($task.Dependencies[0].Id)" -ForegroundColor Red
        }
    }
    
    # VÃ©rifier les dÃ©pendances implicites
    $task = $roadmapWithDependencies.AllTasks["PLAN-1.2.2"]
    if ($task.Dependencies.Count -eq 1 -and $task.Dependencies[0].Id -eq "PLAN-1.1") {
        Write-Host "âœ“ DÃ©pendance implicite correcte" -ForegroundColor Green
    } else {
        Write-Host "âœ— DÃ©pendance implicite incorrecte" -ForegroundColor Red
        Write-Host "  Nombre de dÃ©pendances: $($task.Dependencies.Count)" -ForegroundColor Red
        if ($task.Dependencies.Count -gt 0) {
            Write-Host "  PremiÃ¨re dÃ©pendance: $($task.Dependencies[0].Id)" -ForegroundColor Red
        }
    }
    
    # VÃ©rifier les tÃ¢ches dÃ©pendantes
    $task = $roadmapWithDependencies.AllTasks["PLAN-1.1"]
    if ($task.DependentTasks.Count -eq 2) {
        Write-Host "âœ“ Nombre de tÃ¢ches dÃ©pendantes correct" -ForegroundColor Green
    } else {
        Write-Host "âœ— Nombre de tÃ¢ches dÃ©pendantes incorrect" -ForegroundColor Red
        Write-Host "  Nombre: $($task.DependentTasks.Count)" -ForegroundColor Red
    }
    
    # Test 4: Validation de la structure
    Write-Host "`nTest 4: Validation de la structure" -ForegroundColor Cyan
    $roadmapWithValidation = ConvertFrom-MarkdownToRoadmapExtended -FilePath $testMarkdownPath -ValidateStructure
    
    Write-Host "Nombre de problÃ¨mes de validation: $($roadmapWithValidation.ValidationIssues.Count)" -ForegroundColor Yellow
    if ($roadmapWithValidation.ValidationIssues.Count -eq 0) {
        Write-Host "âœ“ Aucun problÃ¨me de validation" -ForegroundColor Green
    } else {
        Write-Host "âœ— ProblÃ¨mes de validation dÃ©tectÃ©s" -ForegroundColor Red
        foreach ($issue in $roadmapWithValidation.ValidationIssues) {
            Write-Host "  - $issue" -ForegroundColor Red
        }
    }
    
    # CrÃ©er un fichier markdown avec des problÃ¨mes
    $testMarkdownWithIssuesPath = Join-Path -Path $testDir -ChildPath "test-roadmap-issues.md"
    $testMarkdownWithIssues = @"
# Roadmap avec ProblÃ¨mes

## Section 1

- [ ] **1** TÃ¢che 1
  - [x] **1** TÃ¢che avec ID en double
  - [ ] TÃ¢che sans ID
    - [~] **1.2.1** TÃ¢che avec dÃ©pendance circulaire @depends:1.2.1
"@

    $testMarkdownWithIssues | Out-File -FilePath $testMarkdownWithIssuesPath -Encoding UTF8
    
    $roadmapWithIssues = ConvertFrom-MarkdownToRoadmapExtended -FilePath $testMarkdownWithIssuesPath -IncludeMetadata -DetectDependencies -ValidateStructure
    
    Write-Host "`nValidation d'un fichier avec problÃ¨mes:" -ForegroundColor Cyan
    Write-Host "Nombre de problÃ¨mes de validation: $($roadmapWithIssues.ValidationIssues.Count)" -ForegroundColor Yellow
    if ($roadmapWithIssues.ValidationIssues.Count -gt 0) {
        Write-Host "âœ“ ProblÃ¨mes de validation correctement dÃ©tectÃ©s" -ForegroundColor Green
        foreach ($issue in $roadmapWithIssues.ValidationIssues) {
            Write-Host "  - $issue" -ForegroundColor Yellow
        }
    } else {
        Write-Host "âœ— ProblÃ¨mes de validation non dÃ©tectÃ©s" -ForegroundColor Red
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
