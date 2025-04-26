<#
.SYNOPSIS
    Fonctions de journalisation pour le module RoadmapParser.

.DESCRIPTION
    Ce fichier contient des fonctions pour gérer la journalisation standardisée
    dans le module RoadmapParser, incluant différents niveaux de journalisation
    et formats de sortie.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2025-04-26
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
    Configure les paramètres de journalisation.

.DESCRIPTION
    Cette fonction permet de configurer les paramètres de journalisation pour le module.

.PARAMETER LogLevel
    Le niveau de journalisation (Debug, Info, Warning, Error, None).

.PARAMETER LogFile
    Le chemin du fichier de journal.

.PARAMETER LogFormat
    Le format des messages de journal.

.PARAMETER ConsoleOutput
    Indique si les messages doivent être affichés dans la console.

.PARAMETER FileOutput
    Indique si les messages doivent être écrits dans un fichier.

.PARAMETER IncludeTimestamp
    Indique si les messages doivent inclure un horodatage.

.PARAMETER TimestampFormat
    Le format de l'horodatage.

.PARAMETER MaxLogSize
    La taille maximale du fichier de journal avant rotation.

.PARAMETER EnableLogRotation
    Indique si la rotation des fichiers de journal est activée.

.PARAMETER MaxLogFiles
    Le nombre maximum de fichiers de journal à conserver.

.EXAMPLE
    Set-LoggingConfiguration -LogLevel "Info" -LogFile "C:\Logs\roadmap-parser.log" -FileOutput $true

.NOTES
    Cette fonction doit être appelée avant d'utiliser les fonctions de journalisation.
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

    # Mettre à jour les paramètres spécifiés
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

    # Si FileOutput est activé, vérifier que LogFile est défini
    if ($script:LoggingConfig.FileOutput -and -not $script:LoggingConfig.LogFile) {
        Write-Warning "FileOutput est activé mais aucun fichier de journal n'est spécifié. La journalisation dans un fichier sera désactivée."
        $script:LoggingConfig.FileOutput = $false
    }

    # Si LogFile est défini, activer FileOutput par défaut
    if ($script:LoggingConfig.LogFile -and -not $PSBoundParameters.ContainsKey('FileOutput')) {
        $script:LoggingConfig.FileOutput = $true
    }

    # Créer le répertoire du fichier de journal si nécessaire
    if ($script:LoggingConfig.FileOutput -and $script:LoggingConfig.LogFile) {
        $logDir = Split-Path -Path $script:LoggingConfig.LogFile -Parent
        if (-not [string]::IsNullOrEmpty($logDir) -and -not (Test-Path -Path $logDir)) {
            try {
                New-Item -Path $logDir -ItemType Directory -Force | Out-Null
            }
            catch {
                Write-Warning "Impossible de créer le répertoire de journalisation: $logDir. La journalisation dans un fichier sera désactivée."
                $script:LoggingConfig.FileOutput = $false
            }
        }
    }
}

<#
.SYNOPSIS
    Fonction interne pour écrire un message dans le journal.

.DESCRIPTION
    Cette fonction écrit un message dans le journal selon la configuration définie.

.PARAMETER Message
    Le message à journaliser.

.PARAMETER Level
    Le niveau de journalisation du message.

.PARAMETER LogFile
    Le fichier de journal à utiliser (remplace la configuration).

.PARAMETER NoConsole
    Indique si le message ne doit pas être affiché dans la console.

.PARAMETER ForegroundColor
    La couleur du texte dans la console.

.EXAMPLE
    Write-Log -Message "Opération réussie" -Level "Info"

.NOTES
    Cette fonction est utilisée par les autres fonctions de journalisation.
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

    # Vérifier si le niveau de journalisation est suffisant
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

    # Préparer le message
    $timestamp = if ($script:LoggingConfig.IncludeTimestamp) {
        Get-Date -Format $script:LoggingConfig.TimestampFormat
    } else {
        [string]::Empty
    }

    $formattedMessage = $script:LoggingConfig.LogFormat -f $timestamp, $Level, $Message

    # Écrire dans la console si activé
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

    # Écrire dans le fichier si activé
    if ($script:LoggingConfig.FileOutput) {
        $logFilePath = if ($LogFile) { $LogFile } else { $script:LoggingConfig.LogFile }

        if ($logFilePath) {
            # Vérifier si la rotation des logs est nécessaire
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

            # Écrire le message dans le fichier
            try {
                Add-Content -Path $logFilePath -Value $formattedMessage -Encoding UTF8
            }
            catch {
                Write-Warning "Impossible d'écrire dans le fichier de journal: $logFilePath. Erreur: $($_.Exception.Message)"
            }
        }
    }
}

