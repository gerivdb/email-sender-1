<#
.SYNOPSIS
    Script de test de l'intégration complète du Process Manager.

.DESCRIPTION
    Ce script teste l'intégration complète du Process Manager avec les modules améliorés.

.PARAMETER ProjectRoot
    Chemin vers la racine du projet. Par défaut, utilise le répertoire courant.

.PARAMETER Force
    Force l'exécution des tests même si les modules ne sont pas installés.

.EXAMPLE
    .\Test-Integration.ps1
    Teste l'intégration complète du Process Manager.

.EXAMPLE
    .\Test-Integration.ps1 -ProjectRoot "D:\Projets\MonProjet" -Force
    Force l'exécution des tests dans le répertoire spécifié.

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
    [switch]$Force
)

# Définir les chemins
$processManagerRoot = Join-Path -Path $ProjectRoot -ChildPath "development\managers\process-manager"
$modulesRoot = Join-Path -Path $processManagerRoot -ChildPath "modules"
$scriptsRoot = Join-Path -Path $processManagerRoot -ChildPath "scripts"
$testsRoot = Join-Path -Path $processManagerRoot -ChildPath "tests"
$processManagerScript = Join-Path -Path $scriptsRoot -ChildPath "process-manager.ps1"
$testDir = Join-Path -Path $testsRoot -ChildPath "temp"

# Fonction pour écrire des messages de journal
function Write-TestLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error", "Success")]
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
        default { "White" }
    }
    
    # Afficher le message dans la console
    Write-Host $logMessage -ForegroundColor $color
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

# Créer un gestionnaire de test
$testManagerPath = Join-Path -Path $testDir -ChildPath "test-manager.ps1"
Set-Content -Path $testManagerPath -Value @"
<#
.SYNOPSIS
    Gestionnaire de test pour les tests d'intégration.

.DESCRIPTION
    Ce script est un gestionnaire de test utilisé pour les tests d'intégration
    du Process Manager.

.MANIFEST
{
    "Name": "TestManager",
    "Description": "Gestionnaire de test pour les tests d'intégration",
    "Version": "1.0.0",
    "Author": "EMAIL_SENDER_1",
    "Dependencies": []
}
#>

param (
    [Parameter(Mandatory = `$false)]
    [string]`$Command = "Status"
)

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

# Créer un fichier de manifeste pour le gestionnaire de test
$testManifestPath = Join-Path -Path $testDir -ChildPath "test-manager.manifest.json"
Set-Content -Path $testManifestPath -Value @"
{
    "Name": "TestManager",
    "Description": "Gestionnaire de test pour les tests d'intégration",
    "Version": "1.0.0",
    "Author": "EMAIL_SENDER_1",
    "Dependencies": []
}
"@

# Définir les tests unitaires
$tests = @(
    @{
        Name = "Test d'importation du module ProcessManager"
        Test = {
            try {
                Import-Module -Name "ProcessManager" -Force -ErrorAction Stop
                $module = Get-Module -Name "ProcessManager"
                return $module -ne $null
            }
            catch {
                Write-TestLog -Message "Erreur lors de l'importation du module ProcessManager : $_" -Level Error
                return $false
            }
        }
    },
    @{
        Name = "Test de la fonction Get-ManagerManifest"
        Test = {
            try {
                $manifest = Get-ManagerManifest -Path $testManagerPath -ManifestPath $testManifestPath
                return $manifest -ne $null -and $manifest.Name -eq "TestManager" -and $manifest.Version -eq "1.0.0"
            }
            catch {
                Write-TestLog -Message "Erreur lors de l'exécution de Get-ManagerManifest : $_" -Level Error
                return $false
            }
        }
    },
    @{
        Name = "Test de la fonction Test-ManifestValidity"
        Test = {
            try {
                $manifest = Get-ManagerManifest -Path $testManagerPath -ManifestPath $testManifestPath
                $result = Test-ManifestValidity -Manifest $manifest
                return $result -eq $true
            }
            catch {
                Write-TestLog -Message "Erreur lors de l'exécution de Test-ManifestValidity : $_" -Level Error
                return $false
            }
        }
    },
    @{
        Name = "Test de la fonction Test-ManagerValidity"
        Test = {
            try {
                $result = Test-ManagerValidity -Path $testManagerPath
                return $result -eq $true
            }
            catch {
                Write-TestLog -Message "Erreur lors de l'exécution de Test-ManagerValidity : $_" -Level Error
                return $false
            }
        }
    },
    @{
        Name = "Test de la fonction Get-ManagerDependencies"
        Test = {
            try {
                $dependencies = Get-ManagerDependencies -Path $testManagerPath
                return $dependencies -ne $null
            }
            catch {
                Write-TestLog -Message "Erreur lors de l'exécution de Get-ManagerDependencies : $_" -Level Error
                return $false
            }
        }
    },
    @{
        Name = "Test d'enregistrement du gestionnaire avec le Process Manager"
        Test = {
            try {
                $result = & $processManagerScript -Command Register -ManagerName "TestManager" -ManagerPath $testManagerPath -Force
                return $LASTEXITCODE -eq 0
            }
            catch {
                Write-TestLog -Message "Erreur lors de l'enregistrement du gestionnaire : $_" -Level Error
                return $false
            }
        }
    },
    @{
        Name = "Test de découverte des gestionnaires avec le Process Manager"
        Test = {
            try {
                $result = & $processManagerScript -Command Discover -Force
                return $LASTEXITCODE -eq 0
            }
            catch {
                Write-TestLog -Message "Erreur lors de la découverte des gestionnaires : $_" -Level Error
                return $false
            }
        }
    },
    @{
        Name = "Test d'exécution d'une commande sur le gestionnaire avec le Process Manager"
        Test = {
            try {
                $result = & $processManagerScript -Command Run -ManagerName "TestManager" -ManagerCommand "Status"
                return $LASTEXITCODE -eq 0
            }
            catch {
                Write-TestLog -Message "Erreur lors de l'exécution d'une commande sur le gestionnaire : $_" -Level Error
                return $false
            }
        }
    }
)

# Exécuter les tests
$totalTests = $tests.Count
$passedTests = 0
$failedTests = 0

Write-TestLog -Message "Exécution de $totalTests tests d'intégration pour le Process Manager..." -Level Info

foreach ($test in $tests) {
    Write-TestLog -Message "Test : $($test.Name)" -Level Info
    
    try {
        $result = & $test.Test
        
        if ($result) {
            Write-TestLog -Message "  Résultat : Réussi" -Level Success
            $passedTests++
        } else {
            Write-TestLog -Message "  Résultat : Échec" -Level Error
            $failedTests++
        }
    } catch {
        Write-TestLog -Message "  Résultat : Erreur - $_" -Level Error
        $failedTests++
    }
}

# Afficher le résumé
Write-TestLog -Message "`nRésumé des tests :" -Level Info
Write-TestLog -Message "  Tests exécutés : $totalTests" -Level Info
Write-TestLog -Message "  Tests réussis  : $passedTests" -Level Success
Write-TestLog -Message "  Tests échoués  : $failedTests" -Level Error

# Nettoyer les fichiers de test
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}

# Retourner le résultat global
if ($failedTests -eq 0) {
    Write-TestLog -Message "`nTous les tests ont réussi !" -Level Success
    exit 0
} else {
    Write-TestLog -Message "`nCertains tests ont échoué." -Level Error
    exit 1
}
