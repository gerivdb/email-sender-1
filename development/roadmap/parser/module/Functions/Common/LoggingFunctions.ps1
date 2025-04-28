<#
.SYNOPSIS
    Fonctions de journalisation pour les modes RoadmapParser.

.DESCRIPTION
    Ce script contient des fonctions pour la journalisation des Ã©vÃ©nements
    dans les diffÃ©rents modes de RoadmapParser.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.1
    Date de crÃ©ation: 2023-08-15
    Date de mise Ã  jour: 2023-08-16
#>

# Importer les fonctions de rotation des journaux
. "$PSScriptRoot\LogRotationFunctions.ps1"

# Importer les fonctions de verbositÃ©
. "$PSScriptRoot\VerbosityFunctions.ps1"

# Variable globale pour le niveau de journalisation
$script:LoggingLevel = "INFO"

# Niveaux de journalisation disponibles
$script:LoggingLevels = @{
    "ERROR"   = 0
    "WARNING" = 1
    "INFO"    = 2
    "VERBOSE" = 3
    "DEBUG"   = 4
}

# Couleurs pour les diffÃ©rents niveaux de journalisation
$script:LoggingColors = @{
    "ERROR"   = "Red"
    "WARNING" = "Yellow"
    "INFO"    = "White"
    "VERBOSE" = "Gray"
    "DEBUG"   = "DarkGray"
}

# Configuration de journalisation
$script:LoggingConfig = @{
    # Fichier de journal par dÃ©faut
    DefaultLogFile  = "logs\roadmap-parser.log"

    # Activer la rotation des journaux
    EnableRotation  = $true

    # Activer la verbositÃ© configurable
    EnableVerbosity = $true
}

<#
.SYNOPSIS
    DÃ©finit le niveau de journalisation.

.DESCRIPTION
    Cette fonction dÃ©finit le niveau de journalisation pour les fonctions de journalisation.

.PARAMETER Level
    Niveau de journalisation Ã  utiliser. Les valeurs possibles sont : ERROR, WARNING, INFO, VERBOSE, DEBUG.

.EXAMPLE
    Set-LoggingLevel -Level "DEBUG"

.OUTPUTS
    None
#>
function Set-LoggingLevel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("ERROR", "WARNING", "INFO", "VERBOSE", "DEBUG")]
        [string]$Level
    )

    $script:LoggingLevel = $Level
    Write-Host "Niveau de journalisation dÃ©fini Ã  : $Level" -ForegroundColor $script:LoggingColors[$Level]
}

<#
.SYNOPSIS
    Retourne le niveau de journalisation actuel.

.DESCRIPTION
    Cette fonction retourne le niveau de journalisation actuel.

.EXAMPLE
    $level = Get-LoggingLevel

.OUTPUTS
    System.String
#>
function Get-LoggingLevel {
    [CmdletBinding()]
    param()

    return $script:LoggingLevel
}

<#
.SYNOPSIS
    VÃ©rifie si un message doit Ãªtre journalisÃ© en fonction du niveau de journalisation actuel.

.DESCRIPTION
    Cette fonction vÃ©rifie si un message doit Ãªtre journalisÃ© en fonction du niveau de journalisation actuel.

.PARAMETER Level
    Niveau de journalisation du message.

.EXAMPLE
    $shouldLog = Test-LoggingLevel -Level "DEBUG"

.OUTPUTS
    System.Boolean
#>
function Test-LoggingLevel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("ERROR", "WARNING", "INFO", "VERBOSE", "DEBUG")]
        [string]$Level
    )

    return $script:LoggingLevels[$Level] -le $script:LoggingLevels[$script:LoggingLevel]
}

<#
.SYNOPSIS
    Journalise un message d'erreur.

.DESCRIPTION
    Cette fonction journalise un message d'erreur.

.PARAMETER Message
    Message Ã  journaliser.

.EXAMPLE
    Write-LogError "Une erreur s'est produite."

.OUTPUTS
    None
#>
function Write-LogError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message
    )

    if (Test-LoggingLevel -Level "ERROR") {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$timestamp] [ERROR] $Message" -ForegroundColor $script:LoggingColors["ERROR"]
    }
}

<#
.SYNOPSIS
    Journalise un message d'avertissement.

.DESCRIPTION
    Cette fonction journalise un message d'avertissement.

.PARAMETER Message
    Message Ã  journaliser.

.EXAMPLE
    Write-LogWarning "Attention, cette opÃ©ration peut Ãªtre dangereuse."

