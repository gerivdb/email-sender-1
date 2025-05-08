# Tests complets pour la sélection automatique du noyau optimal
# Run with Pester: Invoke-Pester -Path ".\KernelSelectionComprehensive.Tests.ps1"

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $PSScriptRoot
. "$scriptPath\OptimalKernelSelection.ps1"
. "$scriptPath\CrossValidationKernelSelection.ps1"
. "$scriptPath\KernelSelectionConfig.ps1"
. "$scriptPath\KernelSelectionCache.ps1"
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

# Fonction utilitaire pour calculer la densité en utilisant le noyau spécifié
function Get-KernelDensity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double]$X,
        
        [Parameter(Mandatory = $true)]
        [double[]]$Data,
        
        [Parameter(Mandatory = $false)]
        [double]$Bandwidth = 0,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Gaussian", "Epanechnikov", "Triangular", "Uniform", "Biweight", "Triweight", "Cosine", "Optimal", "CrossValidation")]
        [string]$KernelType = "Gaussian"
    )
    
    # Si le noyau est "Optimal", sélectionner automatiquement le noyau optimal
    if ($KernelType -eq "Optimal") {
        $KernelType = Get-OptimalKernel -Data $Data
    }
    
    # Si le noyau est "CrossValidation", sélectionner automatiquement le noyau optimal par validation croisée
    if ($KernelType -eq "CrossValidation") {
        $KernelType = Get-CrossValidationOptimalKernel -Data $Data
    }
    
    # Calculer la densité en utilisant le noyau spécifié
    switch ($KernelType) {
        "Gaussian" {
            return Get-GaussianKernelDensity -X $X -Data $Data -Bandwidth $Bandwidth
        }
        "Epanechnikov" {
            return Get-EpanechnikovKernelDensity -X $X -Data $Data -Bandwidth $Bandwidth
        }
        "Triangular" {
            return Get-TriangularKernelDensity -X $X -Data $Data -Bandwidth $Bandwidth
        }
        "Uniform" {
            return Get-UniformKernelDensity -X $X -Data $Data -Bandwidth $Bandwidth
        }
        "Biweight" {
            return Get-BiweightKernelDensity -X $X -Data $Data -Bandwidth $Bandwidth
        }
        "Triweight" {
            return Get-TriweightKernelDensity -X $X -Data $Data -Bandwidth $Bandwidth
        }
        "Cosine" {
            return Get-CosineKernelDensity -X $X -Data $Data -Bandwidth $Bandwidth
        }
        default {
            return Get-GaussianKernelDensity -X $X -Data $Data -Bandwidth $Bandwidth
        }
    }
}

