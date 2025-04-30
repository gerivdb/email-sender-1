<#
.SYNOPSIS
    Module de service d'enregistrement des gestionnaires pour le Process Manager.

.DESCRIPTION
    Ce module fournit des fonctionnalités avancées pour l'enregistrement, la validation,
    la gestion des dépendances et la sécurité des gestionnaires dans le Process Manager.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1
#>

#region Variables globales

# Chemin du fichier de configuration par défaut
$script:DefaultConfigPath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath "config\process-manager.config.json"

# Niveau de journalisation par défaut
$script:DefaultLogLevel = "Info"

# Chemin du journal par défaut
$script:DefaultLogPath = "logs/process-manager/registration-service.log"

#endregion

#region Fonctions privées

<#
.SYNOPSIS
    Écrit un message dans le journal.

.DESCRIPTION
    Cette fonction écrit un message dans le journal avec un niveau de gravité spécifié.

.PARAMETER Message
    Le message à écrire dans le journal.

.PARAMETER Level
    Le niveau de gravité du message (Debug, Info, Warning, Error).

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

    # Définir les niveaux de journalisation
    $logLevels = @{
        Debug = 0
        Info = 1
        Warning = 2
        Error = 3
    }

    # Obtenir la configuration
    $config = Get-RegistrationConfig

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
        
        # Créer le répertoire de journaux s'il n'existe pas
        $logDir = Split-Path -Path $config.LogPath -Parent
        if (-not (Test-Path -Path $logDir -PathType Container)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }
        
        # Écrire le message dans le fichier de journal
        $logFile = Join-Path -Path $logDir -ChildPath "registration-service_$(Get-Date -Format 'yyyy-MM-dd').log"
        Add-Content -Path $logFile -Value $logMessage -Encoding UTF8
    }
}

<#
.SYNOPSIS
    Obtient la configuration du service d'enregistrement.

.DESCRIPTION
    Cette fonction charge la configuration du service d'enregistrement à partir du fichier de configuration.

.PARAMETER ConfigPath
    Le chemin vers le fichier de configuration. Si non spécifié, utilise le chemin par défaut.

.EXAMPLE
    $config = Get-RegistrationConfig
