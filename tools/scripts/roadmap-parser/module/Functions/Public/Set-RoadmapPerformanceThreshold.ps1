<#
.SYNOPSIS
    DÃ©finit un seuil de performance pour un chronomÃ¨tre.

.DESCRIPTION
    La fonction Set-RoadmapPerformanceThreshold dÃ©finit un seuil de performance pour un chronomÃ¨tre.
    Si le temps d'exÃ©cution dÃ©passe ce seuil, un avertissement sera journalisÃ©.

.PARAMETER Name
    Le nom du chronomÃ¨tre.

.PARAMETER ThresholdMs
    Le seuil de temps d'exÃ©cution en millisecondes.

.EXAMPLE
    Set-RoadmapPerformanceThreshold -Name "MaFonction" -ThresholdMs 1000
    DÃ©finit un seuil de 1000 millisecondes pour le chronomÃ¨tre nommÃ© "MaFonction".

.OUTPUTS
    [void]

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-23
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

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $performanceFunctionsPath)) {
        throw "Le fichier PerformanceMeasurementFunctions.ps1 est introuvable Ã  l'emplacement : $performanceFunctionsPath"
    }

    # Importer les fonctions
    . $performanceFunctionsPath

    # Appeler la fonction de seuil de performance
    Set-PerformanceThreshold -Name $Name -ThresholdMs $ThresholdMs
}
