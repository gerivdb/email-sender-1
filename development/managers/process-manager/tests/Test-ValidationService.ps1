<#
.SYNOPSIS
    Tests unitaires pour le module ValidationService.

.DESCRIPTION
    Ce script exÃ©cute des tests unitaires pour vÃ©rifier le bon fonctionnement
    du module ValidationService.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1
#>

# DÃ©finir le chemin du module Ã  tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\ValidationService\ValidationService.psm1"

# VÃ©rifier que le module existe
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Le module ValidationService est introuvable Ã  l'emplacement : $modulePath"
    exit 1
}

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un gestionnaire de test valide
$validManagerPath = Join-Path -Path $testDir -ChildPath "valid-manager.ps1"
Set-Content -Path $validManagerPath -Value @"
<#
.SYNOPSIS
    Gestionnaire de test valide pour les tests unitaires.

.DESCRIPTION
    Ce script est un gestionnaire de test valide utilisÃ© pour les tests unitaires
    du module ValidationService.
#>

param (
    [Parameter(Mandatory = `$false)]
    [string]`$Command = "Status"
)

function Start-ValidManager {
    [CmdletBinding()]
    param()
    
    Write-Host "DÃ©marrage du gestionnaire de test valide..."
}

function Stop-ValidManager {
    [CmdletBinding()]
    param()
    
    Write-Host "ArrÃªt du gestionnaire de test valide..."
}

function Get-ValidManagerStatus {
    [CmdletBinding()]
    param()
    
    return @{
        Status = "Running"
        StartTime = Get-Date
    }
}

# ExÃ©cuter la commande spÃ©cifiÃ©e
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

# CrÃ©er un gestionnaire de test invalide (syntaxe incorrecte)
$invalidSyntaxManagerPath = Join-Path -Path $testDir -ChildPath "invalid-syntax-manager.ps1"
Set-Content -Path $invalidSyntaxManagerPath -Value @"
<#
.SYNOPSIS
    Gestionnaire de test avec syntaxe invalide pour les tests unitaires.

.DESCRIPTION
    Ce script est un gestionnaire de test avec syntaxe invalide utilisÃ© pour les tests unitaires
    du module ValidationService.
#>

param (
    [Parameter(Mandatory = `$false)]
    [string]`$Command = "Status"
)

function Start-InvalidSyntaxManager {
    [CmdletBinding()]
    param()
    
    Write-Host "DÃ©marrage du gestionnaire de test avec syntaxe invalide..."
}

# Erreur de syntaxe intentionnelle
function Stop-InvalidSyntaxManager {
    [CmdletBinding()
    param()
    
    Write-Host "ArrÃªt du gestionnaire de test avec syntaxe invalide..."
}

function Get-InvalidSyntaxManagerStatus {
    [CmdletBinding()]
    param()
    
    return @{
        Status = "Running"
        StartTime = Get-Date
    }
}

# ExÃ©cuter la commande spÃ©cifiÃ©e
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

# CrÃ©er un gestionnaire de test invalide (fonctions manquantes)
$invalidInterfaceManagerPath = Join-Path -Path $testDir -ChildPath "invalid-interface-manager.ps1"
Set-Content -Path $invalidInterfaceManagerPath -Value @"
<#
.SYNOPSIS
    Gestionnaire de test avec interface invalide pour les tests unitaires.

.DESCRIPTION
    Ce script est un gestionnaire de test avec interface invalide utilisÃ© pour les tests unitaires
    du module ValidationService.
#>

param (
    [Parameter(Mandatory = `$false)]
    [string]`$Command = "Status"
)

function Start-InvalidInterfaceManager {
    [CmdletBinding()]
    param()
    
    Write-Host "DÃ©marrage du gestionnaire de test avec interface invalide..."
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

# ExÃ©cuter la commande spÃ©cifiÃ©e
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

# DÃ©finir les tests unitaires
$tests = @(
    @{
        Name = "Test de Test-ManagerValidity avec gestionnaire valide"
        Test = {
            # Valider le gestionnaire valide
            $result = Test-ManagerValidity -Path $validManagerPath
            
            # VÃ©rifier que la validation a rÃ©ussi
            return $result -eq $true
        }
    },
    @{
        Name = "Test de Test-ManagerValidity avec gestionnaire Ã  syntaxe invalide"
        Test = {
            # Valider le gestionnaire Ã  syntaxe invalide
            $result = Test-ManagerValidity -Path $invalidSyntaxManagerPath
            
            # VÃ©rifier que la validation a Ã©chouÃ©
            return $result -eq $false
        }
    },
    @{
        Name = "Test de Test-ManagerValidity avec gestionnaire Ã  interface invalide"
        Test = {
            # Valider le gestionnaire Ã  interface invalide
            $result = Test-ManagerValidity -Path $invalidInterfaceManagerPath
            
            # VÃ©rifier que la validation a Ã©chouÃ©
            return $result -eq $false
        }
    },
    @{
        Name = "Test de Test-ManagerValidity avec options de validation"
        Test = {
            # Valider le gestionnaire Ã  interface invalide avec option d'ignorer les fonctions manquantes
            $result = Test-ManagerValidity -Path $invalidInterfaceManagerPath -ValidationOptions @{ IgnoreMissingFunctions = $true }
            
            # VÃ©rifier que la validation a rÃ©ussi malgrÃ© l'interface invalide
            return $result -eq $true
        }
    },
    @{
        Name = "Test de Test-ManagerInterface avec gestionnaire valide"
        Test = {
            # VÃ©rifier l'interface du gestionnaire valide
            $result = Test-ManagerInterface -Path $validManagerPath -RequiredFunctions @("Start-ValidManager", "Stop-ValidManager", "Get-ValidManagerStatus")
            
            # VÃ©rifier que la vÃ©rification a rÃ©ussi
            return $result -eq $true
        }
    },
    @{
        Name = "Test de Test-ManagerInterface avec gestionnaire Ã  interface invalide"
        Test = {
            # VÃ©rifier l'interface du gestionnaire Ã  interface invalide
            $result = Test-ManagerInterface -Path $invalidInterfaceManagerPath -RequiredFunctions @("Start-InvalidInterfaceManager", "Stop-InvalidInterfaceManager", "Get-InvalidInterfaceManagerStatus")
            
            # VÃ©rifier que la vÃ©rification a Ã©chouÃ©
            return $result -eq $false
        }
    },
    @{
        Name = "Test de Test-ManagerFunctionality avec gestionnaire valide"
        Test = {
            # Tester la fonctionnalitÃ© du gestionnaire valide
            $result = Test-ManagerFunctionality -Path $validManagerPath -TestParameters @{ Command = "Status" }
            
            # VÃ©rifier que le test a rÃ©ussi
            return $result -eq $true
        }
    }
)

# ExÃ©cuter les tests
$totalTests = $tests.Count
$passedTests = 0
$failedTests = 0

Write-Host "ExÃ©cution de $totalTests tests unitaires pour le module ValidationService..." -ForegroundColor Cyan

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
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}

# Retourner le rÃ©sultat global
if ($failedTests -eq 0) {
    Write-Host "`nTous les tests ont rÃ©ussi !" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont Ã©chouÃ©." -ForegroundColor Red
    exit 1
}
