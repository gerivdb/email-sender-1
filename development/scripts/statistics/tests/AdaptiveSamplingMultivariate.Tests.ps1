# Tests pour AdaptiveSamplingMultivariate.ps1
# Run with Pester: Invoke-Pester -Path ".\AdaptiveSamplingMultivariate.Tests.ps1"

BeforeAll {
    # Charger les modules nécessaires
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\AdaptiveSamplingMultivariate.ps1"
    . $modulePath
}

Describe "Tests pour l'échantillonnage adaptatif multidimensionnel" {
    Context "Tests de base pour Get-AdaptiveSamplingMultivariate" {
        It "Devrait retourner les données d'origine si elles sont plus petites que la taille maximale de l'échantillon" {
            # Créer des données de test
            $data = 1..10 | ForEach-Object {
                [PSCustomObject]@{
                    X = Get-Random -Minimum 0 -Maximum 100
                    Y = Get-Random -Minimum 0 -Maximum 100
                }
            }
            
            $result = Get-AdaptiveSamplingMultivariate -Data $data -MaxSampleSize 20
            $result.Count | Should -Be 10
        }
        
        It "Devrait échantillonner les données si elles sont plus grandes que la taille maximale de l'échantillon" {
            # Créer des données de test
            $data = 1..2000 | ForEach-Object {
                [PSCustomObject]@{
                    X = Get-Random -Minimum 0 -Maximum 100
                    Y = Get-Random -Minimum 0 -Maximum 100
                }
            }
            
            $result = Get-AdaptiveSamplingMultivariate -Data $data -MaxSampleSize 500
            $result.Count | Should -BeLessOrEqual 500
        }
        
        It "Devrait préserver les valeurs extrêmes si demandé" {
            # Créer des données de test avec des valeurs extrêmes
            $data = 1..1000 | ForEach-Object {
                [PSCustomObject]@{
                    X = Get-Random -Minimum 0 -Maximum 100
                    Y = Get-Random -Minimum 0 -Maximum 100
                }
            }
            
            # Ajouter des valeurs extrêmes
            $data += [PSCustomObject]@{
                X = 1000
                Y = 1000
            }
            
            $data += [PSCustomObject]@{
                X = -1000
                Y = -1000
            }
            
            $result = Get-AdaptiveSamplingMultivariate -Data $data -MaxSampleSize 100 -PreserveExtremes $true
            
            # Vérifier que les valeurs extrêmes sont préservées
            $hasExtremeMax = $false
            $hasExtremeMin = $false
            
            foreach ($point in $result) {
                if ($point.X -eq 1000 -and $point.Y -eq 1000) {
                    $hasExtremeMax = $true
                }
                if ($point.X -eq -1000 -and $point.Y -eq -1000) {
                    $hasExtremeMin = $true
                }
            }
            
            $hasExtremeMax -or $hasExtremeMin | Should -Be $true
        }
        
        It "Devrait utiliser la méthode de stratification spécifiée" {
            # Créer des données de test
            $data = 1..1000 | ForEach-Object {
                [PSCustomObject]@{
                    X = Get-Random -Minimum 0 -Maximum 100
                    Y = Get-Random -Minimum 0 -Maximum 100
                }
            }
            
            $result1 = Get-AdaptiveSamplingMultivariate -Data $data -MaxSampleSize 100 -StratificationMethod "Mahalanobis"
            $result2 = Get-AdaptiveSamplingMultivariate -Data $data -MaxSampleSize 100 -StratificationMethod "Uniform"
            
            # Les résultats devraient être différents
            $diff = Compare-Object -ReferenceObject $result1 -DifferenceObject $result2
            $diff | Should -Not -BeNullOrEmpty
        }
        
        It "Devrait accepter des dimensions spécifiées" {
            # Créer des données de test
            $data = 1..100 | ForEach-Object {
                [PSCustomObject]@{
                    X = Get-Random -Minimum 0 -Maximum 100
                    Y = Get-Random -Minimum 0 -Maximum 100
                    Z = Get-Random -Minimum 0 -Maximum 100
                }
            }
            
            $result = Get-AdaptiveSamplingMultivariate -Data $data -Dimensions @("X", "Y") -MaxSampleSize 50
            $result.Count | Should -BeLessOrEqual 50
        }
        
        It "Devrait lever une exception si une dimension spécifiée n'existe pas" {
            # Créer des données de test
            $data = 1..100 | ForEach-Object {
                [PSCustomObject]@{
                    X = Get-Random -Minimum 0 -Maximum 100
                    Y = Get-Random -Minimum 0 -Maximum 100
                }
            }
            
            { Get-AdaptiveSamplingMultivariate -Data $data -Dimensions @("X", "Z") -MaxSampleSize 50 } | Should -Throw "Le point de données ne contient pas la dimension spécifiée: Z"
        }
    }
    
    Context "Tests de performance pour Get-AdaptiveSamplingMultivariate" {
        It "Devrait traiter efficacement de grands ensembles de données" {
            # Créer un grand ensemble de données
            $data = 1..5000 | ForEach-Object {
                [PSCustomObject]@{
                    X = Get-Random -Minimum 0 -Maximum 1000
                    Y = Get-Random -Minimum 0 -Maximum 1000
                    Z = Get-Random -Minimum 0 -Maximum 1000
                }
            }
            
            # Mesurer le temps d'exécution
            $startTime = Get-Date
            $result = Get-AdaptiveSamplingMultivariate -Data $data -MaxSampleSize 500
            $endTime = Get-Date
            $executionTime = ($endTime - $startTime).TotalSeconds
            
            # Vérifier que le résultat est correct
            $result.Count | Should -BeLessOrEqual 500
            
            # Vérifier que le temps d'exécution est raisonnable (moins de 10 secondes)
            $executionTime | Should -BeLessThan 10
        }
    }
    
    Context "Tests de qualité pour Get-AdaptiveSamplingMultivariate" {
        It "Devrait préserver la distribution des données" {
            # Créer des données de test avec une distribution normale
            $data = 1..2000 | ForEach-Object {
                # Générer des variables aléatoires normales
                $u1 = Get-Random -Minimum 0.0001 -Maximum 0.9999
                $u2 = Get-Random -Minimum 0.0001 -Maximum 0.9999
                $z1 = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
                $z2 = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Sin(2 * [Math]::PI * $u2)
                
                # Ajouter une moyenne et une échelle
                $x = 50 + 10 * $z1
                $y = 50 + 10 * $z2
                
                [PSCustomObject]@{
                    X = $x
                    Y = $y
                }
            }
            
            $result = Get-AdaptiveSamplingMultivariate -Data $data -MaxSampleSize 500 -StratificationMethod "Mahalanobis"
            
            # Calculer les statistiques des données originales
            $originalXMean = ($data | ForEach-Object { $_.X } | Measure-Object -Average).Average
            $originalYMean = ($data | ForEach-Object { $_.Y } | Measure-Object -Average).Average
            
            # Calculer les statistiques des données échantillonnées
            $sampledXMean = ($result | ForEach-Object { $_.X } | Measure-Object -Average).Average
            $sampledYMean = ($result | ForEach-Object { $_.Y } | Measure-Object -Average).Average
            
            # Vérifier que les moyennes sont proches
            $sampledXMean | Should -BeGreaterThan ($originalXMean - 5)
            $sampledXMean | Should -BeLessThan ($originalXMean + 5)
            $sampledYMean | Should -BeGreaterThan ($originalYMean - 5)
            $sampledYMean | Should -BeLessThan ($originalYMean + 5)
        }
    }
}

AfterAll {
    # Nettoyage
}
