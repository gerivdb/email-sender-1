#Requires -Version 5.1
<#
.SYNOPSIS
    Crée un mock pour une fonction ou une commande.
.DESCRIPTION
    Crée un mock pour une fonction ou une commande avec une implémentation personnalisée.
    Cette fonction est un wrapper autour de la fonction Mock de Pester avec des fonctionnalités
    supplémentaires.
.PARAMETER CommandName
    Nom de la commande à mocker.
.PARAMETER MockScript
    Script à exécuter lorsque la commande mockée est appelée.
.PARAMETER ParameterFilter
    Filtre pour déterminer quand le mock doit être appliqué.
.PARAMETER ModuleName
    Nom du module contenant la commande à mocker.
.PARAMETER Verifiable
    Indique si le mock doit être vérifiable.
.EXAMPLE
    New-TestMock -CommandName "Get-Content" -MockScript { return "Contenu mocké" }
.EXAMPLE
    New-TestMock -CommandName "Invoke-RestMethod" -ParameterFilter { $Uri -like "*api/users*" } -MockScript { return @{ id = 1; name = "Test" } }
.NOTES
    Cette fonction nécessite Pester 5.0 ou supérieur.
#>
function New-TestMock {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandName,

        [Parameter(Mandatory = $true)]
        [scriptblock]$MockScript,

        [Parameter(Mandatory = $false)]
        [scriptblock]$ParameterFilter,

        [Parameter(Mandatory = $false)]
        [string]$ModuleName,

        [Parameter(Mandatory = $false)]
        [switch]$Verifiable
    )

    # Vérifier que Pester est disponible
    if (-not (Get-Module -Name Pester -ListAvailable)) {
        throw "Le module Pester est requis pour utiliser cette fonction."
    }

    # Construire les paramètres pour la fonction Mock
    $mockParams = @{
        CommandName = $CommandName
        MockWith = $MockScript
    }

    if ($ParameterFilter) {
        $mockParams.ParameterFilter = $ParameterFilter
    }

    if ($ModuleName) {
        $mockParams.ModuleName = $ModuleName
    }

    if ($Verifiable) {
        $mockParams.Verifiable = $true
    }

    # Créer le mock
    try {
        Mock @mockParams
        Write-Verbose "Mock créé pour la commande '$CommandName'."
        
        # Retourner les informations sur le mock
        return @{
            CommandName = $CommandName
            MockScript = $MockScript
            ParameterFilter = $ParameterFilter
            ModuleName = $ModuleName
            Verifiable = $Verifiable
        }
    }
    catch {
        Write-Error "Erreur lors de la création du mock pour la commande '$CommandName' : $_"
        return $null
    }
}
