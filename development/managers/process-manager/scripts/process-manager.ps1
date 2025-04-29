<#
.SYNOPSIS
    Process Manager - Gestionnaire central des processus et gestionnaires du système.

.DESCRIPTION
    Le Process Manager est un composant central qui coordonne et gère tous les gestionnaires
    et processus du système. Il fournit des fonctionnalités de découverte, d'enregistrement,
    de configuration et de journalisation pour tous les gestionnaires.

.PARAMETER Command
    La commande à exécuter. Les commandes disponibles sont :
    - Register : Enregistre un nouveau gestionnaire
    - Discover : Découvre automatiquement les gestionnaires disponibles
    - List : Liste tous les gestionnaires enregistrés
    - Run : Exécute une commande sur un gestionnaire spécifique
    - Status : Affiche l'état d'un gestionnaire spécifique
    - Configure : Configure un gestionnaire spécifique

.PARAMETER ManagerName
    Le nom du gestionnaire sur lequel exécuter la commande.

.PARAMETER ManagerPath
    Le chemin vers le script du gestionnaire à enregistrer.

.PARAMETER ManagerCommand
    La commande à exécuter sur le gestionnaire spécifié.

.PARAMETER ConfigPath
    Le chemin vers le fichier de configuration à utiliser.

.PARAMETER LogLevel
    Le niveau de journalisation à utiliser (Debug, Info, Warning, Error).

.PARAMETER Force
    Force l'exécution de la commande sans demander de confirmation.

.EXAMPLE
    .\process-manager.ps1 -Command Register -ManagerName "ModeManager" -ManagerPath "development\managers\mode-manager\scripts\mode-manager.ps1"
    Enregistre le gestionnaire de modes.

.EXAMPLE
    .\process-manager.ps1 -Command Discover
    Découvre automatiquement tous les gestionnaires disponibles.

.EXAMPLE
    .\process-manager.ps1 -Command List
    Liste tous les gestionnaires enregistrés.

.EXAMPLE
    .\process-manager.ps1 -Command Run -ManagerName "ModeManager" -ManagerCommand "SetMode" -Mode "CHECK"
    Exécute la commande SetMode sur le gestionnaire de modes.

.NOTES
    Auteur: Process Manager Team
    Version: 1.0
    Date de création: 2025-05-02
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("Register", "Discover", "List", "Run", "Status", "Configure")]
    [string]$Command,

    [Parameter(Mandatory = $false)]
    [string]$ManagerName,

    [Parameter(Mandatory = $false)]
    [string]$ManagerPath,

    [Parameter(Mandatory = $false)]
    [string]$ManagerCommand,

    [Parameter(Mandatory = $false)]
    [string]$ConfigPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Debug", "Info", "Warning", "Error")]
    [string]$LogLevel = "Info",

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Importer les fonctions nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "modules"
$configPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) -ChildPath "config"

# Créer les chemins s'ils n'existent pas
if (-not (Test-Path -Path $modulePath)) {
    New-Item -Path $modulePath -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -Path $configPath)) {
    New-Item -Path $configPath -ItemType Directory -Force | Out-Null
}

# Définir le chemin du fichier de configuration par défaut
$defaultConfigPath = Join-Path -Path $configPath -ChildPath "process-manager.config.json"

# Utiliser le chemin de configuration spécifié ou le chemin par défaut
$configFilePath = if ($ConfigPath) { $ConfigPath } else { $defaultConfigPath }

# Créer le fichier de configuration s'il n'existe pas
if (-not (Test-Path -Path $configFilePath)) {
    $defaultConfig = @{
        Enabled = $true
        LogLevel = $LogLevel
        LogPath = "logs/process-manager"
        Managers = @{}
    }
    $defaultConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $configFilePath -Encoding UTF8
    Write-Host "Fichier de configuration créé : $configFilePath" -ForegroundColor Green
}

# Charger la configuration
try {
    $config = Get-Content -Path $configFilePath -Raw | ConvertFrom-Json
    Write-Host "Configuration chargée depuis : $configFilePath" -ForegroundColor Green
} catch {
    Write-Error "Erreur lors du chargement de la configuration : $_"
    exit 1
}

# Créer le répertoire de journalisation s'il n'existe pas
$logPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $scriptPath))) -ChildPath $config.LogPath
if (-not (Test-Path -Path $logPath)) {
    New-Item -Path $logPath -ItemType Directory -Force | Out-Null
    Write-Host "Répertoire de journalisation créé : $logPath" -ForegroundColor Green
}

