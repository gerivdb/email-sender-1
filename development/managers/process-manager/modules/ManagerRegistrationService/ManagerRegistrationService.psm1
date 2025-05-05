<#
.SYNOPSIS
    Module de service d'enregistrement des gestionnaires pour le Process Manager.

.DESCRIPTION
    Ce module fournit des fonctionnalitÃ©s avancÃ©es pour l'enregistrement, la validation,
    la gestion des dÃ©pendances et la sÃ©curitÃ© des gestionnaires dans le Process Manager.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1
#>

#region Variables globales

# Chemin du fichier de configuration par dÃ©faut
$script:DefaultConfigPath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath "config\process-manager.config.json"

# Niveau de journalisation par dÃ©faut
$script:DefaultLogLevel = "Info"

# Chemin du journal par dÃ©faut
$script:DefaultLogPath = "logs/process-manager/registration-service.log"

#endregion

#region Fonctions privÃ©es

<#
.SYNOPSIS
    Ã‰crit un message dans le journal.

.DESCRIPTION
    Cette fonction Ã©crit un message dans le journal avec un niveau de gravitÃ© spÃ©cifiÃ©.

.PARAMETER Message
    Le message Ã  Ã©crire dans le journal.

.PARAMETER Level
    Le niveau de gravitÃ© du message (Debug, Info, Warning, Error).

.EXAMPLE
    Write-RegistrationLog -Message "Enregistrement du gestionnaire 'ModeManager'" -Level Info
#>
function Write-RegistrationLog {
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
        Debug = 0
        Info = 1
        Warning = 2
        Error = 3
    }

    # Obtenir la configuration
    $config = Get-RegistrationConfig

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
        
        # CrÃ©er le rÃ©pertoire de journaux s'il n'existe pas
        $logDir = Split-Path -Path $config.LogPath -Parent
        if (-not (Test-Path -Path $logDir -PathType Container)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }
        
        # Ã‰crire le message dans le fichier de journal
        $logFile = Join-Path -Path $logDir -ChildPath "registration-service_$(Get-Date -Format 'yyyy-MM-dd').log"
        Add-Content -Path $logFile -Value $logMessage -Encoding UTF8
    }
}

<#
.SYNOPSIS
    Obtient la configuration du service d'enregistrement.

.DESCRIPTION
    Cette fonction charge la configuration du service d'enregistrement Ã  partir du fichier de configuration.

.PARAMETER ConfigPath
    Le chemin vers le fichier de configuration. Si non spÃ©cifiÃ©, utilise le chemin par dÃ©faut.

.EXAMPLE
    $config = Get-RegistrationConfig
#>
function Get-RegistrationConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = $script:DefaultConfigPath
    )

    # VÃ©rifier si le fichier de configuration existe
    if (-not (Test-Path -Path $ConfigPath -PathType Leaf)) {
        # CrÃ©er le rÃ©pertoire de configuration s'il n'existe pas
        $configDir = Split-Path -Path $ConfigPath -Parent
        if (-not (Test-Path -Path $configDir -PathType Container)) {
            New-Item -Path $configDir -ItemType Directory -Force | Out-Null
        }
        
        # CrÃ©er un fichier de configuration par dÃ©faut
        $defaultConfig = @{
            Enabled = $true
            LogLevel = $script:DefaultLogLevel
            LogPath = $script:DefaultLogPath
            Managers = @{}
        }
        
        $defaultConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -Encoding UTF8
        Write-RegistrationLog -Message "Fichier de configuration crÃ©Ã© : $ConfigPath" -Level Info
        
        return $defaultConfig
    }
    
    # Charger la configuration
    try {
        $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
        return $config
    }
    catch {
        Write-RegistrationLog -Message "Erreur lors du chargement de la configuration : $_" -Level Error
        
        # Retourner une configuration par dÃ©faut en cas d'erreur
        return @{
            Enabled = $true
            LogLevel = $script:DefaultLogLevel
            LogPath = $script:DefaultLogPath
            Managers = @{}
        }
    }
}

<#
.SYNOPSIS
    Enregistre la configuration du service d'enregistrement.

