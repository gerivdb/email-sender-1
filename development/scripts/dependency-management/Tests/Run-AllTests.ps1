# Script pour exÃ©cuter tous les tests unitaires
# Ce script exÃ©cute tous les tests unitaires et vÃ©rifie que tous les tests rÃ©ussissent

# DÃ©finir les couleurs pour les messages
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"

# Fonction pour exÃ©cuter un test et vÃ©rifier son rÃ©sultat
function Invoke-TestScript {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestScript
    )
    
    Write-Host "`n========== ExÃ©cution du test: $TestScript ==========" -ForegroundColor $infoColor
    
    try {
        # ExÃ©cuter le script de test
        $output = & $TestScript 2>&1
        $exitCode = $LASTEXITCODE
        
        # Afficher la sortie du test
        $output | ForEach-Object { Write-Host $_ }
        
        # VÃ©rifier le rÃ©sultat
        if ($exitCode -eq 0) {
            Write-Host "Test rÃ©ussi: $TestScript" -ForegroundColor $successColor
            return $true
        } else {
            Write-Host "Test Ã©chouÃ©: $TestScript (Code de sortie: $exitCode)" -ForegroundColor $errorColor
            return $false
        }
    } catch {
        Write-Host "Erreur lors de l'exÃ©cution du test: $_" -ForegroundColor $errorColor
        return $false
    }
}

# Obtenir tous les scripts de test
$testScripts = Get-ChildItem -Path $PSScriptRoot -Filter "Test-*.ps1" | Where-Object { $_.Name -ne "Run-AllTests.ps1" }

Write-Host "Nombre de tests trouvÃ©s: $($testScripts.Count)" -ForegroundColor $infoColor

# Initialiser les compteurs
$successCount = 0
$failureCount = 0

# ExÃ©cuter chaque test
foreach ($testScript in $testScripts) {
    $result = Invoke-TestScript -TestScript $testScript.FullName
    
    if ($result) {
        $successCount++
    } else {
        $failureCount++
    }
}

# Afficher le rÃ©sumÃ©
Write-Host "`n========== RÃ©sumÃ© des tests ==========" -ForegroundColor $infoColor
Write-Host "Tests rÃ©ussis: $successCount" -ForegroundColor $successColor
Write-Host "Tests Ã©chouÃ©s: $failureCount" -ForegroundColor $errorColor
Write-Host "Total des tests: $($testScripts.Count)" -ForegroundColor $infoColor

# Calculer le pourcentage de rÃ©ussite
$successPercentage = ($successCount / $testScripts.Count) * 100
Write-Host "Pourcentage de rÃ©ussite: $successPercentage%" -ForegroundColor (if ($successPercentage -eq 100) { $successColor } else { $errorColor })

# DÃ©finir le code de sortie
if ($failureCount -eq 0) {
    Write-Host "`nTous les tests ont rÃ©ussi !" -ForegroundColor $successColor
    exit 0
} else {
    Write-Host "`nCertains tests ont Ã©chouÃ©." -ForegroundColor $errorColor
    exit 1
}
