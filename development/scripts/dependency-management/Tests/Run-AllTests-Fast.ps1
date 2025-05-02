# Script pour exécuter tous les tests unitaires (version rapide)
# Ce script exécute tous les tests unitaires sauf ceux qui prennent trop de temps

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

# Obtenir tous les scripts de test
$testScripts = Get-ChildItem -Path $PSScriptRoot -Filter "Test-*.ps1" | Where-Object { 
    $_.Name -ne "Run-AllTests.ps1" -and 
    $_.Name -ne "Run-AllTests-Fast.ps1" -and 
    $_.Name -ne "Test-DependencyCache.ps1" -and 
    $_.Name -ne "Test-DependencyCache-Simple.ps1"
}

Write-Host "Nombre de tests trouvés: $($testScripts.Count)" -ForegroundColor $infoColor

# Initialiser les compteurs
$successCount = 0
$failureCount = 0

# Exécuter chaque test
foreach ($testScript in $testScripts) {
    $result = Invoke-TestScript -TestScript $testScript.FullName
    
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
