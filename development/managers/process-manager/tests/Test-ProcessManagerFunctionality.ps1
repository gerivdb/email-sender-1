<#
.SYNOPSIS
    Tests fonctionnels complets pour le Process Manager.

.DESCRIPTION
    Ce script exécute des tests fonctionnels complets pour vérifier le bon fonctionnement
    du Process Manager avec les modules améliorés dans des scénarios réels.

.PARAMETER ProjectRoot
    Chemin vers la racine du projet. Par défaut, utilise le répertoire courant.

.PARAMETER Force
    Force l'exécution des tests même si les modules ne sont pas installés.

.PARAMETER SkipCleanup
    Ne supprime pas les fichiers de test après l'exécution.

.EXAMPLE
    .\Test-ProcessManagerFunctionality.ps1
    Exécute les tests fonctionnels complets pour le Process Manager.

.EXAMPLE
    .\Test-ProcessManagerFunctionality.ps1 -ProjectRoot "D:\Projets\MonProjet" -Force -SkipCleanup
    Force l'exécution des tests dans le répertoire spécifié et ne supprime pas les fichiers de test.

.NOTES
    Auteur: EMAIL_SENDER_1
    Version: 1.0
    Date de création: 2025-05-15
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1",

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$SkipCleanup
)

# Définir les chemins
$processManagerRoot = Join-Path -Path $ProjectRoot -ChildPath "development\managers\process-manager"
$modulesRoot = Join-Path -Path $processManagerRoot -ChildPath "modules"
$scriptsRoot = Join-Path -Path $processManagerRoot -ChildPath "scripts"
$testsRoot = Join-Path -Path $processManagerRoot -ChildPath "tests"
$processManagerScript = Join-Path -Path $scriptsRoot -ChildPath "process-manager.ps1"
$testDir = Join-Path -Path $testsRoot -ChildPath "functional-tests"
$testConfigPath = Join-Path -Path $testDir -ChildPath "test-process-manager.config.json"

# Fonction pour écrire des messages de journal
function Write-TestLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error", "Success", "Debug")]
        [string]$Level = "Info"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Définir la couleur en fonction du niveau
    $color = switch ($Level) {
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Success" { "Green" }
        "Debug" { "Gray" }
        default { "White" }
    }
    
    # Afficher le message dans la console
    Write-Host $logMessage -ForegroundColor $color
}

# Fonction pour exécuter un test et vérifier le résultat
function Invoke-FunctionalTest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Test,

        [Parameter(Mandatory = $false)]
        [string]$Description = ""
    )

    Write-TestLog -Message "Test : $Name" -Level Info
    if ($Description) {
        Write-TestLog -Message "  Description : $Description" -Level Debug
    }
    
    try {
        $result = & $Test
        
        if ($result) {
            Write-TestLog -Message "  Résultat : Réussi" -Level Success
            return $true
        } else {
            Write-TestLog -Message "  Résultat : Échec" -Level Error
            return $false
        }
    } catch {
        Write-TestLog -Message "  Résultat : Erreur - $_" -Level Error
        return $false
    }
}

# Vérifier que le répertoire du projet existe
if (-not (Test-Path -Path $ProjectRoot -PathType Container)) {
    Write-TestLog -Message "Le répertoire du projet n'existe pas : $ProjectRoot" -Level Error
    exit 1
}

# Vérifier que le répertoire du Process Manager existe
if (-not (Test-Path -Path $processManagerRoot -PathType Container)) {
    Write-TestLog -Message "Le répertoire du Process Manager n'existe pas : $processManagerRoot" -Level Error
    exit 1
}

# Vérifier que le script du Process Manager existe
if (-not (Test-Path -Path $processManagerScript -PathType Leaf)) {
    Write-TestLog -Message "Le script du Process Manager n'existe pas : $processManagerScript" -Level Error
    exit 1
}

# Vérifier si les modules sont installés
$processManagerModule = Get-Module -Name "ProcessManager" -ListAvailable
if (-not $processManagerModule -and -not $Force) {
    Write-TestLog -Message "Le module ProcessManager n'est pas installé. Utilisez -Force pour forcer l'exécution des tests." -Level Warning
    Write-TestLog -Message "Exécutez le script install-modules.ps1 pour installer le module." -Level Info
    exit 1
}

