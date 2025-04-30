<#
.SYNOPSIS
    Tests unitaires pour le module DependencyResolver.

.DESCRIPTION
    Ce script exécute des tests unitaires pour vérifier le bon fonctionnement
    du module DependencyResolver.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1
#>

# Définir le chemin du module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\DependencyResolver\DependencyResolver.psm1"

# Vérifier que le module existe
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Le module DependencyResolver est introuvable à l'emplacement : $modulePath"
    exit 1
}

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Créer un fichier de configuration de test
$testConfigPath = Join-Path -Path $testDir -ChildPath "test-dependency.config.json"
$testConfig = @{
    Managers = @{
        ManagerA = @{
            Path = Join-Path -Path $testDir -ChildPath "manager-a.ps1"
            Version = "1.0.0"
            Enabled = $true
        }
        ManagerB = @{
            Path = Join-Path -Path $testDir -ChildPath "manager-b.ps1"
            Version = "1.1.0"
            Enabled = $true
        }
        ManagerC = @{
            Path = Join-Path -Path $testDir -ChildPath "manager-c.ps1"
            Version = "2.0.0"
            Enabled = $true
        }
    }
}
$testConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $testConfigPath -Encoding UTF8

# Créer des gestionnaires de test avec des dépendances
$managerAPath = Join-Path -Path $testDir -ChildPath "manager-a.ps1"
Set-Content -Path $managerAPath -Value @"
<#
.SYNOPSIS
    Gestionnaire A pour les tests unitaires.

.DESCRIPTION
    Ce script est un gestionnaire de test utilisé pour les tests unitaires
    du module DependencyResolver.

.MANIFEST
{
    "Name": "ManagerA",
    "Description": "Gestionnaire A pour les tests unitaires",
    "Version": "1.0.0",
    "Author": "EMAIL_SENDER_1",
    "Dependencies": [
        {
            "Name": "ManagerB",
            "MinimumVersion": "1.0.0",
            "Required": true
        }
    ]
}
#>

