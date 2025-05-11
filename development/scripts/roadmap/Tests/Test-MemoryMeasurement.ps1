﻿# Test-MemoryMeasurement.ps1
# Script de test pour le module de mesure de mémoire
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Simple", "Moderate", "Heavy", "All")]
    [string]$TestType = "All",

    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Text", "CSV", "JSON", "HTML")]
    [string]$OutputFormat = "Text",

    [Parameter(Mandatory = $false)]
    [switch]$Verbose
)

# Importer le module de mesure de mémoire
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$utilsPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "utils"
$memoryModulePath = Join-Path -Path $utilsPath -ChildPath "Measure-Memory.ps1"

if (-not (Test-Path -Path $memoryModulePath)) {
    Write-Error "Module de mesure de mémoire non trouvé: $memoryModulePath"
    exit 1
}

. $memoryModulePath

# Fonction pour exécuter un test simple
function Test-SimpleMemoryUsage {
    Write-Host "Exécution du test simple d'utilisation mémoire..." -ForegroundColor Cyan

    $result = Measure-ScriptMemoryUsage -ScriptBlock {
        # Créer un tableau de 1 million d'entiers (environ 8 Mo)
        $array = 1..1000000

        # Effectuer quelques opérations
        $sum = ($array | Measure-Object -Sum).Sum

        return $sum
    } -SampleInterval 100 -Unit MB

    Write-Host "Test simple terminé. Résultat: $($result.Result)" -ForegroundColor Green

    return $result
}

# Fonction pour exécuter un test modéré
function Test-ModerateMemoryUsage {
    Write-Host "Exécution du test modéré d'utilisation mémoire..." -ForegroundColor Cyan

    $result = Measure-ScriptMemoryUsage -ScriptBlock {
        # Créer plusieurs tableaux (environ 40 Mo)
        $arrays = @()
        for ($i = 0; $i -lt 5; $i++) {
            $arrays += , (1..1000000)
        }

        # Effectuer des opérations sur les tableaux
        $sums = @()
        foreach ($array in $arrays) {
            $sums += ($array | Measure-Object -Sum).Sum
        }

        # Créer des objets complexes
        $objects = @()
        for ($i = 0; $i -lt 10000; $i++) {
            $objects += [PSCustomObject]@{
                Id         = $i
                Name       = "Object-$i"
                Value      = Get-Random -Minimum 1 -Maximum 1000
                Properties = @{
                    CreatedAt = Get-Date
                    Tags      = @("Tag1", "Tag2", "Tag3")
                }
            }
        }

        return $sums
    } -SampleInterval 100 -Unit MB

    Write-Host "Test modéré terminé." -ForegroundColor Green

    return $result
}

# Fonction pour exécuter un test intensif
function Test-HeavyMemoryUsage {
    Write-Host "Exécution du test intensif d'utilisation mémoire..." -ForegroundColor Cyan

    $result = Measure-ScriptMemoryUsage -ScriptBlock {
        # Créer une grande quantité de données (environ 200 Mo)
        $largeArrays = @()
        for ($i = 0; $i -lt 20; $i++) {
            $largeArrays += , (1..1000000 | ForEach-Object { Get-Random -Minimum 1 -Maximum 1000 })
        }

        # Effectuer des opérations intensives
        $processedData = @()
        foreach ($array in $largeArrays) {
            $processedData += @{
                Sum               = ($array | Measure-Object -Sum).Sum
                Average           = ($array | Measure-Object -Average).Average
                Min               = ($array | Measure-Object -Minimum).Minimum
                Max               = ($array | Measure-Object -Maximum).Maximum
                StandardDeviation = [Math]::Sqrt(($array | ForEach-Object { [Math]::Pow($_ - ($array | Measure-Object -Average).Average, 2) } | Measure-Object -Average).Average)
            }
        }

        # Simuler une fuite mémoire (ne pas libérer certaines données)
        $script:leakedData = $largeArrays[0..4]

        return $processedData.Count
    } -SampleInterval 100 -Unit MB

    Write-Host "Test intensif terminé." -ForegroundColor Green

    # Forcer la libération de la mémoire "fuitée"
    $script:leakedData = $null
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()

    return $result
}

# Fonction pour exécuter tous les tests
function Test-AllMemoryUsage {
    $results = @{
        Simple   = Test-SimpleMemoryUsage
        Moderate = Test-ModerateMemoryUsage
        Heavy    = Test-HeavyMemoryUsage
    }

    return $results
}

