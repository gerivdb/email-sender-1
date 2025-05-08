# Tests pour KDEOptimizations.ps1
# Run with Pester: Invoke-Pester -Path ".\KDEOptimizations.Tests.ps1"

BeforeAll {
    # Charger les modules nécessaires
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\KDEOptimizations.ps1"
    . $modulePath
}

Describe "Tests pour les optimisations de l'estimation de densité par noyau" {
    Context "Tests de base pour Get-BinnedKDE" {
        It "Devrait calculer correctement la densité en utilisant le binning" {
            # Créer des données de test
            $data = 1..100 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
            $evalPoints = 0..10
            $bandwidth = 5
            
            $result = Get-BinnedKDE -Data $data -EvaluationPoints $evalPoints -Bandwidth $bandwidth
            
            # Vérifier que le résultat est correct
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 11
            
            # Vérifier que les densités sont positives
            $result | ForEach-Object { $_ | Should -BeGreaterThan 0 }
        }
        
        It "Devrait fonctionner avec différents types de noyaux" {
            # Créer des données de test
            $data = 1..50 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
            $evalPoints = 0..5
            $bandwidth = 5
            
            $kernelTypes = @("Gaussian", "Epanechnikov", "Uniform", "Triangular")
            
            foreach ($kernelType in $kernelTypes) {
                $result = Get-BinnedKDE -Data $data -EvaluationPoints $evalPoints -Bandwidth $bandwidth -KernelType $kernelType
                
                # Vérifier que le résultat est correct
                $result | Should -Not -BeNullOrEmpty
                $result.Count | Should -Be 6
                
                # Vérifier que les densités sont positives
                $result | ForEach-Object { $_ | Should -BeGreaterThan 0 }
            }
        }
        
        It "Devrait fonctionner avec différents nombres de bins" {
            # Créer des données de test
            $data = 1..100 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
            $evalPoints = 0..10
            $bandwidth = 5
            
            $binCounts = @(50, 100, 200)
            
            foreach ($binCount in $binCounts) {
                $result = Get-BinnedKDE -Data $data -EvaluationPoints $evalPoints -Bandwidth $bandwidth -BinCount $binCount
                
                # Vérifier que le résultat est correct
                $result | Should -Not -BeNullOrEmpty
                $result.Count | Should -Be 11
                
                # Vérifier que les densités sont positives
                $result | ForEach-Object { $_ | Should -BeGreaterThan 0 }
            }
        }
    }
    
    Context "Tests de base pour Get-FFTKDE" {
        It "Devrait calculer correctement la densité en utilisant la FFT" {
            # Créer des données de test
            $data = 1..100 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
            $bandwidth = 5
            
            # Vérifier si MathNet.Numerics est disponible
            $mathNetAvailable = $false
            try {
                Add-Type -Path "MathNet.Numerics.dll"
                $mathNetAvailable = $true
            }
            catch {
                # MathNet.Numerics n'est pas disponible
            }
            
            if ($mathNetAvailable) {
                $result = Get-FFTKDE -Data $data -Bandwidth $bandwidth
                
                # Vérifier que le résultat est correct
                $result | Should -Not -BeNullOrEmpty
                $result.EvaluationPoints | Should -Not -BeNullOrEmpty
                $result.DensityEstimates | Should -Not -BeNullOrEmpty
                
                # Vérifier que les densités sont positives
                $result.DensityEstimates | ForEach-Object { $_ | Should -BeGreaterThan 0 }
            }
            else {
                # Si MathNet.Numerics n'est pas disponible, le test est ignoré
                Set-ItResult -Skipped -Because "MathNet.Numerics n'est pas disponible"
            }
        }
        
        It "Devrait fonctionner avec différentes tailles de grille" {
            # Créer des données de test
            $data = 1..100 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
            $bandwidth = 5
            
            # Vérifier si MathNet.Numerics est disponible
            $mathNetAvailable = $false
            try {
                Add-Type -Path "MathNet.Numerics.dll"
                $mathNetAvailable = $true
            }
            catch {
                # MathNet.Numerics n'est pas disponible
            }
            
            if ($mathNetAvailable) {
                $gridSizes = @(256, 512, 1024)
                
                foreach ($gridSize in $gridSizes) {
                    $result = Get-FFTKDE -Data $data -Bandwidth $bandwidth -GridSize $gridSize
                    
                    # Vérifier que le résultat est correct
                    $result | Should -Not -BeNullOrEmpty
                    $result.EvaluationPoints.Count | Should -Be $gridSize
                    $result.DensityEstimates.Count | Should -Be $gridSize
                    
                    # Vérifier que les densités sont positives
                    $result.DensityEstimates | ForEach-Object { $_ | Should -BeGreaterThan 0 }
                }
            }
            else {
                # Si MathNet.Numerics n'est pas disponible, le test est ignoré
                Set-ItResult -Skipped -Because "MathNet.Numerics n'est pas disponible"
            }
        }
    }
    
    Context "Tests de base pour Get-CachedKDE" {
        It "Devrait calculer correctement la densité en utilisant la mise en cache" {
            # Créer des données de test
            $data = 1..100 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
            $evalPoints = 0..10
            $bandwidth = 5
            
            $result = Get-CachedKDE -Data $data -EvaluationPoints $evalPoints -Bandwidth $bandwidth
            
            # Vérifier que le résultat est correct
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 11
            
            # Vérifier que les densités sont positives
            $result | ForEach-Object { $_ | Should -BeGreaterThan 0 }
        }
        
        It "Devrait fonctionner avec différentes tailles de cache" {
            # Créer des données de test
            $data = 1..100 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
            $evalPoints = 0..10
            $bandwidth = 5
            
            $cacheSizes = @(100, 500, 1000)
            
            foreach ($cacheSize in $cacheSizes) {
                $result = Get-CachedKDE -Data $data -EvaluationPoints $evalPoints -Bandwidth $bandwidth -CacheSize $cacheSize
                
                # Vérifier que le résultat est correct
                $result | Should -Not -BeNullOrEmpty
                $result.Count | Should -Be 11
                
                # Vérifier que les densités sont positives
                $result | ForEach-Object { $_ | Should -BeGreaterThan 0 }
            }
        }
    }
    
    Context "Tests de performance" {
        It "Get-BinnedKDE devrait être plus rapide que le calcul direct pour les grands ensembles de données" {
            # Créer un grand ensemble de données
            $data = 1..1000 | ForEach-Object { Get-Random -Minimum 0 -Maximum 1000 }
            $evalPoints = 0..100
            $bandwidth = 10
            
            # Fonction pour le calcul direct
            function Get-DirectKDE {
                param (
                    [double[]]$Data,
                    [double[]]$EvaluationPoints,
                    [double]$Bandwidth
                )
                
                $densityEstimates = @()
                foreach ($point in $EvaluationPoints) {
                    $density = 0
                    foreach ($dataPoint in $Data) {
                        $x = ($point - $dataPoint) / $Bandwidth
                        $kernelValue = (1 / [Math]::Sqrt(2 * [Math]::PI)) * [Math]::Exp(-0.5 * $x * $x)
                        $density += $kernelValue
                    }
                    $density /= ($Bandwidth * $Data.Count)
                    $densityEstimates += $density
                }
                
                return $densityEstimates
            }
            
            # Mesurer le temps d'exécution du calcul direct
            $startTimeDirect = Get-Date
            $resultDirect = Get-DirectKDE -Data $data -EvaluationPoints $evalPoints -Bandwidth $bandwidth
            $endTimeDirect = Get-Date
            $executionTimeDirect = ($endTimeDirect - $startTimeDirect).TotalSeconds
            
            # Mesurer le temps d'exécution du calcul avec binning
            $startTimeBinned = Get-Date
            $resultBinned = Get-BinnedKDE -Data $data -EvaluationPoints $evalPoints -Bandwidth $bandwidth
            $endTimeBinned = Get-Date
            $executionTimeBinned = ($endTimeBinned - $startTimeBinned).TotalSeconds
            
            # Vérifier que les résultats sont similaires
            for ($i = 0; $i -lt $resultDirect.Count; $i++) {
                $resultBinned[$i] | Should -BeApproximately $resultDirect[$i] -Epsilon 0.01
            }
            
            # Vérifier que le calcul avec binning est plus rapide
            $executionTimeBinned | Should -BeLessThan $executionTimeDirect
        }
        
        It "Get-CachedKDE devrait être plus rapide que le calcul direct pour les grands ensembles de données" {
            # Créer un grand ensemble de données
            $data = 1..1000 | ForEach-Object { Get-Random -Minimum 0 -Maximum 1000 }
            $evalPoints = 0..100
            $bandwidth = 10
            
            # Fonction pour le calcul direct
            function Get-DirectKDE {
                param (
                    [double[]]$Data,
                    [double[]]$EvaluationPoints,
                    [double]$Bandwidth
                )
                
                $densityEstimates = @()
                foreach ($point in $EvaluationPoints) {
                    $density = 0
                    foreach ($dataPoint in $Data) {
                        $x = ($point - $dataPoint) / $Bandwidth
                        $kernelValue = (1 / [Math]::Sqrt(2 * [Math]::PI)) * [Math]::Exp(-0.5 * $x * $x)
                        $density += $kernelValue
                    }
                    $density /= ($Bandwidth * $Data.Count)
                    $densityEstimates += $density
                }
                
                return $densityEstimates
            }
            
            # Mesurer le temps d'exécution du calcul direct
            $startTimeDirect = Get-Date
            $resultDirect = Get-DirectKDE -Data $data -EvaluationPoints $evalPoints -Bandwidth $bandwidth
            $endTimeDirect = Get-Date
            $executionTimeDirect = ($endTimeDirect - $startTimeDirect).TotalSeconds
            
            # Mesurer le temps d'exécution du calcul avec mise en cache
            $startTimeCached = Get-Date
            $resultCached = Get-CachedKDE -Data $data -EvaluationPoints $evalPoints -Bandwidth $bandwidth
            $endTimeCached = Get-Date
            $executionTimeCached = ($endTimeCached - $startTimeCached).TotalSeconds
            
            # Vérifier que les résultats sont similaires
            for ($i = 0; $i -lt $resultDirect.Count; $i++) {
                $resultCached[$i] | Should -BeApproximately $resultDirect[$i] -Epsilon 0.01
            }
            
            # Vérifier que le calcul avec mise en cache est plus rapide
            $executionTimeCached | Should -BeLessThan $executionTimeDirect
        }
    }
}

AfterAll {
    # Nettoyage
}
