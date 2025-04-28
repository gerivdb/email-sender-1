<#
.SYNOPSIS
    Ã‰crit un message d'erreur dans le journal du module RoadmapParser.

.DESCRIPTION
    La fonction Write-RoadmapError Ã©crit un message d'erreur dans le journal du module RoadmapParser.
    Elle est un wrapper autour de Write-RoadmapLog avec le niveau de journalisation Error.

.PARAMETER Message
    Le message Ã  Ã©crire dans le journal.

.PARAMETER Source
    La source du message.
    Par dÃ©faut, c'est "RoadmapParser".

.PARAMETER Exception
    L'exception Ã  inclure dans le message.

.PARAMETER NoNewLine
    Indique si un saut de ligne doit Ãªtre ajoutÃ© Ã  la fin du message.
    Par dÃ©faut, c'est $false.

.PARAMETER PassThru
    Indique si le message doit Ãªtre retournÃ© aprÃ¨s avoir Ã©tÃ© Ã©crit dans le journal.
    Par dÃ©faut, c'est $false.

.PARAMETER Category
    La catÃ©gorie du message. Permet de regrouper les messages par catÃ©gorie.
    Par dÃ©faut : General.

.PARAMETER AdditionalInfo
    Informations supplÃ©mentaires Ã  inclure dans le message de journal.

.EXAMPLE
    Write-RoadmapError -Message "Ceci est un message d'erreur"
    Ã‰crit un message d'erreur dans le journal.

.OUTPUTS
    [string] Le message formatÃ© si PassThru est $true, sinon rien.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-21
#>
function Write-RoadmapError {
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

    # Utiliser directement la fonction Write-RoadmapLog qui est dÃ©jÃ  importÃ©e par le module

    # Construire les paramÃ¨tres pour Write-RoadmapLog
    $params = @{
        Message = $Message
        Level   = "Error"
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

    # Ã‰crire le message dans le journal
    return Write-RoadmapLog @params
}
