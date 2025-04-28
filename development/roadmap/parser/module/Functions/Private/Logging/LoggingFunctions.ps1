<#
.SYNOPSIS
    DÃ©finit les fonctions de journalisation pour le module RoadmapParser.

.DESCRIPTION
    Ce script dÃ©finit les fonctions de journalisation utilisÃ©es par le module RoadmapParser.
    Il inclut des fonctions pour Ã©crire des messages de journal Ã  diffÃ©rents niveaux de journalisation.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-21
#>

# Importer le script des niveaux de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$loggingLevelsPath = Join-Path -Path $scriptPath -ChildPath "LoggingLevels.ps1"

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $loggingLevelsPath)) {
    throw "Le fichier LoggingLevels.ps1 est introuvable Ã  l'emplacement : $loggingLevelsPath"
}

# Importer le script
. $loggingLevelsPath

# DÃ©finir les variables globales pour la configuration de la journalisation
$script:LoggingEnabled = $true
$script:LoggingLevel = $script:LogLevelInformation
$script:LoggingDestination = "Console"
$script:LoggingFilePath = $null
$script:LoggingFileMaxSize = 10MB
$script:LoggingFileMaxCount = 5
$script:LoggingFormat = "{0} {1} {2}"
$script:LoggingTimestampFormat = "yyyy-MM-dd HH:mm:ss"
$script:LoggingIncludeTimestamp = $true
$script:LoggingIncludeLevel = $true
$script:LoggingIncludeSource = $true
$script:LoggingSourceName = "RoadmapParser"

<#
.SYNOPSIS
    Configure la journalisation.

.DESCRIPTION
    La fonction Set-LoggingConfiguration configure la journalisation.
    Elle permet de dÃ©finir les paramÃ¨tres de journalisation tels que le niveau, la destination, etc.

.PARAMETER Enabled
    Indique si la journalisation est activÃ©e.
    Par dÃ©faut, c'est $true.

.PARAMETER Level
    Le niveau de journalisation.
    Par dÃ©faut, c'est LogLevelInformation.

.PARAMETER Destination
    La destination de la journalisation. Valeurs possibles :
    - Console : Ã‰crit les messages dans la console
    - File : Ã‰crit les messages dans un fichier
    - Both : Ã‰crit les messages dans la console et dans un fichier
    Par dÃ©faut, c'est "Console".

.PARAMETER FilePath
    Le chemin du fichier de journalisation.
    UtilisÃ© uniquement lorsque Destination est "File" ou "Both".

.PARAMETER FileMaxSize
    La taille maximale du fichier de journalisation.
    UtilisÃ© uniquement lorsque Destination est "File" ou "Both".
    Par dÃ©faut, c'est 10MB.

.PARAMETER FileMaxCount
    Le nombre maximal de fichiers de journalisation Ã  conserver.
    UtilisÃ© uniquement lorsque Destination est "File" ou "Both".
    Par dÃ©faut, c'est 5.

.PARAMETER Format
    Le format des messages de journalisation.
    Par dÃ©faut, c'est "{0} {1} {2}".

.PARAMETER TimestampFormat
    Le format des horodatages.
    Par dÃ©faut, c'est "yyyy-MM-dd HH:mm:ss".

.PARAMETER IncludeTimestamp
    Indique si les horodatages doivent Ãªtre inclus dans les messages de journalisation.
    Par dÃ©faut, c'est $true.

.PARAMETER IncludeLevel
    Indique si les niveaux de journalisation doivent Ãªtre inclus dans les messages de journalisation.
    Par dÃ©faut, c'est $true.

.PARAMETER IncludeSource
    Indique si la source doit Ãªtre incluse dans les messages de journalisation.
    Par dÃ©faut, c'est $true.

.PARAMETER SourceName
    Le nom de la source Ã  inclure dans les messages de journalisation.
    Par dÃ©faut, c'est "RoadmapParser".

.EXAMPLE
    Set-LoggingConfiguration -Level $LogLevelDebug -Destination "File" -FilePath "C:\Logs\RoadmapParser.log"
    Configure la journalisation pour Ã©crire les messages de niveau Debug et supÃ©rieur dans un fichier.

.OUTPUTS
    [void]
