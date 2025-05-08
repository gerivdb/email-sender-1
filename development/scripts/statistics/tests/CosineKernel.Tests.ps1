# Tests pour les fonctions du noyau cosinus
# Run with Pester: Invoke-Pester -Path ".\CosineKernel.Tests.ps1"

# Importer le module contenant les fonctions à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\CosineKernel.ps1"
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

# Fonction utilitaire pour générer des échantillons de distribution normale multivariée
function Get-MultivariateNormalSample {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$NumPoints,
        
        [Parameter(Mandatory = $true)]
        [double[]]$Mean,
        
        [Parameter(Mandatory = $true)]
        [double[][]]$Covariance,
        
        [Parameter(Mandatory = $false)]
        [string[]]$DimensionNames = $null
    )
    
    # Vérifier que les dimensions sont cohérentes
    $dimensions = $Mean.Length
    if ($Covariance.Length -ne $dimensions -or $Covariance[0].Length -ne $dimensions) {
        throw "Les dimensions de la moyenne et de la covariance ne correspondent pas."
    }
    
    # Utiliser des noms de dimensions par défaut si non spécifiés
    if ($null -eq $DimensionNames) {
        $DimensionNames = 1..$dimensions | ForEach-Object { "Dim$_" }
    }
    
    # Générer les échantillons
    $sample = @()
    for ($i = 0; $i -lt $NumPoints; $i++) {
        # Générer un vecteur de variables aléatoires normales standard
        $z = 1..$dimensions | ForEach-Object {
            $u1 = [Math]::Max(0.0001, Get-Random -Minimum 0 -Maximum 1)
            $u2 = Get-Random -Minimum 0 -Maximum 1
            [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
        }
        
        # Transformer en variables aléatoires normales multivariées
        # Note: Cette implémentation est simplifiée et ne prend pas en compte la décomposition de Cholesky
        # pour les matrices de covariance non diagonales
        $point = [PSCustomObject]@{}
        for ($j = 0; $j -lt $dimensions; $j++) {
            $value = $Mean[$j] + [Math]::Sqrt($Covariance[$j][$j]) * $z[$j]
            $point | Add-Member -MemberType NoteProperty -Name $DimensionNames[$j] -Value $value
        }
        
        $sample += $point
    }
    
    return $sample
}

