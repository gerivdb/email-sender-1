<#
.SYNOPSIS
    Écrit un message d'information dans le journal du module RoadmapParser.

.DESCRIPTION
    La fonction Write-RoadmapInformation écrit un message d'information dans le journal du module RoadmapParser.
    Elle est un wrapper autour de Write-RoadmapLog avec le niveau de journalisation Information.

.PARAMETER Message
    Le message à écrire dans le journal.

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
    Write-RoadmapInformation -Message "Ceci est un message d'information"
    Écrit un message d'information dans le journal.

.OUTPUTS
    [string] Le message formaté si PassThru est $true, sinon rien.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-21
#>
function Write-RoadmapInformation {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Message,

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

    # Utiliser directement la fonction Write-RoadmapLog qui est déjà importée par le module

    # Construire les paramètres pour Write-RoadmapLog
    $params = @{
        Message = $Message
        Level   = "Information"
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

    if ($PSBoundParameters.ContainsKey('Category')) {
        $params['Category'] = $Category
    }

    if ($PSBoundParameters.ContainsKey('AdditionalInfo')) {
        $params['AdditionalInfo'] = $AdditionalInfo
    }

    # Écrire le message dans le journal
    return Write-RoadmapLog @params
}