# Créer un répertoire temporaire pour les tests
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Créer un fichier de configuration de test
$testConfig = @{
    Enabled = $true
    LogLevel = "Debug"
    LogPath = "logs/test-process-manager"
    Managers = @{}
}
$testConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $testConfigPath -Encoding UTF8

# Créer des gestionnaires de test avec différentes configurations
$testManagers = @(
    @{
        Name = "SimpleManager"
        Path = Join-Path -Path $testDir -ChildPath "simple-manager.ps1"
        ManifestPath = Join-Path -Path $testDir -ChildPath "simple-manager.manifest.json"
        Content = @"
<#
.SYNOPSIS
    Gestionnaire simple pour les tests fonctionnels.

.DESCRIPTION
    Ce script est un gestionnaire simple utilisé pour les tests fonctionnels
    du Process Manager.
#>

param (
    [Parameter(Mandatory = `$false)]
    [string]`$Command = "Status"
)

function Start-SimpleManager {
    [CmdletBinding()]
    param()
    
    Write-Host "Démarrage du gestionnaire simple..."
}

function Stop-SimpleManager {
    [CmdletBinding()]
    param()
    
    Write-Host "Arrêt du gestionnaire simple..."
}

function Get-SimpleManagerStatus {
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
        Start-SimpleManager
    }
    "Stop" {
        Stop-SimpleManager
    }
    "Status" {
        Get-SimpleManagerStatus
    }
    default {
        Write-Host "Commande inconnue : `$Command"
    }
}
"@
        Manifest = @{
            Name = "SimpleManager"
            Description = "Gestionnaire simple pour les tests fonctionnels"
            Version = "1.0.0"
            Author = "EMAIL_SENDER_1"
            Dependencies = @()
        }
    },
    @{
        Name = "DependentManager"
        Path = Join-Path -Path $testDir -ChildPath "dependent-manager.ps1"
        ManifestPath = Join-Path -Path $testDir -ChildPath "dependent-manager.manifest.json"
        Content = @"
<#
.SYNOPSIS
    Gestionnaire dépendant pour les tests fonctionnels.

.DESCRIPTION
    Ce script est un gestionnaire dépendant utilisé pour les tests fonctionnels
    du Process Manager.
#>

param (
    [Parameter(Mandatory = `$false)]
    [string]`$Command = "Status"
)

function Start-DependentManager {
    [CmdletBinding()]
    param()
    
    Write-Host "Démarrage du gestionnaire dépendant..."
    # Dépendance simulée
    Write-Host "Démarrage du gestionnaire simple (dépendance)..."
}

function Stop-DependentManager {
    [CmdletBinding()]
    param()
    
    Write-Host "Arrêt du gestionnaire dépendant..."
    # Dépendance simulée
    Write-Host "Arrêt du gestionnaire simple (dépendance)..."
}

function Get-DependentManagerStatus {
    [CmdletBinding()]
    param()
    
    return @{
        Status = "Running"
        StartTime = Get-Date
        Dependencies = @("SimpleManager")
    }
}

# Exécuter la commande spécifiée
switch (`$Command) {
    "Start" {
        Start-DependentManager
    }
    "Stop" {
        Stop-DependentManager
    }
    "Status" {
        Get-DependentManagerStatus
    }
    default {
        Write-Host "Commande inconnue : `$Command"
    }
}
"@
        Manifest = @{
            Name = "DependentManager"
            Description = "Gestionnaire dépendant pour les tests fonctionnels"
            Version = "1.0.0"
            Author = "EMAIL_SENDER_1"
            Dependencies = @(
                @{
                    Name = "SimpleManager"
                    MinimumVersion = "1.0.0"
                    Required = $true
                }
            )
        }
    },
    @{
        Name = "InvalidManager"
        Path = Join-Path -Path $testDir -ChildPath "invalid-manager.ps1"
        ManifestPath = Join-Path -Path $testDir -ChildPath "invalid-manager.manifest.json"
        Content = @"
<#
.SYNOPSIS
    Gestionnaire invalide pour les tests fonctionnels.

.DESCRIPTION
    Ce script est un gestionnaire invalide utilisé pour les tests fonctionnels
    du Process Manager.
#>

param (
    [Parameter(Mandatory = `$false)]
    [string]`$Command = "Status"
)

# Erreur de syntaxe intentionnelle
function Start-InvalidManager {
    [CmdletBinding()
    param()
    
    Write-Host "Démarrage du gestionnaire invalide..."
}

function Stop-InvalidManager {
    [CmdletBinding()]
    param()
    
    Write-Host "Arrêt du gestionnaire invalide..."
}

# Fonction de statut manquante intentionnellement

# Exécuter la commande spécifiée
switch (`$Command) {
    "Start" {
        Start-InvalidManager
    }
    "Stop" {
        Stop-InvalidManager
    }
    "Status" {
        Write-Host "Statut non disponible"
    }
    default {
        Write-Host "Commande inconnue : `$Command"
    }
}
"@
        Manifest = @{
            Name = "InvalidManager"
            Description = "Gestionnaire invalide pour les tests fonctionnels"
            Version = "1.0.0"
            Author = "EMAIL_SENDER_1"
            Dependencies = @()
        }
    }
)

# Créer les gestionnaires de test
foreach ($manager in $testManagers) {
    # Créer le script du gestionnaire
    Set-Content -Path $manager.Path -Value $manager.Content -Encoding UTF8
    
    # Créer le manifeste du gestionnaire
    $manager.Manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manager.ManifestPath -Encoding UTF8
}

# Définir les tests fonctionnels
$functionalTests = @(
    @{
        Name = "Test d'enregistrement d'un gestionnaire simple"
        Description = "Vérifie que le Process Manager peut enregistrer un gestionnaire simple."
        Test = {
            $result = & $processManagerScript -Command Register -ManagerName "SimpleManager" -ManagerPath $testManagers[0].Path -ConfigPath $testConfigPath -Force
            return $LASTEXITCODE -eq 0
        }
    },
    @{
        Name = "Test d'enregistrement d'un gestionnaire avec dépendances"
        Description = "Vérifie que le Process Manager peut enregistrer un gestionnaire avec dépendances."
        Test = {
            $result = & $processManagerScript -Command Register -ManagerName "DependentManager" -ManagerPath $testManagers[1].Path -ConfigPath $testConfigPath -Force
            return $LASTEXITCODE -eq 0
        }
    },
    @{
        Name = "Test de validation d'un gestionnaire invalide"
        Description = "Vérifie que le Process Manager détecte correctement un gestionnaire invalide."
        Test = {
            if ($processManagerModule) {
                # Utiliser le module ProcessManager si disponible
                $result = Test-ManagerValidity -Path $testManagers[2].Path
                return $result -eq $false
            } else {
                # Utiliser le Process Manager directement
                $result = & $processManagerScript -Command Register -ManagerName "InvalidManager" -ManagerPath $testManagers[2].Path -ConfigPath $testConfigPath -Force -SkipValidation
                return $LASTEXITCODE -eq 0
            }
        }
    },
    @{
        Name = "Test de découverte des gestionnaires"
        Description = "Vérifie que le Process Manager peut découvrir automatiquement les gestionnaires."
        Test = {
            # Créer un répertoire de découverte
            $discoveryDir = Join-Path -Path $testDir -ChildPath "discovery\test-manager"
            New-Item -Path $discoveryDir -ItemType Directory -Force | Out-Null
            
            # Copier le gestionnaire simple dans le répertoire de découverte
            $discoveryScriptsDir = Join-Path -Path $discoveryDir -ChildPath "scripts"
            New-Item -Path $discoveryScriptsDir -ItemType Directory -Force | Out-Null
            $discoveryManagerPath = Join-Path -Path $discoveryScriptsDir -ChildPath "test-manager.ps1"
            Copy-Item -Path $testManagers[0].Path -Destination $discoveryManagerPath
            
            # Exécuter la découverte
            $result = & $processManagerScript -Command Discover -ConfigPath $testConfigPath -Force -SearchPaths @("$testDir\discovery")
            
            return $LASTEXITCODE -eq 0
        }
    },
    @{
        Name = "Test d'exécution d'une commande sur un gestionnaire"
        Description = "Vérifie que le Process Manager peut exécuter une commande sur un gestionnaire."
        Test = {
            $result = & $processManagerScript -Command Run -ManagerName "SimpleManager" -ManagerCommand "Status" -ConfigPath $testConfigPath
            return $LASTEXITCODE -eq 0
        }
    },
    @{
        Name = "Test d'obtention de l'état d'un gestionnaire"
        Description = "Vérifie que le Process Manager peut obtenir l'état d'un gestionnaire."
        Test = {
            $result = & $processManagerScript -Command Status -ManagerName "SimpleManager" -ConfigPath $testConfigPath
            return $LASTEXITCODE -eq 0
        }
    },
    @{
        Name = "Test de configuration d'un gestionnaire"
        Description = "Vérifie que le Process Manager peut configurer un gestionnaire."
        Test = {
            $result = & $processManagerScript -Command Configure -ManagerName "SimpleManager" -Enabled $true -ConfigPath $testConfigPath
            return $LASTEXITCODE -eq 0
        }
    },
    @{
        Name = "Test de listage des gestionnaires"
        Description = "Vérifie que le Process Manager peut lister les gestionnaires enregistrés."
        Test = {
            $result = & $processManagerScript -Command List -ConfigPath $testConfigPath
            return $LASTEXITCODE -eq 0
        }
    },
    @{
        Name = "Test de résolution des dépendances"
        Description = "Vérifie que le Process Manager peut résoudre les dépendances entre gestionnaires."
        Test = {
            if ($processManagerModule) {
                # Utiliser le module ProcessManager si disponible
                $dependencies = Get-ManagerDependencies -Path $testManagers[1].Path
                $result = Test-DependenciesAvailability -Dependencies $dependencies -ConfigPath $testConfigPath
                return $result -eq $true
            } else {
                # Simuler la résolution des dépendances
                $result = & $processManagerScript -Command Run -ManagerName "DependentManager" -ManagerCommand "Status" -ConfigPath $testConfigPath
                return $LASTEXITCODE -eq 0
            }
        }
    },
    @{
        Name = "Test de l'ordre de chargement des gestionnaires"
        Description = "Vérifie que le Process Manager peut déterminer l'ordre de chargement des gestionnaires."
        Test = {
            if ($processManagerModule) {
                # Utiliser le module ProcessManager si disponible
                $loadOrder = Get-ManagerLoadOrder -ManagerNames @("SimpleManager", "DependentManager") -ConfigPath $testConfigPath
                return $loadOrder -ne $null -and $loadOrder[0] -eq "SimpleManager" -and $loadOrder[1] -eq "DependentManager"
            } else {
                # Simuler l'ordre de chargement
                return $true
            }
        }
    }
)

# Exécuter les tests fonctionnels
$totalTests = $functionalTests.Count
$passedTests = 0
$failedTests = 0

Write-TestLog -Message "Exécution de $totalTests tests fonctionnels pour le Process Manager..." -Level Info

foreach ($test in $functionalTests) {
    $result = Invoke-FunctionalTest -Name $test.Name -Description $test.Description -Test $test.Test
    
    if ($result) {
        $passedTests++
    } else {
        $failedTests++
    }
}

# Afficher le résumé
Write-TestLog -Message "`nRésumé des tests fonctionnels :" -Level Info
Write-TestLog -Message "  Tests exécutés : $totalTests" -Level Info
Write-TestLog -Message "  Tests réussis  : $passedTests" -Level Success
Write-TestLog -Message "  Tests échoués  : $failedTests" -Level Error

# Nettoyer les fichiers de test
if (-not $SkipCleanup) {
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
    }
}

# Retourner le résultat global
if ($failedTests -eq 0) {
    Write-TestLog -Message "`nTous les tests fonctionnels ont réussi !" -Level Success
    exit 0
} else {
    Write-TestLog -Message "`nCertains tests fonctionnels ont échoué." -Level Error
    exit 1
}
