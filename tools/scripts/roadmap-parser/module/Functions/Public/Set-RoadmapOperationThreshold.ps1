<#
.SYNOPSIS
    Définit un seuil d'opérations pour un compteur.

.DESCRIPTION
    La fonction Set-RoadmapOperationThreshold définit un seuil d'opérations pour un compteur.
    Si le nombre d'opérations dépasse ce seuil, un avertissement sera journalisé.

.PARAMETER Name
    Le nom du compteur.

.PARAMETER Threshold
    Le seuil d'opérations.

.EXAMPLE
    Set-RoadmapOperationThreshold -Name "MaFonction" -Threshold 1000
    Définit un seuil de 1000 opérations pour le compteur nommé "MaFonction".

.OUTPUTS
    [void]

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-23
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

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $performanceFunctionsPath)) {
        throw "Le fichier PerformanceMeasurementFunctions.ps1 est introuvable à l'emplacement : $performanceFunctionsPath"
    }

    # Importer les fonctions
    . $performanceFunctionsPath

    # Appeler la fonction de seuil d'opérations
    Set-OperationThreshold -Name $Name -Threshold $Threshold
}
