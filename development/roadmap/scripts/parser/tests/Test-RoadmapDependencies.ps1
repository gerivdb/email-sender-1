# Test-RoadmapDependencies.ps1
# Script pour tester la fonction Get-RoadmapDependencies

# Importer les fonctions Ã  tester
$extendedFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\ConvertFrom-MarkdownToRoadmapExtended.ps1"
$dependenciesFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\Get-RoadmapDependencies.ps1"

. $extendedFunctionPath
. $dependenciesFunctionPath

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier markdown de test avec des dÃ©pendances
$testMarkdownPath = Join-Path -Path $testDir -ChildPath "test-dependencies.md"
$testMarkdown = @"
# Roadmap avec DÃ©pendances

Ceci est une roadmap pour tester la dÃ©tection et la gestion des dÃ©pendances.

## Planification

- [ ] **PLAN-1** Analyse des besoins
  - [x] **PLAN-1.1** Recueillir les exigences
  - [ ] **PLAN-1.2** Analyser la faisabilitÃ© @depends:PLAN-1.1
    - [~] **PLAN-1.2.1** Ã‰tude technique
    - [!] **PLAN-1.2.2** Ã‰valuation des coÃ»ts ref:PLAN-1.1

## DÃ©veloppement

- [ ] **DEV-1** ImplÃ©mentation @depends:PLAN-1
  - [ ] **DEV-1.1** DÃ©velopper le backend
  - [ ] **DEV-1.2** CrÃ©er l'interface utilisateur ref:DEV-1.1

## Tests

- [ ] **TEST-1** Tests unitaires @depends:DEV-1.1
- [ ] **TEST-2** Tests d'intÃ©gration @depends:DEV-1,TEST-1
- [ ] **TEST-3** Tests de performance @depends:TEST-2

## DÃ©ploiement

- [ ] **DEPLOY-1** PrÃ©paration de l'environnement
- [ ] **DEPLOY-2** DÃ©ploiement en production @depends:TEST-2,DEPLOY-1
"@

$testMarkdown | Out-File -FilePath $testMarkdownPath -Encoding UTF8

# CrÃ©er un fichier markdown avec des cycles de dÃ©pendances
$testCyclesMarkdownPath = Join-Path -Path $testDir -ChildPath "test-cycles.md"
$testCyclesMarkdown = @"
# Roadmap avec Cycles de DÃ©pendances

## TÃ¢ches

- [ ] **A** TÃ¢che A @depends:C
- [ ] **B** TÃ¢che B @depends:A
- [ ] **C** TÃ¢che C @depends:B

## Autres TÃ¢ches

- [ ] **D** TÃ¢che D ref:E
- [ ] **E** TÃ¢che E ref:F
- [ ] **F** TÃ¢che F ref:D
"@

$testCyclesMarkdown | Out-File -FilePath $testCyclesMarkdownPath -Encoding UTF8

Write-Host "Fichiers de test crÃ©Ã©s." -ForegroundColor Green

