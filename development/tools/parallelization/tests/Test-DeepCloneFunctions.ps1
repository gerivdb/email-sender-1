# Importer le script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\DeepCloneExtensions.ps1"
Write-Host "Chemin du script: $scriptPath"
Write-Host "Le fichier existe: $(Test-Path -Path $scriptPath)"

# Importer le script
. $scriptPath

# Vérifier que les fonctions sont disponibles
$invokeDeepCloneExists = Get-Command -Name Invoke-DeepClone -ErrorAction SilentlyContinue
$invokePSObjectDeepCloneExists = Get-Command -Name Invoke-PSObjectDeepClone -ErrorAction SilentlyContinue

Write-Host "Invoke-DeepClone existe: $($null -ne $invokeDeepCloneExists)"
Write-Host "Invoke-PSObjectDeepClone existe: $($null -ne $invokePSObjectDeepCloneExists)"

# Tester les fonctions si elles existent
if ($invokeDeepCloneExists) {
    Write-Host "`nTest de Invoke-DeepClone:" -ForegroundColor Cyan
    
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
    
    # Vérifier que c'est une copie profonde
    $testPassed = $original.Name -eq "Test" -and $clone.Name -eq "Modified"
    Write-Host "Test réussi: $testPassed" -ForegroundColor $(if ($testPassed) { "Green" } else { "Red" })
}

if ($invokePSObjectDeepCloneExists) {
    Write-Host "`nTest de Invoke-PSObjectDeepClone:" -ForegroundColor Cyan
    
    # Test 1: Clonage d'un objet PSObject avec des propriétés imbriquées
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
    
    # Vérifier que c'est une copie profonde
    $testPassed = $original.Child.Name -eq "Child" -and $clone.Child.Name -eq "ModifiedChild"
    Write-Host "Test réussi: $testPassed" -ForegroundColor $(if ($testPassed) { "Green" } else { "Red" })
}
