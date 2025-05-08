# Démonstration de la sélection automatique du noyau optimal pour l'estimation de densité par noyau

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$scriptPath\OptimalKernelSelection.ps1"
. "$scriptPath\GaussianKernel.ps1"
. "$scriptPath\EpanechnikovKernel.ps1"
. "$scriptPath\TriangularKernel.ps1"
. "$scriptPath\UniformKernel.ps1"
. "$scriptPath\BiweightKernel.ps1"
. "$scriptPath\TriweightKernel.ps1"
. "$scriptPath\CosineKernel.ps1"

# Fonction pour générer des échantillons de distribution normale
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

# Fonction pour générer des échantillons de distribution asymétrique
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

# Fonction pour générer des échantillons de distribution multimodale
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

# Fonction pour générer des échantillons de distribution à queue lourde
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

# Fonction pour calculer la densité en utilisant le noyau spécifié
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
        [ValidateSet("Gaussian", "Epanechnikov", "Triangular", "Uniform", "Biweight", "Triweight", "Cosine", "Optimal")]
        [string]$KernelType = "Gaussian"
    )
    
    # Si le noyau est "Optimal", sélectionner automatiquement le noyau optimal
    if ($KernelType -eq "Optimal") {
        $KernelType = Get-OptimalKernel -Data $Data
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

# Générer des échantillons de différentes distributions
$normalData = Get-NormalSample -NumPoints 1000 -Mean 0 -StdDev 1
$skewedData = Get-SkewedSample -NumPoints 1000 -Shape 2.0
$multimodalData = Get-MultimodalSample -NumPoints 1000 -Means @(-3, 3) -StdDevs @(1, 1) -Weights @(0.5, 0.5)
$heavyTailedData = Get-HeavyTailedSample -NumPoints 1000 -Df 3.0

# Définir les distributions à tester
$distributions = @(
    @{ Name = "Normal"; Data = $normalData },
    @{ Name = "Skewed"; Data = $skewedData },
    @{ Name = "Multimodal"; Data = $multimodalData },
    @{ Name = "HeavyTailed"; Data = $heavyTailedData }
)

# Définir les objectifs à tester
$objectives = @("Precision", "Smoothness", "Speed", "Balance")

# Tester la sélection automatique du noyau optimal pour chaque distribution et objectif
foreach ($distribution in $distributions) {
    Write-Host "`n=== Distribution: $($distribution.Name) ===" -ForegroundColor Magenta
    
    # Détecter les caractéristiques des données
    $characteristics = Get-DataCharacteristics -Data $distribution.Data
    
    Write-Host "`nCaractéristiques des données:" -ForegroundColor White
    Write-Host "- Taille de l'échantillon: $($characteristics.SampleSize)" -ForegroundColor Green
    Write-Host "- Moyenne: $([Math]::Round($characteristics.Mean, 2))" -ForegroundColor Green
    Write-Host "- Médiane: $([Math]::Round($characteristics.Median, 2))" -ForegroundColor Green
    Write-Host "- Écart-type: $([Math]::Round($characteristics.StdDev, 2))" -ForegroundColor Green
    Write-Host "- Asymétrie: $([Math]::Round($characteristics.Skewness, 2))" -ForegroundColor Green
    Write-Host "- Aplatissement: $([Math]::Round($characteristics.Kurtosis, 2))" -ForegroundColor Green
    Write-Host "- Distribution normale: $($characteristics.IsNormal)" -ForegroundColor Green
    Write-Host "- Distribution asymétrique: $($characteristics.IsSkewed)" -ForegroundColor Green
    Write-Host "- Distribution multimodale: $($characteristics.IsMultimodal)" -ForegroundColor Green
    Write-Host "- Présence de valeurs aberrantes: $($characteristics.HasOutliers)" -ForegroundColor Green
    Write-Host "- Complexité: $($characteristics.Complexity)" -ForegroundColor Green
    Write-Host "- Noyau recommandé: $($characteristics.RecommendedKernel)" -ForegroundColor Green
    
    # Tester la sélection automatique du noyau optimal pour chaque objectif
    Write-Host "`nSélection automatique du noyau optimal:" -ForegroundColor White
    foreach ($objective in $objectives) {
        $optimalKernel = Get-OptimalKernel -Data $distribution.Data -Objective $objective
        Write-Host "- Objectif $objective : $optimalKernel" -ForegroundColor Yellow
    }
}

# Démonstration de l'estimation de densité avec le noyau optimal
Write-Host "`n=== Démonstration de l'estimation de densité avec le noyau optimal ===" -ForegroundColor Magenta

# Générer des points d'évaluation
$min = ($normalData | Measure-Object -Minimum).Minimum
$max = ($normalData | Measure-Object -Maximum).Maximum
$evaluationPoints = $min..$max | ForEach-Object { $min + ($max - $min) * $_ / 100 }

# Calculer la densité avec différents noyaux
$kernelTypes = @("Gaussian", "Epanechnikov", "Triangular", "Uniform", "Biweight", "Triweight", "Cosine", "Optimal")
$densities = @{}

foreach ($kernelType in $kernelTypes) {
    $densities[$kernelType] = @()
    foreach ($x in $evaluationPoints) {
        $density = Get-KernelDensity -X $x -Data $normalData -KernelType $kernelType
        $densities[$kernelType] += $density
    }
}

# Afficher les résultats
Write-Host "`nDensité au point x = 0 avec différents noyaux:" -ForegroundColor White
foreach ($kernelType in $kernelTypes) {
    $density = Get-KernelDensity -X 0 -Data $normalData -KernelType $kernelType
    Write-Host "- Noyau $kernelType : $([Math]::Round($density, 4))" -ForegroundColor Yellow
}

Write-Host "`nLe noyau optimal pour la distribution normale est: $(Get-OptimalKernel -Data $normalData)" -ForegroundColor Green
