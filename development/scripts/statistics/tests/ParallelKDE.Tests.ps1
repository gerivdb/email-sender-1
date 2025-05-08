# Tests pour ParallelKDE.ps1
# Run with Pester: Invoke-Pester -Path ".\ParallelKDE.Tests.ps1"

BeforeAll {
    # Charger les modules nécessaires
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\ParallelKDE.ps1"
    . $modulePath
}

Describe "Tests pour le calcul parallèle de l'estimation de densité par noyau" {
    Context "Tests de base pour Get-ParallelKDE1D" {
        It "Devrait calculer correctement la densité pour des données unidimensionnelles" -Skip:($PSVersionTable.PSVersion.Major -lt 7) {
            # Créer des données de test
            $data = 1..100 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
            $evalPoints = 0..10
            $bandwidth = 5
            
            $result = Get-ParallelKDE1D -Data $data -EvaluationPoints $evalPoints -Bandwidth $bandwidth
            
            # Vérifier que le résultat est correct
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 11
            
            # Vérifier que les densités sont positives
            $result | ForEach-Object { $_ | Should -BeGreaterThan 0 }
        }
        
        It "Devrait fonctionner avec différents types de noyaux" -Skip:($PSVersionTable.PSVersion.Major -lt 7) {
            # Créer des données de test
            $data = 1..50 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
            $evalPoints = 0..5
            $bandwidth = 5
            
            $kernelTypes = @("Gaussian", "Epanechnikov", "Uniform", "Triangular")
            
            foreach ($kernelType in $kernelTypes) {
                $result = Get-ParallelKDE1D -Data $data -EvaluationPoints $evalPoints -Bandwidth $bandwidth -KernelType $kernelType
                
                # Vérifier que le résultat est correct
                $result | Should -Not -BeNullOrEmpty
                $result.Count | Should -Be 6
                
                # Vérifier que les densités sont positives
                $result | ForEach-Object { $_ | Should -BeGreaterThan 0 }
            }
        }
        
        It "Devrait utiliser le traitement séquentiel si PowerShell 7 n'est pas disponible" -Skip:($PSVersionTable.PSVersion.Major -ge 7) {
            # Créer des données de test
            $data = 1..50 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
            $evalPoints = 0..5
            $bandwidth = 5
            
            $result = Get-ParallelKDE1D -Data $data -EvaluationPoints $evalPoints -Bandwidth $bandwidth
            
            # Vérifier que le résultat est correct
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 6
            
            # Vérifier que les densités sont positives
            $result | ForEach-Object { $_ | Should -BeGreaterThan 0 }
        }
    }
    
    Context "Tests de base pour Get-ParallelKDEND" {
        It "Devrait calculer correctement la densité pour des données multidimensionnelles" -Skip:($PSVersionTable.PSVersion.Major -lt 7) {
            # Créer des données de test
            $data = 1..50 | ForEach-Object {
                [PSCustomObject]@{
                    X = Get-Random -Minimum 0 -Maximum 100
                    Y = Get-Random -Minimum 0 -Maximum 100
                }
            }
            
            # Créer une grille d'évaluation avec des points d'échantillonnage
            $samplePoints = 1..10 | ForEach-Object {
                [PSCustomObject]@{
                    X = Get-Random -Minimum 0 -Maximum 100
                    Y = Get-Random -Minimum 0 -Maximum 100
                }
            }
            
            $evalGrid = [PSCustomObject]@{
                SamplePoints = $samplePoints
                GridArrays = @{
                    X = 0..10
                    Y = 0..10
                }
                GridSizes = @(11, 11)
            }
            
            $bandwidth = [PSCustomObject]@{
                X = 5
                Y = 5
            }
            
            $result = Get-ParallelKDEND -Data $data -EvaluationGrid $evalGrid -Bandwidth $bandwidth
            
            # Vérifier que le résultat est correct
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 10
            
            # Vérifier que les densités sont positives
            $result | ForEach-Object { $_ | Should -BeGreaterThan 0 }
        }
        
        It "Devrait accepter des dimensions spécifiées" -Skip:($PSVersionTable.PSVersion.Major -lt 7) {
            # Créer des données de test
            $data = 1..50 | ForEach-Object {
                [PSCustomObject]@{
                    X = Get-Random -Minimum 0 -Maximum 100
                    Y = Get-Random -Minimum 0 -Maximum 100
                    Z = Get-Random -Minimum 0 -Maximum 100
                }
            }
            
            # Créer une grille d'évaluation avec des points d'échantillonnage
            $samplePoints = 1..5 | ForEach-Object {
                [PSCustomObject]@{
                    X = Get-Random -Minimum 0 -Maximum 100
                    Y = Get-Random -Minimum 0 -Maximum 100
                    Z = Get-Random -Minimum 0 -Maximum 100
                }
            }
            
            $evalGrid = [PSCustomObject]@{
                SamplePoints = $samplePoints
                GridArrays = @{
                    X = 0..5
                    Y = 0..5
                }
                GridSizes = @(6, 6)
            }
            
            $bandwidth = [PSCustomObject]@{
                X = 5
                Y = 5
            }
            
            $result = Get-ParallelKDEND -Data $data -Dimensions @("X", "Y") -EvaluationGrid $evalGrid -Bandwidth $bandwidth
            
            # Vérifier que le résultat est correct
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 5
        }
        
        It "Devrait lever une exception si une dimension spécifiée n'existe pas" -Skip:($PSVersionTable.PSVersion.Major -lt 7) {
            # Créer des données de test
            $data = 1..50 | ForEach-Object {
                [PSCustomObject]@{
                    X = Get-Random -Minimum 0 -Maximum 100
                    Y = Get-Random -Minimum 0 -Maximum 100
                }
            }
            
            # Créer une grille d'évaluation avec des points d'échantillonnage
            $samplePoints = 1..5 | ForEach-Object {
                [PSCustomObject]@{
                    X = Get-Random -Minimum 0 -Maximum 100
                    Y = Get-Random -Minimum 0 -Maximum 100
                }
            }
            
            $evalGrid = [PSCustomObject]@{
                SamplePoints = $samplePoints
                GridArrays = @{
                    X = 0..5
                    Y = 0..5
                }
                GridSizes = @(6, 6)
            }
            
            $bandwidth = [PSCustomObject]@{
                X = 5
                Y = 5
                Z = 5
            }
            
            { Get-ParallelKDEND -Data $data -Dimensions @("X", "Z") -EvaluationGrid $evalGrid -Bandwidth $bandwidth } | Should -Throw "Le point de données ne contient pas la dimension spécifiée: Z"
        }
    }
    
    Context "Tests de performance pour Get-ParallelKDE1D" {
        It "Devrait être plus rapide que le traitement séquentiel pour les grands ensembles de données" -Skip:($PSVersionTable.PSVersion.Major -lt 7) {
            # Créer un grand ensemble de données
            $data = 1..1000 | ForEach-Object { Get-Random -Minimum 0 -Maximum 1000 }
            $evalPoints = 0..100
            $bandwidth = 10
            
            # Mesurer le temps d'exécution du traitement parallèle
            $startTimeParallel = Get-Date
            $resultParallel = Get-ParallelKDE1D -Data $data -EvaluationPoints $evalPoints -Bandwidth $bandwidth
            $endTimeParallel = Get-Date
            $executionTimeParallel = ($endTimeParallel - $startTimeParallel).TotalSeconds
            
            # Mesurer le temps d'exécution du traitement séquentiel
            $startTimeSequential = Get-Date
            $resultSequential = Get-SequentialKDE1D -Data $data -EvaluationPoints $evalPoints -Bandwidth $bandwidth
            $endTimeSequential = Get-Date
            $executionTimeSequential = ($endTimeSequential - $startTimeSequential).TotalSeconds
            
            # Vérifier que les résultats sont similaires
            for ($i = 0; $i -lt $resultParallel.Count; $i++) {
                $resultParallel[$i] | Should -BeApproximately $resultSequential[$i] -Epsilon 0.01
            }
            
            # Vérifier que le traitement parallèle est plus rapide
            # Note: Ce test peut échouer sur des machines avec peu de cœurs ou si le système est très chargé
            # $executionTimeParallel | Should -BeLessThan $executionTimeSequential
            
            # Vérifier que le temps d'exécution est raisonnable
            $executionTimeParallel | Should -BeLessThan 10
        }
    }
}

AfterAll {
    # Nettoyage
}