Describe "Tests pour les fonctions du noyau cosinus" {
    Context "Tests de base pour Get-CosineKernel" {
        It "Devrait calculer la valeur correcte pour u = 0" {
            $result = Get-CosineKernel -U 0
            $expected = [Math]::PI / 4
            $result | Should -BeApproximately $expected -Epsilon 0.0001
        }
        
        It "Devrait calculer la valeur correcte pour u = 0.5" {
            $result = Get-CosineKernel -U 0.5
            $expected = ([Math]::PI / 4) * [Math]::Cos([Math]::PI * 0.5 / 2)
            $result | Should -BeApproximately $expected -Epsilon 0.0001
        }
        
        It "Devrait retourner 0 pour u > 1" {
            $result = Get-CosineKernel -U 1.5
            $result | Should -Be 0
        }
        
        It "Devrait être symétrique" {
            $result1 = Get-CosineKernel -U 0.5
            $result2 = Get-CosineKernel -U -0.5
            $result1 | Should -BeApproximately $result2 -Epsilon 0.0001
        }
    }
    
    Context "Tests de base pour Get-CosineKernelDensity" {
        # Générer des données de test en dehors du bloc BeforeAll
        # pour éviter les avertissements PSScriptAnalyzer sur les variables non utilisées
        $script:testData1 = Get-NormalSample -NumPoints 100 -Mean 50 -StdDev 10
        
        It "Devrait calculer la densité correctement" {
            $result = Get-CosineKernelDensity -X 50 -Data $script:testData1 -Bandwidth 5
            $result | Should -BeGreaterThan 0
        }
        
        It "Devrait calculer la largeur de bande optimale si non spécifiée" {
            $result = Get-CosineKernelDensity -X 50 -Data $script:testData1
            $result | Should -BeGreaterThan 0
        }
        
        It "Devrait lever une exception si les données contiennent moins de 2 points" {
            { Get-CosineKernelDensity -X 50 -Data @(1) } | Should -Throw "Les données doivent contenir au moins 2 points pour l'estimation de densité par noyau."
        }
    }
    
    Context "Tests de base pour Get-OptimizedCosineKernelDensity" {
        # Générer des données de test en dehors du bloc BeforeAll
        # pour éviter les avertissements PSScriptAnalyzer sur les variables non utilisées
        $script:testData2 = Get-NormalSample -NumPoints 100 -Mean 50 -StdDev 10
        
        It "Devrait calculer la densité correctement" {
            $result = Get-OptimizedCosineKernelDensity -X 50 -Data $script:testData2 -Bandwidth 5
            $result | Should -BeGreaterThan 0
        }
        
        It "Devrait calculer la largeur de bande optimale si non spécifiée" {
            $result = Get-OptimizedCosineKernelDensity -X 50 -Data $script:testData2
            $result | Should -BeGreaterThan 0
        }
        
        It "Devrait lever une exception si les données contiennent moins de 2 points" {
            { Get-OptimizedCosineKernelDensity -X 50 -Data @(1) } | Should -Throw "Les données doivent contenir au moins 2 points pour l'estimation de densité par noyau."
        }
        
        It "Devrait donner des résultats cohérents avec la fonction de base" {
            $resultBase = Get-CosineKernelDensity -X 50 -Data $script:testData2 -Bandwidth 5
            $resultOptimized = Get-OptimizedCosineKernelDensity -X 50 -Data $script:testData2 -Bandwidth 5
            
            $resultOptimized | Should -BeApproximately $resultBase -Epsilon 0.0001
        }
    }
    
    Context "Tests de base pour Get-OptimizedCosineKernelDensityMultiplePoints" {
        # Générer des données de test en dehors du bloc BeforeAll
        # pour éviter les avertissements PSScriptAnalyzer sur les variables non utilisées
        $script:testData3 = Get-NormalSample -NumPoints 100 -Mean 50 -StdDev 10
        
        It "Devrait calculer la densité correctement pour plusieurs points" {
            $evaluationPoints = @(40, 50, 60)
            $results = Get-OptimizedCosineKernelDensityMultiplePoints -EvaluationPoints $evaluationPoints -Data $script:testData3 -Bandwidth 5
            
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -Be 3
            $results[0].Density | Should -BeGreaterThan 0
            $results[1].Density | Should -BeGreaterThan 0
            $results[2].Density | Should -BeGreaterThan 0
        }
        
        It "Devrait calculer la largeur de bande optimale si non spécifiée" {
            $evaluationPoints = @(40, 50, 60)
            $results = Get-OptimizedCosineKernelDensityMultiplePoints -EvaluationPoints $evaluationPoints -Data $script:testData3
            
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -Be 3
            $results[0].Density | Should -BeGreaterThan 0
            $results[1].Density | Should -BeGreaterThan 0
            $results[2].Density | Should -BeGreaterThan 0
        }
        
        It "Devrait lever une exception si les données contiennent moins de 2 points" {
            { Get-OptimizedCosineKernelDensityMultiplePoints -EvaluationPoints @(40, 50, 60) -Data @(1) } | Should -Throw "Les données doivent contenir au moins 2 points pour l'estimation de densité par noyau."
        }
        
        It "Devrait donner des résultats cohérents avec la fonction de base" {
            $evaluationPoints = @(40, 50, 60)
            $results = Get-OptimizedCosineKernelDensityMultiplePoints -EvaluationPoints $evaluationPoints -Data $script:testData3 -Bandwidth 5
            
            foreach ($result in $results) {
                $resultBase = Get-CosineKernelDensity -X $result.Point -Data $script:testData3 -Bandwidth 5
                $result.Density | Should -BeApproximately $resultBase -Epsilon 0.0001
            }
        }
    }
    
    Context "Tests de base pour Get-CosineKernelDensityND" {
        # Générer des données de test bidimensionnelles et le point d'évaluation en dehors du bloc BeforeAll
        # pour éviter les avertissements PSScriptAnalyzer sur les variables non utilisées
        $script:testData2D = Get-MultivariateNormalSample -NumPoints 100 -Mean @(50, 50) -Covariance @(@(100, 0), @(0, 100)) -DimensionNames @("X", "Y")
        
        $script:point2D = [PSCustomObject]@{
            X = 50
            Y = 50
        }
        
        It "Devrait calculer la densité correctement pour des données bidimensionnelles" {
            $result = Get-CosineKernelDensityND -Point $script:point2D -Data $script:testData2D
            $result | Should -BeGreaterThan 0
        }
        
        It "Devrait calculer la largeur de bande optimale si non spécifiée" {
            $result = Get-CosineKernelDensityND -Point $script:point2D -Data $script:testData2D
            $result | Should -BeGreaterThan 0
        }
        
        It "Devrait lever une exception si les données contiennent moins de 2 points" {
            { Get-CosineKernelDensityND -Point $script:point2D -Data @($script:testData2D[0]) } | Should -Throw "Les données doivent contenir au moins 2 points pour l'estimation de densité par noyau."
        }
        
        It "Devrait fonctionner avec une largeur de bande unique" {
            $result = Get-CosineKernelDensityND -Point $script:point2D -Data $script:testData2D -Bandwidth 10
            $result | Should -BeGreaterThan 0
        }
        
        It "Devrait fonctionner avec des largeurs de bande différentes par dimension" {
            $bandwidths = @{
                X = 10
                Y = 15
            }
            $result = Get-CosineKernelDensityND -Point $script:point2D -Data $script:testData2D -Bandwidth $bandwidths
            $result | Should -BeGreaterThan 0
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
            $result = Get-CosineKernelDensityND -Point $script:point3D -Data $script:testData3D
            $result | Should -BeGreaterThan 0
        }
        
        It "Devrait fonctionner avec un sous-ensemble de dimensions" {
            $result = Get-CosineKernelDensityND -Point $script:point3D -Data $script:testData3D -Dimensions @("X", "Y")
            $result | Should -BeGreaterThan 0
        }
    }
}