.DESCRIPTION
    Cette fonction enregistre la configuration du service d'enregistrement dans le fichier de configuration.

.PARAMETER Config
    La configuration Ã  enregistrer.

.PARAMETER ConfigPath
    Le chemin vers le fichier de configuration. Si non spÃ©cifiÃ©, utilise le chemin par dÃ©faut.

.EXAMPLE
    Save-RegistrationConfig -Config $config
#>
function Save-RegistrationConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config,
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = $script:DefaultConfigPath
    )
    
    try {
        # CrÃ©er le rÃ©pertoire de configuration s'il n'existe pas
        $configDir = Split-Path -Path $ConfigPath -Parent
        if (-not (Test-Path -Path $configDir -PathType Container)) {
            New-Item -Path $configDir -ItemType Directory -Force | Out-Null
        }
        
        # Enregistrer la configuration
        $Config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -Encoding UTF8
        Write-RegistrationLog -Message "Configuration enregistrÃ©e : $ConfigPath" -Level Debug
        
        return $true
    }
    catch {
        Write-RegistrationLog -Message "Erreur lors de l'enregistrement de la configuration : $_" -Level Error
        return $false
    }
}

#endregion

#region Fonctions publiques

<#
.SYNOPSIS
    Enregistre un gestionnaire dans le Process Manager.

.DESCRIPTION
    Cette fonction enregistre un gestionnaire dans le Process Manager avec des fonctionnalitÃ©s avancÃ©es
    de validation, de gestion des dÃ©pendances et de sÃ©curitÃ©.

.PARAMETER Name
    Le nom du gestionnaire Ã  enregistrer.

.PARAMETER Path
    Le chemin vers le script du gestionnaire.

.PARAMETER Version
    La version du gestionnaire. Si non spÃ©cifiÃ©e, tente de l'extraire du manifeste.

.PARAMETER Force
    Force l'enregistrement mÃªme si le gestionnaire existe dÃ©jÃ .

.PARAMETER SkipDependencyCheck
    Ignore la vÃ©rification des dÃ©pendances.

.PARAMETER SkipValidation
    Ignore la validation du gestionnaire.

.PARAMETER SkipSecurityCheck
    Ignore les vÃ©rifications de sÃ©curitÃ©.

.PARAMETER ConfigPath
    Le chemin vers le fichier de configuration. Si non spÃ©cifiÃ©, utilise le chemin par dÃ©faut.

.EXAMPLE
    Register-Manager -Name "ModeManager" -Path "development\managers\mode-manager\scripts\mode-manager.ps1"

.EXAMPLE
    Register-Manager -Name "ModeManager" -Path "development\managers\mode-manager\scripts\mode-manager.ps1" -Version "1.0.0" -Force
