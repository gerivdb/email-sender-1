# Importer le script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\DeepCloneExtensions.ps1"
. $scriptPath

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

# Test 3: Clonage d'un objet PSObject avec des collections
Write-Host "`nTest 3: Clonage d'un objet PSObject avec des collections" -ForegroundColor Cyan
$original = [PSCustomObject]@{
    Name = "Parent"
    Array = @(1, 2, 3)
    Dictionary = @{
        "Key1" = "Value1"
        "Key2" = "Value2"
    }
    ArrayList = {
        $list = [System.Collections.ArrayList]::new()
        [void]$list.Add("Item1")
        [void]$list.Add("Item2")
        return $list
    }.Invoke()
}

$clone = Invoke-PSObjectDeepClone -InputObject $original
Write-Host "Original: $($original | ConvertTo-Json -Depth 3)"
Write-Host "Clone: $($clone | ConvertTo-Json -Depth 3)"

# Modifier le clone
$clone.Array[0] = 99
$clone.Dictionary["Key1"] = "Modified"
[void]$clone.ArrayList.Add("Item3")
Write-Host "Après modification du clone:"
Write-Host "Original: $($original | ConvertTo-Json -Depth 3)"
Write-Host "Clone: $($clone | ConvertTo-Json -Depth 3)"

Write-Host "`nTous les tests sont terminés." -ForegroundColor Green
