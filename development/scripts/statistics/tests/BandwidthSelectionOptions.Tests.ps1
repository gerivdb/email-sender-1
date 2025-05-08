BeforeAll {
    # Importer les modules à tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\KernelDensityEstimation.psm1"
    Import-Module $modulePath -Force
    
    $optionsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\BandwidthSelectionOptions.ps1"
    . $optionsPath
}

Describe "Tests de la fonction Get-BandwidthSelectionOptions" {
    Context "Tests de base" {
        It "Crée un objet d'options avec les valeurs par défaut" {
            $options = Get-BandwidthSelectionOptions
            
            $options | Should -Not -BeNullOrEmpty
            $options.Methods | Should -Contain "Silverman"
            $options.Methods | Should -Contain "Scott"
            $options.Methods | Should -Contain "LeaveOneOut"
            $options.Methods | Should -Contain "KFold"
            $options.Methods | Should -Contain "Optimized"
            $options.Weights.Accuracy | Should -Be 1
            $options.Weights.Speed | Should -Be 1
            $options.Weights.Robustness | Should -Be 1
            $options.Weights.Adaptability | Should -Be 1
            $options.AutoDetect | Should -Be $true
            $options.KFoldCount | Should -Be 5
            $options.MaxIterations | Should -Be 20
            $options.Tolerance | Should -Be 0.1
            $options.TimeoutSeconds | Should -Be 30
            $options.PreferSimpleMethods | Should -Be $true
            $options.SmallDatasetThreshold | Should -Be 20
            $options.LargeDatasetThreshold | Should -Be 1000
            $options.CacheResults | Should -Be $false
            $options.ObjectiveProfile | Should -Be "Balanced"
        }
        
        It "Crée un objet d'options avec des valeurs personnalisées" {
            $options = Get-BandwidthSelectionOptions -Methods @("Silverman", "Scott") -AccuracyWeight 3 -SpeedWeight 0 -KFoldCount 10 -MaxIterations 50 -AutoDetect $false
            
            $options | Should -Not -BeNullOrEmpty
            $options.Methods | Should -HaveCount 2
            $options.Methods | Should -Contain "Silverman"
            $options.Methods | Should -Contain "Scott"
            $options.Weights.Accuracy | Should -Be 3
            $options.Weights.Speed | Should -Be 0
            $options.KFoldCount | Should -Be 10
            $options.MaxIterations | Should -Be 50
            $options.AutoDetect | Should -Be $false
            $options.ObjectiveProfile | Should -Be "Accuracy"
        }
    }
    
    Context "Tests de la méthode GetFilteredMethods" {
        It "Filtre les méthodes pour un petit ensemble de données" {
            $options = Get-BandwidthSelectionOptions
            $filteredMethods = $options.GetFilteredMethods(10, "Low")
            
            $filteredMethods | Should -Contain "Silverman"
            $filteredMethods | Should -Contain "Scott"
        }
        
        It "Filtre les méthodes pour un ensemble de données de taille moyenne" {
            $options = Get-BandwidthSelectionOptions
            $filteredMethods = $options.GetFilteredMethods(100, "Medium")
            
            $filteredMethods | Should -Contain "LeaveOneOut"
            $filteredMethods | Should -Contain "KFold"
            $filteredMethods | Should -Contain "Silverman"
            $filteredMethods | Should -Contain "Scott"
        }
        
        It "Filtre les méthodes pour un grand ensemble de données" {
            $options = Get-BandwidthSelectionOptions
            $filteredMethods = $options.GetFilteredMethods(2000, "Medium")
            
            $filteredMethods | Should -Contain "KFold"
            $filteredMethods | Should -Contain "Silverman"
            $filteredMethods | Should -Contain "Scott"
            $filteredMethods | Should -Not -Contain "LeaveOneOut"
        }
    }
}

Describe "Tests de l'intégration de Get-BandwidthSelectionOptions avec Get-KernelDensityEstimation" {
    Context "Tests avec des données simples" {
        BeforeAll {
            # Créer un petit ensemble de données pour les tests
            $testData = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
        }
        
        It "Utilise les options par défaut lorsque BandwidthSelectionOptions n'est pas spécifié" {
            $result = Get-KernelDensityEstimation -Data $testData -BandwidthMethod "Auto"
            
            $result | Should -Not -BeNullOrEmpty
            $result.BandwidthMethod | Should -Be "Auto"
            $result.Bandwidth | Should -BeGreaterThan 0
            $result.OptimalBandwidthInfo | Should -Not -BeNullOrEmpty
            $result.SelectedBandwidthMethod | Should -Be "Silverman"
        }
        
        It "Utilise les options personnalisées lorsque BandwidthSelectionOptions est spécifié" {
            $options = Get-BandwidthSelectionOptions -Methods @("Scott") -SmallDatasetThreshold 5
            $result = Get-KernelDensityEstimation -Data $testData -BandwidthMethod "Auto" -BandwidthSelectionOptions $options
            
            $result | Should -Not -BeNullOrEmpty
            $result.BandwidthMethod | Should -Be "Auto"
            $result.Bandwidth | Should -BeGreaterThan 0
            $result.OptimalBandwidthInfo | Should -Not -BeNullOrEmpty
            $result.OptimalBandwidthInfo.Options | Should -Be $options
        }
    }
    
    Context "Tests avec différents objectifs" {
        BeforeAll {
            # Créer un petit ensemble de données pour les tests
            $testData = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
        }
        
        It "Privilégie la précision avec AccuracyWeight élevé" {
            $options = Get-BandwidthSelectionOptions -AccuracyWeight 3 -SpeedWeight 0 -SmallDatasetThreshold 5
            $result = Get-KernelDensityEstimation -Data $testData -BandwidthMethod "Auto" -BandwidthSelectionOptions $options
            
            $result | Should -Not -BeNullOrEmpty
            $result.OptimalBandwidthInfo.Options.ObjectiveProfile | Should -Be "Accuracy"
        }
        
        It "Privilégie la vitesse avec SpeedWeight élevé" {
            $options = Get-BandwidthSelectionOptions -AccuracyWeight 0 -SpeedWeight 3 -SmallDatasetThreshold 5
            $result = Get-KernelDensityEstimation -Data $testData -BandwidthMethod "Auto" -BandwidthSelectionOptions $options
            
            $result | Should -Not -BeNullOrEmpty
            $result.OptimalBandwidthInfo.Options.ObjectiveProfile | Should -Be "Speed"
        }
    }
}