.OUTPUTS
    None
#>
function Write-LogWarning {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message
    )

    if (Test-LoggingLevel -Level "WARNING") {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$timestamp] [WARNING] $Message" -ForegroundColor $script:LoggingColors["WARNING"]
    }
}

<#
.SYNOPSIS
    Journalise un message d'information.

.DESCRIPTION
    Cette fonction journalise un message d'information.

.PARAMETER Message
    Message Ã  journaliser.

.EXAMPLE
    Write-LogInfo "Traitement en cours..."

.OUTPUTS
    None
#>
function Write-LogInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message
    )

    if (Test-LoggingLevel -Level "INFO") {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$timestamp] [INFO] $Message" -ForegroundColor $script:LoggingColors["INFO"]
    }
}

<#
.SYNOPSIS
    Journalise un message dÃ©taillÃ©.

.DESCRIPTION
    Cette fonction journalise un message dÃ©taillÃ©.

.PARAMETER Message
    Message Ã  journaliser.

.EXAMPLE
    Write-LogVerbose "DÃ©tails supplÃ©mentaires sur le traitement en cours..."

.OUTPUTS
    None
#>
function Write-LogVerbose {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message
    )

    if (Test-LoggingLevel -Level "VERBOSE") {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$timestamp] [VERBOSE] $Message" -ForegroundColor $script:LoggingColors["VERBOSE"]
    }
}

<#
.SYNOPSIS
    Journalise un message de dÃ©bogage.

.DESCRIPTION
    Cette fonction journalise un message de dÃ©bogage.

.PARAMETER Message
    Message Ã  journaliser.

.EXAMPLE
    Write-LogDebug "Valeur de la variable x : $x"

.OUTPUTS
    None
#>
function Write-LogDebug {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message
    )

    if (Test-LoggingLevel -Level "DEBUG") {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$timestamp] [DEBUG] $Message" -ForegroundColor $script:LoggingColors["DEBUG"]
    }
}

<#
.SYNOPSIS
    Journalise un message dans un fichier.

.DESCRIPTION
    Cette fonction journalise un message dans un fichier.
    Elle prend en charge la rotation des journaux si celle-ci est activÃ©e.

.PARAMETER Message
    Message Ã  journaliser.

.PARAMETER Level
    Niveau de journalisation du message.

.PARAMETER LogFile
    Chemin vers le fichier de journalisation.

.PARAMETER Category
    CatÃ©gorie du message.

.PARAMETER Source
    Source du message.

.PARAMETER Id
    Identifiant du message.

.PARAMETER NoRotation
    Indique si la rotation des journaux doit Ãªtre dÃ©sactivÃ©e pour cet appel.

.EXAMPLE
    Write-LogToFile -Message "Une erreur s'est produite." -Level "ERROR" -LogFile "logs\error.log"

.EXAMPLE
    Write-LogToFile -Message "Connexion Ã  la base de donnÃ©es." -Level "INFO" -LogFile "logs\app.log" -Category "Database" -Source "Repository" -Id "DB001"

.OUTPUTS
    None
#>
function Write-LogToFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("ERROR", "WARNING", "INFO", "VERBOSE", "DEBUG")]
        [string]$Level,

        [Parameter(Mandatory = $true, Position = 2)]
        [string]$LogFile,

        [Parameter(Mandatory = $false)]
        [string]$Category = "General",

        [Parameter(Mandatory = $false)]
        [string]$Source = "",

        [Parameter(Mandatory = $false)]
        [string]$Id = "",

        [Parameter(Mandatory = $false)]
        [switch]$NoRotation
    )

    if (Test-LoggingLevel -Level $Level) {
        # CrÃ©er le rÃ©pertoire parent s'il n'existe pas
        $parentDir = Split-Path -Parent $LogFile
        if (-not [string]::IsNullOrEmpty($parentDir) -and -not (Test-Path -Path $parentDir)) {
            New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
        }

        # VÃ©rifier si la rotation des journaux est nÃ©cessaire
        if ($script:LoggingConfig.EnableRotation -and -not $NoRotation) {
            if (Test-Path -Path $LogFile) {
                Invoke-LogRotation -LogFile $LogFile
            }
        }

        # Formater le message en fonction de la verbositÃ© si activÃ©e
        if ($script:LoggingConfig.EnableVerbosity) {
            $logMessage = Format-MessageByVerbosity -Message $Message -Level $Level -Category $Category -Source $Source -Id $Id
        } else {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logMessage = "[$timestamp] [$Level] $Message"
        }

        Add-Content -Path $LogFile -Value $logMessage -Encoding UTF8
    }
}

