<#
.SYNOPSIS
    Mesure l'utilisation de la mémoire d'un bloc de code.

.DESCRIPTION
    La fonction Measure-RoadmapMemoryUsage mesure l'utilisation de la mémoire d'un bloc de code.
    Elle prend un instantané avant et après l'exécution du bloc de code, puis calcule la différence.

.PARAMETER Name
    Le nom de la mesure.

.PARAMETER ScriptBlock
    Le bloc de code à exécuter.

.PARAMETER InputObject
    L'objet à passer au bloc de code.

.PARAMETER ArgumentList
    Les arguments à passer au bloc de code.

.PARAMETER ForceGC
    Indique si le garbage collector doit être forcé avant de mesurer l'utilisation finale de la mémoire.
    Par défaut, c'est $false.

.EXAMPLE
    Measure-RoadmapMemoryUsage -Name "MaFonction" -ScriptBlock { Get-Process }
    Mesure l'utilisation de la mémoire de la commande Get-Process.

.OUTPUTS
    [PSCustomObject] Un objet contenant le résultat du bloc de code et l'utilisation de la mémoire.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-23
#>
function Measure-RoadmapMemoryUsage {
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
        [object[]]$ArgumentList,

        [Parameter(Mandatory = $false)]
        [switch]$ForceGC = $false
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

    # Appeler la fonction de mesure de mémoire
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

    if ($PSBoundParameters.ContainsKey('ForceGC')) {
        $params['ForceGC'] = $ForceGC
    }

    return Measure-MemoryUsage @params
}