#>
function Set-LoggingConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [bool]$Enabled = $true,

        [Parameter(Mandatory = $false)]
        [object]$Level = $script:LogLevelInformation,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Console", "File", "Both")]
        [string]$Destination = "Console",

        [Parameter(Mandatory = $false)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [long]$FileMaxSize = 10MB,

        [Parameter(Mandatory = $false)]
        [int]$FileMaxCount = 5,

        [Parameter(Mandatory = $false)]
        [string]$Format = "{0} {1} {2}",

        [Parameter(Mandatory = $false)]
        [string]$TimestampFormat = "yyyy-MM-dd HH:mm:ss",

        [Parameter(Mandatory = $false)]
        [bool]$IncludeTimestamp = $true,

        [Parameter(Mandatory = $false)]
        [bool]$IncludeLevel = $true,

        [Parameter(Mandatory = $false)]
        [bool]$IncludeSource = $true,

        [Parameter(Mandatory = $false)]
        [string]$SourceName = "RoadmapParser"
    )

    # Valider le niveau de journalisation
    $script:LoggingLevel = ConvertTo-LogLevel -Value $Level

    # Valider la destination
    if ($Destination -in @("File", "Both") -and [string]::IsNullOrEmpty($FilePath)) {
        throw "Le paramÃ¨tre FilePath est requis lorsque Destination est 'File' ou 'Both'."
    }

    # Mettre Ã  jour la configuration
    $script:LoggingEnabled = $Enabled
    $script:LoggingDestination = $Destination
    $script:LoggingFilePath = $FilePath
    $script:LoggingFileMaxSize = $FileMaxSize
    $script:LoggingFileMaxCount = $FileMaxCount
    $script:LoggingFormat = $Format
    $script:LoggingTimestampFormat = $TimestampFormat
    $script:LoggingIncludeTimestamp = $IncludeTimestamp
    $script:LoggingIncludeLevel = $IncludeLevel
    $script:LoggingIncludeSource = $IncludeSource
    $script:LoggingSourceName = $SourceName
}

<#
.SYNOPSIS
    Obtient la configuration de la journalisation.

.DESCRIPTION
    La fonction Get-LoggingConfiguration obtient la configuration de la journalisation.
    Elle retourne un objet contenant les paramÃ¨tres de journalisation actuels.

.EXAMPLE
    Get-LoggingConfiguration
    Obtient la configuration de la journalisation.

.OUTPUTS
    [PSCustomObject] Un objet contenant la configuration de la journalisation.
#>
function Get-LoggingConfiguration {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param ()

    return [PSCustomObject]@{
        Enabled          = $script:LoggingEnabled
        Level            = $script:LoggingLevel
        LevelName        = Get-LogLevelName -LogLevel $script:LoggingLevel
        Destination      = $script:LoggingDestination
        FilePath         = $script:LoggingFilePath
        FileMaxSize      = $script:LoggingFileMaxSize
        FileMaxCount     = $script:LoggingFileMaxCount
        Format           = $script:LoggingFormat
        TimestampFormat  = $script:LoggingTimestampFormat
        IncludeTimestamp = $script:LoggingIncludeTimestamp
        IncludeLevel     = $script:LoggingIncludeLevel
        IncludeSource    = $script:LoggingIncludeSource
        SourceName       = $script:LoggingSourceName
    }
}

<#
.SYNOPSIS
    Ã‰crit un message dans le journal.

.DESCRIPTION
    La fonction Write-Log Ã©crit un message dans le journal.
    Elle prend en charge diffÃ©rents niveaux de journalisation et destinations.

.PARAMETER Message
    Le message Ã  Ã©crire dans le journal.

.PARAMETER Level
    Le niveau de journalisation du message.
    Par dÃ©faut, c'est LogLevelInformation.

.PARAMETER Source
    La source du message.
    Par dÃ©faut, c'est la valeur de LoggingSourceName.

.PARAMETER Exception
    L'exception Ã  inclure dans le message.

.PARAMETER NoNewLine
    Indique si un saut de ligne doit Ãªtre ajoutÃ© Ã  la fin du message.
    Par dÃ©faut, c'est $false.

.PARAMETER PassThru
    Indique si le message doit Ãªtre retournÃ© aprÃ¨s avoir Ã©tÃ© Ã©crit dans le journal.
    Par dÃ©faut, c'est $false.

.EXAMPLE
    Write-Log -Message "Ceci est un message d'information"
    Ã‰crit un message d'information dans le journal.

.EXAMPLE
    Write-Log -Message "Ceci est un message d'erreur" -Level $LogLevelError
    Ã‰crit un message d'erreur dans le journal.

.OUTPUTS
    [string] Le message formatÃ© si PassThru est $true, sinon rien.
