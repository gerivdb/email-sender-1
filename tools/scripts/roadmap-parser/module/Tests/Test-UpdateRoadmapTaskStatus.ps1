<#
.SYNOPSIS
    Tests unitaires pour la fonction Update-RoadmapTaskStatus.

.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Update-RoadmapTaskStatus
    qui permet de mettre Ã  jour le statut d'une tÃ¢che dans un fichier de roadmap.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

# Chemin vers la fonction Ã  tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$functionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Update-RoadmapTaskStatus.ps1"

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $functionPath)) {
    throw "Le fichier Update-RoadmapTaskStatus.ps1 est introuvable Ã  l'emplacement : $functionPath"
}

# Importer la fonction
. $functionPath
Write-Host "Fonction Update-RoadmapTaskStatus importÃ©e depuis : $functionPath" -ForegroundColor Green

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
- [ ] **1.3** TÃ¢che 3

## Section 2

- [ ] **2.1** Autre tÃ¢che
"@ | Set-Content -Path $testFilePath -Encoding UTF8

Write-Host "Fichier de roadmap crÃ©Ã© : $testFilePath" -ForegroundColor Green

# Initialiser les compteurs de tests
$totalTests = 0
$passedTests = 0

# Test 1: Marquer une tÃ¢che comme terminÃ©e
$totalTests++
Write-Host "`nTest 1: Marquer une tÃ¢che comme terminÃ©e" -ForegroundColor Cyan
try {
    # Appeler la fonction
    Update-RoadmapTaskStatus -FilePath $testFilePath -TaskIdentifier "1.2" -Status "Completed"
    
    # VÃ©rifier le rÃ©sultat
    $content = Get-Content -Path $testFilePath -Encoding UTF8
    $taskLine = $content | Where-Object { $_ -match ".*\b1\.2\b.*" }
    
    if ($taskLine -match "\[x\]") {
        Write-Host "  RÃ©ussi : La tÃ¢che 1.2 a Ã©tÃ© marquÃ©e comme terminÃ©e." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Ã‰chouÃ© : La tÃ¢che 1.2 n'a pas Ã©tÃ© marquÃ©e comme terminÃ©e." -ForegroundColor Red
        Write-Host "  Ligne actuelle : $taskLine" -ForegroundColor Red
    }
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 2: Marquer une tÃ¢che comme en cours
$totalTests++
Write-Host "`nTest 2: Marquer une tÃ¢che comme en cours" -ForegroundColor Cyan
try {
    # Appeler la fonction
    Update-RoadmapTaskStatus -FilePath $testFilePath -TaskIdentifier "1.2" -Status "InProgress"
    
    # VÃ©rifier le rÃ©sultat
    $content = Get-Content -Path $testFilePath -Encoding UTF8
    $taskLine = $content | Where-Object { $_ -match ".*\b1\.2\b.*" }
    
    if ($taskLine -match "\[ \]") {
        Write-Host "  RÃ©ussi : La tÃ¢che 1.2 a Ã©tÃ© marquÃ©e comme en cours." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Ã‰chouÃ© : La tÃ¢che 1.2 n'a pas Ã©tÃ© marquÃ©e comme en cours." -ForegroundColor Red
        Write-Host "  Ligne actuelle : $taskLine" -ForegroundColor Red
    }
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 3: Marquer une sous-tÃ¢che comme terminÃ©e
$totalTests++
Write-Host "`nTest 3: Marquer une sous-tÃ¢che comme terminÃ©e" -ForegroundColor Cyan
try {
    # Appeler la fonction
    Update-RoadmapTaskStatus -FilePath $testFilePath -TaskIdentifier "1.2.1" -Status "Completed"
    
    # VÃ©rifier le rÃ©sultat
    $content = Get-Content -Path $testFilePath -Encoding UTF8
    $taskLine = $content | Where-Object { $_ -match ".*\b1\.2\.1\b.*" }
    
    if ($taskLine -match "\[x\]") {
        Write-Host "  RÃ©ussi : La sous-tÃ¢che 1.2.1 a Ã©tÃ© marquÃ©e comme terminÃ©e." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Ã‰chouÃ© : La sous-tÃ¢che 1.2.1 n'a pas Ã©tÃ© marquÃ©e comme terminÃ©e." -ForegroundColor Red
        Write-Host "  Ligne actuelle : $taskLine" -ForegroundColor Red
    }
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 4: Tenter de mettre Ã  jour une tÃ¢che inexistante
$totalTests++
Write-Host "`nTest 4: Tenter de mettre Ã  jour une tÃ¢che inexistante" -ForegroundColor Cyan
try {
    # Appeler la fonction
    Update-RoadmapTaskStatus -FilePath $testFilePath -TaskIdentifier "9.9" -Status "Completed"
    
    Write-Host "  Ã‰chouÃ© : La fonction n'a pas levÃ© d'exception pour une tÃ¢che inexistante." -ForegroundColor Red
} catch {
    if ($_.Exception.Message -match "non trouvÃ©e") {
        Write-Host "  RÃ©ussi : La fonction a correctement levÃ© une exception pour une tÃ¢che inexistante." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Ã‰chouÃ© : La fonction a levÃ© une exception inattendue : $_" -ForegroundColor Red
    }
}

# Supprimer le fichier de test
if (Test-Path -Path $testFilePath) {
    Remove-Item -Path $testFilePath -Force
    Write-Host "`nFichier de test supprimÃ©." -ForegroundColor Gray
}

# Afficher le rÃ©sumÃ© des tests
Write-Host "`nRÃ©sumÃ© des tests :" -ForegroundColor Cyan
Write-Host "  Tests exÃ©cutÃ©s : $totalTests" -ForegroundColor Cyan
Write-Host "  Tests rÃ©ussis : $passedTests" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Red" })
Write-Host "  Tests Ã©chouÃ©s : $($totalTests - $passedTests)" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Red" })

# Retourner le rÃ©sultat global
if ($passedTests -eq $totalTests) {
    Write-Host "`nTous les tests ont rÃ©ussi !" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont Ã©chouÃ©." -ForegroundColor Red
    exit 1
}
