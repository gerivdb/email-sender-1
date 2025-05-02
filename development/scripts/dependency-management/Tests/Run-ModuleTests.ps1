# Script pour exécuter uniquement les tests du module ModuleDependencyAnalyzer-Fixed
# Ce script exécute tous les tests unitaires du module ModuleDependencyAnalyzer-Fixed

# Définir les couleurs pour les messages
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"

# Fonction pour exécuter un test et vérifier son résultat
function Invoke-TestScript {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestScript
    )
    
    Write-Host "`n========== Exécution du test: $TestScript ==========" -ForegroundColor $infoColor
    
    try {
        # Exécuter le script de test
        $output = & $TestScript 2>&1
        $exitCode = $LASTEXITCODE
        
        # Afficher la sortie du test
        $output | ForEach-Object { Write-Host $_ }
        
        # Vérifier le résultat
        if ($exitCode -eq 0) {
            Write-Host "Test réussi: $TestScript" -ForegroundColor $successColor
            return $true
        } else {
            Write-Host "Test échoué: $TestScript (Code de sortie: $exitCode)" -ForegroundColor $errorColor
            return $false
        }
    } catch {
        Write-Host "Erreur lors de l'exécution du test: $_" -ForegroundColor $errorColor
        return $false
    }
}

# Liste des tests à exécuter
$testScripts = @(
    "Test-FixedModule.ps1",
    "Test-ExternalFunctionDependencies.ps1",
    "Test-ResolveExternalFunctionPath.ps1",
    "Test-DependencyCache-Minimal.ps1",
    "Test-DependencyReport.ps1",
    "Test-CompleteDependencyAnalysis.ps1",
    "Test-ModuleDependencyDetectorIntegration.ps1",
    "Test-UnifiedInterface.ps1",
    "Test-IntegrationComplete.ps1"
)

Write-Host "Nombre de tests à exécuter: $($testScripts.Count)" -ForegroundColor $infoColor

# Initialiser les compteurs
$successCount = 0
$failureCount = 0

# Exécuter chaque test
foreach ($testScript in $testScripts) {
    $testPath = Join-Path -Path $PSScriptRoot -ChildPath $testScript
    $result = Invoke-TestScript -TestScript $testPath
    
    if ($result) {
        $successCount++
    } else {
        $failureCount++
    }
}

# Afficher le résumé
Write-Host "`n========== Résumé des tests ==========" -ForegroundColor $infoColor
Write-Host "Tests réussis: $successCount" -ForegroundColor $successColor
Write-Host "Tests échoués: $failureCount" -ForegroundColor $errorColor
Write-Host "Total des tests: $($testScripts.Count)" -ForegroundColor $infoColor

# Calculer le pourcentage de réussite
$successPercentage = ($successCount / $testScripts.Count) * 100
Write-Host "Pourcentage de réussite: $successPercentage%" -ForegroundColor (if ($successPercentage -eq 100) { $successColor } else { $errorColor })

# Définir le code de sortie
if ($failureCount -eq 0) {
    Write-Host "`nTous les tests ont réussi !" -ForegroundColor $successColor
    exit 0
} else {
    Write-Host "`nCertains tests ont échoué." -ForegroundColor $errorColor
    exit 1
}
