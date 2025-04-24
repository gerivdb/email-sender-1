<#
.SYNOPSIS
    Réinitialise un compteur d'opérations.

.DESCRIPTION
    La fonction Reset-RoadmapOperationCounter réinitialise un compteur d'opérations.
    Elle met à jour les statistiques pour le compteur spécifié.

.PARAMETER Name
    Le nom du compteur à réinitialiser.

.PARAMETER LogResult
    Indique si le résultat doit être journalisé.
    Par défaut, c'est $true.

.EXAMPLE
    Reset-RoadmapOperationCounter -Name "MaFonction"
    Réinitialise le compteur d'opérations nommé "MaFonction" et journalise le résultat.

.OUTPUTS
    [int] La valeur du compteur avant la réinitialisation.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-23
#>
function Reset-RoadmapOperationCounter {
    [CmdletBinding()]
    [OutputType([int])]
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

    # Appeler la fonction de réinitialisation du compteur
    return Reset-OperationCounter -Name $Name -LogResult:$LogResult
}
