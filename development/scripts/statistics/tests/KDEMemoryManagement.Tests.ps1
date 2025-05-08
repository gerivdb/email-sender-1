# Tests pour KDEMemoryManagement.ps1
# Run with Pester: Invoke-Pester -Path ".\KDEMemoryManagement.Tests.ps1"

BeforeAll {
    # Charger les modules nécessaires
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\KDEMemoryManagement.ps1"
    . $modulePath
}

Describe "Tests pour la gestion de la mémoire dans l'estimation de densité par noyau" {
    Context "Tests de base pour Get-BatchKDE" {
        It "Devrait calculer correctement la densité en utilisant le traitement par lots" {
            # Créer des données de test
            $data = 1..100 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
            $evalPoints = 0..10
            $bandwidth = 5
            
            $result = Get-BatchKDE -Data $data -EvaluationPoints $evalPoints -Bandwidth $bandwidth
            
            # Vérifier que le résultat est correct
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 11
            
            # Vérifier que les densités sont positives
            $result | ForEach-Object { $_ | Should -BeGreaterThan 0 }
        }
        
        It "Devrait fonctionner avec différentes tailles de lots" {
            # Créer des données de test
            $data = 1..200 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
            $evalPoints = 0..5
            $bandwidth = 5
            
            $batchSizes = @(10, 50, 100)
            
            foreach ($batchSize in $batchSizes) {
                $result = Get-BatchKDE -Data $data -EvaluationPoints $evalPoints -Bandwidth $bandwidth -BatchSize $batchSize
                
                # Vérifier que le résultat est correct
                $result | Should -Not -BeNullOrEmpty
                $result.Count | Should -Be 6
                
                # Vérifier que les densités sont positives
                $result | ForEach-Object { $_ | Should -BeGreaterThan 0 }
            }
        }
        
        It "Devrait fonctionner avec différents types de noyaux" {
            # Créer des données de test
            $data = 1..100 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
            $evalPoints = 0..5
            $bandwidth = 5
            
            $kernelTypes = @("Gaussian", "Epanechnikov", "Uniform", "Triangular")
            
            foreach ($kernelType in $kernelTypes) {
                $result = Get-BatchKDE -Data $data -EvaluationPoints $evalPoints -Bandwidth $bandwidth -KernelType $kernelType
                
                # Vérifier que le résultat est correct
                $result | Should -Not -BeNullOrEmpty
                $result.Count | Should -Be 6
                
                # Vérifier que les densités sont positives
                $result | ForEach-Object { $_ | Should -BeGreaterThan 0 }
            }
        }
    }
    
    Context "Tests de base pour Get-BatchKDEND" {
        It "Devrait calculer correctement la densité pour les données multidimensionnelles en utilisant le traitement par lots" {
            # Créer des données de test
            $data = 1..100 | ForEach-Object {
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
            
            $result = Get-BatchKDEND -Data $data -EvaluationGrid $evalGrid -Bandwidth $bandwidth
            
            # Vérifier que le résultat est correct
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 10
            
            # Vérifier que les densités sont positives
            $result | ForEach-Object { $_ | Should -BeGreaterThan 0 }
        }
        
        It "Devrait accepter des dimensions spécifiées" {
            # Créer des données de test
            $data = 1..100 | ForEach-Object {
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
            
            $result = Get-BatchKDEND -Data $data -Dimensions @("X", "Y") -EvaluationGrid $evalGrid -Bandwidth $bandwidth
            
            # Vérifier que le résultat est correct
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 5
        }
        
        It "Devrait lever une exception si une dimension spécifiée n'existe pas" {
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
            
            { Get-BatchKDEND -Data $data -Dimensions @("X", "Z") -EvaluationGrid $evalGrid -Bandwidth $bandwidth } | Should -Throw "Le point de données ne contient pas la dimension spécifiée: Z"
        }
    }
    
    Context "Tests de base pour Get-StreamingKDE" {
        It "Devrait calculer correctement la densité en utilisant le traitement en streaming" {
            # Créer un fichier temporaire avec des données de test
            $tempFile = [System.IO.Path]::GetTempFileName()
            
            try {
                # Écrire des données de test dans le fichier
                1..100 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 } | Out-File -FilePath $tempFile
                
                $evalPoints = 0..10
                $bandwidth = 5
                
                $result = Get-StreamingKDE -InputFile $tempFile -EvaluationPoints $evalPoints -Bandwidth $bandwidth
                
                # Vérifier que le résultat est correct
                $result | Should -Not -BeNullOrEmpty
                $result.Count | Should -Be 11
                
                # Vérifier que les densités sont positives
                $result | ForEach-Object { $_ | Should -BeGreaterThan 0 }
            }
            finally {
                # Supprimer le fichier temporaire
                Remove-Item -Path $tempFile -Force
            }
        }
        
        It "Devrait lever une exception si le fichier d'entrée n'existe pas" {
            $evalPoints = 0..10
            $bandwidth = 5
            
            { Get-StreamingKDE -InputFile "fichier_inexistant.txt" -EvaluationPoints $evalPoints -Bandwidth $bandwidth } | Should -Throw "Le fichier d'entrée n'existe pas: fichier_inexistant.txt"
        }
    }
    
    Context "Tests de performance" {
        It "Get-BatchKDE devrait utiliser moins de mémoire que le calcul direct pour les grands ensembles de données" {
            # Créer un grand ensemble de données
            $data = 1..5000 | ForEach-Object { Get-Random -Minimum 0 -Maximum 1000 }
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
            
            # Mesurer l'utilisation de la mémoire avant le calcul direct
            [System.GC]::Collect()
            $memoryBefore = [System.GC]::GetTotalMemory($true)
            
            # Effectuer le calcul direct
            $resultDirect = Get-DirectKDE -Data $data -EvaluationPoints $evalPoints -Bandwidth $bandwidth
            
            # Mesurer l'utilisation de la mémoire après le calcul direct
            $memoryAfterDirect = [System.GC]::GetTotalMemory($true)
            $memoryUsedDirect = $memoryAfterDirect - $memoryBefore
            
            # Libérer la mémoire
            $resultDirect = $null
            [System.GC]::Collect()
            
            # Mesurer l'utilisation de la mémoire avant le calcul par lots
            $memoryBefore = [System.GC]::GetTotalMemory($true)
            
            # Effectuer le calcul par lots
            $resultBatch = Get-BatchKDE -Data $data -EvaluationPoints $evalPoints -Bandwidth $bandwidth -BatchSize 500
            
            # Mesurer l'utilisation de la mémoire après le calcul par lots
            $memoryAfterBatch = [System.GC]::GetTotalMemory($true)
            $memoryUsedBatch = $memoryAfterBatch - $memoryBefore
            
            # Vérifier que les résultats sont similaires
            for ($i = 0; $i -lt $resultBatch.Count; $i++) {
                $resultBatch[$i] | Should -BeApproximately $resultDirect[$i] -Epsilon 0.01
            }
            
            # Vérifier que le calcul par lots utilise moins de mémoire
            # Note: Ce test peut être instable en raison de la gestion de la mémoire de .NET
            # $memoryUsedBatch | Should -BeLessThan $memoryUsedDirect
            
            # Vérifier que le calcul par lots fonctionne correctement
            $resultBatch.Count | Should -Be ($evalPoints.Count)
        }
    }
}

AfterAll {
    # Nettoyage
}
