<#
.SYNOPSIS
    Fonctions de journalisation pour le module RoadmapParser.

.DESCRIPTION
    Ce fichier contient des fonctions pour gÃ©rer la journalisation standardisÃ©e
    dans le module RoadmapParser, incluant diffÃ©rents niveaux de journalisation
    et formats de sortie.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2025-04-26
#>

# Variables globales pour la configuration de journalisation
if (-not (Get-Variable -Name LoggingConfig -Scope Script -ErrorAction SilentlyContinue)) {
    $script:LoggingConfig = @{
        LogLevel = "Info"  # Debug, Info, Warning, Error, None
        LogFile = $null
        LogFormat = "[{0}] {1}: {2}"  # {0} = DateTime, {1} = Level, {2} = Message
        ConsoleOutput = $true
        FileOutput = $false
        IncludeTimestamp = $true
        TimestampFormat = "yyyy-MM-dd HH:mm:ss"
        MaxLogSize = 10MB
        EnableLogRotation = $true
        MaxLogFiles = 5
    }
}

<#
.SYNOPSIS
    Configure les paramÃ¨tres de journalisation.

.DESCRIPTION
    Cette fonction permet de configurer les paramÃ¨tres de journalisation pour le module.

.PARAMETER LogLevel
    Le niveau de journalisation (Debug, Info, Warning, Error, None).

.PARAMETER LogFile
    Le chemin du fichier de journal.

.PARAMETER LogFormat
    Le format des messages de journal.

.PARAMETER ConsoleOutput
    Indique si les messages doivent Ãªtre affichÃ©s dans la console.

.PARAMETER FileOutput
    Indique si les messages doivent Ãªtre Ã©crits dans un fichier.

.PARAMETER IncludeTimestamp
    Indique si les messages doivent inclure un horodatage.

.PARAMETER TimestampFormat
    Le format de l'horodatage.

.PARAMETER MaxLogSize
    La taille maximale du fichier de journal avant rotation.

.PARAMETER EnableLogRotation
    Indique si la rotation des fichiers de journal est activÃ©e.

.PARAMETER MaxLogFiles
    Le nombre maximum de fichiers de journal Ã  conserver.

.EXAMPLE
    Set-LoggingConfiguration -LogLevel "Info" -LogFile "C:\Logs\roadmap-parser.log" -FileOutput $true

.NOTES
    Cette fonction doit Ãªtre appelÃ©e avant d'utiliser les fonctions de journalisation.
