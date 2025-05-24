#Requires -Version 5.1
<#
.SYNOPSIS
    Module de journalisation pour les scripts de synchronisation Markdown-Qdrant.
.DESCRIPTION
    Ce module fournit des fonctions pour la journalisation des événements et des erreurs
    dans les scripts de synchronisation Markdown-Qdrant.
.NOTES
    Nom: Logging.psm1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de création: 2025-06-10
#>

# Variables globales
$script:LogPath = "logs\markdown-watcher.log"
$script:MaxLogSize = 10MB  # Taille maximale du fichier de log avant rotation
$script:MaxLogFiles = 5    # Nombre maximal de fichiers de log à conserver
$script:LogLevel = "INFO"  # Niveau de log par défaut
$script:EnableConsoleOutput = $true  # Activer la sortie console
$script:EnableFileOutput = $true     # Activer la sortie fichier

# Fonction pour initialiser le système de journalisation
function Initialize-Logging {
    <#
    .SYNOPSIS
        Initialise le système de journalisation.
    .DESCRIPTION
        Cette fonction initialise le système de journalisation en définissant
        les paramètres comme le chemin du fichier de log, la taille maximale, etc.
    .PARAMETER LogPath
        Chemin du fichier de log.
    .PARAMETER MaxLogSize
        Taille maximale du fichier de log avant rotation.
    .PARAMETER MaxLogFiles
        Nombre maximal de fichiers de log à conserver.
    .PARAMETER LogLevel
        Niveau de log par défaut.
    .PARAMETER EnableConsoleOutput
        Activer la sortie console.
    .PARAMETER EnableFileOutput
        Activer la sortie fichier.
    .EXAMPLE
        Initialize-Logging -LogPath "logs\mon-application.log" -LogLevel "DEBUG"
        Initialise le système de journalisation avec les paramètres spécifiés.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$LogPath = "logs\markdown-watcher.log",
        
        [Parameter(Mandatory = $false)]
        [long]$MaxLogSize = 10MB,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxLogFiles = 5,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$LogLevel = "INFO",
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableConsoleOutput = $true,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableFileOutput = $true
    )
    
    $script:LogPath = $LogPath
    $script:MaxLogSize = $MaxLogSize
    $script:MaxLogFiles = $MaxLogFiles
    $script:LogLevel = $LogLevel
    $script:EnableConsoleOutput = $EnableConsoleOutput
    $script:EnableFileOutput = $EnableFileOutput
    
    # Créer le répertoire de logs s'il n'existe pas
    if ($script:EnableFileOutput) {
        $logDir = Split-Path -Parent $script:LogPath
        
        if (-not (Test-Path -Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
    }
    
    Write-Log "Système de journalisation initialisé" -Level "INFO"
}

# Fonction pour écrire un message dans le log
function Write-Log {
    <#
    .SYNOPSIS
        Écrit un message dans le log.
    .DESCRIPTION
        Cette fonction écrit un message dans le log avec le niveau spécifié.
    .PARAMETER Message
        Message à écrire dans le log.
    .PARAMETER Level
        Niveau du message (DEBUG, INFO, WARNING, ERROR, SUCCESS).
    .PARAMETER Exception
        Exception à inclure dans le message.
    .PARAMETER NoConsole
        Ne pas afficher le message dans la console.
    .PARAMETER NoFile
        Ne pas écrire le message dans le fichier de log.
    .EXAMPLE
        Write-Log "Opération réussie" -Level "SUCCESS"
        Écrit un message de succès dans le log.
    .EXAMPLE
        Write-Log "Erreur lors de l'opération" -Level "ERROR" -Exception $_.Exception
        Écrit un message d'erreur dans le log avec les détails de l'exception.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,
        
        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO",
        
        [Parameter(Mandatory = $false)]
        [System.Exception]$Exception,
        
        [Parameter(Mandatory = $false)]
        [switch]$NoConsole,
        
        [Parameter(Mandatory = $false)]
        [switch]$NoFile
    )
    
    # Vérifier si le niveau de log est suffisant
    $levelValue = @{
        "DEBUG" = 0
        "INFO" = 1
        "WARNING" = 2
        "ERROR" = 3
        "SUCCESS" = 4
    }
    
    if ($levelValue[$Level] -lt $levelValue[$script:LogLevel]) {
        return
    }
    
    # Formater le message
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Ajouter les détails de l'exception si spécifiée
    if ($Exception) {
        $logMessage += "`n[$timestamp] [EXCEPTION] $($Exception.Message)"
        $logMessage += "`n[$timestamp] [STACKTRACE] $($Exception.StackTrace)"
    }
    
    # Afficher le message dans la console si activé
    if ($script:EnableConsoleOutput -and -not $NoConsole) {
        # Définir la couleur en fonction du niveau
        $color = switch ($Level) {
            "DEBUG" { "Gray" }
            "INFO" { "White" }
            "WARNING" { "Yellow" }
            "ERROR" { "Red" }
            "SUCCESS" { "Green" }
            default { "White" }
        }
        
        Write-Host $logMessage -ForegroundColor $color
    }
    
    # Écrire le message dans le fichier de log si activé
    if ($script:EnableFileOutput -and -not $NoFile) {
        try {
            # Vérifier si le fichier de log existe et s'il dépasse la taille maximale
            if (Test-Path -Path $script:LogPath) {
                $logFile = Get-Item -Path $script:LogPath
                
                if ($logFile.Length -ge $script:MaxLogSize) {
                    # Effectuer une rotation des logs
                    Move-Logs
                }
            }
            
            # Créer le répertoire de logs s'il n'existe pas
            $logDir = Split-Path -Parent $script:LogPath
            
            if (-not (Test-Path -Path $logDir)) {
                New-Item -ItemType Directory -Path $logDir -Force | Out-Null
            }
            
            # Écrire le message dans le fichier de log
            Add-Content -Path $script:LogPath -Value $logMessage -Encoding UTF8
        } catch {
            # En cas d'erreur, afficher un message dans la console
            Write-Host "Erreur lors de l'écriture dans le fichier de log: $_" -ForegroundColor Red
        }
    }
}

