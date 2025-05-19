<#
.SYNOPSIS
    Fonctions de clonage profond pour les tests.

.DESCRIPTION
    Ce script fournit des fonctions de clonage profond (deep clone) pour les tests.
    Ces fonctions sont simplifiées et ne sont pas destinées à être utilisées en production.

.NOTES
    Version: 1.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-26
#>

<#
.SYNOPSIS
    Effectue une copie profonde d'un objet.

.DESCRIPTION
    Cette fonction crée une copie profonde (deep clone) d'un objet en utilisant
    différentes stratégies selon le type d'objet.

.PARAMETER InputObject
    Objet à cloner.

.EXAMPLE
    $original = [PSCustomObject]@{ Name = "Test"; Value = 42 }
    $clone = Test-DeepClone -InputObject $original
    $clone.Name = "Modified"
    # $original.Name reste "Test"
#>
function Test-DeepClone {
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
                $clone[$key] = Test-DeepClone -InputObject $InputObject[$key]
            }
            return $clone
        }
        # Traitement spécial pour les tableaux
        elseif ($InputObject -is [array]) {
            $clone = @()
            foreach ($item in $InputObject) {
                $clone += Test-DeepClone -InputObject $item
            }
            return $clone
        }
        # Traitement spécial pour ArrayList
        elseif ($InputObject -is [System.Collections.ArrayList]) {
            $clone = New-Object System.Collections.ArrayList
            foreach ($item in $InputObject) {
                [void]$clone.Add((Test-DeepClone -InputObject $item))
            }
            return $clone
        }
        # Traitement spécial pour les objets PSObject
        elseif ($InputObject -is [PSObject] -or $InputObject -is [PSCustomObject]) {
            return Test-PSObjectDeepClone -InputObject $InputObject
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
    en utilisant une approche spécifique pour ce type d'objet.

.PARAMETER InputObject
    Objet PowerShell à cloner.

.EXAMPLE
    $original = [PSCustomObject]@{
        Name = "Test"
        NestedObject = [PSCustomObject]@{ Property = "Value" }
    }
    $clone = Test-PSObjectDeepClone -InputObject $original
    $clone.NestedObject.Property = "Modified"
    # $original.NestedObject.Property reste "Value"
#>
function Test-PSObjectDeepClone {
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
            $clonedValue = Test-DeepClone -InputObject $propertyValue

            # Ajouter la propriété au clone
            $clone | Add-Member -MemberType NoteProperty -Name $propertyName -Value $clonedValue
        }

        return $clone
    }
}
