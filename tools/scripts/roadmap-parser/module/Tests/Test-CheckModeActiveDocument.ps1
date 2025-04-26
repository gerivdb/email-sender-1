<#
.SYNOPSIS
    Tests pour vérifier la fonctionnalité de mise à jour des cases à cocher dans le document actif du mode CHECK.

.DESCRIPTION
    Ce script teste la fonctionnalité de mise à jour des cases à cocher dans le document actif
    du mode CHECK. Il crée un document de test avec des cases à cocher, simule des tâches
    implémentées et testées à 100%, et vérifie que les cases à cocher sont correctement mises à jour.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-09-15
#>

# Créer un fichier temporaire pour simuler un document actif
$tempFile = [System.IO.Path]::GetTempFileName() + ".md"

# Créer un contenu de test avec différents formats de cases à cocher
$testContent = @"
# Document de test pour le mode CHECK

## Tâches

- [ ] **1.1** Tâche 1.1
- [ ] 1.2 Tâche 1.2
- [ ] Tâche 1.3
- [ ] [1.4] Tâche 1.4
- [ ] (1.5) Tâche 1.5
- [x] **1.6** Tâche déjà cochée
"@

# Écrire le contenu dans le fichier temporaire
$testContent | Set-Content -Path $tempFile -Encoding UTF8

Write-Host "Document de test créé : $tempFile" -ForegroundColor Cyan
Write-Host "Contenu du document de test :" -ForegroundColor Cyan
Get-Content -Path $tempFile | ForEach-Object { Write-Host $_ }

# Créer un fichier temporaire pour simuler une roadmap
$tempRoadmap = [System.IO.Path]::GetTempFileName() + ".md"

# Créer un contenu de test pour la roadmap
$roadmapContent = @"
# Roadmap de test

## Tâches

- [ ] **1.1** Tâche 1.1
- [ ] **1.2** Tâche 1.2
- [ ] **1.3** Tâche 1.3
- [ ] **1.4** Tâche 1.4
- [ ] **1.5** Tâche 1.5
- [x] **1.6** Tâche déjà cochée
"@

# Écrire le contenu dans le fichier temporaire
$roadmapContent | Set-Content -Path $tempRoadmap -Encoding UTF8

Write-Host "`nRoadmap de test créée : $tempRoadmap" -ForegroundColor Cyan

# Chemin vers le script check-mode.ps1
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$checkModePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) -ChildPath "modes\check\check-mode.ps1"

# Vérifier si le script check-mode.ps1 existe
if (-not (Test-Path -Path $checkModePath)) {
    Write-Error "Le script check-mode.ps1 est introuvable à l'emplacement : $checkModePath"
    # Nettoyer les fichiers temporaires
    Remove-Item -Path $tempFile -Force
    Remove-Item -Path $tempRoadmap -Force
    return
}

# Au lieu d'exécuter le script check-mode.ps1 qui a des dépendances complexes,
# nous allons tester directement la fonction Update-ActiveDocumentCheckboxes

# Importer la fonction Update-ActiveDocumentCheckboxes
$updateCheckboxesPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "Functions\Public\Update-ActiveDocumentCheckboxes.ps1"
if (Test-Path -Path $updateCheckboxesPath) {
    . $updateCheckboxesPath
    Write-Host "`nFonction Update-ActiveDocumentCheckboxes importée." -ForegroundColor Green
} else {
    Write-Error "La fonction Update-ActiveDocumentCheckboxes est introuvable à l'emplacement : $updateCheckboxesPath"
    # Nettoyer les fichiers temporaires
    Remove-Item -Path $tempFile -Force
    Remove-Item -Path $tempRoadmap -Force
    return
}

