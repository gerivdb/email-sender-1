<#
.SYNOPSIS
    SystÃ¨me de journalisation centralisÃ©e pour les scripts PowerShell.

.DESCRIPTION
    Ce script fournit un systÃ¨me de journalisation centralisÃ©e pour les scripts PowerShell.
    Il permet de journaliser des messages de diffÃ©rents niveaux (Debug, Info, Warning, Error, etc.)
    dans diffÃ©rentes destinations (fichier, console, journal des Ã©vÃ©nements Windows, etc.).

.EXAMPLE
    . .\CentralizedLogger.ps1
    Initialize-Logger -LogFilePath "C:\Logs\MyScript.log" -LogLevel "Info" -IncludeTimestamp
    Write-LogInfo "DÃ©marrage du script"
    Write-LogWarning "Attention: cette opÃ©ration peut prendre du temps"
    Write-LogError "Une erreur s'est produite: fichier non trouvÃ©"
    Close-Logger

.NOTES
    Auteur: SystÃ¨me d'analyse d'erreurs
    Date de crÃ©ation: 07/04/2025
    Version: 1.0
#>

# DÃ©finir les niveaux de journalisation
enum LogLevel {
    Debug = 0
    Verbose = 1
    Info = 2
    Warning = 3
    Error = 4
    Critical = 5
    None = 6
}

# Variables globales pour la configuration du logger
$script:LoggerConfig = [PSCustomObject]@{
    Initialized = $false
    LogFilePath = ""
    LogLevel = [LogLevel]::Info
    IncludeTimestamp = $true
    IncludeSource = $true
    IncludeLevel = $true
    LogToConsole = $true
    LogToFile = $true
    LogToEventLog = $false
    EventLogSource = "PowerShellScripts"
    EventLogName = "Application"
    LogFileEncoding = "UTF8"
    LogFileAppend = $true
    MaxLogFileSizeMB = 10
    MaxLogFileCount = 5
    LogFileStream = $null
    LogFileStreamWriter = $null
}

