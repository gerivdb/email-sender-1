# Tests pour l'estimation de densité par noyau avec des données multidimensionnelles
# Run with Pester: Invoke-Pester -Path ".\MultidimensionalData.Tests.ps1"

BeforeAll {
    # Charger les modules nécessaires
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\KernelDensityEstimateND.psm1"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force
    }
    
    $modulePath2D = Join-Path -Path $PSScriptRoot -ChildPath "..\KernelDensity2D.psm1"
    if (Test-Path $modulePath2D) {
        Import-Module $modulePath2D -Force
    }
    
    # Fonctions auxiliaires pour les tests
    function Get-MultivariateNormalSample {
        param (
            [int]$NumPoints = 100,
            [double[]]$Mean = @(0, 0),
            [double[,]]$Covariance = @(@(1, 0), @(0, 1)),
            [string[]]$DimensionNames = @("X", "Y")
        )
        
        # Vérifier que les dimensions correspondent
        $numDimensions = $Mean.Count
        if ($Covariance.GetLength(0) -ne $numDimensions -or $Covariance.GetLength(1) -ne $numDimensions) {
            throw "Les dimensions de la matrice de covariance ne correspondent pas au vecteur de moyenne."
        }
        
        if ($DimensionNames.Count -ne $numDimensions) {
            throw "Le nombre de noms de dimensions ne correspond pas au nombre de dimensions."
        }
        
        # Décomposition de Cholesky de la matrice de covariance
        $L = New-Object 'double[,]' $numDimensions, $numDimensions
        
        for ($i = 0; $i -lt $numDimensions; $i++) {
            for ($j = 0; $j -le $i; $j++) {
                $sum = 0
                
                for ($k = 0; $k -lt $j; $k++) {
                    $sum += $L[$i, $k] * $L[$j, $k]
                }
                
                if ($i -eq $j) {
                    $L[$i, $j] = [Math]::Sqrt($Covariance[$i, $i] - $sum)
                } else {
                    $L[$i, $j] = (1.0 / $L[$j, $j] * ($Covariance[$i, $j] - $sum))
                }
            }
        }
        
        # Générer des échantillons
        $samples = @()
        
        for ($n = 0; $n -lt $NumPoints; $n++) {
            # Générer des variables aléatoires normales standard
            $z = New-Object 'double[]' $numDimensions
            
            for ($i = 0; $i -lt $numDimensions; $i++) {
                $u1 = Get-Random -Minimum 0.0001 -Maximum 0.9999
                $u2 = Get-Random -Minimum 0.0001 -Maximum 0.9999
                $z[$i] = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
            }
            
            # Transformer les variables aléatoires
            $x = New-Object 'double[]' $numDimensions
            
            for ($i = 0; $i -lt $numDimensions; $i++) {
                $x[$i] = $Mean[$i]
                
                for ($j = 0; $j -le $i; $j++) {
                    $x[$i] += $L[$i, $j] * $z[$j]
                }
            }
            
            # Créer un objet avec les dimensions nommées
            $sample = [PSCustomObject]@{}
            
            for ($i = 0; $i -lt $numDimensions; $i++) {
                $sample | Add-Member -MemberType NoteProperty -Name $DimensionNames[$i] -Value $x[$i]
            }
            
            $samples += $sample
        }
        
        return $samples
    }
}

