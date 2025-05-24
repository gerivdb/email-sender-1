<#
.SYNOPSIS
    Process Manager - Gestionnaire central des processus et gestionnaires du systÃ¨me.

.DESCRIPTION
    Le Process Manager est un composant central qui coordonne et gÃ¨re tous les gestionnaires
    et processus du systÃ¨me. Il fournit des fonctionnalitÃ©s de dÃ©couverte, d'enregistrement,
    de configuration et de journalisation pour tous les gestionnaires.

.PARAMETER Command
    La commande Ã  exÃ©cuter. Les commandes disponibles sont :
    - Register : Enregistre un nouveau gestionnaire
    - Discover : DÃ©couvre automatiquement les gestionnaires disponibles
    - List : Liste tous les gestionnaires enregistrÃ©s
    - Run : ExÃ©cute une commande sur un gestionnaire spÃ©cifique
    - Status : Affiche l'Ã©tat d'un gestionnaire spÃ©cifique
    - Configure : Configure un gestionnaire spÃ©cifique

.PARAMETER ManagerName
    Le nom du gestionnaire sur lequel exÃ©cuter la commande.

.PARAMETER ManagerPath
    Le chemin vers le script du gestionnaire Ã  enregistrer.

.PARAMETER ManagerCommand
    La commande Ã  exÃ©cuter sur le gestionnaire spÃ©cifiÃ©.

.PARAMETER ConfigPath
    Le chemin vers le fichier de configuration Ã  utiliser.

.PARAMETER LogLevel
    Le niveau de journalisation Ã  utiliser (Debug, Info, Warning, Error).

.PARAMETER Force
    Force l'exÃ©cution de la commande sans demander de confirmation.

.EXAMPLE
    .\process-manager.ps1 -Command Register -ManagerName "ModeManager" -ManagerPath "development\managers\mode-manager\scripts\mode-manager.ps1"
    Enregistre le gestionnaire de modes.

.EXAMPLE
    .\process-manager.ps1 -Command Discover
    DÃ©couvre automatiquement tous les gestionnaires disponibles.

.EXAMPLE
    .\process-manager.ps1 -Command List
    Liste tous les gestionnaires enregistrÃ©s.

.EXAMPLE
    .\process-manager.ps1 -Command Run -ManagerName "ModeManager" -ManagerCommand "SetMode" -Mode "CHECK"
    ExÃ©cute la commande SetMode sur le gestionnaire de modes.

.NOTES
    Auteur: Process Manager Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-02
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
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [string]$Version,

    [Parameter(Mandatory = $false)]
    [switch]$SkipDependencyCheck,

    [Parameter(Mandatory = $false)]
    [switch]$SkipValidation,

    [Parameter(Mandatory = $false)]
    [switch]$SkipSecurityCheck,

    [Parameter(Mandatory = $false)]
    [string[]]$SearchPaths
)

# Importer les fonctions nÃ©cessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "modules"
$configPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) -ChildPath "config"

# CrÃ©er les chemins s'ils n'existent pas
if (-not (Test-Path -Path $modulePath)) {
    New-Item -Path $modulePath -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -Path $configPath)) {
    New-Item -Path $configPath -ItemType Directory -Force | Out-Null
}

# Importer le module ProcessManager s'il est disponible
try {
    Import-Module -Name "ProcessManager" -ErrorAction Stop
    $processManagerModuleAvailable = $true
    Write-Host "Module ProcessManager importÃ© avec succÃ¨s." -ForegroundColor Green
} catch {
    $processManagerModuleAvailable = $false
    Write-Host "Module ProcessManager non disponible. Utilisation des fonctions intÃ©grÃ©es." -ForegroundColor Yellow
    Write-Host "Pour installer le module, exÃ©cutez le script integrate-modules.ps1." -ForegroundColor Yellow
}

# DÃ©finir le chemin du fichier de configuration par dÃ©faut
$defaultConfigPath = Join-Path -Path $configPath -ChildPath "process-manager.config.json"

