# Test-MarkdownToRoadmapWithDependencies.ps1
# Script pour tester la fonction ConvertFrom-MarkdownToRoadmapWithDependencies

# Importer la fonction à tester
$functionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\ConvertFrom-MarkdownToRoadmapWithDependencies.ps1"
. $functionPath

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Créer un fichier markdown de test avec des dépendances
$testMarkdownPath = Join-Path -Path $testDir -ChildPath "test-dependencies.md"
$testMarkdown = @"
# Roadmap avec Dépendances

Ceci est une roadmap pour tester la détection et la gestion des dépendances.

## Planification

- [ ] **PLAN-1** Analyse des besoins
  - [x] **PLAN-1.1** Recueillir les exigences
  - [ ] **PLAN-1.2** Analyser la faisabilité @depends:PLAN-1.1
    - [~] **PLAN-1.2.1** Étude technique
    - [!] **PLAN-1.2.2** Évaluation des coûts ref:PLAN-1.1

## Développement

- [ ] **DEV-1** Implémentation @depends:PLAN-1
  - [ ] **DEV-1.1** Développer le backend
  - [ ] **DEV-1.2** Créer l'interface utilisateur ref:DEV-1.1

## Tests

- [ ] **TEST-1** Tests unitaires @depends:DEV-1.1
- [ ] **TEST-2** Tests d'intégration @depends:DEV-1,TEST-1
- [ ] **TEST-3** Tests de performance @depends:TEST-2
"@

$testMarkdown | Out-File -FilePath $testMarkdownPath -Encoding UTF8

Write-Host "Fichier de test créé: $testMarkdownPath" -ForegroundColor Green

try {
    # Test 1: Conversion avec détection des dépendances
    Write-Host "`nTest 1: Conversion avec détection des dépendances" -ForegroundColor Cyan
    $roadmap = ConvertFrom-MarkdownToRoadmapWithDependencies -FilePath $testMarkdownPath -IncludeMetadata -DetectDependencies
    
    Write-Host "Titre: $($roadmap.Title)" -ForegroundColor Yellow
    Write-Host "Description: $($roadmap.Description)" -ForegroundColor Yellow
    Write-Host "Nombre de sections: $($roadmap.Sections.Count)" -ForegroundColor Yellow
    Write-Host "Nombre de tâches: $($roadmap.AllTasks.Count)" -ForegroundColor Yellow
    
    # Vérifier les dépendances
    Write-Host "`nVérification des dépendances:" -ForegroundColor Cyan
    foreach ($id in $roadmap.AllTasks.Keys) {
        $task = $roadmap.AllTasks[$id]
        $dependencies = $task.Dependencies | ForEach-Object { $_.Id }
        
        if ($dependencies.Count -gt 0) {
            Write-Host "  - $id dépend de: $($dependencies -join ', ')" -ForegroundColor Yellow
        }
    }
    
    # Vérifier les tâches dépendantes
    Write-Host "`nVérification des tâches dépendantes:" -ForegroundColor Cyan
    foreach ($id in $roadmap.AllTasks.Keys) {
        $task = $roadmap.AllTasks[$id]
        $dependentTasks = $task.DependentTasks | ForEach-Object { $_.Id }
        
        if ($dependentTasks.Count -gt 0) {
            Write-Host "  - $id est dépendance de: $($dependentTasks -join ', ')" -ForegroundColor Yellow
        }
    }
    
    # Test 2: Validation de la structure
    Write-Host "`nTest 2: Validation de la structure" -ForegroundColor Cyan
    $roadmapWithValidation = ConvertFrom-MarkdownToRoadmapWithDependencies -FilePath $testMarkdownPath -ValidateStructure
    
    Write-Host "Nombre de problèmes de validation: $($roadmapWithValidation.ValidationIssues.Count)" -ForegroundColor Yellow
    if ($roadmapWithValidation.ValidationIssues.Count -gt 0) {
        Write-Host "Problèmes de validation:" -ForegroundColor Yellow
        foreach ($issue in $roadmapWithValidation.ValidationIssues) {
            Write-Host "  - $issue" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Aucun problème de validation détecté." -ForegroundColor Green
    }
    
    Write-Host "`nTest terminé." -ForegroundColor Green
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
