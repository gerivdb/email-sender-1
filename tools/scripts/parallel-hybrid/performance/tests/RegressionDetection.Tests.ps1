Describe "Tests de détection de régression de performance" {
    Context "Comparaison avec les performances de référence" {
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
                
                # Exécuter des itérations de préchauffage pour éviter les biais de démarrage à froid
                for ($i = 1; $i -le $WarmupIterations; $i++) {
                    & $ScriptBlock @Parameters | Out-Null
                }
                
                $results = @()
                
                # Exécuter les itérations de mesure
                for ($i = 1; $i -le $Iterations; $i++) {
                    # Nettoyer la mémoire avant chaque test
                    [System.GC]::Collect()
                    
                    # Mesurer le temps d'exécution
                    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                    
                    try {
                        # Exécuter la fonction
                        $result = & $ScriptBlock @Parameters
                        $success = $true
                    }
                    catch {
                        Write-Error "Erreur lors de l'exécution de '$Name' : $_"
                        $success = $false
                        $result = $null
                    }
                    
                    $stopwatch.Stop()
                    $executionTime = $stopwatch.Elapsed.TotalMilliseconds
                    
                    # Enregistrer les résultats
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
            
            # Fonction pour sauvegarder les performances de référence
            function Save-BaselinePerformance {
                param (
                    [Parameter(Mandatory = $true)]
                    [PSCustomObject]$PerformanceResult,
                    
                    [Parameter(Mandatory = $true)]
                    [string]$BaselinePath
                )
                
                # Créer le répertoire parent s'il n'existe pas
                $parentDir = Split-Path -Path $BaselinePath -Parent
                if (-not (Test-Path -Path $parentDir -PathType Container)) {
                    New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
                }
                
                # Sauvegarder les performances de référence
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
            
            # Fonction pour charger les performances de référence
            function Load-BaselinePerformance {
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
            
            # Fonction pour comparer les performances actuelles avec les performances de référence
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
            
            # Créer des fonctions de test
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
            
            # Définir le répertoire des performances de référence
            $baselineDir = Join-Path -Path $TestDrive -ChildPath "Baselines"
            New-Item -Path $baselineDir -ItemType Directory -Force | Out-Null
            
            # Définir les chemins des fichiers de référence
            $sortBaselinePath = Join-Path -Path $baselineDir -ChildPath "sort_baseline.json"
            $filterBaselinePath = Join-Path -Path $baselineDir -ChildPath "filter_baseline.json"
            $aggregateBaselinePath = Join-Path -Path $baselineDir -ChildPath "aggregate_baseline.json"
        }
        
        It "Détecte les régressions de performance pour le tri" {
            # Mesurer les performances actuelles
            $currentPerformance = Measure-FunctionPerformance -Name "Tri" -ScriptBlock $sortFunction -Iterations 3
            
            # Charger ou créer les performances de référence
            $baselinePerformance = Load-BaselinePerformance -BaselinePath $sortBaselinePath
            
            if ($null -eq $baselinePerformance) {
                # Sauvegarder les performances actuelles comme référence
                Save-BaselinePerformance -PerformanceResult $currentPerformance -BaselinePath $sortBaselinePath
                Write-Host "Performances de référence pour le tri créées : $($currentPerformance.AverageExecutionTimeMs) ms"
                return
            }
            
            # Comparer les performances actuelles avec les performances de référence
            $comparison = Compare-WithBaseline -CurrentPerformance $currentPerformance -BaselinePerformance $baselinePerformance
            
            # Afficher les résultats
            Write-Host "Performances actuelles pour le tri : $($currentPerformance.AverageExecutionTimeMs) ms"
            Write-Host "Performances de référence pour le tri : $($baselinePerformance.AverageExecutionTimeMs) ms"
            Write-Host "Changement : $($comparison.ChangePercent)%"
            
            # Vérifier s'il y a une régression
            if ($comparison.IsRegression) {
                Write-Host "RÉGRESSION DÉTECTÉE : Les performances ont diminué de $($comparison.ChangePercent)%" -ForegroundColor Red
            }
            else {
                Write-Host "Pas de régression détectée" -ForegroundColor Green
            }
            
            # Mettre à jour les performances de référence si les performances actuelles sont meilleures
            if ($comparison.ChangePercent -lt 0) {
                Save-BaselinePerformance -PerformanceResult $currentPerformance -BaselinePath $sortBaselinePath
                Write-Host "Performances de référence pour le tri mises à jour : $($currentPerformance.AverageExecutionTimeMs) ms" -ForegroundColor Green
            }
            
            # Vérifier qu'il n'y a pas de régression significative
            $comparison.IsRegression | Should -Be $false
        }
        
        It "Détecte les régressions de performance pour le filtrage" {
            # Mesurer les performances actuelles
            $currentPerformance = Measure-FunctionPerformance -Name "Filtrage" -ScriptBlock $filterFunction -Iterations 3
            
            # Charger ou créer les performances de référence
            $baselinePerformance = Load-BaselinePerformance -BaselinePath $filterBaselinePath
            
            if ($null -eq $baselinePerformance) {
                # Sauvegarder les performances actuelles comme référence
                Save-BaselinePerformance -PerformanceResult $currentPerformance -BaselinePath $filterBaselinePath
                Write-Host "Performances de référence pour le filtrage créées : $($currentPerformance.AverageExecutionTimeMs) ms"
                return
            }
            
            # Comparer les performances actuelles avec les performances de référence
            $comparison = Compare-WithBaseline -CurrentPerformance $currentPerformance -BaselinePerformance $baselinePerformance
            
            # Afficher les résultats
            Write-Host "Performances actuelles pour le filtrage : $($currentPerformance.AverageExecutionTimeMs) ms"
            Write-Host "Performances de référence pour le filtrage : $($baselinePerformance.AverageExecutionTimeMs) ms"
            Write-Host "Changement : $($comparison.ChangePercent)%"
            
            # Vérifier s'il y a une régression
            if ($comparison.IsRegression) {
                Write-Host "RÉGRESSION DÉTECTÉE : Les performances ont diminué de $($comparison.ChangePercent)%" -ForegroundColor Red
            }
            else {
                Write-Host "Pas de régression détectée" -ForegroundColor Green
            }
            
            # Mettre à jour les performances de référence si les performances actuelles sont meilleures
            if ($comparison.ChangePercent -lt 0) {
                Save-BaselinePerformance -PerformanceResult $currentPerformance -BaselinePath $filterBaselinePath
                Write-Host "Performances de référence pour le filtrage mises à jour : $($currentPerformance.AverageExecutionTimeMs) ms" -ForegroundColor Green
            }
            
            # Vérifier qu'il n'y a pas de régression significative
            $comparison.IsRegression | Should -Be $false
        }
        
        It "Détecte les régressions de performance pour l'agrégation" {
            # Mesurer les performances actuelles
            $currentPerformance = Measure-FunctionPerformance -Name "Agrégation" -ScriptBlock $aggregateFunction -Iterations 3
            
            # Charger ou créer les performances de référence
            $baselinePerformance = Load-BaselinePerformance -BaselinePath $aggregateBaselinePath
            
            if ($null -eq $baselinePerformance) {
                # Sauvegarder les performances actuelles comme référence
                Save-BaselinePerformance -PerformanceResult $currentPerformance -BaselinePath $aggregateBaselinePath
                Write-Host "Performances de référence pour l'agrégation créées : $($currentPerformance.AverageExecutionTimeMs) ms"
                return
            }
            
            # Comparer les performances actuelles avec les performances de référence
            $comparison = Compare-WithBaseline -CurrentPerformance $currentPerformance -BaselinePerformance $baselinePerformance
            
            # Afficher les résultats
            Write-Host "Performances actuelles pour l'agrégation : $($currentPerformance.AverageExecutionTimeMs) ms"
            Write-Host "Performances de référence pour l'agrégation : $($baselinePerformance.AverageExecutionTimeMs) ms"
            Write-Host "Changement : $($comparison.ChangePercent)%"
            
            # Vérifier s'il y a une régression
            if ($comparison.IsRegression) {
                Write-Host "RÉGRESSION DÉTECTÉE : Les performances ont diminué de $($comparison.ChangePercent)%" -ForegroundColor Red
            }
            else {
                Write-Host "Pas de régression détectée" -ForegroundColor Green
            }
            
            # Mettre à jour les performances de référence si les performances actuelles sont meilleures
            if ($comparison.ChangePercent -lt 0) {
                Save-BaselinePerformance -PerformanceResult $currentPerformance -BaselinePath $aggregateBaselinePath
                Write-Host "Performances de référence pour l'agrégation mises à jour : $($currentPerformance.AverageExecutionTimeMs) ms" -ForegroundColor Green
            }
            
            # Vérifier qu'il n'y a pas de régression significative
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
                
                # Créer le répertoire parent s'il n'existe pas
                $parentDir = Split-Path -Path $HistoryPath -Parent
                if (-not (Test-Path -Path $parentDir -PathType Container)) {
                    New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
                }
                
                # Charger l'historique existant ou créer un nouveau
                if (Test-Path -Path $HistoryPath -PathType Leaf) {
                    $history = Get-Content -Path $HistoryPath -Raw | ConvertFrom-Json
                }
                else {
                    $history = @()
                }
                
                # Ajouter la nouvelle entrée
                $newEntry = [PSCustomObject]@{
                    Name = $Name
                    ExecutionTimeMs = $ExecutionTimeMs
                    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                }
                
                $history += $newEntry
                
                # Sauvegarder l'historique mis à jour
                $history | ConvertTo-Json | Out-File -FilePath $HistoryPath -Encoding utf8
            }
            
            # Fonction pour analyser l'historique des performances
            function Analyze-PerformanceHistory {
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
                
                # Limiter le nombre d'entrées
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
            
            # Créer des fonctions de test
            $sortFunction = {
                param($size = 1000)
                $data = 1..$size | ForEach-Object { Get-Random }
                return $data | Sort-Object
            }
            
            # Définir le répertoire de l'historique des performances
            $historyDir = Join-Path -Path $TestDrive -ChildPath "PerformanceHistory"
            New-Item -Path $historyDir -ItemType Directory -Force | Out-Null
            
            # Définir le chemin du fichier d'historique
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
            
            # Simuler plusieurs exécutions avec des variations de performance
            for ($i = 1; $i -le 5; $i++) {
                # Simuler une variation de performance (±20%)
                $variation = 1 + (Get-Random -Minimum -0.2 -Maximum 0.2)
                $simulatedTime = $avgExecutionTime * $variation
                
                Add-PerformanceHistory -Name "Tri" -ExecutionTimeMs $simulatedTime -HistoryPath $sortHistoryPath
            }
            
            # Analyser l'historique des performances
            $analysis = Analyze-PerformanceHistory -HistoryPath $sortHistoryPath
            
            # Afficher les résultats
            Write-Host "Analyse de l'historique des performances pour le tri :"
            Write-Host "  Nombre d'entrées : $($analysis.Count)"
            Write-Host "  Temps moyen : $($analysis.AverageTimeMs) ms"
            Write-Host "  Temps min/max : $($analysis.MinTimeMs) / $($analysis.MaxTimeMs) ms"
            Write-Host "  Écart-type : $($analysis.StdDevMs) ms"
            Write-Host "  Tendance : $($analysis.TrendPercent)%"
            
            # Vérifier que l'analyse est correcte
            $analysis.Count | Should -Be 6  # 1 mesure réelle + 5 simulations
            $analysis.AverageTimeMs | Should -BeGreaterThan 0
            $analysis.MinTimeMs | Should -BeGreaterThan 0
            $analysis.MaxTimeMs | Should -BeGreaterThan 0
        }
    }
}