#>
function Write-Log {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Message,

        [Parameter(Mandatory = $false, Position = 1)]
        [object]$Level = $script:LogLevelInformation,

        [Parameter(Mandatory = $false)]
        [string]$Source = $script:LoggingSourceName,

        [Parameter(Mandatory = $false)]
        [System.Exception]$Exception,

        [Parameter(Mandatory = $false)]
        [switch]$NoNewLine,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru,

        [Parameter(Mandatory = $false)]
        [string]$Category
    )

    # VÃ©rifier si la journalisation est activÃ©e
    if (-not $script:LoggingEnabled) {
        if ($PassThru) {
            return $Message
        }
        return
    }

    # Convertir le niveau de journalisation
    $logLevel = ConvertTo-LogLevel -Value $Level

    # VÃ©rifier si le niveau de journalisation est suffisant
    if ($logLevel -lt $script:LoggingLevel) {
        if ($PassThru) {
            return $Message
        }
        return
    }

    # Construire le message formatÃ©
    $timestamp = if ($script:LoggingIncludeTimestamp) { Get-Date -Format $script:LoggingTimestampFormat } else { "" }
    $levelPrefix = if ($script:LoggingIncludeLevel) { Get-LogLevelPrefix -LogLevel $logLevel } else { "" }
    $sourcePrefix = if ($script:LoggingIncludeSource) { "[$Source] " } else { "" }

    $formattedMessage = $script:LoggingFormat -f $timestamp, $levelPrefix, $sourcePrefix
    $formattedMessage = "$formattedMessage$Message"

    # Ajouter l'exception si elle est fournie
    if ($null -ne $Exception) {
        $formattedMessage = "$formattedMessage`r`n$($Exception.GetType().FullName): $($Exception.Message)`r`n$($Exception.StackTrace)"
    }

    # Ã‰crire le message dans la console
    if ($script:LoggingDestination -in @("Console", "Both")) {
        $color = Get-LogLevelColor -LogLevel $logLevel

        if ($NoNewLine) {
            Write-Host -Object $formattedMessage -ForegroundColor $color -NoNewline
        } else {
            Write-Host -Object $formattedMessage -ForegroundColor $color
        }
    }

    # Ã‰crire le message dans un fichier
    if ($script:LoggingDestination -in @("File", "Both") -and -not [string]::IsNullOrEmpty($script:LoggingFilePath)) {
        # CrÃ©er le rÃ©pertoire du fichier de journalisation s'il n'existe pas
        $logDir = Split-Path -Parent $script:LoggingFilePath
        if (-not (Test-Path -Path $logDir -PathType Container)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }

        # VÃ©rifier si le fichier de journalisation existe et s'il dÃ©passe la taille maximale
        if (Test-Path -Path $script:LoggingFilePath -PathType Leaf) {
            $logFile = Get-Item -Path $script:LoggingFilePath

            if ($logFile.Length -ge $script:LoggingFileMaxSize) {
                # Effectuer la rotation des fichiers de journalisation
                for ($i = $script:LoggingFileMaxCount - 1; $i -ge 1; $i--) {
                    $oldLogFile = "$($script:LoggingFilePath).$i"
                    $newLogFile = "$($script:LoggingFilePath).$($i + 1)"

                    if (Test-Path -Path $oldLogFile -PathType Leaf) {
                        if (Test-Path -Path $newLogFile -PathType Leaf) {
                            Remove-Item -Path $newLogFile -Force
                        }

                        Move-Item -Path $oldLogFile -Destination $newLogFile -Force
                    }
                }

                $newLogFile = "$($script:LoggingFilePath).1"

                if (Test-Path -Path $newLogFile -PathType Leaf) {
                    Remove-Item -Path $newLogFile -Force
                }

                Move-Item -Path $script:LoggingFilePath -Destination $newLogFile -Force
            }
        }

        # Ã‰crire le message dans le fichier de journalisation
        if ($NoNewLine) {
            $formattedMessage | Out-File -FilePath $script:LoggingFilePath -Append -Encoding UTF8 -NoNewline
        } else {
            $formattedMessage | Out-File -FilePath $script:LoggingFilePath -Append -Encoding UTF8
        }
    }

    # Retourner le message formatÃ© si demandÃ©
    if ($PassThru) {
        return $formattedMessage
    }
}

<#
.SYNOPSIS
    Ã‰crit un message de dÃ©bogage dans le journal.

.DESCRIPTION
    La fonction Write-LogDebug Ã©crit un message de dÃ©bogage dans le journal.
    Elle est un wrapper autour de Write-Log avec le niveau de journalisation Debug.

.PARAMETER Message
    Le message Ã  Ã©crire dans le journal.

.PARAMETER Source
    La source du message.
    Par dÃ©faut, c'est la valeur de LoggingSourceName.

.PARAMETER Exception
    L'exception Ã  inclure dans le message.

