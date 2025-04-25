<#
.SYNOPSIS
    Mesure le nombre d'opérations effectuées par un bloc de code.

.DESCRIPTION
    La fonction Measure-RoadmapOperations mesure le nombre d'opérations effectuées par un bloc de code.
    Elle initialise un compteur, exécute le bloc de code, puis réinitialise le compteur.

.PARAMETER Name
    Le nom du compteur.

.PARAMETER ScriptBlock
    Le bloc de code à exécuter.

.PARAMETER InputObject
    L'objet à passer au bloc de code.

.PARAMETER ArgumentList
    Les arguments à passer au bloc de code.

.EXAMPLE
    Measure-RoadmapOperations -Name "MaFonction" -ScriptBlock { 
        for ($i = 0; $i -lt 1000; $i++) {
            Add-RoadmapOperationCount -Name "MaFonction"
        }
    }
    Mesure le nombre d'opérations effectuées par le bloc de code.

.OUTPUTS
    [PSCustomObject] Un objet contenant le résultat du bloc de code et le nombre d'opérations.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-23
#>
function Measure-RoadmapOperations {
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

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $performanceFunctionsPath)) {
        throw "Le fichier PerformanceMeasurementFunctions.ps1 est introuvable à l'emplacement : $performanceFunctionsPath"
    }

    # Importer les fonctions
    . $performanceFunctionsPath

    # Appeler la fonction de mesure d'opérations
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

    return Measure-Operations @params
}
