# Test simple des collections dans Invoke-RunspaceProcessor
# Ce script teste les modifications apportées à la fonction Invoke-RunspaceProcessor
# pour utiliser System.Collections.Concurrent.ConcurrentBag<T> et System.Collections.Generic.List<T>

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force -Verbose

# Initialiser le module
Initialize-UnifiedParallel -Verbose

Write-Host "Test des collections dans Invoke-RunspaceProcessor" -ForegroundColor Cyan

# Créer des objets de test simples
$testObject1 = [PSCustomObject]@{
    PowerShell = $null
    Handle = $null
    Item = 1
    Value = "Test 1"
}

$testObject2 = [PSCustomObject]@{
    PowerShell = $null
    Handle = $null
    Item = 2
    Value = "Test 2"
}

$testObject3 = [PSCustomObject]@{
    PowerShell = $null
    Handle = $null
    Item = 3
    Value = "Test 3"
}

# Test 1: Utilisation de différents types de collections en entrée
Write-Host "`nTest 1: Utilisation de différents types de collections en entrée" -ForegroundColor Yellow

# Test avec ArrayList
Write-Host "Test avec ArrayList" -ForegroundColor White
$arrayList = New-Object System.Collections.ArrayList
[void]$arrayList.Add($testObject1)
[void]$arrayList.Add($testObject2)
[void]$arrayList.Add($testObject3)
Write-Host "Type de arrayList: $($arrayList.GetType().FullName)"
$results = Invoke-RunspaceProcessor -CompletedRunspaces $arrayList -NoProgress
Write-Host "Nombre de résultats: $($results.Results.Count)"
Write-Host "Type de results.Results: $($results.Results.GetType().FullName)"

# Test avec List<object>
Write-Host "`nTest avec List<object>" -ForegroundColor White
$list = [System.Collections.Generic.List[object]]::new()
$list.Add($testObject1)
$list.Add($testObject2)
$list.Add($testObject3)
Write-Host "Type de list: $($list.GetType().FullName)"
$results = Invoke-RunspaceProcessor -CompletedRunspaces $list -NoProgress
Write-Host "Nombre de résultats: $($results.Results.Count)"
Write-Host "Type de results.Results: $($results.Results.GetType().FullName)"

# Test avec ConcurrentBag<object>
Write-Host "`nTest avec ConcurrentBag<object>" -ForegroundColor White
$bag = [System.Collections.Concurrent.ConcurrentBag[object]]::new()
$bag.Add($testObject1)
$bag.Add($testObject2)
$bag.Add($testObject3)
Write-Host "Type de bag: $($bag.GetType().FullName)"
$results = Invoke-RunspaceProcessor -CompletedRunspaces $bag -NoProgress
Write-Host "Nombre de résultats: $($results.Results.Count)"
Write-Host "Type de results.Results: $($results.Results.GetType().FullName)"

# Test avec tableau
Write-Host "`nTest avec tableau" -ForegroundColor White
$array = @($testObject1, $testObject2, $testObject3)
Write-Host "Type de array: $($array.GetType().FullName)"
$results = Invoke-RunspaceProcessor -CompletedRunspaces $array -NoProgress
Write-Host "Nombre de résultats: $($results.Results.Count)"
Write-Host "Type de results.Results: $($results.Results.GetType().FullName)"

# Test 2: Vérification des performances
Write-Host "`nTest 2: Vérification des performances" -ForegroundColor Yellow

# Créer un grand nombre d'objets
$largeCount = 1000
Write-Host "Création de $largeCount objets..." -ForegroundColor White
$largeList = [System.Collections.Generic.List[object]]::new($largeCount)
for ($i = 1; $i -le $largeCount; $i++) {
    $largeList.Add([PSCustomObject]@{
        PowerShell = $null
        Handle = $null
        Item = $i
        Value = "Test $i"
    })
}

# Traiter les objets
Write-Host "Traitement des objets avec List<object>..." -ForegroundColor White
$startTime = Get-Date
$results = Invoke-RunspaceProcessor -CompletedRunspaces $largeList -NoProgress
$processDuration = (Get-Date) - $startTime
Write-Host "Durée de traitement avec List<object>: $($processDuration.TotalSeconds) secondes" -ForegroundColor White
Write-Host "Nombre de résultats: $($results.Results.Count)" -ForegroundColor White

# Créer un grand nombre d'objets dans un ConcurrentBag
$largeBag = [System.Collections.Concurrent.ConcurrentBag[object]]::new()
for ($i = 1; $i -le $largeCount; $i++) {
    $largeBag.Add([PSCustomObject]@{
        PowerShell = $null
        Handle = $null
        Item = $i
        Value = "Test $i"
    })
}

# Traiter les objets
Write-Host "Traitement des objets avec ConcurrentBag<object>..." -ForegroundColor White
$startTime = Get-Date
$results = Invoke-RunspaceProcessor -CompletedRunspaces $largeBag -NoProgress
$processDuration = (Get-Date) - $startTime
Write-Host "Durée de traitement avec ConcurrentBag<object>: $($processDuration.TotalSeconds) secondes" -ForegroundColor White
Write-Host "Nombre de résultats: $($results.Results.Count)" -ForegroundColor White

Write-Host "`nTests terminés." -ForegroundColor Green
