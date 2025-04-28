<#
.SYNOPSIS
    IncrÃ©mente un compteur d'opÃ©rations.

.DESCRIPTION
    La fonction Add-RoadmapOperationCount incrÃ©mente un compteur d'opÃ©rations.
    Elle crÃ©e le compteur s'il n'existe pas.

.PARAMETER Name
    Le nom du compteur Ã  incrÃ©menter.

.PARAMETER IncrementBy
    La valeur Ã  ajouter au compteur.
    Par dÃ©faut, c'est 1.

.PARAMETER LogResult
    Indique si le rÃ©sultat doit Ãªtre journalisÃ©.
    Par dÃ©faut, c'est $false.

.EXAMPLE
    Add-RoadmapOperationCount -Name "MaFonction"
    IncrÃ©mente le compteur d'opÃ©rations nommÃ© "MaFonction" de 1.

.OUTPUTS
    [int] La nouvelle valeur du compteur.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-23
#>
function Add-RoadmapOperationCount {
    [CmdletBinding()]
    [OutputType([int])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [int]$IncrementBy = 1,

        [Parameter(Mandatory = $false)]
        [switch]$LogResult
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

    # Appeler la fonction d'incrÃ©mentation du compteur
    $params = @{
        Name = $Name
        IncrementBy = $IncrementBy
    }

    if ($PSBoundParameters.ContainsKey('LogResult')) {
        $params['LogResult'] = $LogResult
    }

    return Increment-OperationCounter @params
}
