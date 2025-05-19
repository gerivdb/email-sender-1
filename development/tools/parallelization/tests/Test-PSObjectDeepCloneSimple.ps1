# Définir les fonctions directement dans le script de test
function Invoke-DeepClone {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object]$InputObject,
        
        [Parameter(Mandatory = $false)]
        [int]$Depth = 100
    )

    process {
        if ($null -eq $InputObject) {
            return $null
        }

        # Traitement spécial pour les dictionnaires
        if ($InputObject -is [System.Collections.IDictionary]) {
            $clone = @{}
            foreach ($key in $InputObject.Keys) {
                $clone[$key] = Invoke-DeepClone -InputObject $InputObject[$key] -Depth $Depth
            }
            return $clone
        }
        # Traitement spécial pour les tableaux
        elseif ($InputObject -is [array]) {
            $clone = @()
            foreach ($item in $InputObject) {
                $clone += Invoke-DeepClone -InputObject $item -Depth $Depth
            }
            return $clone
        }
        # Traitement spécial pour ArrayList
        elseif ($InputObject -is [System.Collections.ArrayList]) {
            $clone = New-Object System.Collections.ArrayList
            foreach ($item in $InputObject) {
                [void]$clone.Add((Invoke-DeepClone -InputObject $item -Depth $Depth))
            }
            return $clone
        }
        # Traitement spécial pour les objets PSObject
        elseif ($InputObject -is [PSObject] -or $InputObject -is [PSCustomObject]) {
            return Invoke-PSObjectDeepClone -InputObject $InputObject -Depth $Depth
        }
        # Pour les autres objets, utiliser JSON
        else {
            try {
                $json = ConvertTo-Json -InputObject $InputObject -Depth $Depth -Compress
                return ConvertFrom-Json -InputObject $json -Depth $Depth
            }
            catch {
                Write-Verbose "Erreur lors du clonage via JSON: $_"
                throw "Erreur lors du clonage profond: $_"
            }
        }
    }
}

function Invoke-PSObjectDeepClone {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]$InputObject,
        
        [Parameter(Mandatory = $false)]
        [int]$Depth = 100
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
            $clonedValue = Invoke-DeepClone -InputObject $propertyValue -Depth $Depth
            
            # Ajouter la propriété au clone
            $clone | Add-Member -MemberType NoteProperty -Name $propertyName -Value $clonedValue
        }
        
        return $clone
    }
}

# Test 1: Clonage d'un objet PSObject simple
Write-Host "Test 1: Clonage d'un objet PSObject simple" -ForegroundColor Cyan
$original = [PSCustomObject]@{
    Name = "Test"
    Value = 42
}

$clone = Invoke-PSObjectDeepClone -InputObject $original
Write-Host "Original: $($original | ConvertTo-Json)"
Write-Host "Clone: $($clone | ConvertTo-Json)"

# Modifier le clone
$clone.Name = "Modified"
Write-Host "Après modification du clone:"
Write-Host "Original: $($original | ConvertTo-Json)"
Write-Host "Clone: $($clone | ConvertTo-Json)"

# Test 2: Clonage d'un objet PSObject avec des objets imbriqués
Write-Host "`nTest 2: Clonage d'un objet PSObject avec des objets imbriqués" -ForegroundColor Cyan
$original = [PSCustomObject]@{
    Name = "Parent"
    Child = [PSCustomObject]@{
        Name = "Child"
        Value = 42
    }
    Children = @(
        [PSCustomObject]@{ Name = "Child1"; Value = 1 },
        [PSCustomObject]@{ Name = "Child2"; Value = 2 }
    )
}

$clone = Invoke-PSObjectDeepClone -InputObject $original
Write-Host "Original: $($original | ConvertTo-Json -Depth 3)"
Write-Host "Clone: $($clone | ConvertTo-Json -Depth 3)"

# Modifier le clone
$clone.Child.Name = "ModifiedChild"
$clone.Children[0].Name = "ModifiedChild1"
Write-Host "Après modification du clone:"
Write-Host "Original: $($original | ConvertTo-Json -Depth 3)"
Write-Host "Clone: $($clone | ConvertTo-Json -Depth 3)"

Write-Host "`nTous les tests sont terminés." -ForegroundColor Green
