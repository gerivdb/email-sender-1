<#
.SYNOPSIS
    Tests unitaires pour la fonction Update-RoadmapTaskStatus.

.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Update-RoadmapTaskStatus
    qui permet de mettre à jour le statut d'une tâche dans un fichier de roadmap.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

# Chemin vers la fonction à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$functionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Update-RoadmapTaskStatus.ps1"

# Vérifier si le fichier existe
if (-not (Test-Path -Path $functionPath)) {
    throw "Le fichier Update-RoadmapTaskStatus.ps1 est introuvable à l'emplacement : $functionPath"
}

# Importer la fonction
. $functionPath
Write-Host "Fonction Update-RoadmapTaskStatus importée depuis : $functionPath" -ForegroundColor Green

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
- [ ] **1.3** Tâche 3

## Section 2

- [ ] **2.1** Autre tâche
"@ | Set-Content -Path $testFilePath -Encoding UTF8

Write-Host "Fichier de roadmap créé : $testFilePath" -ForegroundColor Green

# Initialiser les compteurs de tests
$totalTests = 0
$passedTests = 0

# Test 1: Marquer une tâche comme terminée
$totalTests++
Write-Host "`nTest 1: Marquer une tâche comme terminée" -ForegroundColor Cyan
try {
    # Appeler la fonction
    Update-RoadmapTaskStatus -FilePath $testFilePath -TaskIdentifier "1.2" -Status "Completed"
    
    # Vérifier le résultat
    $content = Get-Content -Path $testFilePath -Encoding UTF8
    $taskLine = $content | Where-Object { $_ -match ".*\b1\.2\b.*" }
    
    if ($taskLine -match "\[x\]") {
        Write-Host "  Réussi : La tâche 1.2 a été marquée comme terminée." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Échoué : La tâche 1.2 n'a pas été marquée comme terminée." -ForegroundColor Red
        Write-Host "  Ligne actuelle : $taskLine" -ForegroundColor Red
    }
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 2: Marquer une tâche comme en cours
$totalTests++
Write-Host "`nTest 2: Marquer une tâche comme en cours" -ForegroundColor Cyan
try {
    # Appeler la fonction
    Update-RoadmapTaskStatus -FilePath $testFilePath -TaskIdentifier "1.2" -Status "InProgress"
    
    # Vérifier le résultat
    $content = Get-Content -Path $testFilePath -Encoding UTF8
    $taskLine = $content | Where-Object { $_ -match ".*\b1\.2\b.*" }
    
    if ($taskLine -match "\[ \]") {
        Write-Host "  Réussi : La tâche 1.2 a été marquée comme en cours." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Échoué : La tâche 1.2 n'a pas été marquée comme en cours." -ForegroundColor Red
        Write-Host "  Ligne actuelle : $taskLine" -ForegroundColor Red
    }
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 3: Marquer une sous-tâche comme terminée
$totalTests++
Write-Host "`nTest 3: Marquer une sous-tâche comme terminée" -ForegroundColor Cyan
try {
    # Appeler la fonction
    Update-RoadmapTaskStatus -FilePath $testFilePath -TaskIdentifier "1.2.1" -Status "Completed"
    
    # Vérifier le résultat
    $content = Get-Content -Path $testFilePath -Encoding UTF8
    $taskLine = $content | Where-Object { $_ -match ".*\b1\.2\.1\b.*" }
    
    if ($taskLine -match "\[x\]") {
        Write-Host "  Réussi : La sous-tâche 1.2.1 a été marquée comme terminée." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Échoué : La sous-tâche 1.2.1 n'a pas été marquée comme terminée." -ForegroundColor Red
        Write-Host "  Ligne actuelle : $taskLine" -ForegroundColor Red
    }
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 4: Tenter de mettre à jour une tâche inexistante
$totalTests++
Write-Host "`nTest 4: Tenter de mettre à jour une tâche inexistante" -ForegroundColor Cyan
try {
    # Appeler la fonction
    Update-RoadmapTaskStatus -FilePath $testFilePath -TaskIdentifier "9.9" -Status "Completed"
    
    Write-Host "  Échoué : La fonction n'a pas levé d'exception pour une tâche inexistante." -ForegroundColor Red
} catch {
    if ($_.Exception.Message -match "non trouvée") {
        Write-Host "  Réussi : La fonction a correctement levé une exception pour une tâche inexistante." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Échoué : La fonction a levé une exception inattendue : $_" -ForegroundColor Red
    }
}

# Supprimer le fichier de test
if (Test-Path -Path $testFilePath) {
    Remove-Item -Path $testFilePath -Force
    Write-Host "`nFichier de test supprimé." -ForegroundColor Gray
}

# Afficher le résumé des tests
Write-Host "`nRésumé des tests :" -ForegroundColor Cyan
Write-Host "  Tests exécutés : $totalTests" -ForegroundColor Cyan
Write-Host "  Tests réussis : $passedTests" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Red" })
Write-Host "  Tests échoués : $($totalTests - $passedTests)" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Red" })

# Retourner le résultat global
if ($passedTests -eq $totalTests) {
    Write-Host "`nTous les tests ont réussi !" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont échoué." -ForegroundColor Red
    exit 1
}
