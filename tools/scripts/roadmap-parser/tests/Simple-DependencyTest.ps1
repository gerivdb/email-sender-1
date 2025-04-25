# Simple-DependencyTest.ps1
# Script simple pour tester la fonction Get-RoadmapDependencies

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

# Créer un fichier markdown de test simple
$testMarkdownPath = Join-Path -Path $testDir -ChildPath "simple-test.md"
$testMarkdown = @"
# Simple Test

## Tasks

- [ ] **A** Task A @depends:B
- [ ] **B** Task B
"@

$testMarkdown | Out-File -FilePath $testMarkdownPath -Encoding UTF8

Write-Host "Fichier de test créé: $testMarkdownPath" -ForegroundColor Green

try {
    # Convertir le markdown en roadmap
    $roadmap = ConvertFrom-MarkdownToRoadmapExtended -FilePath $testMarkdownPath -IncludeMetadata
    
    # Vérifier les métadonnées
    $taskA = $roadmap.AllTasks["A"]
    if ($taskA.Metadata.ContainsKey("DependsOn")) {
        Write-Host "Métadonnées de dépendance trouvées: $($taskA.Metadata["DependsOn"] -join ', ')" -ForegroundColor Green
    } else {
        Write-Host "Aucune métadonnée de dépendance trouvée" -ForegroundColor Red
    }
    
    # Analyser les dépendances
    $dependencies = Get-RoadmapDependencies -Roadmap $roadmap -DetectionMode "All"
    
    Write-Host "Dépendances explicites: $($dependencies.ExplicitDependencies.Count)" -ForegroundColor Yellow
    Write-Host "Dépendances implicites: $($dependencies.ImplicitDependencies.Count)" -ForegroundColor Yellow
    
    # Afficher les dépendances explicites
    foreach ($dep in $dependencies.ExplicitDependencies) {
        Write-Host "  - $($dep.TaskId) dépend de $($dep.DependsOn)" -ForegroundColor Yellow
    }
    
    Write-Host "Test terminé." -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors du test: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}
finally {
    # Nettoyer les fichiers de test
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
        Write-Host "Répertoire de test nettoyé: $testDir" -ForegroundColor Gray
    }
}