Describe "Tests pour l'estimation de densité par noyau avec des données multidimensionnelles" {
    Context "Tests de base pour les données 2D" {
        BeforeAll {
            # Générer des données de test 2D
            $mean = @(50, 50)
            $covariance = @(@(100, 0), @(0, 100))
            $testData2D = Get-MultivariateNormalSample -NumPoints 100 -Mean $mean -Covariance $covariance -DimensionNames @("X", "Y")
        }
        
        It "Get-KernelDensity2D fonctionne avec des données 2D" -Skip:(-not (Get-Command Get-KernelDensity2D -ErrorAction SilentlyContinue)) {
            $result = Get-KernelDensity2D -Data $testData2D
            
            $result | Should -Not -BeNullOrEmpty
            $result.Data | Should -Be $testData2D
            $result.XData | Should -Not -BeNullOrEmpty
            $result.YData | Should -Not -BeNullOrEmpty
            $result.EvaluationGrid | Should -Not -BeNullOrEmpty
            $result.DensityEstimates | Should -Not -BeNullOrEmpty
            $result.Parameters | Should -Not -BeNullOrEmpty
            $result.Statistics | Should -Not -BeNullOrEmpty
            
            # Vérifier que les statistiques sont correctes
            $result.Statistics.XMean | Should -BeApproximately $mean[0] -Epsilon 5
            $result.Statistics.YMean | Should -BeApproximately $mean[1] -Epsilon 5
            $result.Statistics.XStdDev | Should -BeApproximately [Math]::Sqrt($covariance[0, 0]) -Epsilon 3
            $result.Statistics.YStdDev | Should -BeApproximately [Math]::Sqrt($covariance[1, 1]) -Epsilon 3
        }
        
        It "Get-KernelDensity2D fonctionne avec différents types de noyaux" -Skip:(-not (Get-Command Get-KernelDensity2D -ErrorAction SilentlyContinue)) {
            $kernelTypes = @("Gaussian", "Epanechnikov", "Uniform", "Triangular")
            
            foreach ($kernelType in $kernelTypes) {
                $result = Get-KernelDensity2D -Data $testData2D -KernelType $kernelType
                
                $result | Should -Not -BeNullOrEmpty
                $result.Parameters.KernelType | Should -Be $kernelType
            }
        }
        
        It "Get-KernelDensity2D fonctionne avec différentes méthodes de sélection de largeur de bande" -Skip:(-not (Get-Command Get-KernelDensity2D -ErrorAction SilentlyContinue)) {
            $bandwidthMethods = @("Silverman", "Scott", "CrossValidation", "Plugin", "Adaptive")
            
            foreach ($bandwidthMethod in $bandwidthMethods) {
                $result = Get-KernelDensity2D -Data $testData2D -BandwidthMethod $bandwidthMethod
                
                $result | Should -Not -BeNullOrEmpty
                $result.Parameters.BandwidthMethod | Should -Be $bandwidthMethod
            }
        }
        
        It "Get-KernelDensity2D fonctionne avec une largeur de bande personnalisée" -Skip:(-not (Get-Command Get-KernelDensity2D -ErrorAction SilentlyContinue)) {
            $bandwidth = @(10, 15)
            $result = Get-KernelDensity2D -Data $testData2D -Bandwidth $bandwidth
            
            $result | Should -Not -BeNullOrEmpty
            $result.Parameters.Bandwidth | Should -Be $bandwidth
        }
        
        It "Get-KernelDensity2D fonctionne avec une taille de grille personnalisée" -Skip:(-not (Get-Command Get-KernelDensity2D -ErrorAction SilentlyContinue)) {
            $gridSize = @(30, 40)
            $result = Get-KernelDensity2D -Data $testData2D -GridSize $gridSize
            
            $result | Should -Not -BeNullOrEmpty
            $result.Parameters.GridSize | Should -Be $gridSize
            $result.EvaluationGrid.XGrid.Count | Should -Be $gridSize[0]
            $result.EvaluationGrid.YGrid.Count | Should -Be $gridSize[1]
        }
    }
    
    Context "Tests de base pour les données multidimensionnelles" {
        BeforeAll {
            # Générer des données de test 3D
            $mean = @(50, 50, 50)
            $covariance = @(@(100, 0, 0), @(0, 100, 0), @(0, 0, 100))
            $testData3D = Get-MultivariateNormalSample -NumPoints 100 -Mean $mean -Covariance $covariance -DimensionNames @("X", "Y", "Z")
            
            # Générer des données de test 4D
            $mean = @(50, 50, 50, 50)
            $covariance = @(@(100, 0, 0, 0), @(0, 100, 0, 0), @(0, 0, 100, 0), @(0, 0, 0, 100))
            $testData4D = Get-MultivariateNormalSample -NumPoints 100 -Mean $mean -Covariance $covariance -DimensionNames @("X", "Y", "Z", "W")
        }
        
        It "Get-KernelDensityEstimateND fonctionne avec des données 3D" -Skip:(-not (Get-Command Get-KernelDensityEstimateND -ErrorAction SilentlyContinue)) {
            $result = Get-KernelDensityEstimateND -Data $testData3D
            
            $result | Should -Not -BeNullOrEmpty
            $result.Data | Should -Be $testData3D
            $result.Dimensions | Should -Not -BeNullOrEmpty
            $result.Dimensions.Count | Should -Be 3
            $result.EvaluationGrid | Should -Not -BeNullOrEmpty
            $result.DensityEstimates | Should -Not -BeNullOrEmpty
            $result.Parameters | Should -Not -BeNullOrEmpty
            $result.Statistics | Should -Not -BeNullOrEmpty
            
            # Vérifier que les statistiques sont correctes
            $result.Statistics.DimensionStats.X.Mean | Should -BeApproximately $mean[0] -Epsilon 5
            $result.Statistics.DimensionStats.Y.Mean | Should -BeApproximately $mean[1] -Epsilon 5
            $result.Statistics.DimensionStats.Z.Mean | Should -BeApproximately $mean[2] -Epsilon 5
            $result.Statistics.DimensionStats.X.StdDev | Should -BeApproximately [Math]::Sqrt($covariance[0, 0]) -Epsilon 3
            $result.Statistics.DimensionStats.Y.StdDev | Should -BeApproximately [Math]::Sqrt($covariance[1, 1]) -Epsilon 3
            $result.Statistics.DimensionStats.Z.StdDev | Should -BeApproximately [Math]::Sqrt($covariance[2, 2]) -Epsilon 3
        }
        
        It "Get-KernelDensityEstimateND fonctionne avec des données 4D" -Skip:(-not (Get-Command Get-KernelDensityEstimateND -ErrorAction SilentlyContinue)) {
            $result = Get-KernelDensityEstimateND -Data $testData4D
            
            $result | Should -Not -BeNullOrEmpty
            $result.Data | Should -Be $testData4D
            $result.Dimensions | Should -Not -BeNullOrEmpty
            $result.Dimensions.Count | Should -Be 4
            $result.EvaluationGrid | Should -Not -BeNullOrEmpty
            $result.DensityEstimates | Should -Not -BeNullOrEmpty
            $result.Parameters | Should -Not -BeNullOrEmpty
            $result.Statistics | Should -Not -BeNullOrEmpty
            
            # Vérifier que les statistiques sont correctes
            $result.Statistics.DimensionStats.X.Mean | Should -BeApproximately $mean[0] -Epsilon 5
            $result.Statistics.DimensionStats.Y.Mean | Should -BeApproximately $mean[1] -Epsilon 5
            $result.Statistics.DimensionStats.Z.Mean | Should -BeApproximately $mean[2] -Epsilon 5
            $result.Statistics.DimensionStats.W.Mean | Should -BeApproximately $mean[3] -Epsilon 5
        }
        
        It "Get-KernelDensityEstimateND fonctionne avec un sous-ensemble de dimensions" -Skip:(-not (Get-Command Get-KernelDensityEstimateND -ErrorAction SilentlyContinue)) {
            $result = Get-KernelDensityEstimateND -Data $testData3D -Dimensions @("X", "Y")
            
            $result | Should -Not -BeNullOrEmpty
            $result.Dimensions | Should -Not -BeNullOrEmpty
            $result.Dimensions.Count | Should -Be 2
            $result.Dimensions[0] | Should -Be "X"
            $result.Dimensions[1] | Should -Be "Y"
        }
        
        It "Get-KernelDensityEstimateND fonctionne avec différents types de noyaux" -Skip:(-not (Get-Command Get-KernelDensityEstimateND -ErrorAction SilentlyContinue)) {
            $kernelTypes = @("Gaussian", "Epanechnikov")
            
            foreach ($kernelType in $kernelTypes) {
                $result = Get-KernelDensityEstimateND -Data $testData3D -KernelType $kernelType
                
                $result | Should -Not -BeNullOrEmpty
                $result.Parameters.KernelType | Should -Be $kernelType
            }
        }
        
        It "Get-KernelDensityEstimateND fonctionne avec différentes méthodes de sélection de largeur de bande" -Skip:(-not (Get-Command Get-KernelDensityEstimateND -ErrorAction SilentlyContinue)) {
            $bandwidthMethods = @("Silverman", "Scott")
            
            foreach ($bandwidthMethod in $bandwidthMethods) {
                $result = Get-KernelDensityEstimateND -Data $testData3D -BandwidthMethod $bandwidthMethod
                
                $result | Should -Not -BeNullOrEmpty
                $result.Parameters.BandwidthMethod | Should -Be $bandwidthMethod
            }
        }
        
        It "Get-KernelDensityEstimateND fonctionne avec une largeur de bande personnalisée" -Skip:(-not (Get-Command Get-KernelDensityEstimateND -ErrorAction SilentlyContinue)) {
            $bandwidth = [PSCustomObject]@{
                X = 10
                Y = 15
                Z = 20
            }
            
            $result = Get-KernelDensityEstimateND -Data $testData3D -Bandwidth $bandwidth
            
            $result | Should -Not -BeNullOrEmpty
            $result.Parameters.Bandwidth | Should -Be $bandwidth
        }
        
        It "Get-KernelDensityEstimateND fonctionne avec MaxDimensions" -Skip:(-not (Get-Command Get-KernelDensityEstimateND -ErrorAction SilentlyContinue)) {
            $result = Get-KernelDensityEstimateND -Data $testData4D -MaxDimensions 2
            
            $result | Should -Not -BeNullOrEmpty
            $result.Parameters.MaxDimensions | Should -Be 2
            $result.EvaluationGrid.IsSampled | Should -Be $true
        }
    }
    
    Context "Tests de performance" {
        BeforeAll {
            # Générer un grand ensemble de données 2D
            $mean = @(50, 50)
            $covariance = @(@(100, 0), @(0, 100))
            $largeData2D = Get-MultivariateNormalSample -NumPoints 1000 -Mean $mean -Covariance $covariance -DimensionNames @("X", "Y")
            
            # Générer un grand ensemble de données 3D
            $mean = @(50, 50, 50)
            $covariance = @(@(100, 0, 0), @(0, 100, 0), @(0, 0, 100))
            $largeData3D = Get-MultivariateNormalSample -NumPoints 1000 -Mean $mean -Covariance $covariance -DimensionNames @("X", "Y", "Z")
        }
        
        It "Get-KernelDensity2D traite efficacement de grands ensembles de données" -Skip:(-not (Get-Command Get-KernelDensity2D -ErrorAction SilentlyContinue)) {
            # Mesurer le temps d'exécution
            $startTime = Get-Date
            $result = Get-KernelDensity2D -Data $largeData2D -GridSize @(20, 20)
            $endTime = Get-Date
            $executionTime = ($endTime - $startTime).TotalSeconds
            
            $result | Should -Not -BeNullOrEmpty
            $executionTime | Should -BeLessThan 10
        }
        
        It "Get-KernelDensityEstimateND traite efficacement de grands ensembles de données" -Skip:(-not (Get-Command Get-KernelDensityEstimateND -ErrorAction SilentlyContinue)) {
            # Mesurer le temps d'exécution
            $startTime = Get-Date
            $result = Get-KernelDensityEstimateND -Data $largeData3D -GridSize 10
            $endTime = Get-Date
            $executionTime = ($endTime - $startTime).TotalSeconds
            
            $result | Should -Not -BeNullOrEmpty
            $executionTime | Should -BeLessThan 20
        }
    }
}

AfterAll {
    # Nettoyage
}
