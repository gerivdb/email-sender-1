# Définir la fonction directement dans le script de test
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

        try {
            # Pour les objets PowerShell standard, utiliser JSON
            if ($InputObject -is [System.Collections.IDictionary]) {
                # Cloner un dictionnaire
                $clone = @{}
                foreach ($key in $InputObject.Keys) {
                    $clone[$key] = Invoke-DeepClone -InputObject $InputObject[$key] -Depth $Depth
                }
                return $clone
            } elseif ($InputObject -is [System.Collections.IList]) {
                # Cloner une liste
                if ($InputObject -is [System.Collections.ArrayList]) {
                    # Pour ArrayList, créer un nouveau ArrayList
                    $clone = New-Object System.Collections.ArrayList

                    # Cloner chaque élément
                    foreach ($item in $InputObject) {
                        $clonedItem = Invoke-DeepClone -InputObject $item -Depth $Depth
                        [void]$clone.Add($clonedItem)
                    }
                    return $clone
                } elseif ($InputObject -is [array]) {
                    # Pour les tableaux
                    $clone = @()
                    foreach ($item in $InputObject) {
                        $clone += Invoke-DeepClone -InputObject $item -Depth $Depth
                    }
                    return $clone
                } else {
                    # Pour les autres collections, utiliser JSON
                    $json = ConvertTo-Json -InputObject $InputObject -Depth $Depth -Compress
                    return ConvertFrom-Json -InputObject $json -Depth $Depth
                }
            } else {
                # Pour les autres objets, utiliser JSON
                $json = ConvertTo-Json -InputObject $InputObject -Depth $Depth -Compress
                return ConvertFrom-Json -InputObject $json -Depth $Depth
            }
        } catch {
            Write-Verbose "Erreur lors du clonage: $_"
            throw "Erreur lors du clonage profond: $_"
        }
    }
}

# Test 1: Clonage d'un objet simple
Write-Host "Test 1: Clonage d'un objet simple" -ForegroundColor Cyan
$original = [PSCustomObject]@{
    Name  = "Test"
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

# Test 4: Clonage d'un ArrayList
Write-Host "`nTest 4: Clonage d'un ArrayList" -ForegroundColor Cyan
$original = [System.Collections.ArrayList]::new()
[void]$original.Add("Item1")
[void]$original.Add("Item2")
$clone = Invoke-DeepClone -InputObject $original
Write-Host "Original: $($original -join ', ')"
Write-Host "Clone: $($clone -join ', ')"

# Modifier le clone
try {
    [void]$clone.Add("Item3")
    Write-Host "Ajout d'un élément au clone réussi."
    Write-Host "Après modification du clone:"
    Write-Host "Original: $($original -join ', ')"
    Write-Host "Clone: $($clone -join ', ')"
} catch {
    Write-Host "Erreur lors de l'ajout d'un élément au clone: $_" -ForegroundColor Red
}

Write-Host "`nTous les tests sont terminés." -ForegroundColor Green
