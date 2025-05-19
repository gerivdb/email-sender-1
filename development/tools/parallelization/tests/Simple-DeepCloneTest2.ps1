# Importer le script à tester
. ..\DeepCloneExtensions.ps1

# Test 1: Clonage d'un objet simple
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

# Test 2: Clonage d'un objet PSObject avec des propriétés imbriquées
$original = [PSCustomObject]@{
    Name = "Parent"
    Child = [PSCustomObject]@{
        Name = "Child"
        Value = 42
    }
}

$clone = Invoke-PSObjectDeepClone -InputObject $original
Write-Host "Original: $($original | ConvertTo-Json -Depth 3)"
Write-Host "Clone: $($clone | ConvertTo-Json -Depth 3)"

# Modifier le clone
$clone.Child.Name = "ModifiedChild"
Write-Host "Après modification du clone:"
Write-Host "Original: $($original | ConvertTo-Json -Depth 3)"
Write-Host "Clone: $($clone | ConvertTo-Json -Depth 3)"
