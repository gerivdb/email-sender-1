# Test-EditRoadmapTask.ps1
# Script pour tester la fonction Edit-RoadmapTask

# Importer les fonctions Ã  tester
$dependenciesFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\ConvertFrom-MarkdownToRoadmapWithDependencies.ps1"
$editFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\Edit-RoadmapTask.ps1"

. $dependenciesFunctionPath
. $editFunctionPath

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier markdown de test
$testMarkdownPath = Join-Path -Path $testDir -ChildPath "test-edit.md"
$testMarkdown = @"
# Roadmap de Test

Ceci est une roadmap de test pour valider la fonction Edit-RoadmapTask.

## Section 1

- [ ] **1** TÃ¢che 1
  - [x] **1.1** TÃ¢che 1.1
  - [ ] **1.2** TÃ¢che 1.2 @depends:1.1
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
    $roadmap = ConvertFrom-MarkdownToRoadmapWithDependencies -FilePath $testMarkdownPath -IncludeMetadata -DetectDependencies

    # Test 1: Modifier le titre d'une tÃ¢che
    Write-Host "`nTest 1: Modifier le titre d'une tÃ¢che" -ForegroundColor Cyan
    $originalTitle = $roadmap.AllTasks["1.1"].Title
    Edit-RoadmapTask -Roadmap $roadmap -TaskId "1.1" -Title "Titre modifiÃ©"

    if ($roadmap.AllTasks["1.1"].Title -eq "Titre modifiÃ©") {
        Write-Host "âœ“ Titre correctement modifiÃ©" -ForegroundColor Green
        Write-Host "  Ancien titre: $originalTitle" -ForegroundColor Yellow
        Write-Host "  Nouveau titre: $($roadmap.AllTasks["1.1"].Title)" -ForegroundColor Yellow
    } else {
        Write-Host "âœ— Titre non modifiÃ©" -ForegroundColor Red
    }

    # Test 2: Modifier le statut d'une tÃ¢che
    Write-Host "`nTest 2: Modifier le statut d'une tÃ¢che" -ForegroundColor Cyan
    $originalStatus = $roadmap.AllTasks["1.2"].Status
    Edit-RoadmapTask -Roadmap $roadmap -TaskId "1.2" -Status "Complete"

    if ($roadmap.AllTasks["1.2"].Status -eq "Complete") {
        Write-Host "âœ“ Statut correctement modifiÃ©" -ForegroundColor Green
        Write-Host "  Ancien statut: $originalStatus" -ForegroundColor Yellow
        Write-Host "  Nouveau statut: $($roadmap.AllTasks["1.2"].Status)" -ForegroundColor Yellow
    } else {
        Write-Host "âœ— Statut non modifiÃ©" -ForegroundColor Red
    }

    # Test 3: Modifier les mÃ©tadonnÃ©es d'une tÃ¢che
    Write-Host "`nTest 3: Modifier les mÃ©tadonnÃ©es d'une tÃ¢che" -ForegroundColor Cyan
    $metadata = @{
        "Priority" = "P2"
        "Assignee" = "sarah"
    }
    Edit-RoadmapTask -Roadmap $roadmap -TaskId "1.2.1" -Metadata $metadata

    if ($roadmap.AllTasks["1.2.1"].Metadata["Priority"] -eq "P2" -and $roadmap.AllTasks["1.2.1"].Metadata["Assignee"] -eq "sarah") {
        Write-Host "âœ“ MÃ©tadonnÃ©es correctement modifiÃ©es" -ForegroundColor Green
        Write-Host "  MÃ©tadonnÃ©es: $($roadmap.AllTasks["1.2.1"].Metadata | ConvertTo-Json -Compress)" -ForegroundColor Yellow
    } else {
        Write-Host "âœ— MÃ©tadonnÃ©es non modifiÃ©es" -ForegroundColor Red
    }

    # Test 4: Ajouter une dÃ©pendance
    Write-Host "`nTest 4: Ajouter une dÃ©pendance" -ForegroundColor Cyan
    $originalDependenciesCount = $roadmap.AllTasks["2"].Dependencies.Count
    Edit-RoadmapTask -Roadmap $roadmap -TaskId "2" -AddDependency "1"

    if ($roadmap.AllTasks["2"].Dependencies.Count -gt $originalDependenciesCount) {
        Write-Host "âœ“ DÃ©pendance correctement ajoutÃ©e" -ForegroundColor Green
        Write-Host "  Nombre de dÃ©pendances avant: $originalDependenciesCount" -ForegroundColor Yellow
        Write-Host "  Nombre de dÃ©pendances aprÃ¨s: $($roadmap.AllTasks["2"].Dependencies.Count)" -ForegroundColor Yellow

        # VÃ©rifier que la tÃ¢che 1 a bien la tÃ¢che 2 comme tÃ¢che dÃ©pendante
        $dependentTasks = $roadmap.AllTasks["1"].DependentTasks | ForEach-Object { $_.Id }
        if ($dependentTasks -contains "2") {
            Write-Host "âœ“ TÃ¢che dÃ©pendante correctement ajoutÃ©e" -ForegroundColor Green
        } else {
            Write-Host "âœ— TÃ¢che dÃ©pendante non ajoutÃ©e" -ForegroundColor Red
        }
    } else {
        Write-Host "âœ— DÃ©pendance non ajoutÃ©e" -ForegroundColor Red
    }

    # Test 5: Supprimer une dÃ©pendance
    Write-Host "`nTest 5: Supprimer une dÃ©pendance" -ForegroundColor Cyan

    # VÃ©rifier les dÃ©pendances avant
    Write-Host "DÃ©pendances de la tÃ¢che 1.2 avant:" -ForegroundColor Yellow
    foreach ($dep in $roadmap.AllTasks["1.2"].Dependencies) {
        Write-Host "  - $($dep.Id)" -ForegroundColor Yellow
    }

    # VÃ©rifier les tÃ¢ches dÃ©pendantes avant
    Write-Host "TÃ¢ches dÃ©pendantes de 1 avant:" -ForegroundColor Yellow
    foreach ($depTask in $roadmap.AllTasks["1"].DependentTasks) {
        Write-Host "  - $($depTask.Id)" -ForegroundColor Yellow
    }

    $originalDependenciesCount = $roadmap.AllTasks["1.2"].Dependencies.Count
    Edit-RoadmapTask -Roadmap $roadmap -TaskId "1.2" -RemoveDependency "1"

    # VÃ©rifier les dÃ©pendances aprÃ¨s
    Write-Host "DÃ©pendances de la tÃ¢che 1.2 aprÃ¨s:" -ForegroundColor Yellow
    foreach ($dep in $roadmap.AllTasks["1.2"].Dependencies) {
        Write-Host "  - $($dep.Id)" -ForegroundColor Yellow
    }

    # VÃ©rifier les tÃ¢ches dÃ©pendantes aprÃ¨s
    Write-Host "TÃ¢ches dÃ©pendantes de 1 aprÃ¨s:" -ForegroundColor Yellow
    foreach ($depTask in $roadmap.AllTasks["1"].DependentTasks) {
        Write-Host "  - $($depTask.Id)" -ForegroundColor Yellow
    }

    if ($roadmap.AllTasks["1.2"].Dependencies.Count -lt $originalDependenciesCount) {
        Write-Host "âœ“ DÃ©pendance correctement supprimÃ©e" -ForegroundColor Green
        Write-Host "  Nombre de dÃ©pendances avant: $originalDependenciesCount" -ForegroundColor Yellow
        Write-Host "  Nombre de dÃ©pendances aprÃ¨s: $($roadmap.AllTasks["1.2"].Dependencies.Count)" -ForegroundColor Yellow

        # VÃ©rifier que la tÃ¢che 1 n'a plus la tÃ¢che 1.2 comme tÃ¢che dÃ©pendante
        $dependentTasks = $roadmap.AllTasks["1"].DependentTasks | ForEach-Object { $_.Id }
        if ($dependentTasks -notcontains "1.2") {
            Write-Host "âœ“ TÃ¢che dÃ©pendante correctement supprimÃ©e" -ForegroundColor Green
        } else {
            Write-Host "âœ— TÃ¢che dÃ©pendante non supprimÃ©e" -ForegroundColor Red
        }
    } else {
        Write-Host "âœ— DÃ©pendance non supprimÃ©e" -ForegroundColor Red
    }

    # Test 6: Tester l'option PassThru
    Write-Host "`nTest 6: Tester l'option PassThru" -ForegroundColor Cyan
    $result = Edit-RoadmapTask -Roadmap $roadmap -TaskId "2.1" -Title "Titre avec PassThru" -PassThru

    if ($null -ne $result -and $result.AllTasks["2.1"].Title -eq "Titre avec PassThru") {
        Write-Host "âœ“ Option PassThru fonctionne correctement" -ForegroundColor Green
    } else {
        Write-Host "âœ— Option PassThru ne fonctionne pas correctement" -ForegroundColor Red
    }

    Write-Host "`nTous les tests sont terminÃ©s." -ForegroundColor Green
} catch {
    Write-Host "Erreur lors des tests: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
} finally {
    # Nettoyer les fichiers de test
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
        Write-Host "`nRÃ©pertoire de test nettoyÃ©: $testDir" -ForegroundColor Gray
    }
}