.PARAMETER NoNewLine
    Indique si un saut de ligne doit Ãªtre ajoutÃ© Ã  la fin du message.
    Par dÃ©faut, c'est $false.

.PARAMETER PassThru
    Indique si le message doit Ãªtre retournÃ© aprÃ¨s avoir Ã©tÃ© Ã©crit dans le journal.
    Par dÃ©faut, c'est $false.

.EXAMPLE
    Write-LogDebug -Message "Ceci est un message de dÃ©bogage"
    Ã‰crit un message de dÃ©bogage dans le journal.

.OUTPUTS
    [string] Le message formatÃ© si PassThru est $true, sinon rien.
#>
function Write-LogDebug {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$Source = $script:LoggingSourceName,

        [Parameter(Mandatory = $false)]
        [System.Exception]$Exception,

        [Parameter(Mandatory = $false)]
        [switch]$NoNewLine,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    return Write-Log -Message $Message -Level $script:LogLevelDebug -Source $Source -Exception $Exception -NoNewLine:$NoNewLine -PassThru:$PassThru
}

<#
.SYNOPSIS
    Ã‰crit un message dÃ©taillÃ© dans le journal.

.DESCRIPTION
    La fonction Write-LogVerbose Ã©crit un message dÃ©taillÃ© dans le journal.
    Elle est un wrapper autour de Write-Log avec le niveau de journalisation Verbose.

.PARAMETER Message
    Le message Ã  Ã©crire dans le journal.

.PARAMETER Source
    La source du message.
    Par dÃ©faut, c'est la valeur de LoggingSourceName.

.PARAMETER Exception
    L'exception Ã  inclure dans le message.

.PARAMETER NoNewLine
    Indique si un saut de ligne doit Ãªtre ajoutÃ© Ã  la fin du message.
    Par dÃ©faut, c'est $false.

.PARAMETER PassThru
    Indique si le message doit Ãªtre retournÃ© aprÃ¨s avoir Ã©tÃ© Ã©crit dans le journal.
    Par dÃ©faut, c'est $false.

.EXAMPLE
    Write-LogVerbose -Message "Ceci est un message dÃ©taillÃ©"
    Ã‰crit un message dÃ©taillÃ© dans le journal.

.OUTPUTS
    [string] Le message formatÃ© si PassThru est $true, sinon rien.
#>
function Write-LogVerbose {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$Source = $script:LoggingSourceName,

        [Parameter(Mandatory = $false)]
        [System.Exception]$Exception,

        [Parameter(Mandatory = $false)]
        [switch]$NoNewLine,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    return Write-Log -Message $Message -Level $script:LogLevelVerbose -Source $Source -Exception $Exception -NoNewLine:$NoNewLine -PassThru:$PassThru
}

<#
.SYNOPSIS
    Ã‰crit un message d'information dans le journal.

.DESCRIPTION
    La fonction Write-LogInformation Ã©crit un message d'information dans le journal.
    Elle est un wrapper autour de Write-Log avec le niveau de journalisation Information.

.PARAMETER Message
    Le message Ã  Ã©crire dans le journal.

.PARAMETER Source
    La source du message.
    Par dÃ©faut, c'est la valeur de LoggingSourceName.

.PARAMETER Exception
    L'exception Ã  inclure dans le message.

.PARAMETER NoNewLine
    Indique si un saut de ligne doit Ãªtre ajoutÃ© Ã  la fin du message.
    Par dÃ©faut, c'est $false.

.PARAMETER PassThru
    Indique si le message doit Ãªtre retournÃ© aprÃ¨s avoir Ã©tÃ© Ã©crit dans le journal.
    Par dÃ©faut, c'est $false.

.EXAMPLE
    Write-LogInformation -Message "Ceci est un message d'information"
    Ã‰crit un message d'information dans le journal.

.OUTPUTS
    [string] Le message formatÃ© si PassThru est $true, sinon rien.
#>
function Write-LogInformation {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$Source = $script:LoggingSourceName,

        [Parameter(Mandatory = $false)]
        [System.Exception]$Exception,

        [Parameter(Mandatory = $false)]
        [switch]$NoNewLine,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    return Write-Log -Message $Message -Level $script:LogLevelInformation -Source $Source -Exception $Exception -NoNewLine:$NoNewLine -PassThru:$PassThru
}

<#
.SYNOPSIS
    Ã‰crit un message d'avertissement dans le journal.

.DESCRIPTION
    La fonction Write-LogWarning Ã©crit un message d'avertissement dans le journal.
    Elle est un wrapper autour de Write-Log avec le niveau de journalisation Warning.

.PARAMETER Message
    Le message Ã  Ã©crire dans le journal.

