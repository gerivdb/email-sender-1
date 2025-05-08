BeforeAll {
    # Charger les modules nécessaires
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\BandwidthSelectionAdvancedOptions.ps1"
    . $modulePath
}

Describe "Tests simples pour les options avancées de sélection de la largeur de bande" {
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
}
