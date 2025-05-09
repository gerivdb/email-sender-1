﻿# Write-Log.ps1
# Script utilitaire pour la journalisation
# Version: 1.0
# Date: 2025-05-15

function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error", "Success", "Debug")]
        [string]$Level = "Info",

        [Parameter(Mandatory = $false)]
        [string]$LogFile,

        [Parameter(Mandatory = $false)]
        [switch]$NoConsole,

        [Parameter(Mandatory = $false)]
        [switch]$NoTimestamp
    )

    # Déterminer la couleur en fonction du niveau
    $color = switch ($Level) {
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Success" { "Green" }
        "Debug" { "Cyan" }
        default { "White" }
    }

    # Créer le message formaté
    $timestamp = if (-not $NoTimestamp) { "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') " } else { "" }
    $formattedMessage = "$timestamp[$Level] $Message"

    # Afficher dans la console si demandé
    if (-not $NoConsole) {
        Write-Host $formattedMessage -ForegroundColor $color
    }

    # Écrire dans le fichier de log si spécifié
    if ($LogFile) {
        # Créer le dossier parent si nécessaire
        $logDir = Split-Path -Path $LogFile -Parent
        if ($logDir -and -not (Test-Path -Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }

        # Ajouter le message au fichier de log
        Add-Content -Path $LogFile -Value $formattedMessage -Encoding UTF8
    }
}

# Fonction pour créer un fichier de log avec rotation
function Initialize-LogFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogDirectory,

        [Parameter(Mandatory = $false)]
        [string]$Prefix = "log",

        [Parameter(Mandatory = $false)]
        [int]$MaxLogFiles = 10,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeTimestamp
    )

    # Créer le dossier de logs s'il n'existe pas
    if (-not (Test-Path -Path $LogDirectory)) {
        New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null
    }

    # Déterminer le nom du fichier de log
    $logFileName = if ($IncludeTimestamp) {
        "$Prefix-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    } else {
        "$Prefix.log"
    }

    $logFilePath = Join-Path -Path $LogDirectory -ChildPath $logFileName

    # Effectuer la rotation des logs si nécessaire
    if (-not $IncludeTimestamp) {
        # Obtenir tous les fichiers de log existants
        $existingLogs = Get-ChildItem -Path $LogDirectory -Filter "$Prefix*.log" |
            Sort-Object -Property LastWriteTime -Descending

        # Si le nombre maximum de fichiers est atteint, supprimer les plus anciens
        if ($existingLogs.Count -ge $MaxLogFiles) {
            $logsToRemove = $existingLogs | Select-Object -Skip ($MaxLogFiles - 1)
            foreach ($log in $logsToRemove) {
                Remove-Item -Path $log.FullName -Force
                Write-Verbose "Fichier de log supprimé : $($log.FullName)"
            }
        }
    }

    # Initialiser le fichier de log
    Set-Content -Path $logFilePath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [Info] Initialisation du fichier de log" -Encoding UTF8

    return $logFilePath
}

# Fonction pour obtenir un résumé des logs
function Get-LogSummary {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogFile,

        [Parameter(Mandatory = $false)]
        [int]$MaxEntries = 10,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error", "Success", "Debug")]
        [string[]]$Levels = @("Warning", "Error")
    )

    if (-not (Test-Path -Path $LogFile)) {
        Write-Warning "Le fichier de log $LogFile n'existe pas."
        return $null
    }

    $logContent = Get-Content -Path $LogFile
    $filteredEntries = @()

    foreach ($line in $logContent) {
        foreach ($level in $Levels) {
            if ($line -match "\[$level\]") {
                $filteredEntries += $line
                break
            }
        }
    }

    # Retourner les dernières entrées
    return $filteredEntries | Select-Object -Last $MaxEntries
}

# Exporter les fonctions si le script est importé comme module
# Export-ModuleMember -Function Write-Log, Initialize-LogFile, Get-LogSummary
