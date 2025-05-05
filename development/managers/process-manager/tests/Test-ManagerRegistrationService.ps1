<#
.SYNOPSIS
    Tests unitaires pour le module ManagerRegistrationService.

.DESCRIPTION
    Ce script exÃ©cute des tests unitaires pour vÃ©rifier le bon fonctionnement
    du module ManagerRegistrationService.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1
#>

# DÃ©finir le chemin du module Ã  tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\ManagerRegistrationService\ManagerRegistrationService.psm1"

# VÃ©rifier que le module existe
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Le module ManagerRegistrationService est introuvable Ã  l'emplacement : $modulePath"
    exit 1
}

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier de configuration de test
$testConfigPath = Join-Path -Path $testDir -ChildPath "test-registration.config.json"

# CrÃ©er un gestionnaire de test
$testManagerPath = Join-Path -Path $testDir -ChildPath "test-manager.ps1"
Set-Content -Path $testManagerPath -Value @"
<#
.SYNOPSIS
    Gestionnaire de test pour les tests unitaires.

.DESCRIPTION
    Ce script est un gestionnaire de test utilisÃ© pour les tests unitaires
    du module ManagerRegistrationService.
#>

param (
    [Parameter(Mandatory = `$false)]
    [string]`$Command = "Status"
)

Write-Host "Gestionnaire de test - Commande : `$Command"
exit 0
"@

# Importer le module
Import-Module -Name $modulePath -Force

# DÃ©finir les tests unitaires
$tests = @(
    @{
        Name = "Test de Register-Manager"
        Test = {
            # Enregistrer un gestionnaire
            $result = Register-Manager -Name "TestManager" -Path $testManagerPath -ConfigPath $testConfigPath
            
            # VÃ©rifier que l'enregistrement a rÃ©ussi
            if (-not $result) {
                return $false
            }
            
            # VÃ©rifier que le gestionnaire est enregistrÃ© dans la configuration
            $config = Get-Content -Path $testConfigPath -Raw | ConvertFrom-Json
            return $config.Managers.TestManager -ne $null
        }
    },
    @{
        Name = "Test de Get-RegisteredManager"
        Test = {
            # RÃ©cupÃ©rer le gestionnaire enregistrÃ©
            $manager = Get-RegisteredManager -Name "TestManager" -ConfigPath $testConfigPath
            
            # VÃ©rifier que le gestionnaire est rÃ©cupÃ©rÃ©
            if (-not $manager) {
                return $false
            }
            
            # VÃ©rifier les propriÃ©tÃ©s du gestionnaire
            return $manager.Path -eq $testManagerPath -and $manager.Enabled -eq $true
        }
    },
    @{
        Name = "Test de Update-Manager"
        Test = {
            # Mettre Ã  jour le gestionnaire
            $result = Update-Manager -Name "TestManager" -Version "1.1.0" -ConfigPath $testConfigPath
            
            # VÃ©rifier que la mise Ã  jour a rÃ©ussi
            if (-not $result) {
                return $false
            }
            
            # VÃ©rifier que la version a Ã©tÃ© mise Ã  jour
            $manager = Get-RegisteredManager -Name "TestManager" -ConfigPath $testConfigPath
            return $manager.Version -eq "1.1.0"
        }
    },
    @{
        Name = "Test de Find-Manager"
        Test = {
            # Rechercher des gestionnaires selon des critÃ¨res
            $managers = Find-Manager -Criteria @{ Version = "1.1.0" } -ConfigPath $testConfigPath
            
            # VÃ©rifier que le gestionnaire est trouvÃ©
            if (-not $managers -or $managers.Count -eq 0) {
                return $false
            }
            
            # VÃ©rifier que le gestionnaire trouvÃ© est celui attendu
            return $managers[0].Name -eq "TestManager"
        }
    },
    @{
        Name = "Test de Unregister-Manager"
        Test = {
            # DÃ©senregistrer le gestionnaire
            $result = Unregister-Manager -Name "TestManager" -ConfigPath $testConfigPath -Force
            
            # VÃ©rifier que le dÃ©senregistrement a rÃ©ussi
            if (-not $result) {
                return $false
            }
            
            # VÃ©rifier que le gestionnaire n'est plus enregistrÃ©
            $manager = Get-RegisteredManager -Name "TestManager" -ConfigPath $testConfigPath
            return $manager.Count -eq 0
        }
    }
)

# ExÃ©cuter les tests
$totalTests = $tests.Count
$passedTests = 0
$failedTests = 0

Write-Host "ExÃ©cution de $totalTests tests unitaires pour le module ManagerRegistrationService..." -ForegroundColor Cyan

foreach ($test in $tests) {
    Write-Host "Test : $($test.Name)" -ForegroundColor Yellow
    
    try {
        $result = & $test.Test
        
        if ($result) {
            Write-Host "  RÃ©sultat : RÃ©ussi" -ForegroundColor Green
            $passedTests++
        } else {
            Write-Host "  RÃ©sultat : Ã‰chec" -ForegroundColor Red
            $failedTests++
        }
    } catch {
        Write-Host "  RÃ©sultat : Erreur - $_" -ForegroundColor Red
        $failedTests++
    }
}

# Afficher le rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© des tests :" -ForegroundColor Cyan
Write-Host "  Tests exÃ©cutÃ©s : $totalTests" -ForegroundColor White
Write-Host "  Tests rÃ©ussis  : $passedTests" -ForegroundColor Green
Write-Host "  Tests Ã©chouÃ©s  : $failedTests" -ForegroundColor Red

# Nettoyer les fichiers de test
if (Test-Path -Path $testConfigPath) {
    Remove-Item -Path $testConfigPath -Force
}

# Retourner le rÃ©sultat global
if ($failedTests -eq 0) {
    Write-Host "`nTous les tests ont rÃ©ussi !" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont Ã©chouÃ©." -ForegroundColor Red
    exit 1
}
