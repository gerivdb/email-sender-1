# Tests de comparaison entre les différents noyaux pour l'estimation de densité par noyau
# Run with Pester: Invoke-Pester -Path ".\KernelComparison.Tests.ps1"

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $PSScriptRoot
. "$scriptPath\GaussianKernel.ps1"
. "$scriptPath\EpanechnikovKernel.ps1"
. "$scriptPath\TriangularKernel.ps1"
. "$scriptPath\UniformKernel.ps1"
. "$scriptPath\BiweightKernel.ps1"
. "$scriptPath\TriweightKernel.ps1"
. "$scriptPath\CosineKernel.ps1"

# Fonction utilitaire pour générer des échantillons de distribution normale
function Get-NormalSample {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$NumPoints,

        [Parameter(Mandatory = $false)]
        [double]$Mean = 0,

        [Parameter(Mandatory = $false)]
        [double]$StdDev = 1
    )

    $sample = @()
    for ($i = 0; $i -lt $NumPoints; $i++) {
        # Méthode Box-Muller pour générer des nombres aléatoires suivant une distribution normale
        $u1 = [Math]::Max(0.0001, Get-Random -Minimum 0 -Maximum 1)
        $u2 = Get-Random -Minimum 0 -Maximum 1
        $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
        $sample += $Mean + $StdDev * $z
    }

    return $sample
}

# Fonction utilitaire pour générer des échantillons de distribution asymétrique
function Get-SkewedSample {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$NumPoints,

        [Parameter(Mandatory = $false)]
        [double]$Shape = 2.0
    )

    $sample = @()
    for ($i = 0; $i -lt $NumPoints; $i++) {
        # Générer un échantillon suivant une distribution gamma (asymétrique)
        $u = 0
        for ($j = 0; $j -lt $Shape; $j++) {
            $u -= [Math]::Log(Get-Random -Minimum 0.0001 -Maximum 1)
        }
        $sample += $u
    }

    return $sample
}

# Fonction utilitaire pour générer des échantillons de distribution multimodale
function Get-MultimodalSample {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$NumPoints,

        [Parameter(Mandatory = $false)]
        [double[]]$Means = @(0, 5),

        [Parameter(Mandatory = $false)]
        [double[]]$StdDevs = @(1, 1),

        [Parameter(Mandatory = $false)]
        [double[]]$Weights = @(0.5, 0.5)
    )

    # Normaliser les poids
    $sumWeights = ($Weights | Measure-Object -Sum).Sum
    $normalizedWeights = $Weights | ForEach-Object { $_ / $sumWeights }

    # Générer l'échantillon
    $sample = @()
    for ($i = 0; $i -lt $NumPoints; $i++) {
        # Choisir une composante en fonction des poids
        $u = Get-Random -Minimum 0 -Maximum 1
        $cumulativeWeight = 0
        $componentIndex = 0

        for ($j = 0; $j -lt $normalizedWeights.Length; $j++) {
            $cumulativeWeight += $normalizedWeights[$j]
            if ($u -lt $cumulativeWeight) {
                $componentIndex = $j
                break
            }
        }

        # Générer un échantillon suivant la composante choisie
        $u1 = [Math]::Max(0.0001, Get-Random -Minimum 0 -Maximum 1)
        $u2 = Get-Random -Minimum 0 -Maximum 1
        $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
        $sample += $Means[$componentIndex] + $StdDevs[$componentIndex] * $z
    }

    return $sample
}

# Fonction utilitaire pour générer des échantillons de distribution à queue lourde
function Get-HeavyTailedSample {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$NumPoints,

        [Parameter(Mandatory = $false)]
        [double]$Df = 3.0  # Degrés de liberté pour la distribution t de Student
    )

    $sample = @()
    for ($i = 0; $i -lt $NumPoints; $i++) {
        # Générer un échantillon suivant une distribution t de Student
        $u1 = [Math]::Max(0.0001, Get-Random -Minimum 0 -Maximum 1)
        $u2 = Get-Random -Minimum 0 -Maximum 1
        $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)  # Distribution normale standard
        $chi2 = 0
        for ($j = 0; $j -lt $Df; $j++) {
            $v = [Math]::Max(0.0001, Get-Random -Minimum 0 -Maximum 1)
            $chi2 -= 2 * [Math]::Log($v)
        }
        $t = $z / [Math]::Sqrt($chi2 / $Df)  # Distribution t de Student
        $sample += $t
    }

    return $sample
}

