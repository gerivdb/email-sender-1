# Tests de performance pour l'estimation de densité par noyau
# Run with Pester: Invoke-Pester -Path ".\PerformanceTests.ps1"

BeforeAll {
    # Charger les modules nécessaires
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\KernelDensityEstimation.psm1"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force
    }
    
    $modulePath2D = Join-Path -Path $PSScriptRoot -ChildPath "..\KernelDensity2D.psm1"
    if (Test-Path $modulePath2D) {
        Import-Module $modulePath2D -Force
    }
    
    $modulePathND = Join-Path -Path $PSScriptRoot -ChildPath "..\KernelDensityEstimateND.psm1"
    if (Test-Path $modulePathND) {
        Import-Module $modulePathND -Force
    }
    
    $optimizationsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\KDEOptimizations.ps1"
    if (Test-Path $optimizationsPath) {
        . $optimizationsPath
    }
    
    $parallelPath = Join-Path -Path $PSScriptRoot -ChildPath "..\ParallelKDE.ps1"
    if (Test-Path $parallelPath) {
        . $parallelPath
    }
    
    $memoryManagementPath = Join-Path -Path $PSScriptRoot -ChildPath "..\KDEMemoryManagement.ps1"
    if (Test-Path $memoryManagementPath) {
        . $memoryManagementPath
    }
    
    # Fonctions auxiliaires pour les tests
    function Measure-ExecutionTime {
        param (
            [Parameter(Mandatory = $true)]
            [scriptblock]$ScriptBlock,
            
            [Parameter(Mandatory = $false)]
            [int]$Iterations = 1
        )
        
        $times = @()
        
        for ($i = 0; $i -lt $Iterations; $i++) {
            $startTime = Get-Date
            $result = & $ScriptBlock
            $endTime = Get-Date
            $executionTime = ($endTime - $startTime).TotalSeconds
            $times += $executionTime
        }
        
        $averageTime = ($times | Measure-Object -Average).Average
        $minTime = ($times | Measure-Object -Minimum).Minimum
        $maxTime = ($times | Measure-Object -Maximum).Maximum
        
        return [PSCustomObject]@{
            AverageTime = $averageTime
            MinTime = $minTime
            MaxTime = $maxTime
            Times = $times
            Result = $result
        }
    }
}

