#Requires -Version 5.1
<#
.SYNOPSIS
    Benchmark de performance pour les modules du projet.
.DESCRIPTION
    Ce script exécute des benchmarks de performance pour les différents modules du projet.
.PARAMETER ModulesToTest
    Liste des modules à tester.
.PARAMETER Iterations
    Nombre d'itérations pour chaque test.
.PARAMETER OutputPath
    Chemin du fichier de sortie pour les résultats.
.EXAMPLE
    .\PerformanceBenchmark.ps1 -ModulesToTest @("CycleDetector", "InputSegmentation", "PredictiveCache", "ParallelProcessing") -Iterations 5
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-17
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string[]]$ModulesToTest = @("CycleDetector", "InputSegmentation", "PredictiveCache", "ParallelProcessing"),
    
    [Parameter(Mandatory = $false)]
    [int]$Iterations = 5,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\reports\performance\benchmark_results.json"
)

# Fonction pour mesurer les performances
function Measure-Performance {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $false)]
        [int]$Iterations = 5
    )
    
    $results = @()
    
    for ($i = 0; $i -lt $Iterations; $i++) {
        $process = Get-Process -Id $PID
        $startMemory = $process.WorkingSet64
        
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $result = & $ScriptBlock
        $stopwatch.Stop()
        
        $process = Get-Process -Id $PID
        $endMemory = $process.WorkingSet64
        
        $results += [PSCustomObject]@{
            Iteration = $i + 1
            ExecutionTimeMs = $stopwatch.ElapsedMilliseconds
            MemoryUsageBytes = $endMemory - $startMemory
            Result = $result
        }
    }
    
    $avgTime = ($results | Measure-Object -Property ExecutionTimeMs -Average).Average
    $minTime = ($results | Measure-Object -Property ExecutionTimeMs -Minimum).Minimum
    $maxTime = ($results | Measure-Object -Property ExecutionTimeMs -Maximum).Maximum
    
    $avgMemory = ($results | Measure-Object -Property MemoryUsageBytes -Average).Average
    
    return [PSCustomObject]@{
        Iterations = $Iterations
        Results = $results
        Statistics = [PSCustomObject]@{
            AvgExecutionTimeMs = $avgTime
            MinExecutionTimeMs = $minTime
            MaxExecutionTimeMs = $maxTime
            AvgMemoryUsageBytes = $avgMemory
        }
    }
}

# Créer le dossier de sortie s'il n'existe pas
$outputDir = Split-Path -Path $OutputPath -Parent
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Résultats globaux
$benchmarkResults = @{}

# Tests pour CycleDetector
if ($ModulesToTest -contains "CycleDetector") {
    Write-Host "Exécution des benchmarks pour CycleDetector..." -ForegroundColor Cyan
    
    # Importer le module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\CycleDetector.psm1"
    Import-Module $modulePath -Force
    
    # Test 1: Détection de cycles dans un petit graphe
    $smallGraph = @{
        "A" = @("B", "C")
        "B" = @("D")
        "C" = @("E")
        "D" = @("F")
        "E" = @("D")
        "F" = @()
    }
    
    $smallGraphTest = Measure-Performance -ScriptBlock {
        Detect-Cycle -Graph $smallGraph
    } -Iterations $Iterations
    
    # Test 2: Détection de cycles dans un graphe moyen
    $mediumGraph = @{}
    for ($i = 0; $i -lt 100; $i++) {
        $connections = @()
        for ($j = 0; $j -lt 5; $j++) {
            $connections += "Node$([Math]::Min(($i + $j + 1) % 100, 99))"
        }
        $mediumGraph["Node$i"] = $connections
    }
    
    $mediumGraphTest = Measure-Performance -ScriptBlock {
        Detect-Cycle -Graph $mediumGraph
    } -Iterations $Iterations
    
    # Test 3: Détection de cycles dans un grand graphe
    $largeGraph = @{}
    for ($i = 0; $i -lt 1000; $i++) {
        $connections = @()
        for ($j = 0; $j -lt 5; $j++) {
            $connections += "Node$([Math]::Min(($i + $j + 1) % 1000, 999))"
        }
        $largeGraph["Node$i"] = $connections
    }
    
    $largeGraphTest = Measure-Performance -ScriptBlock {
        Detect-Cycle -Graph $largeGraph
    } -Iterations $Iterations
    
    $benchmarkResults.CycleDetector = [PSCustomObject]@{
        SmallGraph = $smallGraphTest
        MediumGraph = $mediumGraphTest
        LargeGraph = $largeGraphTest
    }
}

