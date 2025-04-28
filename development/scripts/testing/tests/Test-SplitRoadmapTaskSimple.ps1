<#
.SYNOPSIS
    Test simple pour la fonction Split-RoadmapTask.

.DESCRIPTION
    Ce script effectue un test simple pour la fonction Split-RoadmapTask
    en crÃ©ant un fichier de test et en appelant directement la fonction.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

Write-Host "Test simple pour la fonction Split-RoadmapTask" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Importer la fonction
$functionPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\roadmap-parser\module\Functions\Public\Split-RoadmapTask.ps1"
if (Test-Path -Path $functionPath) {
    . $functionPath
    Write-Host "Fonction Split-RoadmapTask importÃ©e." -ForegroundColor Green
} else {
    throw "La fonction Split-RoadmapTask est introuvable Ã  l'emplacement : $functionPath"
}

# CrÃ©er un fichier temporaire pour les tests
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"

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

Write-Host "Fichier de roadmap crÃ©Ã© : $testFilePath" -ForegroundColor Green

# DÃ©finir les sous-tÃ¢ches
$subTasks = @(
    @{ Title = "PremiÃ¨re sous-tÃ¢che"; Description = "" },
    @{ Title = "DeuxiÃ¨me sous-tÃ¢che"; Description = "" },
    @{ Title = "TroisiÃ¨me sous-tÃ¢che"; Description = "Description de la troisiÃ¨me sous-tÃ¢che" }
)

# Appeler la fonction
try {
    Write-Host "Appel de la fonction Split-RoadmapTask..." -ForegroundColor Yellow
    Split-RoadmapTask -FilePath $testFilePath -TaskIdentifier "1.3" -SubTasks $subTasks
    
    # VÃ©rifier le rÃ©sultat
    $content = Get-Content -Path $testFilePath -Encoding UTF8
    Write-Host "Contenu du fichier aprÃ¨s modification :" -ForegroundColor Yellow
    $content | ForEach-Object { Write-Host $_ }
    
    $hasTask = $content -join "`n" -match "- \[ \] \*\*1\.3\*\* TÃ¢che Ã  dÃ©composer"
    $hasSubTask1 = $content -join "`n" -match "- \[ \] \*\*1\.3\.1\*\* PremiÃ¨re sous-tÃ¢che"
    $hasSubTask2 = $content -join "`n" -match "- \[ \] \*\*1\.3\.2\*\* DeuxiÃ¨me sous-tÃ¢che"
    $hasSubTask3 = $content -join "`n" -match "- \[ \] \*\*1\.3\.3\*\* TroisiÃ¨me sous-tÃ¢che"
    
    if ($hasTask -and $hasSubTask1 -and $hasSubTask2 -and $hasSubTask3) {
        Write-Host "Test rÃ©ussi : Toutes les sous-tÃ¢ches ont Ã©tÃ© correctement ajoutÃ©es." -ForegroundColor Green
    } else {
        Write-Host "Test Ã©chouÃ© : Certaines sous-tÃ¢ches n'ont pas Ã©tÃ© correctement ajoutÃ©es." -ForegroundColor Red
    }
} catch {
    Write-Host "Erreur lors de l'appel de la fonction Split-RoadmapTask : $_" -ForegroundColor Red
} finally {
    # Supprimer le fichier de test
    if (Test-Path -Path $testFilePath) {
        Remove-Item -Path $testFilePath -Force
        Write-Host "Fichier de roadmap supprimÃ©." -ForegroundColor Gray
    }
}

Write-Host "Test simple terminÃ©." -ForegroundColor Cyan