# Fonction de journalisation
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Debug", "Info", "Warning", "Error")]
        [string]$Level = "Info"
    )

    # Définir les niveaux de journalisation
    $logLevels = @{
        Debug = 0
        Info = 1
        Warning = 2
        Error = 3
    }

    # Vérifier si le niveau de journalisation est suffisant
    if ($logLevels[$Level] -ge $logLevels[$config.LogLevel]) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "[$timestamp] [$Level] $Message"
        
        # Définir la couleur en fonction du niveau
        $color = switch ($Level) {
            "Debug" { "Gray" }
            "Info" { "White" }
            "Warning" { "Yellow" }
            "Error" { "Red" }
            default { "White" }
        }
        
        # Afficher le message dans la console
        Write-Host $logMessage -ForegroundColor $color
        
        # Écrire le message dans le fichier de journal
        $logFile = Join-Path -Path $logPath -ChildPath "process-manager_$(Get-Date -Format 'yyyy-MM-dd').log"
        Add-Content -Path $logFile -Value $logMessage -Encoding UTF8
    }
}

# Fonction pour enregistrer un gestionnaire
function Register-Manager {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Vérifier que le fichier du gestionnaire existe
    if (-not (Test-Path -Path $Path)) {
        Write-Log -Message "Le fichier du gestionnaire n'existe pas : $Path" -Level Error
        return $false
    }

    # Vérifier si le gestionnaire est déjà enregistré
    if ($config.Managers.$Name -and -not $Force) {
        Write-Log -Message "Le gestionnaire '$Name' est déjà enregistré. Utilisez -Force pour le remplacer." -Level Warning
        return $false
    }

    # Enregistrer le gestionnaire
    if ($PSCmdlet.ShouldProcess($Name, "Enregistrer le gestionnaire")) {
        $config.Managers | Add-Member -NotePropertyName $Name -NotePropertyValue @{
            Path = $Path
            Enabled = $true
            RegisteredAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        } -Force

        # Enregistrer la configuration
        $config | ConvertTo-Json -Depth 10 | Set-Content -Path $configFilePath -Encoding UTF8
        Write-Log -Message "Gestionnaire '$Name' enregistré avec succès." -Level Info
        return $true
    }

    return $false
}

# Fonction pour découvrir automatiquement les gestionnaires
function Discover-Managers {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    Write-Log -Message "Découverte automatique des gestionnaires..." -Level Info

    # Définir les chemins de recherche
    $searchPaths = @(
        "development\managers"
    )

    $managersFound = 0
    $managersRegistered = 0

    # Parcourir les chemins de recherche
    foreach ($searchPath in $searchPaths) {
        $fullSearchPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $scriptPath))) -ChildPath $searchPath
        
        if (Test-Path -Path $fullSearchPath) {
            Write-Log -Message "Recherche dans $fullSearchPath..." -Level Debug
            
            # Rechercher les répertoires de gestionnaires
            $managerDirs = Get-ChildItem -Path $fullSearchPath -Directory | Where-Object { $_.Name -like "*-manager" }
            
            foreach ($managerDir in $managerDirs) {
                $managerName = $managerDir.Name -replace "-manager", "Manager" -replace "^.", { $args[0].ToString().ToUpper() }
                $managerScriptPath = Join-Path -Path $managerDir.FullName -ChildPath "scripts\$($managerDir.Name).ps1"
                
                if (Test-Path -Path $managerScriptPath) {
                    $managersFound++
                    Write-Log -Message "Gestionnaire trouvé : $managerName ($managerScriptPath)" -Level Debug
                    
                    # Enregistrer le gestionnaire
                    if (Register-Manager -Name $managerName -Path $managerScriptPath -Force:$Force) {
                        $managersRegistered++
                    }
                }
            }
        }
    }

    Write-Log -Message "$managersFound gestionnaires trouvés, $managersRegistered gestionnaires enregistrés." -Level Info
    return $managersRegistered
}

