<#
.SYNOPSIS
    Tests unitaires pour la fonction Invoke-RoadmapCheck.

.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Invoke-RoadmapCheck
    qui permet de vérifier si les tâches sélectionnées ont été implémentées à 100%
    et testées avec succès à 100%.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

# Chemin vers les fonctions à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$invokeCheckPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapCheck.ps1"
$updateTaskPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Update-RoadmapTaskStatus.ps1"

# Vérifier si les fichiers existent
if (-not (Test-Path -Path $invokeCheckPath)) {
    throw "Le fichier Invoke-RoadmapCheck.ps1 est introuvable à l'emplacement : $invokeCheckPath"
}

if (-not (Test-Path -Path $updateTaskPath)) {
    throw "Le fichier Update-RoadmapTaskStatus.ps1 est introuvable à l'emplacement : $updateTaskPath"
}

# Importer les fonctions
. $updateTaskPath
. $invokeCheckPath
Write-Host "Fonctions importées." -ForegroundColor Green

# Créer un fichier temporaire pour les tests
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"

# Créer un fichier de test avec une structure de roadmap simple
@"
# Roadmap de test

## Section 1

- [ ] **1.1** Fonction d'inspection de variables
  - [ ] **1.1.1** Développer la fonction d'affichage formaté des variables
  - [ ] **1.1.2** Implémenter la fonction d'inspection d'objets complexes
  - [ ] **1.1.3** Créer le mécanisme de limitation de profondeur d'inspection

## Section 2

- [ ] **2.1** Autre tâche
"@ | Set-Content -Path $testFilePath -Encoding UTF8

Write-Host "Fichier de roadmap créé : $testFilePath" -ForegroundColor Green

# Créer des fichiers d'implémentation et de test fictifs pour simuler une implémentation complète
$testImplPath = Join-Path -Path $env:TEMP -ChildPath "TestImpl_$(Get-Random)"
$testTestsPath = Join-Path -Path $env:TEMP -ChildPath "TestTests_$(Get-Random)"

# Créer les répertoires
New-Item -Path $testImplPath -ItemType Directory -Force | Out-Null
New-Item -Path $testTestsPath -ItemType Directory -Force | Out-Null

# Créer des fichiers d'implémentation fictifs
@"
function Inspect-Variable {
    param (
        [Parameter(Mandatory = `$true)]
        [object]`$InputObject,
        
        [Parameter(Mandatory = `$false)]
        [string]`$Format = "Text"
    )
    
    # Implémentation fictive pour les tests
    return "Inspection de variable"
}
"@ | Set-Content -Path (Join-Path -Path $testImplPath -ChildPath "Inspect-Variable.ps1") -Encoding UTF8

# Créer des fichiers de test fictifs
@"
# Test fictif pour Inspect-Variable
Write-Host "Test de la fonction Inspect-Variable"
Write-Host "Tous les tests ont réussi !"
exit 0
"@ | Set-Content -Path (Join-Path -Path $testTestsPath -ChildPath "Test-InspectVariable.ps1") -Encoding UTF8

Write-Host "Fichiers d'implémentation et de test créés." -ForegroundColor Green

# Initialiser les compteurs de tests
$totalTests = 0
$passedTests = 0

# Test 1: Vérifier une tâche avec implémentation et tests complets
$totalTests++
Write-Host "`nTest 1: Vérifier une tâche avec implémentation et tests complets" -ForegroundColor Cyan
try {
    # Appeler la fonction
    $result = Invoke-RoadmapCheck -FilePath $testFilePath -TaskIdentifier "1.1" -ImplementationPath $testImplPath -TestsPath $testTestsPath -UpdateRoadmap $false -GenerateReport $false
    
    # Vérifier le résultat
    if ($result.ImplementedTasks -gt 0 -and $result.TestedTasks -gt 0) {
        Write-Host "  Réussi : La fonction a correctement détecté l'implémentation et les tests." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Échoué : La fonction n'a pas correctement détecté l'implémentation et les tests." -ForegroundColor Red
        Write-Host "  Résultat : $($result | ConvertTo-Json -Depth 3)" -ForegroundColor Red
    }
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 2: Mettre à jour la roadmap
$totalTests++
Write-Host "`nTest 2: Mettre à jour la roadmap" -ForegroundColor Cyan
try {
    # Appeler la fonction
    $result = Invoke-RoadmapCheck -FilePath $testFilePath -TaskIdentifier "1.1" -ImplementationPath $testImplPath -TestsPath $testTestsPath -UpdateRoadmap $true -GenerateReport $false
    
    # Vérifier le résultat
    $content = Get-Content -Path $testFilePath -Encoding UTF8
    $taskLine = $content | Where-Object { $_ -match ".*\b1\.1\b.*" }
    
    if ($taskLine -match "\[x\]") {
        Write-Host "  Réussi : La tâche 1.1 a été marquée comme terminée." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Échoué : La tâche 1.1 n'a pas été marquée comme terminée." -ForegroundColor Red
        Write-Host "  Ligne actuelle : $taskLine" -ForegroundColor Red
    }
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 3: Générer un rapport
$totalTests++
Write-Host "`nTest 3: Générer un rapport" -ForegroundColor Cyan
try {
    # Appeler la fonction
    $result = Invoke-RoadmapCheck -FilePath $testFilePath -TaskIdentifier "1.1" -ImplementationPath $testImplPath -TestsPath $testTestsPath -UpdateRoadmap $false -GenerateReport $true
    
    # Vérifier le résultat
    $reportPath = Join-Path -Path (Split-Path -Parent $testFilePath) -ChildPath "check_report_1.1.md"
    
    if (Test-Path -Path $reportPath) {
        Write-Host "  Réussi : Le rapport a été généré." -ForegroundColor Green
        $passedTests++
        
        # Supprimer le rapport
        Remove-Item -Path $reportPath -Force
    } else {
        Write-Host "  Échoué : Le rapport n'a pas été généré." -ForegroundColor Red
    }
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 4: Tenter de vérifier une tâche inexistante
$totalTests++
Write-Host "`nTest 4: Tenter de vérifier une tâche inexistante" -ForegroundColor Cyan
try {
    # Appeler la fonction
    $result = Invoke-RoadmapCheck -FilePath $testFilePath -TaskIdentifier "9.9" -ImplementationPath $testImplPath -TestsPath $testTestsPath -UpdateRoadmap $false -GenerateReport $false
    
    Write-Host "  Échoué : La fonction n'a pas levé d'exception pour une tâche inexistante." -ForegroundColor Red
} catch {
    if ($_.Exception.Message -match "non trouvée") {
        Write-Host "  Réussi : La fonction a correctement levé une exception pour une tâche inexistante." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Échoué : La fonction a levé une exception inattendue : $_" -ForegroundColor Red
    }
}

# Supprimer les fichiers et répertoires de test
if (Test-Path -Path $testFilePath) {
    Remove-Item -Path $testFilePath -Force
}

if (Test-Path -Path $testImplPath) {
    Remove-Item -Path $testImplPath -Recurse -Force
}

if (Test-Path -Path $testTestsPath) {
    Remove-Item -Path $testTestsPath -Recurse -Force
}

Write-Host "`nFichiers et répertoires de test supprimés." -ForegroundColor Gray

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
