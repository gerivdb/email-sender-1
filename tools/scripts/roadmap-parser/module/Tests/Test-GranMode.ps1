<#
.SYNOPSIS
    Test d'intÃ©gration pour le script gran-mode.ps1.

.DESCRIPTION
    Ce script contient un test d'intÃ©gration pour le script gran-mode.ps1
    qui permet de dÃ©composer une tÃ¢che de roadmap en sous-tÃ¢ches plus granulaires.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

# Chemin absolu vers le script gran-mode.ps1
$granModePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\gran-mode.ps1"

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $granModePath)) {
    Write-Warning "Le script gran-mode.ps1 est introuvable Ã  l'emplacement : $granModePath"
    throw "Le script gran-mode.ps1 est introuvable."
}

Write-Host "Test d'intÃ©gration pour le script gran-mode.ps1" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# CrÃ©er un fichier temporaire pour les tests
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"
$testSubTasksFilePath = Join-Path -Path $env:TEMP -ChildPath "TestSubTasks_$(Get-Random).txt"

# CrÃ©er un fichier de test avec une structure de roadmap simple
@"
# Roadmap de test

## Section 1

- [ ] **1.1** TÃ¢che 1
- [ ] **1.2** TÃ¢che 2
  - [ ] **1.2.1** Sous-tÃ¢che 1
  - [ ] **1.2.2** Sous-tÃ¢che 2
- [ ] **1.3** TÃ¢che Ã  dÃ©composer

## Section 2

- [ ] **2.1** Autre tÃ¢che
"@ | Set-Content -Path $testFilePath -Encoding UTF8

# CrÃ©er un fichier de sous-tÃ¢ches
@"
PremiÃ¨re sous-tÃ¢che d'intÃ©gration
DeuxiÃ¨me sous-tÃ¢che d'intÃ©gration
TroisiÃ¨me sous-tÃ¢che d'intÃ©gration
"@ | Set-Content -Path $testSubTasksFilePath -Encoding UTF8

Write-Host "Fichier de roadmap crÃ©Ã© : $testFilePath" -ForegroundColor Green
Write-Host "Fichier de sous-tÃ¢ches crÃ©Ã© : $testSubTasksFilePath" -ForegroundColor Green

# ExÃ©cuter le script gran-mode.ps1
try {
    Write-Host "ExÃ©cution du script gran-mode.ps1..." -ForegroundColor Yellow
    & $granModePath -FilePath $testFilePath -TaskIdentifier "1.3" -SubTasksFile $testSubTasksFilePath

    # VÃ©rifier le rÃ©sultat
    $content = Get-Content -Path $testFilePath -Encoding UTF8
    $hasTask = $content -join "`n" -match "- \[ \] \*\*1\.3\*\* TÃ¢che Ã  dÃ©composer"
    $hasSubTask1 = $content -join "`n" -match "- \[ \] \*\*1\.3\.1\*\* PremiÃ¨re sous-tÃ¢che d'intÃ©gration"
    $hasSubTask2 = $content -join "`n" -match "- \[ \] \*\*1\.3\.2\*\* DeuxiÃ¨me sous-tÃ¢che d'intÃ©gration"
    $hasSubTask3 = $content -join "`n" -match "- \[ \] \*\*1\.3\.3\*\* TroisiÃ¨me sous-tÃ¢che d'intÃ©gration"

    if ($hasTask -and $hasSubTask1 -and $hasSubTask2 -and $hasSubTask3) {
        Write-Host "Test rÃ©ussi : Toutes les sous-tÃ¢ches ont Ã©tÃ© correctement ajoutÃ©es." -ForegroundColor Green
    } else {
        Write-Host "Test Ã©chouÃ© : Certaines sous-tÃ¢ches n'ont pas Ã©tÃ© correctement ajoutÃ©es." -ForegroundColor Red
        Write-Host "Contenu du fichier aprÃ¨s modification :" -ForegroundColor Yellow
        $content | ForEach-Object { Write-Host $_ }
    }
} catch {
    Write-Host "Erreur lors de l'exÃ©cution du script gran-mode.ps1 : $_" -ForegroundColor Red
} finally {
    # Supprimer les fichiers de test
    if (Test-Path -Path $testFilePath) {
        Remove-Item -Path $testFilePath -Force
        Write-Host "Fichier de roadmap supprimÃ©." -ForegroundColor Gray
    }
    if (Test-Path -Path $testSubTasksFilePath) {
        Remove-Item -Path $testSubTasksFilePath -Force
        Write-Host "Fichier de sous-tÃ¢ches supprimÃ©." -ForegroundColor Gray
    }
}

Write-Host "Test d'intÃ©gration terminÃ©." -ForegroundColor Cyan