# Fonction pour lister les gestionnaires enregistrés
function List-Managers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )

    Write-Log -Message "Liste des gestionnaires enregistrés :" -Level Info

    if (-not $config.Managers -or $config.Managers.PSObject.Properties.Count -eq 0) {
        Write-Log -Message "Aucun gestionnaire enregistré." -Level Warning
        return @()
    }

    $managers = @()

    foreach ($managerName in $config.Managers.PSObject.Properties.Name) {
        $manager = $config.Managers.$managerName
        $managerStatus = if ($manager.Enabled) { "Activé" } else { "Désactivé" }
        
        if ($Detailed) {
            Write-Log -Message "- $managerName ($managerStatus)" -Level Info
            Write-Log -Message "  Chemin : $($manager.Path)" -Level Info
            Write-Log -Message "  Enregistré le : $($manager.RegisteredAt)" -Level Info
            
            # Vérifier si le gestionnaire existe
            if (Test-Path -Path $manager.Path) {
                Write-Log -Message "  État : Disponible" -Level Info
            } else {
                Write-Log -Message "  État : Non disponible" -Level Warning
            }
            
            Write-Log -Message "" -Level Info
        } else {
            Write-Log -Message "- $managerName ($managerStatus)" -Level Info
        }

        $managers += [PSCustomObject]@{
            Name = $managerName
            Path = $manager.Path
            Enabled = $manager.Enabled
            RegisteredAt = $manager.RegisteredAt
            Available = Test-Path -Path $manager.Path
        }
    }

    return $managers
}

# Fonction pour exécuter une commande sur un gestionnaire
function Run-ManagerCommand {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ManagerName,

        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{}
    )

    # Vérifier que le gestionnaire est enregistré
    if (-not $config.Managers.$ManagerName) {
        Write-Log -Message "Le gestionnaire '$ManagerName' n'est pas enregistré." -Level Error
        return $false
    }

    # Vérifier que le gestionnaire est activé
    if (-not $config.Managers.$ManagerName.Enabled) {
        Write-Log -Message "Le gestionnaire '$ManagerName' est désactivé." -Level Warning
        return $false
    }

    # Vérifier que le fichier du gestionnaire existe
    $managerPath = $config.Managers.$ManagerName.Path
    if (-not (Test-Path -Path $managerPath)) {
        Write-Log -Message "Le fichier du gestionnaire '$ManagerName' n'existe pas : $managerPath" -Level Error
        return $false
    }

    # Construire la commande
    $commandParams = @{
        FilePath = $managerPath
    }

    # Ajouter le paramètre Command si spécifié
    if ($Command) {
        $commandParams.ArgumentList = "-Command $Command"
    }

    # Ajouter les autres paramètres
    foreach ($param in $Parameters.Keys) {
        $value = $Parameters[$param]
        
        # Gérer les types de paramètres
        if ($value -is [switch]) {
            if ($value) {
                $commandParams.ArgumentList += " -$param"
            }
        } elseif ($value -is [array]) {
            $valueStr = $value -join ","
            $commandParams.ArgumentList += " -$param '$valueStr'"
        } else {
            $commandParams.ArgumentList += " -$param '$value'"
        }
    }

    # Exécuter la commande
    if ($PSCmdlet.ShouldProcess($ManagerName, "Exécuter la commande $Command")) {
        Write-Log -Message "Exécution de la commande sur le gestionnaire '$ManagerName' : $Command" -Level Info
        
        try {
            $result = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File $($commandParams.FilePath) $($commandParams.ArgumentList)" -Wait -PassThru -NoNewWindow
            
            if ($result.ExitCode -eq 0) {
                Write-Log -Message "Commande exécutée avec succès." -Level Info
                return $true
            } else {
                Write-Log -Message "Erreur lors de l'exécution de la commande. Code de sortie : $($result.ExitCode)" -Level Error
                return $false
            }
        } catch {
            Write-Log -Message "Erreur lors de l'exécution de la commande : $_" -Level Error
            return $false
        }
    }

    return $false
}

# Fonction pour obtenir l'état d'un gestionnaire
function Get-ManagerStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ManagerName
    )

    # Vérifier que le gestionnaire est enregistré
    if (-not $config.Managers.$ManagerName) {
        Write-Log -Message "Le gestionnaire '$ManagerName' n'est pas enregistré." -Level Error
        return $null
    }

    $manager = $config.Managers.$ManagerName
    $managerPath = $manager.Path
    $managerEnabled = $manager.Enabled
    $managerAvailable = Test-Path -Path $managerPath

    $status = [PSCustomObject]@{
        Name = $ManagerName
        Path = $managerPath
        Enabled = $managerEnabled
        Available = $managerAvailable
        RegisteredAt = $manager.RegisteredAt
    }

    Write-Log -Message "État du gestionnaire '$ManagerName' :" -Level Info
    Write-Log -Message "- Chemin : $managerPath" -Level Info
    Write-Log -Message "- Activé : $managerEnabled" -Level Info
    Write-Log -Message "- Disponible : $managerAvailable" -Level Info
    Write-Log -Message "- Enregistré le : $($manager.RegisteredAt)" -Level Info

    return $status
}

