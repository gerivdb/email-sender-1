<#
.SYNOPSIS
    Écrit un message de journal pour le module RoadmapParser.

.DESCRIPTION
    La fonction Write-RoadmapLog écrit un message de journal pour le module RoadmapParser.
    Elle prend en charge différents niveaux de journalisation et peut écrire dans un fichier,
    dans la console, ou les deux.

.PARAMETER Message
    Le message à journaliser.

.PARAMETER Level
    Le niveau de journalisation. Valeurs possibles : Debug, Info, Warning, Error, Fatal.
    Par défaut : Info.

.PARAMETER Category
    La catégorie du message. Permet de regrouper les messages par catégorie.
    Par défaut : General.

.PARAMETER Exception
    L'exception associée au message, le cas échéant.

.PARAMETER FilePath
    Le chemin du fichier de journal. Si non spécifié, le journal sera écrit uniquement dans la console.

.PARAMETER NoConsole
    Indique si le message ne doit pas être affiché dans la console.

.PARAMETER AdditionalInfo
    Informations supplémentaires à inclure dans le message de journal.

.EXAMPLE
    Write-RoadmapLog -Message "Traitement du fichier roadmap.md" -Level Info -Category "Parsing"
    Écrit un message d'information dans la console.

.EXAMPLE
    Write-RoadmapLog -Message "Erreur lors de l'ouverture du fichier" -Level Error -Category "IO" -Exception $_ -FilePath ".\logs\roadmap-parser.log"
    Écrit un message d'erreur dans la console et dans un fichier, avec les détails de l'exception.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-15
#>
function Write-RoadmapLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Debug", "Info", "Warning", "Error", "Fatal")]
        [string]$Level = "Info",

        [Parameter(Mandatory = $false)]
        [string]$Category = "General",

        [Parameter(Mandatory = $false)]
        [System.Exception]$Exception,

        [Parameter(Mandatory = $false)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [switch]$NoConsole,

        [Parameter(Mandatory = $false)]
        [System.Collections.Hashtable]$AdditionalInfo
    )

    # Créer le message de journal formaté
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] [$Category] $Message"

    # Ajouter les informations supplémentaires
    if ($AdditionalInfo -and $AdditionalInfo.Count -gt 0) {
        $logMessage += "`nAdditional Information:"
        foreach ($key in $AdditionalInfo.Keys) {
            $logMessage += "`n  - ${key}: $($AdditionalInfo[$key])"
        }
    }

    # Ajouter les détails de l'exception
    if ($Exception) {
        # Vérifier si c'est une exception personnalisée avec une méthode GetDetailedMessage
        if ($Exception.PSObject.Methods.Name -contains "GetDetailedMessage") {
            $logMessage += "`nException Details: $($Exception.GetDetailedMessage())"
        } else {
            $logMessage += "`nException: $($Exception.Message)"
            if ($Exception.StackTrace) {
                $logMessage += "`nStack Trace: $($Exception.StackTrace)"
            }
            if ($Exception.InnerException) {
                $logMessage += "`nInner Exception: $($Exception.InnerException.Message)"
            }
        }
    }

    # Écrire dans la console si demandé
    if (-not $NoConsole) {
        switch ($Level) {
            "Debug" {
                Write-Verbose $logMessage
            }
            "Info" {
                Write-Host $logMessage -ForegroundColor Cyan
            }
            "Warning" {
                Write-Warning $logMessage
            }
            "Error" {
                Write-Error $logMessage
            }
            "Fatal" {
                Write-Error $logMessage
            }
        }
    }

    # Écrire dans le fichier si spécifié
    if (-not [string]::IsNullOrEmpty($FilePath)) {
        try {
            # Créer le répertoire parent si nécessaire
            $logDir = Split-Path -Path $FilePath -Parent
            if (-not [string]::IsNullOrEmpty($logDir) -and -not (Test-Path -Path $logDir)) {
                New-Item -Path $logDir -ItemType Directory -Force | Out-Null
            }

            # Ajouter le message au fichier
            $logMessage | Out-File -FilePath $FilePath -Append -Encoding UTF8
        } catch {
            Write-Error "Erreur lors de l'écriture dans le fichier de journal '$FilePath': $_"
        }
    }
}