# Utiliser le chemin de configuration spÃ©cifiÃ© ou le chemin par dÃ©faut
$configFilePath = if ($ConfigPath) { $ConfigPath } else { $defaultConfigPath }

# CrÃ©er le fichier de configuration s'il n'existe pas
if (-not (Test-Path -Path $configFilePath)) {
    $defaultConfig = @{
        Enabled  = $true
        LogLevel = $LogLevel
        LogPath  = "logs/process-manager"
        Managers = @{}
    }
    $defaultConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $configFilePath -Encoding UTF8
    Write-Host "Fichier de configuration crÃ©Ã© : $configFilePath" -ForegroundColor Green
}

# Charger la configuration
try {
    $config = Get-Content -Path $configFilePath -Raw | ConvertFrom-Json
    Write-Host "Configuration chargÃ©e depuis : $configFilePath" -ForegroundColor Green
} catch {
    Write-Error "Erreur lors du chargement de la configuration : $_"
    exit 1
}

# CrÃ©er le rÃ©pertoire de journalisation s'il n'existe pas
$logPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $scriptPath))) -ChildPath $config.LogPath
if (-not (Test-Path -Path $logPath)) {
    New-Item -Path $logPath -ItemType Directory -Force | Out-Null
    Write-Host "RÃ©pertoire de journalisation crÃ©Ã© : $logPath" -ForegroundColor Green
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

    # DÃ©finir les niveaux de journalisation
    $logLevels = @{
        Debug   = 0
        Info    = 1
        Warning = 2
        Error   = 3
    }

    # VÃ©rifier si le niveau de journalisation est suffisant
    if ($logLevels[$Level] -ge $logLevels[$config.LogLevel]) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "[$timestamp] [$Level] $Message"

        # DÃ©finir la couleur en fonction du niveau
        $color = switch ($Level) {
            "Debug" { "Gray" }
            "Info" { "White" }
            "Warning" { "Yellow" }
            "Error" { "Red" }
            default { "White" }
        }

        # Afficher le message dans la console
        Write-Host $logMessage -ForegroundColor $color

        # Ã‰crire le message dans le fichier de journal
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
        [string]$Version,

        [Parameter(Mandatory = $false)]
        [switch]$Force,

        [Parameter(Mandatory = $false)]
        [switch]$SkipDependencyCheck,

        [Parameter(Mandatory = $false)]
        [switch]$SkipValidation,

        [Parameter(Mandatory = $false)]
        [switch]$SkipSecurityCheck
    )

    # Utiliser le module ProcessManager si disponible
    if ($processManagerModuleAvailable) {
        Write-Log -Message "Utilisation du module ProcessManager pour l'enregistrement du gestionnaire '$Name'." -Level Info

        $registerParams = @{
            Name       = $Name
            Path       = $Path
            ConfigPath = $configFilePath
        }

        if ($PSBoundParameters.ContainsKey('Version')) {
            $registerParams.Version = $Version
        }

        if ($Force) {
            $registerParams.Force = $true
        }

        if ($SkipDependencyCheck) {
            $registerParams.SkipDependencyCheck = $true
        }

        if ($SkipValidation) {
            $registerParams.SkipValidation = $true
        }

        if ($SkipSecurityCheck) {
            $registerParams.SkipSecurityCheck = $true
        }

        if ($PSCmdlet.ShouldProcess($Name, "Enregistrer le gestionnaire avec le module ProcessManager")) {
            try {
                $result = ProcessManager\Register-Manager @registerParams
                return $result
            } catch {
                Write-Log -Message "Erreur lors de l'enregistrement du gestionnaire avec le module ProcessManager : $_" -Level Error
                Write-Log -Message "Utilisation de la mÃ©thode d'enregistrement intÃ©grÃ©e." -Level Warning
                # Continuer avec la mÃ©thode intÃ©grÃ©e
            }
        }
    }

    # MÃ©thode d'enregistrement intÃ©grÃ©e (fallback)
    Write-Log -Message "Utilisation de la mÃ©thode d'enregistrement intÃ©grÃ©e pour le gestionnaire '$Name'." -Level Info

    # VÃ©rifier que le fichier du gestionnaire existe
    if (-not (Test-Path -Path $Path)) {
        Write-Log -Message "Le fichier du gestionnaire n'existe pas : $Path" -Level Error
        return $false
    }

    # VÃ©rifier si le gestionnaire est dÃ©jÃ  enregistrÃ©
    if ($config.Managers.$Name -and -not $Force) {
        Write-Log -Message "Le gestionnaire '$Name' est dÃ©jÃ  enregistrÃ©. Utilisez -Force pour le remplacer." -Level Warning
        return $false
    }

    # Enregistrer le gestionnaire
    if ($PSCmdlet.ShouldProcess($Name, "Enregistrer le gestionnaire")) {
        $managerEntry = @{
            Path         = $Path
            Enabled      = $true
            RegisteredAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }

        # Ajouter la version si spÃ©cifiÃ©e
        if ($PSBoundParameters.ContainsKey('Version')) {
            $managerEntry.Version = $Version
        }

        # Mettre Ã  jour la configuration
        if ($config.Managers.PSObject.Properties.Name -contains $Name) {
            # Mettre Ã  jour un gestionnaire existant
            $config.Managers.$Name = $managerEntry
        } else {
            # Ajouter un nouveau gestionnaire
            $config.Managers | Add-Member -NotePropertyName $Name -NotePropertyValue $managerEntry -Force
        }

        # Enregistrer la configuration
        $config | ConvertTo-Json -Depth 10 | Set-Content -Path $configFilePath -Encoding UTF8
        Write-Log -Message "Gestionnaire '$Name' enregistrÃ© avec succÃ¨s." -Level Info
        return $true
    }

    return $false
}

