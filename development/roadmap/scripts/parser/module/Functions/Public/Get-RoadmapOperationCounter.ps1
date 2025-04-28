<#
.SYNOPSIS
    Obtient la valeur d'un compteur d'opÃ©rations.

.DESCRIPTION
    La fonction Get-RoadmapOperationCounter obtient la valeur d'un compteur d'opÃ©rations.
    Elle retourne 0 si le compteur n'existe pas.

.PARAMETER Name
    Le nom du compteur.

.EXAMPLE
    Get-RoadmapOperationCounter -Name "MaFonction"
    Obtient la valeur du compteur d'opÃ©rations nommÃ© "MaFonction".

.OUTPUTS
    [int] La valeur du compteur.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-23
#>
function Get-RoadmapOperationCounter {
    [CmdletBinding()]
    [OutputType([int])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name
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

    # Appeler la fonction d'obtention du compteur
    return Get-OperationCounter -Name $Name
}
