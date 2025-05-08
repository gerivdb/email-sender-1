BeforeAll {
    # Importer le module à tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\KernelDensityEstimation.psm1"
    Import-Module $modulePath -Force
}

Describe "Tests des options avancées pour l'estimation de densité par noyau" {
    Context "Tests de la fonction Get-KDEAdvancedOptions" {
        It "Crée un objet d'options avec les valeurs par défaut" {
            $options = Get-KDEAdvancedOptions

            $options | Should -Not -BeNullOrEmpty
            $options.PrecisionLevel | Should -Be "Medium"
            $options.OutlierHandling | Should -Be "None"
            $options.PerformanceOptimization | Should -Be "Auto"
            $options.ParallelProcessing | Should -Be $false
            $options.CacheResults | Should -Be $false
            $options.AdaptiveBandwidth | Should -Be $false
            $options.BoundaryCorrection | Should -Be $false
            $options.OutputFormat | Should -Be "Standard"
        }

        It "Crée un objet d'options avec des valeurs personnalisées" {
            $options = Get-KDEAdvancedOptions -PrecisionLevel "High" -OutlierHandling "Trim" -ParallelProcessing $true -BoundaryCorrection $true

            $options | Should -Not -BeNullOrEmpty
            $options.PrecisionLevel | Should -Be "High"
            $options.OutlierHandling | Should -Be "Trim"
            $options.ParallelProcessing | Should -Be $true
            $options.BoundaryCorrection | Should -Be $true
            $options.PrecisionFactor | Should -Be 2.0
        }

        It "Calcule correctement les propriétés dérivées" {
            $options = Get-KDEAdvancedOptions -PrecisionLevel "Low"
            $options.PrecisionFactor | Should -Be 0.5

            $options = Get-KDEAdvancedOptions -PrecisionLevel "Medium"
            $options.PrecisionFactor | Should -Be 1.0

            $options = Get-KDEAdvancedOptions -PrecisionLevel "High"
            $options.PrecisionFactor | Should -Be 2.0

            $options = Get-KDEAdvancedOptions -PrecisionLevel "Ultra"
            $options.PrecisionFactor | Should -Be 4.0
        }

        It "Gère correctement le traitement parallèle en fonction de la version de PowerShell" {
            $options = Get-KDEAdvancedOptions -ParallelProcessing $true

            if ($PSVersionTable.PSVersion.Major -ge 7) {
                $options.UseParallel | Should -Be $true
            } else {
                $options.UseParallel | Should -Be $false
            }
        }
    }

    Context "Tests de la méthode ApplyOutlierHandling" {
        It "Ne modifie pas les données si OutlierHandling est 'None'" {
            $options = Get-KDEAdvancedOptions -OutlierHandling "None"
            $data = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

            $result = $options.ApplyOutlierHandling($data)

            $result | Should -Be $data
        }

        It "Supprime les valeurs aberrantes avec la méthode 'Trim'" {
            $options = Get-KDEAdvancedOptions -OutlierHandling "Trim" -OutlierThreshold 1.5
            $data = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 100)  # 100 est une valeur aberrante

            $result = $options.ApplyOutlierHandling($data)

            $result | Should -Not -Contain 100
            $result.Count | Should -BeLessThan $data.Count
        }

        It "Remplace les valeurs aberrantes avec la méthode 'Winsorize'" {
            $options = Get-KDEAdvancedOptions -OutlierHandling "Winsorize" -OutlierThreshold 1.5
            $data = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 100)  # 100 est une valeur aberrante

            $result = $options.ApplyOutlierHandling($data)

            $result | Should -Not -Contain 100
            $result.Count | Should -Be $data.Count
        }

        It "Retourne des poids avec la méthode 'Robust'" {
            $options = Get-KDEAdvancedOptions -OutlierHandling "Robust" -OutlierThreshold 1.5
            $data = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 100)  # 100 est une valeur aberrante

            $result = $options.ApplyOutlierHandling($data)

            $result | Should -BeOfType [Hashtable]
            $result.Data | Should -Be $data
            $result.Weights | Should -Not -BeNullOrEmpty
            $result.Weights.Count | Should -Be $data.Count
            $result.Weights[9] | Should -BeLessThan 1.0  # Le poids de la valeur aberrante devrait être inférieur à 1
        }
    }

    Context "Tests de la méthode ApplyPerformanceOptimization" {
        It "Ne modifie pas les données si PerformanceOptimization est 'None'" {
            $options = Get-KDEAdvancedOptions -PerformanceOptimization "None"
            $data = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

            $result = $options.ApplyPerformanceOptimization($data)

            $result | Should -Be $data
        }

        It "Échantillonne les données avec la méthode 'Sampling'" {
            $options = Get-KDEAdvancedOptions -PerformanceOptimization "Sampling" -SamplingRate 0.5
            $data = 1..1000  # Utiliser un ensemble de données plus grand pour garantir l'échantillonnage

            $result = $options.ApplyPerformanceOptimization($data)

            $result.Count | Should -BeLessThan $data.Count
        }

        It "Regroupe les données en bins avec la méthode 'Binning'" {
            $options = Get-KDEAdvancedOptions -PerformanceOptimization "Binning" -BinCount 10
            $data = 1..100

            $result = $options.ApplyPerformanceOptimization($data)

            $result | Should -BeOfType [Hashtable]
            $result.Data.Count | Should -Be 10
            $result.Weights.Count | Should -Be 10
        }

        It "Sélectionne automatiquement la méthode d'optimisation en fonction de la taille des données" {
            $options = Get-KDEAdvancedOptions -PerformanceOptimization "Auto"

            # Petit ensemble de données
            $smallData = 1..10
            $resultSmall = $options.ApplyPerformanceOptimization($smallData)
            $resultSmall | Should -Be $smallData

            # Grand ensemble de données
            $largeData = 1..10000
            $resultLarge = $options.ApplyPerformanceOptimization($largeData)
            $resultLarge.Count | Should -BeLessThan $largeData.Count
        }
    }

    Context "Tests de l'intégration avec Get-KernelDensityEstimation" {
        It "Utilise les options avancées pour l'estimation de densité" {
            # Créer des données de test
            $data = 1..100 | ForEach-Object { [Math]::Sin($_ / 10) + [Math]::Sqrt($_ / 100) }

            # Créer des options avancées
            $options = Get-KDEAdvancedOptions -PrecisionLevel "High" -OutputFormat "Detailed"

            # Effectuer l'estimation de densité
            $result = Get-KernelDensityEstimation -Data $data -AdvancedOptions $options

            $result | Should -Not -BeNullOrEmpty
            $result.EvaluationPoints | Should -Not -BeNullOrEmpty
            $result.DensityEstimates | Should -Not -BeNullOrEmpty
            $result.Bandwidth | Should -BeGreaterThan 0
            $result.Options | Should -Be $options
        }

        It "Applique correctement le traitement des valeurs aberrantes" {
            # Créer des données de test avec des valeurs aberrantes
            $data = 1..100 | ForEach-Object { [Math]::Sin($_ / 10) }
            $data += 100  # Ajouter une valeur aberrante

            # Créer des options avancées avec traitement des valeurs aberrantes
            $options = Get-KDEAdvancedOptions -OutlierHandling "Trim" -OutputFormat "Detailed"

            # Effectuer l'estimation de densité
            $result = Get-KernelDensityEstimation -Data $data -AdvancedOptions $options

            $result | Should -Not -BeNullOrEmpty
            $result.ProcessedDataCount | Should -BeLessThan $data.Count
        }

        It "Utilise le format de sortie spécifié" {
            # Créer des données de test
            $data = 1..100 | ForEach-Object { [Math]::Sin($_ / 10) }

            # Tester le format "Standard"
            $optionsStandard = Get-KDEAdvancedOptions -OutputFormat "Standard"
            $resultStandard = Get-KernelDensityEstimation -Data $data -AdvancedOptions $optionsStandard
            $resultStandard.Options | Should -Not -BeNullOrEmpty

            # Tester le format "Minimal"
            $optionsMinimal = Get-KDEAdvancedOptions -OutputFormat "Minimal"
            $resultMinimal = Get-KernelDensityEstimation -Data $data -AdvancedOptions $optionsMinimal
            $resultMinimal.PSObject.Properties.Name | Should -Contain "EvaluationPoints"
            $resultMinimal.PSObject.Properties.Name | Should -Contain "DensityEstimates"
            $resultMinimal.PSObject.Properties.Name | Should -Contain "Bandwidth"
            $resultMinimal.PSObject.Properties.Name | Should -Not -Contain "Options"

            # Tester le format "Raw"
            $optionsRaw = Get-KDEAdvancedOptions -OutputFormat "Raw"
            $resultRaw = Get-KernelDensityEstimation -Data $data -AdvancedOptions $optionsRaw

            # Afficher des informations de débogage
            Write-Host "Type de résultat: $($resultRaw.GetType().FullName)"
            Write-Host "Est-ce un Double? $($resultRaw -is [Double])"
            Write-Host "Est-ce un Double[]? $($resultRaw -is [Double[]])"

            # Vérifier que le résultat contient des valeurs numériques
            $resultRaw | Should -Not -BeNullOrEmpty
            $resultRaw | ForEach-Object { $_ | Should -BeOfType [Double] }
        }
    }
}
