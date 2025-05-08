# Tests pour les différentes méthodes de sélection de largeur de bande dans l'estimation de densité par noyau
# Run with Pester: Invoke-Pester -Path ".\BandwidthSelectionMethods.Tests.ps1"

BeforeAll {
    # Charger les modules nécessaires
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\KernelDensityEstimation.psm1"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force
    }
    
    $bandwidthSelectionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\BandwidthSelection.psm1"
    if (Test-Path $bandwidthSelectionPath) {
        Import-Module $bandwidthSelectionPath -Force
    }
    
    # Fonctions de sélection de largeur de bande pour les tests
    function Get-SilvermanBandwidthValue {
        param (
            [double[]]$Data
        )
        $n = $Data.Count
        $stdDev = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - ($Data | Measure-Object -Average).Average, 2) } | Measure-Object -Average).Average)
        
        # Calculer l'écart interquartile
        $sortedData = $Data | Sort-Object
        $q1Index = [Math]::Floor($n * 0.25)
        $q3Index = [Math]::Floor($n * 0.75)
        $iqr = $sortedData[$q3Index] - $sortedData[$q1Index]
        
        # Règle de Silverman
        return 0.9 * [Math]::Min($stdDev, $iqr / 1.34) * [Math]::Pow($n, -0.2)
    }
    
    function Get-ScottBandwidthValue {
        param (
            [double[]]$Data
        )
        $n = $Data.Count
        $stdDev = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - ($Data | Measure-Object -Average).Average, 2) } | Measure-Object -Average).Average)
        
        # Règle de Scott
        return 1.06 * $stdDev * [Math]::Pow($n, -0.2)
    }
    
    function Get-CrossValidationBandwidthValue {
        param (
            [double[]]$Data,
            [int]$NumBandwidths = 20,
            [double[]]$BandwidthRange = @()
        )
        $n = $Data.Count
        
        # Calculer la largeur de bande initiale avec la règle de Silverman
        $initialBandwidth = Get-SilvermanBandwidthValue -Data $Data
        
        # Définir la plage de largeurs de bande si non spécifiée
        if ($BandwidthRange.Count -eq 0) {
            $BandwidthRange = @(0.1 * $initialBandwidth, 2 * $initialBandwidth)
        }
        
        # Générer les largeurs de bande à tester
        $bandwidthsToTest = 0..($NumBandwidths - 1) | ForEach-Object {
            $BandwidthRange[0] + ($BandwidthRange[1] - $BandwidthRange[0]) * $_ / ($NumBandwidths - 1)
        }
        
        # Calculer le score de validation croisée pour chaque largeur de bande
        $scores = @()
        foreach ($h in $bandwidthsToTest) {
            $score = 0
            
            for ($i = 0; $i -lt $n; $i++) {
                $xi = $Data[$i]
                $density = 0
                
                for ($j = 0; $j -lt $n; $j++) {
                    if ($i -ne $j) {
                        $xj = $Data[$j]
                        $x = ($xi - $xj) / $h
                        
                        # Noyau gaussien
                        $kernelValue = (1 / [Math]::Sqrt(2 * [Math]::PI)) * [Math]::Exp(-0.5 * $x * $x)
                        $density += $kernelValue
                    }
                }
                
                $density = $density / (($n - 1) * $h)
                $score += [Math]::Log($density)
            }
            
            $scores += [PSCustomObject]@{
                Bandwidth = $h
                Score = $score / $n
            }
        }
        
        # Trouver la largeur de bande avec le score le plus élevé
        $bestBandwidth = ($scores | Sort-Object -Property Score -Descending)[0].Bandwidth
        return $bestBandwidth
    }
}

