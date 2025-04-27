<#
.SYNOPSIS
    Trace une Ã©tape intermÃ©diaire dans une fonction.

.DESCRIPTION
    La fonction Trace-RoadmapFunctionStep trace une Ã©tape intermÃ©diaire dans une fonction.
    Elle enregistre le nom de l'Ã©tape et les donnÃ©es associÃ©es.

.PARAMETER StepName
    Le nom de l'Ã©tape.

.PARAMETER StepData
    Les donnÃ©es associÃ©es Ã  l'Ã©tape.

.PARAMETER FunctionName
    Le nom de la fonction.
    Par dÃ©faut, c'est le nom de la fonction appelante.

.EXAMPLE
    Trace-RoadmapFunctionStep -StepName "Validation des donnÃ©es"
    Trace l'Ã©tape "Validation des donnÃ©es" dans la fonction appelante.

.EXAMPLE
    Trace-RoadmapFunctionStep -StepName "Traitement" -StepData $data
    Trace l'Ã©tape "Traitement" avec les donnÃ©es spÃ©cifiÃ©es dans la fonction appelante.

.OUTPUTS
    [void]

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-22
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

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $tracingFunctionsPath)) {
        throw "Le fichier TracingFunctions.ps1 est introuvable Ã  l'emplacement : $tracingFunctionsPath"
    }

    # Importer les fonctions
    . $tracingFunctionsPath

    # Appeler la fonction de trace
    Trace-FunctionStep -StepName $StepName -StepData $StepData -FunctionName $FunctionName
}
