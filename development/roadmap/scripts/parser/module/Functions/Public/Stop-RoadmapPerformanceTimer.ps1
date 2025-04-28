<#
.SYNOPSIS
    ArrÃªte un chronomÃ¨tre et enregistre le temps d'exÃ©cution.

.DESCRIPTION
    La fonction Stop-RoadmapPerformanceTimer arrÃªte un chronomÃ¨tre et enregistre le temps d'exÃ©cution.
    Elle met Ã  jour les statistiques pour le chronomÃ¨tre spÃ©cifiÃ©.

.PARAMETER Name
    Le nom du chronomÃ¨tre Ã  arrÃªter.

.PARAMETER LogResult
    Indique si le rÃ©sultat doit Ãªtre journalisÃ©.
    Par dÃ©faut, c'est $true.

.EXAMPLE
    Stop-RoadmapPerformanceTimer -Name "MaFonction"
    ArrÃªte le chronomÃ¨tre nommÃ© "MaFonction" et journalise le rÃ©sultat.

.OUTPUTS
    [double] Le temps d'exÃ©cution en millisecondes.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-23
#>
function Stop-RoadmapPerformanceTimer {
    [CmdletBinding()]
    [OutputType([double])]
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

    # Appeler la fonction d'arrÃªt du chronomÃ¨tre
    return Stop-PerformanceTimer -Name $Name -LogResult:$LogResult
}
