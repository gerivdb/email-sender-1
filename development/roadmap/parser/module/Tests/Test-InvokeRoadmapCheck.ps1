<#
.SYNOPSIS
    Tests unitaires pour la fonction Invoke-RoadmapCheck.

.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Invoke-RoadmapCheck
    qui permet de vÃ©rifier si les tÃ¢ches sÃ©lectionnÃ©es ont Ã©tÃ© implÃ©mentÃ©es Ã  100%
    et testÃ©es avec succÃ¨s Ã  100%.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

# Chemin vers les fonctions Ã  tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$invokeCheckPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapCheck.ps1"
$updateTaskPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Update-RoadmapTaskStatus.ps1"

# VÃ©rifier si les fichiers existent
if (-not (Test-Path -Path $invokeCheckPath)) {
    throw "Le fichier Invoke-RoadmapCheck.ps1 est introuvable Ã  l'emplacement : $invokeCheckPath"
}

if (-not (Test-Path -Path $updateTaskPath)) {
    throw "Le fichier Update-RoadmapTaskStatus.ps1 est introuvable Ã  l'emplacement : $updateTaskPath"
}

# Importer les fonctions
. $updateTaskPath
. $invokeCheckPath
Write-Host "Fonctions importÃ©es." -ForegroundColor Green

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
function Test-Variable {
    param (
        [Parameter(Mandatory = `$true)]
        [object]`$InputObject,
        
        [Parameter(Mandatory = `$false)]
        [string]`$Format = "Text"
    )
    
    # ImplÃ©mentation fictive pour les tests
    return "Inspection de variable"
}
"@ | Set-Content -Path (Join-Path -Path $testImplPath -ChildPath "Test-Variable.ps1") -Encoding UTF8

# CrÃ©er des fichiers de test fictifs
@"
# Test fictif pour Test-Variable
Write-Host "Test de la fonction Test-Variable"
Write-Host "Tous les tests ont rÃ©ussi !"
exit 0
"@ | Set-Content -Path (Join-Path -Path $testTestsPath -ChildPath "Test-InspectVariable.ps1") -Encoding UTF8

Write-Host "Fichiers d'implÃ©mentation et de test crÃ©Ã©s." -ForegroundColor Green

# Initialiser les compteurs de tests
$totalTests = 0
$passedTests = 0

# Test 1: VÃ©rifier une tÃ¢che avec implÃ©mentation et tests complets
$totalTests++
Write-Host "`nTest 1: VÃ©rifier une tÃ¢che avec implÃ©mentation et tests complets" -ForegroundColor Cyan
try {
    # Appeler la fonction
    $result = Invoke-RoadmapCheck -FilePath $testFilePath -TaskIdentifier "1.1" -ImplementationPath $testImplPath -TestsPath $testTestsPath -UpdateRoadmap $false -GenerateReport $false
    
    # VÃ©rifier le rÃ©sultat
    if ($result.ImplementedTasks -gt 0 -and $result.TestedTasks -gt 0) {
        Write-Host "  RÃ©ussi : La fonction a correctement dÃ©tectÃ© l'implÃ©mentation et les tests." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Ã‰chouÃ© : La fonction n'a pas correctement dÃ©tectÃ© l'implÃ©mentation et les tests." -ForegroundColor Red
        Write-Host "  RÃ©sultat : $($result | ConvertTo-Json -Depth 3)" -ForegroundColor Red
    }
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 2: Mettre Ã  jour la roadmap
$totalTests++
Write-Host "`nTest 2: Mettre Ã  jour la roadmap" -ForegroundColor Cyan
try {
    # Appeler la fonction
    $result = Invoke-RoadmapCheck -FilePath $testFilePath -TaskIdentifier "1.1" -ImplementationPath $testImplPath -TestsPath $testTestsPath -UpdateRoadmap $true -GenerateReport $false
    
    # VÃ©rifier le rÃ©sultat
    $content = Get-Content -Path $testFilePath -Encoding UTF8
    $taskLine = $content | Where-Object { $_ -match ".*\b1\.1\b.*" }
    
    if ($taskLine -match "\[x\]") {
        Write-Host "  RÃ©ussi : La tÃ¢che 1.1 a Ã©tÃ© marquÃ©e comme terminÃ©e." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Ã‰chouÃ© : La tÃ¢che 1.1 n'a pas Ã©tÃ© marquÃ©e comme terminÃ©e." -ForegroundColor Red
        Write-Host "  Ligne actuelle : $taskLine" -ForegroundColor Red
    }
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 3: GÃ©nÃ©rer un rapport
$totalTests++
Write-Host "`nTest 3: GÃ©nÃ©rer un rapport" -ForegroundColor Cyan
try {
    # Appeler la fonction
    $result = Invoke-RoadmapCheck -FilePath $testFilePath -TaskIdentifier "1.1" -ImplementationPath $testImplPath -TestsPath $testTestsPath -UpdateRoadmap $false -GenerateReport $true
    
    # VÃ©rifier le rÃ©sultat
    $reportPath = Join-Path -Path (Split-Path -Parent $testFilePath) -ChildPath "check_report_1.1.md"
    
    if (Test-Path -Path $reportPath) {
        Write-Host "  RÃ©ussi : Le rapport a Ã©tÃ© gÃ©nÃ©rÃ©." -ForegroundColor Green
        $passedTests++
        
        # Supprimer le rapport
        Remove-Item -Path $reportPath -Force
    } else {
        Write-Host "  Ã‰chouÃ© : Le rapport n'a pas Ã©tÃ© gÃ©nÃ©rÃ©." -ForegroundColor Red
    }
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 4: Tenter de vÃ©rifier une tÃ¢che inexistante
$totalTests++
Write-Host "`nTest 4: Tenter de vÃ©rifier une tÃ¢che inexistante" -ForegroundColor Cyan
try {
    # Appeler la fonction
    $result = Invoke-RoadmapCheck -FilePath $testFilePath -TaskIdentifier "9.9" -ImplementationPath $testImplPath -TestsPath $testTestsPath -UpdateRoadmap $false -GenerateReport $false
    
    Write-Host "  Ã‰chouÃ© : La fonction n'a pas levÃ© d'exception pour une tÃ¢che inexistante." -ForegroundColor Red
} catch {
    if ($_.Exception.Message -match "non trouvÃ©e") {
        Write-Host "  RÃ©ussi : La fonction a correctement levÃ© une exception pour une tÃ¢che inexistante." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Ã‰chouÃ© : La fonction a levÃ© une exception inattendue : $_" -ForegroundColor Red
    }
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

