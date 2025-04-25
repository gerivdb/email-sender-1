# Test-MarkdownToRoadmapExtended.ps1
# Script pour tester la fonction ConvertFrom-MarkdownToRoadmapExtended

# Importer la fonction à tester
$functionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\ConvertFrom-MarkdownToRoadmapExtended.ps1"
. $functionPath

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Créer un fichier markdown de test avec des fonctionnalités avancées
$testMarkdownPath = Join-Path -Path $testDir -ChildPath "test-roadmap-extended.md"
$testMarkdown = @"
# Roadmap Avancée

Ceci est une roadmap avancée pour tester les fonctionnalités étendues.

## Planification

- [ ] **PLAN-1** Analyse des besoins @john #important @estimate:3d
  - [x] **PLAN-1.1** Recueillir les exigences @sarah #urgent @date:2023-07-01
  - [ ] **PLAN-1.2** Analyser la faisabilité @depends:PLAN-1.1
    - [~] **PLAN-1.2.1** Étude technique @start:2023-07-05 @end:2023-07-10
    - [!] **PLAN-1.2.2** Évaluation des coûts P1 ref:PLAN-1.1

## Développement

- [ ] **DEV-1** Implémentation @depends:PLAN-1
  - [ ] **DEV-1.1** Développer le backend @sarah @estimate:5d
  - [ ] **DEV-1.2** Créer l'interface utilisateur ref:DEV-1.1
"@

$testMarkdown | Out-File -FilePath $testMarkdownPath -Encoding UTF8

Write-Host "Fichier de test créé: $testMarkdownPath" -ForegroundColor Green

