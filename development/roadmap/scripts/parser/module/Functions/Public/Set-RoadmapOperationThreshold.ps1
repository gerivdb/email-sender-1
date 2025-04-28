<#
.SYNOPSIS
    DÃ©finit un seuil d'opÃ©rations pour un compteur.

.DESCRIPTION
    La fonction Set-RoadmapOperationThreshold dÃ©finit un seuil d'opÃ©rations pour un compteur.
    Si le nombre d'opÃ©rations dÃ©passe ce seuil, un avertissement sera journalisÃ©.

.PARAMETER Name
    Le nom du compteur.

.PARAMETER Threshold
    Le seuil d'opÃ©rations.

.EXAMPLE
    Set-RoadmapOperationThreshold -Name "MaFonction" -Threshold 1000
    DÃ©finit un seuil de 1000 opÃ©rations pour le compteur nommÃ© "MaFonction".

.OUTPUTS
    [void]

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-23
#>
function Set-RoadmapOperationThreshold {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $true, Position = 1)]
        [int]$Threshold
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

    # Appeler la fonction de seuil d'opÃ©rations
    Set-OperationThreshold -Name $Name -Threshold $Threshold
}
