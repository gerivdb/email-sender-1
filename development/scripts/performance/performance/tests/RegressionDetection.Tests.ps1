Describe "Tests de dÃ©tection de rÃ©gression de performance" {
    Context "Comparaison avec les performances de rÃ©fÃ©rence" {
        BeforeAll {
            # Fonction pour mesurer les performances d'une fonction
            function Measure-FunctionPerformance {
                param (
                    [Parameter(Mandatory = $true)]
                    [string]$Name,
                    
                    [Parameter(Mandatory = $true)]
                    [scriptblock]$ScriptBlock,
                    
                    [Parameter(Mandatory = $false)]
                    [hashtable]$Parameters = @{},
                    
                    [Parameter(Mandatory = $false)]
                    [int]$Iterations = 5,
                    
                    [Parameter(Mandatory = $false)]
                    [int]$WarmupIterations = 1
                )
                
                # ExÃ©cuter des itÃ©rations de prÃ©chauffage pour Ã©viter les biais de dÃ©marrage Ã  froid
                for ($i = 1; $i -le $WarmupIterations; $i++) {
                    & $ScriptBlock @Parameters | Out-Null
                }
                
                $results = @()
                
                # ExÃ©cuter les itÃ©rations de mesure
                for ($i = 1; $i -le $Iterations; $i++) {
                    # Nettoyer la mÃ©moire avant chaque test
                    [System.GC]::Collect()
                    
                    # Mesurer le temps d'exÃ©cution
                    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                    
                    try {
                        # ExÃ©cuter la fonction
                        $result = & $ScriptBlock @Parameters
                        $success = $true
                    }
                    catch {
                        Write-Error "Erreur lors de l'exÃ©cution de '$Name' : $_"
                        $success = $false
                        $result = $null
                    }
                    
                    $stopwatch.Stop()
                    $executionTime = $stopwatch.Elapsed.TotalMilliseconds
                    
                    # Enregistrer les rÃ©sultats
                    $results += [PSCustomObject]@{
                        Iteration = $i
                        ExecutionTimeMs = $executionTime
                        Success = $success
                    }
                }
                
                # Calculer les statistiques
                $avgExecutionTime = ($results | Measure-Object -Property ExecutionTimeMs -Average).Average
                $minExecutionTime = ($results | Measure-Object -Property ExecutionTimeMs -Minimum).Minimum
                $maxExecutionTime = ($results | Measure-Object -Property ExecutionTimeMs -Maximum).Maximum
                $stdDevExecutionTime = [Math]::Sqrt(($results | ForEach-Object { [Math]::Pow($_.ExecutionTimeMs - $avgExecutionTime, 2) } | Measure-Object -Average).Average)
                $successRate = ($results | Where-Object { $_.Success } | Measure-Object).Count / $Iterations * 100
                
                return [PSCustomObject]@{
                    Name = $Name
                    AverageExecutionTimeMs = $avgExecutionTime
                    MinExecutionTimeMs = $minExecutionTime
                    MaxExecutionTimeMs = $maxExecutionTime
                    StdDevExecutionTimeMs = $stdDevExecutionTime
                    SuccessRate = $successRate
                    DetailedResults = $results
                }
            }
            
            # Fonction pour sauvegarder les performances de rÃ©fÃ©rence
            function Save-BaselinePerformance {
                param (
                    [Parameter(Mandatory = $true)]
                    [PSCustomObject]$PerformanceResult,
                    
                    [Parameter(Mandatory = $true)]
                    [string]$BaselinePath
                )
                
                # CrÃ©er le rÃ©pertoire parent s'il n'existe pas
                $parentDir = Split-Path -Path $BaselinePath -Parent
                if (-not (Test-Path -Path $parentDir -PathType Container)) {
                    New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
                }
                
                # Sauvegarder les performances de rÃ©fÃ©rence
                $baselineData = [PSCustomObject]@{
                    Name = $PerformanceResult.Name
                    AverageExecutionTimeMs = $PerformanceResult.AverageExecutionTimeMs
                    MinExecutionTimeMs = $PerformanceResult.MinExecutionTimeMs
                    MaxExecutionTimeMs = $PerformanceResult.MaxExecutionTimeMs
                    StdDevExecutionTimeMs = $PerformanceResult.StdDevExecutionTimeMs
                    SuccessRate = $PerformanceResult.SuccessRate
                    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                }
                
                $baselineData | ConvertTo-Json | Out-File -FilePath $BaselinePath -Encoding utf8
            }
            
            # Fonction pour charger les performances de rÃ©fÃ©rence
            function Import-BaselinePerformance {
                param (
                    [Parameter(Mandatory = $true)]
                    [string]$BaselinePath
                )
                
                if (Test-Path -Path $BaselinePath -PathType Leaf) {
                    $baselineData = Get-Content -Path $BaselinePath -Raw | ConvertFrom-Json
                    return $baselineData
                }
                
                return $null
            }
            
            # Fonction pour comparer les performances actuelles avec les performances de rÃ©fÃ©rence
            function Compare-WithBaseline {
                param (
                    [Parameter(Mandatory = $true)]
                    [PSCustomObject]$CurrentPerformance,
                    
                    [Parameter(Mandatory = $true)]
                    [PSCustomObject]$BaselinePerformance,
                    
                    [Parameter(Mandatory = $false)]
                    [double]$RegressionThresholdPercent = 10
                )
                
                $timeChange = ($CurrentPerformance.AverageExecutionTimeMs - $BaselinePerformance.AverageExecutionTimeMs) / $BaselinePerformance.AverageExecutionTimeMs * 100
                $isRegression = $timeChange -gt $RegressionThresholdPercent
                
                return [PSCustomObject]@{
                    Name = $CurrentPerformance.Name
                    CurrentAverageTimeMs = $CurrentPerformance.AverageExecutionTimeMs
                    BaselineAverageTimeMs = $BaselinePerformance.AverageExecutionTimeMs
                    ChangePercent = $timeChange
                    IsRegression = $isRegression
                    RegressionThresholdPercent = $RegressionThresholdPercent
                }
            }
            
            # CrÃ©er des fonctions de test
            $sortFunction = {
                param($size = 1000)
                $data = 1..$size | ForEach-Object { Get-Random }
                return $data | Sort-Object
            }
            
            $filterFunction = {
                param($size = 1000)
                $data = 1..$size | ForEach-Object { Get-Random -Minimum 1 -Maximum 1000 }
                return $data | Where-Object { $_ -gt 500 }
            }
            
            $aggregateFunction = {
                param($size = 1000)
                $data = 1..$size | ForEach-Object { 
                    [PSCustomObject]@{
                        Value = Get-Random -Minimum 1 -Maximum 1000
                        Category = "Category" + (Get-Random -Minimum 1 -Maximum 5)
                    }
                }
                return $data | Group-Object -Property Category | ForEach-Object {
                    [PSCustomObject]@{
                        Category = $_.Name
                        Count = $_.Count
                        Average = ($_.Group | Measure-Object -Property Value -Average).Average
                    }
                }
            }
            
            # DÃ©finir le rÃ©pertoire des performances de rÃ©fÃ©rence
            $baselineDir = Join-Path -Path $TestDrive -ChildPath "Baselines"
            New-Item -Path $baselineDir -ItemType Directory -Force | Out-Null
            
            # DÃ©finir les chemins des fichiers de rÃ©fÃ©rence
            $sortBaselinePath = Join-Path -Path $baselineDir -ChildPath "sort_baseline.json"
            $filterBaselinePath = Join-Path -Path $baselineDir -ChildPath "filter_baseline.json"
            $aggregateBaselinePath = Join-Path -Path $baselineDir -ChildPath "aggregate_baseline.json"
        }
        
        It "DÃ©tecte les rÃ©gressions de performance pour le tri" {
            # Mesurer les performances actuelles
            $currentPerformance = Measure-FunctionPerformance -Name "Tri" -ScriptBlock $sortFunction -Iterations 3
            
            # Charger ou crÃ©er les performances de rÃ©fÃ©rence
            $baselinePerformance = Import-BaselinePerformance -BaselinePath $sortBaselinePath
            
            if ($null -eq $baselinePerformance) {
                # Sauvegarder les performances actuelles comme rÃ©fÃ©rence
                Save-BaselinePerformance -PerformanceResult $currentPerformance -BaselinePath $sortBaselinePath
                Write-Host "Performances de rÃ©fÃ©rence pour le tri crÃ©Ã©es : $($currentPerformance.AverageExecutionTimeMs) ms"
                return
            }
            
            # Comparer les performances actuelles avec les performances de rÃ©fÃ©rence
            $comparison = Compare-WithBaseline -CurrentPerformance $currentPerformance -BaselinePerformance $baselinePerformance
            
            # Afficher les rÃ©sultats
            Write-Host "Performances actuelles pour le tri : $($currentPerformance.AverageExecutionTimeMs) ms"
            Write-Host "Performances de rÃ©fÃ©rence pour le tri : $($baselinePerformance.AverageExecutionTimeMs) ms"
            Write-Host "Changement : $($comparison.ChangePercent)%"
            
            # VÃ©rifier s'il y a une rÃ©gression
            if ($comparison.IsRegression) {
                Write-Host "RÃ‰GRESSION DÃ‰TECTÃ‰E : Les performances ont diminuÃ© de $($comparison.ChangePercent)%" -ForegroundColor Red
            }
            else {
                Write-Host "Pas de rÃ©gression dÃ©tectÃ©e" -ForegroundColor Green
            }
            
            # Mettre Ã  jour les performances de rÃ©fÃ©rence si les performances actuelles sont meilleures
            if ($comparison.ChangePercent -lt 0) {
                Save-BaselinePerformance -PerformanceResult $currentPerformance -BaselinePath $sortBaselinePath
                Write-Host "Performances de rÃ©fÃ©rence pour le tri mises Ã  jour : $($currentPerformance.AverageExecutionTimeMs) ms" -ForegroundColor Green
            }
            
            # VÃ©rifier qu'il n'y a pas de rÃ©gression significative
            $comparison.IsRegression | Should -Be $false
        }
        
        It "DÃ©tecte les rÃ©gressions de performance pour le filtrage" {
            # Mesurer les performances actuelles
            $currentPerformance = Measure-FunctionPerformance -Name "Filtrage" -ScriptBlock $filterFunction -Iterations 3
            
            # Charger ou crÃ©er les performances de rÃ©fÃ©rence
            $baselinePerformance = Import-BaselinePerformance -BaselinePath $filterBaselinePath
            
            if ($null -eq $baselinePerformance) {
                # Sauvegarder les performances actuelles comme rÃ©fÃ©rence
                Save-BaselinePerformance -PerformanceResult $currentPerformance -BaselinePath $filterBaselinePath
                Write-Host "Performances de rÃ©fÃ©rence pour le filtrage crÃ©Ã©es : $($currentPerformance.AverageExecutionTimeMs) ms"
                return
            }
            
            # Comparer les performances actuelles avec les performances de rÃ©fÃ©rence
            $comparison = Compare-WithBaseline -CurrentPerformance $currentPerformance -BaselinePerformance $baselinePerformance
            
            # Afficher les rÃ©sultats
            Write-Host "Performances actuelles pour le filtrage : $($currentPerformance.AverageExecutionTimeMs) ms"
            Write-Host "Performances de rÃ©fÃ©rence pour le filtrage : $($baselinePerformance.AverageExecutionTimeMs) ms"
            Write-Host "Changement : $($comparison.ChangePercent)%"
            
            # VÃ©rifier s'il y a une rÃ©gression
            if ($comparison.IsRegression) {
                Write-Host "RÃ‰GRESSION DÃ‰TECTÃ‰E : Les performances ont diminuÃ© de $($comparison.ChangePercent)%" -ForegroundColor Red
            }
            else {
                Write-Host "Pas de rÃ©gression dÃ©tectÃ©e" -ForegroundColor Green
            }
            
            # Mettre Ã  jour les performances de rÃ©fÃ©rence si les performances actuelles sont meilleures
            if ($comparison.ChangePercent -lt 0) {
                Save-BaselinePerformance -PerformanceResult $currentPerformance -BaselinePath $filterBaselinePath
                Write-Host "Performances de rÃ©fÃ©rence pour le filtrage mises Ã  jour : $($currentPerformance.AverageExecutionTimeMs) ms" -ForegroundColor Green
            }
            
            # VÃ©rifier qu'il n'y a pas de rÃ©gression significative
            $comparison.IsRegression | Should -Be $false
        }
        
        It "DÃ©tecte les rÃ©gressions de performance pour l'agrÃ©gation" {
            # Mesurer les performances actuelles
            $currentPerformance = Measure-FunctionPerformance -Name "AgrÃ©gation" -ScriptBlock $aggregateFunction -Iterations 3
            
            # Charger ou crÃ©er les performances de rÃ©fÃ©rence
            $baselinePerformance = Import-BaselinePerformance -BaselinePath $aggregateBaselinePath
            
            if ($null -eq $baselinePerformance) {
                # Sauvegarder les performances actuelles comme rÃ©fÃ©rence
                Save-BaselinePerformance -PerformanceResult $currentPerformance -BaselinePath $aggregateBaselinePath
                Write-Host "Performances de rÃ©fÃ©rence pour l'agrÃ©gation crÃ©Ã©es : $($currentPerformance.AverageExecutionTimeMs) ms"
                return
            }
            
            # Comparer les performances actuelles avec les performances de rÃ©fÃ©rence
            $comparison = Compare-WithBaseline -CurrentPerformance $currentPerformance -BaselinePerformance $baselinePerformance
            
            # Afficher les rÃ©sultats
            Write-Host "Performances actuelles pour l'agrÃ©gation : $($currentPerformance.AverageExecutionTimeMs) ms"
            Write-Host "Performances de rÃ©fÃ©rence pour l'agrÃ©gation : $($baselinePerformance.AverageExecutionTimeMs) ms"
            Write-Host "Changement : $($comparison.ChangePercent)%"
            
            # VÃ©rifier s'il y a une rÃ©gression
            if ($comparison.IsRegression) {
                Write-Host "RÃ‰GRESSION DÃ‰TECTÃ‰E : Les performances ont diminuÃ© de $($comparison.ChangePercent)%" -ForegroundColor Red
            }
            else {
                Write-Host "Pas de rÃ©gression dÃ©tectÃ©e" -ForegroundColor Green
            }
            
            # Mettre Ã  jour les performances de rÃ©fÃ©rence si les performances actuelles sont meilleures
            if ($comparison.ChangePercent -lt 0) {
                Save-BaselinePerformance -PerformanceResult $currentPerformance -BaselinePath $aggregateBaselinePath
                Write-Host "Performances de rÃ©fÃ©rence pour l'agrÃ©gation mises Ã  jour : $($currentPerformance.AverageExecutionTimeMs) ms" -ForegroundColor Green
            }
            
            # VÃ©rifier qu'il n'y a pas de rÃ©gression significative
            $comparison.IsRegression | Should -Be $false
        }
    }
    
    Context "Suivi des performances au fil du temps" {
        BeforeAll {
            # Fonction pour enregistrer les performances dans un historique
            function Add-PerformanceHistory {
                param (
                    [Parameter(Mandatory = $true)]
                    [string]$Name,
                    
                    [Parameter(Mandatory = $true)]
                    [double]$ExecutionTimeMs,
                    
                    [Parameter(Mandatory = $true)]
                    [string]$HistoryPath
                )
                
                # CrÃ©er le rÃ©pertoire parent s'il n'existe pas
                $parentDir = Split-Path -Path $HistoryPath -Parent
                if (-not (Test-Path -Path $parentDir -PathType Container)) {
                    New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
                }
                
                # Charger l'historique existant ou crÃ©er un nouveau
                if (Test-Path -Path $HistoryPath -PathType Leaf) {
                    $history = Get-Content -Path $HistoryPath -Raw | ConvertFrom-Json
                }
                else {
                    $history = @()
                }
                
                # Ajouter la nouvelle entrÃ©e
                $newEntry = [PSCustomObject]@{
                    Name = $Name
                    ExecutionTimeMs = $ExecutionTimeMs
                    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                }
                
                $history += $newEntry
                
                # Sauvegarder l'historique mis Ã  jour
                $history | ConvertTo-Json | Out-File -FilePath $HistoryPath -Encoding utf8
            }
            
            # Fonction pour analyser l'historique des performances
            function Test-PerformanceHistory {
                param (
                    [Parameter(Mandatory = $true)]
                    [string]$HistoryPath,
                    
                    [Parameter(Mandatory = $false)]
                    [int]$MaxEntries = 10
                )
                
                if (-not (Test-Path -Path $HistoryPath -PathType Leaf)) {
                    return $null
                }
                
                # Charger l'historique
                $history = Get-Content -Path $HistoryPath -Raw | ConvertFrom-Json
                
                # Limiter le nombre d'entrÃ©es
                if ($history.Count -gt $MaxEntries) {
                    $history = $history | Select-Object -Last $MaxEntries
                }
                
                # Calculer les statistiques
                $avgTime = ($history | Measure-Object -Property ExecutionTimeMs -Average).Average
                $minTime = ($history | Measure-Object -Property ExecutionTimeMs -Minimum).Minimum
                $maxTime = ($history | Measure-Object -Property ExecutionTimeMs -Maximum).Maximum
                $stdDev = [Math]::Sqrt(($history | ForEach-Object { [Math]::Pow($_.ExecutionTimeMs - $avgTime, 2) } | Measure-Object -Average).Average)
                
                # Calculer la tendance
                $trend = 0
                if ($history.Count -gt 1) {
                    $firstHalf = $history | Select-Object -First ([Math]::Floor($history.Count / 2))
                    $secondHalf = $history | Select-Object -Last ([Math]::Ceiling($history.Count / 2))
                    
                    $firstHalfAvg = ($firstHalf | Measure-Object -Property ExecutionTimeMs -Average).Average
                    $secondHalfAvg = ($secondHalf | Measure-Object -Property ExecutionTimeMs -Average).Average
                    
                    $trend = ($secondHalfAvg - $firstHalfAvg) / $firstHalfAvg * 100
                }
                
                return [PSCustomObject]@{
                    Count = $history.Count
                    AverageTimeMs = $avgTime
                    MinTimeMs = $minTime
                    MaxTimeMs = $maxTime
                    StdDevMs = $stdDev
                    TrendPercent = $trend
                    History = $history
                }
            }
            
            # CrÃ©er des fonctions de test
            $sortFunction = {
                param($size = 1000)
                $data = 1..$size | ForEach-Object { Get-Random }
                return $data | Sort-Object
            }
            
            # DÃ©finir le rÃ©pertoire de l'historique des performances
            $historyDir = Join-Path -Path $TestDrive -ChildPath "PerformanceHistory"
            New-Item -Path $historyDir -ItemType Directory -Force | Out-Null
            
            # DÃ©finir le chemin du fichier d'historique
            $sortHistoryPath = Join-Path -Path $historyDir -ChildPath "sort_history.json"
        }
        
        It "Enregistre et analyse l'historique des performances" {
            # Mesurer les performances actuelles
            $iterations = 3
            $executionTimes = @()
            
            for ($i = 1; $i -le $iterations; $i++) {
                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                & $sortFunction | Out-Null
                $stopwatch.Stop()
                $executionTimes += $stopwatch.Elapsed.TotalMilliseconds
            }
            
            $avgExecutionTime = ($executionTimes | Measure-Object -Average).Average
            
            # Enregistrer les performances dans l'historique
            Add-PerformanceHistory -Name "Tri" -ExecutionTimeMs $avgExecutionTime -HistoryPath $sortHistoryPath
            
            # Simuler plusieurs exÃ©cutions avec des variations de performance
            for ($i = 1; $i -le 5; $i++) {
                # Simuler une variation de performance (Â±20%)
                $variation = 1 + (Get-Random -Minimum -0.2 -Maximum 0.2)
                $simulatedTime = $avgExecutionTime * $variation
                
                Add-PerformanceHistory -Name "Tri" -ExecutionTimeMs $simulatedTime -HistoryPath $sortHistoryPath
            }
            
            # Analyser l'historique des performances
            $analysis = Test-PerformanceHistory -HistoryPath $sortHistoryPath
            
            # Afficher les rÃ©sultats
            Write-Host "Analyse de l'historique des performances pour le tri :"
            Write-Host "  Nombre d'entrÃ©es : $($analysis.Count)"
            Write-Host "  Temps moyen : $($analysis.AverageTimeMs) ms"
            Write-Host "  Temps min/max : $($analysis.MinTimeMs) / $($analysis.MaxTimeMs) ms"
            Write-Host "  Ã‰cart-type : $($analysis.StdDevMs) ms"
            Write-Host "  Tendance : $($analysis.TrendPercent)%"
            
            # VÃ©rifier que l'analyse est correcte
            $analysis.Count | Should -Be 6  # 1 mesure rÃ©elle + 5 simulations
            $analysis.AverageTimeMs | Should -BeGreaterThan 0
            $analysis.MinTimeMs | Should -BeGreaterThan 0
            $analysis.MaxTimeMs | Should -BeGreaterThan 0
        }
    }
}