# Fonction pour initialiser le logger
function Initialize-Logger {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$LogFilePath = "",
        
        [Parameter(Mandatory = $false)]
        [LogLevel]$LogLevel = [LogLevel]::Info,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeTimestamp = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeSource = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeLevel = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$LogToConsole = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$LogToFile = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$LogToEventLog = $false,
        
        [Parameter(Mandatory = $false)]
        [string]$EventLogSource = "PowerShellScripts",
        
        [Parameter(Mandatory = $false)]
        [string]$EventLogName = "Application",
        
        [Parameter(Mandatory = $false)]
        [string]$LogFileEncoding = "UTF8",
        
        [Parameter(Mandatory = $false)]
        [switch]$LogFileAppend = $true,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxLogFileSizeMB = 10,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxLogFileCount = 5
    )
    
    # Fermer le logger s'il est dÃ©jÃ  initialisÃ©
    if ($script:LoggerConfig.Initialized) {
        Close-Logger
    }
    
    # Configurer le logger
    $script:LoggerConfig.LogFilePath = $LogFilePath
    $script:LoggerConfig.LogLevel = $LogLevel
    $script:LoggerConfig.IncludeTimestamp = $IncludeTimestamp
    $script:LoggerConfig.IncludeSource = $IncludeSource
    $script:LoggerConfig.IncludeLevel = $IncludeLevel
    $script:LoggerConfig.LogToConsole = $LogToConsole
    $script:LoggerConfig.LogToFile = $LogToFile -and -not [string]::IsNullOrEmpty($LogFilePath)
    $script:LoggerConfig.LogToEventLog = $LogToEventLog
    $script:LoggerConfig.EventLogSource = $EventLogSource
    $script:LoggerConfig.EventLogName = $EventLogName
    $script:LoggerConfig.LogFileEncoding = $LogFileEncoding
    $script:LoggerConfig.LogFileAppend = $LogFileAppend
    $script:LoggerConfig.MaxLogFileSizeMB = $MaxLogFileSizeMB
    $script:LoggerConfig.MaxLogFileCount = $MaxLogFileCount
    
    # Initialiser le fichier journal si nÃ©cessaire
    if ($script:LoggerConfig.LogToFile) {
        try {
            # CrÃ©er le dossier du journal si nÃ©cessaire
            $logDirectory = Split-Path -Path $LogFilePath -Parent
            if (-not [string]::IsNullOrEmpty($logDirectory) -and -not (Test-Path -Path $logDirectory -PathType Container)) {
                New-Item -Path $logDirectory -ItemType Directory -Force | Out-Null
            }
            
            # VÃ©rifier si le fichier journal existe et s'il dÃ©passe la taille maximale
            if (Test-Path -Path $LogFilePath -PathType Leaf) {
                $logFile = Get-Item -Path $LogFilePath
                if ($logFile.Length -gt ($MaxLogFileSizeMB * 1MB)) {
                    # Effectuer une rotation des fichiers journaux
                    Rotate-LogFiles -LogFilePath $LogFilePath -MaxLogFileCount $MaxLogFileCount
                }
            }
            
            # Ouvrir le flux de fichier
            $fileMode = if ($LogFileAppend -and (Test-Path -Path $LogFilePath -PathType Leaf)) { [System.IO.FileMode]::Append } else { [System.IO.FileMode]::Create }
            $fileAccess = [System.IO.FileAccess]::Write
            $fileShare = [System.IO.FileShare]::Read
            
            $script:LoggerConfig.LogFileStream = New-Object System.IO.FileStream($LogFilePath, $fileMode, $fileAccess, $fileShare)
            
            # CrÃ©er l'encodeur en fonction de l'encodage spÃ©cifiÃ©
            $encoder = switch ($LogFileEncoding.ToUpper()) {
                "UTF8" { New-Object System.Text.UTF8Encoding($true) }
                "UTF8-NOBOM" { New-Object System.Text.UTF8Encoding($false) }
                "UTF16" { [System.Text.Encoding]::Unicode }
                "UTF16BE" { [System.Text.Encoding]::BigEndianUnicode }
                "UTF32" { [System.Text.Encoding]::UTF32 }
                "ASCII" { [System.Text.Encoding]::ASCII }
                default { New-Object System.Text.UTF8Encoding($true) }
            }
            
            $script:LoggerConfig.LogFileStreamWriter = New-Object System.IO.StreamWriter($script:LoggerConfig.LogFileStream, $encoder)
            
            # Ã‰crire un en-tÃªte dans le fichier journal
            $headerText = "=== Session de journalisation dÃ©marrÃ©e le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ==="
            $script:LoggerConfig.LogFileStreamWriter.WriteLine($headerText)
            $script:LoggerConfig.LogFileStreamWriter.Flush()
        }
        catch {
            Write-Warning "Impossible d'initialiser le fichier journal: $_"
            $script:LoggerConfig.LogToFile = $false
        }
    }
    
    # Initialiser le journal des Ã©vÃ©nements Windows si nÃ©cessaire
    if ($script:LoggerConfig.LogToEventLog) {
        try {
            # VÃ©rifier si la source existe, sinon la crÃ©er
            if (-not [System.Diagnostics.EventLog]::SourceExists($EventLogSource)) {
                # NÃ©cessite des privilÃ¨ges administratifs
                [System.Diagnostics.EventLog]::CreateEventSource($EventLogSource, $EventLogName)
                Write-Verbose "Source de journal d'Ã©vÃ©nements '$EventLogSource' crÃ©Ã©e."
            }
        }
        catch {
            Write-Warning "Impossible d'initialiser le journal des Ã©vÃ©nements Windows: $_"
            $script:LoggerConfig.LogToEventLog = $false
        }
    }
    
    $script:LoggerConfig.Initialized = $true
    
    # Journaliser l'initialisation
    Write-LogInfo "Logger initialisÃ© avec le niveau $LogLevel"
}

# Fonction pour effectuer une rotation des fichiers journaux
function Rotate-LogFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogFilePath,
        
        [Parameter(Mandatory = $true)]
        [int]$MaxLogFileCount
    )
    
    try {
        # Supprimer le fichier journal le plus ancien si nÃ©cessaire
        $oldestLogFile = "$LogFilePath.$MaxLogFileCount"
        if (Test-Path -Path $oldestLogFile -PathType Leaf) {
            Remove-Item -Path $oldestLogFile -Force
        }
        
        # DÃ©placer les fichiers journaux existants
        for ($i = $MaxLogFileCount - 1; $i -ge 1; $i--) {
            $currentLogFile = "$LogFilePath.$i"
            $nextLogFile = "$LogFilePath.$($i + 1)"
            
            if (Test-Path -Path $currentLogFile -PathType Leaf) {
                Move-Item -Path $currentLogFile -Destination $nextLogFile -Force
            }
        }
        
        # Renommer le fichier journal actuel
        if (Test-Path -Path $LogFilePath -PathType Leaf) {
            Move-Item -Path $LogFilePath -Destination "$LogFilePath.1" -Force
        }
    }
    catch {
        Write-Warning "Erreur lors de la rotation des fichiers journaux: $_"
    }
}