# Fonction utilitaire pour générer des échantillons de distribution uniforme
function Get-UniformSample {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$NumPoints,

        [Parameter(Mandatory = $false)]
        [double]$Min = 0,

        [Parameter(Mandatory = $false)]
        [double]$Max = 1
    )

    $sample = @()
    for ($i = 0; $i -lt $NumPoints; $i++) {
        $sample += Get-Random -Minimum $Min -Maximum $Max
    }

    return $sample
}

# Fonction utilitaire pour calculer l'erreur quadratique moyenne entre deux densités
function Get-MeanSquaredError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Density1,

        [Parameter(Mandatory = $true)]
        [double[]]$Density2
    )

    if ($Density1.Count -ne $Density2.Count) {
        throw "Les densités doivent avoir le même nombre de points."
    }

    $mse = 0
    for ($i = 0; $i -lt $Density1.Count; $i++) {
        $mse += [Math]::Pow($Density1[$i] - $Density2[$i], 2)
    }

    return $mse / $Density1.Count
}

# Fonction utilitaire pour calculer la densité théorique d'une distribution normale
function Get-NormalDensity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double]$X,

        [Parameter(Mandatory = $false)]
        [double]$Mean = 0,

        [Parameter(Mandatory = $false)]
        [double]$StdDev = 1
    )

    $z = ($X - $Mean) / $StdDev
    $density = (1 / ($StdDev * [Math]::Sqrt(2 * [Math]::PI))) * [Math]::Exp(-0.5 * $z * $z)

    return $density
}

# Fonction utilitaire pour calculer la densité théorique d'une distribution uniforme
function Get-UniformDensity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double]$X,

        [Parameter(Mandatory = $false)]
        [double]$Min = 0,

        [Parameter(Mandatory = $false)]
        [double]$Max = 1
    )

    if ($X -ge $Min -and $X -le $Max) {
        return 1 / ($Max - $Min)
    } else {
        return 0
    }
}

# Fonction utilitaire pour calculer la densité théorique d'une distribution bimodale
function Get-BimodalDensity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double]$X,

        [Parameter(Mandatory = $false)]
        [double]$Mean1 = -3,

        [Parameter(Mandatory = $false)]
        [double]$StdDev1 = 1,

        [Parameter(Mandatory = $false)]
        [double]$Mean2 = 3,

        [Parameter(Mandatory = $false)]
        [double]$StdDev2 = 1,

        [Parameter(Mandatory = $false)]
        [double]$Weight1 = 0.5
    )

    $density1 = Get-NormalDensity -X $X -Mean $Mean1 -StdDev $StdDev1
    $density2 = Get-NormalDensity -X $X -Mean $Mean2 -StdDev $StdDev2

    return $Weight1 * $density1 + (1 - $Weight1) * $density2
}

