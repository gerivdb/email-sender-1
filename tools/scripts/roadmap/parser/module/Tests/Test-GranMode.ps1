<#
.SYNOPSIS
    Test d'intégration pour le script gran-mode.ps1.

.DESCRIPTION
    Ce script contient un test d'intégration pour le script gran-mode.ps1
    qui permet de décomposer une tâche de roadmap en sous-tâches plus granulaires.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

# Chemin absolu vers le script gran-mode.ps1
$granModePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\gran-mode.ps1"

# Vérifier si le fichier existe
if (-not (Test-Path -Path $granModePath)) {
    Write-Warning "Le script gran-mode.ps1 est introuvable à l'emplacement : $granModePath"
    throw "Le script gran-mode.ps1 est introuvable."
}

Write-Host "Test d'intégration pour le script gran-mode.ps1" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

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
    & $granModePath -FilePath $testFilePath -TaskIdentifier "1.3" -SubTasksFile $testSubTasksFilePath

    # Vérifier le résultat
    $content = Get-Content -Path $testFilePath -Encoding UTF8
    $hasTask = $content -join "`n" -match "- \[ \] \*\*1\.3\*\* Tâche à décomposer"
    $hasSubTask1 = $content -join "`n" -match "- \[ \] \*\*1\.3\.1\*\* Première sous-tâche d'intégration"
    $hasSubTask2 = $content -join "`n" -match "- \[ \] \*\*1\.3\.2\*\* Deuxième sous-tâche d'intégration"
    $hasSubTask3 = $content -join "`n" -match "- \[ \] \*\*1\.3\.3\*\* Troisième sous-tâche d'intégration"

    if ($hasTask -and $hasSubTask1 -and $hasSubTask2 -and $hasSubTask3) {
        Write-Host "Test réussi : Toutes les sous-tâches ont été correctement ajoutées." -ForegroundColor Green
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

Write-Host "Test d'intégration terminé." -ForegroundColor Cyan
