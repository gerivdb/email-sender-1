# Test-RoadmapDependencies.ps1
# Script pour tester la fonction Get-RoadmapDependencies

# Importer les fonctions à tester
$extendedFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\ConvertFrom-MarkdownToRoadmapExtended.ps1"
$dependenciesFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\Get-RoadmapDependencies.ps1"

. $extendedFunctionPath
. $dependenciesFunctionPath

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

## Déploiement

- [ ] **DEPLOY-1** Préparation de l'environnement
- [ ] **DEPLOY-2** Déploiement en production @depends:TEST-2,DEPLOY-1
"@

$testMarkdown | Out-File -FilePath $testMarkdownPath -Encoding UTF8

# Créer un fichier markdown avec des cycles de dépendances
$testCyclesMarkdownPath = Join-Path -Path $testDir -ChildPath "test-cycles.md"
$testCyclesMarkdown = @"
# Roadmap avec Cycles de Dépendances

## Tâches

- [ ] **A** Tâche A @depends:C
- [ ] **B** Tâche B @depends:A
- [ ] **C** Tâche C @depends:B

## Autres Tâches

- [ ] **D** Tâche D ref:E
- [ ] **E** Tâche E ref:F
- [ ] **F** Tâche F ref:D
"@

$testCyclesMarkdown | Out-File -FilePath $testCyclesMarkdownPath -Encoding UTF8

Write-Host "Fichiers de test créés." -ForegroundColor Green

try {
    # Test 1: Détection des dépendances explicites
    Write-Host "`nTest 1: Détection des dépendances explicites" -ForegroundColor Cyan
    $roadmap = ConvertFrom-MarkdownToRoadmapExtended -FilePath $testMarkdownPath -IncludeMetadata -DetectDependencies
    $dependencies = Get-RoadmapDependencies -Roadmap $roadmap -DetectionMode "Explicit" -ValidateDependencies

    Write-Host "Nombre de dépendances explicites: $($dependencies.ExplicitDependencies.Count)" -ForegroundColor Yellow

    if ($dependencies.ExplicitDependencies.Count -gt 0) {
        Write-Host "✓ Dépendances explicites détectées" -ForegroundColor Green
        Write-Host "Dépendances explicites:" -ForegroundColor Yellow
        foreach ($dep in $dependencies.ExplicitDependencies) {
            Write-Host "  - $($dep.TaskId) dépend de $($dep.DependsOn)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "✗ Aucune dépendance explicite détectée" -ForegroundColor Red
    }

    # Test 2: Détection des dépendances implicites
    Write-Host "`nTest 2: Détection des dépendances implicites" -ForegroundColor Cyan
    $dependencies = Get-RoadmapDependencies -Roadmap $roadmap -DetectionMode "Implicit" -ValidateDependencies

    Write-Host "Nombre de dépendances implicites: $($dependencies.ImplicitDependencies.Count)" -ForegroundColor Yellow

    if ($dependencies.ImplicitDependencies.Count -gt 0) {
        Write-Host "✓ Dépendances implicites détectées" -ForegroundColor Green
        Write-Host "Dépendances implicites:" -ForegroundColor Yellow
        foreach ($dep in $dependencies.ImplicitDependencies) {
            Write-Host "  - $($dep.TaskId) dépend de $($dep.DependsOn) (Source: $($dep.Source))" -ForegroundColor Yellow
        }
    } else {
        Write-Host "✗ Aucune dépendance implicite détectée" -ForegroundColor Red
    }

    # Test 3: Détection des cycles de dépendances
    Write-Host "`nTest 3: Détection des cycles de dépendances" -ForegroundColor Cyan
    $roadmapWithCycles = ConvertFrom-MarkdownToRoadmapExtended -FilePath $testCyclesMarkdownPath -IncludeMetadata
    $dependencies = Get-RoadmapDependencies -Roadmap $roadmapWithCycles -DetectCycles -ValidateDependencies

    Write-Host "Nombre de cycles détectés: $($dependencies.Cycles.Count)" -ForegroundColor Yellow

    if ($dependencies.Cycles.Count -gt 0) {
        Write-Host "✓ Cycles de dépendances détectés" -ForegroundColor Green
        Write-Host "Cycles de dépendances:" -ForegroundColor Yellow
        foreach ($cycle in $dependencies.Cycles) {
            Write-Host "  - $($cycle.CycleString)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "✗ Aucun cycle de dépendance détecté" -ForegroundColor Red
    }

    # Test 4: Génération de visualisation
    Write-Host "`nTest 4: Génération de visualisation" -ForegroundColor Cyan
    $visualizationPath = Join-Path -Path $testDir -ChildPath "dependencies-visualization.md"
    $dependencies = Get-RoadmapDependencies -Roadmap $roadmap -GenerateVisualization -OutputPath $visualizationPath

    if (-not [string]::IsNullOrEmpty($dependencies.Visualization)) {
        Write-Host "✓ Visualisation générée" -ForegroundColor Green
        Write-Host "Visualisation écrite dans: $visualizationPath" -ForegroundColor Yellow

        if (Test-Path -Path $visualizationPath) {
            $visualizationContent = Get-Content -Path $visualizationPath -Raw
            $visualizationLines = ($visualizationContent -split "`n").Count
            Write-Host "Taille de la visualisation: $visualizationLines lignes" -ForegroundColor Yellow
        } else {
            Write-Host "✗ Fichier de visualisation non créé" -ForegroundColor Red
        }
    } else {
        Write-Host "✗ Aucune visualisation générée" -ForegroundColor Red
    }

    Write-Host "`nTous les tests sont terminés." -ForegroundColor Green
} catch {
    Write-Host "Erreur lors des tests: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
} finally {
    # Nettoyer les fichiers de test
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
        Write-Host "`nRépertoire de test nettoyé: $testDir" -ForegroundColor Gray
    }
}
