#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour valider les optimisations de boucles.
.DESCRIPTION
    Ce script de test vérifie que l'utilisation de boucles for
    améliore les performances par rapport aux boucles foreach.
.NOTES
    Version: 1.0
    Auteur: EMAIL_SENDER_1 Team
    Date: 2025-05-15
#>

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Install-Module -Name Pester -Force -SkipPublisherCheck
}
Import-Module Pester -Force

# Définir les chemins
$scriptRoot = $PSScriptRoot
$projectRoot = (Get-Item $scriptRoot).Parent.Parent.FullName

# Fonction pour mesurer les performances des boucles foreach
function Test-ForeachLoop {
    param (
        [int]$Size = 10000,
        [switch]$UseArray
    )
    
    # Créer les données de test
    if ($UseArray) {
        $data = @()
        for ($i = 0; $i -lt $Size; $i++) {
            $data += [PSCustomObject]@{
                Id = $i
                Value = "Item $i"
            }
        }
    }
    else {
        $data = [System.Collections.Generic.List[PSCustomObject]]::new($Size)
        for ($i = 0; $i -lt $Size; $i++) {
            $data.Add([PSCustomObject]@{
                Id = $i
                Value = "Item $i"
            })
        }
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
        [int]$Size = 10000,
        [switch]$UseArray
    )
    
    # Créer les données de test
    if ($UseArray) {
        $data = @()
        for ($i = 0; $i -lt $Size; $i++) {
            $data += [PSCustomObject]@{
                Id = $i
                Value = "Item $i"
            }
        }
    }
    else {
        $data = [System.Collections.Generic.List[PSCustomObject]]::new($Size)
        for ($i = 0; $i -lt $Size; $i++) {
            $data.Add([PSCustomObject]@{
                Id = $i
                Value = "Item $i"
            })
        }
    }
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    $sum = 0
    for ($i = 0; $i -lt $data.Count; $i++) {
        $sum += $data[$i].Id
    }
    
    $stopwatch.Stop()
    return $stopwatch.ElapsedMilliseconds
}

# Tests Pester
Describe "Tests d'optimisation des boucles" {
    Context "Comparaison des performances avec tableaux standard" {
        BeforeAll {
            $smallSize = 1000
            $mediumSize = 5000
            $largeSize = 10000
            
            # Exécuter les tests plusieurs fois pour obtenir des résultats plus fiables
            $iterations = 5
            
            $foreachSmallResults = @()
            $forSmallResults = @()
            $foreachMediumResults = @()
            $forMediumResults = @()
            $foreachLargeResults = @()
            $forLargeResults = @()
            
            for ($i = 0; $i -lt $iterations; $i++) {
                $foreachSmallResults += Test-ForeachLoop -Size $smallSize -UseArray
                $forSmallResults += Test-ForLoop -Size $smallSize -UseArray
                $foreachMediumResults += Test-ForeachLoop -Size $mediumSize -UseArray
                $forMediumResults += Test-ForLoop -Size $mediumSize -UseArray
                $foreachLargeResults += Test-ForeachLoop -Size $largeSize -UseArray
                $forLargeResults += Test-ForLoop -Size $largeSize -UseArray
            }
            
            $foreachSmallAvg = ($foreachSmallResults | Measure-Object -Average).Average
            $forSmallAvg = ($forSmallResults | Measure-Object -Average).Average
            $foreachMediumAvg = ($foreachMediumResults | Measure-Object -Average).Average
            $forMediumAvg = ($forMediumResults | Measure-Object -Average).Average
            $foreachLargeAvg = ($foreachLargeResults | Measure-Object -Average).Average
            $forLargeAvg = ($forLargeResults | Measure-Object -Average).Average
            
            $smallImprovement = ($foreachSmallAvg - $forSmallAvg) / $foreachSmallAvg * 100
            $mediumImprovement = ($foreachMediumAvg - $forMediumAvg) / $foreachMediumAvg * 100
            $largeImprovement = ($foreachLargeAvg - $forLargeAvg) / $foreachLargeAvg * 100
        }
        
        It "Les boucles for devraient être plus rapides pour les petites tailles avec tableaux standard" {
            Write-Host "Boucle foreach (1000 éléments): $foreachSmallAvg ms"
            Write-Host "Boucle for (1000 éléments): $forSmallAvg ms"
            Write-Host "Amélioration: $([Math]::Round($smallImprovement, 2))%"
            
            $forSmallAvg | Should -BeLessThan $foreachSmallAvg
        }
        
        It "Les boucles for devraient être plus rapides pour les tailles moyennes avec tableaux standard" {
            Write-Host "Boucle foreach (5000 éléments): $foreachMediumAvg ms"
            Write-Host "Boucle for (5000 éléments): $forMediumAvg ms"
            Write-Host "Amélioration: $([Math]::Round($mediumImprovement, 2))%"
            
            $forMediumAvg | Should -BeLessThan $foreachMediumAvg
        }
        
        It "Les boucles for devraient être plus rapides pour les grandes tailles avec tableaux standard" {
            Write-Host "Boucle foreach (10000 éléments): $foreachLargeAvg ms"
            Write-Host "Boucle for (10000 éléments): $forLargeAvg ms"
            Write-Host "Amélioration: $([Math]::Round($largeImprovement, 2))%"
            
            $forLargeAvg | Should -BeLessThan $foreachLargeAvg
        }
    }
    
    Context "Comparaison des performances avec List<T>" {
        BeforeAll {
            $smallSize = 1000
            $mediumSize = 5000
            $largeSize = 10000
            
            # Exécuter les tests plusieurs fois pour obtenir des résultats plus fiables
            $iterations = 5
            
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
            
            $smallImprovement = ($foreachSmallAvg - $forSmallAvg) / $foreachSmallAvg * 100
            $mediumImprovement = ($foreachMediumAvg - $forMediumAvg) / $foreachMediumAvg * 100
            $largeImprovement = ($foreachLargeAvg - $forLargeAvg) / $foreachLargeAvg * 100
        }
        
        It "Les boucles for devraient être plus rapides pour les petites tailles avec List<T>" {
            Write-Host "Boucle foreach (1000 éléments): $foreachSmallAvg ms"
            Write-Host "Boucle for (1000 éléments): $forSmallAvg ms"
            Write-Host "Amélioration: $([Math]::Round($smallImprovement, 2))%"
            
            $forSmallAvg | Should -BeLessThan $foreachSmallAvg
        }
        
        It "Les boucles for devraient être plus rapides pour les tailles moyennes avec List<T>" {
            Write-Host "Boucle foreach (5000 éléments): $foreachMediumAvg ms"
            Write-Host "Boucle for (5000 éléments): $forMediumAvg ms"
            Write-Host "Amélioration: $([Math]::Round($mediumImprovement, 2))%"
            
            $forMediumAvg | Should -BeLessThan $foreachMediumAvg
        }
        
        It "Les boucles for devraient être plus rapides pour les grandes tailles avec List<T>" {
            Write-Host "Boucle foreach (10000 éléments): $foreachLargeAvg ms"
            Write-Host "Boucle for (10000 éléments): $forLargeAvg ms"
            Write-Host "Amélioration: $([Math]::Round($largeImprovement, 2))%"
            
            $forLargeAvg | Should -BeLessThan $foreachLargeAvg
        }
    }
}

# Exécuter les tests
Invoke-Pester -Output Detailed
