<#
.SYNOPSIS
    Test d'intÃ©gration pour le script check-mode.ps1.

.DESCRIPTION
    Ce script effectue un test d'intÃ©gration pour le script check-mode.ps1
    qui implÃ©mente le mode CHECK pour vÃ©rifier si les tÃ¢ches sÃ©lectionnÃ©es
    ont Ã©tÃ© implÃ©mentÃ©es Ã  100% et testÃ©es avec succÃ¨s Ã  100%.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

# Chemin vers le script Ã  tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$projectRoot = Split-Path -Parent (Split-Path -Parent $modulePath)
$checkModePath = Join-Path -Path $projectRoot -ChildPath "check-mode.ps1"

# VÃ©rifier si le script existe
if (-not (Test-Path -Path $checkModePath)) {
    throw "Le script check-mode.ps1 est introuvable Ã  l'emplacement : $checkModePath"
}

Write-Host "Script check-mode.ps1 trouvÃ© Ã  l'emplacement : $checkModePath" -ForegroundColor Green

# CrÃ©er un fichier temporaire pour les tests
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"

# CrÃ©er un fichier de test avec une structure de roadmap simple
@"
# Roadmap de test

## Section 1

- [ ] **1.1** Fonction d'inspection de variables
  - [ ] **1.1.1** DÃ©velopper la fonction d'affichage formatÃ© des variables
  - [ ] **1.1.2** ImplÃ©menter la fonction d'inspection d'objets complexes
  - [ ] **1.1.3** CrÃ©er le mÃ©canisme de limitation de profondeur d'inspection

## Section 2

- [ ] **2.1** Autre tÃ¢che
"@ | Set-Content -Path $testFilePath -Encoding UTF8

Write-Host "Fichier de roadmap crÃ©Ã© : $testFilePath" -ForegroundColor Green

# CrÃ©er des fichiers d'implÃ©mentation et de test fictifs pour simuler une implÃ©mentation complÃ¨te
$testImplPath = Join-Path -Path $env:TEMP -ChildPath "TestImpl_$(Get-Random)"
$testTestsPath = Join-Path -Path $env:TEMP -ChildPath "TestTests_$(Get-Random)"

# CrÃ©er les rÃ©pertoires
New-Item -Path $testImplPath -ItemType Directory -Force | Out-Null
New-Item -Path $testTestsPath -ItemType Directory -Force | Out-Null

# CrÃ©er des fichiers d'implÃ©mentation fictifs
@"
function Inspect-Variable {
    param (
        [Parameter(Mandatory = `$true)]
        [object]`$InputObject,
        
        [Parameter(Mandatory = `$false)]
        [string]`$Format = "Text"
    )
    
    # ImplÃ©mentation fictive pour les tests
    return "Inspection de variable"
}
"@ | Set-Content -Path (Join-Path -Path $testImplPath -ChildPath "Inspect-Variable.ps1") -Encoding UTF8

# CrÃ©er des fichiers de test fictifs
@"
# Test fictif pour Inspect-Variable
Write-Host "Test de la fonction Inspect-Variable"
Write-Host "Tous les tests ont rÃ©ussi !"
exit 0
"@ | Set-Content -Path (Join-Path -Path $testTestsPath -ChildPath "Test-InspectVariable.ps1") -Encoding UTF8

Write-Host "Fichiers d'implÃ©mentation et de test crÃ©Ã©s." -ForegroundColor Green

# ExÃ©cuter le script check-mode.ps1
Write-Host "`nExÃ©cution du script check-mode.ps1..." -ForegroundColor Cyan
try {
    # Appeler le script
    & $checkModePath -FilePath $testFilePath -TaskIdentifier "1.1" -ImplementationPath $testImplPath -TestsPath $testTestsPath -UpdateRoadmap -GenerateReport
    
    # VÃ©rifier le rÃ©sultat
    $content = Get-Content -Path $testFilePath -Encoding UTF8
    $taskLine = $content | Where-Object { $_ -match ".*\b1\.1\b.*" }
    
    if ($taskLine -match "\[x\]") {
        Write-Host "`nTest rÃ©ussi : La tÃ¢che 1.1 a Ã©tÃ© marquÃ©e comme terminÃ©e." -ForegroundColor Green
        $testSuccess = $true
    } else {
        Write-Host "`nTest Ã©chouÃ© : La tÃ¢che 1.1 n'a pas Ã©tÃ© marquÃ©e comme terminÃ©e." -ForegroundColor Red
        Write-Host "Ligne actuelle : $taskLine" -ForegroundColor Red
        $testSuccess = $false
    }
    
    # VÃ©rifier si le rapport a Ã©tÃ© gÃ©nÃ©rÃ©
    $reportPath = Join-Path -Path (Split-Path -Parent $testFilePath) -ChildPath "check_report_1.1.md"
    
    if (Test-Path -Path $reportPath) {
        Write-Host "Rapport gÃ©nÃ©rÃ© : $reportPath" -ForegroundColor Green
        
        # Supprimer le rapport
        Remove-Item -Path $reportPath -Force
    } else {
        Write-Host "Le rapport n'a pas Ã©tÃ© gÃ©nÃ©rÃ©." -ForegroundColor Yellow
    }
} catch {
    Write-Host "`nErreur lors de l'exÃ©cution du script check-mode.ps1 : $_" -ForegroundColor Red
    $testSuccess = $false
}

# Supprimer les fichiers et rÃ©pertoires de test
if (Test-Path -Path $testFilePath) {
    Remove-Item -Path $testFilePath -Force
}

if (Test-Path -Path $testImplPath) {
    Remove-Item -Path $testImplPath -Recurse -Force
}

if (Test-Path -Path $testTestsPath) {
    Remove-Item -Path $testTestsPath -Recurse -Force
}

Write-Host "`nFichiers et rÃ©pertoires de test supprimÃ©s." -ForegroundColor Gray

# Retourner le rÃ©sultat global
if ($testSuccess) {
    Write-Host "`nTest d'intÃ©gration rÃ©ussi !" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nTest d'intÃ©gration Ã©chouÃ©." -ForegroundColor Red
    exit 1
}
