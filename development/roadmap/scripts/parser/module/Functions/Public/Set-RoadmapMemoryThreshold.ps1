<#
.SYNOPSIS
    DÃ©finit un seuil de mÃ©moire pour un instantanÃ©.

.DESCRIPTION
    La fonction Set-RoadmapMemoryThreshold dÃ©finit un seuil de mÃ©moire pour un instantanÃ©.
    Si l'utilisation de la mÃ©moire dÃ©passe ce seuil, un avertissement sera journalisÃ©.

.PARAMETER Name
    Le nom de l'instantanÃ©.

.PARAMETER ThresholdBytes
    Le seuil en octets.

.PARAMETER ThresholdMB
    Le seuil en mÃ©gaoctets.

.EXAMPLE
    Set-RoadmapMemoryThreshold -Name "MaFonction" -ThresholdMB 100
    DÃ©finit un seuil de 100 MB pour l'instantanÃ© nommÃ© "MaFonction".

.OUTPUTS
    [void]

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-23
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

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $performanceFunctionsPath)) {
        throw "Le fichier PerformanceMeasurementFunctions.ps1 est introuvable Ã  l'emplacement : $performanceFunctionsPath"
    }

    # Importer les fonctions
    . $performanceFunctionsPath

    # Appeler la fonction de seuil de mÃ©moire
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
