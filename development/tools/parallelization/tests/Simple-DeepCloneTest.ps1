# Importer le script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\DeepCloneExtensions.ps1"
. $scriptPath

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

Write-Host "`nTest 4: Clonage d'un ArrayList" -ForegroundColor Cyan
$original = [System.Collections.ArrayList]::new()
[void]$original.Add("Item1")
[void]$original.Add("Item2")
$clone = Invoke-DeepClone -InputObject $original
Write-Host "Original: $($original -join ', ')"
Write-Host "Clone: $($clone -join ', ')"

# Modifier le clone
[void]$clone.Add("Item3")
Write-Host "Après modification du clone:"
Write-Host "Original: $($original -join ', ')"
Write-Host "Clone: $($clone -join ', ')"

Write-Host "`nTous les tests sont terminés." -ForegroundColor Green
