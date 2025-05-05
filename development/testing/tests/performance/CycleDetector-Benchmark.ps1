# Script de benchmark pour le module CycleDetector
# Ce script mesure les performances du module CycleDetector sur diffÃ©rentes tailles de graphes
# et gÃ©nÃ¨re un rapport de performance.

# Importer le module CycleDetector
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\CycleDetector.psm1"
Import-Module $modulePath -Force

# Fonction pour gÃ©nÃ©rer un graphe alÃ©atoire de taille spÃ©cifiÃ©e
function New-RandomGraph {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$NodeCount,
        
        [Parameter(Mandatory = $false)]
        [double]$EdgeDensity = 0.1,
        
        [Parameter(Mandatory = $false)]
        [switch]$WithCycle
    )
    
    $graph = @{}
    
    # CrÃ©er les nÅ“uds
    for ($i = 1; $i -le $NodeCount; $i++) {
        $graph["Node$i"] = @()
    }
    
    # Ajouter des arÃªtes alÃ©atoires
    $random = New-Object System.Random
    
    for ($i = 1; $i -le $NodeCount; $i++) {
        $edgeCount = [Math]::Ceiling($NodeCount * $EdgeDensity)
        
        for ($j = 1; $j -le $edgeCount; $j++) {
            $target = $random.Next(1, $NodeCount + 1)
            
            # Ã‰viter les boucles sur soi-mÃªme
            if ($target -ne $i) {
                $graph["Node$i"] += "Node$target"
            }
        }
    }
    
    # Ajouter un cycle si demandÃ©
    if ($WithCycle) {
        # CrÃ©er un cycle simple de longueur 3
        $startNode = "Node" + $random.Next(1, $NodeCount - 2)
        $middleNode = "Node" + ($random.Next(1, $NodeCount - 1))
        $endNode = "Node" + $random.Next(2, $NodeCount)
        
        # S'assurer que les nÅ“uds sont diffÃ©rents
        while ($middleNode -eq $startNode) {
            $middleNode = "Node" + ($random.Next(1, $NodeCount - 1))
        }
        
        while ($endNode -eq $startNode -or $endNode -eq $middleNode) {
            $endNode = "Node" + $random.Next(2, $NodeCount)
        }
        
        # Ajouter les arÃªtes pour former un cycle
        $graph[$startNode] = @($middleNode) + $graph[$startNode]
        $graph[$middleNode] = @($endNode) + $graph[$middleNode]
        $graph[$endNode] = @($startNode) + $graph[$endNode]
    }
    
    return $graph
}

# Fonction pour mesurer les performances
function Measure-CycleDetectorPerformance {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph,
        
        [Parameter(Mandatory = $false)]
        [int]$Iterations = 5
    )
    
    # RÃ©initialiser les statistiques
    Initialize-CycleDetector
    Clear-CycleDetectionCache
    
    $results = @{
        GraphSize = $Graph.Count
        TotalTime = 0
        AverageTime = 0
        MinTime = [double]::MaxValue
        MaxTime = 0
        HasCycle = $false
        MemoryUsage = 0
    }
    
    # Mesurer l'utilisation de la mÃ©moire avant
    $memoryBefore = [System.GC]::GetTotalMemory($true)
    
    # ExÃ©cuter plusieurs itÃ©rations pour obtenir des mesures plus prÃ©cises
    for ($i = 1; $i -le $Iterations; $i++) {
        $startTime = Get-Date
        
        # ExÃ©cuter la dÃ©tection de cycles
        $cycleResult = Find-Cycle -Graph $Graph
        
        $endTime = Get-Date
        $executionTime = ($endTime - $startTime).TotalMilliseconds
        
        # Mettre Ã  jour les rÃ©sultats
        $results.TotalTime += $executionTime
        $results.MinTime = [Math]::Min($results.MinTime, $executionTime)
        $results.MaxTime = [Math]::Max($results.MaxTime, $executionTime)
        $results.HasCycle = $cycleResult.HasCycle
    }
    
    # Mesurer l'utilisation de la mÃ©moire aprÃ¨s
    $memoryAfter = [System.GC]::GetTotalMemory($true)
    $results.MemoryUsage = ($memoryAfter - $memoryBefore) / 1MB
    
    # Calculer la moyenne
    $results.AverageTime = $results.TotalTime / $Iterations
    
    # RÃ©cupÃ©rer les statistiques du cache
    $cacheStats = Get-CycleDetectionStatistics
    $results.CacheHits = $cacheStats.CacheHits
    $results.CacheMisses = $cacheStats.CacheMisses
    
    return [PSCustomObject]$results
}

# Fonction pour exÃ©cuter le benchmark complet
function Start-CycleDetectorBenchmark {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "benchmark_results.csv"
    )
    
    $graphSizes = @(10, 50, 100, 500, 1000, 5000)
    $edgeDensities = @(0.01, 0.05, 0.1, 0.2)
    $results = @()
    
    Write-Host "DÃ©marrage du benchmark CycleDetector..."
    
    foreach ($size in $graphSizes) {
        foreach ($density in $edgeDensities) {
            Write-Host "Benchmark pour graphe de taille $size avec densitÃ© $density..."
            
            # Graphe sans cycle
            Write-Host "  - Graphe sans cycle..."
            $graph = New-RandomGraph -NodeCount $size -EdgeDensity $density
            $result = Measure-CycleDetectorPerformance -Graph $graph
            $result | Add-Member -MemberType NoteProperty -Name "EdgeDensity" -Value $density
            $result | Add-Member -MemberType NoteProperty -Name "WithCycle" -Value $false
            $results += $result
            
            # Graphe avec cycle
            Write-Host "  - Graphe avec cycle..."
            $graph = New-RandomGraph -NodeCount $size -EdgeDensity $density -WithCycle
            $result = Measure-CycleDetectorPerformance -Graph $graph
            $result | Add-Member -MemberType NoteProperty -Name "EdgeDensity" -Value $density
            $result | Add-Member -MemberType NoteProperty -Name "WithCycle" -Value $true
            $results += $result
        }
    }
    
    # Exporter les rÃ©sultats en CSV
    $results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    
    Write-Host "Benchmark terminÃ©. RÃ©sultats exportÃ©s dans $OutputPath"
    
    # Afficher un rÃ©sumÃ© des rÃ©sultats
    Write-Host "`nRÃ©sumÃ© des rÃ©sultats :"
    Write-Host "======================"
    
    $summary = $results | Group-Object -Property GraphSize | ForEach-Object {
        $group = $_
        $avgTime = ($group.Group | Measure-Object -Property AverageTime -Average).Average
        $avgMemory = ($group.Group | Measure-Object -Property MemoryUsage -Average).Average
        
        [PSCustomObject]@{
            GraphSize = $group.Name
            AverageTime = [Math]::Round($avgTime, 2)
            AverageMemory = [Math]::Round($avgMemory, 2)
        }
    }
    
    $summary | Format-Table -AutoSize
    
    return $results
}

# ExÃ©cuter le benchmark
$benchmarkResults = Start-CycleDetectorBenchmark -OutputPath "benchmark_results.csv"