try {
    # Test 1: Conversion de base
    Write-Host "`nTest 1: Conversion de base" -ForegroundColor Cyan
    $roadmap = ConvertFrom-MarkdownToRoadmapExtended -FilePath $testMarkdownPath
    
    Write-Host "Titre: $($roadmap.Title)" -ForegroundColor Yellow
    Write-Host "Description: $($roadmap.Description)" -ForegroundColor Yellow
    Write-Host "Nombre de sections: $($roadmap.Sections.Count)" -ForegroundColor Yellow
    Write-Host "Nombre de tâches: $($roadmap.AllTasks.Count)" -ForegroundColor Yellow
    
    # Vérifier les sections
    if ($roadmap.Sections.Count -eq 2) {
        Write-Host "✓ Nombre de sections correct" -ForegroundColor Green
    } else {
        Write-Host "✗ Nombre de sections incorrect" -ForegroundColor Red
    }
    
    # Vérifier le dictionnaire de tâches
    if ($roadmap.AllTasks.Count -eq 7) {
        Write-Host "✓ Nombre de tâches dans le dictionnaire correct" -ForegroundColor Green
    } else {
        Write-Host "✗ Nombre de tâches dans le dictionnaire incorrect" -ForegroundColor Red
        Write-Host "  Nombre: $($roadmap.AllTasks.Count)" -ForegroundColor Red
    }
    
    # Test 2: Conversion avec métadonnées
    Write-Host "`nTest 2: Conversion avec métadonnées" -ForegroundColor Cyan
    $roadmapWithMetadata = ConvertFrom-MarkdownToRoadmapExtended -FilePath $testMarkdownPath -IncludeMetadata
    
    # Vérifier les métadonnées
    $task = $roadmapWithMetadata.AllTasks["PLAN-1"]
    if ($task.Metadata.ContainsKey("Assignee") -and $task.Metadata["Assignee"] -eq "john") {
        Write-Host "✓ Assignation correcte" -ForegroundColor Green
    } else {
        Write-Host "✗ Assignation incorrecte" -ForegroundColor Red
    }
    
    if ($task.Metadata.ContainsKey("Tags") -and $task.Metadata["Tags"] -contains "important") {
        Write-Host "✓ Tags corrects" -ForegroundColor Green
    } else {
        Write-Host "✗ Tags incorrects" -ForegroundColor Red
    }
    
    if ($task.Metadata.ContainsKey("Estimate") -and $task.Metadata["Estimate"] -eq "3d") {
        Write-Host "✓ Estimation correcte" -ForegroundColor Green
    } else {
        Write-Host "✗ Estimation incorrecte" -ForegroundColor Red
    }
    
    # Test 3: Détection des dépendances
    Write-Host "`nTest 3: Détection des dépendances" -ForegroundColor Cyan
    $roadmapWithDependencies = ConvertFrom-MarkdownToRoadmapExtended -FilePath $testMarkdownPath -IncludeMetadata -DetectDependencies
    
    # Vérifier les dépendances explicites
    $task = $roadmapWithDependencies.AllTasks["PLAN-1.2"]
    if ($task.Dependencies.Count -eq 1 -and $task.Dependencies[0].Id -eq "PLAN-1.1") {
        Write-Host "✓ Dépendance explicite correcte" -ForegroundColor Green
    } else {
        Write-Host "✗ Dépendance explicite incorrecte" -ForegroundColor Red
        Write-Host "  Nombre de dépendances: $($task.Dependencies.Count)" -ForegroundColor Red
        if ($task.Dependencies.Count -gt 0) {
            Write-Host "  Première dépendance: $($task.Dependencies[0].Id)" -ForegroundColor Red
        }
    }
    
    # Vérifier les dépendances implicites
    $task = $roadmapWithDependencies.AllTasks["PLAN-1.2.2"]
    if ($task.Dependencies.Count -eq 1 -and $task.Dependencies[0].Id -eq "PLAN-1.1") {
        Write-Host "✓ Dépendance implicite correcte" -ForegroundColor Green
    } else {
        Write-Host "✗ Dépendance implicite incorrecte" -ForegroundColor Red
        Write-Host "  Nombre de dépendances: $($task.Dependencies.Count)" -ForegroundColor Red
        if ($task.Dependencies.Count -gt 0) {
            Write-Host "  Première dépendance: $($task.Dependencies[0].Id)" -ForegroundColor Red
        }
    }
    
    # Vérifier les tâches dépendantes
    $task = $roadmapWithDependencies.AllTasks["PLAN-1.1"]
    if ($task.DependentTasks.Count -eq 2) {
        Write-Host "✓ Nombre de tâches dépendantes correct" -ForegroundColor Green
    } else {
        Write-Host "✗ Nombre de tâches dépendantes incorrect" -ForegroundColor Red
        Write-Host "  Nombre: $($task.DependentTasks.Count)" -ForegroundColor Red
    }
    
    # Test 4: Validation de la structure
    Write-Host "`nTest 4: Validation de la structure" -ForegroundColor Cyan
    $roadmapWithValidation = ConvertFrom-MarkdownToRoadmapExtended -FilePath $testMarkdownPath -ValidateStructure
    
    Write-Host "Nombre de problèmes de validation: $($roadmapWithValidation.ValidationIssues.Count)" -ForegroundColor Yellow
    if ($roadmapWithValidation.ValidationIssues.Count -eq 0) {
        Write-Host "✓ Aucun problème de validation" -ForegroundColor Green
    } else {
        Write-Host "✗ Problèmes de validation détectés" -ForegroundColor Red
        foreach ($issue in $roadmapWithValidation.ValidationIssues) {
            Write-Host "  - $issue" -ForegroundColor Red
        }
    }
    
    # Créer un fichier markdown avec des problèmes
    $testMarkdownWithIssuesPath = Join-Path -Path $testDir -ChildPath "test-roadmap-issues.md"
    $testMarkdownWithIssues = @"
# Roadmap avec Problèmes

## Section 1

- [ ] **1** Tâche 1
  - [x] **1** Tâche avec ID en double
  - [ ] Tâche sans ID
    - [~] **1.2.1** Tâche avec dépendance circulaire @depends:1.2.1
"@

    $testMarkdownWithIssues | Out-File -FilePath $testMarkdownWithIssuesPath -Encoding UTF8
    
    $roadmapWithIssues = ConvertFrom-MarkdownToRoadmapExtended -FilePath $testMarkdownWithIssuesPath -IncludeMetadata -DetectDependencies -ValidateStructure
    
    Write-Host "`nValidation d'un fichier avec problèmes:" -ForegroundColor Cyan
    Write-Host "Nombre de problèmes de validation: $($roadmapWithIssues.ValidationIssues.Count)" -ForegroundColor Yellow
    if ($roadmapWithIssues.ValidationIssues.Count -gt 0) {
        Write-Host "✓ Problèmes de validation correctement détectés" -ForegroundColor Green
        foreach ($issue in $roadmapWithIssues.ValidationIssues) {
            Write-Host "  - $issue" -ForegroundColor Yellow
        }
    } else {
        Write-Host "✗ Problèmes de validation non détectés" -ForegroundColor Red
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
