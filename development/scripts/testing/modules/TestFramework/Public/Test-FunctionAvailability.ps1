#Requires -Version 5.1
<#
.SYNOPSIS
    Vérifie la disponibilité d'une fonction ou d'une commande.
.DESCRIPTION
    Vérifie si une fonction ou une commande est disponible dans la session PowerShell actuelle.
    Cette fonction est utile pour les tests unitaires pour vérifier que les fonctions
    nécessaires sont disponibles avant d'exécuter les tests.
.PARAMETER FunctionName
    Nom de la fonction ou de la commande à vérifier.
.PARAMETER ModuleName
    Nom du module contenant la fonction ou la commande.
.PARAMETER ThrowOnError
    Indique si une exception doit être levée si la fonction n'est pas disponible.
.EXAMPLE
    Test-FunctionAvailability -FunctionName "Get-Content"
.EXAMPLE
    Test-FunctionAvailability -FunctionName "Get-AzureRmVM" -ModuleName "AzureRM.Compute" -ThrowOnError
.NOTES
    Cette fonction est utile pour les tests unitaires pour vérifier que les fonctions
    nécessaires sont disponibles avant d'exécuter les tests.
#>
function Test-FunctionAvailability {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string[]]$FunctionName,

        [Parameter(Mandatory = $false)]
        [string]$ModuleName,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnError
    )

    $results = @{}

    foreach ($function in $FunctionName) {
        $available = $false
        $error = $null

        try {
            if ($ModuleName) {
                # Vérifier si le module est disponible
                $moduleAvailable = Get-Module -Name $ModuleName -ListAvailable
                if (-not $moduleAvailable) {
                    $error = "Le module '$ModuleName' n'est pas disponible."
                }
                else {
                    # Vérifier si la fonction est disponible dans le module
                    $functionAvailable = Get-Command -Name $function -Module $ModuleName -ErrorAction SilentlyContinue
                    if ($functionAvailable) {
                        $available = $true
                    }
                    else {
                        $error = "La fonction '$function' n'est pas disponible dans le module '$ModuleName'."
                    }
                }
            }
            else {
                # Vérifier si la fonction est disponible dans la session
                $functionAvailable = Get-Command -Name $function -ErrorAction SilentlyContinue
                if ($functionAvailable) {
                    $available = $true
                }
                else {
                    $error = "La fonction '$function' n'est pas disponible dans la session."
                }
            }
        }
        catch {
            $error = "Erreur lors de la vérification de la disponibilité de la fonction '$function' : $_"
        }

        $results[$function] = @{
            Available = $available
            Error = $error
        }

        if (-not $available -and $ThrowOnError) {
            throw $error
        }
    }

    return $results
}
