<#
.SYNOPSIS
    Test complet pour le mode GRAN.

.DESCRIPTION
    Ce script effectue un test complet pour le mode GRAN en crÃƒÂ©ant les fichiers nÃƒÂ©cessaires
    et en exÃƒÂ©cutant le script gran-mode.ps1.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃƒÂ©ation: 2023-08-15
#>

Write-Host "Test complet pour le mode GRAN" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

# CrÃƒÂ©er les rÃƒÂ©pertoires nÃƒÂ©cessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path $scriptPath -ChildPath "roadmap-parser\module\Functions\Public"

if (-not (Test-Path -Path $modulePath)) {
    New-Item -Path $modulePath -ItemType Directory -Force | Out-Null
    Write-Host "RÃƒÂ©pertoire crÃƒÂ©ÃƒÂ© : $modulePath" -ForegroundColor Green
}

# Copier les fichiers de fonction
$sourceFiles = @(
    (Join-Path -Path $scriptPath -ChildPath "..\development\scripts\roadmap-parser\module\Functions\Public\Split-RoadmapTask.ps1"),
    (Join-Path -Path $scriptPath -ChildPath "..\development\scripts\roadmap-parser\module\Functions\Public\Invoke-RoadmapGranularization.ps1")
)

$destinationFiles = @(
    (Join-Path -Path $modulePath -ChildPath "Split-RoadmapTask.ps1"),
    (Join-Path -Path $modulePath -ChildPath "Invoke-RoadmapGranularization.ps1")
)

for ($i = 0; $i -lt $sourceFiles.Count; $i++) {
    if (Test-Path -Path $sourceFiles[$i]) {
        Copy-Item -Path $sourceFiles[$i] -Destination $destinationFiles[$i] -Force
        Write-Host "Fichier copiÃƒÂ© : $($sourceFiles[$i]) -> $($destinationFiles[$i])" -ForegroundColor Green
    } else {
        Write-Host "Fichier source introuvable : $($sourceFiles[$i])" -ForegroundColor Red
    }
}

# CrÃƒÂ©er un fichier temporaire pour les tests
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"
$testSubTasksFilePath = Join-Path -Path $env:TEMP -ChildPath "TestSubTasks_$(Get-Random).txt"

# CrÃƒÂ©er un fichier de test avec une structure de roadmap simple
@"
# Roadmap de test

## Section 1

- [ ] **1.1** TÃƒÂ¢che 1
- [ ] **1.2** TÃƒÂ¢che 2
  - [ ] **1.2.1** Sous-tÃƒÂ¢che 1
  - [ ] **1.2.2** Sous-tÃƒÂ¢che 2
- [ ] **1.3** TÃƒÂ¢che ÃƒÂ  dÃƒÂ©composer

## Section 2

- [ ] **2.1** Autre tÃƒÂ¢che
"@ | Set-Content -Path $testFilePath -Encoding UTF8

# CrÃƒÂ©er un fichier de sous-tÃƒÂ¢ches
@"
PremiÃƒÂ¨re sous-tÃƒÂ¢che d'intÃƒÂ©gration
DeuxiÃƒÂ¨me sous-tÃƒÂ¢che d'intÃƒÂ©gration
TroisiÃƒÂ¨me sous-tÃƒÂ¢che d'intÃƒÂ©gration
"@ | Set-Content -Path $testSubTasksFilePath -Encoding UTF8

Write-Host "Fichier de roadmap crÃƒÂ©ÃƒÂ© : $testFilePath" -ForegroundColor Green
Write-Host "Fichier de sous-tÃƒÂ¢ches crÃƒÂ©ÃƒÂ© : $testSubTasksFilePath" -ForegroundColor Green

# ExÃƒÂ©cuter le script gran-mode.ps1
try {
    Write-Host "ExÃƒÂ©cution du script gran-mode.ps1..." -ForegroundColor Yellow
    $granModePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\gran-mode.ps1"
    Write-Host "Chemin du script gran-mode.ps1 : $granModePath" -ForegroundColor Yellow
    & $granModePath -FilePath $testFilePath -TaskIdentifier "1.3" -SubTasksFile $testSubTasksFilePath

    # VÃƒÂ©rifier le rÃƒÂ©sultat
    $content = Get-Content -Path $testFilePath -Encoding UTF8
    $hasTask = $content -join "`n" -match "- \[ \] \*\*1\.3\*\* TÃƒÂ¢che ÃƒÂ  dÃƒÂ©composer"
    $hasSubTask1 = $content -join "`n" -match "- \[ \] \*\*1\.3\.1\*\* PremiÃƒÂ¨re sous-tÃƒÂ¢che d'intÃƒÂ©gration"
    $hasSubTask2 = $content -join "`n" -match "- \[ \] \*\*1\.3\.2\*\* DeuxiÃƒÂ¨me sous-tÃƒÂ¢che d'intÃƒÂ©gration"
    $hasSubTask3 = $content -join "`n" -match "- \[ \] \*\*1\.3\.3\*\* TroisiÃƒÂ¨me sous-tÃƒÂ¢che d'intÃƒÂ©gration"

    if ($hasTask -and $hasSubTask1 -and $hasSubTask2 -and $hasSubTask3) {
        Write-Host "Test rÃƒÂ©ussi : Toutes les sous-tÃƒÂ¢ches ont ÃƒÂ©tÃƒÂ© correctement ajoutÃƒÂ©es." -ForegroundColor Green
        Write-Host "Contenu du fichier aprÃƒÂ¨s modification :" -ForegroundColor Yellow
        $content | ForEach-Object { Write-Host $_ }
    } else {
        Write-Host "Test ÃƒÂ©chouÃƒÂ© : Certaines sous-tÃƒÂ¢ches n'ont pas ÃƒÂ©tÃƒÂ© correctement ajoutÃƒÂ©es." -ForegroundColor Red
        Write-Host "Contenu du fichier aprÃƒÂ¨s modification :" -ForegroundColor Yellow
        $content | ForEach-Object { Write-Host $_ }
    }
} catch {
    Write-Host "Erreur lors de l'exÃƒÂ©cution du script gran-mode.ps1 : $_" -ForegroundColor Red
} finally {
    # Supprimer les fichiers de test
    if (Test-Path -Path $testFilePath) {
        Remove-Item -Path $testFilePath -Force
        Write-Host "Fichier de roadmap supprimÃƒÂ©." -ForegroundColor Gray
    }
    if (Test-Path -Path $testSubTasksFilePath) {
        Remove-Item -Path $testSubTasksFilePath -Force
        Write-Host "Fichier de sous-tÃƒÂ¢ches supprimÃƒÂ©." -ForegroundColor Gray
    }
}

Write-Host "Test complet terminÃƒÂ©." -ForegroundColor Cyan