<#
.SYNOPSIS
    Journalise un message Ã  la fois dans la console et dans un fichier.

.DESCRIPTION
    Cette fonction journalise un message Ã  la fois dans la console et dans un fichier.
    Elle prend en charge la rotation des journaux et la verbositÃ© configurable.

.PARAMETER Message
    Message Ã  journaliser.

.PARAMETER Level
    Niveau de journalisation du message.

.PARAMETER LogFile
    Chemin vers le fichier de journalisation.

.PARAMETER Category
    CatÃ©gorie du message.

.PARAMETER Source
    Source du message.

.PARAMETER Id
    Identifiant du message.

.PARAMETER NoRotation
    Indique si la rotation des journaux doit Ãªtre dÃ©sactivÃ©e pour cet appel.

.EXAMPLE
    Write-Log -Message "Une erreur s'est produite." -Level "ERROR" -LogFile "logs\error.log"

.EXAMPLE
    Write-Log -Message "Connexion Ã  la base de donnÃ©es." -Level "INFO" -LogFile "logs\app.log" -Category "Database" -Source "Repository" -Id "DB001"

.OUTPUTS
    None
#>
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("ERROR", "WARNING", "INFO", "VERBOSE", "DEBUG")]
        [string]$Level,

        [Parameter(Mandatory = $false, Position = 2)]
        [string]$LogFile,

        [Parameter(Mandatory = $false)]
        [string]$Category = "General",

        [Parameter(Mandatory = $false)]
        [string]$Source = "",

        [Parameter(Mandatory = $false)]
        [string]$Id = "",

        [Parameter(Mandatory = $false)]
        [switch]$NoRotation
    )

    if ($script:LoggingConfig.EnableVerbosity) {
        # Utiliser les fonctions de verbositÃ© configurable
        if ($LogFile) {
            Write-LogWithVerbosity -Message $Message -Level $Level -Category $Category -Source $Source -Id $Id -LogFile $LogFile
        } else {
            # Convertir le niveau de journalisation au format attendu par Write-LogWithVerbosity
            $verbosityLevel = switch ($Level) {
                "ERROR" { "Error" }
                "WARNING" { "Warning" }
                "INFO" { "Info" }
                "VERBOSE" { "Verbose" }
                "DEBUG" { "Debug" }
                default { "Info" }
            }

            Write-LogWithVerbosity -Message $Message -Level $verbosityLevel -Category $Category -Source $Source -Id $Id
        }
    } else {
        # Journaliser dans la console
        switch ($Level) {
            "ERROR" { Write-LogError $Message }
            "WARNING" { Write-LogWarning $Message }
            "INFO" { Write-LogInfo $Message }
            "VERBOSE" { Write-LogVerbose $Message }
            "DEBUG" { Write-LogDebug $Message }
        }

        # Journaliser dans un fichier si spÃ©cifiÃ©
        if ($LogFile) {
            Write-LogToFile -Message $Message -Level $Level -LogFile $LogFile -Category $Category -Source $Source -Id $Id -NoRotation:$NoRotation
        }
    }
}

# Exporter les fonctions
if ($MyInvocation.ScriptName -ne '') {
    # Nous sommes dans un module
    Export-ModuleMember -Function Set-LoggingLevel, Get-LoggingLevel, Test-LoggingLevel, Write-LogError, Write-LogWarning, Write-LogInfo, Write-LogVerbose, Write-LogDebug, Write-LogToFile, Write-Log

    # Exporter les fonctions de rotation des journaux
    Export-ModuleMember -Function Get-LogRotationConfig, Set-LogRotationConfig, Test-LogRotationBySize, Test-LogRotationByDate, Invoke-LogRotationBySize, Invoke-LogRotationByDate, Compress-LogFile, Invoke-LogAutoPurge, Invoke-LogRotation

    # Exporter les fonctions de verbositÃ©
    Export-ModuleMember -Function Get-VerbosityConfig, Set-VerbosityLevel, Get-VerbosityLevel, Set-VerbosityFormat, Get-VerbosityFormat, Set-VerbosityCategories, Get-VerbosityCategories, Set-VerbosityPreset, Test-VerbosityLogLevel, Format-MessageByVerbosity, Write-LogWithVerbosity
}
