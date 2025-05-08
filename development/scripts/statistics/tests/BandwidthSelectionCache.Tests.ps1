BeforeAll {
    # Importer les modules à tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\KernelDensityEstimation.psm1"
    Import-Module $modulePath -Force

    $cachePath = Join-Path -Path $PSScriptRoot -ChildPath "..\BandwidthSelectionCache.ps1"
    . $cachePath

    $optionsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\BandwidthSelectionOptions.ps1"
    . $optionsPath
}

Describe "Tests du module BandwidthSelectionCache" {
    Context "Tests de base" {
        BeforeEach {
            # Réinitialiser le cache avant chaque test
            Initialize-BandwidthSelectionCache -MaxCacheSize 10 -ExpirationMinutes 5
        }

        It "Initialise correctement le cache" {
            $stats = Get-CacheStatistics

            $stats | Should -Not -BeNullOrEmpty
            $stats.EntryCount | Should -Be 0
            $stats.MaxSize | Should -Be 10
            $stats.ExpirationMinutes | Should -Be 5
            $stats.Hits | Should -Be 0
            $stats.Misses | Should -Be 0
        }

        It "Génère une clé de cache unique pour des données similaires" {
            $data1 = @(1, 2, 3, 4, 5)
            $data2 = @(1, 2, 3, 4, 5)
            $data3 = @(1, 2, 3, 4, 6)

            $params = @{
                KernelType = "Gaussian"
                Objective  = "Balanced"
            }

            $key1 = Get-CacheKey -Data $data1 -Parameters $params
            $key2 = Get-CacheKey -Data $data2 -Parameters $params
            $key3 = Get-CacheKey -Data $data3 -Parameters $params

            $key1 | Should -Be $key2
            $key1 | Should -Not -Be $key3
        }

        It "Ajoute et récupère correctement une entrée du cache" {
            $data = @(1, 2, 3, 4, 5)
            $params = @{
                KernelType = "Gaussian"
                Objective  = "Balanced"
            }

            $key = Get-CacheKey -Data $data -Parameters $params
            $result = @{
                SelectedMethod = "Silverman"
                Bandwidth      = 0.5
                ExecutionTime  = 0.1
            }

            # Ajouter l'entrée au cache
            Add-CacheEntry -Key $key -Result $result

            # Récupérer l'entrée du cache
            $cachedResult = Get-CacheEntry -Key $key

            $cachedResult | Should -Not -BeNullOrEmpty
            $cachedResult.SelectedMethod | Should -Be "Silverman"
            $cachedResult.Bandwidth | Should -Be 0.5
            $cachedResult.ExecutionTime | Should -Be 0.1

            # Vérifier les statistiques
            $stats = Get-CacheStatistics
            $stats.EntryCount | Should -Be 1
            $stats.Hits | Should -Be 1
            $stats.Additions | Should -Be 1
        }

        It "Retourne null pour une clé inexistante" {
            $result = Get-CacheEntry -Key "NonExistentKey"

            $result | Should -BeNullOrEmpty

            # Vérifier les statistiques
            $stats = Get-CacheStatistics
            $stats.Misses | Should -Be 1
        }

        It "Supprime les entrées expirées" {
            # Ajouter quelques entrées au cache
            for ($i = 0; $i -lt 3; $i++) {
                $key = "Key$i"
                $result = @{
                    SelectedMethod = "Method$i"
                    Bandwidth      = $i
                }

                Add-CacheEntry -Key $key -Result $result
            }

            # Vérifier que les entrées ont été ajoutées
            $stats = Get-CacheStatistics
            $stats.EntryCount | Should -Be 3

            # Simuler l'expiration des entrées en modifiant directement le timestamp
            $script:BandwidthSelectionCache.Entries["Key0"].Timestamp = (Get-Date).AddMinutes(-10)
            $script:BandwidthSelectionCache.Entries["Key1"].Timestamp = (Get-Date).AddMinutes(-10)

            # Nettoyer les entrées expirées
            Clear-ExpiredCacheEntries

            # Vérifier que les entrées expirées ont été supprimées
            $stats = Get-CacheStatistics
            $stats.EntryCount | Should -Be 1
            $stats.Expirations | Should -Be 2

            # Vérifier que l'entrée non expirée est toujours présente
            $result = Get-CacheEntry -Key "Key2"
            $result | Should -Not -BeNullOrEmpty
            $result.SelectedMethod | Should -Be "Method2"
        }

        It "Supprime l'entrée la plus ancienne lorsque le cache est plein" {
            # Remplir le cache (taille max = 10)
            for ($i = 0; $i -lt 10; $i++) {
                $key = "Key$i"
                $result = @{
                    SelectedMethod = "Method$i"
                    Bandwidth      = $i
                }

                Add-CacheEntry -Key $key -Result $result
            }

            # Vérifier que le cache est plein
            $stats = Get-CacheStatistics
            $stats.EntryCount | Should -Be 10

            # Ajouter une nouvelle entrée
            $key = "KeyNew"
            $result = @{
                SelectedMethod = "MethodNew"
                Bandwidth      = 99
            }

            Add-CacheEntry -Key $key -Result $result

            # Vérifier que le cache contient toujours 10 entrées
            $stats = Get-CacheStatistics
            $stats.EntryCount | Should -Be 10
            $stats.Evictions | Should -Be 1

            # Vérifier que la nouvelle entrée est présente
            $result = Get-CacheEntry -Key "KeyNew"
            $result | Should -Not -BeNullOrEmpty
            $result.SelectedMethod | Should -Be "MethodNew"

            # Vérifier que l'entrée la plus ancienne a été supprimée
            $result = Get-CacheEntry -Key "Key0"
            $result | Should -BeNullOrEmpty
        }
    }
}

