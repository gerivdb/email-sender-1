#Requires -Version 5.1
<#
.SYNOPSIS
    Teste la validitÃ© du cache d'analyse des pull requests.

.DESCRIPTION
    Ce script vÃ©rifie la validitÃ© et l'intÃ©gritÃ© du cache utilisÃ© pour
    l'analyse des pull requests, en effectuant une sÃ©rie de tests.

.PARAMETER CachePath
    Le chemin du cache Ã  tester.
    Par dÃ©faut: "cache\pr-analysis"

.PARAMETER TestCount
    Le nombre de tests Ã  effectuer.
    Par dÃ©faut: 10

.PARAMETER TestDataSize
    La taille approximative des donnÃ©es de test en Ko.
    Par dÃ©faut: 10

.PARAMETER DetailedReport
    Indique s'il faut gÃ©nÃ©rer un rapport dÃ©taillÃ©.
    Par dÃ©faut: $false

.EXAMPLE
    .\Test-PRCacheValidity.ps1
    Teste le cache avec les paramÃ¨tres par dÃ©faut.

.EXAMPLE
    .\Test-PRCacheValidity.ps1 -CachePath "D:\Cache\PR" -TestCount 50 -TestDataSize 100 -DetailedReport
    Teste le cache avec des paramÃ¨tres personnalisÃ©s et gÃ©nÃ¨re un rapport dÃ©taillÃ©.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$CachePath = "cache\pr-analysis",

    [Parameter()]
    [int]$TestCount = 10,

    [Parameter()]
    [int]$TestDataSize = 10, # Ko

    [Parameter()]
    [switch]$DetailedReport
)

# Importer le module de cache
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "modules\PRAnalysisCache.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Error "Module PRAnalysisCache non trouvÃ© Ã  l'emplacement: $modulePath"
    exit 1
}

# Fonction pour gÃ©nÃ©rer des donnÃ©es de test
function New-TestData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$SizeKB
    )

    try {
        # GÃ©nÃ©rer une chaÃ®ne alÃ©atoire de la taille spÃ©cifiÃ©e
        $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        $random = New-Object System.Random
        $result = ""
        
        # 1 Ko = environ 1024 caractÃ¨res
        $charCount = $SizeKB * 1024
        
        for ($i = 0; $i -lt $charCount; $i++) {
            $result += $chars[$random.Next(0, $chars.Length)]
        }
        
        return $result
    } catch {
        Write-Error "Erreur lors de la gÃ©nÃ©ration des donnÃ©es de test: $_"
        return $null
    }
}

