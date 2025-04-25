<#
.SYNOPSIS
    Test simple pour la fonction Invoke-RoadmapGranularization.

.DESCRIPTION
    Ce script effectue un test simple pour la fonction Invoke-RoadmapGranularization
    en créant un fichier de test et en appelant directement la fonction.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

Write-Host "Test simple pour la fonction Invoke-RoadmapGranularization" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

# Importer les fonctions
$splitTaskPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\roadmap-parser\module\Functions\Public\Split-RoadmapTask.ps1"
$invokeGranPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\roadmap-parser\module\Functions\Public\Invoke-RoadmapGranularization.ps1"

if (Test-Path -Path $splitTaskPath) {
    . $splitTaskPath
    Write-Host "Fonction Split-RoadmapTask importée." -ForegroundColor Green
} else {
    throw "La fonction Split-RoadmapTask est introuvable à l'emplacement : $splitTaskPath"
}

if (Test-Path -Path $invokeGranPath) {
    . $invokeGranPath
    Write-Host "Fonction Invoke-RoadmapGranularization importée." -ForegroundColor Green
} else {
    throw "La fonction Invoke-RoadmapGranularization est introuvable à l'emplacement : $invokeGranPath"
}

# Créer un fichier temporaire pour les tests
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"

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

Write-Host "Fichier de roadmap créé : $testFilePath" -ForegroundColor Green

# Définir les sous-tâches
$subTasksInput = @"
Première sous-tâche
Deuxième sous-tâche
Troisième sous-tâche avec description
"@

# Appeler la fonction
try {
    Write-Host "Appel de la fonction Invoke-RoadmapGranularization..." -ForegroundColor Yellow
    Invoke-RoadmapGranularization -FilePath $testFilePath -TaskIdentifier "1.3" -SubTasksInput $subTasksInput
    
    # Vérifier le résultat
    $content = Get-Content -Path $testFilePath -Encoding UTF8
    Write-Host "Contenu du fichier après modification :" -ForegroundColor Yellow
    $content | ForEach-Object { Write-Host $_ }
    
    $hasTask = $content -join "`n" -match "- \[ \] \*\*1\.3\*\* Tâche à décomposer"
    $hasSubTask1 = $content -join "`n" -match "- \[ \] \*\*1\.3\.1\*\* Première sous-tâche"
    $hasSubTask2 = $content -join "`n" -match "- \[ \] \*\*1\.3\.2\*\* Deuxième sous-tâche"
    $hasSubTask3 = $content -join "`n" -match "- \[ \] \*\*1\.3\.3\*\* Troisième sous-tâche avec description"
    
    if ($hasTask -and $hasSubTask1 -and $hasSubTask2 -and $hasSubTask3) {
        Write-Host "Test réussi : Toutes les sous-tâches ont été correctement ajoutées." -ForegroundColor Green
    } else {
        Write-Host "Test échoué : Certaines sous-tâches n'ont pas été correctement ajoutées." -ForegroundColor Red
    }
} catch {
    Write-Host "Erreur lors de l'appel de la fonction Invoke-RoadmapGranularization : $_" -ForegroundColor Red
} finally {
    # Supprimer le fichier de test
    if (Test-Path -Path $testFilePath) {
        Remove-Item -Path $testFilePath -Force
        Write-Host "Fichier de roadmap supprimé." -ForegroundColor Gray
    }
}

Write-Host "Test simple terminé." -ForegroundColor Cyan
