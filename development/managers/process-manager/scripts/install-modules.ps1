<#
.SYNOPSIS
    Script d'installation des modules du Process Manager.

.DESCRIPTION
    Ce script installe les modules du Process Manager en les copiant dans le répertoire des modules PowerShell
    et en configurant l'environnement pour leur utilisation.

.PARAMETER ProjectRoot
    Chemin vers la racine du projet. Par défaut, utilise le répertoire courant.

.PARAMETER Force
    Force l'installation même si les modules sont déjà installés.

.PARAMETER SkipIntegration
    Ignore l'intégration des modules dans le Process Manager.

.EXAMPLE
    .\install-modules.ps1
    Installe les modules du Process Manager.

.EXAMPLE
    .\install-modules.ps1 -ProjectRoot "D:\Projets\MonProjet" -Force
    Force l'installation des modules dans le répertoire spécifié.

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
    [switch]$SkipIntegration
)

# Définir les chemins
$processManagerRoot = Join-Path -Path $ProjectRoot -ChildPath "development\managers\process-manager"
$modulesRoot = Join-Path -Path $processManagerRoot -ChildPath "modules"
$scriptsRoot = Join-Path -Path $processManagerRoot -ChildPath "scripts"
$configRoot = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $processManagerRoot)) -ChildPath "config"
$integrateModulesScript = Join-Path -Path $scriptsRoot -ChildPath "integrate-modules.ps1"

# Fonction pour écrire des messages de journal
function Write-InstallLog {
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
    Write-InstallLog -Message "Le répertoire du projet n'existe pas : $ProjectRoot" -Level Error
    exit 1
}

# Vérifier que le répertoire du Process Manager existe
if (-not (Test-Path -Path $processManagerRoot -PathType Container)) {
    Write-InstallLog -Message "Le répertoire du Process Manager n'existe pas : $processManagerRoot" -Level Error
    exit 1
}

# Vérifier que le répertoire des modules existe
if (-not (Test-Path -Path $modulesRoot -PathType Container)) {
    Write-InstallLog -Message "Le répertoire des modules n'existe pas : $modulesRoot" -Level Error
    exit 1
}

# Vérifier que le script d'intégration des modules existe
if (-not (Test-Path -Path $integrateModulesScript -PathType Leaf)) {
    Write-InstallLog -Message "Le script d'intégration des modules n'existe pas : $integrateModulesScript" -Level Error
    exit 1
}

# Vérifier si les modules sont déjà installés
$moduleNames = @(
    "ManagerRegistrationService",
    "ManifestParser",
    "ValidationService",
    "DependencyResolver"
)

$modulesInstalled = $true
foreach ($moduleName in $moduleNames) {
    $modulePath = Join-Path -Path $modulesRoot -ChildPath $moduleName
    if (-not (Test-Path -Path $modulePath -PathType Container)) {
        $modulesInstalled = $false
        break
    }
}

if ($modulesInstalled -and -not $Force) {
    Write-InstallLog -Message "Les modules sont déjà installés. Utilisez -Force pour forcer l'installation." -Level Warning
    exit 0
}

# Intégrer les modules
if (-not $SkipIntegration) {
    if ($PSCmdlet.ShouldProcess("Process Manager", "Intégrer les modules")) {
        Write-InstallLog -Message "Intégration des modules..." -Level Info
        
        try {
            $integrateParams = @{
                ProjectRoot = $ProjectRoot
            }
            
            if ($Force) {
                $integrateParams.Force = $true
            }
            
            $result = & $integrateModulesScript @integrateParams
            
            if ($LASTEXITCODE -eq 0) {
                Write-InstallLog -Message "Modules intégrés avec succès." -Level Success
            } else {
                Write-InstallLog -Message "Erreur lors de l'intégration des modules. Code de sortie : $LASTEXITCODE" -Level Error
                exit 1
            }
        } catch {
            Write-InstallLog -Message "Erreur lors de l'intégration des modules : $_" -Level Error
            exit 1
        }
    }
}

# Créer un fichier de configuration par défaut pour le Process Manager
$configPath = Join-Path -Path $configRoot -ChildPath "process-manager.config.json"
if (-not (Test-Path -Path $configPath -PathType Leaf) -or $Force) {
    if ($PSCmdlet.ShouldProcess($configPath, "Créer le fichier de configuration")) {
        # Créer le répertoire de configuration s'il n'existe pas
        if (-not (Test-Path -Path $configRoot -PathType Container)) {
            New-Item -Path $configRoot -ItemType Directory -Force | Out-Null
            Write-InstallLog -Message "Répertoire de configuration créé : $configRoot" -Level Success
        }
        
        # Créer le fichier de configuration par défaut
        $defaultConfig = @{
            Enabled = $true
            LogLevel = "Info"
            LogPath = "logs/process-manager"
            Managers = @{}
        }
        
        $defaultConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath -Encoding UTF8
        Write-InstallLog -Message "Fichier de configuration créé : $configPath" -Level Success
    }
}

# Vérifier l'installation
$processManagerModule = Get-Module -Name "ProcessManager" -ListAvailable
if ($processManagerModule) {
    Write-InstallLog -Message "Module ProcessManager installé avec succès." -Level Success
    Write-InstallLog -Message "Version : $($processManagerModule.Version)" -Level Info
    Write-InstallLog -Message "Chemin : $($processManagerModule.Path)" -Level Info
} else {
    Write-InstallLog -Message "Le module ProcessManager n'est pas installé correctement." -Level Warning
    Write-InstallLog -Message "Exécutez le script integrate-modules.ps1 pour installer le module." -Level Info
}

# Afficher les instructions d'utilisation
Write-InstallLog -Message "Installation terminée." -Level Success
Write-InstallLog -Message "Pour utiliser les modules, importez le module principal : Import-Module ProcessManager" -Level Info
Write-InstallLog -Message "Pour utiliser le Process Manager, exécutez le script process-manager.ps1 avec les paramètres appropriés." -Level Info
Write-InstallLog -Message "Exemple : .\process-manager.ps1 -Command Discover" -Level Info

# Retourner le résultat
return $processManagerModule -ne $null
