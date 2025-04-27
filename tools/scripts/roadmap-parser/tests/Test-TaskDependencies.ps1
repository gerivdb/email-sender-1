# Test-TaskDependencies.ps1
# Script pour tester la fonction Get-TaskDependencies

# Importer la fonction Ã  tester
$functionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\Get-TaskDependencies.ps1"
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
"@

$testMarkdown | Out-File -FilePath $testMarkdownPath -Encoding UTF8

Write-Host "Fichier de test crÃ©Ã©: $testMarkdownPath" -ForegroundColor Green

try {
    # Analyser les dÃ©pendances
    $visualizationPath = Join-Path -Path $testDir -ChildPath "dependencies-visualization.md"
    $dependencies = Get-TaskDependencies -FilePath $testMarkdownPath -OutputPath $visualizationPath
    
    Write-Host "Nombre de tÃ¢ches: $($dependencies.Tasks.Count)" -ForegroundColor Yellow
    Write-Host "Nombre de dÃ©pendances: $($dependencies.Dependencies.Count)" -ForegroundColor Yellow
    
    # Afficher les dÃ©pendances
    Write-Host "`nDÃ©pendances:" -ForegroundColor Cyan
    foreach ($dependency in $dependencies.Dependencies) {
        Write-Host "  - $($dependency.TaskId) dÃ©pend de $($dependency.DependsOn) (Type: $($dependency.Type))" -ForegroundColor Yellow
    }
    
    # VÃ©rifier la visualisation
    if (-not [string]::IsNullOrEmpty($dependencies.Visualization)) {
        Write-Host "`nVisualisation gÃ©nÃ©rÃ©e:" -ForegroundColor Cyan
        Write-Host $dependencies.Visualization -ForegroundColor Gray
        
        if (Test-Path -Path $visualizationPath) {
            Write-Host "Visualisation Ã©crite dans: $visualizationPath" -ForegroundColor Green
        } else {
            Write-Host "Fichier de visualisation non crÃ©Ã©" -ForegroundColor Red
        }
    } else {
        Write-Host "`nAucune visualisation gÃ©nÃ©rÃ©e" -ForegroundColor Red
    }
    
    Write-Host "`nTest terminÃ©." -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors du test: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}
finally {
    # Nettoyer les fichiers de test
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
        Write-Host "`nRÃ©pertoire de test nettoyÃ©: $testDir" -ForegroundColor Gray
    }
}
