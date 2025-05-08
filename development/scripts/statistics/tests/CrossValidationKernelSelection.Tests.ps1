# Tests pour les fonctions de sélection du noyau optimal par validation croisée
# Run with Pester: Invoke-Pester -Path ".\CrossValidationKernelSelection.Tests.ps1"

# Importer les modules contenant les fonctions à tester
$scriptPath = Split-Path -Parent $PSScriptRoot
. "$scriptPath\CrossValidationKernelSelection.ps1"
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

Describe "Tests pour Get-LeaveOneOutCVError" {
    Context "Tests de base" {
        It "Devrait calculer l'erreur de validation croisée leave-one-out pour le noyau gaussien" {
            $data = Get-NormalSample -NumPoints 20 -Mean 0 -StdDev 1
            $error = Get-LeaveOneOutCVError -Data $data -KernelType "Gaussian"
            
            $error | Should -BeOfType [double]
            $error | Should -BeGreaterThan 0
        }
        
        It "Devrait calculer l'erreur de validation croisée leave-one-out pour le noyau d'Epanechnikov" {
            $data = Get-NormalSample -NumPoints 20 -Mean 0 -StdDev 1
            $error = Get-LeaveOneOutCVError -Data $data -KernelType "Epanechnikov"
            
            $error | Should -BeOfType [double]
            $error | Should -BeGreaterThan 0
        }
        
        It "Devrait calculer l'erreur de validation croisée leave-one-out pour le noyau triangulaire" {
            $data = Get-NormalSample -NumPoints 20 -Mean 0 -StdDev 1
            $error = Get-LeaveOneOutCVError -Data $data -KernelType "Triangular"
            
            $error | Should -BeOfType [double]
            $error | Should -BeGreaterThan 0
        }
        
        It "Devrait calculer l'erreur de validation croisée leave-one-out pour le noyau uniforme" {
            $data = Get-NormalSample -NumPoints 20 -Mean 0 -StdDev 1
            $error = Get-LeaveOneOutCVError -Data $data -KernelType "Uniform"
            
            $error | Should -BeOfType [double]
            $error | Should -BeGreaterThan 0
        }
        
        It "Devrait calculer l'erreur de validation croisée leave-one-out pour le noyau biweight" {
            $data = Get-NormalSample -NumPoints 20 -Mean 0 -StdDev 1
            $error = Get-LeaveOneOutCVError -Data $data -KernelType "Biweight"
            
            $error | Should -BeOfType [double]
            $error | Should -BeGreaterThan 0
        }
        
        It "Devrait calculer l'erreur de validation croisée leave-one-out pour le noyau triweight" {
            $data = Get-NormalSample -NumPoints 20 -Mean 0 -StdDev 1
            $error = Get-LeaveOneOutCVError -Data $data -KernelType "Triweight"
            
            $error | Should -BeOfType [double]
            $error | Should -BeGreaterThan 0
        }
        
        It "Devrait calculer l'erreur de validation croisée leave-one-out pour le noyau cosinus" {
            $data = Get-NormalSample -NumPoints 20 -Mean 0 -StdDev 1
            $error = Get-LeaveOneOutCVError -Data $data -KernelType "Cosine"
            
            $error | Should -BeOfType [double]
            $error | Should -BeGreaterThan 0
        }
        
        It "Devrait lever une exception si les données contiennent moins de 3 points" {
            $data = @(1, 2)
            { Get-LeaveOneOutCVError -Data $data -KernelType "Gaussian" } | Should -Throw "Les données doivent contenir au moins 3 points pour la validation croisée leave-one-out."
        }
    }
}

