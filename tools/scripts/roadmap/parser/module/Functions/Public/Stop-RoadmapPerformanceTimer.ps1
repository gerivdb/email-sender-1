<#
.SYNOPSIS
    Arrête un chronomètre et enregistre le temps d'exécution.

.DESCRIPTION
    La fonction Stop-RoadmapPerformanceTimer arrête un chronomètre et enregistre le temps d'exécution.
    Elle met à jour les statistiques pour le chronomètre spécifié.

.PARAMETER Name
    Le nom du chronomètre à arrêter.

.PARAMETER LogResult
    Indique si le résultat doit être journalisé.
    Par défaut, c'est $true.

.EXAMPLE
    Stop-RoadmapPerformanceTimer -Name "MaFonction"
    Arrête le chronomètre nommé "MaFonction" et journalise le résultat.

.OUTPUTS
    [double] Le temps d'exécution en millisecondes.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-23
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

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $performanceFunctionsPath)) {
        throw "Le fichier PerformanceMeasurementFunctions.ps1 est introuvable à l'emplacement : $performanceFunctionsPath"
    }

    # Importer les fonctions
    . $performanceFunctionsPath

    # Appeler la fonction d'arrêt du chronomètre
    return Stop-PerformanceTimer -Name $Name -LogResult:$LogResult
}
