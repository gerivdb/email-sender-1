<#
.SYNOPSIS
    Trace la sortie d'une fonction.

.DESCRIPTION
    La fonction Trace-RoadmapFunctionExit trace la sortie d'une fonction.
    Elle enregistre le nom de la fonction et la valeur de retour.

.PARAMETER FunctionName
    Le nom de la fonction.
    Par dÃ©faut, c'est le nom de la fonction appelante.

.PARAMETER ReturnValue
    La valeur de retour de la fonction.

.PARAMETER DecreaseDepth
    Indique si la profondeur doit Ãªtre diminuÃ©e avant la trace.
    Par dÃ©faut, c'est $true.

.EXAMPLE
    Trace-RoadmapFunctionExit
    Trace la sortie de la fonction appelante.

.EXAMPLE
    Trace-RoadmapFunctionExit -FunctionName "Ma-Fonction" -ReturnValue $result
    Trace la sortie de la fonction "Ma-Fonction" avec la valeur de retour spÃ©cifiÃ©e.

.OUTPUTS
    [void]

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-22
#>
function Trace-RoadmapFunctionExit {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$FunctionName = (Get-PSCallStack)[1].Command,

        [Parameter(Mandatory = $false)]
        [object]$ReturnValue,

        [Parameter(Mandatory = $false)]
        [switch]$DecreaseDepth = $true
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
    Trace-FunctionExit -FunctionName $FunctionName -ReturnValue $ReturnValue -DecreaseDepth:$DecreaseDepth
}