#>
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
        [switch]$SkipSecurityCheck,

        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = $script:DefaultConfigPath
    )

    # Obtenir la configuration
    $config = Get-RegistrationConfig -ConfigPath $ConfigPath

    # VÃ©rifier que le fichier du gestionnaire existe
    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        Write-RegistrationLog -Message "Le fichier du gestionnaire n'existe pas : $Path" -Level Error
        return $false
    }

    # VÃ©rifier si le gestionnaire est dÃ©jÃ  enregistrÃ©
    if ($config.Managers.$Name -and -not $Force) {
        Write-RegistrationLog -Message "Le gestionnaire '$Name' est dÃ©jÃ  enregistrÃ©. Utilisez -Force pour le remplacer." -Level Warning
        return $false
    }

    # Extraire le manifeste si disponible (sera implÃ©mentÃ© dans le module ManifestParser)
    $manifest = $null
    if (-not $SkipValidation) {
        # Cette partie sera implÃ©mentÃ©e dans le module ManifestParser
        Write-RegistrationLog -Message "Extraction du manifeste non implÃ©mentÃ©e. Utilisation des valeurs par dÃ©faut." -Level Warning
    }

    # DÃ©terminer la version
    if (-not $Version) {
        if ($manifest -and $manifest.Version) {
            $Version = $manifest.Version
        } else {
            $Version = "1.0.0"
            Write-RegistrationLog -Message "Version non spÃ©cifiÃ©e et non trouvÃ©e dans le manifeste. Utilisation de la version par dÃ©faut : $Version" -Level Warning
        }
    }

    # Valider le gestionnaire (sera implÃ©mentÃ© dans le module ValidationService)
    if (-not $SkipValidation) {
        # Cette partie sera implÃ©mentÃ©e dans le module ValidationService
        Write-RegistrationLog -Message "Validation du gestionnaire non implÃ©mentÃ©e. Poursuite de l'enregistrement." -Level Warning
    }

    # VÃ©rifier les dÃ©pendances (sera implÃ©mentÃ© dans le module DependencyResolver)
    if (-not $SkipDependencyCheck) {
        # Cette partie sera implÃ©mentÃ©e dans le module DependencyResolver
        Write-RegistrationLog -Message "VÃ©rification des dÃ©pendances non implÃ©mentÃ©e. Poursuite de l'enregistrement." -Level Warning
    }

    # VÃ©rifier la sÃ©curitÃ© (sera implÃ©mentÃ© dans le module SecurityService)
    if (-not $SkipSecurityCheck) {
        # Cette partie sera implÃ©mentÃ©e dans le module SecurityService
        Write-RegistrationLog -Message "VÃ©rification de sÃ©curitÃ© non implÃ©mentÃ©e. Poursuite de l'enregistrement." -Level Warning
    }

    # Enregistrer le gestionnaire
    if ($PSCmdlet.ShouldProcess($Name, "Enregistrer le gestionnaire")) {
        # CrÃ©er ou mettre Ã  jour l'entrÃ©e du gestionnaire
        $managerEntry = @{
            Path = $Path
            Version = $Version
            Enabled = $true
            RegisteredAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            LastUpdatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }

        # Ajouter des mÃ©tadonnÃ©es supplÃ©mentaires si disponibles
        if ($manifest) {
            if ($manifest.Description) {
                $managerEntry.Description = $manifest.Description
            }
            if ($manifest.Author) {
                $managerEntry.Author = $manifest.Author
            }
            if ($manifest.Dependencies) {
                $managerEntry.Dependencies = $manifest.Dependencies
            }
            if ($manifest.Capabilities) {
                $managerEntry.Capabilities = $manifest.Capabilities
            }
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
        if (Save-RegistrationConfig -Config $config -ConfigPath $ConfigPath) {
            Write-RegistrationLog -Message "Gestionnaire '$Name' enregistrÃ© avec succÃ¨s (version $Version)." -Level Info
            return $true
        } else {
            Write-RegistrationLog -Message "Erreur lors de l'enregistrement de la configuration pour le gestionnaire '$Name'." -Level Error
            return $false
        }
    }

    return $false
}

<#
.SYNOPSIS
    DÃ©senregistre un gestionnaire du Process Manager.

.DESCRIPTION
    Cette fonction supprime l'enregistrement d'un gestionnaire du Process Manager.

.PARAMETER Name
    Le nom du gestionnaire Ã  dÃ©senregistrer.

.PARAMETER Version
    La version spÃ©cifique du gestionnaire Ã  dÃ©senregistrer. Si non spÃ©cifiÃ©e, dÃ©senregistre toutes les versions.

.PARAMETER Force
    Force le dÃ©senregistrement sans demander de confirmation.

.PARAMETER ConfigPath
    Le chemin vers le fichier de configuration. Si non spÃ©cifiÃ©, utilise le chemin par dÃ©faut.

.EXAMPLE
    Unregister-Manager -Name "ModeManager"

.EXAMPLE
    Unregister-Manager -Name "ModeManager" -Version "1.0.0" -Force
