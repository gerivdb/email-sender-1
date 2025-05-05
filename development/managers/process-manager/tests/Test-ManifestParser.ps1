<#
.SYNOPSIS
    Tests unitaires pour le module ManifestParser.

.DESCRIPTION
    Ce script exÃ©cute des tests unitaires pour vÃ©rifier le bon fonctionnement
    du module ManifestParser.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1
#>

# DÃ©finir le chemin du module Ã  tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\ManifestParser\ManifestParser.psm1"

# VÃ©rifier que le module existe
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Le module ManifestParser est introuvable Ã  l'emplacement : $modulePath"
    exit 1
}

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un gestionnaire de test
$testManagerPath = Join-Path -Path $testDir -ChildPath "test-manager.ps1"
Set-Content -Path $testManagerPath -Value @"
<#
.SYNOPSIS
    Gestionnaire de test pour les tests unitaires.

.DESCRIPTION
    Ce script est un gestionnaire de test utilisÃ© pour les tests unitaires
    du module ManifestParser.

.VERSION
    1.0.0

.AUTHOR
    EMAIL_SENDER_1
#>

param (
    [Parameter(Mandatory = `$false)]
    [string]`$Command = "Status"
)

# Importer les modules requis
Import-Module "TestModule"

function Start-TestManager {
    [CmdletBinding()]
    param()
    
    Write-Host "DÃ©marrage du gestionnaire de test..."
}

function Stop-TestManager {
    [CmdletBinding()]
    param()
    
    Write-Host "ArrÃªt du gestionnaire de test..."
}

function Get-TestManagerStatus {
    [CmdletBinding()]
    param()
    
    return @{
        Status = "Running"
        StartTime = Get-Date
    }
}

function Get-TestManagerConfiguration {
    [CmdletBinding()]
    param()
    
    return @{
        LogLevel = "Info"
        MaxThreads = 4
    }
}

function Set-TestManagerConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = `$false)]
        [string]`$LogLevel,
        
        [Parameter(Mandatory = `$false)]
        [int]`$MaxThreads
    )
    
    Write-Host "Configuration mise Ã  jour."
}

# ExÃ©cuter la commande spÃ©cifiÃ©e
switch (`$Command) {
    "Start" {
        Start-TestManager
    }
    "Stop" {
        Stop-TestManager
    }
    "Status" {
        Get-TestManagerStatus
    }
    default {
        Write-Host "Commande inconnue : `$Command"
    }
}
"@

# CrÃ©er un fichier de manifeste JSON pour les tests
$testManifestJsonPath = Join-Path -Path $testDir -ChildPath "test-manager.manifest.json"
Set-Content -Path $testManifestJsonPath -Value @"
{
    "Name": "TestManager",
    "Description": "Un gestionnaire de test pour les tests unitaires",
    "Version": "1.0.0",
    "Author": "EMAIL_SENDER_1",
    "Contact": "contact@email-sender-1.com",
    "License": "MIT",
    "RequiredPowerShellVersion": "5.1",
    "Dependencies": [
        {
            "Name": "TestModule",
            "MinimumVersion": "1.0.0",
            "Required": true
        }
    ],
    "Capabilities": [
        "Startable",
        "Stoppable",
        "StatusReporting",
        "Configurable"
    ],
    "EntryPoint": "Start-TestManager",
    "StopFunction": "Stop-TestManager"
}
"@

# CrÃ©er un script avec un manifeste intÃ©grÃ© dans les commentaires
$testManagerWithManifestPath = Join-Path -Path $testDir -ChildPath "test-manager-with-manifest.ps1"
Set-Content -Path $testManagerWithManifestPath -Value @"
<#
.SYNOPSIS
    Gestionnaire de test avec manifeste intÃ©grÃ©.

.DESCRIPTION
    Ce script est un gestionnaire de test avec un manifeste intÃ©grÃ©
    utilisÃ© pour les tests unitaires du module ManifestParser.

.MANIFEST
{
    "Name": "TestManagerWithManifest",
    "Description": "Un gestionnaire de test avec manifeste intÃ©grÃ©",
    "Version": "1.1.0",
    "Author": "EMAIL_SENDER_1",
    "Dependencies": [
        {
            "Name": "TestModule",
            "MinimumVersion": "1.0.0",
            "Required": true
        }
    ],
    "Capabilities": [
        "Startable",
        "Stoppable"
    ]
}
#>

param (
    [Parameter(Mandatory = `$false)]
    [string]`$Command = "Status"
)

function Start-TestManagerWithManifest {
    [CmdletBinding()]
    param()
    
    Write-Host "DÃ©marrage du gestionnaire de test avec manifeste intÃ©grÃ©..."
}

function Stop-TestManagerWithManifest {
    [CmdletBinding()]
    param()
    
    Write-Host "ArrÃªt du gestionnaire de test avec manifeste intÃ©grÃ©..."
}

# ExÃ©cuter la commande spÃ©cifiÃ©e
switch (`$Command) {
    "Start" {
        Start-TestManagerWithManifest
    }
    "Stop" {
        Stop-TestManagerWithManifest
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
        Name = "Test de Get-ManagerManifest avec fichier JSON"
        Test = {
            # Extraire le manifeste du fichier JSON
            $manifest = Get-ManagerManifest -Path $testManagerPath -ManifestPath $testManifestJsonPath
            
            # VÃ©rifier que le manifeste est extrait correctement
            if (-not $manifest) {
                return $false
            }
            
            # VÃ©rifier les propriÃ©tÃ©s du manifeste
            return $manifest.Name -eq "TestManager" -and $manifest.Version -eq "1.0.0" -and $manifest.Author -eq "EMAIL_SENDER_1"
        }
    },
    @{
        Name = "Test de Get-ManagerManifest avec manifeste intÃ©grÃ©"
        Test = {
            # Extraire le manifeste du script avec manifeste intÃ©grÃ©
            $manifest = Get-ManagerManifest -Path $testManagerWithManifestPath
            
            # VÃ©rifier que le manifeste est extrait correctement
            if (-not $manifest) {
                return $false
            }
            
            # VÃ©rifier les propriÃ©tÃ©s du manifeste
            return $manifest.Name -eq "TestManagerWithManifest" -and $manifest.Version -eq "1.1.0" -and $manifest.Author -eq "EMAIL_SENDER_1"
        }
    },
    @{
        Name = "Test de Get-ManagerManifest avec gÃ©nÃ©ration automatique"
        Test = {
            # Extraire le manifeste du script sans manifeste explicite
            $manifest = Get-ManagerManifest -Path $testManagerPath
            
            # VÃ©rifier que le manifeste est gÃ©nÃ©rÃ© correctement
            if (-not $manifest) {
                return $false
            }
            
            # VÃ©rifier les propriÃ©tÃ©s du manifeste
            return $manifest.Name -eq "test-manager" -and $manifest.Version -eq "1.0.0"
        }
    },
    @{
        Name = "Test de Test-ManifestValidity avec manifeste valide"
        Test = {
            # Extraire le manifeste du fichier JSON
            $manifest = Get-ManagerManifest -Path $testManagerPath -ManifestPath $testManifestJsonPath
            
            # VÃ©rifier la validitÃ© du manifeste
            return Test-ManifestValidity -Manifest $manifest
        }
    },
    @{
        Name = "Test de Test-ManifestValidity avec manifeste invalide"
        Test = {
            # CrÃ©er un manifeste invalide (sans nom)
            $invalidManifest = @{
                Description = "Un manifeste invalide"
                Version = "1.0.0"
            }
            
            # VÃ©rifier que le manifeste est dÃ©tectÃ© comme invalide
            return -not (Test-ManifestValidity -Manifest $invalidManifest)
        }
    },
    @{
        Name = "Test de Convert-ToManifest"
        Test = {
            # GÃ©nÃ©rer un manifeste Ã  partir du script
            $outputPath = Join-Path -Path $testDir -ChildPath "generated-manifest.json"
            $manifest = Convert-ToManifest -Path $testManagerPath -OutputPath $outputPath
            
            # VÃ©rifier que le manifeste est gÃ©nÃ©rÃ© correctement
            if (-not $manifest) {
                return $false
            }
            
            # VÃ©rifier que le fichier de manifeste est crÃ©Ã©
            if (-not (Test-Path -Path $outputPath)) {
                return $false
            }
            
            # VÃ©rifier les propriÃ©tÃ©s du manifeste
            return $manifest.Name -eq "test-manager" -and $manifest.Version -eq "1.0.0" -and $manifest.Capabilities -contains "Startable"
        }
    }
)

# ExÃ©cuter les tests
$totalTests = $tests.Count
$passedTests = 0
$failedTests = 0

Write-Host "ExÃ©cution de $totalTests tests unitaires pour le module ManifestParser..." -ForegroundColor Cyan

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
