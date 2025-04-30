<#
.SYNOPSIS
    Tests unitaires pour le module ManagerRegistrationService.

.DESCRIPTION
    Ce script exécute des tests unitaires pour vérifier le bon fonctionnement
    du module ManagerRegistrationService.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1
#>

# Définir le chemin du module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\ManagerRegistrationService\ManagerRegistrationService.psm1"

# Vérifier que le module existe
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Le module ManagerRegistrationService est introuvable à l'emplacement : $modulePath"
    exit 1
}

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Créer un fichier de configuration de test
$testConfigPath = Join-Path -Path $testDir -ChildPath "test-registration.config.json"

# Créer un gestionnaire de test
$testManagerPath = Join-Path -Path $testDir -ChildPath "test-manager.ps1"
Set-Content -Path $testManagerPath -Value @"
<#
.SYNOPSIS
    Gestionnaire de test pour les tests unitaires.

.DESCRIPTION
    Ce script est un gestionnaire de test utilisé pour les tests unitaires
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

# Définir les tests unitaires
$tests = @(
    @{
        Name = "Test de Register-Manager"
        Test = {
            # Enregistrer un gestionnaire
            $result = Register-Manager -Name "TestManager" -Path $testManagerPath -ConfigPath $testConfigPath
            
            # Vérifier que l'enregistrement a réussi
            if (-not $result) {
                return $false
            }
            
            # Vérifier que le gestionnaire est enregistré dans la configuration
            $config = Get-Content -Path $testConfigPath -Raw | ConvertFrom-Json
            return $config.Managers.TestManager -ne $null
        }
    },
    @{
        Name = "Test de Get-RegisteredManager"
        Test = {
            # Récupérer le gestionnaire enregistré
            $manager = Get-RegisteredManager -Name "TestManager" -ConfigPath $testConfigPath
            
            # Vérifier que le gestionnaire est récupéré
            if (-not $manager) {
                return $false
            }
            
            # Vérifier les propriétés du gestionnaire
            return $manager.Path -eq $testManagerPath -and $manager.Enabled -eq $true
        }
    },
    @{
        Name = "Test de Update-Manager"
        Test = {
            # Mettre à jour le gestionnaire
            $result = Update-Manager -Name "TestManager" -Version "1.1.0" -ConfigPath $testConfigPath
            
            # Vérifier que la mise à jour a réussi
            if (-not $result) {
                return $false
            }
            
            # Vérifier que la version a été mise à jour
            $manager = Get-RegisteredManager -Name "TestManager" -ConfigPath $testConfigPath
            return $manager.Version -eq "1.1.0"
        }
    },
    @{
        Name = "Test de Find-Manager"
        Test = {
            # Rechercher des gestionnaires selon des critères
            $managers = Find-Manager -Criteria @{ Version = "1.1.0" } -ConfigPath $testConfigPath
            
            # Vérifier que le gestionnaire est trouvé
            if (-not $managers -or $managers.Count -eq 0) {
                return $false
            }
            
            # Vérifier que le gestionnaire trouvé est celui attendu
            return $managers[0].Name -eq "TestManager"
        }
    },
    @{
        Name = "Test de Unregister-Manager"
        Test = {
            # Désenregistrer le gestionnaire
            $result = Unregister-Manager -Name "TestManager" -ConfigPath $testConfigPath -Force
            
            # Vérifier que le désenregistrement a réussi
            if (-not $result) {
                return $false
            }
            
            # Vérifier que le gestionnaire n'est plus enregistré
            $manager = Get-RegisteredManager -Name "TestManager" -ConfigPath $testConfigPath
            return $manager.Count -eq 0
        }
    }
)

# Exécuter les tests
$totalTests = $tests.Count
$passedTests = 0
$failedTests = 0

Write-Host "Exécution de $totalTests tests unitaires pour le module ManagerRegistrationService..." -ForegroundColor Cyan

foreach ($test in $tests) {
    Write-Host "Test : $($test.Name)" -ForegroundColor Yellow
    
    try {
        $result = & $test.Test
        
        if ($result) {
            Write-Host "  Résultat : Réussi" -ForegroundColor Green
            $passedTests++
        } else {
            Write-Host "  Résultat : Échec" -ForegroundColor Red
            $failedTests++
        }
    } catch {
        Write-Host "  Résultat : Erreur - $_" -ForegroundColor Red
        $failedTests++
    }
}

# Afficher le résumé
Write-Host "`nRésumé des tests :" -ForegroundColor Cyan
Write-Host "  Tests exécutés : $totalTests" -ForegroundColor White
Write-Host "  Tests réussis  : $passedTests" -ForegroundColor Green
Write-Host "  Tests échoués  : $failedTests" -ForegroundColor Red

# Nettoyer les fichiers de test
if (Test-Path -Path $testConfigPath) {
    Remove-Item -Path $testConfigPath -Force
}

# Retourner le résultat global
if ($failedTests -eq 0) {
    Write-Host "`nTous les tests ont réussi !" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont échoué." -ForegroundColor Red
    exit 1
}