# Créer des résultats de test simulés
$implementationResults = @{
    "1.1" = @{
        ImplementationComplete = $true
        ImplementationPercentage = 100
        TaskTitle = "Tâche 1.1"
    }
    "1.2" = @{
        ImplementationComplete = $false
        ImplementationPercentage = 50
        TaskTitle = "Tâche 1.2"
    }
    "1.3" = @{
        ImplementationComplete = $true
        ImplementationPercentage = 100
        TaskTitle = "Tâche 1.3"
    }
    "1.4" = @{
        ImplementationComplete = $true
        ImplementationPercentage = 100
        TaskTitle = "Tâche 1.4"
    }
    "1.5" = @{
        ImplementationComplete = $true
        ImplementationPercentage = 100
        TaskTitle = "Tâche 1.5"
    }
}

$testResults = @{
    "1.1" = @{
        TestsComplete = $true
        TestsSuccessful = $true
        TaskTitle = "Tâche 1.1"
    }
    "1.2" = @{
        TestsComplete = $false
        TestsSuccessful = $false
        TaskTitle = "Tâche 1.2"
    }
    "1.3" = @{
        TestsComplete = $true
        TestsSuccessful = $true
        TaskTitle = "Tâche 1.3"
    }
    "1.4" = @{
        TestsComplete = $true
        TestsSuccessful = $true
        TaskTitle = "Tâche 1.4"
    }
    "1.5" = @{
        TestsComplete = $true
        TestsSuccessful = $true
        TaskTitle = "Tâche 1.5"
    }
}

# Exécuter la fonction en mode simulation (WhatIf)
Write-Host "`nExécution de la fonction Update-ActiveDocumentCheckboxes en mode simulation :" -ForegroundColor Cyan
$updateResult = Update-ActiveDocumentCheckboxes -DocumentPath $tempFile -ImplementationResults $implementationResults -TestResults $testResults -WhatIf

# Vérifier que le contenu du document actif n'a pas été modifié (mode simulation)
$contentAfterSimulation = Get-Content -Path $tempFile -Encoding UTF8
$contentChanged = $false
for ($i = 0; $i -lt $contentAfterSimulation.Count; $i++) {
    if ($contentAfterSimulation[$i] -match "- \[x\]" -and $contentAfterSimulation[$i] -notmatch "Tâche déjà cochée") {
        $contentChanged = $true
        break
    }
}

if ($contentChanged) {
    Write-Host "`nTest échoué : Le contenu du document actif a été modifié en mode simulation." -ForegroundColor Red
} else {
    Write-Host "`nTest réussi : Le contenu du document actif n'a pas été modifié en mode simulation." -ForegroundColor Green
}

# Exécuter la fonction en mode force
Write-Host "`nExécution de la fonction Update-ActiveDocumentCheckboxes en mode force :" -ForegroundColor Cyan
$updateResult = Update-ActiveDocumentCheckboxes -DocumentPath $tempFile -ImplementationResults $implementationResults -TestResults $testResults

# Vérifier que le contenu du document actif a été modifié (mode force)
$contentAfterForce = Get-Content -Path $tempFile -Encoding UTF8
$contentChanged = $false
for ($i = 0; $i -lt $contentAfterForce.Count; $i++) {
    if ($contentAfterForce[$i] -match "- \[x\]" -and $contentAfterForce[$i] -match "Tâche 1.1") {
        $contentChanged = $true
        break
    }
}

if ($contentChanged) {
    Write-Host "`nTest réussi : Le contenu du document actif a été modifié en mode force." -ForegroundColor Green
} else {
    Write-Host "`nTest échoué : Le contenu du document actif n'a pas été modifié en mode force." -ForegroundColor Red
}

# Afficher le contenu du document actif après les tests
Write-Host "`nContenu du document actif après les tests :" -ForegroundColor Cyan
Get-Content -Path $tempFile | ForEach-Object { Write-Host $_ }

# Nettoyer les fichiers temporaires
Remove-Item -Path $tempFile -Force
Remove-Item -Path $tempRoadmap -Force

Write-Host "`nTests terminés." -ForegroundColor Cyan