param (
    [Parameter(Mandatory = `$false)]
    [string]`$Command = "Status"
)

# Importer les dépendances
Import-Module "ManagerB"

function Start-ManagerA {
    [CmdletBinding()]
    param()
    
    Write-Host "Démarrage du gestionnaire A..."
    Start-ManagerB
}

function Stop-ManagerA {
    [CmdletBinding()]
    param()
    
    Write-Host "Arrêt du gestionnaire A..."
    Stop-ManagerB
}

function Get-ManagerAStatus {
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
        Start-ManagerA
    }
    "Stop" {
        Stop-ManagerA
    }
    "Status" {
        Get-ManagerAStatus
    }
    default {
        Write-Host "Commande inconnue : `$Command"
    }
}
"@

$managerBPath = Join-Path -Path $testDir -ChildPath "manager-b.ps1"
Set-Content -Path $managerBPath -Value @"
<#
.SYNOPSIS
    Gestionnaire B pour les tests unitaires.

.DESCRIPTION
    Ce script est un gestionnaire de test utilisé pour les tests unitaires
    du module DependencyResolver.

.MANIFEST
{
    "Name": "ManagerB",
    "Description": "Gestionnaire B pour les tests unitaires",
    "Version": "1.1.0",
    "Author": "EMAIL_SENDER_1",
    "Dependencies": [
        {
            "Name": "ManagerC",
            "MinimumVersion": "1.5.0",
            "MaximumVersion": "2.5.0",
            "Required": true
        }
    ]
}
#>

param (
    [Parameter(Mandatory = `$false)]
    [string]`$Command = "Status"
)

# Importer les dépendances
Import-Module "ManagerC"

function Start-ManagerB {
    [CmdletBinding()]
    param()
    
    Write-Host "Démarrage du gestionnaire B..."
    Start-ManagerC
}

function Stop-ManagerB {
    [CmdletBinding()]
    param()
    
    Write-Host "Arrêt du gestionnaire B..."
    Stop-ManagerC
}

function Get-ManagerBStatus {
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
        Start-ManagerB
    }
    "Stop" {
        Stop-ManagerB
    }
    "Status" {
        Get-ManagerBStatus
    }
    default {
        Write-Host "Commande inconnue : `$Command"
    }
}
"@

$managerCPath = Join-Path -Path $testDir -ChildPath "manager-c.ps1"
Set-Content -Path $managerCPath -Value @"
<#
.SYNOPSIS
    Gestionnaire C pour les tests unitaires.

.DESCRIPTION
    Ce script est un gestionnaire de test utilisé pour les tests unitaires
    du module DependencyResolver.

.MANIFEST
{
    "Name": "ManagerC",
    "Description": "Gestionnaire C pour les tests unitaires",
    "Version": "2.0.0",
    "Author": "EMAIL_SENDER_1",
    "Dependencies": []
}
#>

param (
    [Parameter(Mandatory = `$false)]
    [string]`$Command = "Status"
)

function Start-ManagerC {
    [CmdletBinding()]
    param()
    
    Write-Host "Démarrage du gestionnaire C..."
}

function Stop-ManagerC {
    [CmdletBinding()]
    param()
    
    Write-Host "Arrêt du gestionnaire C..."
}

function Get-ManagerCStatus {
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
        Start-ManagerC
    }
    "Stop" {
        Stop-ManagerC
    }
    "Status" {
        Get-ManagerCStatus
    }
    default {
        Write-Host "Commande inconnue : `$Command"
    }
}
"@

# Créer un gestionnaire avec des dépendances cycliques
$managerDPath = Join-Path -Path $testDir -ChildPath "manager-d.ps1"
Set-Content -Path $managerDPath -Value @"
<#
.SYNOPSIS
    Gestionnaire D pour les tests unitaires.

.DESCRIPTION
    Ce script est un gestionnaire de test utilisé pour les tests unitaires
    du module DependencyResolver.

.MANIFEST
{
    "Name": "ManagerD",
    "Description": "Gestionnaire D pour les tests unitaires",
    "Version": "1.0.0",
    "Author": "EMAIL_SENDER_1",
    "Dependencies": [
        {
            "Name": "ManagerE",
            "Required": true
        }
    ]
}
#>

param (
    [Parameter(Mandatory = `$false)]
    [string]`$Command = "Status"
)

# Importer les dépendances
Import-Module "ManagerE"

function Start-ManagerD {
    [CmdletBinding()]
    param()
    
    Write-Host "Démarrage du gestionnaire D..."
    Start-ManagerE
}

function Stop-ManagerD {
    [CmdletBinding()]
    param()
    
    Write-Host "Arrêt du gestionnaire D..."
    Stop-ManagerE
}

function Get-ManagerDStatus {
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
        Start-ManagerD
    }
    "Stop" {
        Stop-ManagerD
    }
    "Status" {
        Get-ManagerDStatus
    }
    default {
        Write-Host "Commande inconnue : `$Command"
    }
}
"@

$managerEPath = Join-Path -Path $testDir -ChildPath "manager-e.ps1"
Set-Content -Path $managerEPath -Value @"
<#
.SYNOPSIS
    Gestionnaire E pour les tests unitaires.

.DESCRIPTION
    Ce script est un gestionnaire de test utilisé pour les tests unitaires
    du module DependencyResolver.

.MANIFEST
{
    "Name": "ManagerE",
    "Description": "Gestionnaire E pour les tests unitaires",
    "Version": "1.0.0",
    "Author": "EMAIL_SENDER_1",
    "Dependencies": [
        {
            "Name": "ManagerD",
            "Required": true
        }
    ]
}
#>

param (
    [Parameter(Mandatory = `$false)]
    [string]`$Command = "Status"
)

# Importer les dépendances
Import-Module "ManagerD"

function Start-ManagerE {
    [CmdletBinding()]
    param()
    
    Write-Host "Démarrage du gestionnaire E..."
    Start-ManagerD
}

function Stop-ManagerE {
    [CmdletBinding()]
    param()
    
    Write-Host "Arrêt du gestionnaire E..."
    Stop-ManagerD
}

function Get-ManagerEStatus {
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
        Start-ManagerE
    }
    "Stop" {
        Stop-ManagerE
    }
    "Status" {
        Get-ManagerEStatus
    }
    default {
        Write-Host "Commande inconnue : `$Command"
    }
}
"@

# Mettre à jour la configuration pour inclure les gestionnaires D et E
$testConfig.Managers.ManagerD = @{
    Path = $managerDPath
    Version = "1.0.0"
    Enabled = $true
}
$testConfig.Managers.ManagerE = @{
    Path = $managerEPath
    Version = "1.0.0"
    Enabled = $true
}
$testConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $testConfigPath -Encoding UTF8

# Importer le module
Import-Module -Name $modulePath -Force

# Définir les tests unitaires
$tests = @(
    @{
        Name = "Test de Get-ManagerDependencies avec manifeste"
        Test = {
            # Extraire les dépendances du gestionnaire A
            $dependencies = Get-ManagerDependencies -Path $managerAPath
            
            # Vérifier que les dépendances sont extraites correctement
            if (-not $dependencies -or $dependencies.Count -eq 0) {
                return $false
            }
            
            # Vérifier les propriétés des dépendances
            return $dependencies[0].Name -eq "ManagerB" -and $dependencies[0].MinimumVersion -eq "1.0.0" -and $dependencies[0].Required -eq $true
        }
    },
    @{
        Name = "Test de Get-ManagerDependencies avec analyse manuelle"
        Test = {
            # Extraire les dépendances du gestionnaire A sans utiliser le manifeste
            $dependencies = Get-ManagerDependencies -Path $managerAPath
            
            # Vérifier que les dépendances sont extraites correctement
            if (-not $dependencies -or $dependencies.Count -eq 0) {
                return $false
            }
            
            # Vérifier que la dépendance à ManagerB est détectée
            return $dependencies | Where-Object { $_.Name -eq "ManagerB" } | Select-Object -First 1
        }
    },
    @{
        Name = "Test de Test-DependenciesAvailability avec dépendances disponibles"
        Test = {
            # Définir les dépendances à vérifier
            $dependencies = @(
                @{
                    Name = "ManagerB"
                    MinimumVersion = "1.0.0"
                    Required = $true
                }
            )
            
            # Vérifier la disponibilité des dépendances
            $result = Test-DependenciesAvailability -Dependencies $dependencies -ConfigPath $testConfigPath
            
            # Vérifier que la vérification a réussi
            return $result -eq $true
        }
    },
    @{
        Name = "Test de Test-DependenciesAvailability avec dépendances incompatibles"
        Test = {
            # Définir les dépendances à vérifier
            $dependencies = @(
                @{
                    Name = "ManagerB"
                    MinimumVersion = "2.0.0"
                    Required = $true
                }
            )
            
            # Vérifier la disponibilité des dépendances
            $result = Test-DependenciesAvailability -Dependencies $dependencies -ConfigPath $testConfigPath
            
            # Vérifier que la vérification a échoué
            return $result -eq $false
        }
    },
    @{
        Name = "Test de Resolve-DependencyConflicts avec dépendances compatibles"
        Test = {
            # Définir les dépendances à résoudre
            $dependencies = @(
                @{
                    Name = "ManagerC"
                    MinimumVersion = "1.5.0"
                    Required = $true
                },
                @{
                    Name = "ManagerC"
                    MaximumVersion = "2.5.0"
                    Required = $false
                }
            )
            
            # Résoudre les conflits de dépendances
            $resolvedDependencies = Resolve-DependencyConflicts -Dependencies $dependencies -ConfigPath $testConfigPath
            
            # Vérifier que la résolution a réussi
            if (-not $resolvedDependencies -or $resolvedDependencies.Count -eq 0) {
                return $false
            }
            
            # Vérifier les propriétés de la dépendance résolue
            return $resolvedDependencies[0].Name -eq "ManagerC" -and $resolvedDependencies[0].MinimumVersion -eq "1.5.0" -and $resolvedDependencies[0].MaximumVersion -eq "2.5.0" -and $resolvedDependencies[0].Required -eq $true
        }
    },
    @{
        Name = "Test de Resolve-DependencyConflicts avec dépendances incompatibles"
        Test = {
            # Définir les dépendances à résoudre
            $dependencies = @(
                @{
                    Name = "ManagerC"
                    MinimumVersion = "3.0.0"
                    Required = $true
                },
                @{
                    Name = "ManagerC"
                    MaximumVersion = "2.0.0"
                    Required = $true
                }
            )
            
            # Résoudre les conflits de dépendances
            $resolvedDependencies = Resolve-DependencyConflicts -Dependencies $dependencies -ConfigPath $testConfigPath
            
            # Vérifier que la résolution a échoué
            return $resolvedDependencies -eq $null
        }
    },
    @{
        Name = "Test de Get-ManagerLoadOrder avec dépendances linéaires"
        Test = {
            # Déterminer l'ordre de chargement des gestionnaires
            $loadOrder = Get-ManagerLoadOrder -ManagerNames @("ManagerA", "ManagerB", "ManagerC") -ConfigPath $testConfigPath
            
            # Vérifier que l'ordre de chargement est correct
            if (-not $loadOrder -or $loadOrder.Count -ne 3) {
                return $false
            }
            
            # Vérifier que l'ordre est correct (C -> B -> A)
            return $loadOrder[0] -eq "ManagerC" -and $loadOrder[1] -eq "ManagerB" -and $loadOrder[2] -eq "ManagerA"
        }
    },
    @{
        Name = "Test de Get-ManagerLoadOrder avec dépendances cycliques"
        Test = {
            # Déterminer l'ordre de chargement des gestionnaires avec dépendances cycliques
            $loadOrder = Get-ManagerLoadOrder -ManagerNames @("ManagerD", "ManagerE") -ConfigPath $testConfigPath
            
            # Vérifier que la détection de cycle a échoué
            return $loadOrder -eq $null
        }
    }
)

# Exécuter les tests
$totalTests = $tests.Count
$passedTests = 0
$failedTests = 0

Write-Host "Exécution de $totalTests tests unitaires pour le module DependencyResolver..." -ForegroundColor Cyan

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