# Fonction pour formater les résultats de tous les tests
function Format-AllTestResults {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Results,

        [Parameter(Mandatory = $false)]
        [string]$Format = "Text"
    )

    switch ($Format) {
        "Text" {
            $output = @()
            $output += "=== RÉSULTATS DES TESTS DE MESURE MÉMOIRE ==="
            $output += "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
            $output += ""

            foreach ($key in $Results.Keys) {
                $result = $Results[$key]
                $stats = $result.MemoryStatistics

                $output += "--- TEST $key ---"
                $output += "Durée: $($stats.Duration) secondes"
                $output += "Working Set Initial: $($stats.InitialWorkingSet) $($stats.Unit)"
                $output += "Working Set Final: $($stats.CurrentWorkingSet) $($stats.Unit)"
                $output += "Working Set Pic: $($stats.PeakWorkingSet) $($stats.Unit)"
                $output += "Working Set Delta: $($stats.WorkingSetDelta) $($stats.Unit)"
                $output += "Mémoire Privée Initiale: $($stats.InitialPrivateMemory) $($stats.Unit)"
                $output += "Mémoire Privée Finale: $($stats.CurrentPrivateMemory) $($stats.Unit)"
                $output += "Mémoire Privée Pic: $($stats.PeakPrivateMemory) $($stats.Unit)"
                $output += "Mémoire Privée Delta: $($stats.PrivateMemoryDelta) $($stats.Unit)"
                $output += "Working Set après GC: $($stats.FinalWorkingSetAfterGC) $($stats.Unit)"
                $output += "Mémoire Privée après GC: $($stats.FinalPrivateMemoryAfterGC) $($stats.Unit)"
                $output += "Working Set conservé: $($stats.RetainedWorkingSet) $($stats.Unit)"
                $output += "Mémoire Privée conservée: $($stats.RetainedPrivateMemory) $($stats.Unit)"
                $output += ""
            }

            return $output -join "`n"
        }
        "HTML" {
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Résultats des tests de mesure mémoire</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #333; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { padding: 8px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #f2f2f2; }
        .highlight { font-weight: bold; color: #e74c3c; }
        .test-section { margin-bottom: 30px; border: 1px solid #ddd; padding: 15px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>Résultats des tests de mesure mémoire</h1>
    <p>Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>

"@

            foreach ($key in $Results.Keys) {
                $result = $Results[$key]
                $stats = $result.MemoryStatistics

                $html += @"
    <div class="test-section">
        <h2>Test $key</h2>
        <table>
            <tr><th>Métrique</th><th>Valeur</th></tr>
            <tr><td>Durée</td><td>$($stats.Duration) secondes</td></tr>
            <tr><td>Working Set Initial</td><td>$($stats.InitialWorkingSet) $($stats.Unit)</td></tr>
            <tr><td>Working Set Final</td><td>$($stats.CurrentWorkingSet) $($stats.Unit)</td></tr>
            <tr><td>Working Set Pic</td><td class="highlight">$($stats.PeakWorkingSet) $($stats.Unit)</td></tr>
            <tr><td>Working Set Delta</td><td>$($stats.WorkingSetDelta) $($stats.Unit)</td></tr>
            <tr><td>Mémoire Privée Initiale</td><td>$($stats.InitialPrivateMemory) $($stats.Unit)</td></tr>
            <tr><td>Mémoire Privée Finale</td><td>$($stats.CurrentPrivateMemory) $($stats.Unit)</td></tr>
            <tr><td>Mémoire Privée Pic</td><td class="highlight">$($stats.PeakPrivateMemory) $($stats.Unit)</td></tr>
            <tr><td>Mémoire Privée Delta</td><td>$($stats.PrivateMemoryDelta) $($stats.Unit)</td></tr>
            <tr><td>Working Set après GC</td><td>$($stats.FinalWorkingSetAfterGC) $($stats.Unit)</td></tr>
            <tr><td>Mémoire Privée après GC</td><td>$($stats.FinalPrivateMemoryAfterGC) $($stats.Unit)</td></tr>
            <tr><td>Working Set conservé</td><td>$($stats.RetainedWorkingSet) $($stats.Unit)</td></tr>
            <tr><td>Mémoire Privée conservée</td><td>$($stats.RetainedPrivateMemory) $($stats.Unit)</td></tr>
        </table>
    </div>
"@
            }

            $html += @"
</body>
</html>
"@

            return $html
        }
        "JSON" {
            $jsonResults = @{}

            foreach ($key in $Results.Keys) {
                $jsonResults[$key] = $Results[$key].MemoryStatistics
            }

            return $jsonResults | ConvertTo-Json -Depth 5
        }
        "CSV" {
            $csvResults = @()

            foreach ($key in $Results.Keys) {
                $stats = $Results[$key].MemoryStatistics
                $stats | Add-Member -MemberType NoteProperty -Name TestType -Value $key
                $csvResults += $stats
            }

            return $csvResults | ConvertTo-Csv -NoTypeInformation
        }
    }
}

# Exécuter les tests selon le type spécifié
$testResults = $null

switch ($TestType) {
    "Simple" {
        $testResults = @{ Simple = Test-SimpleMemoryUsage }
    }
    "Moderate" {
        $testResults = @{ Moderate = Test-ModerateMemoryUsage }
    }
    "Heavy" {
        $testResults = @{ Heavy = Test-HeavyMemoryUsage }
    }
    "All" {
        $testResults = Test-AllMemoryUsage
    }
}

# Formater et afficher les résultats
$formattedResults = Format-AllTestResults -Results $testResults -Format $OutputFormat

if ($OutputPath) {
    $formattedResults | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "Résultats enregistrés dans: $OutputPath" -ForegroundColor Green
} else {
    Write-Output $formattedResults
}

# Retourner les résultats pour une utilisation ultérieure
return $testResults
