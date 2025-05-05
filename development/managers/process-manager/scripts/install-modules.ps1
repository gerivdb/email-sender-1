<#
.SYNOPSIS
    Script d'installation des modules du Process Manager.

.DESCRIPTION
    Ce script installe les modules du Process Manager en les copiant dans le rÃ©pertoire des modules PowerShell
    et en configurant l'environnement pour leur utilisation.

.PARAMETER ProjectRoot
    Chemin vers la racine du projet. Par dÃ©faut, utilise le rÃ©pertoire courant.

.PARAMETER Force
    Force l'installation mÃªme si les modules sont dÃ©jÃ  installÃ©s.

.PARAMETER SkipIntegration
    Ignore l'intÃ©gration des modules dans le Process Manager.

.EXAMPLE
    .\install-modules.ps1
    Installe les modules du Process Manager.

.EXAMPLE
    .\install-modules.ps1 -ProjectRoot "D:\Projets\MonProjet" -Force
    Force l'installation des modules dans le rÃ©pertoire spÃ©cifiÃ©.

.NOTES
    Auteur: EMAIL_SENDER_1
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
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

# DÃ©finir les chemins
$processManagerRoot = Join-Path -Path $ProjectRoot -ChildPath "development\managers\process-manager"
$modulesRoot = Join-Path -Path $processManagerRoot -ChildPath "modules"
$scriptsRoot = Join-Path -Path $processManagerRoot -ChildPath "scripts"
$configRoot = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $processManagerRoot)) -ChildPath "config"
$integrateModulesScript = Join-Path -Path $scriptsRoot -ChildPath "integrate-modules.ps1"

# Fonction pour Ã©crire des messages de journal
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
    
    # DÃ©finir la couleur en fonction du niveau
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

# VÃ©rifier que le rÃ©pertoire du projet existe
if (-not (Test-Path -Path $ProjectRoot -PathType Container)) {
    Write-InstallLog -Message "Le rÃ©pertoire du projet n'existe pas : $ProjectRoot" -Level Error
    exit 1
}

# VÃ©rifier que le rÃ©pertoire du Process Manager existe
if (-not (Test-Path -Path $processManagerRoot -PathType Container)) {
    Write-InstallLog -Message "Le rÃ©pertoire du Process Manager n'existe pas : $processManagerRoot" -Level Error
    exit 1
}

# VÃ©rifier que le rÃ©pertoire des modules existe
if (-not (Test-Path -Path $modulesRoot -PathType Container)) {
    Write-InstallLog -Message "Le rÃ©pertoire des modules n'existe pas : $modulesRoot" -Level Error
    exit 1
}

# VÃ©rifier que le script d'intÃ©gration des modules existe
if (-not (Test-Path -Path $integrateModulesScript -PathType Leaf)) {
    Write-InstallLog -Message "Le script d'intÃ©gration des modules n'existe pas : $integrateModulesScript" -Level Error
    exit 1
}

# VÃ©rifier si les modules sont dÃ©jÃ  installÃ©s
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
    Write-InstallLog -Message "Les modules sont dÃ©jÃ  installÃ©s. Utilisez -Force pour forcer l'installation." -Level Warning
    exit 0
}

# IntÃ©grer les modules
if (-not $SkipIntegration) {
    if ($PSCmdlet.ShouldProcess("Process Manager", "IntÃ©grer les modules")) {
        Write-InstallLog -Message "IntÃ©gration des modules..." -Level Info
        
        try {
            $integrateParams = @{
                ProjectRoot = $ProjectRoot
            }
            
            if ($Force) {
                $integrateParams.Force = $true
            }
            
            $result = & $integrateModulesScript @integrateParams
            
            if ($LASTEXITCODE -eq 0) {
                Write-InstallLog -Message "Modules intÃ©grÃ©s avec succÃ¨s." -Level Success
            } else {
                Write-InstallLog -Message "Erreur lors de l'intÃ©gration des modules. Code de sortie : $LASTEXITCODE" -Level Error
                exit 1
            }
        } catch {
            Write-InstallLog -Message "Erreur lors de l'intÃ©gration des modules : $_" -Level Error
            exit 1
        }
    }
}

# CrÃ©er un fichier de configuration par dÃ©faut pour le Process Manager
$configPath = Join-Path -Path $configRoot -ChildPath "process-manager.config.json"
if (-not (Test-Path -Path $configPath -PathType Leaf) -or $Force) {
    if ($PSCmdlet.ShouldProcess($configPath, "CrÃ©er le fichier de configuration")) {
        # CrÃ©er le rÃ©pertoire de configuration s'il n'existe pas
        if (-not (Test-Path -Path $configRoot -PathType Container)) {
            New-Item -Path $configRoot -ItemType Directory -Force | Out-Null
            Write-InstallLog -Message "RÃ©pertoire de configuration crÃ©Ã© : $configRoot" -Level Success
        }
        
        # CrÃ©er le fichier de configuration par dÃ©faut
        $defaultConfig = @{
            Enabled = $true
            LogLevel = "Info"
            LogPath = "logs/process-manager"
            Managers = @{}
        }
        
        $defaultConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath -Encoding UTF8
        Write-InstallLog -Message "Fichier de configuration crÃ©Ã© : $configPath" -Level Success
    }
}

# VÃ©rifier l'installation
$processManagerModule = Get-Module -Name "ProcessManager" -ListAvailable
if ($processManagerModule) {
    Write-InstallLog -Message "Module ProcessManager installÃ© avec succÃ¨s." -Level Success
    Write-InstallLog -Message "Version : $($processManagerModule.Version)" -Level Info
    Write-InstallLog -Message "Chemin : $($processManagerModule.Path)" -Level Info
} else {
    Write-InstallLog -Message "Le module ProcessManager n'est pas installÃ© correctement." -Level Warning
    Write-InstallLog -Message "ExÃ©cutez le script integrate-modules.ps1 pour installer le module." -Level Info
}

# Afficher les instructions d'utilisation
Write-InstallLog -Message "Installation terminÃ©e." -Level Success
Write-InstallLog -Message "Pour utiliser les modules, importez le module principal : Import-Module ProcessManager" -Level Info
Write-InstallLog -Message "Pour utiliser le Process Manager, exÃ©cutez le script process-manager.ps1 avec les paramÃ¨tres appropriÃ©s." -Level Info
Write-InstallLog -Message "Exemple : .\process-manager.ps1 -Command Discover" -Level Info

# Retourner le rÃ©sultat
return $processManagerModule -ne $null