# Fonction pour tester les opÃ©rations de base du cache
function Test-BasicCacheOperations {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Cache,
        
        [Parameter(Mandatory = $true)]
        [int]$Count,
        
        [Parameter(Mandatory = $true)]
        [int]$DataSizeKB
    )

    try {
        $results = @{
            SetSuccess = 0
            SetFailure = 0
            GetSuccess = 0
            GetFailure = 0
            RemoveSuccess = 0
            RemoveFailure = 0
            DataIntegritySuccess = 0
            DataIntegrityFailure = 0
            TestData = @()
        }
        
        Write-Host "ExÃ©cution de $Count tests avec des donnÃ©es de $DataSizeKB Ko..." -ForegroundColor Cyan
        
        for ($i = 1; $i -le $Count; $i++) {
            $testKey = "TestKey_$i"
            $testData = New-TestData -SizeKB $DataSizeKB
            
            if ($null -eq $testData) {
                $results.SetFailure++
                continue
            }
            
            # Test 1: Set
            try {
                $Cache.Set($testKey, $testData)
                $results.SetSuccess++
                
                if ($DetailedReport) {
                    $results.TestData += [PSCustomObject]@{
                        Key = $testKey
                        Operation = "Set"
                        Success = $true
                        Error = $null
                    }
                }
            } catch {
                $results.SetFailure++
                
                if ($DetailedReport) {
                    $results.TestData += [PSCustomObject]@{
                        Key = $testKey
                        Operation = "Set"
                        Success = $false
                        Error = $_.Exception.Message
                    }
                }
                
                continue
            }
            
            # Test 2: Get
            try {
                $retrievedData = $Cache.Get($testKey)
                
                if ($null -ne $retrievedData) {
                    $results.GetSuccess++
                    
                    if ($DetailedReport) {
                        $results.TestData += [PSCustomObject]@{
                            Key = $testKey
                            Operation = "Get"
                            Success = $true
                            Error = $null
                        }
                    }
                } else {
                    $results.GetFailure++
                    
                    if ($DetailedReport) {
                        $results.TestData += [PSCustomObject]@{
                            Key = $testKey
                            Operation = "Get"
                            Success = $false
                            Error = "DonnÃ©es non trouvÃ©es dans le cache"
                        }
                    }
                    
                    continue
                }
            } catch {
                $results.GetFailure++
                
                if ($DetailedReport) {
                    $results.TestData += [PSCustomObject]@{
                        Key = $testKey
                        Operation = "Get"
                        Success = $false
                        Error = $_.Exception.Message
                    }
                }
                
                continue
            }
            
            # Test 3: IntÃ©gritÃ© des donnÃ©es
            if ($retrievedData -eq $testData) {
                $results.DataIntegritySuccess++
                
                if ($DetailedReport) {
                    $results.TestData += [PSCustomObject]@{
                        Key = $testKey
                        Operation = "DataIntegrity"
                        Success = $true
                        Error = $null
                    }
                }
            } else {
                $results.DataIntegrityFailure++
                
                if ($DetailedReport) {
                    $results.TestData += [PSCustomObject]@{
                        Key = $testKey
                        Operation = "DataIntegrity"
                        Success = $false
                        Error = "Les donnÃ©es rÃ©cupÃ©rÃ©es ne correspondent pas aux donnÃ©es stockÃ©es"
                    }
                }
            }
            
            # Test 4: Remove
            try {
                $Cache.Remove($testKey)
                $results.RemoveSuccess++
                
                if ($DetailedReport) {
                    $results.TestData += [PSCustomObject]@{
                        Key = $testKey
                        Operation = "Remove"
                        Success = $true
                        Error = $null
                    }
                }
            } catch {
                $results.RemoveFailure++
                
                if ($DetailedReport) {
                    $results.TestData += [PSCustomObject]@{
                        Key = $testKey
                        Operation = "Remove"
                        Success = $false
                        Error = $_.Exception.Message
                    }
                }
            }
            
            # VÃ©rifier que l'Ã©lÃ©ment a bien Ã©tÃ© supprimÃ©
            $verifyRemoved = $Cache.Get($testKey)
            if ($null -ne $verifyRemoved) {
                $results.RemoveFailure++
                
                if ($DetailedReport) {
                    $results.TestData += [PSCustomObject]@{
                        Key = $testKey
                        Operation = "VerifyRemove"
                        Success = $false
                        Error = "L'Ã©lÃ©ment n'a pas Ã©tÃ© correctement supprimÃ© du cache"
                    }
                }
            }
            
            # Afficher la progression
            Write-Progress -Activity "Test du cache" -Status "Test $i/$Count" -PercentComplete (($i / $Count) * 100)
        }
        
        Write-Progress -Activity "Test du cache" -Completed
        
        return $results
    } catch {
        Write-Error "Erreur lors du test des opÃ©rations de base du cache: $_"
        return $null
    }
}

