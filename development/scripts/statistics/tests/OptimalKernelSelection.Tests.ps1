# Tests pour les fonctions de sélection automatique du noyau optimal
# Run with Pester: Invoke-Pester -Path ".\OptimalKernelSelection.Tests.ps1"

# Importer le module contenant les fonctions à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\OptimalKernelSelection.ps1"
. $modulePath

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

Describe "Tests pour Get-DataCharacteristics" {
    Context "Tests de base" {
        It "Devrait détecter correctement une distribution normale" {
            $normalData = Get-NormalSample -NumPoints 100 -Mean 0 -StdDev 1
            $characteristics = Get-DataCharacteristics -Data $normalData
            
            $characteristics.IsNormal | Should -BeTrue
            $characteristics.RecommendedKernel | Should -Be "Gaussian"
        }
        
        It "Devrait détecter correctement une distribution asymétrique" {
            $skewedData = Get-SkewedSample -NumPoints 100 -Shape 2.0
            $characteristics = Get-DataCharacteristics -Data $skewedData
            
            $characteristics.IsSkewed | Should -BeTrue
            $characteristics.RecommendedKernel | Should -Be "Biweight"
        }
        
        It "Devrait détecter correctement une distribution multimodale" {
            $multimodalData = Get-MultimodalSample -NumPoints 100 -Means @(-3, 3) -StdDevs @(1, 1) -Weights @(0.5, 0.5)
            $characteristics = Get-DataCharacteristics -Data $multimodalData
            
            $characteristics.IsMultimodal | Should -BeTrue
            $characteristics.RecommendedKernel | Should -Be "Epanechnikov"
        }
        
        It "Devrait détecter correctement une distribution à queue lourde" {
            $heavyTailedData = Get-HeavyTailedSample -NumPoints 100 -Df 3.0
            $characteristics = Get-DataCharacteristics -Data $heavyTailedData
            
            $characteristics.Kurtosis | Should -BeGreaterThan 0
            $characteristics.RecommendedKernel | Should -Be "Triweight"
        }
        
        It "Devrait lever une exception si les données contiennent moins de 3 points" {
            { Get-DataCharacteristics -Data @(1, 2) } | Should -Throw "Les données doivent contenir au moins 3 points pour détecter leurs caractéristiques."
        }
    }
}

Describe "Tests pour Get-OptimalKernel" {
    Context "Tests de base" {
        It "Devrait sélectionner le noyau optimal pour une distribution normale" {
            $normalData = Get-NormalSample -NumPoints 100 -Mean 0 -StdDev 1
            $optimalKernel = Get-OptimalKernel -Data $normalData -Objective "Balance" -DataCharacteristics "Normal"
            
            $optimalKernel | Should -Be "Gaussian"
        }
        
        It "Devrait sélectionner le noyau optimal pour une distribution asymétrique" {
            $skewedData = Get-SkewedSample -NumPoints 100 -Shape 2.0
            $optimalKernel = Get-OptimalKernel -Data $skewedData -Objective "Balance" -DataCharacteristics "Skewed"
            
            $optimalKernel | Should -Be "Biweight"
        }
        
        It "Devrait sélectionner le noyau optimal pour une distribution multimodale" {
            $multimodalData = Get-MultimodalSample -NumPoints 100 -Means @(-3, 3) -StdDevs @(1, 1) -Weights @(0.5, 0.5)
            $optimalKernel = Get-OptimalKernel -Data $multimodalData -Objective "Balance" -DataCharacteristics "Multimodal"
            
            $optimalKernel | Should -Be "Epanechnikov"
        }
        
        It "Devrait sélectionner le noyau optimal pour une distribution à queue lourde" {
            $heavyTailedData = Get-HeavyTailedSample -NumPoints 100 -Df 3.0
            $optimalKernel = Get-OptimalKernel -Data $heavyTailedData -Objective "Balance" -DataCharacteristics "HeavyTailed"
            
            $optimalKernel | Should -Be "Triweight"
        }
        
        It "Devrait sélectionner le noyau optimal pour des données éparses" {
            $sparseData = Get-NormalSample -NumPoints 10 -Mean 0 -StdDev 1
            $optimalKernel = Get-OptimalKernel -Data $sparseData -Objective "Balance" -DataCharacteristics "Sparse"
            
            $optimalKernel | Should -Be "Cosine"
        }
        
        It "Devrait lever une exception si les données contiennent moins de 2 points" {
            { Get-OptimalKernel -Data @(1) } | Should -Throw "Les données doivent contenir au moins 2 points pour sélectionner le noyau optimal."
        }
    }
    
    Context "Tests avec différents objectifs" {
        $normalData = Get-NormalSample -NumPoints 100 -Mean 0 -StdDev 1
        
        It "Devrait sélectionner le noyau optimal avec l'objectif Precision" {
            $optimalKernel = Get-OptimalKernel -Data $normalData -Objective "Precision" -DataCharacteristics "Normal"
            
            $optimalKernel | Should -Be "Epanechnikov"
        }
        
        It "Devrait sélectionner le noyau optimal avec l'objectif Smoothness" {
            $optimalKernel = Get-OptimalKernel -Data $normalData -Objective "Smoothness" -DataCharacteristics "Normal"
            
            $optimalKernel | Should -Be "Gaussian"
        }
        
        It "Devrait sélectionner le noyau optimal avec l'objectif Speed" {
            $optimalKernel = Get-OptimalKernel -Data $normalData -Objective "Speed" -DataCharacteristics "Normal"
            
            $optimalKernel | Should -Be "Triangular"
        }
        
        It "Devrait sélectionner le noyau optimal avec l'objectif Balance" {
            $optimalKernel = Get-OptimalKernel -Data $normalData -Objective "Balance" -DataCharacteristics "Normal"
            
            $optimalKernel | Should -Be "Gaussian"
        }
    }
    
    Context "Tests avec détection automatique des caractéristiques" {
        It "Devrait détecter automatiquement les caractéristiques et sélectionner le noyau optimal" {
            $normalData = Get-NormalSample -NumPoints 100 -Mean 0 -StdDev 1
            $optimalKernel = Get-OptimalKernel -Data $normalData
            
            $optimalKernel | Should -Not -BeNullOrEmpty
        }
    }
}
