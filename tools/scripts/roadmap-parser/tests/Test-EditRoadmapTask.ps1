# Test-EditRoadmapTask.ps1
# Script pour tester la fonction Edit-RoadmapTask

# Importer les fonctions à tester
$dependenciesFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\ConvertFrom-MarkdownToRoadmapWithDependencies.ps1"
$editFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\Edit-RoadmapTask.ps1"

. $dependenciesFunctionPath
. $editFunctionPath

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Créer un fichier markdown de test
$testMarkdownPath = Join-Path -Path $testDir -ChildPath "test-edit.md"
$testMarkdown = @"
# Roadmap de Test

Ceci est une roadmap de test pour valider la fonction Edit-RoadmapTask.

## Section 1

- [ ] **1** Tâche 1
  - [x] **1.1** Tâche 1.1
  - [ ] **1.2** Tâche 1.2 @depends:1.1
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
    $roadmap = ConvertFrom-MarkdownToRoadmapWithDependencies -FilePath $testMarkdownPath -IncludeMetadata -DetectDependencies

    # Test 1: Modifier le titre d'une tâche
    Write-Host "`nTest 1: Modifier le titre d'une tâche" -ForegroundColor Cyan
    $originalTitle = $roadmap.AllTasks["1.1"].Title
    Edit-RoadmapTask -Roadmap $roadmap -TaskId "1.1" -Title "Titre modifié"

    if ($roadmap.AllTasks["1.1"].Title -eq "Titre modifié") {
        Write-Host "✓ Titre correctement modifié" -ForegroundColor Green
        Write-Host "  Ancien titre: $originalTitle" -ForegroundColor Yellow
        Write-Host "  Nouveau titre: $($roadmap.AllTasks["1.1"].Title)" -ForegroundColor Yellow
    } else {
        Write-Host "✗ Titre non modifié" -ForegroundColor Red
    }

    # Test 2: Modifier le statut d'une tâche
    Write-Host "`nTest 2: Modifier le statut d'une tâche" -ForegroundColor Cyan
    $originalStatus = $roadmap.AllTasks["1.2"].Status
    Edit-RoadmapTask -Roadmap $roadmap -TaskId "1.2" -Status "Complete"

    if ($roadmap.AllTasks["1.2"].Status -eq "Complete") {
        Write-Host "✓ Statut correctement modifié" -ForegroundColor Green
        Write-Host "  Ancien statut: $originalStatus" -ForegroundColor Yellow
        Write-Host "  Nouveau statut: $($roadmap.AllTasks["1.2"].Status)" -ForegroundColor Yellow
    } else {
        Write-Host "✗ Statut non modifié" -ForegroundColor Red
    }

    # Test 3: Modifier les métadonnées d'une tâche
    Write-Host "`nTest 3: Modifier les métadonnées d'une tâche" -ForegroundColor Cyan
    $metadata = @{
        "Priority" = "P2"
        "Assignee" = "sarah"
    }
    Edit-RoadmapTask -Roadmap $roadmap -TaskId "1.2.1" -Metadata $metadata

    if ($roadmap.AllTasks["1.2.1"].Metadata["Priority"] -eq "P2" -and $roadmap.AllTasks["1.2.1"].Metadata["Assignee"] -eq "sarah") {
        Write-Host "✓ Métadonnées correctement modifiées" -ForegroundColor Green
        Write-Host "  Métadonnées: $($roadmap.AllTasks["1.2.1"].Metadata | ConvertTo-Json -Compress)" -ForegroundColor Yellow
    } else {
        Write-Host "✗ Métadonnées non modifiées" -ForegroundColor Red
    }

    # Test 4: Ajouter une dépendance
    Write-Host "`nTest 4: Ajouter une dépendance" -ForegroundColor Cyan
    $originalDependenciesCount = $roadmap.AllTasks["2"].Dependencies.Count
    Edit-RoadmapTask -Roadmap $roadmap -TaskId "2" -AddDependency "1"

    if ($roadmap.AllTasks["2"].Dependencies.Count -gt $originalDependenciesCount) {
        Write-Host "✓ Dépendance correctement ajoutée" -ForegroundColor Green
        Write-Host "  Nombre de dépendances avant: $originalDependenciesCount" -ForegroundColor Yellow
        Write-Host "  Nombre de dépendances après: $($roadmap.AllTasks["2"].Dependencies.Count)" -ForegroundColor Yellow

        # Vérifier que la tâche 1 a bien la tâche 2 comme tâche dépendante
        $dependentTasks = $roadmap.AllTasks["1"].DependentTasks | ForEach-Object { $_.Id }
        if ($dependentTasks -contains "2") {
            Write-Host "✓ Tâche dépendante correctement ajoutée" -ForegroundColor Green
        } else {
            Write-Host "✗ Tâche dépendante non ajoutée" -ForegroundColor Red
        }
    } else {
        Write-Host "✗ Dépendance non ajoutée" -ForegroundColor Red
    }

    # Test 5: Supprimer une dépendance
    Write-Host "`nTest 5: Supprimer une dépendance" -ForegroundColor Cyan

    # Vérifier les dépendances avant
    Write-Host "Dépendances de la tâche 1.2 avant:" -ForegroundColor Yellow
    foreach ($dep in $roadmap.AllTasks["1.2"].Dependencies) {
        Write-Host "  - $($dep.Id)" -ForegroundColor Yellow
    }

    # Vérifier les tâches dépendantes avant
    Write-Host "Tâches dépendantes de 1 avant:" -ForegroundColor Yellow
    foreach ($depTask in $roadmap.AllTasks["1"].DependentTasks) {
        Write-Host "  - $($depTask.Id)" -ForegroundColor Yellow
    }

    $originalDependenciesCount = $roadmap.AllTasks["1.2"].Dependencies.Count
    Edit-RoadmapTask -Roadmap $roadmap -TaskId "1.2" -RemoveDependency "1"

    # Vérifier les dépendances après
    Write-Host "Dépendances de la tâche 1.2 après:" -ForegroundColor Yellow
    foreach ($dep in $roadmap.AllTasks["1.2"].Dependencies) {
        Write-Host "  - $($dep.Id)" -ForegroundColor Yellow
    }

    # Vérifier les tâches dépendantes après
    Write-Host "Tâches dépendantes de 1 après:" -ForegroundColor Yellow
    foreach ($depTask in $roadmap.AllTasks["1"].DependentTasks) {
        Write-Host "  - $($depTask.Id)" -ForegroundColor Yellow
    }

    if ($roadmap.AllTasks["1.2"].Dependencies.Count -lt $originalDependenciesCount) {
        Write-Host "✓ Dépendance correctement supprimée" -ForegroundColor Green
        Write-Host "  Nombre de dépendances avant: $originalDependenciesCount" -ForegroundColor Yellow
        Write-Host "  Nombre de dépendances après: $($roadmap.AllTasks["1.2"].Dependencies.Count)" -ForegroundColor Yellow

        # Vérifier que la tâche 1 n'a plus la tâche 1.2 comme tâche dépendante
        $dependentTasks = $roadmap.AllTasks["1"].DependentTasks | ForEach-Object { $_.Id }
        if ($dependentTasks -notcontains "1.2") {
            Write-Host "✓ Tâche dépendante correctement supprimée" -ForegroundColor Green
        } else {
            Write-Host "✗ Tâche dépendante non supprimée" -ForegroundColor Red
        }
    } else {
        Write-Host "✗ Dépendance non supprimée" -ForegroundColor Red
    }

    # Test 6: Tester l'option PassThru
    Write-Host "`nTest 6: Tester l'option PassThru" -ForegroundColor Cyan
    $result = Edit-RoadmapTask -Roadmap $roadmap -TaskId "2.1" -Title "Titre avec PassThru" -PassThru

    if ($null -ne $result -and $result.AllTasks["2.1"].Title -eq "Titre avec PassThru") {
        Write-Host "✓ Option PassThru fonctionne correctement" -ForegroundColor Green
    } else {
        Write-Host "✗ Option PassThru ne fonctionne pas correctement" -ForegroundColor Red
    }

    Write-Host "`nTous les tests sont terminés." -ForegroundColor Green
} catch {
    Write-Host "Erreur lors des tests: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
} finally {
    # Nettoyer les fichiers de test
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
        Write-Host "`nRépertoire de test nettoyé: $testDir" -ForegroundColor Gray
    }
}
