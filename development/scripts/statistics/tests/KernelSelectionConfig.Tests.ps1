# Tests pour les fonctions de configuration de la sélection du noyau optimal
# Run with Pester: Invoke-Pester -Path ".\KernelSelectionConfig.Tests.ps1"

# Importer le module contenant les fonctions à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\KernelSelectionConfig.ps1"
. $modulePath

Describe "Tests pour Get-KernelSelectionConfig" {
    Context "Tests de base" {
        It "Devrait retourner la configuration actuelle" {
            $config = Get-KernelSelectionConfig
            
            $config | Should -Not -BeNullOrEmpty
            $config.AvailableKernels | Should -Not -BeNullOrEmpty
            $config.PreferredKernels | Should -Not -BeNullOrEmpty
            $config.ObjectivePreferences | Should -Not -BeNullOrEmpty
            $config.DefaultSelectionMethod | Should -Not -BeNullOrEmpty
            $config.CrossValidation | Should -Not -BeNullOrEmpty
            $config.Bandwidth | Should -Not -BeNullOrEmpty
            $config.Cache | Should -Not -BeNullOrEmpty
            $config.Performance | Should -Not -BeNullOrEmpty
            $config.CharacteristicsDetection | Should -Not -BeNullOrEmpty
        }
        
        It "Devrait contenir les noyaux disponibles" {
            $config = Get-KernelSelectionConfig
            
            $config.AvailableKernels | Should -Contain "Gaussian"
            $config.AvailableKernels | Should -Contain "Epanechnikov"
            $config.AvailableKernels | Should -Contain "Triangular"
            $config.AvailableKernels | Should -Contain "Uniform"
            $config.AvailableKernels | Should -Contain "Biweight"
            $config.AvailableKernels | Should -Contain "Triweight"
            $config.AvailableKernels | Should -Contain "Cosine"
        }
        
        It "Devrait contenir les noyaux préférés pour différentes caractéristiques de données" {
            $config = Get-KernelSelectionConfig
            
            $config.PreferredKernels.Normal | Should -Not -BeNullOrEmpty
            $config.PreferredKernels.Skewed | Should -Not -BeNullOrEmpty
            $config.PreferredKernels.Multimodal | Should -Not -BeNullOrEmpty
            $config.PreferredKernels.HeavyTailed | Should -Not -BeNullOrEmpty
            $config.PreferredKernels.Sparse | Should -Not -BeNullOrEmpty
        }
        
        It "Devrait contenir les noyaux préférés pour différents objectifs" {
            $config = Get-KernelSelectionConfig
            
            $config.ObjectivePreferences.Precision | Should -Not -BeNullOrEmpty
            $config.ObjectivePreferences.Smoothness | Should -Not -BeNullOrEmpty
            $config.ObjectivePreferences.Speed | Should -Not -BeNullOrEmpty
            $config.ObjectivePreferences.Balance | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Tests pour Set-KernelSelectionConfig" {
    Context "Tests de base" {
        BeforeEach {
            # Sauvegarder la configuration actuelle
            $script:originalConfig = Get-KernelSelectionConfig
        }
        
        AfterEach {
            # Restaurer la configuration originale
            Set-KernelSelectionConfig -Config $script:originalConfig
        }
        
        It "Devrait modifier la configuration" {
            $config = Get-KernelSelectionConfig
            $config.DefaultSelectionMethod = "CrossValidation"
            Set-KernelSelectionConfig -Config $config
            
            $newConfig = Get-KernelSelectionConfig
            $newConfig.DefaultSelectionMethod | Should -Be "CrossValidation"
        }
        
        It "Devrait modifier les noyaux disponibles" {
            $config = Get-KernelSelectionConfig
            $config.AvailableKernels = @("Gaussian", "Epanechnikov")
            Set-KernelSelectionConfig -Config $config
            
            $newConfig = Get-KernelSelectionConfig
            $newConfig.AvailableKernels | Should -HaveCount 2
            $newConfig.AvailableKernels | Should -Contain "Gaussian"
            $newConfig.AvailableKernels | Should -Contain "Epanechnikov"
        }
        
        It "Devrait modifier les noyaux préférés pour différentes caractéristiques de données" {
            $config = Get-KernelSelectionConfig
            $config.PreferredKernels.Normal = "Epanechnikov"
            Set-KernelSelectionConfig -Config $config
            
            $newConfig = Get-KernelSelectionConfig
            $newConfig.PreferredKernels.Normal | Should -Be "Epanechnikov"
        }
        
        It "Devrait modifier les noyaux préférés pour différents objectifs" {
            $config = Get-KernelSelectionConfig
            $config.ObjectivePreferences.Precision = "Gaussian"
            Set-KernelSelectionConfig -Config $config
            
            $newConfig = Get-KernelSelectionConfig
            $newConfig.ObjectivePreferences.Precision | Should -Be "Gaussian"
        }
        
        It "Devrait modifier la configuration de la validation croisée" {
            $config = Get-KernelSelectionConfig
            $config.CrossValidation.Method = "LeaveOneOut"
            $config.CrossValidation.K = 10
            Set-KernelSelectionConfig -Config $config
            
            $newConfig = Get-KernelSelectionConfig
            $newConfig.CrossValidation.Method | Should -Be "LeaveOneOut"
            $newConfig.CrossValidation.K | Should -Be 10
        }
        
        It "Devrait modifier la configuration de la largeur de bande" {
            $config = Get-KernelSelectionConfig
            $config.Bandwidth.AutoSelect = $false
            $config.Bandwidth.DefaultValue = 2.0
            Set-KernelSelectionConfig -Config $config
            
            $newConfig = Get-KernelSelectionConfig
            $newConfig.Bandwidth.AutoSelect | Should -Be $false
            $newConfig.Bandwidth.DefaultValue | Should -Be 2.0
        }
        
        It "Devrait modifier la configuration de la mise en cache" {
            $config = Get-KernelSelectionConfig
            $config.Cache.Enabled = $false
            $config.Cache.MaxCacheSize = 200
            Set-KernelSelectionConfig -Config $config
            
            $newConfig = Get-KernelSelectionConfig
            $newConfig.Cache.Enabled | Should -Be $false
            $newConfig.Cache.MaxCacheSize | Should -Be 200
        }
        
        It "Devrait modifier la configuration des performances" {
            $config = Get-KernelSelectionConfig
            $config.Performance.UseOptimizedFunctions = $false
            $config.Performance.ParallelExecution = $false
            Set-KernelSelectionConfig -Config $config
            
            $newConfig = Get-KernelSelectionConfig
            $newConfig.Performance.UseOptimizedFunctions | Should -Be $false
            $newConfig.Performance.ParallelExecution | Should -Be $false
        }
        
        It "Devrait modifier la configuration de la détection des caractéristiques" {
            $config = Get-KernelSelectionConfig
            $config.CharacteristicsDetection.NormalityThreshold = 0.1
            $config.CharacteristicsDetection.SkewnessThreshold = 1.0
            Set-KernelSelectionConfig -Config $config
            
            $newConfig = Get-KernelSelectionConfig
            $newConfig.CharacteristicsDetection.NormalityThreshold | Should -Be 0.1
            $newConfig.CharacteristicsDetection.SkewnessThreshold | Should -Be 1.0
        }
    }
}

Describe "Tests pour Reset-KernelSelectionConfig" {
    Context "Tests de base" {
        BeforeEach {
            # Sauvegarder la configuration actuelle
            $script:originalConfig = Get-KernelSelectionConfig
        }
        
        AfterEach {
            # Restaurer la configuration originale
            Set-KernelSelectionConfig -Config $script:originalConfig
        }
        
        It "Devrait réinitialiser la configuration" {
            $config = Get-KernelSelectionConfig
            $config.DefaultSelectionMethod = "CrossValidation"
            Set-KernelSelectionConfig -Config $config
            
            Reset-KernelSelectionConfig
            
            $newConfig = Get-KernelSelectionConfig
            $newConfig.DefaultSelectionMethod | Should -Be "Characteristics"
        }
        
        It "Devrait réinitialiser les noyaux disponibles" {
            $config = Get-KernelSelectionConfig
            $config.AvailableKernels = @("Gaussian", "Epanechnikov")
            Set-KernelSelectionConfig -Config $config
            
            Reset-KernelSelectionConfig
            
            $newConfig = Get-KernelSelectionConfig
            $newConfig.AvailableKernels | Should -HaveCount 7
            $newConfig.AvailableKernels | Should -Contain "Gaussian"
            $newConfig.AvailableKernels | Should -Contain "Epanechnikov"
            $newConfig.AvailableKernels | Should -Contain "Triangular"
            $newConfig.AvailableKernels | Should -Contain "Uniform"
            $newConfig.AvailableKernels | Should -Contain "Biweight"
            $newConfig.AvailableKernels | Should -Contain "Triweight"
            $newConfig.AvailableKernels | Should -Contain "Cosine"
        }
    }
}

Describe "Tests pour Export-KernelSelectionConfig et Import-KernelSelectionConfig" {
    Context "Tests de base" {
        BeforeEach {
            # Sauvegarder la configuration actuelle
            $script:originalConfig = Get-KernelSelectionConfig
            
            # Créer un fichier temporaire
            $script:tempFile = [System.IO.Path]::GetTempFileName()
        }
        
        AfterEach {
            # Restaurer la configuration originale
            Set-KernelSelectionConfig -Config $script:originalConfig
            
            # Supprimer le fichier temporaire
            if (Test-Path -Path $script:tempFile) {
                Remove-Item -Path $script:tempFile -Force
            }
        }
        
        It "Devrait exporter et importer la configuration" {
            $config = Get-KernelSelectionConfig
            $config.DefaultSelectionMethod = "CrossValidation"
            Set-KernelSelectionConfig -Config $config
            
            Export-KernelSelectionConfig -FilePath $script:tempFile
            
            Reset-KernelSelectionConfig
            
            Import-KernelSelectionConfig -FilePath $script:tempFile
            
            $newConfig = Get-KernelSelectionConfig
            $newConfig.DefaultSelectionMethod | Should -Be "CrossValidation"
        }
        
        It "Devrait lever une exception si le fichier d'importation n'existe pas" {
            $nonExistentFile = "C:\NonExistentFile.json"
            
            { Import-KernelSelectionConfig -FilePath $nonExistentFile } | Should -Throw "Le fichier de configuration 'C:\NonExistentFile.json' n'existe pas."
        }
    }
}
