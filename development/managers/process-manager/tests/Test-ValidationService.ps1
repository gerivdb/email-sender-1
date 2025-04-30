<#
.SYNOPSIS
    Tests unitaires pour le module ValidationService.

.DESCRIPTION
    Ce script exécute des tests unitaires pour vérifier le bon fonctionnement
    du module ValidationService.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1
#>

# Définir le chemin du module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\ValidationService\ValidationService.psm1"

# Vérifier que le module existe
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Le module ValidationService est introuvable à l'emplacement : $modulePath"
    exit 1
}

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Créer un gestionnaire de test valide
$validManagerPath = Join-Path -Path $testDir -ChildPath "valid-manager.ps1"
Set-Content -Path $validManagerPath -Value @"
<#
.SYNOPSIS
    Gestionnaire de test valide pour les tests unitaires.

.DESCRIPTION
    Ce script est un gestionnaire de test valide utilisé pour les tests unitaires
    du module ValidationService.
#>

param (
    [Parameter(Mandatory = `$false)]
    [string]`$Command = "Status"
)

function Start-ValidManager {
    [CmdletBinding()]
    param()
    
    Write-Host "Démarrage du gestionnaire de test valide..."
}

function Stop-ValidManager {
    [CmdletBinding()]
    param()
    
    Write-Host "Arrêt du gestionnaire de test valide..."
}

function Get-ValidManagerStatus {
    [CmdletBinding()]
    param()
    
    return @{
        Status = "Running"
        StartTime = Get-Date
    }
}

# Exécuter la commande spécifiée
switch (`$Command) {
    "Start" {
        Start-ValidManager
    }
    "Stop" {
        Stop-ValidManager
    }
    "Status" {
        Get-ValidManagerStatus
    }
    default {
        Write-Host "Commande inconnue : `$Command"
    }
}
"@

# Créer un gestionnaire de test invalide (syntaxe incorrecte)
$invalidSyntaxManagerPath = Join-Path -Path $testDir -ChildPath "invalid-syntax-manager.ps1"
Set-Content -Path $invalidSyntaxManagerPath -Value @"
<#
.SYNOPSIS
    Gestionnaire de test avec syntaxe invalide pour les tests unitaires.

.DESCRIPTION
    Ce script est un gestionnaire de test avec syntaxe invalide utilisé pour les tests unitaires
    du module ValidationService.
#>

param (
    [Parameter(Mandatory = `$false)]
    [string]`$Command = "Status"
)

function Start-InvalidSyntaxManager {
    [CmdletBinding()]
    param()
    
    Write-Host "Démarrage du gestionnaire de test avec syntaxe invalide..."
}

# Erreur de syntaxe intentionnelle
function Stop-InvalidSyntaxManager {
    [CmdletBinding()
    param()
    
    Write-Host "Arrêt du gestionnaire de test avec syntaxe invalide..."
}

function Get-InvalidSyntaxManagerStatus {
    [CmdletBinding()]
    param()
    
    return @{
        Status = "Running"
        StartTime = Get-Date
    }
}

# Exécuter la commande spécifiée
switch (`$Command) {
    "Start" {
        Start-InvalidSyntaxManager
    }
    "Stop" {
        Stop-InvalidSyntaxManager
    }
    "Status" {
        Get-InvalidSyntaxManagerStatus
    }
    default {
        Write-Host "Commande inconnue : `$Command"
    }
}
"@

# Créer un gestionnaire de test invalide (fonctions manquantes)
$invalidInterfaceManagerPath = Join-Path -Path $testDir -ChildPath "invalid-interface-manager.ps1"
Set-Content -Path $invalidInterfaceManagerPath -Value @"
<#
.SYNOPSIS
    Gestionnaire de test avec interface invalide pour les tests unitaires.

.DESCRIPTION
    Ce script est un gestionnaire de test avec interface invalide utilisé pour les tests unitaires
    du module ValidationService.
#>

param (
    [Parameter(Mandatory = `$false)]
    [string]`$Command = "Status"
)

function Start-InvalidInterfaceManager {
    [CmdletBinding()]
    param()
    
    Write-Host "Démarrage du gestionnaire de test avec interface invalide..."
}

# Fonction Stop manquante intentionnellement

function Get-InvalidInterfaceManagerStatus {
    [CmdletBinding()]
    param()
    
    return @{
        Status = "Running"
        StartTime = Get-Date
    }
}

# Exécuter la commande spécifiée
switch (`$Command) {
    "Start" {
        Start-InvalidInterfaceManager
    }
    "Status" {
        Get-InvalidInterfaceManagerStatus
    }
    default {
        Write-Host "Commande inconnue : `$Command"
    }
}
"@

# Importer le module
Import-Module -Name $modulePath -Force

# Définir les tests unitaires
$tests = @(
    @{
        Name = "Test de Test-ManagerValidity avec gestionnaire valide"
        Test = {
            # Valider le gestionnaire valide
            $result = Test-ManagerValidity -Path $validManagerPath
            
            # Vérifier que la validation a réussi
            return $result -eq $true
        }
    },
    @{
        Name = "Test de Test-ManagerValidity avec gestionnaire à syntaxe invalide"
        Test = {
            # Valider le gestionnaire à syntaxe invalide
            $result = Test-ManagerValidity -Path $invalidSyntaxManagerPath
            
            # Vérifier que la validation a échoué
            return $result -eq $false
        }
    },
    @{
        Name = "Test de Test-ManagerValidity avec gestionnaire à interface invalide"
        Test = {
            # Valider le gestionnaire à interface invalide
            $result = Test-ManagerValidity -Path $invalidInterfaceManagerPath
            
            # Vérifier que la validation a échoué
            return $result -eq $false
        }
    },
    @{
        Name = "Test de Test-ManagerValidity avec options de validation"
        Test = {
            # Valider le gestionnaire à interface invalide avec option d'ignorer les fonctions manquantes
            $result = Test-ManagerValidity -Path $invalidInterfaceManagerPath -ValidationOptions @{ IgnoreMissingFunctions = $true }
            
            # Vérifier que la validation a réussi malgré l'interface invalide
            return $result -eq $true
        }
    },
    @{
        Name = "Test de Test-ManagerInterface avec gestionnaire valide"
        Test = {
            # Vérifier l'interface du gestionnaire valide
            $result = Test-ManagerInterface -Path $validManagerPath -RequiredFunctions @("Start-ValidManager", "Stop-ValidManager", "Get-ValidManagerStatus")
            
            # Vérifier que la vérification a réussi
            return $result -eq $true
        }
    },
    @{
        Name = "Test de Test-ManagerInterface avec gestionnaire à interface invalide"
        Test = {
            # Vérifier l'interface du gestionnaire à interface invalide
            $result = Test-ManagerInterface -Path $invalidInterfaceManagerPath -RequiredFunctions @("Start-InvalidInterfaceManager", "Stop-InvalidInterfaceManager", "Get-InvalidInterfaceManagerStatus")
            
            # Vérifier que la vérification a échoué
            return $result -eq $false
        }
    },
    @{
        Name = "Test de Test-ManagerFunctionality avec gestionnaire valide"
        Test = {
            # Tester la fonctionnalité du gestionnaire valide
            $result = Test-ManagerFunctionality -Path $validManagerPath -TestParameters @{ Command = "Status" }
            
            # Vérifier que le test a réussi
            return $result -eq $true
        }
    }
)

# Exécuter les tests
$totalTests = $tests.Count
$passedTests = 0
$failedTests = 0

Write-Host "Exécution de $totalTests tests unitaires pour le module ValidationService..." -ForegroundColor Cyan

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
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}

# Retourner le résultat global
if ($failedTests -eq 0) {
    Write-Host "`nTous les tests ont réussi !" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont échoué." -ForegroundColor Red
    exit 1
}
