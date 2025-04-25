<#
.SYNOPSIS
    Obtient les statistiques de mémoire pour un instantané.

.DESCRIPTION
    La fonction Get-RoadmapMemoryStatistics obtient les statistiques de mémoire pour un instantané.
    Elle retourne un objet contenant les statistiques telles que le nombre d'exécutions, l'utilisation totale, etc.

.PARAMETER Name
    Le nom de l'instantané.
    Si non spécifié, retourne les statistiques pour tous les instantanés.

.EXAMPLE
    Get-RoadmapMemoryStatistics -Name "MaFonction"
    Obtient les statistiques pour l'instantané nommé "MaFonction".

.OUTPUTS
    [PSCustomObject] Un objet contenant les statistiques de mémoire.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-23
#>
function Get-RoadmapMemoryStatistics {
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

    # Appeler la fonction de statistiques de mémoire
    if ($PSBoundParameters.ContainsKey('Name')) {
        return Get-MemoryStatistics -Name $Name
    } else {
        return Get-MemoryStatistics
    }
}
