BeforeAll {
    # Importer le module à tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\KernelDensityEstimation.psm1"
    Import-Module $modulePath -Force
}

Describe "Tests de l'intégration de Get-OptimalBandwidthMethod dans Get-KernelDensityEstimation" {
    Context "Tests de base avec la méthode Auto" {
        It "Sélectionne automatiquement une méthode de largeur de bande pour des données normales" {
            # Générer des données normales
            $normalData = 1..100 | ForEach-Object { [Math]::Sqrt(-2 * [Math]::Log([Math]::Max(0.0001, Get-Random -Minimum 0 -Maximum 1))) * [Math]::Cos(2 * [Math]::PI * (Get-Random -Minimum 0 -Maximum 1)) * 15 + 100 }
            
            # Effectuer l'estimation de densité avec la méthode Auto
            $result = Get-KernelDensityEstimation -Data $normalData -BandwidthMethod "Auto" -KernelType "Gaussian" -Objective "Balance"
            
            # Vérifier que le résultat contient les informations attendues
            $result | Should -Not -BeNullOrEmpty
            $result.BandwidthMethod | Should -Be "Auto"
            $result.Bandwidth | Should -BeGreaterThan 0
            $result.OptimalBandwidthInfo | Should -Not -BeNullOrEmpty
            $result.SelectedBandwidthMethod | Should -Not -BeNullOrEmpty
            $result.OptimalBandwidthInfo.RecommendationBasis | Should -Not -BeNullOrEmpty
        }
        
        It "Sélectionne automatiquement une méthode de largeur de bande pour des données multimodales" {
            # Générer des données multimodales (mélange de deux distributions normales)
            $multimodalData = @()
            $multimodalData += 1..50 | ForEach-Object { [Math]::Sqrt(-2 * [Math]::Log([Math]::Max(0.0001, Get-Random -Minimum 0 -Maximum 1))) * [Math]::Cos(2 * [Math]::PI * (Get-Random -Minimum 0 -Maximum 1)) * 5 + 50 }
            $multimodalData += 1..50 | ForEach-Object { [Math]::Sqrt(-2 * [Math]::Log([Math]::Max(0.0001, Get-Random -Minimum 0 -Maximum 1))) * [Math]::Cos(2 * [Math]::PI * (Get-Random -Minimum 0 -Maximum 1)) * 5 + 100 }
            
            # Effectuer l'estimation de densité avec la méthode Auto
            $result = Get-KernelDensityEstimation -Data $multimodalData -BandwidthMethod "Auto" -KernelType "Gaussian" -Objective "Balance"
            
            # Vérifier que le résultat contient les informations attendues
            $result | Should -Not -BeNullOrEmpty
            $result.BandwidthMethod | Should -Be "Auto"
            $result.Bandwidth | Should -BeGreaterThan 0
            $result.OptimalBandwidthInfo | Should -Not -BeNullOrEmpty
            $result.SelectedBandwidthMethod | Should -Not -BeNullOrEmpty
            $result.OptimalBandwidthInfo.RecommendationBasis | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Tests avec différents objectifs" {
        It "Privilégie la précision avec l'objectif 'Precision'" {
            # Générer des données
            $data = 1..100 | ForEach-Object { [Math]::Sqrt(-2 * [Math]::Log([Math]::Max(0.0001, Get-Random -Minimum 0 -Maximum 1))) * [Math]::Cos(2 * [Math]::PI * (Get-Random -Minimum 0 -Maximum 1)) * 15 + 100 }
            
            # Effectuer l'estimation de densité avec l'objectif Precision
            $result = Get-KernelDensityEstimation -Data $data -BandwidthMethod "Auto" -KernelType "Gaussian" -Objective "Precision"
            
            # Vérifier que le résultat contient les informations attendues
            $result | Should -Not -BeNullOrEmpty
            $result.OptimalBandwidthInfo.RecommendationBasis | Should -Match "Accuracy"
        }
        
        It "Privilégie la vitesse avec l'objectif 'Speed'" {
            # Générer des données
            $data = 1..100 | ForEach-Object { [Math]::Sqrt(-2 * [Math]::Log([Math]::Max(0.0001, Get-Random -Minimum 0 -Maximum 1))) * [Math]::Cos(2 * [Math]::PI * (Get-Random -Minimum 0 -Maximum 1)) * 15 + 100 }
            
            # Effectuer l'estimation de densité avec l'objectif Speed
            $result = Get-KernelDensityEstimation -Data $data -BandwidthMethod "Auto" -KernelType "Gaussian" -Objective "Speed"
            
            # Vérifier que le résultat contient les informations attendues
            $result | Should -Not -BeNullOrEmpty
            $result.OptimalBandwidthInfo.RecommendationBasis | Should -Match "Speed"
        }
    }
    
    Context "Tests avec différents types de noyaux" {
        It "Fonctionne avec le noyau Epanechnikov" {
            # Générer des données
            $data = 1..100 | ForEach-Object { [Math]::Sqrt(-2 * [Math]::Log([Math]::Max(0.0001, Get-Random -Minimum 0 -Maximum 1))) * [Math]::Cos(2 * [Math]::PI * (Get-Random -Minimum 0 -Maximum 1)) * 15 + 100 }
            
            # Effectuer l'estimation de densité avec le noyau Epanechnikov
            $result = Get-KernelDensityEstimation -Data $data -BandwidthMethod "Auto" -KernelType "Epanechnikov" -Objective "Balance"
            
            # Vérifier que le résultat contient les informations attendues
            $result | Should -Not -BeNullOrEmpty
            $result.KernelType | Should -Be "Epanechnikov"
            $result.Bandwidth | Should -BeGreaterThan 0
        }
        
        It "Fonctionne avec le noyau Triangular" {
            # Générer des données
            $data = 1..100 | ForEach-Object { [Math]::Sqrt(-2 * [Math]::Log([Math]::Max(0.0001, Get-Random -Minimum 0 -Maximum 1))) * [Math]::Cos(2 * [Math]::PI * (Get-Random -Minimum 0 -Maximum 1)) * 15 + 100 }
            
            # Effectuer l'estimation de densité avec le noyau Triangular
            $result = Get-KernelDensityEstimation -Data $data -BandwidthMethod "Auto" -KernelType "Triangular" -Objective "Balance"
            
            # Vérifier que le résultat contient les informations attendues
            $result | Should -Not -BeNullOrEmpty
            $result.KernelType | Should -Be "Triangular"
            $result.Bandwidth | Should -BeGreaterThan 0
        }
    }
    
    Context "Tests de compatibilité avec les options avancées" {
        It "Fonctionne avec les options avancées" {
            # Générer des données
            $data = 1..100 | ForEach-Object { [Math]::Sqrt(-2 * [Math]::Log([Math]::Max(0.0001, Get-Random -Minimum 0 -Maximum 1))) * [Math]::Cos(2 * [Math]::PI * (Get-Random -Minimum 0 -Maximum 1)) * 15 + 100 }
            
            # Créer des options avancées
            $options = Get-KDEAdvancedOptions -PrecisionLevel "High" -OutlierHandling "Trim" -ParallelProcessing $true
            
            # Effectuer l'estimation de densité avec la méthode Auto et les options avancées
            $result = Get-KernelDensityEstimation -Data $data -BandwidthMethod "Auto" -KernelType "Gaussian" -Objective "Balance" -AdvancedOptions $options
            
            # Vérifier que le résultat contient les informations attendues
            $result | Should -Not -BeNullOrEmpty
            $result.Bandwidth | Should -BeGreaterThan 0
            $result.Options | Should -Be $options
        }
    }
}