Describe "Tests des méthodes de sélection de largeur de bande" {
    Context "Tests des propriétés mathématiques des méthodes de sélection" {
        BeforeAll {
            # Générer des données de test
            $normalData = 1..100 | ForEach-Object {
                # Générer des variables aléatoires normales
                $u1 = Get-Random -Minimum 0.0001 -Maximum 0.9999
                $u2 = Get-Random -Minimum 0.0001 -Maximum 0.9999
                $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
                
                # Ajouter une moyenne et une échelle
                50 + 10 * $z
            }
            
            $uniformData = 1..100 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
            
            $bimodalData = 1..50 | ForEach-Object { Get-Random -Minimum 0 -Maximum 30 } + (1..50 | ForEach-Object { Get-Random -Minimum 70 -Maximum 100 })
        }
        
        It "La méthode de Silverman donne des résultats raisonnables pour les données normales" {
            $bandwidth = Get-SilvermanBandwidthValue -Data $normalData
            
            $bandwidth | Should -BeGreaterThan 0
            
            # Pour des données normales avec n=100, stdDev=10, la règle de Silverman donne environ:
            # h = 0.9 * 10 * 100^(-1/5) ≈ 0.9 * 10 * 0.398 ≈ 3.58
            $bandwidth | Should -BeGreaterThan 2
            $bandwidth | Should -BeLessThan 6
        }
        
        It "La méthode de Scott donne des résultats raisonnables pour les données normales" {
            $bandwidth = Get-ScottBandwidthValue -Data $normalData
            
            $bandwidth | Should -BeGreaterThan 0
            
            # Pour des données normales avec n=100, stdDev=10, la règle de Scott donne environ:
            # h = 1.06 * 10 * 100^(-1/5) ≈ 1.06 * 10 * 0.398 ≈ 4.22
            $bandwidth | Should -BeGreaterThan 3
            $bandwidth | Should -BeLessThan 7
        }
        
        It "La méthode de validation croisée donne des résultats raisonnables pour les données normales" {
            $bandwidth = Get-CrossValidationBandwidthValue -Data $normalData
            
            $bandwidth | Should -BeGreaterThan 0
        }
        
        It "La méthode de Silverman est sensible à la distribution des données" {
            $bandwidthNormal = Get-SilvermanBandwidthValue -Data $normalData
            $bandwidthUniform = Get-SilvermanBandwidthValue -Data $uniformData
            $bandwidthBimodal = Get-SilvermanBandwidthValue -Data $bimodalData
            
            # Les largeurs de bande devraient être différentes pour différentes distributions
            $bandwidthNormal | Should -Not -BeApproximately $bandwidthUniform -Epsilon 0.1
            $bandwidthNormal | Should -Not -BeApproximately $bandwidthBimodal -Epsilon 0.1
            $bandwidthUniform | Should -Not -BeApproximately $bandwidthBimodal -Epsilon 0.1
        }
        
        It "La méthode de Scott est sensible à la distribution des données" {
            $bandwidthNormal = Get-ScottBandwidthValue -Data $normalData
            $bandwidthUniform = Get-ScottBandwidthValue -Data $uniformData
            $bandwidthBimodal = Get-ScottBandwidthValue -Data $bimodalData
            
            # Les largeurs de bande devraient être différentes pour différentes distributions
            $bandwidthNormal | Should -Not -BeApproximately $bandwidthUniform -Epsilon 0.1
            $bandwidthNormal | Should -Not -BeApproximately $bandwidthBimodal -Epsilon 0.1
            $bandwidthUniform | Should -Not -BeApproximately $bandwidthBimodal -Epsilon 0.1
        }
    }
    
    Context "Tests d'intégration avec l'estimation de densité par noyau" {
        BeforeAll {
            # Générer des données de test
            $testData = 1..100 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
        }
        
        It "L'estimation de densité fonctionne avec la méthode de Silverman" -Skip:(-not (Get-Command Get-KernelDensityEstimation -ErrorAction SilentlyContinue)) {
            $result = Get-KernelDensityEstimation -Data $testData -BandwidthMethod "Silverman"
            
            $result | Should -Not -BeNullOrEmpty
            $result.BandwidthMethod | Should -Be "Silverman"
            $result.Bandwidth | Should -BeGreaterThan 0
            $result.DensityEstimates | Should -Not -BeNullOrEmpty
            $result.DensityEstimates | ForEach-Object { $_ | Should -BeGreaterOrEqual 0 }
        }
        
        It "L'estimation de densité fonctionne avec la méthode de Scott" -Skip:(-not (Get-Command Get-KernelDensityEstimation -ErrorAction SilentlyContinue)) {
            $result = Get-KernelDensityEstimation -Data $testData -BandwidthMethod "Scott"
            
            $result | Should -Not -BeNullOrEmpty
            $result.BandwidthMethod | Should -Be "Scott"
            $result.Bandwidth | Should -BeGreaterThan 0
            $result.DensityEstimates | Should -Not -BeNullOrEmpty
            $result.DensityEstimates | ForEach-Object { $_ | Should -BeGreaterOrEqual 0 }
        }
        
        It "L'estimation de densité fonctionne avec la méthode de validation croisée" -Skip:(-not (Get-Command Get-KernelDensityEstimation -ErrorAction SilentlyContinue)) {
            $result = Get-KernelDensityEstimation -Data $testData -BandwidthMethod "CrossValidation"
            
            $result | Should -Not -BeNullOrEmpty
            $result.BandwidthMethod | Should -Be "CrossValidation"
            $result.Bandwidth | Should -BeGreaterThan 0
            $result.DensityEstimates | Should -Not -BeNullOrEmpty
            $result.DensityEstimates | ForEach-Object { $_ | Should -BeGreaterOrEqual 0 }
        }
        
        It "L'estimation de densité fonctionne avec la méthode automatique" -Skip:(-not (Get-Command Get-KernelDensityEstimation -ErrorAction SilentlyContinue)) {
            $result = Get-KernelDensityEstimation -Data $testData -BandwidthMethod "Auto"
            
            $result | Should -Not -BeNullOrEmpty
            $result.BandwidthMethod | Should -Be "Auto"
            $result.Bandwidth | Should -BeGreaterThan 0
            $result.DensityEstimates | Should -Not -BeNullOrEmpty
            $result.DensityEstimates | ForEach-Object { $_ | Should -BeGreaterOrEqual 0 }
        }
    }
    
    Context "Tests avec Get-OptimalBandwidth" {
        BeforeAll {
            # Générer des données de test
            $testData = 1..100 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
        }
        
        It "Get-OptimalBandwidth fonctionne avec la méthode de Silverman" -Skip:(-not (Get-Command Get-OptimalBandwidth -ErrorAction SilentlyContinue)) {
            $result = Get-OptimalBandwidth -Data $testData -Method "Silverman"
            
            $result | Should -Not -BeNullOrEmpty
            $result.Method | Should -Be "Silverman"
            $result.Value | Should -BeGreaterThan 0
        }
        
        It "Get-OptimalBandwidth fonctionne avec la méthode de Scott" -Skip:(-not (Get-Command Get-OptimalBandwidth -ErrorAction SilentlyContinue)) {
            $result = Get-OptimalBandwidth -Data $testData -Method "Scott"
            
            $result | Should -Not -BeNullOrEmpty
            $result.Method | Should -Be "Scott"
            $result.Value | Should -BeGreaterThan 0
        }
        
        It "Get-OptimalBandwidth fonctionne avec la méthode de validation croisée" -Skip:(-not (Get-Command Get-OptimalBandwidth -ErrorAction SilentlyContinue)) {
            $result = Get-OptimalBandwidth -Data $testData -Method "CrossValidation"
            
            $result | Should -Not -BeNullOrEmpty
            $result.Method | Should -Be "CrossValidation"
            $result.Value | Should -BeGreaterThan 0
        }
        
        It "Get-OptimalBandwidth fonctionne avec la méthode Plugin" -Skip:(-not (Get-Command Get-OptimalBandwidth -ErrorAction SilentlyContinue)) {
            $result = Get-OptimalBandwidth -Data $testData -Method "Plugin"
            
            $result | Should -Not -BeNullOrEmpty
            $result.Method | Should -Be "Plugin"
            $result.Value | Should -BeGreaterThan 0
        }
        
        It "Get-OptimalBandwidth fonctionne avec la méthode Adaptive" -Skip:(-not (Get-Command Get-OptimalBandwidth -ErrorAction SilentlyContinue)) {
            $result = Get-OptimalBandwidth -Data $testData -Method "Adaptive"
            
            $result | Should -Not -BeNullOrEmpty
            $result.Method | Should -Be "Adaptive"
            $result.Value | Should -BeGreaterThan 0
        }
    }
}

AfterAll {
    # Nettoyage
}
