# Test-RoadmapToJson.ps1
# Script pour tester la fonction Export-RoadmapToJson

# Importer les fonctions Ã  tester
$extendedFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\ConvertFrom-MarkdownToRoadmapExtended.ps1"
$jsonFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\Export-RoadmapToJson.ps1"

. $extendedFunctionPath
. $jsonFunctionPath

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier markdown de test
$testMarkdownPath = Join-Path -Path $testDir -ChildPath "test-roadmap.md"
$testMarkdown = @"
# Roadmap de Test

Ceci est une roadmap de test pour valider la fonction Export-RoadmapToJson.

## Section 1

- [ ] **1** TÃ¢che 1
  - [x] **1.1** TÃ¢che 1.1
  - [ ] **1.2** TÃ¢che 1.2
    - [~] **1.2.1** TÃ¢che 1.2.1 @john #important
    - [!] **1.2.2** TÃ¢che 1.2.2 P1

## Section 2

- [ ] **2** TÃ¢che 2
  - [ ] **2.1** TÃ¢che 2.1 @date:2023-12-31
"@

$testMarkdown | Out-File -FilePath $testMarkdownPath -Encoding UTF8

Write-Host "Fichier de test crÃ©Ã©: $testMarkdownPath" -ForegroundColor Green

try {
    # Convertir le markdown en roadmap
    $roadmap = ConvertFrom-MarkdownToRoadmapExtended -FilePath $testMarkdownPath -IncludeMetadata -DetectDependencies
    
    # Test 1: Export simple
    Write-Host "`nTest 1: Export simple" -ForegroundColor Cyan
    $jsonPath = Join-Path -Path $testDir -ChildPath "roadmap-simple.json"
    $json = Export-RoadmapToJson -Roadmap $roadmap -OutputPath $jsonPath
    
    if (Test-Path -Path $jsonPath) {
        $fileSize = (Get-Item -Path $jsonPath).Length
        Write-Host "âœ“ Fichier JSON crÃ©Ã©: $jsonPath ($fileSize octets)" -ForegroundColor Green
    } else {
        Write-Host "âœ— Fichier JSON non crÃ©Ã©" -ForegroundColor Red
    }
    
    # Test 2: Export avec mÃ©tadonnÃ©es et dÃ©pendances
    Write-Host "`nTest 2: Export avec mÃ©tadonnÃ©es et dÃ©pendances" -ForegroundColor Cyan
    $jsonPath = Join-Path -Path $testDir -ChildPath "roadmap-full.json"
    $json = Export-RoadmapToJson -Roadmap $roadmap -OutputPath $jsonPath -IncludeMetadata -IncludeDependencies -PrettyPrint
    
    if (Test-Path -Path $jsonPath) {
        $fileSize = (Get-Item -Path $jsonPath).Length
        Write-Host "âœ“ Fichier JSON crÃ©Ã©: $jsonPath ($fileSize octets)" -ForegroundColor Green
        
        # VÃ©rifier le contenu du fichier
        $jsonContent = Get-Content -Path $jsonPath -Raw
        $jsonObject = $jsonContent | ConvertFrom-Json
        
        Write-Host "Titre: $($jsonObject.Title)" -ForegroundColor Yellow
        Write-Host "Nombre de sections: $($jsonObject.Sections.Count)" -ForegroundColor Yellow
        
        # VÃ©rifier les mÃ©tadonnÃ©es
        $task = $jsonObject.Sections[0].Tasks[0].SubTasks[1].SubTasks[0]
        if ($task.PSObject.Properties.Name -contains "Metadata") {
            Write-Host "âœ“ MÃ©tadonnÃ©es incluses" -ForegroundColor Green
            Write-Host "MÃ©tadonnÃ©es de la tÃ¢che $($task.Id): $($task.Metadata | ConvertTo-Json -Compress)" -ForegroundColor Yellow
        } else {
            Write-Host "âœ— MÃ©tadonnÃ©es non incluses" -ForegroundColor Red
        }
    } else {
        Write-Host "âœ— Fichier JSON non crÃ©Ã©" -ForegroundColor Red
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
