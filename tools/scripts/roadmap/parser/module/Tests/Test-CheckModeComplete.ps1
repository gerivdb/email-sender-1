<#
.SYNOPSIS
    Test d'intégration pour le script check-mode.ps1.

.DESCRIPTION
    Ce script effectue un test d'intégration pour le script check-mode.ps1
    qui implémente le mode CHECK pour vérifier si les tâches sélectionnées
    ont été implémentées à 100% et testées avec succès à 100%.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

# Chemin vers le script à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$projectRoot = Split-Path -Parent (Split-Path -Parent $modulePath)
$checkModePath = Join-Path -Path $projectRoot -ChildPath "check-mode.ps1"

# Vérifier si le script existe
if (-not (Test-Path -Path $checkModePath)) {
    throw "Le script check-mode.ps1 est introuvable à l'emplacement : $checkModePath"
}

Write-Host "Script check-mode.ps1 trouvé à l'emplacement : $checkModePath" -ForegroundColor Green

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

# Exécuter le script check-mode.ps1
Write-Host "`nExécution du script check-mode.ps1..." -ForegroundColor Cyan
try {
    # Appeler le script
    & $checkModePath -FilePath $testFilePath -TaskIdentifier "1.1" -ImplementationPath $testImplPath -TestsPath $testTestsPath -UpdateRoadmap -GenerateReport
    
    # Vérifier le résultat
    $content = Get-Content -Path $testFilePath -Encoding UTF8
    $taskLine = $content | Where-Object { $_ -match ".*\b1\.1\b.*" }
    
    if ($taskLine -match "\[x\]") {
        Write-Host "`nTest réussi : La tâche 1.1 a été marquée comme terminée." -ForegroundColor Green
        $testSuccess = $true
    } else {
        Write-Host "`nTest échoué : La tâche 1.1 n'a pas été marquée comme terminée." -ForegroundColor Red
        Write-Host "Ligne actuelle : $taskLine" -ForegroundColor Red
        $testSuccess = $false
    }
    
    # Vérifier si le rapport a été généré
    $reportPath = Join-Path -Path (Split-Path -Parent $testFilePath) -ChildPath "check_report_1.1.md"
    
    if (Test-Path -Path $reportPath) {
        Write-Host "Rapport généré : $reportPath" -ForegroundColor Green
        
        # Supprimer le rapport
        Remove-Item -Path $reportPath -Force
    } else {
        Write-Host "Le rapport n'a pas été généré." -ForegroundColor Yellow
    }
} catch {
    Write-Host "`nErreur lors de l'exécution du script check-mode.ps1 : $_" -ForegroundColor Red
    $testSuccess = $false
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

# Retourner le résultat global
if ($testSuccess) {
    Write-Host "`nTest d'intégration réussi !" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nTest d'intégration échoué." -ForegroundColor Red
    exit 1
}