# Tests pour InputSegmentation
if ($ModulesToTest -contains "InputSegmentation") {
    Write-Host "Exécution des benchmarks pour InputSegmentation..." -ForegroundColor Cyan
    
    # Importer le module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\InputSegmentation.psm1"
    Import-Module $modulePath -Force
    
    # Initialiser le module
    Initialize-InputSegmentation -MaxInputSizeKB 10 -DefaultChunkSizeKB 5
    
    # Test 1: Segmentation d'un petit texte
    $smallText = "A" * 5KB
    
    $smallTextTest = Measure-Performance -ScriptBlock {
        Split-TextInput -Text $smallText -ChunkSizeKB 2
    } -Iterations $Iterations
    
    # Test 2: Segmentation d'un texte moyen
    $mediumText = "A" * 20KB
    
    $mediumTextTest = Measure-Performance -ScriptBlock {
        Split-TextInput -Text $mediumText -ChunkSizeKB 5
    } -Iterations $Iterations
    
    # Test 3: Segmentation d'un grand texte
    $largeText = "A" * 100KB
    
    $largeTextTest = Measure-Performance -ScriptBlock {
        Split-TextInput -Text $largeText -ChunkSizeKB 10
    } -Iterations $Iterations
    
    $benchmarkResults.InputSegmentation = [PSCustomObject]@{
        SmallText = $smallTextTest
        MediumText = $mediumTextTest
        LargeText = $largeTextTest
    }
}

# Tests pour PredictiveCache
if ($ModulesToTest -contains "PredictiveCache") {
    Write-Host "Exécution des benchmarks pour PredictiveCache..." -ForegroundColor Cyan
    
    # Importer le module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\PredictiveCache.psm1"
    Import-Module $modulePath -Force
    
    # Créer des dossiers temporaires
    $tempCachePath = Join-Path -Path $env:TEMP -ChildPath "cache_benchmark"
    $tempModelPath = Join-Path -Path $env:TEMP -ChildPath "model_benchmark"
    
    if (-not (Test-Path -Path $tempCachePath)) {
        New-Item -Path $tempCachePath -ItemType Directory -Force | Out-Null
    }
    
    if (-not (Test-Path -Path $tempModelPath)) {
        New-Item -Path $tempModelPath -ItemType Directory -Force | Out-Null
    }
    
    # Initialiser le module
    Initialize-PredictiveCache -Enabled $true -CachePath $tempCachePath -ModelPath $tempModelPath -MaxCacheSize 10MB -DefaultTTL 3600
    
    # Test 1: Mise en cache de petites valeurs
    $smallCacheTest = Measure-Performance -ScriptBlock {
        for ($i = 0; $i -lt 100; $i++) {
            Set-PredictiveCache -Key "small-key-$i" -Value "small-value-$i"
        }
    } -Iterations $Iterations
    
    # Test 2: Mise en cache de valeurs moyennes
    $mediumCacheTest = Measure-Performance -ScriptBlock {
        for ($i = 0; $i -lt 100; $i++) {
            $value = @{
                id = $i
                name = "Item $i"
                properties = @{
                    prop1 = "Value 1"
                    prop2 = "Value 2"
                }
            }
            Set-PredictiveCache -Key "medium-key-$i" -Value $value
        }
    } -Iterations $Iterations
    
    # Test 3: Récupération de valeurs
    $getCacheTest = Measure-Performance -ScriptBlock {
        for ($i = 0; $i -lt 100; $i++) {
            $value = Get-PredictiveCache -Key "medium-key-$i"
        }
    } -Iterations $Iterations
    
    # Test 4: Prédiction de clés
    $predictCacheTest = Measure-Performance -ScriptBlock {
        for ($i = 0; $i -lt 10; $i++) {
            Register-CacheAccess -Key "seq-key-1" -WorkflowId "test-workflow" -NodeId "test-node"
            Register-CacheAccess -Key "seq-key-2" -WorkflowId "test-workflow" -NodeId "test-node"
            Register-CacheAccess -Key "seq-key-3" -WorkflowId "test-workflow" -NodeId "test-node"
        }
        
        Get-PredictedCacheKeys -Key "seq-key-1" -WorkflowId "test-workflow" -NodeId "test-node"
    } -Iterations $Iterations
    
    $benchmarkResults.PredictiveCache = [PSCustomObject]@{
        SmallCache = $smallCacheTest
        MediumCache = $mediumCacheTest
        GetCache = $getCacheTest
        PredictCache = $predictCacheTest
    }
}