#>
function Set-LoggingConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Debug", "Info", "Warning", "Error", "None")]
        [string]$LogLevel,

        [Parameter(Mandatory = $false)]
        [string]$LogFile,

        [Parameter(Mandatory = $false)]
        [string]$LogFormat,

        [Parameter(Mandatory = $false)]
        [bool]$ConsoleOutput,

        [Parameter(Mandatory = $false)]
        [bool]$FileOutput,

        [Parameter(Mandatory = $false)]
        [bool]$IncludeTimestamp,

        [Parameter(Mandatory = $false)]
        [string]$TimestampFormat,

        [Parameter(Mandatory = $false)]
        [long]$MaxLogSize,

        [Parameter(Mandatory = $false)]
        [bool]$EnableLogRotation,

        [Parameter(Mandatory = $false)]
        [int]$MaxLogFiles
    )

    # Mettre Ã  jour les paramÃ¨tres spÃ©cifiÃ©s
    if ($PSBoundParameters.ContainsKey('LogLevel')) { $script:LoggingConfig.LogLevel = $LogLevel }
    if ($PSBoundParameters.ContainsKey('LogFile')) { $script:LoggingConfig.LogFile = $LogFile }
    if ($PSBoundParameters.ContainsKey('LogFormat')) { $script:LoggingConfig.LogFormat = $LogFormat }
    if ($PSBoundParameters.ContainsKey('ConsoleOutput')) { $script:LoggingConfig.ConsoleOutput = $ConsoleOutput }
    if ($PSBoundParameters.ContainsKey('FileOutput')) { $script:LoggingConfig.FileOutput = $FileOutput }
    if ($PSBoundParameters.ContainsKey('IncludeTimestamp')) { $script:LoggingConfig.IncludeTimestamp = $IncludeTimestamp }
    if ($PSBoundParameters.ContainsKey('TimestampFormat')) { $script:LoggingConfig.TimestampFormat = $TimestampFormat }
    if ($PSBoundParameters.ContainsKey('MaxLogSize')) { $script:LoggingConfig.MaxLogSize = $MaxLogSize }
    if ($PSBoundParameters.ContainsKey('EnableLogRotation')) { $script:LoggingConfig.EnableLogRotation = $EnableLogRotation }
    if ($PSBoundParameters.ContainsKey('MaxLogFiles')) { $script:LoggingConfig.MaxLogFiles = $MaxLogFiles }

    # Si FileOutput est activÃ©, vÃ©rifier que LogFile est dÃ©fini
    if ($script:LoggingConfig.FileOutput -and -not $script:LoggingConfig.LogFile) {
        Write-Warning "FileOutput est activÃ© mais aucun fichier de journal n'est spÃ©cifiÃ©. La journalisation dans un fichier sera dÃ©sactivÃ©e."
        $script:LoggingConfig.FileOutput = $false
    }

    # Si LogFile est dÃ©fini, activer FileOutput par dÃ©faut
    if ($script:LoggingConfig.LogFile -and -not $PSBoundParameters.ContainsKey('FileOutput')) {
        $script:LoggingConfig.FileOutput = $true
    }

    # CrÃ©er le rÃ©pertoire du fichier de journal si nÃ©cessaire
    if ($script:LoggingConfig.FileOutput -and $script:LoggingConfig.LogFile) {
        $logDir = Split-Path -Path $script:LoggingConfig.LogFile -Parent
        if (-not [string]::IsNullOrEmpty($logDir) -and -not (Test-Path -Path $logDir)) {
            try {
                New-Item -Path $logDir -ItemType Directory -Force | Out-Null
            }
            catch {
                Write-Warning "Impossible de crÃ©er le rÃ©pertoire de journalisation: $logDir. La journalisation dans un fichier sera dÃ©sactivÃ©e."
                $script:LoggingConfig.FileOutput = $false
            }
        }
    }
}

<#
.SYNOPSIS
    Fonction interne pour Ã©crire un message dans le journal.

.DESCRIPTION
    Cette fonction Ã©crit un message dans le journal selon la configuration dÃ©finie.

.PARAMETER Message
    Le message Ã  journaliser.

.PARAMETER Level
    Le niveau de journalisation du message.

.PARAMETER LogFile
    Le fichier de journal Ã  utiliser (remplace la configuration).

.PARAMETER NoConsole
    Indique si le message ne doit pas Ãªtre affichÃ© dans la console.

.PARAMETER ForegroundColor
    La couleur du texte dans la console.

.EXAMPLE
    Write-Log -Message "OpÃ©ration rÃ©ussie" -Level "Info"

.NOTES
    Cette fonction est utilisÃ©e par les autres fonctions de journalisation.
