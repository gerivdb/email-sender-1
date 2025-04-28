<#
.SYNOPSIS
    Ã‰crit un message de journal pour le module RoadmapParser.

.DESCRIPTION
    La fonction Write-RoadmapLog Ã©crit un message de journal pour le module RoadmapParser.
    Elle prend en charge diffÃ©rents niveaux de journalisation et peut Ã©crire dans un fichier,
    dans la console, ou les deux.

.PARAMETER Message
    Le message Ã  journaliser.

.PARAMETER Level
    Le niveau de journalisation. Valeurs possibles : Debug, Info, Warning, Error, Fatal.
    Par dÃ©faut : Info.

.PARAMETER Category
    La catÃ©gorie du message. Permet de regrouper les messages par catÃ©gorie.
    Par dÃ©faut : General.

.PARAMETER Exception
    L'exception associÃ©e au message, le cas Ã©chÃ©ant.

.PARAMETER FilePath
    Le chemin du fichier de journal. Si non spÃ©cifiÃ©, le journal sera Ã©crit uniquement dans la console.

.PARAMETER NoConsole
    Indique si le message ne doit pas Ãªtre affichÃ© dans la console.

.PARAMETER AdditionalInfo
    Informations supplÃ©mentaires Ã  inclure dans le message de journal.

.EXAMPLE
    Write-RoadmapLog -Message "Traitement du fichier roadmap.md" -Level Info -Category "Parsing"
    Ã‰crit un message d'information dans la console.

.EXAMPLE
    Write-RoadmapLog -Message "Erreur lors de l'ouverture du fichier" -Level Error -Category "IO" -Exception $_ -FilePath ".\logs\roadmap-parser.log"
    Ã‰crit un message d'erreur dans la console et dans un fichier, avec les dÃ©tails de l'exception.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-15
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

    # CrÃ©er le message de journal formatÃ©
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] [$Category] $Message"

    # Ajouter les informations supplÃ©mentaires
    if ($AdditionalInfo -and $AdditionalInfo.Count -gt 0) {
        $logMessage += "`nAdditional Information:"
        foreach ($key in $AdditionalInfo.Keys) {
            $logMessage += "`n  - ${key}: $($AdditionalInfo[$key])"
        }
    }

    # Ajouter les dÃ©tails de l'exception
    if ($Exception) {
        # VÃ©rifier si c'est une exception personnalisÃ©e avec une mÃ©thode GetDetailedMessage
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

    # Ã‰crire dans la console si demandÃ©
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

    # Ã‰crire dans le fichier si spÃ©cifiÃ©
    if (-not [string]::IsNullOrEmpty($FilePath)) {
        try {
            # CrÃ©er le rÃ©pertoire parent si nÃ©cessaire
            $logDir = Split-Path -Path $FilePath -Parent
            if (-not [string]::IsNullOrEmpty($logDir) -and -not (Test-Path -Path $logDir)) {
                New-Item -Path $logDir -ItemType Directory -Force | Out-Null
            }

            # Ajouter le message au fichier
            $logMessage | Out-File -FilePath $FilePath -Append -Encoding UTF8
        } catch {
            Write-Error "Erreur lors de l'Ã©criture dans le fichier de journal '$FilePath': $_"
        }
    }
}