#>
function Unregister-Manager {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [string]$Version,

        [Parameter(Mandatory = $false)]
        [switch]$Force,

        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = $script:DefaultConfigPath
    )

    # Obtenir la configuration
    $config = Get-RegistrationConfig -ConfigPath $ConfigPath

    # VÃ©rifier si le gestionnaire est enregistrÃ©
    if (-not $config.Managers.PSObject.Properties.Name -contains $Name) {
        Write-RegistrationLog -Message "Le gestionnaire '$Name' n'est pas enregistrÃ©." -Level Warning
        return $false
    }

    # VÃ©rifier la version si spÃ©cifiÃ©e
    if ($Version -and $config.Managers.$Name.Version -ne $Version) {
        Write-RegistrationLog -Message "La version '$Version' du gestionnaire '$Name' n'est pas enregistrÃ©e." -Level Warning
        return $false
    }

    # DÃ©senregistrer le gestionnaire
    if ($PSCmdlet.ShouldProcess($Name, "DÃ©senregistrer le gestionnaire")) {
        # Supprimer le gestionnaire de la configuration
        $config.Managers.PSObject.Properties.Remove($Name)

        # Enregistrer la configuration
        if (Save-RegistrationConfig -Config $config -ConfigPath $ConfigPath) {
            Write-RegistrationLog -Message "Gestionnaire '$Name' dÃ©senregistrÃ© avec succÃ¨s." -Level Info
            return $true
        } else {
            Write-RegistrationLog -Message "Erreur lors de l'enregistrement de la configuration aprÃ¨s dÃ©senregistrement du gestionnaire '$Name'." -Level Error
            return $false
        }
    }

    return $false
}

<#
.SYNOPSIS
    Met Ã  jour un gestionnaire dans le Process Manager.

.DESCRIPTION
    Cette fonction met Ã  jour l'enregistrement d'un gestionnaire dans le Process Manager.

.PARAMETER Name
    Le nom du gestionnaire Ã  mettre Ã  jour.

.PARAMETER Path
    Le nouveau chemin vers le script du gestionnaire.

.PARAMETER Version
    La nouvelle version du gestionnaire.

.PARAMETER Force
    Force la mise Ã  jour sans demander de confirmation.

.PARAMETER SkipDependencyCheck
    Ignore la vÃ©rification des dÃ©pendances.

.PARAMETER SkipValidation
    Ignore la validation du gestionnaire.

.PARAMETER SkipSecurityCheck
    Ignore les vÃ©rifications de sÃ©curitÃ©.

.PARAMETER ConfigPath
    Le chemin vers le fichier de configuration. Si non spÃ©cifiÃ©, utilise le chemin par dÃ©faut.

.EXAMPLE
    Update-Manager -Name "ModeManager" -Path "development\managers\mode-manager\scripts\mode-manager.ps1" -Version "1.1.0"

.EXAMPLE
    Update-Manager -Name "ModeManager" -Path "development\managers\mode-manager\scripts\mode-manager.ps1" -Force
#>
function Update-Manager {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
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
        [switch]$SkipSecurityCheck,

        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = $script:DefaultConfigPath
    )

    # Obtenir la configuration
    $config = Get-RegistrationConfig -ConfigPath $ConfigPath

    # VÃ©rifier si le gestionnaire est enregistrÃ©
    if (-not $config.Managers.PSObject.Properties.Name -contains $Name) {
        Write-RegistrationLog -Message "Le gestionnaire '$Name' n'est pas enregistrÃ©." -Level Warning
        return $false
    }

    # Utiliser le chemin existant si non spÃ©cifiÃ©
    if (-not $Path) {
        $Path = $config.Managers.$Name.Path
    }

    # VÃ©rifier que le fichier du gestionnaire existe
    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        Write-RegistrationLog -Message "Le fichier du gestionnaire n'existe pas : $Path" -Level Error
        return $false
    }

    # Utiliser la version existante si non spÃ©cifiÃ©e
    if (-not $Version) {
        $Version = $config.Managers.$Name.Version
    }

    # Mettre Ã  jour le gestionnaire
    if ($PSCmdlet.ShouldProcess($Name, "Mettre Ã  jour le gestionnaire")) {
        # Appeler Register-Manager avec les paramÃ¨tres appropriÃ©s
        $registerParams = @{
            Name = $Name
            Path = $Path
            Version = $Version
            Force = $true
            ConfigPath = $ConfigPath
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

        $result = Register-Manager @registerParams

        if ($result) {
            Write-RegistrationLog -Message "Gestionnaire '$Name' mis Ã  jour avec succÃ¨s (version $Version)." -Level Info
            return $true
        } else {
            Write-RegistrationLog -Message "Erreur lors de la mise Ã  jour du gestionnaire '$Name'." -Level Error
            return $false
        }
    }

    return $false
}