# Fonction pour configurer un gestionnaire
function Configure-Manager {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ManagerName,

        [Parameter(Mandatory = $false)]
        [bool]$Enabled,

        [Parameter(Mandatory = $false)]
        [string]$Path
    )

    # Vérifier que le gestionnaire est enregistré
    if (-not $config.Managers.$ManagerName) {
        Write-Log -Message "Le gestionnaire '$ManagerName' n'est pas enregistré." -Level Error
        return $false
    }

    # Mettre à jour la configuration
    if ($PSCmdlet.ShouldProcess($ManagerName, "Configurer le gestionnaire")) {
        $modified = $false

        if ($PSBoundParameters.ContainsKey('Enabled')) {
            $config.Managers.$ManagerName.Enabled = $Enabled
            Write-Log -Message "État du gestionnaire '$ManagerName' mis à jour : $Enabled" -Level Info
            $modified = $true
        }

        if ($PSBoundParameters.ContainsKey('Path')) {
            # Vérifier que le fichier existe
            if (Test-Path -Path $Path) {
                $config.Managers.$ManagerName.Path = $Path
                Write-Log -Message "Chemin du gestionnaire '$ManagerName' mis à jour : $Path" -Level Info
                $modified = $true
            } else {
                Write-Log -Message "Le fichier spécifié n'existe pas : $Path" -Level Error
                return $false
            }
        }

        if ($modified) {
            # Enregistrer la configuration
            $config | ConvertTo-Json -Depth 10 | Set-Content -Path $configFilePath -Encoding UTF8
            Write-Log -Message "Configuration du gestionnaire '$ManagerName' mise à jour avec succès." -Level Info
            return $true
        } else {
            Write-Log -Message "Aucune modification apportée à la configuration du gestionnaire '$ManagerName'." -Level Warning
            return $false
        }
    }

    return $false
}

# Exécuter la commande spécifiée
switch ($Command) {
    "Register" {
        if (-not $ManagerName -or -not $ManagerPath) {
            Write-Log -Message "Les paramètres ManagerName et ManagerPath sont requis pour la commande Register." -Level Error
            exit 1
        }
        
        Register-Manager -Name $ManagerName -Path $ManagerPath -Force:$Force
    }
    
    "Discover" {
        Discover-Managers -Force:$Force
    }
    
    "List" {
        List-Managers -Detailed
    }
    
    "Run" {
        if (-not $ManagerName -or -not $ManagerCommand) {
            Write-Log -Message "Les paramètres ManagerName et ManagerCommand sont requis pour la commande Run." -Level Error
            exit 1
        }
        
        # Extraire les paramètres supplémentaires
        $params = @{}
        foreach ($param in $PSBoundParameters.Keys) {
            if ($param -notin @("Command", "ManagerName", "ManagerCommand", "ConfigPath", "LogLevel", "Force")) {
                $params[$param] = $PSBoundParameters[$param]
            }
        }
        
        Run-ManagerCommand -ManagerName $ManagerName -Command $ManagerCommand -Parameters $params
    }
    
    "Status" {
        if (-not $ManagerName) {
            Write-Log -Message "Le paramètre ManagerName est requis pour la commande Status." -Level Error
            exit 1
        }
        
        Get-ManagerStatus -ManagerName $ManagerName
    }
    
    "Configure" {
        if (-not $ManagerName) {
            Write-Log -Message "Le paramètre ManagerName est requis pour la commande Configure." -Level Error
            exit 1
        }
        
        # Extraire les paramètres de configuration
        $configParams = @{
            ManagerName = $ManagerName
        }
        
        if ($PSBoundParameters.ContainsKey('Enabled')) {
            $configParams.Enabled = $Enabled
        }
        
        if ($PSBoundParameters.ContainsKey('ManagerPath')) {
            $configParams.Path = $ManagerPath
        }
        
        Configure-Manager @configParams
    }
}
