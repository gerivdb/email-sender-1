#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour valider les optimisations de conversion de types.
.DESCRIPTION
    Ce script de test vérifie que l'utilisation de méthodes TryParse
    améliore les performances par rapport aux conversions génériques.
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
$conversionPath = Join-Path -Path $projectRoot -ChildPath "development\roadmap\scripts\parser\module\Functions\Private\Conversion"

# Importer la fonction de conversion
$conversionFile = Join-Path -Path $conversionPath -ChildPath "ConvertTo-Type.ps1"
. $conversionFile

# Fonction pour mesurer les performances des conversions standard
function Test-StandardConversion {
    param (
        [int]$Iterations = 1000,
        [string]$Type = "Integer"
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    $values = @()
    switch ($Type) {
        "Integer" {
            $values = 1..$Iterations | ForEach-Object { "$_" }
            for ($i = 0; $i -lt $Iterations; $i++) {
                try {
                    $result = [int]::Parse($values[$i])
                }
                catch {
                    # Ignorer les erreurs
                }
            }
        }
        "Decimal" {
            $values = 1..$Iterations | ForEach-Object { "$_.5" }
            for ($i = 0; $i -lt $Iterations; $i++) {
                try {
                    $result = [decimal]::Parse($values[$i], [System.Globalization.CultureInfo]::InvariantCulture)
                }
                catch {
                    # Ignorer les erreurs
                }
            }
        }
        "Boolean" {
            $values = 1..$Iterations | ForEach-Object { if ($_ % 2 -eq 0) { "true" } else { "false" } }
            for ($i = 0; $i -lt $Iterations; $i++) {
                try {
                    $result = [bool]::Parse($values[$i])
                }
                catch {
                    # Ignorer les erreurs
                }
            }
        }
        "DateTime" {
            $values = 1..$Iterations | ForEach-Object { "2025-01-$([Math]::Min(31, $_))" }
            for ($i = 0; $i -lt $Iterations; $i++) {
                try {
                    $result = [datetime]::Parse($values[$i])
                }
                catch {
                    # Ignorer les erreurs
                }
            }
        }
    }
    
    $stopwatch.Stop()
    return $stopwatch.ElapsedMilliseconds
}

# Fonction pour mesurer les performances des conversions optimisées
function Test-OptimizedConversion {
    param (
        [int]$Iterations = 1000,
        [string]$Type = "Integer"
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    $values = @()
    switch ($Type) {
        "Integer" {
            $values = 1..$Iterations | ForEach-Object { "$_" }
            for ($i = 0; $i -lt $Iterations; $i++) {
                $result = $null
                [int]::TryParse($values[$i], [ref]$result)
            }
        }
        "Decimal" {
            $values = 1..$Iterations | ForEach-Object { "$_.5" }
            for ($i = 0; $i -lt $Iterations; $i++) {
                $result = $null
                [decimal]::TryParse($values[$i], [System.Globalization.NumberStyles]::Number, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$result)
            }
        }
        "Boolean" {
            $values = 1..$Iterations | ForEach-Object { if ($_ % 2 -eq 0) { "true" } else { "false" } }
            for ($i = 0; $i -lt $Iterations; $i++) {
                $result = $null
                [bool]::TryParse($values[$i], [ref]$result)
            }
        }
        "DateTime" {
            $values = 1..$Iterations | ForEach-Object { "2025-01-$([Math]::Min(31, $_))" }
            for ($i = 0; $i -lt $Iterations; $i++) {
                $result = $null
                [datetime]::TryParse($values[$i], [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$result)
            }
        }
    }
    
    $stopwatch.Stop()
    return $stopwatch.ElapsedMilliseconds
}

# Tests Pester
Describe "Tests d'optimisation des conversions de types" {
    Context "Comparaison des performances" {
        BeforeAll {
            $iterations = 10000
            $testTypes = @("Integer", "Decimal", "Boolean", "DateTime")
            
            # Exécuter les tests plusieurs fois pour obtenir des résultats plus fiables
            $runCount = 3
            
            $results = @{}
            
            foreach ($type in $testTypes) {
                $standardResults = @()
                $optimizedResults = @()
                
                for ($i = 0; $i -lt $runCount; $i++) {
                    $standardResults += Test-StandardConversion -Iterations $iterations -Type $type
                    $optimizedResults += Test-OptimizedConversion -Iterations $iterations -Type $type
                }
                
                $standardAvg = ($standardResults | Measure-Object -Average).Average
                $optimizedAvg = ($optimizedResults | Measure-Object -Average).Average
                $improvement = ($standardAvg - $optimizedAvg) / $standardAvg * 100
                
                $results[$type] = @{
                    StandardAvg = $standardAvg
                    OptimizedAvg = $optimizedAvg
                    Improvement = $improvement
                }
            }
        }
        
        It "Les conversions optimisées devraient être plus rapides pour les entiers" {
            $type = "Integer"
            Write-Host "Conversion standard ($type): $($results[$type].StandardAvg) ms"
            Write-Host "Conversion optimisée ($type): $($results[$type].OptimizedAvg) ms"
            Write-Host "Amélioration: $([Math]::Round($results[$type].Improvement, 2))%"
            
            $results[$type].OptimizedAvg | Should -BeLessThan $results[$type].StandardAvg
        }
        
        It "Les conversions optimisées devraient être plus rapides pour les décimaux" {
            $type = "Decimal"
            Write-Host "Conversion standard ($type): $($results[$type].StandardAvg) ms"
            Write-Host "Conversion optimisée ($type): $($results[$type].OptimizedAvg) ms"
            Write-Host "Amélioration: $([Math]::Round($results[$type].Improvement, 2))%"
            
            $results[$type].OptimizedAvg | Should -BeLessThan $results[$type].StandardAvg
        }
        
        It "Les conversions optimisées devraient être plus rapides pour les booléens" {
            $type = "Boolean"
            Write-Host "Conversion standard ($type): $($results[$type].StandardAvg) ms"
            Write-Host "Conversion optimisée ($type): $($results[$type].OptimizedAvg) ms"
            Write-Host "Amélioration: $([Math]::Round($results[$type].Improvement, 2))%"
            
            $results[$type].OptimizedAvg | Should -BeLessThan $results[$type].StandardAvg
        }
        
        It "Les conversions optimisées devraient être plus rapides pour les dates" {
            $type = "DateTime"
            Write-Host "Conversion standard ($type): $($results[$type].StandardAvg) ms"
            Write-Host "Conversion optimisée ($type): $($results[$type].OptimizedAvg) ms"
            Write-Host "Amélioration: $([Math]::Round($results[$type].Improvement, 2))%"
            
            $results[$type].OptimizedAvg | Should -BeLessThan $results[$type].StandardAvg
        }
    }
}

# Exécuter les tests
Invoke-Pester -Output Detailed
