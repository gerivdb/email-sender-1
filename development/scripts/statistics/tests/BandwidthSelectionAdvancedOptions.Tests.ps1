BeforeAll {
    # Charger les modules nécessaires
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\BandwidthSelectionAdvancedOptions.ps1"
    . $modulePath
    
    $kdePath = Join-Path -Path $PSScriptRoot -ChildPath "..\KernelDensityEstimation.psm1"
    Import-Module $kdePath -Force
}

Describe "Tests pour les options avancées de sélection de la largeur de bande" {
    Context "Tests de base pour Get-BandwidthSelectionAdvancedOptions" {
        It "Devrait créer un objet d'options avec les valeurs par défaut" {
            $options = Get-BandwidthSelectionAdvancedOptions
            $options | Should -Not -BeNullOrEmpty
            $options.OptimizationStrategy | Should -Be "Standard"
            $options.CrossValidationFolds | Should -Be 5
            $options.MaxIterations | Should -Be 20
            $options.Tolerance | Should -Be 0.01
            $options.OutlierHandling | Should -Be "None"
            $options.SamplingStrategy | Should -Be "None"
            $options.ParallelProcessing | Should -Be $false
            $options.CacheResults | Should -Be $false
            $options.Methods.Count | Should -BeGreaterThan 0
            $options.Weights.Count | Should -Be 4
        }
        
        It "Devrait créer un objet d'options avec les valeurs spécifiées" {
            $options = Get-BandwidthSelectionAdvancedOptions -OptimizationStrategy "Precision" -CrossValidationFolds 10 -MaxIterations 50 -Tolerance 0.005 -OutlierHandling "Trim" -SamplingStrategy "Adaptive" -ParallelProcessing $true
            $options | Should -Not -BeNullOrEmpty
            $options.OptimizationStrategy | Should -Be "Precision"
            $options.CrossValidationFolds | Should -Be 10
            $options.MaxIterations | Should -Be 50
            $options.Tolerance | Should -Be 0.005
            $options.OutlierHandling | Should -Be "Trim"
            $options.SamplingStrategy | Should -Be "Adaptive"
            $options.ParallelProcessing | Should -Be $true
        }
        
        It "Devrait définir les poids en fonction de la stratégie d'optimisation" {
            $options1 = Get-BandwidthSelectionAdvancedOptions -OptimizationStrategy "Precision"
            $options1.Weights.Accuracy | Should -Be 3
            $options1.Weights.Speed | Should -Be 1
            
            $options2 = Get-BandwidthSelectionAdvancedOptions -OptimizationStrategy "Performance"
            $options2.Weights.Accuracy | Should -Be 1
            $options2.Weights.Speed | Should -Be 3
            
            $options3 = Get-BandwidthSelectionAdvancedOptions -OptimizationStrategy "Robustness"
            $options3.Weights.Robustness | Should -Be 3
            
            $options4 = Get-BandwidthSelectionAdvancedOptions -OptimizationStrategy "Adaptability"
            $options4.Weights.Adaptability | Should -Be 3
        }
        
        It "Devrait utiliser les poids personnalisés si spécifiés" {
            $customWeights = @{
                Accuracy = 2
                Speed = 3
                Robustness = 1
                Adaptability = 4
            }
            
            $options = Get-BandwidthSelectionAdvancedOptions -OptimizationStrategy "Precision" -CustomWeights $customWeights
            $options.Weights.Accuracy | Should -Be 2
            $options.Weights.Speed | Should -Be 3
            $options.Weights.Robustness | Should -Be 1
            $options.Weights.Adaptability | Should -Be 4
        }
        
        It "Devrait filtrer les méthodes exclues" {
            $options = Get-BandwidthSelectionAdvancedOptions -ExcludedMethods @("Silverman", "Scott")
            $options.Methods | Should -Not -Contain "Silverman"
            $options.Methods | Should -Not -Contain "Scott"
            $options.Methods | Should -Contain "LeaveOneOut"
            $options.Methods | Should -Contain "KFold"
            $options.Methods | Should -Contain "Optimized"
        }
        
        It "Devrait utiliser uniquement les méthodes préférées si spécifiées" {
            $options = Get-BandwidthSelectionAdvancedOptions -PreferredMethods @("Silverman", "Scott")
            $options.Methods | Should -Contain "Silverman"
            $options.Methods | Should -Contain "Scott"
            $options.Methods | Should -Not -Contain "LeaveOneOut"
            $options.Methods | Should -Not -Contain "KFold"
            $options.Methods | Should -Not -Contain "Optimized"
        }
        
        It "Devrait avoir une méthode GetFilteredMethods fonctionnelle" {
            $options = Get-BandwidthSelectionAdvancedOptions
            $methods = $options.GetFilteredMethods(50, "Low")
            $methods | Should -Not -BeNullOrEmpty
            $methods.Count | Should -BeGreaterThan 0
            
            $methods = $options.GetFilteredMethods(50, "Medium")
            $methods | Should -Not -BeNullOrEmpty
            $methods.Count | Should -BeGreaterThan 0
            
            $methods = $options.GetFilteredMethods(50, "High")
            $methods | Should -Not -BeNullOrEmpty
            $methods.Count | Should -BeGreaterThan 0
        }
    }
    
    Context "Tests d'intégration avec Get-OptimalBandwidthMethod" {
        It "Devrait utiliser les options avancées pour la sélection de la largeur de bande" {
            # Générer des données
            $data = 1..100 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
            
            # Créer des options avancées
            $options = Get-BandwidthSelectionAdvancedOptions -OptimizationStrategy "Precision" -CrossValidationFolds 3 -MaxIterations 10 -OutlierHandling "Trim"
            
            # Appeler Get-OptimalBandwidthMethod avec les options avancées
            $result = Get-OptimalBandwidthMethod -Data $data -AdvancedOptions $options
            
            # Vérifier que le résultat est valide
            $result | Should -Not -BeNullOrEmpty
            $result.Bandwidth | Should -BeGreaterThan 0
            $result.SelectedMethod | Should -Not -BeNullOrEmpty
        }
        
        It "Devrait traiter les valeurs aberrantes si spécifié dans les options avancées" {
            # Générer des données avec des valeurs aberrantes
            $data = 1..90 | ForEach-Object { Get-Random -Minimum 40 -Maximum 60 }
            $data += 1..10 | ForEach-Object { Get-Random -Minimum 100 -Maximum 200 }
            
            # Créer des options avancées avec traitement des valeurs aberrantes
            $options1 = Get-BandwidthSelectionAdvancedOptions -OutlierHandling "None"
            $options2 = Get-BandwidthSelectionAdvancedOptions -OutlierHandling "Trim"
            
            # Appeler Get-OptimalBandwidthMethod avec les deux options
            $result1 = Get-OptimalBandwidthMethod -Data $data -AdvancedOptions $options1
            $result2 = Get-OptimalBandwidthMethod -Data $data -AdvancedOptions $options2
            
            # Les résultats devraient être différents
            $result1.Bandwidth | Should -Not -Be $result2.Bandwidth
        }
        
        It "Devrait utiliser l'échantillonnage adaptatif si spécifié dans les options avancées" {
            # Générer un grand ensemble de données
            $data = 1..2000 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
            
            # Créer des options avancées avec échantillonnage adaptatif
            $options = Get-BandwidthSelectionAdvancedOptions -SamplingStrategy "Adaptive" -MaxSampleSize 500
            
            # Appeler Get-OptimalBandwidthMethod avec les options avancées
            $result = Get-OptimalBandwidthMethod -Data $data -AdvancedOptions $options
            
            # Vérifier que l'échantillonnage a été utilisé
            $result.UsedSampling | Should -Be $true
            $result.SampledDataCount | Should -BeLessOrEqual 500
            $result.OriginalDataCount | Should -Be 2000
        }
        
        It "Devrait utiliser le traitement parallèle si spécifié dans les options avancées" {
            # Vérifier si PowerShell 7+ est utilisé
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                # Générer des données
                $data = 1..500 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
                
                # Créer des options avancées avec traitement parallèle
                $options = Get-BandwidthSelectionAdvancedOptions -ParallelProcessing $true -MaxParallelJobs 2
                
                # Appeler Get-OptimalBandwidthMethod avec les options avancées
                $result = Get-OptimalBandwidthMethod -Data $data -AdvancedOptions $options
                
                # Vérifier que le résultat est valide
                $result.Bandwidth | Should -BeGreaterThan 0
            }
            else {
                Set-ItResult -Skipped -Because "PowerShell 7+ est requis pour le traitement parallèle"
            }
        }
    }
}