Describe "Tests de performance pour l'estimation de densité par noyau" {
    Context "Tests de performance pour les données unidimensionnelles" {
        BeforeAll {
            # Générer des données de test
            $smallData = 1..100 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
            $mediumData = 1..1000 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
            $largeData = 1..10000 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
            
            $evalPoints = 0..100
            $bandwidth = 5
        }
        
        It "Compare les performances des différentes méthodes d'optimisation" {
            # Tester avec des données moyennes
            $data = $mediumData
            
            # Méthode directe
            $directTime = Measure-ExecutionTime -ScriptBlock {
                $densityEstimates = @()
                foreach ($point in $evalPoints) {
                    $density = 0
                    foreach ($dataPoint in $data) {
                        $x = ($point - $dataPoint) / $bandwidth
                        $kernelValue = (1 / [Math]::Sqrt(2 * [Math]::PI)) * [Math]::Exp(-0.5 * $x * $x)
                        $density += $kernelValue
                    }
                    $density /= ($bandwidth * $data.Count)
                    $densityEstimates += $density
                }
                return $densityEstimates
            }
            
            # Méthode avec binning
            $binnedTime = Measure-ExecutionTime -ScriptBlock {
                Get-BinnedKDE -Data $data -EvaluationPoints $evalPoints -Bandwidth $bandwidth
            } -Skip:(-not (Get-Command Get-BinnedKDE -ErrorAction SilentlyContinue))
            
            # Méthode avec mise en cache
            $cachedTime = Measure-ExecutionTime -ScriptBlock {
                Get-CachedKDE -Data $data -EvaluationPoints $evalPoints -Bandwidth $bandwidth
            } -Skip:(-not (Get-Command Get-CachedKDE -ErrorAction SilentlyContinue))
            
            # Méthode avec traitement par lots
            $batchTime = Measure-ExecutionTime -ScriptBlock {
                Get-BatchKDE -Data $data -EvaluationPoints $evalPoints -Bandwidth $bandwidth -BatchSize 200
            } -Skip:(-not (Get-Command Get-BatchKDE -ErrorAction SilentlyContinue))
            
            # Méthode avec traitement parallèle
            $parallelTime = Measure-ExecutionTime -ScriptBlock {
                Get-ParallelKDE1D -Data $data -EvaluationPoints $evalPoints -Bandwidth $bandwidth
            } -Skip:(-not (Get-Command Get-ParallelKDE1D -ErrorAction SilentlyContinue) -or $PSVersionTable.PSVersion.Major -lt 7)
            
            # Vérifier que les méthodes optimisées sont plus rapides que la méthode directe
            if ($null -ne $binnedTime) {
                $binnedTime.AverageTime | Should -BeLessThan $directTime.AverageTime
            }
            
            if ($null -ne $cachedTime) {
                $cachedTime.AverageTime | Should -BeLessThan $directTime.AverageTime
            }
            
            if ($null -ne $batchTime) {
                $batchTime.AverageTime | Should -BeLessThan $directTime.AverageTime * 1.5
            }
            
            if ($null -ne $parallelTime) {
                $parallelTime.AverageTime | Should -BeLessThan $directTime.AverageTime * 1.5
            }
        }
        
        It "Teste l'évolution des performances avec la taille des données" {
            # Fonction pour mesurer les performances
            function Test-DataSize {
                param (
                    [double[]]$Data,
                    [string]$DataSize
                )
                
                # Méthode directe
                $directTime = Measure-ExecutionTime -ScriptBlock {
                    $densityEstimates = @()
                    foreach ($point in $evalPoints) {
                        $density = 0
                        foreach ($dataPoint in $Data) {
                            $x = ($point - $dataPoint) / $bandwidth
                            $kernelValue = (1 / [Math]::Sqrt(2 * [Math]::PI)) * [Math]::Exp(-0.5 * $x * $x)
                            $density += $kernelValue
                        }
                        $density /= ($bandwidth * $Data.Count)
                        $densityEstimates += $density
                    }
                    return $densityEstimates
                }
                
                # Méthode avec binning
                $binnedTime = Measure-ExecutionTime -ScriptBlock {
                    Get-BinnedKDE -Data $Data -EvaluationPoints $evalPoints -Bandwidth $bandwidth
                } -Skip:(-not (Get-Command Get-BinnedKDE -ErrorAction SilentlyContinue))
                
                return [PSCustomObject]@{
                    DataSize = $DataSize
                    DataCount = $Data.Count
                    DirectTime = $directTime.AverageTime
                    BinnedTime = $binnedTime.AverageTime
                    Ratio = if ($null -ne $binnedTime) { $directTime.AverageTime / $binnedTime.AverageTime } else { $null }
                }
            }
            
            # Tester avec différentes tailles de données
            $smallResult = Test-DataSize -Data $smallData -DataSize "Small"
            $mediumResult = Test-DataSize -Data $mediumData -DataSize "Medium"
            $largeResult = Test-DataSize -Data $largeData -DataSize "Large"
            
            # Vérifier que le ratio d'amélioration augmente avec la taille des données
            if ($null -ne $smallResult.Ratio -and $null -ne $mediumResult.Ratio) {
                $mediumResult.Ratio | Should -BeGreaterThan $smallResult.Ratio
            }
            
            if ($null -ne $mediumResult.Ratio -and $null -ne $largeResult.Ratio) {
                $largeResult.Ratio | Should -BeGreaterThan $mediumResult.Ratio
            }
        }
    }
    
    Context "Tests de performance pour les données multidimensionnelles" {
        BeforeAll {
            # Générer des données de test 2D
            $smallData2D = 1..50 | ForEach-Object {
                [PSCustomObject]@{
                    X = Get-Random -Minimum 0 -Maximum 100
                    Y = Get-Random -Minimum 0 -Maximum 100
                }
            }
            
            $mediumData2D = 1..200 | ForEach-Object {
                [PSCustomObject]@{
                    X = Get-Random -Minimum 0 -Maximum 100
                    Y = Get-Random -Minimum 0 -Maximum 100
                }
            }
            
            # Générer des données de test 3D
            $smallData3D = 1..50 | ForEach-Object {
                [PSCustomObject]@{
                    X = Get-Random -Minimum 0 -Maximum 100
                    Y = Get-Random -Minimum 0 -Maximum 100
                    Z = Get-Random -Minimum 0 -Maximum 100
                }
            }
        }
        
        It "Compare les performances des différentes méthodes pour les données 2D" -Skip:(-not (Get-Command Get-KernelDensity2D -ErrorAction SilentlyContinue)) {
            # Tester avec des données moyennes
            $data = $mediumData2D
            
            # Méthode standard
            $standardTime = Measure-ExecutionTime -ScriptBlock {
                Get-KernelDensity2D -Data $data -GridSize @(20, 20)
            }
            
            # Méthode avec échantillonnage adaptatif
            $adaptiveSamplingPath = Join-Path -Path $PSScriptRoot -ChildPath "..\AdaptiveSamplingMultivariate.ps1"
            if (Test-Path $adaptiveSamplingPath) {
                . $adaptiveSamplingPath
                
                $samplingTime = Measure-ExecutionTime -ScriptBlock {
                    $sampledData = Get-AdaptiveSamplingMultivariate -Data $data -MaxSampleSize 100
                    Get-KernelDensity2D -Data $sampledData -GridSize @(20, 20)
                }
                
                # Vérifier que l'échantillonnage adaptatif est plus rapide
                $samplingTime.AverageTime | Should -BeLessThan $standardTime.AverageTime
            }
        }
        
        It "Compare les performances des différentes méthodes pour les données 3D" -Skip:(-not (Get-Command Get-KernelDensityEstimateND -ErrorAction SilentlyContinue)) {
            # Tester avec des données
            $data = $smallData3D
            
            # Méthode standard
            $standardTime = Measure-ExecutionTime -ScriptBlock {
                Get-KernelDensityEstimateND -Data $data -GridSize 10
            }
            
            # Méthode avec échantillonnage adaptatif
            $adaptiveSamplingPath = Join-Path -Path $PSScriptRoot -ChildPath "..\AdaptiveSamplingMultivariate.ps1"
            if (Test-Path $adaptiveSamplingPath) {
                . $adaptiveSamplingPath
                
                $samplingTime = Measure-ExecutionTime -ScriptBlock {
                    $sampledData = Get-AdaptiveSamplingMultivariate -Data $data -MaxSampleSize 30
                    Get-KernelDensityEstimateND -Data $sampledData -GridSize 10
                }
                
                # Vérifier que l'échantillonnage adaptatif est plus rapide
                $samplingTime.AverageTime | Should -BeLessThan $standardTime.AverageTime
            }
        }
    }
    
    Context "Tests de performance pour différents types de noyaux" {
        BeforeAll {
            # Générer des données de test
            $testData = 1..1000 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
            $evalPoints = 0..100
            $bandwidth = 5
        }
        
        It "Compare les performances des différents types de noyaux" -Skip:(-not (Get-Command Get-BinnedKDE -ErrorAction SilentlyContinue)) {
            $kernelTypes = @("Gaussian", "Epanechnikov", "Uniform", "Triangular")
            $results = @()
            
            foreach ($kernelType in $kernelTypes) {
                $time = Measure-ExecutionTime -ScriptBlock {
                    Get-BinnedKDE -Data $testData -EvaluationPoints $evalPoints -Bandwidth $bandwidth -KernelType $kernelType
                }
                
                $results += [PSCustomObject]@{
                    KernelType = $kernelType
                    ExecutionTime = $time.AverageTime
                }
            }
            
            # Vérifier que les noyaux plus simples sont plus rapides
            $gaussianTime = ($results | Where-Object { $_.KernelType -eq "Gaussian" }).ExecutionTime
            $uniformTime = ($results | Where-Object { $_.KernelType -eq "Uniform" }).ExecutionTime
            
            $uniformTime | Should -BeLessThan $gaussianTime
        }
    }
}

AfterAll {
    # Nettoyage
}
