<#
.SYNOPSIS
    Valide une valeur selon une fonction de validation personnalisÃ©e.

.DESCRIPTION
    La fonction Test-Custom valide une valeur selon une fonction de validation personnalisÃ©e.
    Elle permet de dÃ©finir des rÃ¨gles de validation complexes et peut Ãªtre utilisÃ©e pour
    valider les entrÃ©es des fonctions du module RoadmapParser.

.PARAMETER Value
    La valeur Ã  valider.

.PARAMETER ValidationFunction
    La fonction de validation personnalisÃ©e Ã  utiliser.
    Cette fonction doit prendre un paramÃ¨tre (la valeur Ã  valider) et retourner un boolÃ©en.

.PARAMETER ValidationScript
    Le script de validation personnalisÃ© Ã  utiliser.
    Ce script doit prendre un paramÃ¨tre (la valeur Ã  valider) et retourner un boolÃ©en.

.PARAMETER ErrorMessage
    Le message d'erreur Ã  afficher en cas d'Ã©chec de la validation.
    Si non spÃ©cifiÃ©, un message par dÃ©faut sera utilisÃ©.

.PARAMETER ThrowOnFailure
    Indique si une exception doit Ãªtre levÃ©e en cas d'Ã©chec de la validation.

.EXAMPLE
    Test-Custom -Value 42 -ValidationFunction { param($val) $val -gt 0 -and $val -lt 100 }
    VÃ©rifie que la valeur 42 est positive et infÃ©rieure Ã  100.

.EXAMPLE
    Test-Custom -Value "Hello" -ValidationScript { param($val) $val.Length -gt 3 } -ThrowOnFailure
    VÃ©rifie que la chaÃ®ne "Hello" a une longueur supÃ©rieure Ã  3 caractÃ¨res, et lÃ¨ve une exception si ce n'est pas le cas.

.OUTPUTS
    [bool] Indique si la validation a rÃ©ussi.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-20
#>
function Test-Custom {
    [CmdletBinding(DefaultParameterSetName = "Function")]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [AllowNull()]
        $Value,

        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = "Function")]
        [scriptblock]$ValidationFunction,

        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = "Script")]
        [scriptblock]$ValidationScript,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )

    # Initialiser le rÃ©sultat de la validation
    $isValid = $false

    # Effectuer la validation selon le type de validation
    try {
        if ($PSCmdlet.ParameterSetName -eq "Function") {
            $isValid = & $ValidationFunction $Value
        } else {
            $isValid = & $ValidationScript $Value
        }
    } catch {
        $isValid = $false
        if ([string]::IsNullOrEmpty($ErrorMessage)) {
            $ErrorMessage = "Erreur lors de l'exÃ©cution de la validation personnalisÃ©e : $_"
        }
    }

    # GÃ©rer l'Ã©chec de la validation
    if (-not $isValid) {
        if ([string]::IsNullOrEmpty($ErrorMessage)) {
            $ErrorMessage = "La valeur ne correspond pas aux critÃ¨res de validation personnalisÃ©s."
        }

        if ($ThrowOnFailure) {
            throw $ErrorMessage
        } else {
            Write-Warning $ErrorMessage
        }
    }

    return $isValid
}