# Fonction pour dÃ©couvrir automatiquement les gestionnaires
function Find-Managers {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Force,

        [Parameter(Mandatory = $false)]
        [switch]$SkipDependencyCheck,

        [Parameter(Mandatory = $false)]
        [switch]$SkipValidation,

        [Parameter(Mandatory = $false)]
        [switch]$SkipSecurityCheck,

        [Parameter(Mandatory = $false)]
        [string[]]$SearchPaths = @("development\managers")
    )

    Write-Log -Message "DÃ©couverte automatique des gestionnaires..." -Level Info

    $managersFound = 0
    $managersRegistered = 0

    # Parcourir les chemins de recherche
    foreach ($searchPath in $SearchPaths) {
        $fullSearchPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $scriptPath))) -ChildPath $searchPath

        if (Test-Path -Path $fullSearchPath) {
            Write-Log -Message "Recherche dans $fullSearchPath..." -Level Debug

            # Rechercher les rÃ©pertoires de gestionnaires
            $managerDirs = Get-ChildItem -Path $fullSearchPath -Directory | Where-Object { $_.Name -like "*-manager" }

            foreach ($managerDir in $managerDirs) {
                $managerName = $managerDir.Name -replace "-manager", "Manager" -replace "^.", { $args[0].ToString().ToUpper() }
                $managerScriptPath = Join-Path -Path $managerDir.FullName -ChildPath "scripts\$($managerDir.Name).ps1"
                $manifestPath = Join-Path -Path $managerDir.FullName -ChildPath "scripts\$($managerDir.Name).manifest.json"

                if (Test-Path -Path $managerScriptPath) {
                    $managersFound++
                    Write-Log -Message "Gestionnaire trouvÃ© : $managerName ($managerScriptPath)" -Level Debug

                    # PrÃ©parer les paramÃ¨tres d'enregistrement
                    $registerParams = @{
                        Name  = $managerName
                        Path  = $managerScriptPath
                        Force = $Force
                    }

                    # Ajouter les paramÃ¨tres optionnels
                    if ($SkipDependencyCheck) {
                        $registerParams.SkipDependencyCheck = $true
                    }

                    if ($SkipValidation) {
                        $registerParams.SkipValidation = $true
                    }

                    if ($SkipSecurityCheck) {
                        $registerParams.SkipSecurityCheck = $true
                    }

                    # Extraire la version du manifeste si disponible
                    if ($processManagerModuleAvailable -and (Test-Path -Path $manifestPath)) {
                        try {
                            $manifest = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json
                            if ($manifest.Version) {
                                $registerParams.Version = $manifest.Version
                                Write-Log -Message "Version extraite du manifeste : $($manifest.Version)" -Level Debug
                            }
                        } catch {
                            Write-Log -Message "Erreur lors de l'extraction du manifeste : $_" -Level Warning
                        }
                    }

                    # Enregistrer le gestionnaire
                    if (Register-Manager @registerParams) {
                        $managersRegistered++
                    }
                }
            }
        }
    }

    Write-Log -Message "$managersFound gestionnaires trouvÃ©s, $managersRegistered gestionnaires enregistrÃ©s." -Level Info
    return $managersRegistered
}

