<#
.SYNOPSIS
    Définit un seuil de mémoire pour un instantané.

.DESCRIPTION
    La fonction Set-RoadmapMemoryThreshold définit un seuil de mémoire pour un instantané.
    Si l'utilisation de la mémoire dépasse ce seuil, un avertissement sera journalisé.

.PARAMETER Name
    Le nom de l'instantané.

.PARAMETER ThresholdBytes
    Le seuil en octets.

.PARAMETER ThresholdMB
    Le seuil en mégaoctets.

.EXAMPLE
    Set-RoadmapMemoryThreshold -Name "MaFonction" -ThresholdMB 100
    Définit un seuil de 100 MB pour l'instantané nommé "MaFonction".

.OUTPUTS
    [void]

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-23
#>
function Set-RoadmapMemoryThreshold {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $false, Position = 1)]
        [double]$ThresholdBytes,

        [Parameter(Mandatory = $false)]
        [double]$ThresholdMB
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

    # Appeler la fonction de seuil de mémoire
    $params = @{
        Name = $Name
    }

    if ($PSBoundParameters.ContainsKey('ThresholdBytes')) {
        $params['ThresholdBytes'] = $ThresholdBytes
    }

    if ($PSBoundParameters.ContainsKey('ThresholdMB')) {
        $params['ThresholdMB'] = $ThresholdMB
    }

    Set-MemoryThreshold @params
}