# Fonction pour tester les performances du cache
function Test-CachePerformance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Cache,
        
        [Parameter(Mandatory = $true)]
        [int]$Count,
        
        [Parameter(Mandatory = $true)]
        [int]$DataSizeKB
    )

    try {
        $results = @{
            SetTimes = @()
            GetTimes = @()
            RemoveTimes = @()
        }
        
        Write-Host "Test des performances du cache..." -ForegroundColor Cyan
        
        for ($i = 1; $i -le $Count; $i++) {
            $testKey = "PerfTestKey_$i"
            $testData = New-TestData -SizeKB $DataSizeKB
            
            if ($null -eq $testData) {
                continue
            }
            
            # Mesurer le temps de Set
            $setStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $Cache.Set($testKey, $testData)
            $setStopwatch.Stop()
            $results.SetTimes += $setStopwatch.ElapsedMilliseconds
            
            # Mesurer le temps de Get
            $getStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $Cache.Get($testKey)
            $getStopwatch.Stop()
            $results.GetTimes += $getStopwatch.ElapsedMilliseconds
            
            # Mesurer le temps de Remove
            $removeStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $Cache.Remove($testKey)
            $removeStopwatch.Stop()
            $results.RemoveTimes += $removeStopwatch.ElapsedMilliseconds
            
            # Afficher la progression
            Write-Progress -Activity "Test des performances du cache" -Status "Test $i/$Count" -PercentComplete (($i / $Count) * 100)
        }
        
        Write-Progress -Activity "Test des performances du cache" -Completed
        
        # Calculer les statistiques
        $results.SetAvgMs = ($results.SetTimes | Measure-Object -Average).Average
        $results.GetAvgMs = ($results.GetTimes | Measure-Object -Average).Average
        $results.RemoveAvgMs = ($results.RemoveTimes | Measure-Object -Average).Average
        
        $results.SetMaxMs = ($results.SetTimes | Measure-Object -Maximum).Maximum
        $results.GetMaxMs = ($results.GetTimes | Measure-Object -Maximum).Maximum
        $results.RemoveMaxMs = ($results.RemoveTimes | Measure-Object -Maximum).Maximum
        
        return $results
    } catch {
        Write-Error "Erreur lors du test des performances du cache: $_"
        return $null
    }
}

# Fonction pour gÃ©nÃ©rer un rapport
function New-CacheValidityReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$BasicResults,
        
        [Parameter(Mandatory = $true)]
        [object]$PerformanceResults,
        
        [Parameter(Mandatory = $true)]
        [object]$Cache,
        
        [Parameter(Mandatory = $true)]
        [string]$CachePath,
        
        [Parameter(Mandatory = $true)]
        [bool]$Detailed
    )

    try {
        $report = [PSCustomObject]@{
            Timestamp = Get-Date
            CachePath = $CachePath
            CacheStats = $Cache.GetStats()
            BasicTests = [PSCustomObject]@{
                SetSuccess = $BasicResults.SetSuccess
                SetFailure = $BasicResults.SetFailure
                GetSuccess = $BasicResults.GetSuccess
                GetFailure = $BasicResults.GetFailure
                RemoveSuccess = $BasicResults.RemoveSuccess
                RemoveFailure = $BasicResults.RemoveFailure
                DataIntegritySuccess = $BasicResults.DataIntegritySuccess
                DataIntegrityFailure = $BasicResults.DataIntegrityFailure
                SuccessRate = if (($BasicResults.SetSuccess + $BasicResults.SetFailure) -gt 0) {
                    [Math]::Round(($BasicResults.SetSuccess / ($BasicResults.SetSuccess + $BasicResults.SetFailure)) * 100, 2)
                } else { 0 }
            }
            PerformanceTests = [PSCustomObject]@{
                SetAvgMs = [Math]::Round($PerformanceResults.SetAvgMs, 2)
                GetAvgMs = [Math]::Round($PerformanceResults.GetAvgMs, 2)
                RemoveAvgMs = [Math]::Round($PerformanceResults.RemoveAvgMs, 2)
                SetMaxMs = $PerformanceResults.SetMaxMs
                GetMaxMs = $PerformanceResults.GetMaxMs
                RemoveMaxMs = $PerformanceResults.RemoveMaxMs
            }
            Recommendations = @()
        }
        
        # Ajouter les dÃ©tails des tests si demandÃ©
        if ($Detailed) {
            $report | Add-Member -MemberType NoteProperty -Name "TestDetails" -Value $BasicResults.TestData
        }
        
        # GÃ©nÃ©rer des recommandations
        if ($report.BasicTests.SuccessRate -lt 100) {
            $report.Recommendations += "Le taux de rÃ©ussite des opÃ©rations de base est infÃ©rieur Ã  100%. VÃ©rifiez les erreurs dÃ©taillÃ©es et envisagez de rÃ©initialiser le cache."
        }
        
        if ($report.BasicTests.DataIntegrityFailure -gt 0) {
            $report.Recommendations += "Des problÃ¨mes d'intÃ©gritÃ© des donnÃ©es ont Ã©tÃ© dÃ©tectÃ©s. Le cache pourrait Ãªtre corrompu. Envisagez de le rÃ©initialiser."
        }
        
        if ($report.PerformanceTests.GetAvgMs -gt 50) {
            $report.Recommendations += "Les temps d'accÃ¨s au cache sont Ã©levÃ©s. Envisagez d'optimiser la configuration du cache ou de vÃ©rifier les performances du stockage."
        }
        
        return $report
    } catch {
        Write-Error "Erreur lors de la gÃ©nÃ©ration du rapport: $_"
        return $null
    }
}

