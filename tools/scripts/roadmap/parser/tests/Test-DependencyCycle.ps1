# Test-DependencyCycle.ps1
# Script pour tester la fonction Find-DependencyCycle

# Importer les fonctions à tester
$extendedFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\ConvertFrom-MarkdownToRoadmapExtended.ps1"
$cycleFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\Find-DependencyCycle.ps1"

. $extendedFunctionPath
. $cycleFunctionPath

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Créer un fichier markdown de test avec des cycles de dépendances
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

Write-Host "Fichier de test créé: $testCyclesMarkdownPath" -ForegroundColor Green

try {
    # Convertir le markdown en roadmap
    $roadmap = ConvertFrom-MarkdownToRoadmapExtended -FilePath $testCyclesMarkdownPath -IncludeMetadata -DetectDependencies
    
    # Vérifier les dépendances
    Write-Host "Vérification des dépendances..." -ForegroundColor Cyan
    foreach ($id in $roadmap.AllTasks.Keys) {
        $task = $roadmap.AllTasks[$id]
        $dependencies = $task.Dependencies | ForEach-Object { $_.Id }
        Write-Host "  - $id dépend de: $($dependencies -join ', ')" -ForegroundColor Yellow
    }
    
    # Détecter les cycles
    $visualizationPath = Join-Path -Path $testDir -ChildPath "cycles-visualization.md"
    $cycles = Find-DependencyCycle -Roadmap $roadmap -OutputPath $visualizationPath
    
    Write-Host "`nNombre de cycles détectés: $($cycles.Cycles.Count)" -ForegroundColor Yellow
    
    if ($cycles.Cycles.Count -gt 0) {
        Write-Host "✓ Cycles de dépendances détectés" -ForegroundColor Green
        Write-Host "Cycles de dépendances:" -ForegroundColor Yellow
        foreach ($cycle in $cycles.Cycles) {
            Write-Host "  - $($cycle.CycleString)" -ForegroundColor Yellow
        }
        
        if (-not [string]::IsNullOrEmpty($cycles.Visualization)) {
            Write-Host "`nVisualisation générée:" -ForegroundColor Cyan
            Write-Host $cycles.Visualization -ForegroundColor Gray
            
            if (Test-Path -Path $visualizationPath) {
                Write-Host "Visualisation écrite dans: $visualizationPath" -ForegroundColor Green
            } else {
                Write-Host "Fichier de visualisation non créé" -ForegroundColor Red
            }
        } else {
            Write-Host "`nAucune visualisation générée" -ForegroundColor Red
        }
    } else {
        Write-Host "✗ Aucun cycle de dépendance détecté" -ForegroundColor Red
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
