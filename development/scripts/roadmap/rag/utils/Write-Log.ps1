# Write-Log.ps1
# Module de journalisation pour les scripts du système RAG de roadmaps
# Version: 1.0
# Date: 2025-05-15

function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet("Info", "Warning", "Error", "Success", "Debug")]
        [string]$Level = "Info",

        [Parameter(Mandatory = $false)]
        [string]$LogFilePath,

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
        "Debug" { "Gray" }
        default { "White" }
    }

    # Créer le message formaté
    $timestamp = if (-not $NoTimestamp) { "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') " } else { "" }
    $formattedMessage = "$timestamp[$Level] $Message"

    # Afficher le message dans la console
    if (-not $NoConsole) {
        Write-Host $formattedMessage -ForegroundColor $color
    }

    # Enregistrer le message dans un fichier de journal si un chemin est spécifié
    if (-not [string]::IsNullOrEmpty($LogFilePath)) {
        try {
            # Créer le répertoire du fichier de journal si nécessaire
            $logDir = Split-Path -Parent $LogFilePath

            if (-not [string]::IsNullOrEmpty($logDir) -and -not (Test-Path -Path $logDir)) {
                New-Item -Path $logDir -ItemType Directory -Force | Out-Null
            }

            # Ajouter le message au fichier de journal
            $formattedMessage | Out-File -FilePath $LogFilePath -Append -Encoding UTF8
        } catch {
            Write-Host "Erreur lors de l'écriture dans le fichier de journal : $_" -ForegroundColor Red
        }
    }
}

function Write-InfoLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$LogFilePath,

        [Parameter(Mandatory = $false)]
        [switch]$NoConsole,

        [Parameter(Mandatory = $false)]
        [switch]$NoTimestamp
    )

    Write-Log -Message $Message -Level "Info" -LogFilePath $LogFilePath -NoConsole:$NoConsole -NoTimestamp:$NoTimestamp
}

function Write-WarningLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$LogFilePath,

        [Parameter(Mandatory = $false)]
        [switch]$NoConsole,

        [Parameter(Mandatory = $false)]
        [switch]$NoTimestamp
    )

    Write-Log -Message $Message -Level "Warning" -LogFilePath $LogFilePath -NoConsole:$NoConsole -NoTimestamp:$NoTimestamp
}

function Write-ErrorLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$LogFilePath,

        [Parameter(Mandatory = $false)]
        [switch]$NoConsole,

        [Parameter(Mandatory = $false)]
        [switch]$NoTimestamp
    )

    Write-Log -Message $Message -Level "Error" -LogFilePath $LogFilePath -NoConsole:$NoConsole -NoTimestamp:$NoTimestamp
}

function Write-SuccessLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$LogFilePath,

        [Parameter(Mandatory = $false)]
        [switch]$NoConsole,

        [Parameter(Mandatory = $false)]
        [switch]$NoTimestamp
    )

    Write-Log -Message $Message -Level "Success" -LogFilePath $LogFilePath -NoConsole:$NoConsole -NoTimestamp:$NoTimestamp
}

function Write-DebugLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$LogFilePath,

        [Parameter(Mandatory = $false)]
        [switch]$NoConsole,

        [Parameter(Mandatory = $false)]
        [switch]$NoTimestamp
    )

    Write-Log -Message $Message -Level "Debug" -LogFilePath $LogFilePath -NoConsole:$NoConsole -NoTimestamp:$NoTimestamp
}

# Fonctions exportées implicitement
