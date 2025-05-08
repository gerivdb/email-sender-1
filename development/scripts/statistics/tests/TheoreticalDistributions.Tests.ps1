# Tests de validation avec des distributions théoriques connues
# Run with Pester: Invoke-Pester -Path ".\TheoreticalDistributions.Tests.ps1"

BeforeAll {
    # Charger les modules nécessaires
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\KernelDensityEstimation.psm1"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force
    }
    
    $modulePath2D = Join-Path -Path $PSScriptRoot -ChildPath "..\KernelDensity2D.psm1"
    if (Test-Path $modulePath2D) {
        Import-Module $modulePath2D -Force
    }
    
    $modulePathND = Join-Path -Path $PSScriptRoot -ChildPath "..\KernelDensityEstimateND.psm1"
    if (Test-Path $modulePathND) {
        Import-Module $modulePathND -Force
    }
    
    # Fonctions pour générer des échantillons à partir de distributions théoriques
    function Get-NormalSample {
        param (
            [int]$NumPoints = 1000,
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
    
    function Get-UniformSample {
        param (
            [int]$NumPoints = 1000,
            [double]$Min = 0,
            [double]$Max = 1
        )
        
        $samples = @()
        
        for ($i = 0; $i -lt $NumPoints; $i++) {
            $samples += $Min + (Get-Random -Minimum 0 -Maximum 10000) / 10000 * ($Max - $Min)
        }
        
        return $samples
    }
    
    function Get-ExponentialSample {
        param (
            [int]$NumPoints = 1000,
            [double]$Rate = 1
        )
        
        $samples = @()
        
        for ($i = 0; $i -lt $NumPoints; $i++) {
            $u = Get-Random -Minimum 0.0001 -Maximum 0.9999
            $samples += -[Math]::Log($u) / $Rate
        }
        
        return $samples
    }
    
    function Get-BimodalSample {
        param (
            [int]$NumPoints = 1000,
            [double]$Mean1 = -3,
            [double]$StdDev1 = 1,
            [double]$Mean2 = 3,
            [double]$StdDev2 = 1,
            [double]$Weight1 = 0.5
        )
        
        $samples = @()
        
        for ($i = 0; $i -lt $NumPoints; $i++) {
            $u = Get-Random -Minimum 0 -Maximum 1
            
            if ($u -lt $Weight1) {
                # Échantillon de la première distribution normale
                $u1 = Get-Random -Minimum 0.0001 -Maximum 0.9999
                $u2 = Get-Random -Minimum 0.0001 -Maximum 0.9999
                $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
                $samples += $Mean1 + $StdDev1 * $z
            } else {
                # Échantillon de la seconde distribution normale
                $u1 = Get-Random -Minimum 0.0001 -Maximum 0.9999
                $u2 = Get-Random -Minimum 0.0001 -Maximum 0.9999
                $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
                $samples += $Mean2 + $StdDev2 * $z
            }
        }
        
        return $samples
    }
    
    function Get-BivariateNormalSample {
        param (
            [int]$NumPoints = 1000,
            [double[]]$Mean = @(0, 0),
            [double[,]]$Covariance = @(@(1, 0), @(0, 1))
        )
        
        # Décomposition de Cholesky de la matrice de covariance
        $L = New-Object 'double[,]' 2, 2
        
        $L[0, 0] = [Math]::Sqrt($Covariance[0, 0])
        $L[1, 0] = $Covariance[1, 0] / $L[0, 0]
        $L[1, 1] = [Math]::Sqrt($Covariance[1, 1] - $L[1, 0] * $L[1, 0])
        
        $samples = @()
        
        for ($i = 0; $i -lt $NumPoints; $i++) {
            # Générer deux variables aléatoires normales standard
            $u1 = Get-Random -Minimum 0.0001 -Maximum 0.9999
            $u2 = Get-Random -Minimum 0.0001 -Maximum 0.9999
            $z1 = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
            
            $u3 = Get-Random -Minimum 0.0001 -Maximum 0.9999
            $u4 = Get-Random -Minimum 0.0001 -Maximum 0.9999
            $z2 = [Math]::Sqrt(-2 * [Math]::Log($u3)) * [Math]::Cos(2 * [Math]::PI * $u4)
            
            # Transformer les variables aléatoires
            $x = $Mean[0] + $L[0, 0] * $z1
            $y = $Mean[1] + $L[1, 0] * $z1 + $L[1, 1] * $z2
            
            $samples += [PSCustomObject]@{
                X = $x
                Y = $y
            }
        }
        
        return $samples
    }
    
    # Fonctions pour calculer les densités théoriques
    function Get-NormalDensity {
        param (
            [double]$X,
            [double]$Mean = 0,
            [double]$StdDev = 1
        )
        
        return (1 / ($StdDev * [Math]::Sqrt(2 * [Math]::PI))) * [Math]::Exp(-0.5 * [Math]::Pow(($X - $Mean) / $StdDev, 2))
    }
    
    function Get-UniformDensity {
        param (
            [double]$X,
            [double]$Min = 0,
            [double]$Max = 1
        )
        
        if ($X -ge $Min -and $X -le $Max) {
            return 1 / ($Max - $Min)
        }
        
        return 0
    }
    
    function Get-ExponentialDensity {
        param (
            [double]$X,
            [double]$Rate = 1
        )
        
        if ($X -ge 0) {
            return $Rate * [Math]::Exp(-$Rate * $X)
        }
        
        return 0
    }
    
    function Get-BimodalDensity {
        param (
            [double]$X,
            [double]$Mean1 = -3,
            [double]$StdDev1 = 1,
            [double]$Mean2 = 3,
            [double]$StdDev2 = 1,
            [double]$Weight1 = 0.5
        )
        
        $density1 = Get-NormalDensity -X $X -Mean $Mean1 -StdDev $StdDev1
        $density2 = Get-NormalDensity -X $X -Mean $Mean2 -StdDev $StdDev2
        
        return $Weight1 * $density1 + (1 - $Weight1) * $density2
    }
    
    function Get-BivariateNormalDensity {
        param (
            [double]$X,
            [double]$Y,
            [double[]]$Mean = @(0, 0),
            [double[,]]$Covariance = @(@(1, 0), @(0, 1))
        )
        
        # Calculer le déterminant de la matrice de covariance
        $det = $Covariance[0, 0] * $Covariance[1, 1] - $Covariance[0, 1] * $Covariance[1, 0]
        
        # Calculer l'inverse de la matrice de covariance
        $invCov = New-Object 'double[,]' 2, 2
        $invCov[0, 0] = $Covariance[1, 1] / $det
        $invCov[0, 1] = -$Covariance[0, 1] / $det
        $invCov[1, 0] = -$Covariance[1, 0] / $det
        $invCov[1, 1] = $Covariance[0, 0] / $det
        
        # Calculer la distance de Mahalanobis au carré
        $dx = $X - $Mean[0]
        $dy = $Y - $Mean[1]
        $mahalanobisSquared = $dx * $invCov[0, 0] * $dx + $dx * $invCov[0, 1] * $dy + $dy * $invCov[1, 0] * $dx + $dy * $invCov[1, 1] * $dy
        
        # Calculer la densité
        return (1 / (2 * [Math]::PI * [Math]::Sqrt($det))) * [Math]::Exp(-0.5 * $mahalanobisSquared)
    }
}

Describe "Tests de validation avec des distributions théoriques connues" {
    Context "Tests avec la distribution normale" {
        BeforeAll {
            # Paramètres de la distribution
            $mean = 50
            $stdDev = 10
            
            # Générer un échantillon
            $normalSample = Get-NormalSample -NumPoints 1000 -Mean $mean -StdDev $stdDev
            
            # Points d'évaluation
            $evalPoints = 0..100
        }
        
        It "L'estimation de densité par noyau correspond à la densité théorique" -Skip:(-not (Get-Command Get-KernelDensityEstimation -ErrorAction SilentlyContinue)) {
            # Calculer l'estimation de densité par noyau
            $kdeResult = Get-KernelDensityEstimation -Data $normalSample -KernelType "Gaussian" -BandwidthMethod "Silverman"
            
            # Calculer la densité théorique aux mêmes points
            $theoreticalDensities = $kdeResult.EvaluationPoints | ForEach-Object {
                Get-NormalDensity -X $_ -Mean $mean -StdDev $stdDev
            }
            
            # Calculer l'erreur quadratique moyenne
            $mse = 0
            for ($i = 0; $i -lt $kdeResult.DensityEstimates.Count; $i++) {
                $mse += [Math]::Pow($kdeResult.DensityEstimates[$i] - $theoreticalDensities[$i], 2)
            }
            $mse /= $kdeResult.DensityEstimates.Count
            
            # L'erreur quadratique moyenne devrait être faible
            $mse | Should -BeLessThan 0.0001
        }
    }
    
    Context "Tests avec la distribution uniforme" {
        BeforeAll {
            # Paramètres de la distribution
            $min = 20
            $max = 80
            
            # Générer un échantillon
            $uniformSample = Get-UniformSample -NumPoints 1000 -Min $min -Max $max
            
            # Points d'évaluation
            $evalPoints = 0..100
        }
        
        It "L'estimation de densité par noyau correspond à la densité théorique" -Skip:(-not (Get-Command Get-KernelDensityEstimation -ErrorAction SilentlyContinue)) {
            # Calculer l'estimation de densité par noyau
            $kdeResult = Get-KernelDensityEstimation -Data $uniformSample -KernelType "Gaussian" -BandwidthMethod "Silverman"
            
            # Calculer la densité théorique aux mêmes points
            $theoreticalDensities = $kdeResult.EvaluationPoints | ForEach-Object {
                Get-UniformDensity -X $_ -Min $min -Max $max
            }
            
            # Calculer l'erreur quadratique moyenne
            $mse = 0
            for ($i = 0; $i -lt $kdeResult.DensityEstimates.Count; $i++) {
                $mse += [Math]::Pow($kdeResult.DensityEstimates[$i] - $theoreticalDensities[$i], 2)
            }
            $mse /= $kdeResult.DensityEstimates.Count
            
            # L'erreur quadratique moyenne devrait être faible
            $mse | Should -BeLessThan 0.001
        }
    }
    
    Context "Tests avec la distribution exponentielle" {
        BeforeAll {
            # Paramètres de la distribution
            $rate = 0.1
            
            # Générer un échantillon
            $exponentialSample = Get-ExponentialSample -NumPoints 1000 -Rate $rate
            
            # Points d'évaluation
            $evalPoints = 0..100
        }
        
        It "L'estimation de densité par noyau correspond à la densité théorique" -Skip:(-not (Get-Command Get-KernelDensityEstimation -ErrorAction SilentlyContinue)) {
            # Calculer l'estimation de densité par noyau
            $kdeResult = Get-KernelDensityEstimation -Data $exponentialSample -KernelType "Gaussian" -BandwidthMethod "Silverman"
            
            # Calculer la densité théorique aux mêmes points
            $theoreticalDensities = $kdeResult.EvaluationPoints | ForEach-Object {
                Get-ExponentialDensity -X $_ -Rate $rate
            }
            
            # Calculer l'erreur quadratique moyenne
            $mse = 0
            for ($i = 0; $i -lt $kdeResult.DensityEstimates.Count; $i++) {
                $mse += [Math]::Pow($kdeResult.DensityEstimates[$i] - $theoreticalDensities[$i], 2)
            }
            $mse /= $kdeResult.DensityEstimates.Count
            
            # L'erreur quadratique moyenne devrait être faible
            $mse | Should -BeLessThan 0.001
        }
    }
    
    Context "Tests avec la distribution bimodale" {
        BeforeAll {
            # Paramètres de la distribution
            $mean1 = 30
            $stdDev1 = 5
            $mean2 = 70
            $stdDev2 = 5
            $weight1 = 0.6
            
            # Générer un échantillon
            $bimodalSample = Get-BimodalSample -NumPoints 1000 -Mean1 $mean1 -StdDev1 $stdDev1 -Mean2 $mean2 -StdDev2 $stdDev2 -Weight1 $weight1
            
            # Points d'évaluation
            $evalPoints = 0..100
        }
        
        It "L'estimation de densité par noyau correspond à la densité théorique" -Skip:(-not (Get-Command Get-KernelDensityEstimation -ErrorAction SilentlyContinue)) {
            # Calculer l'estimation de densité par noyau
            $kdeResult = Get-KernelDensityEstimation -Data $bimodalSample -KernelType "Gaussian" -BandwidthMethod "Silverman"
            
            # Calculer la densité théorique aux mêmes points
            $theoreticalDensities = $kdeResult.EvaluationPoints | ForEach-Object {
                Get-BimodalDensity -X $_ -Mean1 $mean1 -StdDev1 $stdDev1 -Mean2 $mean2 -StdDev2 $stdDev2 -Weight1 $weight1
            }
            
            # Calculer l'erreur quadratique moyenne
            $mse = 0
            for ($i = 0; $i -lt $kdeResult.DensityEstimates.Count; $i++) {
                $mse += [Math]::Pow($kdeResult.DensityEstimates[$i] - $theoreticalDensities[$i], 2)
            }
            $mse /= $kdeResult.DensityEstimates.Count
            
            # L'erreur quadratique moyenne devrait être faible
            $mse | Should -BeLessThan 0.001
        }
    }
    
    Context "Tests avec la distribution normale bivariée" {
        BeforeAll {
            # Paramètres de la distribution
            $mean = @(50, 50)
            $covariance = @(@(100, 0), @(0, 100))
            
            # Générer un échantillon
            $bivariateNormalSample = Get-BivariateNormalSample -NumPoints 1000 -Mean $mean -Covariance $covariance
        }
        
        It "L'estimation de densité par noyau 2D correspond à la densité théorique" -Skip:(-not (Get-Command Get-KernelDensity2D -ErrorAction SilentlyContinue)) {
            # Calculer l'estimation de densité par noyau
            $kdeResult = Get-KernelDensity2D -Data $bivariateNormalSample -KernelType "Gaussian" -BandwidthMethod "Silverman" -GridSize @(20, 20)
            
            # Calculer la densité théorique aux points de la grille
            $theoreticalDensities = New-Object 'double[,]' $kdeResult.EvaluationGrid.XGrid.Count, $kdeResult.EvaluationGrid.YGrid.Count
            
            for ($i = 0; $i -lt $kdeResult.EvaluationGrid.XGrid.Count; $i++) {
                for ($j = 0; $j -lt $kdeResult.EvaluationGrid.YGrid.Count; $j++) {
                    $x = $kdeResult.EvaluationGrid.XGrid[$i]
                    $y = $kdeResult.EvaluationGrid.YGrid[$j]
                    $theoreticalDensities[$i, $j] = Get-BivariateNormalDensity -X $x -Y $y -Mean $mean -Covariance $covariance
                }
            }
            
            # Calculer l'erreur quadratique moyenne
            $mse = 0
            $count = 0
            
            for ($i = 0; $i -lt $kdeResult.EvaluationGrid.XGrid.Count; $i++) {
                for ($j = 0; $j -lt $kdeResult.EvaluationGrid.YGrid.Count; $j++) {
                    $mse += [Math]::Pow($kdeResult.DensityEstimates[$i, $j] - $theoreticalDensities[$i, $j], 2)
                    $count++
                }
            }
            
            $mse /= $count
            
            # L'erreur quadratique moyenne devrait être faible
            $mse | Should -BeLessThan 0.0001
        }
    }
}

AfterAll {
    # Nettoyage
}