# Fonction pour fermer le logger
function Close-Logger {
    [CmdletBinding()]
    param ()
    
    if (-not $script:LoggerConfig.Initialized) {
        return
    }
    
    try {
        # Fermer le flux de fichier
        if ($null -ne $script:LoggerConfig.LogFileStreamWriter) {
            $footerText = "=== Session de journalisation terminÃ©e le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ==="
            $script:LoggerConfig.LogFileStreamWriter.WriteLine($footerText)
            $script:LoggerConfig.LogFileStreamWriter.Flush()
            $script:LoggerConfig.LogFileStreamWriter.Close()
            $script:LoggerConfig.LogFileStreamWriter = $null
        }
        
        if ($null -ne $script:LoggerConfig.LogFileStream) {
            $script:LoggerConfig.LogFileStream.Close()
            $script:LoggerConfig.LogFileStream = $null
        }
    }
    catch {
        Write-Warning "Erreur lors de la fermeture du logger: $_"
    }
    finally {
        $script:LoggerConfig.Initialized = $false
    }
}

# Fonction interne pour Ã©crire un message dans le journal
function Write-LogMessage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $true)]
        [LogLevel]$Level,
        
        [Parameter(Mandatory = $false)]
        [string]$Source = "",
        
        [Parameter(Mandatory = $false)]
        [int]$EventId = 0
    )
    
    # VÃ©rifier si le logger est initialisÃ©
    if (-not $script:LoggerConfig.Initialized) {
        Initialize-Logger
    }
    
    # VÃ©rifier si le niveau de journalisation est suffisant
    if ($Level -lt $script:LoggerConfig.LogLevel) {
        return
    }
    
    # DÃ©terminer la source si non spÃ©cifiÃ©e
    if ([string]::IsNullOrEmpty($Source)) {
        $callStack = Get-PSCallStack | Select-Object -Skip 2 | Select-Object -First 1
        $Source = if ($callStack) {
            $caller = $callStack
            "$($caller.Command) at line $($caller.ScriptLineNumber) in $($caller.ScriptName)"
        }
        else {
            "Unknown"
        }
    }
    
    # Construire le message formatÃ©
    $formattedMessage = ""
    
    if ($script:LoggerConfig.IncludeTimestamp) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $formattedMessage += "[$timestamp] "
    }
    
    if ($script:LoggerConfig.IncludeLevel) {
        $formattedMessage += "[$Level] "
    }
    
    if ($script:LoggerConfig.IncludeSource -and -not [string]::IsNullOrEmpty($Source)) {
        $formattedMessage += "[$Source] "
    }
    
    $formattedMessage += $Message
    
    # Journaliser dans la console
    if ($script:LoggerConfig.LogToConsole) {
        $foregroundColor = switch ($Level) {
            ([LogLevel]::Debug) { "Gray" }
            ([LogLevel]::Verbose) { "White" }
            ([LogLevel]::Info) { "Green" }
            ([LogLevel]::Warning) { "Yellow" }
            ([LogLevel]::Error) { "Red" }
            ([LogLevel]::Critical) { "Magenta" }
            default { "White" }
        }
        
        Write-Host $formattedMessage -ForegroundColor $foregroundColor
    }
    
    # Journaliser dans le fichier
    if ($script:LoggerConfig.LogToFile -and $null -ne $script:LoggerConfig.LogFileStreamWriter) {
        try {
            $script:LoggerConfig.LogFileStreamWriter.WriteLine($formattedMessage)
            $script:LoggerConfig.LogFileStreamWriter.Flush()
        }
        catch {
            Write-Warning "Erreur lors de l'Ã©criture dans le fichier journal: $_"
        }
    }
    
    # Journaliser dans le journal des Ã©vÃ©nements Windows
    if ($script:LoggerConfig.LogToEventLog) {
        try {
            $entryType = switch ($Level) {
                ([LogLevel]::Debug) { "Information" }
                ([LogLevel]::Verbose) { "Information" }
                ([LogLevel]::Info) { "Information" }
                ([LogLevel]::Warning) { "Warning" }
                ([LogLevel]::Error) { "Error" }
                ([LogLevel]::Critical) { "Error" }
                default { "Information" }
            }
            
            $eventId = if ($EventId -eq 0) {
                switch ($Level) {
                    ([LogLevel]::Debug) { 100 }
                    ([LogLevel]::Verbose) { 200 }
                    ([LogLevel]::Info) { 300 }
                    ([LogLevel]::Warning) { 400 }
                    ([LogLevel]::Error) { 500 }
                    ([LogLevel]::Critical) { 600 }
                    default { 900 }
                }
            }
            else {
                $EventId
            }
            
            Write-EventLog -LogName $script:LoggerConfig.EventLogName -Source $script:LoggerConfig.EventLogSource -EventId $eventId -EntryType $entryType -Message $formattedMessage
        }
        catch {
            Write-Warning "Erreur lors de l'Ã©criture dans le journal des Ã©vÃ©nements Windows: $_"
        }
    }
}

