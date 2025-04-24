<#
.SYNOPSIS
    Obtient les statistiques d'opérations pour un compteur.

.DESCRIPTION
    La fonction Get-RoadmapOperationStatistics obtient les statistiques d'opérations pour un compteur.
    Elle retourne un objet contenant les statistiques telles que le nombre d'exécutions, le total d'opérations, etc.

.PARAMETER Name
    Le nom du compteur.
    Si non spécifié, retourne les statistiques pour tous les compteurs.

.EXAMPLE
    Get-RoadmapOperationStatistics -Name "MaFonction"
    Obtient les statistiques pour le compteur nommé "MaFonction".

.OUTPUTS
    [PSCustomObject] Un objet contenant les statistiques d'opérations.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-23
#>
function Get-RoadmapOperationStatistics {
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

    # Appeler la fonction de statistiques d'opérations
    if ($PSBoundParameters.ContainsKey('Name')) {
        return Get-OperationStatistics -Name $Name
    } else {
        return Get-OperationStatistics
    }
}
