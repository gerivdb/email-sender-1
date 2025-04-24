<#
.SYNOPSIS
    Définit un seuil de performance pour un chronomètre.

.DESCRIPTION
    La fonction Set-RoadmapPerformanceThreshold définit un seuil de performance pour un chronomètre.
    Si le temps d'exécution dépasse ce seuil, un avertissement sera journalisé.

.PARAMETER Name
    Le nom du chronomètre.

.PARAMETER ThresholdMs
    Le seuil de temps d'exécution en millisecondes.

.EXAMPLE
    Set-RoadmapPerformanceThreshold -Name "MaFonction" -ThresholdMs 1000
    Définit un seuil de 1000 millisecondes pour le chronomètre nommé "MaFonction".

.OUTPUTS
    [void]

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-23
#>
function Set-RoadmapPerformanceThreshold {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $true, Position = 1)]
        [int]$ThresholdMs
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

    # Appeler la fonction de seuil de performance
    Set-PerformanceThreshold -Name $Name -ThresholdMs $ThresholdMs
}