# Tests pour ParallelProcessing
if ($ModulesToTest -contains "ParallelProcessing") {
    Write-Host "Exécution des benchmarks pour ParallelProcessing..." -ForegroundColor Cyan
    
    # Importer le script
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\development\scripts\performance\Optimize-ParallelExecution.ps1"
    . $scriptPath
    
    # Fonction de test
    function Test-Function {
        param($item)
        Start-Sleep -Milliseconds 10
        return $item * 2
    }
    
    # Test 1: Traitement séquentiel
    $sequentialTest = Measure-Performance -ScriptBlock {
        $data = 1..20
        Invoke-SequentialProcessing -Data $data -ScriptBlock ${function:Test-Function}
    } -Iterations $Iterations
    
    # Test 2: Traitement parallèle avec Runspace Pools
    $runspaceTest = Measure-Performance -ScriptBlock {
        $data = 1..20
        Invoke-RunspacePoolProcessing -Data $data -ScriptBlock ${function:Test-Function} -MaxThreads 4
    } -Iterations $Iterations
    
    # Test 3: Traitement parallèle par lots
    $batchTest = Measure-Performance -ScriptBlock {
        $data = 1..20
        Invoke-BatchParallelProcessing -Data $data -ScriptBlock ${function:Test-Function} -MaxThreads 4 -ChunkSize 5
    } -Iterations $Iterations
    
    # Test 4: Optimisation automatique
    $optimizeTest = Measure-Performance -ScriptBlock {
        $data = 1..20
        Optimize-ParallelExecution -Data $data -ScriptBlock ${function:Test-Function} -MaxThreads 4 -ChunkSize 5 -Measure
    } -Iterations $Iterations
    
    $benchmarkResults.ParallelProcessing = [PSCustomObject]@{
        Sequential = $sequentialTest
        Runspace = $runspaceTest
        Batch = $batchTest
        Optimize = $optimizeTest
    }
}

# Enregistrer les résultats
$benchmarkResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host "Benchmarks terminés. Résultats enregistrés dans $OutputPath" -ForegroundColor Green

# Afficher un résumé
Write-Host "`nRésumé des performances:" -ForegroundColor Cyan

foreach ($module in $benchmarkResults.Keys) {
    Write-Host "`n$module:" -ForegroundColor Yellow
    
    $moduleResults = $benchmarkResults.$module
    
    foreach ($test in $moduleResults.PSObject.Properties.Name) {
        $testResult = $moduleResults.$test
        $avgTime = $testResult.Statistics.AvgExecutionTimeMs
        
        Write-Host "  $test : $avgTime ms" -ForegroundColor White
    }
}
