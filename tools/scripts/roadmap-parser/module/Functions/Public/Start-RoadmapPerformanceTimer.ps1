<#
.SYNOPSIS
    DÃ©marre un chronomÃ¨tre pour mesurer le temps d'exÃ©cution.

.DESCRIPTION
    La fonction Start-RoadmapPerformanceTimer dÃ©marre un chronomÃ¨tre pour mesurer le temps d'exÃ©cution.
    Elle crÃ©e un nouveau chronomÃ¨tre ou rÃ©initialise un chronomÃ¨tre existant.

.PARAMETER Name
    Le nom du chronomÃ¨tre.
    Ce nom est utilisÃ© pour identifier le chronomÃ¨tre lors de l'arrÃªt ou de la rÃ©initialisation.

.PARAMETER Reset
    Indique si le chronomÃ¨tre doit Ãªtre rÃ©initialisÃ© s'il existe dÃ©jÃ .
    Par dÃ©faut, c'est $true.

.EXAMPLE
    Start-RoadmapPerformanceTimer -Name "MaFonction"
    DÃ©marre un chronomÃ¨tre nommÃ© "MaFonction".

.OUTPUTS
    [void]

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-23
#>
function Start-RoadmapPerformanceTimer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [switch]$Reset = $true
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

    # Appeler la fonction de dÃ©marrage du chronomÃ¨tre
    Start-PerformanceTimer -Name $Name -Reset:$Reset
}