Describe "Tests complets pour la sélection automatique du noyau optimal" {
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
        }
        
        It "Le noyau optimal pour une distribution normale devrait être précis" {
            # Sélectionner le noyau optimal
            $optimalKernel = Get-OptimalKernel -Data $normalSample
            
            # Calculer la densité avec le noyau optimal
            $optimalDensities = @()
            foreach ($x in $normalEvalPoints) {
                $density = Get-KernelDensity -X $x -Data $normalSample -KernelType $optimalKernel
                $optimalDensities += $density
            }
            
            # Calculer la densité théorique
            $theoreticalDensities = @()
            foreach ($x in $normalEvalPoints) {
                $density = Get-NormalDensity -X $x -Mean 0 -StdDev 1
                $theoreticalDensities += $density
            }
            
            # Calculer l'erreur quadratique moyenne
            $mse = Get-MeanSquaredError -Density1 $optimalDensities -Density2 $theoreticalDensities
            
            # L'erreur devrait être faible
            $mse | Should -BeLessThan 0.01
        }
        
        It "Le noyau optimal par validation croisée pour une distribution normale devrait être précis" {
            # Sélectionner le noyau optimal par validation croisée
            $optimalKernel = Get-CrossValidationOptimalKernel -Data $normalSample
            
            # Calculer la densité avec le noyau optimal
            $optimalDensities = @()
            foreach ($x in $normalEvalPoints) {
                $density = Get-KernelDensity -X $x -Data $normalSample -KernelType $optimalKernel
                $optimalDensities += $density
            }
            
            # Calculer la densité théorique
            $theoreticalDensities = @()
            foreach ($x in $normalEvalPoints) {
                $density = Get-NormalDensity -X $x -Mean 0 -StdDev 1
                $theoreticalDensities += $density
            }
            
            # Calculer l'erreur quadratique moyenne
            $mse = Get-MeanSquaredError -Density1 $optimalDensities -Density2 $theoreticalDensities
            
            # L'erreur devrait être faible
            $mse | Should -BeLessThan 0.01
        }
    }
    
    Context "Tests de performance pour différentes tailles de données" {
        It "La sélection du noyau optimal devrait être rapide pour de petits ensembles de données" {
            $data = Get-NormalSample -NumPoints 20 -Mean 0 -StdDev 1
            
            $startTime = Get-Date
            $optimalKernel = Get-OptimalKernel -Data $data
            $endTime = Get-Date
            $executionTime = ($endTime - $startTime).TotalMilliseconds
            
            # L'exécution devrait être rapide (moins de 100 ms)
            $executionTime | Should -BeLessThan 100
        }
        
        It "La sélection du noyau optimal par validation croisée devrait être plus lente que la sélection basée sur les caractéristiques" {
            $data = Get-NormalSample -NumPoints 20 -Mean 0 -StdDev 1
            
            $startTime1 = Get-Date
            $optimalKernel1 = Get-OptimalKernel -Data $data
            $endTime1 = Get-Date
            $executionTime1 = ($endTime1 - $startTime1).TotalMilliseconds
            
            $startTime2 = Get-Date
            $optimalKernel2 = Get-CrossValidationOptimalKernel -Data $data
            $endTime2 = Get-Date
            $executionTime2 = ($endTime2 - $startTime2).TotalMilliseconds
            
            # La validation croisée devrait être plus lente
            $executionTime2 | Should -BeGreaterThan $executionTime1
        }
    }
    
    Context "Tests de mise en cache" {
        BeforeAll {
            # Sauvegarder la configuration actuelle
            $script:originalConfig = Get-KernelSelectionConfig
            
            # Activer la mise en cache
            $config = Get-KernelSelectionConfig
            $config.Cache.Enabled = $true
            $config.Cache.MaxCacheSize = 100
            $config.Cache.ExpirationTime = 3600
            Set-KernelSelectionConfig -Config $config
            
            # Réinitialiser le cache
            $script:KernelSelectionCache.Characteristics.Clear()
            $script:KernelSelectionCache.CrossValidation.Clear()
            $script:KernelSelectionCache.Stats.Hits = 0
            $script:KernelSelectionCache.Stats.Misses = 0
            $script:KernelSelectionCache.Stats.Evictions = 0
            $script:KernelSelectionCache.Stats.LastCleanup = [DateTime]::Now
        }
        
        AfterAll {
            # Restaurer la configuration originale
            Set-KernelSelectionConfig -Config $script:originalConfig
        }
        
        It "La mise en cache devrait accélérer les appels répétés à Get-OptimalKernel" {
            $data = Get-NormalSample -NumPoints 50 -Mean 0 -StdDev 1
            
            # Premier appel (miss)
            $startTime1 = Get-Date
            $optimalKernel1 = Get-OptimalKernel -Data $data
            $endTime1 = Get-Date
            $executionTime1 = ($endTime1 - $startTime1).TotalMilliseconds
            
            # Deuxième appel (hit)
            $startTime2 = Get-Date
            $optimalKernel2 = Get-OptimalKernel -Data $data
            $endTime2 = Get-Date
            $executionTime2 = ($endTime2 - $startTime2).TotalMilliseconds
            
            # Le deuxième appel devrait être plus rapide
            $executionTime2 | Should -BeLessThan $executionTime1
            
            # Les résultats devraient être identiques
            $optimalKernel2 | Should -Be $optimalKernel1
            
            # Vérifier les statistiques du cache
            $stats = Get-KernelSelectionCacheStats
            $stats.Hits | Should -Be 1
            $stats.Misses | Should -Be 1
        }
    }
}
