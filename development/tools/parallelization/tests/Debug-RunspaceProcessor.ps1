# Script de débogage pour Invoke-RunspaceProcessor
# Ce script teste les modifications apportées à la fonction Invoke-RunspaceProcessor
# pour identifier les problèmes liés aux avertissements "Runspace invalide détecté"

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force -Verbose

# Initialiser le module
Initialize-UnifiedParallel -Verbose

Write-Host "Débogage de Invoke-RunspaceProcessor" -ForegroundColor Cyan

# Fonction pour créer un objet de test avec des propriétés spécifiques
function New-TestObject {
    param (
        [int]$Id,
        [bool]$IncludePowerShell = $false,
        [bool]$IncludeHandle = $false,
        [bool]$IncludeValue = $true,
        [bool]$IncludeItem = $true
    )
    
    $props = @{}
    
    if ($IncludePowerShell) {
        $props['PowerShell'] = [powershell]::Create()
    }
    
    if ($IncludeHandle) {
        $props['Handle'] = New-Object System.Management.Automation.PSDataCollection[PSObject]
    }
    
    if ($IncludeValue) {
        $props['Value'] = "Test $Id"
    }
    
    if ($IncludeItem) {
        $props['Item'] = $Id
    }
    
    return [PSCustomObject]$props
}

# Test 1: Objets avec différentes combinaisons de propriétés
Write-Host "`nTest 1: Objets avec différentes combinaisons de propriétés" -ForegroundColor Yellow

# Cas 1: Objet avec Value et Item seulement
$testObj1 = New-TestObject -Id 1 -IncludePowerShell $false -IncludeHandle $false -IncludeValue $true -IncludeItem $true
Write-Host "Cas 1: Objet avec Value et Item seulement" -ForegroundColor White
Write-Host "Propriétés: $($testObj1 | Format-List | Out-String)"
$result1 = Invoke-RunspaceProcessor -CompletedRunspaces $testObj1 -NoProgress -Verbose
Write-Host "Résultat: $($result1.Results.Count) résultats"

# Cas 2: Objet avec PowerShell null et Handle null
$testObj2 = New-TestObject -Id 2 -IncludePowerShell $true -IncludeHandle $true -IncludeValue $true -IncludeItem $true
$testObj2.PowerShell = $null
$testObj2.Handle = $null
Write-Host "`nCas 2: Objet avec PowerShell null et Handle null" -ForegroundColor White
Write-Host "Propriétés: $($testObj2 | Format-List | Out-String)"
$result2 = Invoke-RunspaceProcessor -CompletedRunspaces $testObj2 -NoProgress -Verbose
Write-Host "Résultat: $($result2.Results.Count) résultats"

# Cas 3: Objet avec PowerShell mais sans Handle
$testObj3 = New-TestObject -Id 3 -IncludePowerShell $true -IncludeHandle $false -IncludeValue $true -IncludeItem $true
Write-Host "`nCas 3: Objet avec PowerShell mais sans Handle" -ForegroundColor White
Write-Host "Propriétés: $($testObj3 | Format-List | Out-String)"
$result3 = Invoke-RunspaceProcessor -CompletedRunspaces $testObj3 -NoProgress -Verbose
Write-Host "Résultat: $($result3.Results.Count) résultats"

# Cas 4: Objet sans PowerShell mais avec Handle
$testObj4 = New-TestObject -Id 4 -IncludePowerShell $false -IncludeHandle $true -IncludeValue $true -IncludeItem $true
Write-Host "`nCas 4: Objet sans PowerShell mais avec Handle" -ForegroundColor White
Write-Host "Propriétés: $($testObj4 | Format-List | Out-String)"
$result4 = Invoke-RunspaceProcessor -CompletedRunspaces $testObj4 -NoProgress -Verbose
Write-Host "Résultat: $($result4.Results.Count) résultats"

# Cas 5: Objet sans Value ni Item
$testObj5 = New-TestObject -Id 5 -IncludePowerShell $false -IncludeHandle $false -IncludeValue $false -IncludeItem $false
Write-Host "`nCas 5: Objet sans Value ni Item" -ForegroundColor White
Write-Host "Propriétés: $($testObj5 | Format-List | Out-String)"
$result5 = Invoke-RunspaceProcessor -CompletedRunspaces $testObj5 -NoProgress -Verbose
Write-Host "Résultat: $($result5.Results.Count) résultats"

# Test 2: Collections mixtes
Write-Host "`nTest 2: Collections mixtes" -ForegroundColor Yellow

# Créer une collection mixte
$mixedList = [System.Collections.Generic.List[object]]::new()
$mixedList.Add((New-TestObject -Id 1 -IncludePowerShell $false -IncludeHandle $false -IncludeValue $true -IncludeItem $true))
$mixedList.Add((New-TestObject -Id 2 -IncludePowerShell $true -IncludeHandle $true -IncludeValue $true -IncludeItem $true))
$mixedList.Add((New-TestObject -Id 3 -IncludePowerShell $false -IncludeHandle $true -IncludeValue $true -IncludeItem $true))
$mixedList.Add((New-TestObject -Id 4 -IncludePowerShell $true -IncludeHandle $false -IncludeValue $true -IncludeItem $true))
$mixedList.Add((New-TestObject -Id 5 -IncludePowerShell $false -IncludeHandle $false -IncludeValue $false -IncludeItem $false))
$mixedList.Add($null)  # Ajouter un élément null

Write-Host "Collection mixte avec 6 éléments (dont un null)" -ForegroundColor White
$result6 = Invoke-RunspaceProcessor -CompletedRunspaces $mixedList -NoProgress -Verbose
Write-Host "Résultat: $($result6.Results.Count) résultats"

# Test 3: Vérification des valeurs de retour
Write-Host "`nTest 3: Vérification des valeurs de retour" -ForegroundColor Yellow

# Créer une collection d'objets valides
$validList = [System.Collections.Generic.List[object]]::new()
for ($i = 1; $i -le 5; $i++) {
    $validList.Add((New-TestObject -Id $i -IncludePowerShell $false -IncludeHandle $false -IncludeValue $true -IncludeItem $true))
}

Write-Host "Collection de 5 objets valides" -ForegroundColor White
$result7 = Invoke-RunspaceProcessor -CompletedRunspaces $validList -NoProgress -Verbose
Write-Host "Résultat: $($result7.Results.Count) résultats"
Write-Host "Valeurs de retour:"
foreach ($item in $result7.Results) {
    Write-Host "  - Value: $($item.Value), Success: $($item.Success), Item: $($item.Item)"
}

Write-Host "`nDébogage terminé." -ForegroundColor Green
