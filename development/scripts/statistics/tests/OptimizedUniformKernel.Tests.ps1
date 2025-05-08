# Tests pour les fonctions optimisées du noyau uniforme (rectangular) dans l'estimation de densité par noyau
# Run with Pester: Invoke-Pester -Path ".\OptimizedUniformKernel.Tests.ps1"

BeforeAll {
    # Charger le module du noyau uniforme
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UniformKernel.ps1"
    if (Test-Path $modulePath) {
        . $modulePath
    } else {
        throw "Le module UniformKernel.ps1 n'a pas été trouvé dans le répertoire parent."
    }

    # Fonctions auxiliaires pour les tests
    function Get-NormalSample {
        param (
            [int]$NumPoints = 100,
            [double]$Mean = 0,
            [double]$StdDev = 1
        )

        $samples = @()

        for ($i = 0; $i -lt $NumPoints; $i++) {
            # Méthode Box-Muller pour générer des variables aléatoires normales
            $u1 = Get-Random -Minimum 0.0001 -Maximum 0.9999
            $u2 = Get-Random -Minimum 0.0001 -Maximum 0.9999
            $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)

            # Transformer pour obtenir la moyenne et l'écart-type souhaités
            $samples += $Mean + $StdDev * $z
        }

        return $samples
    }

    function Get-MultivariateNormalSample {
        param (
            [int]$NumPoints = 100,
            [double[]]$Mean = @(0, 0),
            [double[, ]]$Covariance = @(@(1, 0), @(0, 1)),
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

Describe "Tests pour les fonctions optimisées du noyau uniforme" {
    Context "Tests de base pour Get-OptimizedUniformKernelDensity" {
        # Générer des données de test en dehors du bloc BeforeAll
        # pour éviter les avertissements PSScriptAnalyzer sur les variables non utilisées
        $script:testData1 = Get-NormalSample -NumPoints 100 -Mean 50 -StdDev 10

        It "Devrait calculer la densité correctement" {
            $result = Get-OptimizedUniformKernelDensity -X 50 -Data $script:testData1 -Bandwidth 5
            $result | Should -BeGreaterThan 0
        }

        It "Devrait calculer la largeur de bande optimale si non spécifiée" {
            $result = Get-OptimizedUniformKernelDensity -X 50 -Data $script:testData1
            $result | Should -BeGreaterThan 0
        }

        It "Devrait lever une exception si les données contiennent moins de 2 points" {
            { Get-OptimizedUniformKernelDensity -X 50 -Data @(1) } | Should -Throw "Les données doivent contenir au moins 2 points pour l'estimation de densité par noyau."
        }

        It "Devrait donner des résultats cohérents avec la fonction de base" {
            $resultBase = Get-UniformKernelDensity -X 50 -Data $script:testData1 -Bandwidth 5
            $resultOptimized = Get-OptimizedUniformKernelDensity -X 50 -Data $script:testData1 -Bandwidth 5

            $resultOptimized | Should -BeApproximately $resultBase -Epsilon 0.0001
        }
    }

    Context "Tests de base pour Get-OptimizedUniformKernelDensityMultiplePoints" {
        # Générer des données de test en dehors du bloc BeforeAll
        # pour éviter les avertissements PSScriptAnalyzer sur les variables non utilisées
        $script:testData2 = Get-NormalSample -NumPoints 100 -Mean 50 -StdDev 10
        $script:evalPoints1 = 40..60

        It "Devrait calculer la densité correctement pour plusieurs points" {
            $result = Get-OptimizedUniformKernelDensityMultiplePoints -EvaluationPoints $script:evalPoints1 -Data $script:testData2 -Bandwidth 5
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be $script:evalPoints1.Count
            $result[0].Density | Should -BeGreaterThan 0
        }

        It "Devrait calculer la largeur de bande optimale si non spécifiée" {
            $result = Get-OptimizedUniformKernelDensityMultiplePoints -EvaluationPoints $script:evalPoints1 -Data $script:testData2
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be $script:evalPoints1.Count
            $result[0].Density | Should -BeGreaterThan 0
        }

        It "Devrait lever une exception si les données contiennent moins de 2 points" {
            { Get-OptimizedUniformKernelDensityMultiplePoints -EvaluationPoints $script:evalPoints1 -Data @(1) } | Should -Throw "Les données doivent contenir au moins 2 points pour l'estimation de densité par noyau."
        }

        It "Devrait donner des résultats cohérents avec la fonction de base" {
            $resultBase = $script:evalPoints1 | ForEach-Object { Get-UniformKernelDensity -X $_ -Data $script:testData2 -Bandwidth 5 }
            $resultOptimized = Get-OptimizedUniformKernelDensityMultiplePoints -EvaluationPoints $script:evalPoints1 -Data $script:testData2 -Bandwidth 5

            for ($i = 0; $i -lt $script:evalPoints1.Count; $i++) {
                $resultOptimized[$i].Density | Should -BeApproximately $resultBase[$i] -Epsilon 0.0001
            }
        }
    }

    Context "Tests de base pour Get-UniformKernelDensityND" {
        # Générer des données de test bidimensionnelles et le point d'évaluation en dehors du bloc BeforeAll
        # pour éviter les avertissements PSScriptAnalyzer sur les variables non utilisées
        $script:testData2D = Get-MultivariateNormalSample -NumPoints 100 -Mean @(50, 50) -Covariance @(@(100, 0), @(0, 100)) -DimensionNames @("X", "Y")

        $script:point2D = [PSCustomObject]@{
            X = 50
            Y = 50
        }

        It "Devrait calculer la densité correctement pour des données bidimensionnelles" {
            $result = Get-UniformKernelDensityND -Point $script:point2D -Data $script:testData2D
            $result | Should -BeGreaterThan 0
        }

        It "Devrait calculer la largeur de bande optimale si non spécifiée" {
            $result = Get-UniformKernelDensityND -Point $script:point2D -Data $script:testData2D
            $result | Should -BeGreaterThan 0
        }

        It "Devrait lever une exception si les données contiennent moins de 2 points" {
            { Get-UniformKernelDensityND -Point $script:point2D -Data @($script:testData2D[0]) } | Should -Throw "Les données doivent contenir au moins 2 points pour l'estimation de densité par noyau."
        }

        It "Devrait fonctionner avec une largeur de bande unique" {
            $result = Get-UniformKernelDensityND -Point $script:point2D -Data $script:testData2D -Bandwidth 10
            $result | Should -BeGreaterThan 0
        }

        It "Devrait fonctionner avec une largeur de bande par dimension" {
            $bandwidth = [PSCustomObject]@{
                X = 10
                Y = 20
            }
            $result = Get-UniformKernelDensityND -Point $script:point2D -Data $script:testData2D -Bandwidth $bandwidth
            $result | Should -BeGreaterThan 0
        }

        It "Devrait lever une exception si la largeur de bande ne contient pas les dimensions spécifiées" {
            $bandwidth = [PSCustomObject]@{
                X = 10
                Z = 20
            }
            { Get-UniformKernelDensityND -Point $script:point2D -Data $script:testData2D -Bandwidth $bandwidth } | Should -Throw "La largeur de bande ne contient pas la dimension spécifiée: Y"
        }

        It "Devrait lever une exception si le point d'évaluation ne contient pas les dimensions spécifiées" {
            $invalidPoint = [PSCustomObject]@{
                X = 50
                Z = 50
            }
            { Get-UniformKernelDensityND -Point $invalidPoint -Data $script:testData2D } | Should -Throw "Le point d'évaluation ne contient pas la dimension spécifiée: Y"
        }
    }

    Context "Tests avec des données tridimensionnelles" {
        # Générer des données de test tridimensionnelles et le point d'évaluation en dehors du bloc BeforeAll
        # pour éviter les avertissements PSScriptAnalyzer sur les variables non utilisées
        $script:testData3D = Get-MultivariateNormalSample -NumPoints 100 -Mean @(50, 50, 50) -Covariance @(@(100, 0, 0), @(0, 100, 0), @(0, 0, 100)) -DimensionNames @("X", "Y", "Z")

        $script:point3D = [PSCustomObject]@{
            X = 50
            Y = 50
            Z = 50
        }

        It "Devrait calculer la densité correctement pour des données tridimensionnelles" {
            $result = Get-UniformKernelDensityND -Point $script:point3D -Data $script:testData3D
            $result | Should -BeGreaterThan 0
        }

        It "Devrait fonctionner avec un sous-ensemble de dimensions" {
            $result = Get-UniformKernelDensityND -Point $script:point3D -Data $script:testData3D -Dimensions @("X", "Y")
            $result | Should -BeGreaterThan 0
        }
    }

    Context "Tests de performance" {
        # Générer des données de test en dehors du bloc BeforeAll
        # pour éviter les avertissements PSScriptAnalyzer sur les variables non utilisées
        $script:testData3 = Get-NormalSample -NumPoints 1000 -Mean 50 -StdDev 10
        $script:evalPoints2 = 40..60

        It "La fonction optimisée devrait être plus rapide que la fonction de base" {
            # Mesurer le temps d'exécution de la fonction de base
            $startTime = Get-Date
            $script:evalPoints2 | ForEach-Object { Get-UniformKernelDensity -X $_ -Data $script:testData3 -Bandwidth 5 }
            $endTime = Get-Date
            $baseTime = ($endTime - $startTime).TotalMilliseconds

            # Mesurer le temps d'exécution de la fonction optimisée
            $startTime = Get-Date
            $script:evalPoints2 | ForEach-Object { Get-OptimizedUniformKernelDensity -X $_ -Data $script:testData3 -Bandwidth 5 }
            $endTime = Get-Date
            $optimizedTime = ($endTime - $startTime).TotalMilliseconds

            # La fonction optimisée devrait être plus rapide
            $optimizedTime | Should -BeLessThan $baseTime
        }

        It "La fonction optimisée pour plusieurs points devrait être plus rapide que la fonction optimisée pour un seul point" {
            # Mesurer le temps d'exécution de la fonction optimisée pour un seul point
            $startTime = Get-Date
            $script:evalPoints2 | ForEach-Object { Get-OptimizedUniformKernelDensity -X $_ -Data $script:testData3 -Bandwidth 5 }
            $endTime = Get-Date
            $singlePointTime = ($endTime - $startTime).TotalMilliseconds

            # Mesurer le temps d'exécution de la fonction optimisée pour plusieurs points
            $startTime = Get-Date
            Get-OptimizedUniformKernelDensityMultiplePoints -EvaluationPoints $script:evalPoints2 -Data $script:testData3 -Bandwidth 5
            $endTime = Get-Date
            $multiplePointsTime = ($endTime - $startTime).TotalMilliseconds

            # La fonction optimisée pour plusieurs points devrait être plus rapide
            $multiplePointsTime | Should -BeLessThan $singlePointTime
        }
    }
}

AfterAll {
    # Nettoyage
}
