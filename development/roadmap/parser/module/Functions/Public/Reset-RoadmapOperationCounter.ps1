<#
.SYNOPSIS
    RÃ©initialise un compteur d'opÃ©rations.

.DESCRIPTION
    La fonction Reset-RoadmapOperationCounter rÃ©initialise un compteur d'opÃ©rations.
    Elle met Ã  jour les statistiques pour le compteur spÃ©cifiÃ©.

.PARAMETER Name
    Le nom du compteur Ã  rÃ©initialiser.

.PARAMETER LogResult
    Indique si le rÃ©sultat doit Ãªtre journalisÃ©.
    Par dÃ©faut, c'est $true.

.EXAMPLE
    Reset-RoadmapOperationCounter -Name "MaFonction"
    RÃ©initialise le compteur d'opÃ©rations nommÃ© "MaFonction" et journalise le rÃ©sultat.

.OUTPUTS
    [int] La valeur du compteur avant la rÃ©initialisation.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-23
#>
function Reset-RoadmapOperationCounter {
    [CmdletBinding()]
    [OutputType([int])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [switch]$LogResult = $true
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

    # Appeler la fonction de rÃ©initialisation du compteur
    return Reset-OperationCounter -Name $Name -LogResult:$LogResult
}