Describe "Tests de l'intégration du cache avec Get-OptimalBandwidthMethod" {
    Context "Tests de base" {
        BeforeEach {
            # Réinitialiser le cache avant chaque test
            if (Get-Command -Name Initialize-BandwidthSelectionCache -ErrorAction SilentlyContinue) {
                Initialize-BandwidthSelectionCache -MaxCacheSize 10 -ExpirationMinutes 5
            }
        }

        It "Utilise le cache pour des appels répétés avec les mêmes données" {
            # Réinitialiser le cache
            Initialize-BandwidthSelectionCache -MaxCacheSize 10 -ExpirationMinutes 5

            # Créer des données de test
            $data = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

            # Vérifier les statistiques initiales du cache
            $initialStats = Get-CacheStatistics
            $initialHits = $initialStats.Hits
            $initialAdditions = $initialStats.Additions

            # Premier appel (sans cache)
            $result1 = Get-OptimalBandwidthMethod -Data $data -KernelType "Gaussian" -Objective "Balanced" -UseCache $true

            # Vérifier que l'entrée a été ajoutée au cache
            $statsAfterFirstCall = Get-CacheStatistics
            $statsAfterFirstCall.Additions | Should -Be ($initialAdditions + 1)

            # Deuxième appel (avec cache)
            $result2 = Get-OptimalBandwidthMethod -Data $data -KernelType "Gaussian" -Objective "Balanced" -UseCache $true

            # Vérifier que les résultats sont identiques
            $result1.SelectedMethod | Should -Be $result2.SelectedMethod
            $result1.Bandwidth | Should -Be $result2.Bandwidth

            # Vérifier les statistiques du cache
            $statsAfterSecondCall = Get-CacheStatistics
            $statsAfterSecondCall.Hits | Should -Be ($initialHits + 1)
            $statsAfterSecondCall.Additions | Should -Be ($initialAdditions + 1)
        }

        It "N'utilise pas le cache si UseCache est $false" {
            # Créer des données de test
            $data = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

            # Premier appel (sans cache)
            $result1 = Get-OptimalBandwidthMethod -Data $data -KernelType "Gaussian" -Objective "Balanced" -UseCache $false

            # Deuxième appel (sans cache)
            $result2 = Get-OptimalBandwidthMethod -Data $data -KernelType "Gaussian" -Objective "Balanced" -UseCache $false

            # Vérifier que les résultats sont identiques (car les données sont identiques)
            $result1.SelectedMethod | Should -Be $result2.SelectedMethod
            $result1.Bandwidth | Should -Be $result2.Bandwidth

            # Vérifier les statistiques du cache (ne devraient pas changer)
            $stats = Get-CacheStatistics
            $stats.Additions | Should -Be 0
        }
    }
}

Describe "Tests de l'intégration du cache avec Get-KernelDensityEstimation" {
    Context "Tests de base" {
        BeforeEach {
            # Réinitialiser le cache avant chaque test
            if (Get-Command -Name Initialize-BandwidthSelectionCache -ErrorAction SilentlyContinue) {
                Initialize-BandwidthSelectionCache -MaxCacheSize 10 -ExpirationMinutes 5
            }
        }

        It "Utilise le cache lorsque CacheResults est activé dans BandwidthSelectionOptions" {
            # Réinitialiser le cache
            Initialize-BandwidthSelectionCache -MaxCacheSize 10 -ExpirationMinutes 5

            # Créer des données de test
            $data = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

            # Vérifier les statistiques initiales du cache
            $initialStats = Get-CacheStatistics
            $initialHits = $initialStats.Hits
            $initialAdditions = $initialStats.Additions

            # Créer des options avec mise en cache activée
            $options = Get-BandwidthSelectionOptions -CacheResults $true

            # Premier appel (sans cache)
            $result1 = Get-KernelDensityEstimation -Data $data -BandwidthMethod "Auto" -BandwidthSelectionOptions $options

            # Vérifier que l'entrée a été ajoutée au cache
            $statsAfterFirstCall = Get-CacheStatistics
            $statsAfterFirstCall.Additions | Should -Be ($initialAdditions + 1)

            # Deuxième appel (avec cache)
            $result2 = Get-KernelDensityEstimation -Data $data -BandwidthMethod "Auto" -BandwidthSelectionOptions $options

            # Vérifier que les résultats sont identiques
            $result1.Bandwidth | Should -Be $result2.Bandwidth
            if ($null -ne $result1.SelectedBandwidthMethod -and $null -ne $result2.SelectedBandwidthMethod) {
                $result1.SelectedBandwidthMethod | Should -Be $result2.SelectedBandwidthMethod
            }

            # Vérifier les statistiques du cache
            $statsAfterSecondCall = Get-CacheStatistics
            $statsAfterSecondCall.Hits | Should -Be ($initialHits + 1)
            $statsAfterSecondCall.Additions | Should -Be ($initialAdditions + 1)
        }
    }
}
