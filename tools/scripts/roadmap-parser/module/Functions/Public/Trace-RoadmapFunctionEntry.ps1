<#
.SYNOPSIS
    Trace l'entrée dans une fonction.

.DESCRIPTION
    La fonction Trace-RoadmapFunctionEntry trace l'entrée dans une fonction.
    Elle enregistre le nom de la fonction et les paramètres d'entrée.

.PARAMETER FunctionName
    Le nom de la fonction.
    Par défaut, c'est le nom de la fonction appelante.

.PARAMETER Parameters
    Les paramètres de la fonction.
    Par défaut, ce sont les paramètres liés de la fonction appelante.

.PARAMETER CallerName
    Le nom de l'appelant.
    Par défaut, c'est déterminé automatiquement.

.PARAMETER IncreaseDepth
    Indique si la profondeur doit être augmentée après la trace.
    Par défaut, c'est $true.

.EXAMPLE
    Trace-RoadmapFunctionEntry
    Trace l'entrée dans la fonction appelante.

.EXAMPLE
    Trace-RoadmapFunctionEntry -FunctionName "Ma-Fonction" -Parameters $PSBoundParameters
    Trace l'entrée dans la fonction "Ma-Fonction" avec les paramètres spécifiés.

.OUTPUTS
    [void]

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-22
#>
function Trace-RoadmapFunctionEntry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$FunctionName = (Get-PSCallStack)[1].Command,

        [Parameter(Mandatory = $false)]
        [System.Collections.IDictionary]$Parameters = (Get-Variable -Name PSBoundParameters -Scope 1 -ErrorAction SilentlyContinue).Value,

        [Parameter(Mandatory = $false)]
        [string]$CallerName,

        [Parameter(Mandatory = $false)]
        [switch]$IncreaseDepth = $true
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
    Trace-FunctionEntry -FunctionName $FunctionName -Parameters $Parameters -CallerName $CallerName -IncreaseDepth:$IncreaseDepth
}