#>
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("Debug", "Info", "Warning", "Error")]
        [string]$Level,

        [Parameter(Mandatory = $false)]
        [string]$LogFile,

        [Parameter(Mandatory = $false)]
        [switch]$NoConsole,

        [Parameter(Mandatory = $false)]
        [System.ConsoleColor]$ForegroundColor
    )

    # VÃ©rifier si le niveau de journalisation est suffisant
    $levelPriority = @{
        "Debug" = 0
        "Info" = 1
        "Warning" = 2
        "Error" = 3
        "None" = 4
    }

    if ($levelPriority[$Level] -lt $levelPriority[$script:LoggingConfig.LogLevel]) {
        return
    }

    # PrÃ©parer le message
    $timestamp = if ($script:LoggingConfig.IncludeTimestamp) {
        Get-Date -Format $script:LoggingConfig.TimestampFormat
    } else {
        [string]::Empty
    }

    $formattedMessage = $script:LoggingConfig.LogFormat -f $timestamp, $Level, $Message

    # Ã‰crire dans la console si activÃ©
    if ($script:LoggingConfig.ConsoleOutput -and -not $NoConsole) {
        if ($ForegroundColor) {
            Write-Host $formattedMessage -ForegroundColor $ForegroundColor
        } else {
            $color = switch ($Level) {
                "Debug" { [System.ConsoleColor]::Gray }
                "Info" { [System.ConsoleColor]::White }
                "Warning" { [System.ConsoleColor]::Yellow }
                "Error" { [System.ConsoleColor]::Red }
                default { [System.ConsoleColor]::White }
            }
            Write-Host $formattedMessage -ForegroundColor $color
        }
    }

    # Ã‰crire dans le fichier si activÃ©
    if ($script:LoggingConfig.FileOutput) {
        $logFilePath = if ($LogFile) { $LogFile } else { $script:LoggingConfig.LogFile }

        if ($logFilePath) {
            # VÃ©rifier si la rotation des logs est nÃ©cessaire
            if ($script:LoggingConfig.EnableLogRotation -and (Test-Path -Path $logFilePath)) {
                $logFileInfo = Get-Item -Path $logFilePath
                if ($logFileInfo.Length -ge $script:LoggingConfig.MaxLogSize) {
                    # Importer la fonction de rotation des logs si disponible
                    if (-not (Get-Command -Name "Invoke-LogRotation" -ErrorAction SilentlyContinue)) {
                        $logRotationPath = Join-Path -Path $PSScriptRoot -ChildPath "LogRotation.ps1"
                        if (Test-Path -Path $logRotationPath) {
                            . $logRotationPath
                        }
                    }

                    # Effectuer la rotation des logs
                    if (Get-Command -Name "Invoke-LogRotation" -ErrorAction SilentlyContinue) {
                        Invoke-LogRotation -LogFile $logFilePath -MaxLogFiles $script:LoggingConfig.MaxLogFiles
                    }
                }
            }

            # Ã‰crire le message dans le fichier
            try {
                Add-Content -Path $logFilePath -Value $formattedMessage -Encoding UTF8
            }
            catch {
                Write-Warning "Impossible d'Ã©crire dans le fichier de journal: $logFilePath. Erreur: $($_.Exception.Message)"
            }
        }
    }
}

<#
.SYNOPSIS
    Ã‰crit un message de dÃ©bogage dans le journal.

.DESCRIPTION
    Cette fonction Ã©crit un message de niveau "Debug" dans le journal.

.PARAMETER Message
    Le message Ã  journaliser.

.PARAMETER LogFile
    Le fichier de journal Ã  utiliser (remplace la configuration).

.EXAMPLE
    Write-LogDebug -Message "Valeur de la variable: $value"

.NOTES
    Cette fonction n'affiche les messages que si le niveau de journalisation est "Debug".
#>
function Write-LogDebug {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$LogFile
    )

    $params = @{
        Message = $Message
        Level = "Debug"
    }

    if ($LogFile) {
        $params.LogFile = $LogFile
    }

    Write-Log @params
}

<#
.SYNOPSIS
    Ã‰crit un message d'information dans le journal.

.DESCRIPTION
    Cette fonction Ã©crit un message de niveau "Info" dans le journal.

.PARAMETER Message
    Le message Ã  journaliser.

.PARAMETER LogFile
    Le fichier de journal Ã  utiliser (remplace la configuration).

.EXAMPLE
    Write-LogInfo -Message "OpÃ©ration rÃ©ussie"

.NOTES
    Cette fonction n'affiche les messages que si le niveau de journalisation est "Info" ou infÃ©rieur.
#>
function Write-LogInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$LogFile
    )

    $params = @{
        Message = $Message
        Level = "Info"
    }

    if ($LogFile) {
        $params.LogFile = $LogFile
    }

    Write-Log @params
}