# Point d'entrÃ©e principal
try {
    # RÃ©soudre le chemin complet du cache
    $fullCachePath = $CachePath
    if (-not [System.IO.Path]::IsPathRooted($CachePath)) {
        $fullCachePath = Join-Path -Path $PWD -ChildPath $CachePath
    }

    # VÃ©rifier si le cache existe
    if (-not (Test-Path -Path $fullCachePath)) {
        Write-Error "Le rÃ©pertoire du cache n'existe pas: $fullCachePath"
        exit 1
    }

    # CrÃ©er le cache
    $cache = New-PRAnalysisCache -Name "PRAnalysisCache" -CachePath $fullCachePath
    if ($null -eq $cache) {
        Write-Error "Impossible de crÃ©er le cache."
        exit 1
    }

    # Tester les opÃ©rations de base
    $basicResults = Test-BasicCacheOperations -Cache $cache -Count $TestCount -DataSizeKB $TestDataSize
    if ($null -eq $basicResults) {
        Write-Error "Ã‰chec des tests d'opÃ©rations de base."
        exit 1
    }

    # Tester les performances
    $performanceResults = Test-CachePerformance -Cache $cache -Count $TestCount -DataSizeKB $TestDataSize
    if ($null -eq $performanceResults) {
        Write-Error "Ã‰chec des tests de performance."
        exit 1
    }

    # GÃ©nÃ©rer le rapport
    $report = New-CacheValidityReport -BasicResults $basicResults -PerformanceResults $performanceResults -Cache $cache -CachePath $fullCachePath -Detailed $DetailedReport.IsPresent
    if ($null -eq $report) {
        Write-Error "Ã‰chec de la gÃ©nÃ©ration du rapport."
        exit 1
    }

    # Afficher un rÃ©sumÃ©
    Write-Host "`nRÃ©sumÃ© des tests de validitÃ© du cache:" -ForegroundColor Cyan
    Write-Host "  Chemin du cache: $fullCachePath" -ForegroundColor White
    Write-Host "  Taux de rÃ©ussite: $($report.BasicTests.SuccessRate)%" -ForegroundColor White
    Write-Host "  Temps moyen de Get: $($report.PerformanceTests.GetAvgMs) ms" -ForegroundColor White
    Write-Host "  Temps moyen de Set: $($report.PerformanceTests.SetAvgMs) ms" -ForegroundColor White
    Write-Host "  Temps moyen de Remove: $($report.PerformanceTests.RemoveAvgMs) ms" -ForegroundColor White
    
    if ($report.Recommendations.Count -gt 0) {
        Write-Host "`nRecommandations:" -ForegroundColor Yellow
        foreach ($recommendation in $report.Recommendations) {
            Write-Host "  - $recommendation" -ForegroundColor Yellow
        }
    }
    
    # Retourner le rapport
    return $report
} catch {
    Write-Error "Erreur lors du test de validitÃ© du cache: $_"
    exit 1
}
