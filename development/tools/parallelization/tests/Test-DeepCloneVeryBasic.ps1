# Définir la fonction directement dans le script de test
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
        # Pour les autres objets, utiliser JSON
        else {
            $json = ConvertTo-Json -InputObject $InputObject -Depth 100 -Compress
            return ConvertFrom-Json -InputObject $json -Depth 100
        }
    }
}

# Test 1: Clonage d'un objet simple
Write-Host "Test 1: Clonage d'un objet simple" -ForegroundColor Cyan
$original = [PSCustomObject]@{
    Name = "Test"
    Value = 42
}

$clone = Invoke-DeepClone -InputObject $original
Write-Host "Original: $($original | ConvertTo-Json)"
Write-Host "Clone: $($clone | ConvertTo-Json)"

# Modifier le clone
$clone.Name = "Modified"
Write-Host "Après modification du clone:"
Write-Host "Original: $($original | ConvertTo-Json)"
Write-Host "Clone: $($clone | ConvertTo-Json)"

# Test 2: Clonage d'un tableau
Write-Host "`nTest 2: Clonage d'un tableau" -ForegroundColor Cyan
$original = @(1, 2, 3, 4, 5)
$clone = Invoke-DeepClone -InputObject $original
Write-Host "Original: $($original -join ', ')"
Write-Host "Clone: $($clone -join ', ')"

# Modifier le clone
$clone[0] = 99
Write-Host "Après modification du clone:"
Write-Host "Original: $($original -join ', ')"
Write-Host "Clone: $($clone -join ', ')"

# Test 3: Clonage d'un dictionnaire
Write-Host "`nTest 3: Clonage d'un dictionnaire" -ForegroundColor Cyan
$original = @{
    "Key1" = "Value1"
    "Key2" = @{
        "NestedKey" = "NestedValue"
    }
    "Key3" = @(1, 2, 3)
}
$clone = Invoke-DeepClone -InputObject $original
Write-Host "Original: $($original | ConvertTo-Json -Depth 3)"
Write-Host "Clone: $($clone | ConvertTo-Json -Depth 3)"

# Modifier le clone
$clone["Key1"] = "Modified"
$clone["Key2"]["NestedKey"] = "ModifiedNested"
$clone["Key3"][0] = 99
Write-Host "Après modification du clone:"
Write-Host "Original: $($original | ConvertTo-Json -Depth 3)"
Write-Host "Clone: $($clone | ConvertTo-Json -Depth 3)"

Write-Host "`nTous les tests sont terminés." -ForegroundColor Green