Describe "Tests de comparaison entre les différents noyaux" {
    Context "Tests de précision pour différentes distributions" {
        BeforeAll {
            # Générer des échantillons de différentes distributions
            $normalSample = Get-NormalSample -NumPoints 100 -Mean 0 -StdDev 1
            $skewedSample = Get-SkewedSample -NumPoints 100 -Shape 2.0
            $multimodalSample = Get-MultimodalSample -NumPoints 100 -Means @(-3, 3) -StdDevs @(1, 1) -Weights @(0.5, 0.5)
            $heavyTailedSample = Get-HeavyTailedSample -NumPoints 100 -Df 3.0
            $uniformSample = Get-UniformSample -NumPoints 100 -Min -1 -Max 1

            # Définir les points d'évaluation
            $normalEvalPoints = -3..3 | ForEach-Object { $_ / 2 }
            $skewedEvalPoints = 0..6 | ForEach-Object { $_ / 2 }
            $multimodalEvalPoints = -5..5 | ForEach-Object { $_ }
            $heavyTailedEvalPoints = -5..5 | ForEach-Object { $_ }
            $uniformEvalPoints = -2..2 | ForEach-Object { $_ / 2 }

            # Définir les noyaux à tester
            $kernelTypes = @("Gaussian", "Epanechnikov", "Triangular", "Uniform", "Biweight", "Triweight", "Cosine")

            # Calculer les densités théoriques
            $normalTheoreticalDensities = @()
            foreach ($x in $normalEvalPoints) {
                $density = Get-NormalDensity -X $x -Mean 0 -StdDev 1
                $normalTheoreticalDensities += $density
            }

            $uniformTheoreticalDensities = @()
            foreach ($x in $uniformEvalPoints) {
                $density = Get-UniformDensity -X $x -Min -1 -Max 1
                $uniformTheoreticalDensities += $density
            }

            $bimodalTheoreticalDensities = @()
            foreach ($x in $multimodalEvalPoints) {
                $density = Get-BimodalDensity -X $x -Mean1 -3 -StdDev1 1 -Mean2 3 -StdDev2 1 -Weight1 0.5
                $bimodalTheoreticalDensities += $density
            }
        }

        It "Comparaison des noyaux pour une distribution normale" {
            # Calculer les densités pour chaque noyau
            $kernelDensities = @{}
            $kernelMSEs = @{}

            foreach ($kernelType in $kernelTypes) {
                $densities = @()

                foreach ($x in $normalEvalPoints) {
                    $density = 0

                    switch ($kernelType) {
                        "Gaussian" {
                            $density = Get-GaussianKernelDensity -X $x -Data $normalSample
                        }
                        "Epanechnikov" {
                            $density = Get-EpanechnikovKernelDensity -X $x -Data $normalSample
                        }
                        "Triangular" {
                            $density = Get-TriangularKernelDensity -X $x -Data $normalSample
                        }
                        "Uniform" {
                            $density = Get-UniformKernelDensity -X $x -Data $normalSample
                        }
                        "Biweight" {
                            $density = Get-BiweightKernelDensity -X $x -Data $normalSample
                        }
                        "Triweight" {
                            $density = Get-TriweightKernelDensity -X $x -Data $normalSample
                        }
                        "Cosine" {
                            $density = Get-CosineKernelDensity -X $x -Data $normalSample
                        }
                    }

                    $densities += $density
                }

                $kernelDensities[$kernelType] = $densities
                $kernelMSEs[$kernelType] = Get-MeanSquaredError -Density1 $densities -Density2 $normalTheoreticalDensities
            }

            # Trier les noyaux par erreur croissante
            $sortedKernels = $kernelMSEs.GetEnumerator() | Sort-Object -Property Value

            # Afficher les résultats
            Write-Host "Erreurs quadratiques moyennes pour une distribution normale:"
            foreach ($kernel in $sortedKernels) {
                Write-Host "  $($kernel.Name): $($kernel.Value)"
            }

            # Vérifier que tous les noyaux ont une erreur raisonnable
            foreach ($kernelType in $kernelTypes) {
                $kernelMSEs[$kernelType] | Should -BeLessThan 0.1
            }
        }

        It "Comparaison des noyaux pour une distribution uniforme" {
            # Calculer les densités pour chaque noyau
            $kernelDensities = @{}
            $kernelMSEs = @{}

            foreach ($kernelType in $kernelTypes) {
                $densities = @()

                foreach ($x in $uniformEvalPoints) {
                    $density = 0

                    switch ($kernelType) {
                        "Gaussian" {
                            $density = Get-GaussianKernelDensity -X $x -Data $uniformSample
                        }
                        "Epanechnikov" {
                            $density = Get-EpanechnikovKernelDensity -X $x -Data $uniformSample
                        }
                        "Triangular" {
                            $density = Get-TriangularKernelDensity -X $x -Data $uniformSample
                        }
                        "Uniform" {
                            $density = Get-UniformKernelDensity -X $x -Data $uniformSample
                        }
                        "Biweight" {
                            $density = Get-BiweightKernelDensity -X $x -Data $uniformSample
                        }
                        "Triweight" {
                            $density = Get-TriweightKernelDensity -X $x -Data $uniformSample
                        }
                        "Cosine" {
                            $density = Get-CosineKernelDensity -X $x -Data $uniformSample
                        }
                    }

                    $densities += $density
                }

                $kernelDensities[$kernelType] = $densities
                $kernelMSEs[$kernelType] = Get-MeanSquaredError -Density1 $densities -Density2 $uniformTheoreticalDensities
            }

            # Trier les noyaux par erreur croissante
            $sortedKernels = $kernelMSEs.GetEnumerator() | Sort-Object -Property Value

            # Afficher les résultats
            Write-Host "Erreurs quadratiques moyennes pour une distribution uniforme:"
            foreach ($kernel in $sortedKernels) {
                Write-Host "  $($kernel.Name): $($kernel.Value)"
            }

            # Vérifier que tous les noyaux ont une erreur raisonnable
            foreach ($kernelType in $kernelTypes) {
                $kernelMSEs[$kernelType] | Should -BeLessThan 0.1
            }
        }
    }

    Context "Tests de performance pour différentes tailles de données" {
        It "Comparaison des performances des noyaux pour différentes tailles de données" {
            # Définir les tailles de données à tester
            $dataSizes = @(10, 100, 1000)

            # Définir les noyaux à tester
            $kernelTypes = @("Gaussian", "Epanechnikov", "Triangular", "Uniform", "Biweight", "Triweight", "Cosine")

            # Mesurer les performances pour chaque taille de données et chaque noyau
            $results = @{}

            foreach ($dataSize in $dataSizes) {
                $results[$dataSize] = @{}

                # Générer des données
                $data = Get-NormalSample -NumPoints $dataSize -Mean 0 -StdDev 1

                foreach ($kernelType in $kernelTypes) {
                    # Mesurer le temps d'exécution
                    $startTime = Get-Date

                    # Calculer la densité en un point
                    switch ($kernelType) {
                        "Gaussian" {
                            $density = Get-GaussianKernelDensity -X 0 -Data $data
                        }
                        "Epanechnikov" {
                            $density = Get-EpanechnikovKernelDensity -X 0 -Data $data
                        }
                        "Triangular" {
                            $density = Get-TriangularKernelDensity -X 0 -Data $data
                        }
                        "Uniform" {
                            $density = Get-UniformKernelDensity -X 0 -Data $data
                        }
                        "Biweight" {
                            $density = Get-BiweightKernelDensity -X 0 -Data $data
                        }
                        "Triweight" {
                            $density = Get-TriweightKernelDensity -X 0 -Data $data
                        }
                        "Cosine" {
                            $density = Get-CosineKernelDensity -X 0 -Data $data
                        }
                    }

                    $endTime = Get-Date
                    $executionTime = ($endTime - $startTime).TotalMilliseconds

                    $results[$dataSize][$kernelType] = $executionTime
                }
            }

            # Afficher les résultats
            foreach ($dataSize in $dataSizes) {
                Write-Host "Temps d'exécution (ms) pour $dataSize points:"
                $sortedKernels = $results[$dataSize].GetEnumerator() | Sort-Object -Property Value
                foreach ($kernel in $sortedKernels) {
                    Write-Host "  $($kernel.Name): $([Math]::Round($kernel.Value, 2))"
                }
            }

            # Vérifier que les noyaux optimisés sont plus rapides pour les grandes tailles de données
            $largeDataSize = $dataSizes[-1]
            $results[$largeDataSize]["Uniform"] | Should -BeLessThan $results[$largeDataSize]["Gaussian"]
            $results[$largeDataSize]["Triangular"] | Should -BeLessThan $results[$largeDataSize]["Gaussian"]
        }

        It "Comparaison des performances des fonctions optimisées et non optimisées" {
            # Définir la taille des données
            $dataSize = 1000

            # Générer des données
            $data = Get-NormalSample -NumPoints $dataSize -Mean 0 -StdDev 1

            # Mesurer les performances des fonctions non optimisées
            $startTime1 = Get-Date
            $density1 = Get-GaussianKernelDensity -X 0 -Data $data
            $endTime1 = Get-Date
            $executionTime1 = ($endTime1 - $startTime1).TotalMilliseconds

            # Mesurer les performances des fonctions optimisées
            $startTime2 = Get-Date
            $density2 = Get-OptimizedGaussianKernelDensity -X 0 -Data $data
            $endTime2 = Get-Date
            $executionTime2 = ($endTime2 - $startTime2).TotalMilliseconds

            # Afficher les résultats
            Write-Host "Temps d'exécution (ms) pour $dataSize points:"
            Write-Host "  Fonction non optimisée: $([Math]::Round($executionTime1, 2))"
            Write-Host "  Fonction optimisée: $([Math]::Round($executionTime2, 2))"
            Write-Host "  Accélération: $([Math]::Round($executionTime1 / $executionTime2, 2))x"

            # Vérifier que la fonction optimisée est plus rapide
            $executionTime2 | Should -BeLessThan $executionTime1

            # Vérifier que les résultats sont cohérents
            $density2 | Should -BeApproximately $density1 -Epsilon 0.0001
        }
    }

    Context "Tests de robustesse pour différentes distributions" {
        It "Les noyaux devraient être robustes aux valeurs aberrantes" {
            # Générer des données avec des valeurs aberrantes
            $data = Get-NormalSample -NumPoints 100 -Mean 0 -StdDev 1
            $data += @(10, 11, 12)  # Ajouter des valeurs aberrantes

            # Définir les noyaux à tester
            $kernelTypes = @("Gaussian", "Epanechnikov", "Triangular", "Uniform", "Biweight", "Triweight", "Cosine")

            # Calculer les densités pour chaque noyau
            $densities = @{}

            foreach ($kernelType in $kernelTypes) {
                $density = 0

                switch ($kernelType) {
                    "Gaussian" {
                        $density = Get-GaussianKernelDensity -X 0 -Data $data
                    }
                    "Epanechnikov" {
                        $density = Get-EpanechnikovKernelDensity -X 0 -Data $data
                    }
                    "Triangular" {
                        $density = Get-TriangularKernelDensity -X 0 -Data $data
                    }
                    "Uniform" {
                        $density = Get-UniformKernelDensity -X 0 -Data $data
                    }
                    "Biweight" {
                        $density = Get-BiweightKernelDensity -X 0 -Data $data
                    }
                    "Triweight" {
                        $density = Get-TriweightKernelDensity -X 0 -Data $data
                    }
                    "Cosine" {
                        $density = Get-CosineKernelDensity -X 0 -Data $data
                    }
                }

                $densities[$kernelType] = $density
            }

            # Afficher les résultats
            Write-Host "Densités au point 0 avec des valeurs aberrantes:"
            foreach ($kernelType in $kernelTypes) {
                Write-Host "  $($kernelType): $($densities[$kernelType])"
            }

            # Vérifier que tous les noyaux donnent des résultats raisonnables
            foreach ($kernelType in $kernelTypes) {
                $densities[$kernelType] | Should -BeGreaterThan 0
            }

            # Vérifier que les noyaux à support compact sont moins sensibles aux valeurs aberrantes
            $densities["Gaussian"] | Should -BeLessThan $densities["Uniform"]
            $densities["Gaussian"] | Should -BeLessThan $densities["Epanechnikov"]
            $densities["Gaussian"] | Should -BeLessThan $densities["Biweight"]
            $densities["Gaussian"] | Should -BeLessThan $densities["Triweight"]
        }
    }
}