#>
function Get-RegistrationConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = $script:DefaultConfigPath
    )

    # Vérifier si le fichier de configuration existe
    if (-not (Test-Path -Path $ConfigPath -PathType Leaf)) {
        # Créer le répertoire de configuration s'il n'existe pas
        $configDir = Split-Path -Path $ConfigPath -Parent
        if (-not (Test-Path -Path $configDir -PathType Container)) {
            New-Item -Path $configDir -ItemType Directory -Force | Out-Null
        }
        
        # Créer un fichier de configuration par défaut
        $defaultConfig = @{
            Enabled = $true
            LogLevel = $script:DefaultLogLevel
            LogPath = $script:DefaultLogPath
            Managers = @{}
        }
        
        $defaultConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -Encoding UTF8
        Write-RegistrationLog -Message "Fichier de configuration créé : $ConfigPath" -Level Info
        
        return $defaultConfig
    }
    
    # Charger la configuration
    try {
        $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
        return $config
    }
    catch {
        Write-RegistrationLog -Message "Erreur lors du chargement de la configuration : $_" -Level Error
        
        # Retourner une configuration par défaut en cas d'erreur
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
    La configuration à enregistrer.

.PARAMETER ConfigPath
    Le chemin vers le fichier de configuration. Si non spécifié, utilise le chemin par défaut.

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
        # Créer le répertoire de configuration s'il n'existe pas
        $configDir = Split-Path -Path $ConfigPath -Parent
        if (-not (Test-Path -Path $configDir -PathType Container)) {
            New-Item -Path $configDir -ItemType Directory -Force | Out-Null
        }
        
        # Enregistrer la configuration
        $Config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -Encoding UTF8
        Write-RegistrationLog -Message "Configuration enregistrée : $ConfigPath" -Level Debug
        
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
    Cette fonction enregistre un gestionnaire dans le Process Manager avec des fonctionnalités avancées
    de validation, de gestion des dépendances et de sécurité.

.PARAMETER Name
    Le nom du gestionnaire à enregistrer.

.PARAMETER Path
    Le chemin vers le script du gestionnaire.

.PARAMETER Version
    La version du gestionnaire. Si non spécifiée, tente de l'extraire du manifeste.

.PARAMETER Force
    Force l'enregistrement même si le gestionnaire existe déjà.

.PARAMETER SkipDependencyCheck
    Ignore la vérification des dépendances.

.PARAMETER SkipValidation
    Ignore la validation du gestionnaire.

.PARAMETER SkipSecurityCheck
    Ignore les vérifications de sécurité.

.PARAMETER ConfigPath
    Le chemin vers le fichier de configuration. Si non spécifié, utilise le chemin par défaut.

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

    # Vérifier que le fichier du gestionnaire existe
    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        Write-RegistrationLog -Message "Le fichier du gestionnaire n'existe pas : $Path" -Level Error
        return $false
    }

    # Vérifier si le gestionnaire est déjà enregistré
    if ($config.Managers.$Name -and -not $Force) {
        Write-RegistrationLog -Message "Le gestionnaire '$Name' est déjà enregistré. Utilisez -Force pour le remplacer." -Level Warning
        return $false
    }

    # Extraire le manifeste si disponible (sera implémenté dans le module ManifestParser)
    $manifest = $null
    if (-not $SkipValidation) {
        # Cette partie sera implémentée dans le module ManifestParser
        Write-RegistrationLog -Message "Extraction du manifeste non implémentée. Utilisation des valeurs par défaut." -Level Warning
    }

    # Déterminer la version
    if (-not $Version) {
        if ($manifest -and $manifest.Version) {
            $Version = $manifest.Version
        } else {
            $Version = "1.0.0"
            Write-RegistrationLog -Message "Version non spécifiée et non trouvée dans le manifeste. Utilisation de la version par défaut : $Version" -Level Warning
        }
    }

    # Valider le gestionnaire (sera implémenté dans le module ValidationService)
    if (-not $SkipValidation) {
        # Cette partie sera implémentée dans le module ValidationService
        Write-RegistrationLog -Message "Validation du gestionnaire non implémentée. Poursuite de l'enregistrement." -Level Warning
    }

    # Vérifier les dépendances (sera implémenté dans le module DependencyResolver)
    if (-not $SkipDependencyCheck) {
        # Cette partie sera implémentée dans le module DependencyResolver
        Write-RegistrationLog -Message "Vérification des dépendances non implémentée. Poursuite de l'enregistrement." -Level Warning
    }

    # Vérifier la sécurité (sera implémenté dans le module SecurityService)
    if (-not $SkipSecurityCheck) {
        # Cette partie sera implémentée dans le module SecurityService
        Write-RegistrationLog -Message "Vérification de sécurité non implémentée. Poursuite de l'enregistrement." -Level Warning
    }

    # Enregistrer le gestionnaire
    if ($PSCmdlet.ShouldProcess($Name, "Enregistrer le gestionnaire")) {
        # Créer ou mettre à jour l'entrée du gestionnaire
        $managerEntry = @{
            Path = $Path
            Version = $Version
            Enabled = $true
            RegisteredAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            LastUpdatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }

        # Ajouter des métadonnées supplémentaires si disponibles
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

        # Mettre à jour la configuration
        if ($config.Managers.PSObject.Properties.Name -contains $Name) {
            # Mettre à jour un gestionnaire existant
            $config.Managers.$Name = $managerEntry
        } else {
            # Ajouter un nouveau gestionnaire
            $config.Managers | Add-Member -NotePropertyName $Name -NotePropertyValue $managerEntry -Force
        }

        # Enregistrer la configuration
        if (Save-RegistrationConfig -Config $config -ConfigPath $ConfigPath) {
            Write-RegistrationLog -Message "Gestionnaire '$Name' enregistré avec succès (version $Version)." -Level Info
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
    Désenregistre un gestionnaire du Process Manager.

.DESCRIPTION
    Cette fonction supprime l'enregistrement d'un gestionnaire du Process Manager.

.PARAMETER Name
    Le nom du gestionnaire à désenregistrer.

.PARAMETER Version
    La version spécifique du gestionnaire à désenregistrer. Si non spécifiée, désenregistre toutes les versions.

.PARAMETER Force
    Force le désenregistrement sans demander de confirmation.

.PARAMETER ConfigPath
    Le chemin vers le fichier de configuration. Si non spécifié, utilise le chemin par défaut.

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

    # Vérifier si le gestionnaire est enregistré
    if (-not $config.Managers.PSObject.Properties.Name -contains $Name) {
        Write-RegistrationLog -Message "Le gestionnaire '$Name' n'est pas enregistré." -Level Warning
        return $false
    }

    # Vérifier la version si spécifiée
    if ($Version -and $config.Managers.$Name.Version -ne $Version) {
        Write-RegistrationLog -Message "La version '$Version' du gestionnaire '$Name' n'est pas enregistrée." -Level Warning
        return $false
    }

    # Désenregistrer le gestionnaire
    if ($PSCmdlet.ShouldProcess($Name, "Désenregistrer le gestionnaire")) {
        # Supprimer le gestionnaire de la configuration
        $config.Managers.PSObject.Properties.Remove($Name)

        # Enregistrer la configuration
        if (Save-RegistrationConfig -Config $config -ConfigPath $ConfigPath) {
            Write-RegistrationLog -Message "Gestionnaire '$Name' désenregistré avec succès." -Level Info
            return $true
        } else {
            Write-RegistrationLog -Message "Erreur lors de l'enregistrement de la configuration après désenregistrement du gestionnaire '$Name'." -Level Error
            return $false
        }
    }

    return $false
}

<#
.SYNOPSIS
    Met à jour un gestionnaire dans le Process Manager.

.DESCRIPTION
    Cette fonction met à jour l'enregistrement d'un gestionnaire dans le Process Manager.

.PARAMETER Name
    Le nom du gestionnaire à mettre à jour.

.PARAMETER Path
    Le nouveau chemin vers le script du gestionnaire.

.PARAMETER Version
    La nouvelle version du gestionnaire.

.PARAMETER Force
    Force la mise à jour sans demander de confirmation.

.PARAMETER SkipDependencyCheck
    Ignore la vérification des dépendances.

.PARAMETER SkipValidation
    Ignore la validation du gestionnaire.

.PARAMETER SkipSecurityCheck
    Ignore les vérifications de sécurité.

.PARAMETER ConfigPath
    Le chemin vers le fichier de configuration. Si non spécifié, utilise le chemin par défaut.

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

    # Vérifier si le gestionnaire est enregistré
    if (-not $config.Managers.PSObject.Properties.Name -contains $Name) {
        Write-RegistrationLog -Message "Le gestionnaire '$Name' n'est pas enregistré." -Level Warning
        return $false
    }

    # Utiliser le chemin existant si non spécifié
    if (-not $Path) {
        $Path = $config.Managers.$Name.Path
    }

    # Vérifier que le fichier du gestionnaire existe
    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        Write-RegistrationLog -Message "Le fichier du gestionnaire n'existe pas : $Path" -Level Error
        return $false
    }

    # Utiliser la version existante si non spécifiée
    if (-not $Version) {
        $Version = $config.Managers.$Name.Version
    }

    # Mettre à jour le gestionnaire
    if ($PSCmdlet.ShouldProcess($Name, "Mettre à jour le gestionnaire")) {
        # Appeler Register-Manager avec les paramètres appropriés
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
            Write-RegistrationLog -Message "Gestionnaire '$Name' mis à jour avec succès (version $Version)." -Level Info
            return $true
        } else {
            Write-RegistrationLog -Message "Erreur lors de la mise à jour du gestionnaire '$Name'." -Level Error
            return $false
        }
    }

    return $false
}

