#Requires -Version 5.1
<#
.SYNOPSIS
    Tests de performance pour le module CacheManager.ps1.
.DESCRIPTION
    Ce script contient des tests de performance pour mesurer les gains apportés par le module CacheManager.ps1.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-06-06
#>

# Importer le module CacheManager
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$modulesPath = Join-Path -Path $projectRoot -ChildPath "modules"
$cacheManagerPath = Join-Path -Path $modulesPath -ChildPath "CacheManager.ps1"
. $cacheManagerPath

# Créer un répertoire pour les rapports
$reportsPath = Join-Path -Path $projectRoot -ChildPath "reports"
if (-not (Test-Path -Path $reportsPath)) {
    New-Item -Path $reportsPath -ItemType Directory -Force | Out-Null
}

# Fonction pour mesurer les performances
function Measure-Performance {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestName,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $false)]
        [int]$Iterations = 10
    )
    
    $results = @()
    
    for ($i = 1; $i -le $Iterations; $i++) {
        $startTime = Get-Date
        $result = & $ScriptBlock
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        $results += [PSCustomObject]@{
            TestName = $TestName
            Iteration = $i
            Duration = $duration
            Result = $result
        }
    }
    
    $avgDuration = ($results | Measure-Object -Property Duration -Average).Average
    $minDuration = ($results | Measure-Object -Property Duration -Minimum).Minimum
    $maxDuration = ($results | Measure-Object -Property Duration -Maximum).Maximum
    $stdDeviation = [Math]::Sqrt(($results | ForEach-Object { [Math]::Pow($_.Duration - $avgDuration, 2) } | Measure-Object -Average).Average)
    
    return [PSCustomObject]@{
        TestName = $TestName
        AverageDuration = $avgDuration
        MinDuration = $minDuration
        MaxDuration = $maxDuration
        StdDeviation = $stdDeviation
        Iterations = $Iterations
        Results = $results
    }
}

# Initialiser le gestionnaire de cache
Initialize-CacheManager -Enabled $true -MaxItems 1000 -DefaultTTL 3600 -EvictionPolicy "LRU"

# Test 1: Opération coûteuse sans cache
Write-Host "Test 1: Opération coûteuse sans cache..." -ForegroundColor Green

$expensiveOperation = {
    # Simuler une opération coûteuse
    Start-Sleep -Milliseconds 100
    return "Résultat de l'opération coûteuse"
}

$withoutCacheResults = Measure-Performance -TestName "Sans cache" -ScriptBlock {
    & $expensiveOperation
} -Iterations 10

# Test 2: Opération coûteuse avec cache
Write-Host "Test 2: Opération coûteuse avec cache..." -ForegroundColor Green

$withCacheResults = Measure-Performance -TestName "Avec cache" -ScriptBlock {
    $cacheKey = "ExpensiveOperation"
    $cachedResult = Get-CacheItem -Key $cacheKey
    
    if ($null -eq $cachedResult) {
        $result = & $expensiveOperation
        Set-CacheItem -Key $cacheKey -Value $result
        return $result
    }
    
    return $cachedResult
} -Iterations 10

# Test 3: Opération coûteuse avec Invoke-CachedFunction
Write-Host "Test 3: Opération coûteuse avec Invoke-CachedFunction..." -ForegroundColor Green

$withInvokeCachedResults = Measure-Performance -TestName "Avec Invoke-CachedFunction" -ScriptBlock {
    Invoke-CachedFunction -ScriptBlock $expensiveOperation -CacheKey "ExpensiveOperation2"
} -Iterations 10

# Test 4: Opération avec paramètres sans cache
Write-Host "Test 4: Opération avec paramètres sans cache..." -ForegroundColor Green

$parameterizedOperation = {
    param($a, $b)
    
    # Simuler une opération coûteuse
    Start-Sleep -Milliseconds 100
    return $a + $b
}

$withoutCacheParamResults = Measure-Performance -TestName "Sans cache (paramètres)" -ScriptBlock {
    & $parameterizedOperation 2 3
} -Iterations 10

# Test 5: Opération avec paramètres avec Invoke-CachedFunction
Write-Host "Test 5: Opération avec paramètres avec Invoke-CachedFunction..." -ForegroundColor Green

$withInvokeCachedParamResults = Measure-Performance -TestName "Avec Invoke-CachedFunction (paramètres)" -ScriptBlock {
    Invoke-CachedFunction -ScriptBlock $parameterizedOperation -CacheKey "ParameterizedOperation_2_3" -Arguments @(2, 3)
} -Iterations 10

# Afficher les résultats
Write-Host "`nRésultats des tests de performance :" -ForegroundColor Yellow

$allResults = @($withoutCacheResults, $withCacheResults, $withInvokeCachedResults, $withoutCacheParamResults, $withInvokeCachedParamResults)

$allResults | Format-Table -Property TestName, AverageDuration, MinDuration, MaxDuration, StdDeviation -AutoSize

# Calculer les gains de performance
$gainWithCache = ($withoutCacheResults.AverageDuration - $withCacheResults.AverageDuration) / $withoutCacheResults.AverageDuration * 100
$gainWithInvokeCached = ($withoutCacheResults.AverageDuration - $withInvokeCachedResults.AverageDuration) / $withoutCacheResults.AverageDuration * 100
$gainWithInvokeCachedParam = ($withoutCacheParamResults.AverageDuration - $withInvokeCachedParamResults.AverageDuration) / $withoutCacheParamResults.AverageDuration * 100

Write-Host "`nGains de performance :" -ForegroundColor Yellow
Write-Host "Gain avec cache : $([Math]::Round($gainWithCache, 2))%"
Write-Host "Gain avec Invoke-CachedFunction : $([Math]::Round($gainWithInvokeCached, 2))%"
Write-Host "Gain avec Invoke-CachedFunction (paramètres) : $([Math]::Round($gainWithInvokeCachedParam, 2))%"

# Enregistrer les résultats dans un fichier CSV
$csvPath = Join-Path -Path $reportsPath -ChildPath "CacheManager_Performance.csv"
$allResults | Select-Object -Property TestName, AverageDuration, MinDuration, MaxDuration, StdDeviation, Iterations | Export-Csv -Path $csvPath -NoTypeInformation

Write-Host "`nRésultats enregistrés dans : $csvPath" -ForegroundColor Green

# Enregistrer les statistiques du cache
$cacheStats = Get-CacheStatistics
$cacheStatsPath = Join-Path -Path $reportsPath -ChildPath "CacheManager_Statistics.json"
$cacheStats | ConvertTo-Json | Set-Content -Path $cacheStatsPath -Encoding UTF8

Write-Host "Statistiques du cache enregistrées dans : $cacheStatsPath" -ForegroundColor Green
