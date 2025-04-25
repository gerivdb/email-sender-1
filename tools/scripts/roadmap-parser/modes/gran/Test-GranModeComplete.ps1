<#
.SYNOPSIS
    Test complet pour le mode GRAN.

.DESCRIPTION
    Ce script effectue un test complet pour le mode GRAN en créant les fichiers nécessaires
    et en exécutant le script gran-mode.ps1.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

Write-Host "Test complet pour le mode GRAN" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

# Créer les répertoires nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path $scriptPath -ChildPath "roadmap-parser\module\Functions\Public"

if (-not (Test-Path -Path $modulePath)) {
    New-Item -Path $modulePath -ItemType Directory -Force | Out-Null
    Write-Host "Répertoire créé : $modulePath" -ForegroundColor Green
}

# Copier les fichiers de fonction
$sourceFiles = @(
    (Join-Path -Path $scriptPath -ChildPath "..\scripts\roadmap-parser\module\Functions\Public\Split-RoadmapTask.ps1"),
    (Join-Path -Path $scriptPath -ChildPath "..\scripts\roadmap-parser\module\Functions\Public\Invoke-RoadmapGranularization.ps1")
)

$destinationFiles = @(
    (Join-Path -Path $modulePath -ChildPath "Split-RoadmapTask.ps1"),
    (Join-Path -Path $modulePath -ChildPath "Invoke-RoadmapGranularization.ps1")
)

for ($i = 0; $i -lt $sourceFiles.Count; $i++) {
    if (Test-Path -Path $sourceFiles[$i]) {
        Copy-Item -Path $sourceFiles[$i] -Destination $destinationFiles[$i] -Force
        Write-Host "Fichier copié : $($sourceFiles[$i]) -> $($destinationFiles[$i])" -ForegroundColor Green
    } else {
        Write-Host "Fichier source introuvable : $($sourceFiles[$i])" -ForegroundColor Red
    }
}

# Créer un fichier temporaire pour les tests
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"
$testSubTasksFilePath = Join-Path -Path $env:TEMP -ChildPath "TestSubTasks_$(Get-Random).txt"

# Créer un fichier de test avec une structure de roadmap simple
@"
# Roadmap de test

## Section 1

- [ ] **1.1** Tâche 1
- [ ] **1.2** Tâche 2
  - [ ] **1.2.1** Sous-tâche 1
  - [ ] **1.2.2** Sous-tâche 2
- [ ] **1.3** Tâche à décomposer

## Section 2

- [ ] **2.1** Autre tâche
"@ | Set-Content -Path $testFilePath -Encoding UTF8

# Créer un fichier de sous-tâches
@"
Première sous-tâche d'intégration
Deuxième sous-tâche d'intégration
Troisième sous-tâche d'intégration
"@ | Set-Content -Path $testSubTasksFilePath -Encoding UTF8

Write-Host "Fichier de roadmap créé : $testFilePath" -ForegroundColor Green
Write-Host "Fichier de sous-tâches créé : $testSubTasksFilePath" -ForegroundColor Green

# Exécuter le script gran-mode.ps1
try {
    Write-Host "Exécution du script gran-mode.ps1..." -ForegroundColor Yellow
    $granModePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\gran-mode.ps1"
    Write-Host "Chemin du script gran-mode.ps1 : $granModePath" -ForegroundColor Yellow
    & $granModePath -FilePath $testFilePath -TaskIdentifier "1.3" -SubTasksFile $testSubTasksFilePath

    # Vérifier le résultat
    $content = Get-Content -Path $testFilePath -Encoding UTF8
    $hasTask = $content -join "`n" -match "- \[ \] \*\*1\.3\*\* Tâche à décomposer"
    $hasSubTask1 = $content -join "`n" -match "- \[ \] \*\*1\.3\.1\*\* Première sous-tâche d'intégration"
    $hasSubTask2 = $content -join "`n" -match "- \[ \] \*\*1\.3\.2\*\* Deuxième sous-tâche d'intégration"
    $hasSubTask3 = $content -join "`n" -match "- \[ \] \*\*1\.3\.3\*\* Troisième sous-tâche d'intégration"

    if ($hasTask -and $hasSubTask1 -and $hasSubTask2 -and $hasSubTask3) {
        Write-Host "Test réussi : Toutes les sous-tâches ont été correctement ajoutées." -ForegroundColor Green
        Write-Host "Contenu du fichier après modification :" -ForegroundColor Yellow
        $content | ForEach-Object { Write-Host $_ }
    } else {
        Write-Host "Test échoué : Certaines sous-tâches n'ont pas été correctement ajoutées." -ForegroundColor Red
        Write-Host "Contenu du fichier après modification :" -ForegroundColor Yellow
        $content | ForEach-Object { Write-Host $_ }
    }
} catch {
    Write-Host "Erreur lors de l'exécution du script gran-mode.ps1 : $_" -ForegroundColor Red
} finally {
    # Supprimer les fichiers de test
    if (Test-Path -Path $testFilePath) {
        Remove-Item -Path $testFilePath -Force
        Write-Host "Fichier de roadmap supprimé." -ForegroundColor Gray
    }
    if (Test-Path -Path $testSubTasksFilePath) {
        Remove-Item -Path $testSubTasksFilePath -Force
        Write-Host "Fichier de sous-tâches supprimé." -ForegroundColor Gray
    }
}

Write-Host "Test complet terminé." -ForegroundColor Cyan
