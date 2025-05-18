#Requires -Version 5.1
<#
.SYNOPSIS
    Test manuel pour valider les optimisations.
.DESCRIPTION
    Ce script exécute des tests manuels pour vérifier que les optimisations
    améliorent effectivement les performances.
.NOTES
    Version: 1.0
    Auteur: EMAIL_SENDER_1 Team
    Date: 2025-05-15
#>

# Fonction pour mesurer les performances des tableaux standard
function Test-StandardArray {
    param (
        [int]$Size = 10000
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    $array = @()
    for ($i = 0; $i -lt $Size; $i++) {
        $array += [PSCustomObject]@{
            Id = $i
            Value = "Item $i"
        }
    }
    
    $stopwatch.Stop()
    return $stopwatch.ElapsedMilliseconds
}

# Fonction pour mesurer les performances des collections List<T>
function Test-OptimizedList {
    param (
        [int]$Size = 10000
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    $list = [System.Collections.Generic.List[PSCustomObject]]::new($Size)
    for ($i = 0; $i -lt $Size; $i++) {
        $list.Add([PSCustomObject]@{
            Id = $i
            Value = "Item $i"
        })
    }
    
    $stopwatch.Stop()
    return $stopwatch.ElapsedMilliseconds
}

# Fonction pour mesurer les performances des boucles foreach
function Test-ForeachLoop {
    param (
        [int]$Size = 10000
    )
    
    # Créer les données de test
    $data = [System.Collections.Generic.List[PSCustomObject]]::new($Size)
    for ($i = 0; $i -lt $Size; $i++) {
        $data.Add([PSCustomObject]@{
            Id = $i
            Value = "Item $i"
        })
    }
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    $sum = 0
    foreach ($item in $data) {
        $sum += $item.Id
    }
    
    $stopwatch.Stop()
    return $stopwatch.ElapsedMilliseconds
}

# Fonction pour mesurer les performances des boucles for
function Test-ForLoop {
    param (
        [int]$Size = 10000
    )
    
    # Créer les données de test
    $data = [System.Collections.Generic.List[PSCustomObject]]::new($Size)
    for ($i = 0; $i -lt $Size; $i++) {
        $data.Add([PSCustomObject]@{
            Id = $i
            Value = "Item $i"
        })
    }
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    $sum = 0
    for ($i = 0; $i -lt $data.Count; $i++) {
        $sum += $data[$i].Id
    }
    
    $stopwatch.Stop()
    return $stopwatch.ElapsedMilliseconds
}

# Fonction pour mesurer les performances des conversions standard
function Test-StandardConversion {
    param (
        [int]$Iterations = 1000
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    $values = 1..$Iterations | ForEach-Object { "$_" }
    for ($i = 0; $i -lt $Iterations; $i++) {
        try {
            $result = [int]::Parse($values[$i])
        }
        catch {
            # Ignorer les erreurs
        }
    }
    
    $stopwatch.Stop()
    return $stopwatch.ElapsedMilliseconds
}

# Fonction pour mesurer les performances des conversions optimisées
function Test-OptimizedConversion {
    param (
        [int]$Iterations = 1000
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    $values = 1..$Iterations | ForEach-Object { "$_" }
    for ($i = 0; $i -lt $Iterations; $i++) {
        $result = $null
        [int]::TryParse($values[$i], [ref]$result)
    }
    
    $stopwatch.Stop()
    return $stopwatch.ElapsedMilliseconds
}

# Exécuter les tests
Write-Host "=== Test des collections optimisées ===" -ForegroundColor Cyan

$smallSize = 1000
$mediumSize = 5000
$largeSize = 10000

$iterations = 5

$standardSmallResults = @()
$optimizedSmallResults = @()
$standardMediumResults = @()
$optimizedMediumResults = @()
$standardLargeResults = @()
$optimizedLargeResults = @()

for ($i = 0; $i -lt $iterations; $i++) {
    $standardSmallResults += Test-StandardArray -Size $smallSize
    $optimizedSmallResults += Test-OptimizedList -Size $smallSize
    $standardMediumResults += Test-StandardArray -Size $mediumSize
    $optimizedMediumResults += Test-OptimizedList -Size $mediumSize
    $standardLargeResults += Test-StandardArray -Size $largeSize
    $optimizedLargeResults += Test-OptimizedList -Size $largeSize
}

$standardSmallAvg = ($standardSmallResults | Measure-Object -Average).Average
$optimizedSmallAvg = ($optimizedSmallResults | Measure-Object -Average).Average
$standardMediumAvg = ($standardMediumResults | Measure-Object -Average).Average
$optimizedMediumAvg = ($optimizedMediumResults | Measure-Object -Average).Average
$standardLargeAvg = ($standardLargeResults | Measure-Object -Average).Average
$optimizedLargeAvg = ($optimizedLargeResults | Measure-Object -Average).Average

$smallImprovement = ($standardSmallAvg - $optimizedSmallAvg) / $standardSmallAvg * 100
$mediumImprovement = ($standardMediumAvg - $optimizedMediumAvg) / $standardMediumAvg * 100
$largeImprovement = ($standardLargeAvg - $optimizedLargeAvg) / $standardLargeAvg * 100

Write-Host "Tableau standard (1000 éléments): $standardSmallAvg ms"
Write-Host "Liste optimisée (1000 éléments): $optimizedSmallAvg ms"
Write-Host "Amélioration: $([Math]::Round($smallImprovement, 2))%"
Write-Host ""

Write-Host "Tableau standard (5000 éléments): $standardMediumAvg ms"
Write-Host "Liste optimisée (5000 éléments): $optimizedMediumAvg ms"
Write-Host "Amélioration: $([Math]::Round($mediumImprovement, 2))%"
Write-Host ""

Write-Host "Tableau standard (10000 éléments): $standardLargeAvg ms"
Write-Host "Liste optimisée (10000 éléments): $optimizedLargeAvg ms"
Write-Host "Amélioration: $([Math]::Round($largeImprovement, 2))%"
Write-Host ""

Write-Host "=== Test des boucles optimisées ===" -ForegroundColor Cyan

$foreachSmallResults = @()
$forSmallResults = @()
$foreachMediumResults = @()
$forMediumResults = @()
$foreachLargeResults = @()
$forLargeResults = @()

for ($i = 0; $i -lt $iterations; $i++) {
    $foreachSmallResults += Test-ForeachLoop -Size $smallSize
    $forSmallResults += Test-ForLoop -Size $smallSize
    $foreachMediumResults += Test-ForeachLoop -Size $mediumSize
    $forMediumResults += Test-ForLoop -Size $mediumSize
    $foreachLargeResults += Test-ForeachLoop -Size $largeSize
    $forLargeResults += Test-ForLoop -Size $largeSize
}

$foreachSmallAvg = ($foreachSmallResults | Measure-Object -Average).Average
$forSmallAvg = ($forSmallResults | Measure-Object -Average).Average
$foreachMediumAvg = ($foreachMediumResults | Measure-Object -Average).Average
$forMediumAvg = ($forMediumResults | Measure-Object -Average).Average
$foreachLargeAvg = ($foreachLargeResults | Measure-Object -Average).Average
$forLargeAvg = ($forLargeResults | Measure-Object -Average).Average

$smallLoopImprovement = ($foreachSmallAvg - $forSmallAvg) / $foreachSmallAvg * 100
$mediumLoopImprovement = ($foreachMediumAvg - $forMediumAvg) / $foreachMediumAvg * 100
$largeLoopImprovement = ($foreachLargeAvg - $forLargeAvg) / $foreachLargeAvg * 100

Write-Host "Boucle foreach (1000 éléments): $foreachSmallAvg ms"
Write-Host "Boucle for (1000 éléments): $forSmallAvg ms"
Write-Host "Amélioration: $([Math]::Round($smallLoopImprovement, 2))%"
Write-Host ""

Write-Host "Boucle foreach (5000 éléments): $foreachMediumAvg ms"
Write-Host "Boucle for (5000 éléments): $forMediumAvg ms"
Write-Host "Amélioration: $([Math]::Round($mediumLoopImprovement, 2))%"
Write-Host ""

Write-Host "Boucle foreach (10000 éléments): $foreachLargeAvg ms"
Write-Host "Boucle for (10000 éléments): $forLargeAvg ms"
Write-Host "Amélioration: $([Math]::Round($largeLoopImprovement, 2))%"
Write-Host ""

Write-Host "=== Test des conversions optimisées ===" -ForegroundColor Cyan

$standardConversionResults = @()
$optimizedConversionResults = @()

for ($i = 0; $i -lt $iterations; $i++) {
    $standardConversionResults += Test-StandardConversion -Iterations 10000
    $optimizedConversionResults += Test-OptimizedConversion -Iterations 10000
}

$standardConversionAvg = ($standardConversionResults | Measure-Object -Average).Average
$optimizedConversionAvg = ($optimizedConversionResults | Measure-Object -Average).Average

$conversionImprovement = ($standardConversionAvg - $optimizedConversionAvg) / $standardConversionAvg * 100

Write-Host "Conversion standard: $standardConversionAvg ms"
Write-Host "Conversion optimisée: $optimizedConversionAvg ms"
Write-Host "Amélioration: $([Math]::Round($conversionImprovement, 2))%"
Write-Host ""
