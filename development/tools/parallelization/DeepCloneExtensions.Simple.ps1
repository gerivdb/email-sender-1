<#
.SYNOPSIS
    Méthodes d'extension pour la copie profonde d'objets.

.DESCRIPTION
    Ce script fournit des méthodes d'extension pour effectuer des copies profondes (deep clone)
    de différents types d'objets, y compris les types sérialisables et les objets PowerShell.

.NOTES
    Version: 1.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-25
#>

<#
.SYNOPSIS
    Effectue une copie profonde d'un objet.

.DESCRIPTION
    Cette fonction crée une copie profonde (deep clone) d'un objet en utilisant
    différentes stratégies selon le type d'objet. Tous les objets référencés sont également clonés.

.PARAMETER InputObject
    Objet à cloner.

.EXAMPLE
    $original = [PSCustomObject]@{ Name = "Test"; Value = 42 }
    $clone = Invoke-DeepClone -InputObject $original
    $clone.Name = "Modified"
    # $original.Name reste "Test"

.NOTES
    Cette fonction utilise principalement la sérialisation JSON pour les objets PowerShell
    et des approches spécifiques pour les collections.
#>
function Invoke-DeepClone {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object]$InputObject
    )

    process {
        if ($null -eq $InputObject) {
            return $null
        }

        # Traitement spécial pour les dictionnaires
        if ($InputObject -is [System.Collections.IDictionary]) {
            $clone = @{}
            foreach ($key in $InputObject.Keys) {
                $clone[$key] = Invoke-DeepClone -InputObject $InputObject[$key]
            }
            return $clone
        }
        # Traitement spécial pour les tableaux
        elseif ($InputObject -is [array]) {
            $clone = @()
            foreach ($item in $InputObject) {
                $clone += Invoke-DeepClone -InputObject $item
            }
            return $clone
        }
        # Traitement spécial pour ArrayList
        elseif ($InputObject -is [System.Collections.ArrayList]) {
            $clone = New-Object System.Collections.ArrayList
            foreach ($item in $InputObject) {
                [void]$clone.Add((Invoke-DeepClone -InputObject $item))
            }
            return $clone
        }
        # Traitement spécial pour les objets PSObject
        elseif ($InputObject -is [PSObject] -or $InputObject -is [PSCustomObject]) {
            return Invoke-PSObjectDeepClone -InputObject $InputObject
        }
        # Pour les autres objets, utiliser JSON
        else {
            try {
                $json = ConvertTo-Json -InputObject $InputObject -Depth 100 -Compress
                return ConvertFrom-Json -InputObject $json -Depth 100
            } catch {
                Write-Verbose "Erreur lors du clonage via JSON: $_"
                throw "Erreur lors du clonage profond: $_"
            }
        }
    }
}

<#
.SYNOPSIS
    Effectue une copie profonde d'un objet PowerShell (PSObject).

.DESCRIPTION
    Cette fonction crée une copie profonde (deep clone) d'un objet PowerShell (PSObject)
    en utilisant une approche spécifique pour ce type d'objet. Tous les objets référencés
    sont également clonés.

.PARAMETER InputObject
    Objet PowerShell à cloner.

.EXAMPLE
    $original = [PSCustomObject]@{
        Name = "Test"
        NestedObject = [PSCustomObject]@{ Property = "Value" }
    }
    $clone = Invoke-PSObjectDeepClone -InputObject $original
    $clone.NestedObject.Property = "Modified"
    # $original.NestedObject.Property reste "Value"

.NOTES
    Cette fonction est spécialement optimisée pour les objets PowerShell (PSObject).
#>
function Invoke-PSObjectDeepClone {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]$InputObject
    )

    process {
        if ($null -eq $InputObject) {
            return $null
        }

        # Pour les objets PSObject, créer un nouvel objet et copier les propriétés
        $clone = [PSCustomObject]@{}

        # Obtenir toutes les propriétés de l'objet
        $properties = $InputObject.PSObject.Properties

        # Copier chaque propriété
        foreach ($property in $properties) {
            $propertyName = $property.Name
            $propertyValue = $property.Value

            # Cloner récursivement la valeur de la propriété
            $clonedValue = Invoke-DeepClone -InputObject $propertyValue

            # Ajouter la propriété au clone
            $clone | Add-Member -MemberType NoteProperty -Name $propertyName -Value $clonedValue
        }

        return $clone
    }
}

# Exporter les fonctions si le script est importé comme module
if ($MyInvocation.Line -match 'Import-Module') {
    Export-ModuleMember -Function Invoke-DeepClone, Invoke-PSObjectDeepClone
}
