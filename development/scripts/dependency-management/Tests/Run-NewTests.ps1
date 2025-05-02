# Script pour exécuter les nouveaux tests

# Définir les couleurs pour les messages
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"
$warningColor = "Yellow"

# Liste des tests à exécuter
$tests = @(
    "Test-FunctionCallDependencies.ps1",
    "Test-FunctionUsageAnalysis.ps1",
    "Test-FunctionDependencyGraph.ps1"
)

# Compter le nombre de tests
$totalTests = $tests.Count
Write-Host "Nombre de tests à exécuter: $totalTests" -ForegroundColor $infoColor

# Initialiser les compteurs
$successCount = 0
$failureCount = 0

# Exécuter chaque test
foreach ($test in $tests) {
    $testPath = Join-Path -Path $PSScriptRoot -ChildPath $test
    
    Write-Host "`n========== Exécution du test: $testPath ==========" -ForegroundColor $infoColor
    
    try {
        # Exécuter le test
        & $testPath
        
        # Vérifier le code de retour
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Test réussi: $testPath" -ForegroundColor $successColor
            $successCount++
        } else {
            Write-Host "Test échoué: $testPath" -ForegroundColor $errorColor
            $failureCount++
        }
    } catch {
        Write-Host "Erreur lors de l'exécution du test: $_" -ForegroundColor $errorColor
        $failureCount++
    }
}

# Afficher le résumé
Write-Host "`n========== Résumé des tests ==========" -ForegroundColor $infoColor
Write-Host "Tests réussis: $successCount" -ForegroundColor $successColor
Write-Host "Tests échoués: $failureCount" -ForegroundColor $errorColor
Write-Host "Total des tests: $totalTests" -ForegroundColor $infoColor

# Calculer le pourcentage de réussite
$successPercentage = [math]::Round(($successCount / $totalTests) * 100)
Write-Host "Pourcentage de réussite: $successPercentage%" -ForegroundColor $(if ($successPercentage -eq 100) { $successColor } else { $warningColor })

# Afficher un message final
if ($failureCount -eq 0) {
    Write-Host "`nTous les tests ont réussi !" -ForegroundColor $successColor
} else {
    Write-Host "`nCertains tests ont échoué." -ForegroundColor $errorColor
}
