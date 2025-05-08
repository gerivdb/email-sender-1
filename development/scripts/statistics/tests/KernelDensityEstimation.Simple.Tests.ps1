BeforeAll {
    # Charger les modules nécessaires
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\AdaptiveSampling.ps1"
    . $modulePath
    
    $kdePath = Join-Path -Path $PSScriptRoot -ChildPath "..\KernelDensityEstimation.psm1"
    Import-Module $kdePath -Force
}

Describe "Tests simples pour Get-KernelDensityEstimation avec échantillonnage" {
    Context "Tests de base pour l'échantillonnage dans Get-KernelDensityEstimation" {
        It "Devrait fonctionner avec la méthode Auto et l'échantillonnage adaptatif" {
            # Générer un ensemble de données de taille moyenne
            $data = 1..200 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
            
            # Créer des options de sélection de la largeur de bande avec échantillonnage
            $options = [PSCustomObject]@{
                Methods               = @("Silverman", "Scott")
                Weights               = @{
                    Accuracy     = 1
                    Speed        = 1
                    Robustness   = 1
                    Adaptability = 1
                }
                AutoDetect            = $true
                KFoldCount            = 5
                MaxIterations         = 20
                Tolerance             = 0.1
                TimeoutSeconds        = 30
                BandwidthRange        = $null
                PreferSimpleMethods   = $true
                SmallDatasetThreshold = 20
                LargeDatasetThreshold = 100  # Définir un seuil bas pour activer l'échantillonnage
                CacheResults          = $false
                ObjectiveProfile      = "Balanced"
                GetFilteredMethods    = $null
            }
            
            # Appeler Get-KernelDensityEstimation avec la méthode Auto et les options
            $result = Get-KernelDensityEstimation -Data $data -BandwidthMethod "Auto" -BandwidthSelectionOptions $options
            
            # Vérifier que le résultat est valide
            $result | Should -Not -BeNullOrEmpty
            $result.Bandwidth | Should -BeGreaterThan 0
            $result.DensityEstimates | Should -Not -BeNullOrEmpty
            $result.DensityEstimates.Count | Should -Be $result.EvaluationPoints.Count
        }
        
        It "Devrait fonctionner avec le traitement parallèle si disponible" {
            # Vérifier si PowerShell 7+ est utilisé
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                # Générer un ensemble de données de taille moyenne
                $data = 1..200 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
                
                # Appeler Get-KernelDensityEstimation avec le traitement parallèle
                $result = Get-KernelDensityEstimation -Data $data -Parallel
                
                # Vérifier que le résultat est valide
                $result | Should -Not -BeNullOrEmpty
                $result.Bandwidth | Should -BeGreaterThan 0
                $result.DensityEstimates | Should -Not -BeNullOrEmpty
                $result.DensityEstimates.Count | Should -Be $result.EvaluationPoints.Count
            }
            else {
                Set-ItResult -Skipped -Because "PowerShell 7+ est requis pour le traitement parallèle"
            }
        }
    }
}