try {
    # Test 1: DÃ©tection des dÃ©pendances explicites
    Write-Host "`nTest 1: DÃ©tection des dÃ©pendances explicites" -ForegroundColor Cyan
    $roadmap = ConvertFrom-MarkdownToRoadmapExtended -FilePath $testMarkdownPath -IncludeMetadata -DetectDependencies
    $dependencies = Get-RoadmapDependencies -Roadmap $roadmap -DetectionMode "Explicit" -ValidateDependencies

    Write-Host "Nombre de dÃ©pendances explicites: $($dependencies.ExplicitDependencies.Count)" -ForegroundColor Yellow

    if ($dependencies.ExplicitDependencies.Count -gt 0) {
        Write-Host "âœ“ DÃ©pendances explicites dÃ©tectÃ©es" -ForegroundColor Green
        Write-Host "DÃ©pendances explicites:" -ForegroundColor Yellow
        foreach ($dep in $dependencies.ExplicitDependencies) {
            Write-Host "  - $($dep.TaskId) dÃ©pend de $($dep.DependsOn)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "âœ— Aucune dÃ©pendance explicite dÃ©tectÃ©e" -ForegroundColor Red
    }

    # Test 2: DÃ©tection des dÃ©pendances implicites
    Write-Host "`nTest 2: DÃ©tection des dÃ©pendances implicites" -ForegroundColor Cyan
    $dependencies = Get-RoadmapDependencies -Roadmap $roadmap -DetectionMode "Implicit" -ValidateDependencies

    Write-Host "Nombre de dÃ©pendances implicites: $($dependencies.ImplicitDependencies.Count)" -ForegroundColor Yellow

    if ($dependencies.ImplicitDependencies.Count -gt 0) {
        Write-Host "âœ“ DÃ©pendances implicites dÃ©tectÃ©es" -ForegroundColor Green
        Write-Host "DÃ©pendances implicites:" -ForegroundColor Yellow
        foreach ($dep in $dependencies.ImplicitDependencies) {
            Write-Host "  - $($dep.TaskId) dÃ©pend de $($dep.DependsOn) (Source: $($dep.Source))" -ForegroundColor Yellow
        }
    } else {
        Write-Host "âœ— Aucune dÃ©pendance implicite dÃ©tectÃ©e" -ForegroundColor Red
    }

    # Test 3: DÃ©tection des cycles de dÃ©pendances
    Write-Host "`nTest 3: DÃ©tection des cycles de dÃ©pendances" -ForegroundColor Cyan
    $roadmapWithCycles = ConvertFrom-MarkdownToRoadmapExtended -FilePath $testCyclesMarkdownPath -IncludeMetadata
    $dependencies = Get-RoadmapDependencies -Roadmap $roadmapWithCycles -DetectCycles -ValidateDependencies

    Write-Host "Nombre de cycles dÃ©tectÃ©s: $($dependencies.Cycles.Count)" -ForegroundColor Yellow

    if ($dependencies.Cycles.Count -gt 0) {
        Write-Host "âœ“ Cycles de dÃ©pendances dÃ©tectÃ©s" -ForegroundColor Green
        Write-Host "Cycles de dÃ©pendances:" -ForegroundColor Yellow
        foreach ($cycle in $dependencies.Cycles) {
            Write-Host "  - $($cycle.CycleString)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "âœ— Aucun cycle de dÃ©pendance dÃ©tectÃ©" -ForegroundColor Red
    }

    # Test 4: GÃ©nÃ©ration de visualisation
    Write-Host "`nTest 4: GÃ©nÃ©ration de visualisation" -ForegroundColor Cyan
    $visualizationPath = Join-Path -Path $testDir -ChildPath "dependencies-visualization.md"
    $dependencies = Get-RoadmapDependencies -Roadmap $roadmap -GenerateVisualization -OutputPath $visualizationPath

    if (-not [string]::IsNullOrEmpty($dependencies.Visualization)) {
        Write-Host "âœ“ Visualisation gÃ©nÃ©rÃ©e" -ForegroundColor Green
        Write-Host "Visualisation Ã©crite dans: $visualizationPath" -ForegroundColor Yellow

        if (Test-Path -Path $visualizationPath) {
            $visualizationContent = Get-Content -Path $visualizationPath -Raw
            $visualizationLines = ($visualizationContent -split "`n").Count
            Write-Host "Taille de la visualisation: $visualizationLines lignes" -ForegroundColor Yellow
        } else {
            Write-Host "âœ— Fichier de visualisation non crÃ©Ã©" -ForegroundColor Red
        }
    } else {
        Write-Host "âœ— Aucune visualisation gÃ©nÃ©rÃ©e" -ForegroundColor Red
    }

    Write-Host "`nTous les tests sont terminÃ©s." -ForegroundColor Green
} catch {
    Write-Host "Erreur lors des tests: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
} finally {
    # Nettoyer les fichiers de test
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
        Write-Host "`nRÃ©pertoire de test nettoyÃ©: $testDir" -ForegroundColor Gray
    }
}