Describe "Tests pour Get-KFoldCVError" {
    Context "Tests de base" {
        It "Devrait calculer l'erreur de validation croisée k-fold pour le noyau gaussien" {
            $data = Get-NormalSample -NumPoints 20 -Mean 0 -StdDev 1
            $error = Get-KFoldCVError -Data $data -KernelType "Gaussian" -K 5
            
            $error | Should -BeOfType [double]
            $error | Should -BeGreaterThan 0
        }
        
        It "Devrait calculer l'erreur de validation croisée k-fold pour le noyau d'Epanechnikov" {
            $data = Get-NormalSample -NumPoints 20 -Mean 0 -StdDev 1
            $error = Get-KFoldCVError -Data $data -KernelType "Epanechnikov" -K 5
            
            $error | Should -BeOfType [double]
            $error | Should -BeGreaterThan 0
        }
        
        It "Devrait calculer l'erreur de validation croisée k-fold pour le noyau triangulaire" {
            $data = Get-NormalSample -NumPoints 20 -Mean 0 -StdDev 1
            $error = Get-KFoldCVError -Data $data -KernelType "Triangular" -K 5
            
            $error | Should -BeOfType [double]
            $error | Should -BeGreaterThan 0
        }
        
        It "Devrait calculer l'erreur de validation croisée k-fold pour le noyau uniforme" {
            $data = Get-NormalSample -NumPoints 20 -Mean 0 -StdDev 1
            $error = Get-KFoldCVError -Data $data -KernelType "Uniform" -K 5
            
            $error | Should -BeOfType [double]
            $error | Should -BeGreaterThan 0
        }
        
        It "Devrait calculer l'erreur de validation croisée k-fold pour le noyau biweight" {
            $data = Get-NormalSample -NumPoints 20 -Mean 0 -StdDev 1
            $error = Get-KFoldCVError -Data $data -KernelType "Biweight" -K 5
            
            $error | Should -BeOfType [double]
            $error | Should -BeGreaterThan 0
        }
        
        It "Devrait calculer l'erreur de validation croisée k-fold pour le noyau triweight" {
            $data = Get-NormalSample -NumPoints 20 -Mean 0 -StdDev 1
            $error = Get-KFoldCVError -Data $data -KernelType "Triweight" -K 5
            
            $error | Should -BeOfType [double]
            $error | Should -BeGreaterThan 0
        }
        
        It "Devrait calculer l'erreur de validation croisée k-fold pour le noyau cosinus" {
            $data = Get-NormalSample -NumPoints 20 -Mean 0 -StdDev 1
            $error = Get-KFoldCVError -Data $data -KernelType "Cosine" -K 5
            
            $error | Should -BeOfType [double]
            $error | Should -BeGreaterThan 0
        }
        
        It "Devrait lever une exception si les données contiennent moins de K points" {
            $data = @(1, 2, 3, 4)
            { Get-KFoldCVError -Data $data -KernelType "Gaussian" -K 5 } | Should -Throw "Les données doivent contenir au moins 5 points pour la validation croisée par 5-fold."
        }
    }
}

Describe "Tests pour Get-CrossValidationOptimalKernel" {
    Context "Tests de base" {
        It "Devrait sélectionner le noyau optimal par validation croisée k-fold" {
            $data = Get-NormalSample -NumPoints 20 -Mean 0 -StdDev 1
            $optimalKernel = Get-CrossValidationOptimalKernel -Data $data -ValidationMethod "KFold" -K 5
            
            $optimalKernel | Should -BeOfType [string]
            $optimalKernel | Should -BeIn @("Gaussian", "Epanechnikov", "Triangular", "Uniform", "Biweight", "Triweight", "Cosine")
        }
        
        It "Devrait sélectionner le noyau optimal par validation croisée leave-one-out" {
            $data = Get-NormalSample -NumPoints 20 -Mean 0 -StdDev 1
            $optimalKernel = Get-CrossValidationOptimalKernel -Data $data -ValidationMethod "LeaveOneOut"
            
            $optimalKernel | Should -BeOfType [string]
            $optimalKernel | Should -BeIn @("Gaussian", "Epanechnikov", "Triangular", "Uniform", "Biweight", "Triweight", "Cosine")
        }
        
        It "Devrait sélectionner le noyau optimal parmi un sous-ensemble de noyaux" {
            $data = Get-NormalSample -NumPoints 20 -Mean 0 -StdDev 1
            $optimalKernel = Get-CrossValidationOptimalKernel -Data $data -KernelTypes @("Gaussian", "Epanechnikov", "Triangular")
            
            $optimalKernel | Should -BeOfType [string]
            $optimalKernel | Should -BeIn @("Gaussian", "Epanechnikov", "Triangular")
        }
        
        It "Devrait lever une exception si les données contiennent moins de 3 points" {
            $data = @(1, 2)
            { Get-CrossValidationOptimalKernel -Data $data } | Should -Throw "Les données doivent contenir au moins 3 points pour la validation croisée."
        }
    }
    
    Context "Tests avec différentes distributions" {
        It "Devrait sélectionner le noyau optimal pour une distribution normale" {
            $data = Get-NormalSample -NumPoints 50 -Mean 0 -StdDev 1
            $optimalKernel = Get-CrossValidationOptimalKernel -Data $data
            
            $optimalKernel | Should -BeOfType [string]
            $optimalKernel | Should -BeIn @("Gaussian", "Epanechnikov", "Triangular", "Uniform", "Biweight", "Triweight", "Cosine")
        }
        
        It "Devrait sélectionner le noyau optimal pour une distribution asymétrique" {
            $data = Get-SkewedSample -NumPoints 50 -Shape 2.0
            $optimalKernel = Get-CrossValidationOptimalKernel -Data $data
            
            $optimalKernel | Should -BeOfType [string]
            $optimalKernel | Should -BeIn @("Gaussian", "Epanechnikov", "Triangular", "Uniform", "Biweight", "Triweight", "Cosine")
        }
        
        It "Devrait sélectionner le noyau optimal pour une distribution multimodale" {
            $data = Get-MultimodalSample -NumPoints 50 -Means @(-3, 3) -StdDevs @(1, 1) -Weights @(0.5, 0.5)
            $optimalKernel = Get-CrossValidationOptimalKernel -Data $data
            
            $optimalKernel | Should -BeOfType [string]
            $optimalKernel | Should -BeIn @("Gaussian", "Epanechnikov", "Triangular", "Uniform", "Biweight", "Triweight", "Cosine")
        }
    }
}
