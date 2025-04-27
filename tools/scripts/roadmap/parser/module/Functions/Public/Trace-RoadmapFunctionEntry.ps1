<#
.SYNOPSIS
    Trace l'entrÃ©e dans une fonction.

.DESCRIPTION
    La fonction Trace-RoadmapFunctionEntry trace l'entrÃ©e dans une fonction.
    Elle enregistre le nom de la fonction et les paramÃ¨tres d'entrÃ©e.

.PARAMETER FunctionName
    Le nom de la fonction.
    Par dÃ©faut, c'est le nom de la fonction appelante.

.PARAMETER Parameters
    Les paramÃ¨tres de la fonction.
    Par dÃ©faut, ce sont les paramÃ¨tres liÃ©s de la fonction appelante.

.PARAMETER CallerName
    Le nom de l'appelant.
    Par dÃ©faut, c'est dÃ©terminÃ© automatiquement.

.PARAMETER IncreaseDepth
    Indique si la profondeur doit Ãªtre augmentÃ©e aprÃ¨s la trace.
    Par dÃ©faut, c'est $true.

.EXAMPLE
    Trace-RoadmapFunctionEntry
    Trace l'entrÃ©e dans la fonction appelante.

.EXAMPLE
    Trace-RoadmapFunctionEntry -FunctionName "Ma-Fonction" -Parameters $PSBoundParameters
    Trace l'entrÃ©e dans la fonction "Ma-Fonction" avec les paramÃ¨tres spÃ©cifiÃ©s.

.OUTPUTS
    [void]

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-22
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

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $tracingFunctionsPath)) {
        throw "Le fichier TracingFunctions.ps1 est introuvable Ã  l'emplacement : $tracingFunctionsPath"
    }

    # Importer les fonctions
    . $tracingFunctionsPath

    # Appeler la fonction de trace
    Trace-FunctionEntry -FunctionName $FunctionName -Parameters $Parameters -CallerName $CallerName -IncreaseDepth:$IncreaseDepth
}
