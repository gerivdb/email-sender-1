<#
.SYNOPSIS
    Tests unitaires pour le module ManifestParser.

.DESCRIPTION
    Ce script exécute des tests unitaires pour vérifier le bon fonctionnement
    du module ManifestParser.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1
#>

# Définir le chemin du module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\ManifestParser\ManifestParser.psm1"

# Vérifier que le module existe
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Le module ManifestParser est introuvable à l'emplacement : $modulePath"
    exit 1
}

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Créer un gestionnaire de test
$testManagerPath = Join-Path -Path $testDir -ChildPath "test-manager.ps1"
Set-Content -Path $testManagerPath -Value @"
<#
.SYNOPSIS
    Gestionnaire de test pour les tests unitaires.

.DESCRIPTION
    Ce script est un gestionnaire de test utilisé pour les tests unitaires
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
    
    Write-Host "Démarrage du gestionnaire de test..."
}

function Stop-TestManager {
    [CmdletBinding()]
    param()
    
    Write-Host "Arrêt du gestionnaire de test..."
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
    
    Write-Host "Configuration mise à jour."
}

# Exécuter la commande spécifiée
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

# Créer un fichier de manifeste JSON pour les tests
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

# Créer un script avec un manifeste intégré dans les commentaires
$testManagerWithManifestPath = Join-Path -Path $testDir -ChildPath "test-manager-with-manifest.ps1"
Set-Content -Path $testManagerWithManifestPath -Value @"
<#
.SYNOPSIS
    Gestionnaire de test avec manifeste intégré.

.DESCRIPTION
    Ce script est un gestionnaire de test avec un manifeste intégré
    utilisé pour les tests unitaires du module ManifestParser.

.MANIFEST
{
    "Name": "TestManagerWithManifest",
    "Description": "Un gestionnaire de test avec manifeste intégré",
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
    
    Write-Host "Démarrage du gestionnaire de test avec manifeste intégré..."
}

function Stop-TestManagerWithManifest {
    [CmdletBinding()]
    param()
    
    Write-Host "Arrêt du gestionnaire de test avec manifeste intégré..."
}

# Exécuter la commande spécifiée
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

# Définir les tests unitaires
$tests = @(
    @{
        Name = "Test de Get-ManagerManifest avec fichier JSON"
        Test = {
            # Extraire le manifeste du fichier JSON
            $manifest = Get-ManagerManifest -Path $testManagerPath -ManifestPath $testManifestJsonPath
            
            # Vérifier que le manifeste est extrait correctement
            if (-not $manifest) {
                return $false
            }
            
            # Vérifier les propriétés du manifeste
            return $manifest.Name -eq "TestManager" -and $manifest.Version -eq "1.0.0" -and $manifest.Author -eq "EMAIL_SENDER_1"
        }
    },
    @{
        Name = "Test de Get-ManagerManifest avec manifeste intégré"
        Test = {
            # Extraire le manifeste du script avec manifeste intégré
            $manifest = Get-ManagerManifest -Path $testManagerWithManifestPath
            
            # Vérifier que le manifeste est extrait correctement
            if (-not $manifest) {
                return $false
            }
            
            # Vérifier les propriétés du manifeste
            return $manifest.Name -eq "TestManagerWithManifest" -and $manifest.Version -eq "1.1.0" -and $manifest.Author -eq "EMAIL_SENDER_1"
        }
    },
    @{
        Name = "Test de Get-ManagerManifest avec génération automatique"
        Test = {
            # Extraire le manifeste du script sans manifeste explicite
            $manifest = Get-ManagerManifest -Path $testManagerPath
            
            # Vérifier que le manifeste est généré correctement
            if (-not $manifest) {
                return $false
            }
            
            # Vérifier les propriétés du manifeste
            return $manifest.Name -eq "test-manager" -and $manifest.Version -eq "1.0.0"
        }
    },
    @{
        Name = "Test de Test-ManifestValidity avec manifeste valide"
        Test = {
            # Extraire le manifeste du fichier JSON
            $manifest = Get-ManagerManifest -Path $testManagerPath -ManifestPath $testManifestJsonPath
            
            # Vérifier la validité du manifeste
            return Test-ManifestValidity -Manifest $manifest
        }
    },
    @{
        Name = "Test de Test-ManifestValidity avec manifeste invalide"
        Test = {
            # Créer un manifeste invalide (sans nom)
            $invalidManifest = @{
                Description = "Un manifeste invalide"
                Version = "1.0.0"
            }
            
            # Vérifier que le manifeste est détecté comme invalide
            return -not (Test-ManifestValidity -Manifest $invalidManifest)
        }
    },
    @{
        Name = "Test de Convert-ToManifest"
        Test = {
            # Générer un manifeste à partir du script
            $outputPath = Join-Path -Path $testDir -ChildPath "generated-manifest.json"
            $manifest = Convert-ToManifest -Path $testManagerPath -OutputPath $outputPath
            
            # Vérifier que le manifeste est généré correctement
            if (-not $manifest) {
                return $false
            }
            
            # Vérifier que le fichier de manifeste est créé
            if (-not (Test-Path -Path $outputPath)) {
                return $false
            }
            
            # Vérifier les propriétés du manifeste
            return $manifest.Name -eq "test-manager" -and $manifest.Version -eq "1.0.0" -and $manifest.Capabilities -contains "Startable"
        }
    }
)

# Exécuter les tests
$totalTests = $tests.Count
$passedTests = 0
$failedTests = 0

Write-Host "Exécution de $totalTests tests unitaires pour le module ManifestParser..." -ForegroundColor Cyan

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
