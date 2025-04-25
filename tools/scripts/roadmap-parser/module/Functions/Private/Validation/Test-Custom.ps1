<#
.SYNOPSIS
    Valide une valeur selon une fonction de validation personnalisée.

.DESCRIPTION
    La fonction Test-Custom valide une valeur selon une fonction de validation personnalisée.
    Elle permet de définir des règles de validation complexes et peut être utilisée pour
    valider les entrées des fonctions du module RoadmapParser.

.PARAMETER Value
    La valeur à valider.

.PARAMETER ValidationFunction
    La fonction de validation personnalisée à utiliser.
    Cette fonction doit prendre un paramètre (la valeur à valider) et retourner un booléen.

.PARAMETER ValidationScript
    Le script de validation personnalisé à utiliser.
    Ce script doit prendre un paramètre (la valeur à valider) et retourner un booléen.

.PARAMETER ErrorMessage
    Le message d'erreur à afficher en cas d'échec de la validation.
    Si non spécifié, un message par défaut sera utilisé.

.PARAMETER ThrowOnFailure
    Indique si une exception doit être levée en cas d'échec de la validation.

.EXAMPLE
    Test-Custom -Value 42 -ValidationFunction { param($val) $val -gt 0 -and $val -lt 100 }
    Vérifie que la valeur 42 est positive et inférieure à 100.

.EXAMPLE
    Test-Custom -Value "Hello" -ValidationScript { param($val) $val.Length -gt 3 } -ThrowOnFailure
    Vérifie que la chaîne "Hello" a une longueur supérieure à 3 caractères, et lève une exception si ce n'est pas le cas.

.OUTPUTS
    [bool] Indique si la validation a réussi.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-20
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

    # Initialiser le résultat de la validation
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
            $ErrorMessage = "Erreur lors de l'exécution de la validation personnalisée : $_"
        }
    }

    # Gérer l'échec de la validation
    if (-not $isValid) {
        if ([string]::IsNullOrEmpty($ErrorMessage)) {
            $ErrorMessage = "La valeur ne correspond pas aux critères de validation personnalisés."
        }

        if ($ThrowOnFailure) {
            throw $ErrorMessage
        } else {
            Write-Warning $ErrorMessage
        }
    }

    return $isValid
}
