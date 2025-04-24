<#
.SYNOPSIS
    Démarre un chronomètre pour mesurer le temps d'exécution.

.DESCRIPTION
    La fonction Start-RoadmapPerformanceTimer démarre un chronomètre pour mesurer le temps d'exécution.
    Elle crée un nouveau chronomètre ou réinitialise un chronomètre existant.

.PARAMETER Name
    Le nom du chronomètre.
    Ce nom est utilisé pour identifier le chronomètre lors de l'arrêt ou de la réinitialisation.

.PARAMETER Reset
    Indique si le chronomètre doit être réinitialisé s'il existe déjà.
    Par défaut, c'est $true.

.EXAMPLE
    Start-RoadmapPerformanceTimer -Name "MaFonction"
    Démarre un chronomètre nommé "MaFonction".

.OUTPUTS
    [void]

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-23
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

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $performanceFunctionsPath)) {
        throw "Le fichier PerformanceMeasurementFunctions.ps1 est introuvable à l'emplacement : $performanceFunctionsPath"
    }

    # Importer les fonctions
    . $performanceFunctionsPath

    # Appeler la fonction de démarrage du chronomètre
    Start-PerformanceTimer -Name $Name -Reset:$Reset
}