<#
.SYNOPSIS
    Obtient les informations sur un ou plusieurs gestionnaires enregistrÃ©s.

.DESCRIPTION
    Cette fonction rÃ©cupÃ¨re les informations sur les gestionnaires enregistrÃ©s dans le Process Manager.

.PARAMETER Name
    Le nom du gestionnaire Ã  rÃ©cupÃ©rer. Si non spÃ©cifiÃ©, rÃ©cupÃ¨re tous les gestionnaires.

.PARAMETER Detailed
    Affiche des informations dÃ©taillÃ©es sur les gestionnaires.

.PARAMETER ConfigPath
    Le chemin vers le fichier de configuration. Si non spÃ©cifiÃ©, utilise le chemin par dÃ©faut.

.EXAMPLE
    Get-RegisteredManager

.EXAMPLE
    Get-RegisteredManager -Name "ModeManager" -Detailed
#>
function Get-RegisteredManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [switch]$Detailed,

        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = $script:DefaultConfigPath
    )

    # Obtenir la configuration
    $config = Get-RegistrationConfig -ConfigPath $ConfigPath

    # VÃ©rifier si des gestionnaires sont enregistrÃ©s
    if (-not $config.Managers -or $config.Managers.PSObject.Properties.Count -eq 0) {
        Write-RegistrationLog -Message "Aucun gestionnaire n'est enregistrÃ©." -Level Info
        return @()
    }

    # Filtrer par nom si spÃ©cifiÃ©
    if ($Name) {
        if (-not $config.Managers.PSObject.Properties.Name -contains $Name) {
            Write-RegistrationLog -Message "Le gestionnaire '$Name' n'est pas enregistrÃ©." -Level Warning
            return @()
        }

        $managers = @($config.Managers.$Name)
        $managers | Add-Member -NotePropertyName Name -NotePropertyValue $Name -Force
    } else {
        # RÃ©cupÃ©rer tous les gestionnaires
        $managers = @()
        foreach ($managerName in $config.Managers.PSObject.Properties.Name) {
            $manager = $config.Managers.$managerName
            $manager | Add-Member -NotePropertyName Name -NotePropertyValue $managerName -Force
            $managers += $manager
        }
    }

    # Retourner les gestionnaires
    return $managers
}

<#
.SYNOPSIS
    Recherche des gestionnaires enregistrÃ©s selon des critÃ¨res spÃ©cifiques.

.DESCRIPTION
    Cette fonction recherche des gestionnaires enregistrÃ©s dans le Process Manager selon des critÃ¨res spÃ©cifiques.

.PARAMETER Criteria
    Les critÃ¨res de recherche sous forme de hashtable.

.PARAMETER ConfigPath
    Le chemin vers le fichier de configuration. Si non spÃ©cifiÃ©, utilise le chemin par dÃ©faut.

.EXAMPLE
    Find-Manager -Criteria @{ Version = "1.0.0" }

.EXAMPLE
    Find-Manager -Criteria @{ Author = "EMAIL_SENDER_1"; Enabled = $true }
#>
function Find-Manager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Criteria,

        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = $script:DefaultConfigPath
    )

    # Obtenir tous les gestionnaires
    $managers = Get-RegisteredManager -ConfigPath $ConfigPath

    # Filtrer selon les critÃ¨res
    $filteredManagers = @()
    foreach ($manager in $managers) {
        $match = $true
        foreach ($key in $Criteria.Keys) {
            if ($manager.PSObject.Properties.Name -contains $key) {
                if ($manager.$key -ne $Criteria[$key]) {
                    $match = $false
                    break
                }
            } else {
                $match = $false
                break
            }
        }

        if ($match) {
            $filteredManagers += $manager
        }
    }

    # Retourner les gestionnaires filtrÃ©s
    return $filteredManagers
}

#endregion

# Exporter les fonctions publiques
Export-ModuleMember -Function Register-Manager, Unregister-Manager, Update-Manager, Get-RegisteredManager, Find-Manager
