# Test-MarkdownToRoadmapWithDependencies.ps1
# Script pour tester la fonction ConvertFrom-MarkdownToRoadmapWithDependencies

# Importer la fonction Ã  tester
$functionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\ConvertFrom-MarkdownToRoadmapWithDependencies.ps1"
. $functionPath

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
"@

$testMarkdown | Out-File -FilePath $testMarkdownPath -Encoding UTF8

Write-Host "Fichier de test crÃ©Ã©: $testMarkdownPath" -ForegroundColor Green

try {
    # Test 1: Conversion avec dÃ©tection des dÃ©pendances
    Write-Host "`nTest 1: Conversion avec dÃ©tection des dÃ©pendances" -ForegroundColor Cyan
    $roadmap = ConvertFrom-MarkdownToRoadmapWithDependencies -FilePath $testMarkdownPath -IncludeMetadata -DetectDependencies
    
    Write-Host "Titre: $($roadmap.Title)" -ForegroundColor Yellow
    Write-Host "Description: $($roadmap.Description)" -ForegroundColor Yellow
    Write-Host "Nombre de sections: $($roadmap.Sections.Count)" -ForegroundColor Yellow
    Write-Host "Nombre de tÃ¢ches: $($roadmap.AllTasks.Count)" -ForegroundColor Yellow
    
    # VÃ©rifier les dÃ©pendances
    Write-Host "`nVÃ©rification des dÃ©pendances:" -ForegroundColor Cyan
    foreach ($id in $roadmap.AllTasks.Keys) {
        $task = $roadmap.AllTasks[$id]
        $dependencies = $task.Dependencies | ForEach-Object { $_.Id }
        
        if ($dependencies.Count -gt 0) {
            Write-Host "  - $id dÃ©pend de: $($dependencies -join ', ')" -ForegroundColor Yellow
        }
    }
    
    # VÃ©rifier les tÃ¢ches dÃ©pendantes
    Write-Host "`nVÃ©rification des tÃ¢ches dÃ©pendantes:" -ForegroundColor Cyan
    foreach ($id in $roadmap.AllTasks.Keys) {
        $task = $roadmap.AllTasks[$id]
        $dependentTasks = $task.DependentTasks | ForEach-Object { $_.Id }
        
        if ($dependentTasks.Count -gt 0) {
            Write-Host "  - $id est dÃ©pendance de: $($dependentTasks -join ', ')" -ForegroundColor Yellow
        }
    }
    
    # Test 2: Validation de la structure
    Write-Host "`nTest 2: Validation de la structure" -ForegroundColor Cyan
    $roadmapWithValidation = ConvertFrom-MarkdownToRoadmapWithDependencies -FilePath $testMarkdownPath -ValidateStructure
    
    Write-Host "Nombre de problÃ¨mes de validation: $($roadmapWithValidation.ValidationIssues.Count)" -ForegroundColor Yellow
    if ($roadmapWithValidation.ValidationIssues.Count -gt 0) {
        Write-Host "ProblÃ¨mes de validation:" -ForegroundColor Yellow
        foreach ($issue in $roadmapWithValidation.ValidationIssues) {
            Write-Host "  - $issue" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Aucun problÃ¨me de validation dÃ©tectÃ©." -ForegroundColor Green
    }
    
    Write-Host "`nTest terminÃ©." -ForegroundColor Green
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
