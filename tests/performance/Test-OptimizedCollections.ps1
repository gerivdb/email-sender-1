#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour valider les optimisations de collections.
.DESCRIPTION
    Ce script de test vérifie que l'utilisation de collections optimisées (List<T>)
    améliore les performances par rapport aux tableaux standard.
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
$performancePath = Join-Path -Path $projectRoot -ChildPath "development\scripts\performance"

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

# Tests Pester
Describe "Tests d'optimisation des collections" {
    Context "Comparaison des performances" {
        BeforeAll {
            $smallSize = 1000
            $mediumSize = 5000
            $largeSize = 10000
            
            # Exécuter les tests plusieurs fois pour obtenir des résultats plus fiables
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
        }
        
        It "Les collections optimisées devraient être plus rapides pour les petites tailles" {
            Write-Host "Tableau standard (1000 éléments): $standardSmallAvg ms"
            Write-Host "Liste optimisée (1000 éléments): $optimizedSmallAvg ms"
            Write-Host "Amélioration: $([Math]::Round($smallImprovement, 2))%"
            
            $optimizedSmallAvg | Should -BeLessThan $standardSmallAvg
        }
        
        It "Les collections optimisées devraient être plus rapides pour les tailles moyennes" {
            Write-Host "Tableau standard (5000 éléments): $standardMediumAvg ms"
            Write-Host "Liste optimisée (5000 éléments): $optimizedMediumAvg ms"
            Write-Host "Amélioration: $([Math]::Round($mediumImprovement, 2))%"
            
            $optimizedMediumAvg | Should -BeLessThan $standardMediumAvg
        }
        
        It "Les collections optimisées devraient être plus rapides pour les grandes tailles" {
            Write-Host "Tableau standard (10000 éléments): $standardLargeAvg ms"
            Write-Host "Liste optimisée (10000 éléments): $optimizedLargeAvg ms"
            Write-Host "Amélioration: $([Math]::Round($largeImprovement, 2))%"
            
            $optimizedLargeAvg | Should -BeLessThan $standardLargeAvg
        }
        
        It "L'amélioration devrait être plus significative pour les grandes tailles" {
            $largeImprovement | Should -BeGreaterThan $smallImprovement
        }
    }
}

# Exécuter les tests
Invoke-Pester -Output Detailed
