<#
.SYNOPSIS
    Tests unitaires pour la fonction Test-RoadmapBreakpointCondition.

.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Test-RoadmapBreakpointCondition
    qui permet d'Ã©valuer des conditions de points d'arrÃªt.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

# Chemin vers la fonction Ã  tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$functionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Test-RoadmapBreakpointCondition.ps1"

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $functionPath)) {
    throw "Le fichier Test-RoadmapBreakpointCondition.ps1 est introuvable Ã  l'emplacement : $functionPath"
}

# Importer la fonction
. $functionPath
Write-Host "Fonction Test-RoadmapBreakpointCondition importÃ©e depuis : $functionPath" -ForegroundColor Green

# Initialiser les compteurs de tests
$totalTests = 0
$passedTests = 0

# Test 1: Ã‰valuer une condition boolÃ©enne simple (true)
$totalTests++
Write-Host "`nTest 1: Ã‰valuer une condition boolÃ©enne simple (true)" -ForegroundColor Cyan
try {
    $result = Test-RoadmapBreakpointCondition -Condition $true
    
    if ($result -eq $true) {
        Write-Host "  RÃ©ussi : La condition boolÃ©enne true a Ã©tÃ© correctement Ã©valuÃ©e Ã  true." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Ã‰chouÃ© : La condition boolÃ©enne true a Ã©tÃ© incorrectement Ã©valuÃ©e Ã  false." -ForegroundColor Red
    }
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 2: Ã‰valuer une condition boolÃ©enne simple (false)
$totalTests++
Write-Host "`nTest 2: Ã‰valuer une condition boolÃ©enne simple (false)" -ForegroundColor Cyan
try {
    $result = Test-RoadmapBreakpointCondition -Condition $false
    
    if ($result -eq $false) {
        Write-Host "  RÃ©ussi : La condition boolÃ©enne false a Ã©tÃ© correctement Ã©valuÃ©e Ã  false." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Ã‰chouÃ© : La condition boolÃ©enne false a Ã©tÃ© incorrectement Ã©valuÃ©e Ã  true." -ForegroundColor Red
    }
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 3: Ã‰valuer une condition sous forme de chaÃ®ne
$totalTests++
Write-Host "`nTest 3: Ã‰valuer une condition sous forme de chaÃ®ne" -ForegroundColor Cyan
try {
    $result = Test-RoadmapBreakpointCondition -Condition "2 -gt 1"
    
    if ($result -eq $true) {
        Write-Host "  RÃ©ussi : La condition '2 -gt 1' a Ã©tÃ© correctement Ã©valuÃ©e Ã  true." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Ã‰chouÃ© : La condition '2 -gt 1' a Ã©tÃ© incorrectement Ã©valuÃ©e Ã  false." -ForegroundColor Red
    }
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 4: Ã‰valuer une condition sous forme de ScriptBlock
$totalTests++
Write-Host "`nTest 4: Ã‰valuer une condition sous forme de ScriptBlock" -ForegroundColor Cyan
try {
    $result = Test-RoadmapBreakpointCondition -Condition { 3 -lt 5 }
    
    if ($result -eq $true) {
        Write-Host "  RÃ©ussi : La condition ScriptBlock '3 -lt 5' a Ã©tÃ© correctement Ã©valuÃ©e Ã  true." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Ã‰chouÃ© : La condition ScriptBlock '3 -lt 5' a Ã©tÃ© incorrectement Ã©valuÃ©e Ã  false." -ForegroundColor Red
    }
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 5: Ã‰valuer une condition avec des variables
$totalTests++
Write-Host "`nTest 5: Ã‰valuer une condition avec des variables" -ForegroundColor Cyan
try {
    $vars = @{
        "a" = 10
        "b" = 5
    }
    
    $result = Test-RoadmapBreakpointCondition -Condition '$a -gt $b' -Variables $vars
    
    if ($result -eq $true) {
        Write-Host "  RÃ©ussi : La condition avec variables a Ã©tÃ© correctement Ã©valuÃ©e Ã  true." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Ã‰chouÃ© : La condition avec variables a Ã©tÃ© incorrectement Ã©valuÃ©e Ã  false." -ForegroundColor Red
    }
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 6: Ã‰valuer une condition invalide
$totalTests++
Write-Host "`nTest 6: Ã‰valuer une condition invalide" -ForegroundColor Cyan
try {
    $result = Test-RoadmapBreakpointCondition -Condition "ceci n'est pas une expression valide"
    
    if ($result -eq $false) {
        Write-Host "  RÃ©ussi : La condition invalide a Ã©tÃ© correctement Ã©valuÃ©e Ã  false." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Ã‰chouÃ© : La condition invalide a Ã©tÃ© incorrectement Ã©valuÃ©e Ã  true." -ForegroundColor Red
    }
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 7: Ã‰valuer une condition avec ThrowOnError
$totalTests++
Write-Host "`nTest 7: Ã‰valuer une condition avec ThrowOnError" -ForegroundColor Cyan
try {
    Test-RoadmapBreakpointCondition -Condition "ceci n'est pas une expression valide" -ThrowOnError
    
    Write-Host "  Ã‰chouÃ© : La fonction n'a pas levÃ© d'exception pour une condition invalide avec ThrowOnError." -ForegroundColor Red
} catch {
    Write-Host "  RÃ©ussi : La fonction a correctement levÃ© une exception pour une condition invalide avec ThrowOnError." -ForegroundColor Green
    $passedTests++
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