<#
.SYNOPSIS
    Écrit un message de débogage dans le journal.

.DESCRIPTION
    Cette fonction écrit un message de niveau "Debug" dans le journal.

.PARAMETER Message
    Le message à journaliser.

.PARAMETER LogFile
    Le fichier de journal à utiliser (remplace la configuration).

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
    Écrit un message d'information dans le journal.

.DESCRIPTION
    Cette fonction écrit un message de niveau "Info" dans le journal.

.PARAMETER Message
    Le message à journaliser.

.PARAMETER LogFile
    Le fichier de journal à utiliser (remplace la configuration).

.EXAMPLE
    Write-LogInfo -Message "Opération réussie"

.NOTES
    Cette fonction n'affiche les messages que si le niveau de journalisation est "Info" ou inférieur.
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
    Écrit un message d'avertissement dans le journal.

.DESCRIPTION
    Cette fonction écrit un message de niveau "Warning" dans le journal.

.PARAMETER Message
    Le message à journaliser.

.PARAMETER LogFile
    Le fichier de journal à utiliser (remplace la configuration).

.EXAMPLE
    Write-LogWarning -Message "Opération réussie avec des avertissements"

.NOTES
    Cette fonction n'affiche les messages que si le niveau de journalisation est "Warning" ou inférieur.
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
    Écrit un message d'erreur dans le journal.

.DESCRIPTION
    Cette fonction écrit un message de niveau "Error" dans le journal.

.PARAMETER Message
    Le message à journaliser.

.PARAMETER LogFile
    Le fichier de journal à utiliser (remplace la configuration).

.EXAMPLE
    Write-LogError -Message "Opération échouée: $($_.Exception.Message)"

.NOTES
    Cette fonction n'affiche les messages que si le niveau de journalisation est "Error" ou inférieur.
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
    Utile pour vérifier la configuration actuelle avant de la modifier.
#>
function Get-LoggingConfiguration {
    [CmdletBinding()]
    param ()

    return $script:LoggingConfig.Clone()
}

<#
.SYNOPSIS
    Crée un nouveau fichier de journal.

.DESCRIPTION
    Cette fonction crée un nouveau fichier de journal avec un en-tête.

.PARAMETER LogFile
    Le chemin du fichier de journal à créer.

.PARAMETER Header
    L'en-tête à ajouter au fichier de journal.

.EXAMPLE
    New-LogFile -LogFile "C:\Logs\roadmap-parser.log" -Header "Session de journalisation démarrée le $(Get-Date)"

.NOTES
    Cette fonction écrase le fichier s'il existe déjà.
#>
function New-LogFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogFile,

        [Parameter(Mandatory = $false)]
        [string]$Header = "=== Session de journalisation démarrée le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ==="
    )

    try {
        # Créer le répertoire si nécessaire
        $logDir = Split-Path -Path $LogFile -Parent
        if (-not [string]::IsNullOrEmpty($logDir) -and -not (Test-Path -Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }

        # Créer le fichier avec l'en-tête
        Set-Content -Path $LogFile -Value $Header -Encoding UTF8
        Write-LogInfo -Message "Nouveau fichier de journal créé: $LogFile" -LogFile $LogFile
        return $true
    }
    catch {
        Write-Warning "Impossible de créer le fichier de journal: $LogFile. Erreur: $($_.Exception.Message)"
        return $false
    }
}

# Note: Les fonctions sont exportées lors de l'importation du module
# Set-LoggingConfiguration, Write-LogDebug, Write-LogInfo, Write-LogWarning, Write-LogError, Get-LoggingConfiguration, New-LogFile