<#
.SYNOPSIS
    Obtient les informations sur un ou plusieurs gestionnaires enregistrés.

.DESCRIPTION
    Cette fonction récupère les informations sur les gestionnaires enregistrés dans le Process Manager.

.PARAMETER Name
    Le nom du gestionnaire à récupérer. Si non spécifié, récupère tous les gestionnaires.

.PARAMETER Detailed
    Affiche des informations détaillées sur les gestionnaires.

.PARAMETER ConfigPath
    Le chemin vers le fichier de configuration. Si non spécifié, utilise le chemin par défaut.

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

    # Vérifier si des gestionnaires sont enregistrés
    if (-not $config.Managers -or $config.Managers.PSObject.Properties.Count -eq 0) {
        Write-RegistrationLog -Message "Aucun gestionnaire n'est enregistré." -Level Info
        return @()
    }

    # Filtrer par nom si spécifié
    if ($Name) {
        if (-not $config.Managers.PSObject.Properties.Name -contains $Name) {
            Write-RegistrationLog -Message "Le gestionnaire '$Name' n'est pas enregistré." -Level Warning
            return @()
        }

        $managers = @($config.Managers.$Name)
        $managers | Add-Member -NotePropertyName Name -NotePropertyValue $Name -Force
    } else {
        # Récupérer tous les gestionnaires
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
    Recherche des gestionnaires enregistrés selon des critères spécifiques.

.DESCRIPTION
    Cette fonction recherche des gestionnaires enregistrés dans le Process Manager selon des critères spécifiques.

.PARAMETER Criteria
    Les critères de recherche sous forme de hashtable.

.PARAMETER ConfigPath
    Le chemin vers le fichier de configuration. Si non spécifié, utilise le chemin par défaut.

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

    # Filtrer selon les critères
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

    # Retourner les gestionnaires filtrés
    return $filteredManagers
}

#endregion

# Exporter les fonctions publiques
Export-ModuleMember -Function Register-Manager, Unregister-Manager, Update-Manager, Get-RegisteredManager, Find-Manager
