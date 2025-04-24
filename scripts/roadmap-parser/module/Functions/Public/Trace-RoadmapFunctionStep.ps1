<#
.SYNOPSIS
    Trace une étape intermédiaire dans une fonction.

.DESCRIPTION
    La fonction Trace-RoadmapFunctionStep trace une étape intermédiaire dans une fonction.
    Elle enregistre le nom de l'étape et les données associées.

.PARAMETER StepName
    Le nom de l'étape.

.PARAMETER StepData
    Les données associées à l'étape.

.PARAMETER FunctionName
    Le nom de la fonction.
    Par défaut, c'est le nom de la fonction appelante.

.EXAMPLE
    Trace-RoadmapFunctionStep -StepName "Validation des données"
    Trace l'étape "Validation des données" dans la fonction appelante.

.EXAMPLE
    Trace-RoadmapFunctionStep -StepName "Traitement" -StepData $data
    Trace l'étape "Traitement" avec les données spécifiées dans la fonction appelante.

.OUTPUTS
    [void]

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-22
#>
function Trace-RoadmapFunctionStep {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$StepName,

        [Parameter(Mandatory = $false, Position = 1)]
        [object]$StepData,

        [Parameter(Mandatory = $false)]
        [string]$FunctionName = (Get-PSCallStack)[1].Command
    )

    # Importer les fonctions de trace
    $modulePath = $PSScriptRoot
    if ($modulePath -match '\\Functions\\Public$') {
        $modulePath = Split-Path -Parent (Split-Path -Parent $modulePath)
    }
    $privatePath = Join-Path -Path $modulePath -ChildPath "Functions\Private\Logging"
    $tracingFunctionsPath = Join-Path -Path $privatePath -ChildPath "TracingFunctions.ps1"

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $tracingFunctionsPath)) {
        throw "Le fichier TracingFunctions.ps1 est introuvable à l'emplacement : $tracingFunctionsPath"
    }

    # Importer les fonctions
    . $tracingFunctionsPath

    # Appeler la fonction de trace
    Trace-FunctionStep -StepName $StepName -StepData $StepData -FunctionName $FunctionName
}
