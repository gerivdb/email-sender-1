# Test-TaskDependencies.ps1
# Script pour tester la fonction Get-TaskDependencies

# Importer la fonction à tester
$functionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\Get-TaskDependencies.ps1"
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
"@

$testMarkdown | Out-File -FilePath $testMarkdownPath -Encoding UTF8

Write-Host "Fichier de test créé: $testMarkdownPath" -ForegroundColor Green

try {
    # Analyser les dépendances
    $visualizationPath = Join-Path -Path $testDir -ChildPath "dependencies-visualization.md"
    $dependencies = Get-TaskDependencies -FilePath $testMarkdownPath -OutputPath $visualizationPath
    
    Write-Host "Nombre de tâches: $($dependencies.Tasks.Count)" -ForegroundColor Yellow
    Write-Host "Nombre de dépendances: $($dependencies.Dependencies.Count)" -ForegroundColor Yellow
    
    # Afficher les dépendances
    Write-Host "`nDépendances:" -ForegroundColor Cyan
    foreach ($dependency in $dependencies.Dependencies) {
        Write-Host "  - $($dependency.TaskId) dépend de $($dependency.DependsOn) (Type: $($dependency.Type))" -ForegroundColor Yellow
    }
    
    # Vérifier la visualisation
    if (-not [string]::IsNullOrEmpty($dependencies.Visualization)) {
        Write-Host "`nVisualisation générée:" -ForegroundColor Cyan
        Write-Host $dependencies.Visualization -ForegroundColor Gray
        
        if (Test-Path -Path $visualizationPath) {
            Write-Host "Visualisation écrite dans: $visualizationPath" -ForegroundColor Green
        } else {
            Write-Host "Fichier de visualisation non créé" -ForegroundColor Red
        }
    } else {
        Write-Host "`nAucune visualisation générée" -ForegroundColor Red
    }
    
    Write-Host "`nTest terminé." -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors du test: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}
finally {
    # Nettoyer les fichiers de test
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
        Write-Host "`nRépertoire de test nettoyé: $testDir" -ForegroundColor Gray
    }
}