# Fonction pour lister les gestionnaires enregistrÃ©s
function Get-Managers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )

    Write-Log -Message "Liste des gestionnaires enregistrÃ©s :" -Level Info

    if (-not $config.Managers -or $config.Managers.PSObject.Properties.Count -eq 0) {
        Write-Log -Message "Aucun gestionnaire enregistrÃ©." -Level Warning
        return @()
    }

    $managers = @()

    foreach ($managerName in $config.Managers.PSObject.Properties.Name) {
        $manager = $config.Managers.$managerName
        $managerStatus = if ($manager.Enabled) { "ActivÃ©" } else { "DÃ©sactivÃ©" }

        if ($Detailed) {
            Write-Log -Message "- $managerName ($managerStatus)" -Level Info
            Write-Log -Message "  Chemin : $($manager.Path)" -Level Info
            Write-Log -Message "  EnregistrÃ© le : $($manager.RegisteredAt)" -Level Info

            # VÃ©rifier si le gestionnaire existe
            if (Test-Path -Path $manager.Path) {
                Write-Log -Message "  Ã‰tat : Disponible" -Level Info
            } else {
                Write-Log -Message "  Ã‰tat : Non disponible" -Level Warning
            }

            Write-Log -Message "" -Level Info
        } else {
            Write-Log -Message "- $managerName ($managerStatus)" -Level Info
        }

        $managers += [PSCustomObject]@{
            Name         = $managerName
            Path         = $manager.Path
            Enabled      = $manager.Enabled
            RegisteredAt = $manager.RegisteredAt
            Available    = Test-Path -Path $manager.Path
        }
    }

    return $managers
}

# Fonction pour exÃ©cuter une commande sur un gestionnaire
function Start-ManagerCommand {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ManagerName,

        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{}
    )

    # VÃ©rifier que le gestionnaire est enregistrÃ©
    if (-not $config.Managers.$ManagerName) {
        Write-Log -Message "Le gestionnaire '$ManagerName' n'est pas enregistrÃ©." -Level Error
        return $false
    }

    # VÃ©rifier que le gestionnaire est activÃ©
    if (-not $config.Managers.$ManagerName.Enabled) {
        Write-Log -Message "Le gestionnaire '$ManagerName' est dÃ©sactivÃ©." -Level Warning
        return $false
    }

    # VÃ©rifier que le fichier du gestionnaire existe
    $managerPath = $config.Managers.$ManagerName.Path
    if (-not (Test-Path -Path $managerPath)) {
        Write-Log -Message "Le fichier du gestionnaire '$ManagerName' n'existe pas : $managerPath" -Level Error
        return $false
    }

    # Construire la commande
    $commandParams = @{
        FilePath = $managerPath
    }

    # Ajouter le paramÃ¨tre Command si spÃ©cifiÃ©
    if ($Command) {
        $commandParams.ArgumentList = "-Command $Command"
    }

    # Ajouter les autres paramÃ¨tres
    foreach ($param in $Parameters.Keys) {
        $value = $Parameters[$param]

        # GÃ©rer les types de paramÃ¨tres
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

    # ExÃ©cuter la commande
    if ($PSCmdlet.ShouldProcess($ManagerName, "ExÃ©cuter la commande $Command")) {
        Write-Log -Message "ExÃ©cution de la commande sur le gestionnaire '$ManagerName' : $Command" -Level Info

        try {
            $result = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File $($commandParams.FilePath) $($commandParams.ArgumentList)" -Wait -PassThru -NoNewWindow

            if ($result.ExitCode -eq 0) {
                Write-Log -Message "Commande exÃ©cutÃ©e avec succÃ¨s." -Level Info
                return $true
            } else {
                Write-Log -Message "Erreur lors de l'exÃ©cution de la commande. Code de sortie : $($result.ExitCode)" -Level Error
                return $false
            }
        } catch {
            Write-Log -Message "Erreur lors de l'exÃ©cution de la commande : $_" -Level Error
            return $false
        }
    }

    return $false
}