# Fonctions pour journaliser des messages de diffÃ©rents niveaux
function Write-LogDebug {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$Source = "",
        
        [Parameter(Mandatory = $false)]
        [int]$EventId = 0
    )
    
    Write-LogMessage -Message $Message -Level ([LogLevel]::Debug) -Source $Source -EventId $EventId
}

function Write-LogVerbose {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$Source = "",
        
        [Parameter(Mandatory = $false)]
        [int]$EventId = 0
    )
    
    Write-LogMessage -Message $Message -Level ([LogLevel]::Verbose) -Source $Source -EventId $EventId
}

function Write-LogInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$Source = "",
        
        [Parameter(Mandatory = $false)]
        [int]$EventId = 0
    )
    
    Write-LogMessage -Message $Message -Level ([LogLevel]::Info) -Source $Source -EventId $EventId
}

function Write-LogWarning {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$Source = "",
        
        [Parameter(Mandatory = $false)]
        [int]$EventId = 0
    )
    
    Write-LogMessage -Message $Message -Level ([LogLevel]::Warning) -Source $Source -EventId $EventId
}

function Write-LogError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$Source = "",
        
        [Parameter(Mandatory = $false)]
        [int]$EventId = 0,
        
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord = $null
    )
    
    $fullMessage = $Message
    
    if ($null -ne $ErrorRecord) {
        $fullMessage += "`nException: $($ErrorRecord.Exception.GetType().FullName)"
        $fullMessage += "`nMessage: $($ErrorRecord.Exception.Message)"
        $fullMessage += "`nStack Trace: $($ErrorRecord.ScriptStackTrace)"
    }
    
    Write-LogMessage -Message $fullMessage -Level ([LogLevel]::Error) -Source $Source -EventId $EventId
}

function Write-LogCritical {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$Source = "",
        
        [Parameter(Mandatory = $false)]
        [int]$EventId = 0,
        
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord = $null
    )
    
    $fullMessage = $Message
    
    if ($null -ne $ErrorRecord) {
        $fullMessage += "`nException: $($ErrorRecord.Exception.GetType().FullName)"
        $fullMessage += "`nMessage: $($ErrorRecord.Exception.Message)"
        $fullMessage += "`nStack Trace: $($ErrorRecord.ScriptStackTrace)"
    }
    
    Write-LogMessage -Message $fullMessage -Level ([LogLevel]::Critical) -Source $Source -EventId $EventId
}

# Fonction pour obtenir la configuration actuelle du logger
function Get-LoggerConfig {
    [CmdletBinding()]
    param ()
    
    return $script:LoggerConfig
}

# Fonction pour dÃ©finir le niveau de journalisation
function Set-LogLevel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [LogLevel]$Level
    )
    
    $script:LoggerConfig.LogLevel = $Level
    Write-LogInfo "Niveau de journalisation dÃ©fini Ã  $Level"
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-Logger, Close-Logger, Write-LogDebug, Write-LogVerbose, Write-LogInfo, Write-LogWarning, Write-LogError, Write-LogCritical, Get-LoggerConfig, Set-LogLevel

# Enregistrer un gestionnaire de fin de script pour fermer le logger
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    Close-Logger
}