<#
.SYNOPSIS
    Ã‰crit un message d'avertissement dans le journal.

.DESCRIPTION
    Cette fonction Ã©crit un message de niveau "Warning" dans le journal.

.PARAMETER Message
    Le message Ã  journaliser.

.PARAMETER LogFile
    Le fichier de journal Ã  utiliser (remplace la configuration).

.EXAMPLE
    Write-LogWarning -Message "OpÃ©ration rÃ©ussie avec des avertissements"

.NOTES
    Cette fonction n'affiche les messages que si le niveau de journalisation est "Warning" ou infÃ©rieur.
#>
function Write-LogWarning {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$LogFile
    )

    $params = @{
        Message = $Message
        Level = "Warning"
        ForegroundColor = [System.ConsoleColor]::Yellow
    }

    if ($LogFile) {
        $params.LogFile = $LogFile
    }

    Write-Log @params
}

<#
.SYNOPSIS
    Ã‰crit un message d'erreur dans le journal.

.DESCRIPTION
    Cette fonction Ã©crit un message de niveau "Error" dans le journal.

.PARAMETER Message
    Le message Ã  journaliser.

.PARAMETER LogFile
    Le fichier de journal Ã  utiliser (remplace la configuration).

.EXAMPLE
    Write-LogError -Message "OpÃ©ration Ã©chouÃ©e: $($_.Exception.Message)"

.NOTES
    Cette fonction n'affiche les messages que si le niveau de journalisation est "Error" ou infÃ©rieur.
#>
function Write-LogError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$LogFile
    )

    $params = @{
        Message = $Message
        Level = "Error"
        ForegroundColor = [System.ConsoleColor]::Red
    }

    if ($LogFile) {
        $params.LogFile = $LogFile
    }

    Write-Log @params
}

<#
.SYNOPSIS
    Obtient la configuration actuelle de journalisation.

.DESCRIPTION
    Cette fonction retourne la configuration actuelle de journalisation.

.EXAMPLE
    $config = Get-LoggingConfiguration

.NOTES
    Utile pour vÃ©rifier la configuration actuelle avant de la modifier.
#>
function Get-LoggingConfiguration {
    [CmdletBinding()]
    param ()

    return $script:LoggingConfig.Clone()
}

<#
.SYNOPSIS
    CrÃ©e un nouveau fichier de journal.

.DESCRIPTION
    Cette fonction crÃ©e un nouveau fichier de journal avec un en-tÃªte.

.PARAMETER LogFile
    Le chemin du fichier de journal Ã  crÃ©er.

.PARAMETER Header
    L'en-tÃªte Ã  ajouter au fichier de journal.

.EXAMPLE
    New-LogFile -LogFile "C:\Logs\roadmap-parser.log" -Header "Session de journalisation dÃ©marrÃ©e le $(Get-Date)"

.NOTES
    Cette fonction Ã©crase le fichier s'il existe dÃ©jÃ .
#>
function New-LogFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogFile,

        [Parameter(Mandatory = $false)]
        [string]$Header = "=== Session de journalisation dÃ©marrÃ©e le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ==="
    )

    try {
        # CrÃ©er le rÃ©pertoire si nÃ©cessaire
        $logDir = Split-Path -Path $LogFile -Parent
        if (-not [string]::IsNullOrEmpty($logDir) -and -not (Test-Path -Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }

        # CrÃ©er le fichier avec l'en-tÃªte
        Set-Content -Path $LogFile -Value $Header -Encoding UTF8
        Write-LogInfo -Message "Nouveau fichier de journal crÃ©Ã©: $LogFile" -LogFile $LogFile
        return $true
    }
    catch {
        Write-Warning "Impossible de crÃ©er le fichier de journal: $LogFile. Erreur: $($_.Exception.Message)"
        return $false
    }
}

# Note: Les fonctions sont exportÃ©es lors de l'importation du module
# Set-LoggingConfiguration, Write-LogDebug, Write-LogInfo, Write-LogWarning, Write-LogError, Get-LoggingConfiguration, New-LogFile
