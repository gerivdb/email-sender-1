# Test-RoadmapToJson.ps1
# Script pour tester la fonction Export-RoadmapToJson

# Importer les fonctions à tester
$extendedFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\ConvertFrom-MarkdownToRoadmapExtended.ps1"
$jsonFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\Export-RoadmapToJson.ps1"

. $extendedFunctionPath
. $jsonFunctionPath

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Créer un fichier markdown de test
$testMarkdownPath = Join-Path -Path $testDir -ChildPath "test-roadmap.md"
$testMarkdown = @"
# Roadmap de Test

Ceci est une roadmap de test pour valider la fonction Export-RoadmapToJson.

## Section 1

- [ ] **1** Tâche 1
  - [x] **1.1** Tâche 1.1
  - [ ] **1.2** Tâche 1.2
    - [~] **1.2.1** Tâche 1.2.1 @john #important
    - [!] **1.2.2** Tâche 1.2.2 P1

## Section 2

- [ ] **2** Tâche 2
  - [ ] **2.1** Tâche 2.1 @date:2023-12-31
"@

$testMarkdown | Out-File -FilePath $testMarkdownPath -Encoding UTF8

Write-Host "Fichier de test créé: $testMarkdownPath" -ForegroundColor Green

try {
    # Convertir le markdown en roadmap
    $roadmap = ConvertFrom-MarkdownToRoadmapExtended -FilePath $testMarkdownPath -IncludeMetadata -DetectDependencies
    
    # Test 1: Export simple
    Write-Host "`nTest 1: Export simple" -ForegroundColor Cyan
    $jsonPath = Join-Path -Path $testDir -ChildPath "roadmap-simple.json"
    $json = Export-RoadmapToJson -Roadmap $roadmap -OutputPath $jsonPath
    
    if (Test-Path -Path $jsonPath) {
        $fileSize = (Get-Item -Path $jsonPath).Length
        Write-Host "✓ Fichier JSON créé: $jsonPath ($fileSize octets)" -ForegroundColor Green
    } else {
        Write-Host "✗ Fichier JSON non créé" -ForegroundColor Red
    }
    
    # Test 2: Export avec métadonnées et dépendances
    Write-Host "`nTest 2: Export avec métadonnées et dépendances" -ForegroundColor Cyan
    $jsonPath = Join-Path -Path $testDir -ChildPath "roadmap-full.json"
    $json = Export-RoadmapToJson -Roadmap $roadmap -OutputPath $jsonPath -IncludeMetadata -IncludeDependencies -PrettyPrint
    
    if (Test-Path -Path $jsonPath) {
        $fileSize = (Get-Item -Path $jsonPath).Length
        Write-Host "✓ Fichier JSON créé: $jsonPath ($fileSize octets)" -ForegroundColor Green
        
        # Vérifier le contenu du fichier
        $jsonContent = Get-Content -Path $jsonPath -Raw
        $jsonObject = $jsonContent | ConvertFrom-Json
        
        Write-Host "Titre: $($jsonObject.Title)" -ForegroundColor Yellow
        Write-Host "Nombre de sections: $($jsonObject.Sections.Count)" -ForegroundColor Yellow
        
        # Vérifier les métadonnées
        $task = $jsonObject.Sections[0].Tasks[0].SubTasks[1].SubTasks[0]
        if ($task.PSObject.Properties.Name -contains "Metadata") {
            Write-Host "✓ Métadonnées incluses" -ForegroundColor Green
            Write-Host "Métadonnées de la tâche $($task.Id): $($task.Metadata | ConvertTo-Json -Compress)" -ForegroundColor Yellow
        } else {
            Write-Host "✗ Métadonnées non incluses" -ForegroundColor Red
        }
    } else {
        Write-Host "✗ Fichier JSON non créé" -ForegroundColor Red
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
