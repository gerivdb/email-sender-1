<#
.SYNOPSIS
    Tests unitaires pour la fonction Test-RoadmapBreakpointCondition.

.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Test-RoadmapBreakpointCondition
    qui permet d'évaluer des conditions de points d'arrêt.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

# Chemin vers la fonction à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$functionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Test-RoadmapBreakpointCondition.ps1"

# Vérifier si le fichier existe
if (-not (Test-Path -Path $functionPath)) {
    throw "Le fichier Test-RoadmapBreakpointCondition.ps1 est introuvable à l'emplacement : $functionPath"
}

# Importer la fonction
. $functionPath
Write-Host "Fonction Test-RoadmapBreakpointCondition importée depuis : $functionPath" -ForegroundColor Green

# Initialiser les compteurs de tests
$totalTests = 0
$passedTests = 0

# Test 1: Évaluer une condition booléenne simple (true)
$totalTests++
Write-Host "`nTest 1: Évaluer une condition booléenne simple (true)" -ForegroundColor Cyan
try {
    $result = Test-RoadmapBreakpointCondition -Condition $true
    
    if ($result -eq $true) {
        Write-Host "  Réussi : La condition booléenne true a été correctement évaluée à true." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Échoué : La condition booléenne true a été incorrectement évaluée à false." -ForegroundColor Red
    }
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 2: Évaluer une condition booléenne simple (false)
$totalTests++
Write-Host "`nTest 2: Évaluer une condition booléenne simple (false)" -ForegroundColor Cyan
try {
    $result = Test-RoadmapBreakpointCondition -Condition $false
    
    if ($result -eq $false) {
        Write-Host "  Réussi : La condition booléenne false a été correctement évaluée à false." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Échoué : La condition booléenne false a été incorrectement évaluée à true." -ForegroundColor Red
    }
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 3: Évaluer une condition sous forme de chaîne
$totalTests++
Write-Host "`nTest 3: Évaluer une condition sous forme de chaîne" -ForegroundColor Cyan
try {
    $result = Test-RoadmapBreakpointCondition -Condition "2 -gt 1"
    
    if ($result -eq $true) {
        Write-Host "  Réussi : La condition '2 -gt 1' a été correctement évaluée à true." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Échoué : La condition '2 -gt 1' a été incorrectement évaluée à false." -ForegroundColor Red
    }
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 4: Évaluer une condition sous forme de ScriptBlock
$totalTests++
Write-Host "`nTest 4: Évaluer une condition sous forme de ScriptBlock" -ForegroundColor Cyan
try {
    $result = Test-RoadmapBreakpointCondition -Condition { 3 -lt 5 }
    
    if ($result -eq $true) {
        Write-Host "  Réussi : La condition ScriptBlock '3 -lt 5' a été correctement évaluée à true." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Échoué : La condition ScriptBlock '3 -lt 5' a été incorrectement évaluée à false." -ForegroundColor Red
    }
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 5: Évaluer une condition avec des variables
$totalTests++
Write-Host "`nTest 5: Évaluer une condition avec des variables" -ForegroundColor Cyan
try {
    $vars = @{
        "a" = 10
        "b" = 5
    }
    
    $result = Test-RoadmapBreakpointCondition -Condition '$a -gt $b' -Variables $vars
    
    if ($result -eq $true) {
        Write-Host "  Réussi : La condition avec variables a été correctement évaluée à true." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Échoué : La condition avec variables a été incorrectement évaluée à false." -ForegroundColor Red
    }
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 6: Évaluer une condition invalide
$totalTests++
Write-Host "`nTest 6: Évaluer une condition invalide" -ForegroundColor Cyan
try {
    $result = Test-RoadmapBreakpointCondition -Condition "ceci n'est pas une expression valide"
    
    if ($result -eq $false) {
        Write-Host "  Réussi : La condition invalide a été correctement évaluée à false." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Échoué : La condition invalide a été incorrectement évaluée à true." -ForegroundColor Red
    }
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 7: Évaluer une condition avec ThrowOnError
$totalTests++
Write-Host "`nTest 7: Évaluer une condition avec ThrowOnError" -ForegroundColor Cyan
try {
    Test-RoadmapBreakpointCondition -Condition "ceci n'est pas une expression valide" -ThrowOnError
    
    Write-Host "  Échoué : La fonction n'a pas levé d'exception pour une condition invalide avec ThrowOnError." -ForegroundColor Red
} catch {
    Write-Host "  Réussi : La fonction a correctement levé une exception pour une condition invalide avec ThrowOnError." -ForegroundColor Green
    $passedTests++
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
