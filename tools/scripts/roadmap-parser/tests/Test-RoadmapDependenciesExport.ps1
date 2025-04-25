# Test-RoadmapDependenciesExport.ps1
# Script pour tester l'export et l'import des dépendances

# Importer les fonctions à tester
$extendedFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\ConvertFrom-MarkdownToRoadmapExtended.ps1"
$exportFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\Export-RoadmapToJson.ps1"
$importFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\Import-RoadmapFromJson.ps1"

. $extendedFunctionPath
. $exportFunctionPath
. $importFunctionPath

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Créer un fichier markdown de test simple avec des dépendances explicites
$testMarkdownPath = Join-Path -Path $testDir -ChildPath "test-dependencies.md"
$testMarkdown = @"
# Test de Dépendances

## Tâches

- [ ] **A** Tâche A
- [ ] **B** Tâche B @depends:A
- [ ] **C** Tâche C @depends:B
"@

$testMarkdown | Out-File -FilePath $testMarkdownPath -Encoding UTF8

Write-Host "Fichier de test créé: $testMarkdownPath" -ForegroundColor Green

try {
    # Convertir le markdown en roadmap
    Write-Host "Conversion du markdown en roadmap..." -ForegroundColor Cyan
    $roadmap = ConvertFrom-MarkdownToRoadmapExtended -FilePath $testMarkdownPath -IncludeMetadata -DetectDependencies
    
    # Vérifier les dépendances
    Write-Host "`nVérification des dépendances dans la roadmap originale:" -ForegroundColor Cyan
    foreach ($id in $roadmap.AllTasks.Keys) {
        $task = $roadmap.AllTasks[$id]
        $dependencies = $task.Dependencies | ForEach-Object { $_.Id }
        Write-Host "  - $id dépend de: $($dependencies -join ', ')" -ForegroundColor Yellow
        
        # Vérifier les métadonnées
        if ($task.Metadata.ContainsKey("DependsOn")) {
            Write-Host "    Métadonnées DependsOn: $($task.Metadata["DependsOn"] -join ', ')" -ForegroundColor Gray
        }
    }
    
    # Exporter la roadmap en JSON
    $jsonPath = Join-Path -Path $testDir -ChildPath "dependencies.json"
    Export-RoadmapToJson -Roadmap $roadmap -OutputPath $jsonPath -IncludeMetadata -IncludeDependencies -PrettyPrint
    
    Write-Host "`nRoadmap exportée en JSON: $jsonPath" -ForegroundColor Green
    
    # Afficher le contenu du fichier JSON
    Write-Host "`nContenu du fichier JSON:" -ForegroundColor Cyan
    $jsonContent = Get-Content -Path $jsonPath -Raw
    Write-Host $jsonContent -ForegroundColor Gray
    
    # Importer la roadmap à partir du JSON
    $importedRoadmap = Import-RoadmapFromJson -FilePath $jsonPath -DetectDependencies
    
    # Vérifier les dépendances dans la roadmap importée
    Write-Host "`nVérification des dépendances dans la roadmap importée:" -ForegroundColor Cyan
    foreach ($id in $importedRoadmap.AllTasks.Keys) {
        $task = $importedRoadmap.AllTasks[$id]
        $dependencies = $task.Dependencies | ForEach-Object { $_.Id }
        Write-Host "  - $id dépend de: $($dependencies -join ', ')" -ForegroundColor Yellow
        
        # Vérifier les métadonnées
        if ($task.Metadata.ContainsKey("DependsOn")) {
            Write-Host "    Métadonnées DependsOn: $($task.Metadata["DependsOn"] -join ', ')" -ForegroundColor Gray
        }
        
        # Vérifier les propriétés temporaires
        if ($task.PSObject.Properties.Name -contains "_DependsOn") {
            Write-Host "    Propriété _DependsOn: $($task._DependsOn -join ', ')" -ForegroundColor Gray
        }
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
