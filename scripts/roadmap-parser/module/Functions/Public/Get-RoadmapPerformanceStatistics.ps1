<#
.SYNOPSIS
    Obtient les statistiques de performance pour un chronomètre.

.DESCRIPTION
    La fonction Get-RoadmapPerformanceStatistics obtient les statistiques de performance pour un chronomètre.
    Elle retourne un objet contenant les statistiques telles que le nombre d'exécutions, le temps total, etc.

.PARAMETER Name
    Le nom du chronomètre.
    Si non spécifié, retourne les statistiques pour tous les chronomètres.

.EXAMPLE
    Get-RoadmapPerformanceStatistics -Name "MaFonction"
    Obtient les statistiques pour le chronomètre nommé "MaFonction".

.OUTPUTS
    [PSCustomObject] Un objet contenant les statistiques de performance.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-23
#>
function Get-RoadmapPerformanceStatistics {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Name
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

    # Appeler la fonction de statistiques de performance
    if ($PSBoundParameters.ContainsKey('Name')) {
        return Get-PerformanceStatistics -Name $Name
    } else {
        return Get-PerformanceStatistics
    }
}
