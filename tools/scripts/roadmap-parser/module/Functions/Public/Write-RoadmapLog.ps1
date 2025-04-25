<#
.SYNOPSIS
    Écrit un message dans le journal du module RoadmapParser.

.DESCRIPTION
    La fonction Write-RoadmapLog écrit un message dans le journal du module RoadmapParser.
    Elle prend en charge différents niveaux de journalisation et destinations.

.PARAMETER Message
    Le message à écrire dans le journal.

.PARAMETER Level
    Le niveau de journalisation du message. Valeurs possibles :
    - Debug : Message de débogage
    - Verbose : Message détaillé
    - Information : Message d'information
    - Warning : Message d'avertissement
    - Error : Message d'erreur
    - Critical : Message critique
    Par défaut, c'est "Information".

.PARAMETER Source
    La source du message.
    Par défaut, c'est "RoadmapParser".

.PARAMETER Exception
    L'exception à inclure dans le message.

.PARAMETER NoNewLine
    Indique si un saut de ligne doit être ajouté à la fin du message.
    Par défaut, c'est $false.

.PARAMETER PassThru
    Indique si le message doit être retourné après avoir été écrit dans le journal.
    Par défaut, c'est $false.

.PARAMETER Category
    La catégorie du message. Permet de regrouper les messages par catégorie.
    Par défaut : General.

.PARAMETER AdditionalInfo
    Informations supplémentaires à inclure dans le message de journal.

.EXAMPLE
    Write-RoadmapLog -Message "Ceci est un message d'information"
    Écrit un message d'information dans le journal.

.EXAMPLE
    Write-RoadmapLog -Message "Ceci est un message d'erreur" -Level Error
    Écrit un message d'erreur dans le journal.

.EXAMPLE
    Write-RoadmapLog -Message "Ceci est un message d'avertissement" -Level Warning -Source "MonModule"
    Écrit un message d'avertissement dans le journal avec une source personnalisée.

.OUTPUTS
    [string] Le message formaté si PassThru est $true, sinon rien.

.NOTES
    Auteur: RoadmapParser Team
    Version: 2.0
    Date de création: 2023-07-21
#>
function Write-RoadmapLog {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Message,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet("Debug", "Verbose", "Information", "Warning", "Error", "Critical")]
        [string]$Level = "Information",

        [Parameter(Mandatory = $false)]
        [string]$Source = "RoadmapParser",

        [Parameter(Mandatory = $false)]
        [System.Exception]$Exception,

        [Parameter(Mandatory = $false)]
        [switch]$NoNewLine,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru,

        [Parameter(Mandatory = $false)]
        [string]$Category = "General",

        [Parameter(Mandatory = $false)]
        [System.Collections.Hashtable]$AdditionalInfo
    )

    # Importer les fonctions de journalisation
    $modulePath = $PSScriptRoot
    if ($modulePath -match '\\Functions\\Public$') {
        $modulePath = Split-Path -Parent (Split-Path -Parent $modulePath)
    }
    $privatePath = Join-Path -Path $modulePath -ChildPath "Functions\Private\Logging"
    $loggingFunctionsPath = Join-Path -Path $privatePath -ChildPath "LoggingFunctions.ps1"

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $loggingFunctionsPath)) {
        throw "Le fichier LoggingFunctions.ps1 est introuvable à l'emplacement : $loggingFunctionsPath"
    }

    # Importer les fonctions
    . $loggingFunctionsPath

    # Ajouter les informations supplémentaires au message
    $fullMessage = $Message

    if ($Category -ne "General") {
        $fullMessage = "[$Category] $fullMessage"
    }

    if ($AdditionalInfo -and $AdditionalInfo.Count -gt 0) {
        $fullMessage += "`nInformations supplémentaires:"
        foreach ($key in $AdditionalInfo.Keys) {
            $fullMessage += "`n  - ${key}: $($AdditionalInfo[$key])"
        }
    }

    # Construire les paramètres pour Write-Log
    $params = @{
        Message = $fullMessage
        Level   = $Level
        Source  = $Source
    }

    if ($PSBoundParameters.ContainsKey('Exception')) {
        $params['Exception'] = $Exception
    }

    if ($NoNewLine) {
        $params['NoNewLine'] = $true
    }

    if ($PassThru) {
        $params['PassThru'] = $true
    }

    # Écrire le message dans le journal
    return Write-Log @params
}
