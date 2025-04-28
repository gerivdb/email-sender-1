# Test-DependencyCycle.ps1
# Script pour tester la fonction Find-DependencyCycle

# Importer les fonctions Ã  tester
$extendedFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\ConvertFrom-MarkdownToRoadmapExtended.ps1"
$cycleFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\Find-DependencyCycle.ps1"

. $extendedFunctionPath
. $cycleFunctionPath

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier markdown de test avec des cycles de dÃ©pendances
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

Write-Host "Fichier de test crÃ©Ã©: $testCyclesMarkdownPath" -ForegroundColor Green

try {
    # Convertir le markdown en roadmap
    $roadmap = ConvertFrom-MarkdownToRoadmapExtended -FilePath $testCyclesMarkdownPath -IncludeMetadata -DetectDependencies
    
    # VÃ©rifier les dÃ©pendances
    Write-Host "VÃ©rification des dÃ©pendances..." -ForegroundColor Cyan
    foreach ($id in $roadmap.AllTasks.Keys) {
        $task = $roadmap.AllTasks[$id]
        $dependencies = $task.Dependencies | ForEach-Object { $_.Id }
        Write-Host "  - $id dÃ©pend de: $($dependencies -join ', ')" -ForegroundColor Yellow
    }
    
    # DÃ©tecter les cycles
    $visualizationPath = Join-Path -Path $testDir -ChildPath "cycles-visualization.md"
    $cycles = Find-DependencyCycle -Roadmap $roadmap -OutputPath $visualizationPath
    
    Write-Host "`nNombre de cycles dÃ©tectÃ©s: $($cycles.Cycles.Count)" -ForegroundColor Yellow
    
    if ($cycles.Cycles.Count -gt 0) {
        Write-Host "âœ“ Cycles de dÃ©pendances dÃ©tectÃ©s" -ForegroundColor Green
        Write-Host "Cycles de dÃ©pendances:" -ForegroundColor Yellow
        foreach ($cycle in $cycles.Cycles) {
            Write-Host "  - $($cycle.CycleString)" -ForegroundColor Yellow
        }
        
        if (-not [string]::IsNullOrEmpty($cycles.Visualization)) {
            Write-Host "`nVisualisation gÃ©nÃ©rÃ©e:" -ForegroundColor Cyan
            Write-Host $cycles.Visualization -ForegroundColor Gray
            
            if (Test-Path -Path $visualizationPath) {
                Write-Host "Visualisation Ã©crite dans: $visualizationPath" -ForegroundColor Green
            } else {
                Write-Host "Fichier de visualisation non crÃ©Ã©" -ForegroundColor Red
            }
        } else {
            Write-Host "`nAucune visualisation gÃ©nÃ©rÃ©e" -ForegroundColor Red
        }
    } else {
        Write-Host "âœ— Aucun cycle de dÃ©pendance dÃ©tectÃ©" -ForegroundColor Red
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
