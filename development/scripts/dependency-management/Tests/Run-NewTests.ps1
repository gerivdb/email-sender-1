# Script pour exÃ©cuter les nouveaux tests

# DÃ©finir les couleurs pour les messages
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"
$warningColor = "Yellow"

# Liste des tests Ã  exÃ©cuter
$tests = @(
    "Test-FunctionCallDependencies.ps1",
    "Test-FunctionUsageAnalysis.ps1",
    "Test-FunctionDependencyGraph.ps1"
)

# Compter le nombre de tests
$totalTests = $tests.Count
Write-Host "Nombre de tests Ã  exÃ©cuter: $totalTests" -ForegroundColor $infoColor

# Initialiser les compteurs
$successCount = 0
$failureCount = 0

# ExÃ©cuter chaque test
foreach ($test in $tests) {
    $testPath = Join-Path -Path $PSScriptRoot -ChildPath $test
    
    Write-Host "`n========== ExÃ©cution du test: $testPath ==========" -ForegroundColor $infoColor
    
    try {
        # ExÃ©cuter le test
        & $testPath
        
        # VÃ©rifier le code de retour
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Test rÃ©ussi: $testPath" -ForegroundColor $successColor
            $successCount++
        } else {
            Write-Host "Test Ã©chouÃ©: $testPath" -ForegroundColor $errorColor
            $failureCount++
        }
    } catch {
        Write-Host "Erreur lors de l'exÃ©cution du test: $_" -ForegroundColor $errorColor
        $failureCount++
    }
}

# Afficher le rÃ©sumÃ©
Write-Host "`n========== RÃ©sumÃ© des tests ==========" -ForegroundColor $infoColor
Write-Host "Tests rÃ©ussis: $successCount" -ForegroundColor $successColor
Write-Host "Tests Ã©chouÃ©s: $failureCount" -ForegroundColor $errorColor
Write-Host "Total des tests: $totalTests" -ForegroundColor $infoColor

# Calculer le pourcentage de rÃ©ussite
$successPercentage = [math]::Round(($successCount / $totalTests) * 100)
Write-Host "Pourcentage de rÃ©ussite: $successPercentage%" -ForegroundColor $(if ($successPercentage -eq 100) { $successColor } else { $warningColor })

# Afficher un message final
if ($failureCount -eq 0) {
    Write-Host "`nTous les tests ont rÃ©ussi !" -ForegroundColor $successColor
} else {
    Write-Host "`nCertains tests ont Ã©chouÃ©." -ForegroundColor $errorColor
}