# Fonction pour obtenir l'Ã©tat d'un gestionnaire
function Get-ManagerStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ManagerName
    )

    # VÃ©rifier que le gestionnaire est enregistrÃ©
    if (-not $config.Managers.$ManagerName) {
        Write-Log -Message "Le gestionnaire '$ManagerName' n'est pas enregistrÃ©." -Level Error
        return $null
    }

    $manager = $config.Managers.$ManagerName
    $managerPath = $manager.Path
    $managerEnabled = $manager.Enabled
    $managerAvailable = Test-Path -Path $managerPath

    $status = [PSCustomObject]@{
        Name         = $ManagerName
        Path         = $managerPath
        Enabled      = $managerEnabled
        Available    = $managerAvailable
        RegisteredAt = $manager.RegisteredAt
    }

    Write-Log -Message "Ã‰tat du gestionnaire '$ManagerName' :" -Level Info
    Write-Log -Message "- Chemin : $managerPath" -Level Info
    Write-Log -Message "- ActivÃ© : $managerEnabled" -Level Info
    Write-Log -Message "- Disponible : $managerAvailable" -Level Info
    Write-Log -Message "- EnregistrÃ© le : $($manager.RegisteredAt)" -Level Info

    return $status
}

# Fonction pour configurer un gestionnaire
function Set-Manager {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ManagerName,

        [Parameter(Mandatory = $false)]
        [bool]$Enabled,

        [Parameter(Mandatory = $false)]
        [string]$Path
    )

    # VÃ©rifier que le gestionnaire est enregistrÃ©
    if (-not $config.Managers.$ManagerName) {
        Write-Log -Message "Le gestionnaire '$ManagerName' n'est pas enregistrÃ©." -Level Error
        return $false
    }

    # Mettre Ã  jour la configuration
    if ($PSCmdlet.ShouldProcess($ManagerName, "Configurer le gestionnaire")) {
        $modified = $false

        if ($PSBoundParameters.ContainsKey('Enabled')) {
            $config.Managers.$ManagerName.Enabled = $Enabled
            Write-Log -Message "Ã‰tat du gestionnaire '$ManagerName' mis Ã  jour : $Enabled" -Level Info
            $modified = $true
        }

        if ($PSBoundParameters.ContainsKey('Path')) {
            # VÃ©rifier que le fichier existe
            if (Test-Path -Path $Path) {
                $config.Managers.$ManagerName.Path = $Path
                Write-Log -Message "Chemin du gestionnaire '$ManagerName' mis Ã  jour : $Path" -Level Info
                $modified = $true
            } else {
                Write-Log -Message "Le fichier spÃ©cifiÃ© n'existe pas : $Path" -Level Error
                return $false
            }
        }

        if ($modified) {
            # Enregistrer la configuration
            $config | ConvertTo-Json -Depth 10 | Set-Content -Path $configFilePath -Encoding UTF8
            Write-Log -Message "Configuration du gestionnaire '$ManagerName' mise Ã  jour avec succÃ¨s." -Level Info
            return $true
        } else {
            Write-Log -Message "Aucune modification apportÃ©e Ã  la configuration du gestionnaire '$ManagerName'." -Level Warning
            return $false
        }
    }

    return $false
}

