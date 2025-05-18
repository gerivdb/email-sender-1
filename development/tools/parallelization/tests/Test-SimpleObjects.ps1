# Test simple pour Invoke-RunspaceProcessor avec des objets simples
# Ce script teste les modifications apportées à la fonction Invoke-RunspaceProcessor
# pour gérer correctement les objets simples sans générer d'avertissements

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Initialiser le module
Initialize-UnifiedParallel

Write-Host "Test de Invoke-RunspaceProcessor avec des objets simples" -ForegroundColor Cyan

# Créer des objets de test simples
$testObject1 = [PSCustomObject]@{
    Value = "Test 1"
    Item = 1
}

$testObject2 = [PSCustomObject]@{
    Value = "Test 2"
    Item = 2
}

$testObject3 = [PSCustomObject]@{
    Value = "Test 3"
    Item = 3
}

# Test avec List<object>
Write-Host "`nTest avec List<object>" -ForegroundColor Yellow
$list = [System.Collections.Generic.List[object]]::new()
$list.Add($testObject1)
$list.Add($testObject2)
$list.Add($testObject3)
Write-Host "Type de list: $($list.GetType().FullName)"
$results = Invoke-RunspaceProcessor -CompletedRunspaces $list -NoProgress -Debug
Write-Host "Nombre de résultats: $($results.Results.Count)"
Write-Host "Type de results.Results: $($results.Results.GetType().FullName)"
foreach ($result in $results.Results) {
    Write-Host "  - Value: $($result.Value), Success: $($result.Success), Item: $($result.Item)"
}

# Test avec ConcurrentBag<object>
Write-Host "`nTest avec ConcurrentBag<object>" -ForegroundColor Yellow
$bag = [System.Collections.Concurrent.ConcurrentBag[object]]::new()
$bag.Add($testObject1)
$bag.Add($testObject2)
$bag.Add($testObject3)
Write-Host "Type de bag: $($bag.GetType().FullName)"
$results = Invoke-RunspaceProcessor -CompletedRunspaces $bag -NoProgress -Debug
Write-Host "Nombre de résultats: $($results.Results.Count)"
Write-Host "Type de results.Results: $($results.Results.GetType().FullName)"
foreach ($result in $results.Results) {
    Write-Host "  - Value: $($result.Value), Success: $($result.Success), Item: $($result.Item)"
}

# Test avec tableau
Write-Host "`nTest avec tableau" -ForegroundColor Yellow
$array = @($testObject1, $testObject2, $testObject3)
Write-Host "Type de array: $($array.GetType().FullName)"
$results = Invoke-RunspaceProcessor -CompletedRunspaces $array -NoProgress -Debug
Write-Host "Nombre de résultats: $($results.Results.Count)"
Write-Host "Type de results.Results: $($results.Results.GetType().FullName)"
foreach ($result in $results.Results) {
    Write-Host "  - Value: $($result.Value), Success: $($result.Success), Item: $($result.Item)"
}

# Test avec objets mixtes
Write-Host "`nTest avec objets mixtes" -ForegroundColor Yellow
$mixedList = [System.Collections.Generic.List[object]]::new()
$mixedList.Add($testObject1)
$mixedList.Add([PSCustomObject]@{ Value = "Test 4" })
$mixedList.Add([PSCustomObject]@{ Item = 5 })
$mixedList.Add([PSCustomObject]@{ OtherProperty = "Test 6" })
$mixedList.Add($null)
Write-Host "Type de mixedList: $($mixedList.GetType().FullName)"
$results = Invoke-RunspaceProcessor -CompletedRunspaces $mixedList -NoProgress -Debug
Write-Host "Nombre de résultats: $($results.Results.Count)"
Write-Host "Type de results.Results: $($results.Results.GetType().FullName)"
foreach ($result in $results.Results) {
    Write-Host "  - Value: $($result.Value), Success: $($result.Success), Item: $($result.Item)"
}

Write-Host "`nTests terminés." -ForegroundColor Green
