<#
.SYNOPSIS
    Incrémente un compteur d'opérations.

.DESCRIPTION
    La fonction Add-RoadmapOperationCount incrémente un compteur d'opérations.
    Elle crée le compteur s'il n'existe pas.

.PARAMETER Name
    Le nom du compteur à incrémenter.

.PARAMETER IncrementBy
    La valeur à ajouter au compteur.
    Par défaut, c'est 1.

.PARAMETER LogResult
    Indique si le résultat doit être journalisé.
    Par défaut, c'est $false.

.EXAMPLE
    Add-RoadmapOperationCount -Name "MaFonction"
    Incrémente le compteur d'opérations nommé "MaFonction" de 1.

.OUTPUTS
    [int] La nouvelle valeur du compteur.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-23
#>
function Add-RoadmapOperationCount {
    [CmdletBinding()]
    [OutputType([int])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [int]$IncrementBy = 1,

        [Parameter(Mandatory = $false)]
        [switch]$LogResult
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

    # Appeler la fonction d'incrémentation du compteur
    $params = @{
        Name = $Name
        IncrementBy = $IncrementBy
    }

    if ($PSBoundParameters.ContainsKey('LogResult')) {
        $params['LogResult'] = $LogResult
    }

    return Increment-OperationCounter @params
}
