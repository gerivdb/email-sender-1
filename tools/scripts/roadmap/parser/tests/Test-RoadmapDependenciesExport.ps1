# Test-RoadmapDependenciesExport.ps1
# Script pour tester l'export et l'import des dÃ©pendances

# Importer les fonctions Ã  tester
$extendedFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\ConvertFrom-MarkdownToRoadmapExtended.ps1"
$exportFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\Export-RoadmapToJson.ps1"
$importFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\Import-RoadmapFromJson.ps1"

. $extendedFunctionPath
. $exportFunctionPath
. $importFunctionPath

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier markdown de test simple avec des dÃ©pendances explicites
$testMarkdownPath = Join-Path -Path $testDir -ChildPath "test-dependencies.md"
$testMarkdown = @"
# Test de DÃ©pendances

## TÃ¢ches

- [ ] **A** TÃ¢che A
- [ ] **B** TÃ¢che B @depends:A
- [ ] **C** TÃ¢che C @depends:B
"@

$testMarkdown | Out-File -FilePath $testMarkdownPath -Encoding UTF8

Write-Host "Fichier de test crÃ©Ã©: $testMarkdownPath" -ForegroundColor Green

try {
    # Convertir le markdown en roadmap
    Write-Host "Conversion du markdown en roadmap..." -ForegroundColor Cyan
    $roadmap = ConvertFrom-MarkdownToRoadmapExtended -FilePath $testMarkdownPath -IncludeMetadata -DetectDependencies
    
    # VÃ©rifier les dÃ©pendances
    Write-Host "`nVÃ©rification des dÃ©pendances dans la roadmap originale:" -ForegroundColor Cyan
    foreach ($id in $roadmap.AllTasks.Keys) {
        $task = $roadmap.AllTasks[$id]
        $dependencies = $task.Dependencies | ForEach-Object { $_.Id }
        Write-Host "  - $id dÃ©pend de: $($dependencies -join ', ')" -ForegroundColor Yellow
        
        # VÃ©rifier les mÃ©tadonnÃ©es
        if ($task.Metadata.ContainsKey("DependsOn")) {
            Write-Host "    MÃ©tadonnÃ©es DependsOn: $($task.Metadata["DependsOn"] -join ', ')" -ForegroundColor Gray
        }
    }
    
    # Exporter la roadmap en JSON
    $jsonPath = Join-Path -Path $testDir -ChildPath "dependencies.json"
    Export-RoadmapToJson -Roadmap $roadmap -OutputPath $jsonPath -IncludeMetadata -IncludeDependencies -PrettyPrint
    
    Write-Host "`nRoadmap exportÃ©e en JSON: $jsonPath" -ForegroundColor Green
    
    # Afficher le contenu du fichier JSON
    Write-Host "`nContenu du fichier JSON:" -ForegroundColor Cyan
    $jsonContent = Get-Content -Path $jsonPath -Raw
    Write-Host $jsonContent -ForegroundColor Gray
    
    # Importer la roadmap Ã  partir du JSON
    $importedRoadmap = Import-RoadmapFromJson -FilePath $jsonPath -DetectDependencies
    
    # VÃ©rifier les dÃ©pendances dans la roadmap importÃ©e
    Write-Host "`nVÃ©rification des dÃ©pendances dans la roadmap importÃ©e:" -ForegroundColor Cyan
    foreach ($id in $importedRoadmap.AllTasks.Keys) {
        $task = $importedRoadmap.AllTasks[$id]
        $dependencies = $task.Dependencies | ForEach-Object { $_.Id }
        Write-Host "  - $id dÃ©pend de: $($dependencies -join ', ')" -ForegroundColor Yellow
        
        # VÃ©rifier les mÃ©tadonnÃ©es
        if ($task.Metadata.ContainsKey("DependsOn")) {
            Write-Host "    MÃ©tadonnÃ©es DependsOn: $($task.Metadata["DependsOn"] -join ', ')" -ForegroundColor Gray
        }
        
        # VÃ©rifier les propriÃ©tÃ©s temporaires
        if ($task.PSObject.Properties.Name -contains "_DependsOn") {
            Write-Host "    PropriÃ©tÃ© _DependsOn: $($task._DependsOn -join ', ')" -ForegroundColor Gray
        }
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
