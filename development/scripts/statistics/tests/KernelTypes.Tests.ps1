# Tests pour les différents types de noyaux dans l'estimation de densité par noyau
# Run with Pester: Invoke-Pester -Path ".\KernelTypes.Tests.ps1"

BeforeAll {
    # Charger les modules nécessaires
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\KernelDensityEstimation.psm1"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force
    }
    
    # Fonctions de noyau pour les tests
    function Get-GaussianKernelValue {
        param (
            [double]$x
        )
        return (1 / [Math]::Sqrt(2 * [Math]::PI)) * [Math]::Exp(-0.5 * $x * $x)
    }
    
    function Get-EpanechnikovKernelValue {
        param (
            [double]$x
        )
        if ([Math]::Abs($x) <= 1) {
            return 0.75 * (1 - $x * $x)
        }
        return 0
    }
    
    function Get-TriangularKernelValue {
        param (
            [double]$x
        )
        if ([Math]::Abs($x) <= 1) {
            return 1 - [Math]::Abs($x)
        }
        return 0
    }
    
    function Get-UniformKernelValue {
        param (
            [double]$x
        )
        if ([Math]::Abs($x) <= 1) {
            return 0.5
        }
        return 0
    }
    
    function Get-BiweightKernelValue {
        param (
            [double]$x
        )
        if ([Math]::Abs($x) <= 1) {
            return (15/16) * [Math]::Pow(1 - $x * $x, 2)
        }
        return 0
    }
    
    function Get-TriweightKernelValue {
        param (
            [double]$x
        )
        if ([Math]::Abs($x) <= 1) {
            return (35/32) * [Math]::Pow(1 - $x * $x, 3)
        }
        return 0
    }
    
    function Get-CosineKernelValue {
        param (
            [double]$x
        )
        if ([Math]::Abs($x) <= 1) {
            return ([Math]::PI/4) * [Math]::Cos([Math]::PI * $x / 2)
        }
        return 0
    }
}

