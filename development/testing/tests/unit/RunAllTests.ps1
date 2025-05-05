#Requires -Version 5.1
<#
.SYNOPSIS
    Script pour exÃ©cuter tous les tests unitaires et d'intÃ©gration.
.DESCRIPTION
    Ce script exÃ©cute tous les tests unitaires et d'intÃ©gration pour les modules
    DependencyCycleResolver et CycleDetector.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-04-20
#>

# Initialiser les rÃ©sultats des tests
$testsPassed = 0
$testsFailed = 0

# Fonction pour exÃ©cuter un script de test
function Invoke-TestScript {
    param (
        [string]$Path
    )
    
    Write-Host "ExÃ©cution des tests: $Path" -ForegroundColor Yellow
    
    # ExÃ©cuter le script de test
    $result = & $Path
    
    # VÃ©rifier le code de sortie
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Tests rÃ©ussis" -ForegroundColor Green
        return $true
    } else {
        Write-Host "  Tests Ã©chouÃ©s" -ForegroundColor Red
        return $false
    }
}

# ExÃ©cuter les tests unitaires pour DependencyCycleResolver
$result = Invoke-TestScript -Path "$PSScriptRoot\SimpleDependencyCycleResolverTests.ps1"
if ($result) { $testsPassed++ } else { $testsFailed++ }

# ExÃ©cuter les tests d'intÃ©gration
$result = Invoke-TestScript -Path "$PSScriptRoot\DependencyCycleIntegrationTests.ps1"
if ($result) { $testsPassed++ } else { $testsFailed++ }

# Afficher le rÃ©sumÃ© des tests
Write-Host "`nRÃ©sumÃ© des tests:" -ForegroundColor Yellow
Write-Host "  Tests rÃ©ussis: $testsPassed" -ForegroundColor Green
Write-Host "  Tests Ã©chouÃ©s: $testsFailed" -ForegroundColor Red
Write-Host "  Total: $($testsPassed + $testsFailed)" -ForegroundColor Yellow

# Retourner un code de sortie en fonction des rÃ©sultats des tests
if ($testsFailed -eq 0) {
    Write-Host "`nTous les tests ont Ã©tÃ© exÃ©cutÃ©s avec succÃ¨s." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont Ã©chouÃ©." -ForegroundColor Red
    exit 1
}