# Fonction pour effectuer une rotation des logs
function Move-Logs {
    <#
    .SYNOPSIS
        Effectue une rotation des fichiers de log.
    .DESCRIPTION
        Cette fonction effectue une rotation des fichiers de log en renommant
        les fichiers existants et en créant un nouveau fichier de log.
    .EXAMPLE
        Move-Logs
        Effectue une rotation des fichiers de log.
    #>
    [CmdletBinding()]
    param ()
    
    try {
        # Vérifier si le fichier de log existe
        if (-not (Test-Path -Path $script:LogPath)) {
            return
        }
        
        # Obtenir le répertoire et le nom du fichier de log
        $logDir = Split-Path -Parent $script:LogPath
        $logFileName = Split-Path -Leaf $script:LogPath
        $logFileNameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($logFileName)
        $logFileExt = [System.IO.Path]::GetExtension($logFileName)
        
        # Supprimer le fichier de log le plus ancien si le nombre maximal est atteint
        $oldestLogFile = Join-Path -Path $logDir -ChildPath "$logFileNameWithoutExt.$($script:MaxLogFiles)$logFileExt"
        
        if (Test-Path -Path $oldestLogFile) {
            Remove-Item -Path $oldestLogFile -Force
        }
        
        # Renommer les fichiers de log existants
        for ($i = $script:MaxLogFiles - 1; $i -ge 1; $i--) {
            $currentLogFile = Join-Path -Path $logDir -ChildPath "$logFileNameWithoutExt.$i$logFileExt"
            $newLogFile = Join-Path -Path $logDir -ChildPath "$logFileNameWithoutExt.$($i+1)$logFileExt"
            
            if (Test-Path -Path $currentLogFile) {
                Move-Item -Path $currentLogFile -Destination $newLogFile -Force
            }
        }
        
        # Renommer le fichier de log actuel
        $newLogFile = Join-Path -Path $logDir -ChildPath "$logFileNameWithoutExt.1$logFileExt"
        Move-Item -Path $script:LogPath -Destination $newLogFile -Force
        
        # Créer un nouveau fichier de log
        New-Item -ItemType File -Path $script:LogPath -Force | Out-Null
        
        # Écrire un message dans le nouveau fichier de log
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $rotationMessage = "[$timestamp] [INFO] Rotation des logs effectuée"
        Add-Content -Path $script:LogPath -Value $rotationMessage -Encoding UTF8
    } catch {
        # En cas d'erreur, afficher un message dans la console
        Write-Host "Erreur lors de la rotation des logs: $_" -ForegroundColor Red
    }
}

# Fonction pour obtenir les logs récents
function Get-RecentLogs {
    <#
    .SYNOPSIS
        Obtient les logs récents.
    .DESCRIPTION
        Cette fonction obtient les logs récents en lisant le fichier de log.
    .PARAMETER Count
        Nombre de lignes à récupérer.
    .PARAMETER Level
        Niveau de log à filtrer.
    .PARAMETER Pattern
        Motif à rechercher dans les logs.
    .EXAMPLE
        Get-RecentLogs -Count 10 -Level "ERROR"
        Obtient les 10 dernières erreurs dans les logs.
    .EXAMPLE
        Get-RecentLogs -Pattern "Synchronisation"
        Obtient les logs contenant le mot "Synchronisation".
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$Count = 100,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR", "SUCCESS", "")]
        [string]$Level = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Pattern = ""
    )
    
    try {
        # Vérifier si le fichier de log existe
        if (-not (Test-Path -Path $script:LogPath)) {
            Write-Warning "Le fichier de log n'existe pas: $($script:LogPath)"
            return @()
        }
        
        # Lire le fichier de log
        $logs = Get-Content -Path $script:LogPath -Tail $Count
        
        # Filtrer par niveau si spécifié
        if ($Level) {
            $logs = $logs | Where-Object { $_ -match "\[$Level\]" }
        }
        
        # Filtrer par motif si spécifié
        if ($Pattern) {
            $logs = $logs | Where-Object { $_ -match $Pattern }
        }
        
        return $logs
    } catch {
        Write-Error "Erreur lors de la récupération des logs: $_"
        return @()
    }
}

# Initialiser le système de journalisation avec les valeurs par défaut
Initialize-Logging

# Exporter les fonctions
Export-ModuleMember -Function Initialize-Logging, Write-Log, Move-Logs, Get-RecentLogs