Describe "Tests des fonctions de noyau" {
    Context "Tests des propriétés mathématiques des noyaux" {
        It "Le noyau gaussien est symétrique" {
            $values = -1..1 | ForEach-Object { $_ / 10 }
            
            foreach ($x in $values) {
                $valueAtX = Get-GaussianKernelValue -x $x
                $valueAtMinusX = Get-GaussianKernelValue -x (-$x)
                
                $valueAtX | Should -BeApproximately $valueAtMinusX -Epsilon 0.0001
            }
        }
        
        It "Le noyau d'Epanechnikov est symétrique" {
            $values = -1..1 | ForEach-Object { $_ / 10 }
            
            foreach ($x in $values) {
                $valueAtX = Get-EpanechnikovKernelValue -x $x
                $valueAtMinusX = Get-EpanechnikovKernelValue -x (-$x)
                
                $valueAtX | Should -BeApproximately $valueAtMinusX -Epsilon 0.0001
            }
        }
        
        It "Le noyau triangulaire est symétrique" {
            $values = -1..1 | ForEach-Object { $_ / 10 }
            
            foreach ($x in $values) {
                $valueAtX = Get-TriangularKernelValue -x $x
                $valueAtMinusX = Get-TriangularKernelValue -x (-$x)
                
                $valueAtX | Should -BeApproximately $valueAtMinusX -Epsilon 0.0001
            }
        }
        
        It "Le noyau uniforme est symétrique" {
            $values = -1..1 | ForEach-Object { $_ / 10 }
            
            foreach ($x in $values) {
                $valueAtX = Get-UniformKernelValue -x $x
                $valueAtMinusX = Get-UniformKernelValue -x (-$x)
                
                $valueAtX | Should -BeApproximately $valueAtMinusX -Epsilon 0.0001
            }
        }
        
        It "Le noyau biweight est symétrique" {
            $values = -1..1 | ForEach-Object { $_ / 10 }
            
            foreach ($x in $values) {
                $valueAtX = Get-BiweightKernelValue -x $x
                $valueAtMinusX = Get-BiweightKernelValue -x (-$x)
                
                $valueAtX | Should -BeApproximately $valueAtMinusX -Epsilon 0.0001
            }
        }
        
        It "Le noyau triweight est symétrique" {
            $values = -1..1 | ForEach-Object { $_ / 10 }
            
            foreach ($x in $values) {
                $valueAtX = Get-TriweightKernelValue -x $x
                $valueAtMinusX = Get-TriweightKernelValue -x (-$x)
                
                $valueAtX | Should -BeApproximately $valueAtMinusX -Epsilon 0.0001
            }
        }
        
        It "Le noyau cosinus est symétrique" {
            $values = -1..1 | ForEach-Object { $_ / 10 }
            
            foreach ($x in $values) {
                $valueAtX = Get-CosineKernelValue -x $x
                $valueAtMinusX = Get-CosineKernelValue -x (-$x)
                
                $valueAtX | Should -BeApproximately $valueAtMinusX -Epsilon 0.0001
            }
        }
        
        It "Les noyaux s'intègrent à 1 (approximativement)" {
            # Calculer l'intégrale numérique des noyaux sur [-3, 3]
            $stepSize = 0.01
            $range = -3..3 | ForEach-Object { $_ * $stepSize }
            
            # Noyau gaussien
            $gaussianIntegral = 0
            foreach ($x in $range) {
                $gaussianIntegral += Get-GaussianKernelValue -x $x * $stepSize
            }
            $gaussianIntegral | Should -BeApproximately 1 -Epsilon 0.01
            
            # Noyau d'Epanechnikov
            $epanechnikovIntegral = 0
            foreach ($x in $range) {
                $epanechnikovIntegral += Get-EpanechnikovKernelValue -x $x * $stepSize
            }
            $epanechnikovIntegral | Should -BeApproximately 1 -Epsilon 0.01
            
            # Noyau triangulaire
            $triangularIntegral = 0
            foreach ($x in $range) {
                $triangularIntegral += Get-TriangularKernelValue -x $x * $stepSize
            }
            $triangularIntegral | Should -BeApproximately 1 -Epsilon 0.01
            
            # Noyau uniforme
            $uniformIntegral = 0
            foreach ($x in $range) {
                $uniformIntegral += Get-UniformKernelValue -x $x * $stepSize
            }
            $uniformIntegral | Should -BeApproximately 1 -Epsilon 0.01
            
            # Noyau biweight
            $biweightIntegral = 0
            foreach ($x in $range) {
                $biweightIntegral += Get-BiweightKernelValue -x $x * $stepSize
            }
            $biweightIntegral | Should -BeApproximately 1 -Epsilon 0.01
            
            # Noyau triweight
            $triweightIntegral = 0
            foreach ($x in $range) {
                $triweightIntegral += Get-TriweightKernelValue -x $x * $stepSize
            }
            $triweightIntegral | Should -BeApproximately 1 -Epsilon 0.01
            
            # Noyau cosinus
            $cosineIntegral = 0
            foreach ($x in $range) {
                $cosineIntegral += Get-CosineKernelValue -x $x * $stepSize
            }
            $cosineIntegral | Should -BeApproximately 1 -Epsilon 0.01
        }
    }
    
    Context "Tests d'intégration avec l'estimation de densité par noyau" {
        BeforeAll {
            # Générer des données de test
            $testData = 1..100 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
        }
        
        It "L'estimation de densité fonctionne avec le noyau gaussien" -Skip:(-not (Get-Command Get-KernelDensityEstimation -ErrorAction SilentlyContinue)) {
            $result = Get-KernelDensityEstimation -Data $testData -KernelType "Gaussian"
            
            $result | Should -Not -BeNullOrEmpty
            $result.KernelType | Should -Be "Gaussian"
            $result.Bandwidth | Should -BeGreaterThan 0
            $result.DensityEstimates | Should -Not -BeNullOrEmpty
            $result.DensityEstimates | ForEach-Object { $_ | Should -BeGreaterOrEqual 0 }
        }
        
        It "L'estimation de densité fonctionne avec le noyau d'Epanechnikov" -Skip:(-not (Get-Command Get-KernelDensityEstimation -ErrorAction SilentlyContinue)) {
            $result = Get-KernelDensityEstimation -Data $testData -KernelType "Epanechnikov"
            
            $result | Should -Not -BeNullOrEmpty
            $result.KernelType | Should -Be "Epanechnikov"
            $result.Bandwidth | Should -BeGreaterThan 0
            $result.DensityEstimates | Should -Not -BeNullOrEmpty
            $result.DensityEstimates | ForEach-Object { $_ | Should -BeGreaterOrEqual 0 }
        }
        
        It "L'estimation de densité fonctionne avec le noyau triangulaire" -Skip:(-not (Get-Command Get-KernelDensityEstimation -ErrorAction SilentlyContinue)) {
            $result = Get-KernelDensityEstimation -Data $testData -KernelType "Triangular"
            
            $result | Should -Not -BeNullOrEmpty
            $result.KernelType | Should -Be "Triangular"
            $result.Bandwidth | Should -BeGreaterThan 0
            $result.DensityEstimates | Should -Not -BeNullOrEmpty
            $result.DensityEstimates | ForEach-Object { $_ | Should -BeGreaterOrEqual 0 }
        }
        
        It "L'estimation de densité fonctionne avec le noyau uniforme" -Skip:(-not (Get-Command Get-KernelDensityEstimation -ErrorAction SilentlyContinue)) {
            $result = Get-KernelDensityEstimation -Data $testData -KernelType "Uniform"
            
            $result | Should -Not -BeNullOrEmpty
            $result.KernelType | Should -Be "Uniform"
            $result.Bandwidth | Should -BeGreaterThan 0
            $result.DensityEstimates | Should -Not -BeNullOrEmpty
            $result.DensityEstimates | ForEach-Object { $_ | Should -BeGreaterOrEqual 0 }
        }
        
        It "L'estimation de densité fonctionne avec le noyau biweight" -Skip:(-not (Get-Command Get-KernelDensityEstimation -ErrorAction SilentlyContinue)) {
            $result = Get-KernelDensityEstimation -Data $testData -KernelType "Biweight"
            
            $result | Should -Not -BeNullOrEmpty
            $result.KernelType | Should -Be "Biweight"
            $result.Bandwidth | Should -BeGreaterThan 0
            $result.DensityEstimates | Should -Not -BeNullOrEmpty
            $result.DensityEstimates | ForEach-Object { $_ | Should -BeGreaterOrEqual 0 }
        }
        
        It "L'estimation de densité fonctionne avec le noyau triweight" -Skip:(-not (Get-Command Get-KernelDensityEstimation -ErrorAction SilentlyContinue)) {
            $result = Get-KernelDensityEstimation -Data $testData -KernelType "Triweight"
            
            $result | Should -Not -BeNullOrEmpty
            $result.KernelType | Should -Be "Triweight"
            $result.Bandwidth | Should -BeGreaterThan 0
            $result.DensityEstimates | Should -Not -BeNullOrEmpty
            $result.DensityEstimates | ForEach-Object { $_ | Should -BeGreaterOrEqual 0 }
        }
        
        It "L'estimation de densité fonctionne avec le noyau cosinus" -Skip:(-not (Get-Command Get-KernelDensityEstimation -ErrorAction SilentlyContinue)) {
            $result = Get-KernelDensityEstimation -Data $testData -KernelType "Cosine"
            
            $result | Should -Not -BeNullOrEmpty
            $result.KernelType | Should -Be "Cosine"
            $result.Bandwidth | Should -BeGreaterThan 0
            $result.DensityEstimates | Should -Not -BeNullOrEmpty
            $result.DensityEstimates | ForEach-Object { $_ | Should -BeGreaterOrEqual 0 }
        }
    }
}

AfterAll {
    # Nettoyage
}
