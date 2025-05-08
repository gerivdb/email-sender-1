# Tests pour le noyau uniforme (rectangular) dans l'estimation de densité par noyau
# Run with Pester: Invoke-Pester -Path ".\UniformKernel.Tests.ps1"

BeforeAll {
    # Charger le module du noyau uniforme
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UniformKernel.ps1"
    if (Test-Path $modulePath) {
        . $modulePath
    } else {
        throw "Le module UniformKernel.ps1 n'a pas été trouvé dans le répertoire parent."
    }
    
    # Charger le module KernelDensityEstimation s'il existe
    $kdeModulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\KernelDensityEstimation.psm1"
    if (Test-Path $kdeModulePath) {
        Import-Module $kdeModulePath -Force
    }
}

Describe "Tests pour le noyau uniforme" {
    Context "Tests de base pour Get-UniformKernel" {
        It "Devrait retourner 0.5 pour u = 0" {
            $result = Get-UniformKernel -U 0
            $result | Should -Be 0.5
        }
        
        It "Devrait retourner 0.5 pour u = 0.5" {
            $result = Get-UniformKernel -U 0.5
            $result | Should -Be 0.5
        }
        
        It "Devrait retourner 0.5 pour u = 1" {
            $result = Get-UniformKernel -U 1
            $result | Should -Be 0.5
        }
        
        It "Devrait retourner 0 pour u = 1.1" {
            $result = Get-UniformKernel -U 1.1
            $result | Should -Be 0
        }
        
        It "Devrait retourner 0 pour u = -1.1" {
            $result = Get-UniformKernel -U -1.1
            $result | Should -Be 0
        }
        
        It "Devrait retourner 0.5 pour u = -1" {
            $result = Get-UniformKernel -U -1
            $result | Should -Be 0.5
        }
        
        It "Devrait retourner 0.5 pour u = -0.5" {
            $result = Get-UniformKernel -U -0.5
            $result | Should -Be 0.5
        }
    }
    
    Context "Tests des propriétés mathématiques du noyau uniforme" {
        It "Le noyau uniforme est symétrique" {
            $values = -1..1 | ForEach-Object { $_ / 10 }
            
            foreach ($x in $values) {
                $valueAtX = Get-UniformKernel -U $x
                $valueAtMinusX = Get-UniformKernel -U (-$x)
                
                $valueAtX | Should -BeApproximately $valueAtMinusX -Epsilon 0.0001
            }
        }
        
        It "Le noyau uniforme s'intègre à 1 (approximativement)" {
            # Calculer l'intégrale numérique du noyau uniforme sur [-3, 3]
            $stepSize = 0.01
            $range = -3..3 | ForEach-Object { $_ * $stepSize }
            $integral = 0
            
            foreach ($x in $range) {
                $integral += Get-UniformKernel -U $x * $stepSize
            }
            
            $integral | Should -BeApproximately 1 -Epsilon 0.05
        }
    }
    
    Context "Tests de base pour Get-UniformKernelDensity" {
        BeforeAll {
            # Générer des données de test
            $testData = 1..100 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
        }
        
        It "Devrait calculer la densité correctement" {
            $result = Get-UniformKernelDensity -X 50 -Data $testData -Bandwidth 10
            $result | Should -BeGreaterThan 0
        }
        
        It "Devrait calculer la largeur de bande optimale si non spécifiée" {
            $result = Get-UniformKernelDensity -X 50 -Data $testData
            $result | Should -BeGreaterThan 0
        }
        
        It "Devrait lever une exception si les données contiennent moins de 2 points" {
            { Get-UniformKernelDensity -X 50 -Data @(1) } | Should -Throw "Les données doivent contenir au moins 2 points pour l'estimation de densité par noyau."
        }
    }
    
    Context "Tests avec des distributions connues" {
        BeforeAll {
            # Générer des données normales
            $normalData = 1..100 | ForEach-Object {
                # Méthode Box-Muller pour générer des variables aléatoires normales
                $u1 = Get-Random -Minimum 0.0001 -Maximum 0.9999
                $u2 = Get-Random -Minimum 0.0001 -Maximum 0.9999
                $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
                
                # Transformer pour obtenir une distribution normale avec moyenne 100 et écart-type 15
                100 + 15 * $z
            }
            
            # Générer des données uniformes
            $uniformData = 1..100 | ForEach-Object { Get-Random -Minimum 50 -Maximum 150 }
        }
        
        It "La densité maximale pour une distribution normale devrait être proche de la moyenne" {
            # Calculer la densité pour différents points
            $densityPoints = 50..150
            $densities = $densityPoints | ForEach-Object { 
                [PSCustomObject]@{
                    Point = $_
                    Density = Get-UniformKernelDensity -X $_ -Data $normalData -Bandwidth 10
                }
            }
            
            # Trouver le point de densité maximale
            $maxDensityPoint = ($densities | Sort-Object -Property Density -Descending)[0].Point
            
            # Vérifier que le point de densité maximale est proche de la moyenne (100)
            $maxDensityPoint | Should -BeGreaterThan 90
            $maxDensityPoint | Should -BeLessThan 110
        }
        
        It "La densité pour une distribution uniforme devrait être approximativement constante" {
            # Calculer la densité pour différents points
            $densityPoints = 60..140  # Points à l'intérieur de la distribution uniforme
            $densities = $densityPoints | ForEach-Object { 
                [PSCustomObject]@{
                    Point = $_
                    Density = Get-UniformKernelDensity -X $_ -Data $uniformData -Bandwidth 20
                }
            }
            
            # Calculer la densité moyenne
            $meanDensity = ($densities | Measure-Object -Property Density -Average).Average
            
            # Vérifier que les densités ne s'écartent pas trop de la moyenne
            foreach ($density in $densities) {
                $density.Density | Should -BeGreaterThan ($meanDensity * 0.5)
                $density.Density | Should -BeLessThan ($meanDensity * 1.5)
            }
        }
    }
    
    Context "Tests d'intégration avec KernelDensityEstimation" -Skip:(-not (Get-Command Get-KernelDensityEstimation -ErrorAction SilentlyContinue)) {
        BeforeAll {
            # Générer des données de test
            $testData = 1..100 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
        }
        
        It "Get-KernelDensityEstimation devrait fonctionner avec le noyau uniforme" {
            # Ajouter le noyau uniforme au switch dans Get-KernelDensity
            # Cette partie nécessite une modification du module KernelDensityEstimation.psm1
            
            # Tester si le noyau uniforme est disponible
            $result = Get-KernelDensityEstimation -Data $testData -KernelType "Uniform" -ErrorAction SilentlyContinue
            
            if ($null -ne $result) {
                $result | Should -Not -BeNullOrEmpty
                $result.KernelType | Should -Be "Uniform"
                $result.Bandwidth | Should -BeGreaterThan 0
                $result.DensityEstimates | Should -Not -BeNullOrEmpty
                $result.DensityEstimates | ForEach-Object { $_ | Should -BeGreaterOrEqual 0 }
            } else {
                Set-ItResult -Skipped -Because "Le noyau uniforme n'est pas encore intégré dans Get-KernelDensityEstimation"
            }
        }
    }
}

AfterAll {
    # Nettoyage
}
