#Requires -Version 5.1
<#
.SYNOPSIS
    Script pour exécuter tous les tests unitaires et d'intégration.
.DESCRIPTION
    Ce script exécute tous les tests unitaires et d'intégration pour les modules
    DependencyCycleResolver et CycleDetector.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-20
#>

# Initialiser les résultats des tests
$testsPassed = 0
$testsFailed = 0

# Fonction pour exécuter un script de test
function Invoke-TestScript {
    param (
        [string]$Path
    )
    
    Write-Host "Exécution des tests: $Path" -ForegroundColor Yellow
    
    # Exécuter le script de test
    $result = & $Path
    
    # Vérifier le code de sortie
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Tests réussis" -ForegroundColor Green
        return $true
    } else {
        Write-Host "  Tests échoués" -ForegroundColor Red
        return $false
    }
}

# Exécuter les tests unitaires pour DependencyCycleResolver
$result = Invoke-TestScript -Path "$PSScriptRoot\SimpleDependencyCycleResolverTests.ps1"
if ($result) { $testsPassed++ } else { $testsFailed++ }

# Exécuter les tests d'intégration
$result = Invoke-TestScript -Path "$PSScriptRoot\DependencyCycleIntegrationTests.ps1"
if ($result) { $testsPassed++ } else { $testsFailed++ }

# Afficher le résumé des tests
Write-Host "`nRésumé des tests:" -ForegroundColor Yellow
Write-Host "  Tests réussis: $testsPassed" -ForegroundColor Green
Write-Host "  Tests échoués: $testsFailed" -ForegroundColor Red
Write-Host "  Total: $($testsPassed + $testsFailed)" -ForegroundColor Yellow

# Retourner un code de sortie en fonction des résultats des tests
if ($testsFailed -eq 0) {
    Write-Host "`nTous les tests ont été exécutés avec succès." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont échoué." -ForegroundColor Red
    exit 1
}