# ExÃ©cuter la commande spÃ©cifiÃ©e
switch ($Command) {
    "Register" {
        if (-not $ManagerName -or -not $ManagerPath) {
            Write-Log -Message "Les paramÃ¨tres ManagerName et ManagerPath sont requis pour la commande Register." -Level Error
            exit 1
        }

        # Extraire les paramÃ¨tres supplÃ©mentaires
        $registerParams = @{
            Name  = $ManagerName
            Path  = $ManagerPath
            Force = $Force
        }

        # Ajouter les paramÃ¨tres optionnels
        if ($PSBoundParameters.ContainsKey('Version')) {
            $registerParams.Version = $Version
        }

        if ($PSBoundParameters.ContainsKey('SkipDependencyCheck')) {
            $registerParams.SkipDependencyCheck = $SkipDependencyCheck
        }

        if ($PSBoundParameters.ContainsKey('SkipValidation')) {
            $registerParams.SkipValidation = $SkipValidation
        }

        if ($PSBoundParameters.ContainsKey('SkipSecurityCheck')) {
            $registerParams.SkipSecurityCheck = $SkipSecurityCheck
        }

        Register-Manager @registerParams
    }

    "Discover" {
        # Extraire les paramÃ¨tres supplÃ©mentaires
        $discoverParams = @{
            Force = $Force
        }

        # Ajouter les paramÃ¨tres optionnels
        if ($PSBoundParameters.ContainsKey('SkipDependencyCheck')) {
            $discoverParams.SkipDependencyCheck = $SkipDependencyCheck
        }

        if ($PSBoundParameters.ContainsKey('SkipValidation')) {
            $discoverParams.SkipValidation = $SkipValidation
        }

        if ($PSBoundParameters.ContainsKey('SkipSecurityCheck')) {
            $discoverParams.SkipSecurityCheck = $SkipSecurityCheck
        }

        if ($PSBoundParameters.ContainsKey('SearchPaths')) {
            $discoverParams.SearchPaths = $SearchPaths
        }

        Find-Managers @discoverParams
    }

    "List" {
        Get-Managers -Detailed
    }

    "Run" {
        if (-not $ManagerName -or -not $ManagerCommand) {
            Write-Log -Message "Les paramÃ¨tres ManagerName et ManagerCommand sont requis pour la commande Run." -Level Error
            exit 1
        }

        # Extraire les paramÃ¨tres supplÃ©mentaires
        $params = @{}
        foreach ($param in $PSBoundParameters.Keys) {
            if ($param -notin @("Command", "ManagerName", "ManagerCommand", "ConfigPath", "LogLevel", "Force")) {
                $params[$param] = $PSBoundParameters[$param]
            }
        }

        Start-ManagerCommand -ManagerName $ManagerName -Command $ManagerCommand -Parameters $params
    }

    "Status" {
        if (-not $ManagerName) {
            Write-Log -Message "Le paramÃ¨tre ManagerName est requis pour la commande Status." -Level Error
            exit 1
        }

        Get-ManagerStatus -ManagerName $ManagerName
    }

    "Configure" {
        if (-not $ManagerName) {
            Write-Log -Message "Le paramÃ¨tre ManagerName est requis pour la commande Configure." -Level Error
            exit 1
        }

        # Extraire les paramÃ¨tres de configuration
        $configParams = @{
            ManagerName = $ManagerName
        }

        if ($PSBoundParameters.ContainsKey('Enabled')) {
            $configParams.Enabled = $Enabled
        }

        if ($PSBoundParameters.ContainsKey('ManagerPath')) {
            $configParams.Path = $ManagerPath
        }

        Set-Manager @configParams
    }
}