.PARAMETER Source
    La source du message.
    Par dÃ©faut, c'est la valeur de LoggingSourceName.

.PARAMETER Exception
    L'exception Ã  inclure dans le message.

.PARAMETER NoNewLine
    Indique si un saut de ligne doit Ãªtre ajoutÃ© Ã  la fin du message.
    Par dÃ©faut, c'est $false.

.PARAMETER PassThru
    Indique si le message doit Ãªtre retournÃ© aprÃ¨s avoir Ã©tÃ© Ã©crit dans le journal.
    Par dÃ©faut, c'est $false.

.EXAMPLE
    Write-LogWarning -Message "Ceci est un message d'avertissement"
    Ã‰crit un message d'avertissement dans le journal.

.OUTPUTS
    [string] Le message formatÃ© si PassThru est $true, sinon rien.
#>
function Write-LogWarning {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$Source = $script:LoggingSourceName,

        [Parameter(Mandatory = $false)]
        [System.Exception]$Exception,

        [Parameter(Mandatory = $false)]
        [switch]$NoNewLine,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    return Write-Log -Message $Message -Level $script:LogLevelWarning -Source $Source -Exception $Exception -NoNewLine:$NoNewLine -PassThru:$PassThru
}

<#
.SYNOPSIS
    Ã‰crit un message d'erreur dans le journal.

.DESCRIPTION
    La fonction Write-LogError Ã©crit un message d'erreur dans le journal.
    Elle est un wrapper autour de Write-Log avec le niveau de journalisation Error.

.PARAMETER Message
    Le message Ã  Ã©crire dans le journal.

.PARAMETER Source
    La source du message.
    Par dÃ©faut, c'est la valeur de LoggingSourceName.

.PARAMETER Exception
    L'exception Ã  inclure dans le message.

.PARAMETER NoNewLine
    Indique si un saut de ligne doit Ãªtre ajoutÃ© Ã  la fin du message.
    Par dÃ©faut, c'est $false.

.PARAMETER PassThru
    Indique si le message doit Ãªtre retournÃ© aprÃ¨s avoir Ã©tÃ© Ã©crit dans le journal.
    Par dÃ©faut, c'est $false.

.EXAMPLE
    Write-LogError -Message "Ceci est un message d'erreur"
    Ã‰crit un message d'erreur dans le journal.

.OUTPUTS
    [string] Le message formatÃ© si PassThru est $true, sinon rien.
#>
function Write-LogError {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$Source = $script:LoggingSourceName,

        [Parameter(Mandatory = $false)]
        [System.Exception]$Exception,

        [Parameter(Mandatory = $false)]
        [switch]$NoNewLine,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    return Write-Log -Message $Message -Level $script:LogLevelError -Source $Source -Exception $Exception -NoNewLine:$NoNewLine -PassThru:$PassThru
}

<#
.SYNOPSIS
    Ã‰crit un message critique dans le journal.

.DESCRIPTION
    La fonction Write-LogCritical Ã©crit un message critique dans le journal.
    Elle est un wrapper autour de Write-Log avec le niveau de journalisation Critical.

.PARAMETER Message
    Le message Ã  Ã©crire dans le journal.

.PARAMETER Source
    La source du message.
    Par dÃ©faut, c'est la valeur de LoggingSourceName.

.PARAMETER Exception
    L'exception Ã  inclure dans le message.

.PARAMETER NoNewLine
    Indique si un saut de ligne doit Ãªtre ajoutÃ© Ã  la fin du message.
    Par dÃ©faut, c'est $false.

.PARAMETER PassThru
    Indique si le message doit Ãªtre retournÃ© aprÃ¨s avoir Ã©tÃ© Ã©crit dans le journal.
    Par dÃ©faut, c'est $false.

.EXAMPLE
    Write-LogCritical -Message "Ceci est un message critique"
    Ã‰crit un message critique dans le journal.

.OUTPUTS
    [string] Le message formatÃ© si PassThru est $true, sinon rien.
#>
function Write-LogCritical {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$Source = $script:LoggingSourceName,

        [Parameter(Mandatory = $false)]
        [System.Exception]$Exception,

        [Parameter(Mandatory = $false)]
        [switch]$NoNewLine,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    return Write-Log -Message $Message -Level $script:LogLevelCritical -Source $Source -Exception $Exception -NoNewLine:$NoNewLine -PassThru:$PassThru
}

# Exporter les fonctions
Export-ModuleMember -Function Set-LoggingConfiguration, Get-LoggingConfiguration, Write-Log, Write-LogDebug, Write-LogVerbose, Write-LogInformation, Write-LogWarning, Write-LogError, Write-LogCritical
