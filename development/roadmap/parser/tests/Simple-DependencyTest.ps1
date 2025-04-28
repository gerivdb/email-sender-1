# Simple-DependencyTest.ps1
# Script simple pour tester la fonction Get-RoadmapDependencies

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

# CrÃ©er un fichier markdown de test simple
$testMarkdownPath = Join-Path -Path $testDir -ChildPath "simple-test.md"
$testMarkdown = @"
# Simple Test

## Tasks

- [ ] **A** Task A @depends:B
- [ ] **B** Task B
"@

$testMarkdown | Out-File -FilePath $testMarkdownPath -Encoding UTF8

Write-Host "Fichier de test crÃ©Ã©: $testMarkdownPath" -ForegroundColor Green

try {
    # Convertir le markdown en roadmap
    $roadmap = ConvertFrom-MarkdownToRoadmapExtended -FilePath $testMarkdownPath -IncludeMetadata
    
    # VÃ©rifier les mÃ©tadonnÃ©es
    $taskA = $roadmap.AllTasks["A"]
    if ($taskA.Metadata.ContainsKey("DependsOn")) {
        Write-Host "MÃ©tadonnÃ©es de dÃ©pendance trouvÃ©es: $($taskA.Metadata["DependsOn"] -join ', ')" -ForegroundColor Green
    } else {
        Write-Host "Aucune mÃ©tadonnÃ©e de dÃ©pendance trouvÃ©e" -ForegroundColor Red
    }
    
    # Analyser les dÃ©pendances
    $dependencies = Get-RoadmapDependencies -Roadmap $roadmap -DetectionMode "All"
    
    Write-Host "DÃ©pendances explicites: $($dependencies.ExplicitDependencies.Count)" -ForegroundColor Yellow
    Write-Host "DÃ©pendances implicites: $($dependencies.ImplicitDependencies.Count)" -ForegroundColor Yellow
    
    # Afficher les dÃ©pendances explicites
    foreach ($dep in $dependencies.ExplicitDependencies) {
        Write-Host "  - $($dep.TaskId) dÃ©pend de $($dep.DependsOn)" -ForegroundColor Yellow
    }
    
    Write-Host "Test terminÃ©." -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors du test: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}
finally {
    # Nettoyer les fichiers de test
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
        Write-Host "RÃ©pertoire de test nettoyÃ©: $testDir" -ForegroundColor Gray
    }
}
