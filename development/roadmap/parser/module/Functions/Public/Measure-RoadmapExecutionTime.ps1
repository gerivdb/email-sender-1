<#
.SYNOPSIS
    Mesure le temps d'exÃ©cution d'un bloc de code.

.DESCRIPTION
    La fonction Measure-RoadmapExecutionTime mesure le temps d'exÃ©cution d'un bloc de code.
    Elle dÃ©marre un chronomÃ¨tre, exÃ©cute le bloc de code, puis arrÃªte le chronomÃ¨tre.

.PARAMETER Name
    Le nom du chronomÃ¨tre.

.PARAMETER ScriptBlock
    Le bloc de code Ã  exÃ©cuter.

.PARAMETER InputObject
    L'objet Ã  passer au bloc de code.

.PARAMETER ArgumentList
    Les arguments Ã  passer au bloc de code.

.EXAMPLE
    Measure-RoadmapExecutionTime -Name "MaFonction" -ScriptBlock { Get-Process }
    Mesure le temps d'exÃ©cution de la commande Get-Process.

.OUTPUTS
    [PSCustomObject] Un objet contenant le rÃ©sultat du bloc de code et le temps d'exÃ©cution.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-23
#>
function Measure-RoadmapExecutionTime {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $true, Position = 1)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $false)]
        [object]$InputObject,

        [Parameter(Mandatory = $false)]
        [object[]]$ArgumentList
    )

    # Importer les fonctions de mesure de performance
    $modulePath = $PSScriptRoot
    if ($modulePath -match '\\Functions\\Public$') {
        $modulePath = Split-Path -Parent (Split-Path -Parent $modulePath)
    }
    $privatePath = Join-Path -Path $modulePath -ChildPath "Functions\Private\Performance"
    $performanceFunctionsPath = Join-Path -Path $privatePath -ChildPath "PerformanceMeasurementFunctions.ps1"

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $performanceFunctionsPath)) {
        throw "Le fichier PerformanceMeasurementFunctions.ps1 est introuvable Ã  l'emplacement : $performanceFunctionsPath"
    }

    # Importer les fonctions
    . $performanceFunctionsPath

    # Appeler la fonction de mesure de temps d'exÃ©cution
    $params = @{
        Name = $Name
        ScriptBlock = $ScriptBlock
    }

    if ($PSBoundParameters.ContainsKey('InputObject')) {
        $params['InputObject'] = $InputObject
    }

    if ($PSBoundParameters.ContainsKey('ArgumentList')) {
        $params['ArgumentList'] = $ArgumentList
    }

    return Measure-ExecutionTime @params
}
