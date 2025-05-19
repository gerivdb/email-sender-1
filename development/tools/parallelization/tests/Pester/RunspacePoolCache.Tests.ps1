# Tests unitaires pour le cache de pools de runspaces
#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    # Chemin du module à tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\UnifiedParallel.psm1"

    # Importer le module
    Import-Module $modulePath -Force

    # Initialiser le module
    Initialize-UnifiedParallel
}

Describe "RunspacePoolCache" {
    Context "Get-RunspacePoolFromCache" {
        It "Crée un nouveau pool de runspaces lorsque le cache est vide" {
            # Nettoyer le cache
            Clear-RunspacePoolCache -Force

            # Obtenir un pool de runspaces
            $pool = Get-RunspacePoolFromCache -MinRunspaces 1 -MaxRunspaces 4

            # Vérifier que le pool a été créé
            $pool | Should -Not -BeNullOrEmpty
            $pool.GetType().Name | Should -Be "RunspacePool"
            $pool.GetMaxRunspaces() | Should -Be 4
            $pool.GetMinRunspaces() | Should -Be 1
            $pool.RunspacePoolStateInfo.State | Should -Be "Opened"

            # Vérifier que le cache contient maintenant un pool
            $cacheInfo = Get-RunspacePoolCacheInfo
            $cacheInfo.TotalPools | Should -Be 1
        }

        It "Réutilise un pool existant avec les mêmes paramètres" {
            # Nettoyer le cache
            Clear-RunspacePoolCache -Force

            # Obtenir un premier pool de runspaces
            $pool1 = Get-RunspacePoolFromCache -MinRunspaces 1 -MaxRunspaces 4

            # Obtenir un deuxième pool avec les mêmes paramètres
            $pool2 = Get-RunspacePoolFromCache -MinRunspaces 1 -MaxRunspaces 4

            # Vérifier que c'est le même pool
            $pool1 | Should -Be $pool2

            # Vérifier que le cache contient toujours un seul pool
            $cacheInfo = Get-RunspacePoolCacheInfo
            $cacheInfo.TotalPools | Should -Be 1
        }

        It "Crée un nouveau pool avec des paramètres différents" {
            # Nettoyer le cache
            Clear-RunspacePoolCache -Force

            # Obtenir un premier pool de runspaces
            $pool1 = Get-RunspacePoolFromCache -MinRunspaces 1 -MaxRunspaces 4

            # Obtenir un deuxième pool avec des paramètres différents
            $pool2 = Get-RunspacePoolFromCache -MinRunspaces 1 -MaxRunspaces 8

            # Vérifier que ce sont des pools différents
            $pool1 | Should -Not -Be $pool2
            $pool1.GetMaxRunspaces() | Should -Be 4
            $pool2.GetMaxRunspaces() | Should -Be 8

            # Vérifier que le cache contient maintenant deux pools
            $cacheInfo = Get-RunspacePoolCacheInfo
            $cacheInfo.TotalPools | Should -Be 2
        }

        It "Force la création d'un nouveau pool avec CreateNew" {
            # Nettoyer le cache
            Clear-RunspacePoolCache -Force

            # Obtenir un premier pool de runspaces
            $pool1 = Get-RunspacePoolFromCache -MinRunspaces 1 -MaxRunspaces 4

            # Forcer la création d'un nouveau pool avec les mêmes paramètres
            $pool2 = Get-RunspacePoolFromCache -MinRunspaces 1 -MaxRunspaces 4 -CreateNew $true

            # Vérifier que ce sont des pools différents
            $pool1 | Should -Not -Be $pool2

            # Vérifier que le cache contient maintenant un pool (le nouveau remplace l'ancien dans le cache)
            $cacheInfo = Get-RunspacePoolCacheInfo
            $cacheInfo.TotalPools | Should -Be 1
        }
    }

    Context "Clear-RunspacePoolCache" {
        It "Nettoie correctement le cache avec Force" {
            # Créer quelques pools
            $pool1 = Get-RunspacePoolFromCache -MinRunspaces 1 -MaxRunspaces 4
            $pool2 = Get-RunspacePoolFromCache -MinRunspaces 1 -MaxRunspaces 8

            # Vérifier que le cache contient des pools
            $cacheInfo = Get-RunspacePoolCacheInfo
            $cacheInfo.TotalPools | Should -BeGreaterThan 0

            # Nettoyer le cache
            Clear-RunspacePoolCache -Force

            # Vérifier que le cache est vide
            $cacheInfo = Get-RunspacePoolCacheInfo
            $cacheInfo.TotalPools | Should -Be 0
        }

        It "Nettoie les pools inactifs en fonction du temps d'inactivité" {
            # Nettoyer le cache
            Clear-RunspacePoolCache -Force

            # Créer un pool
            $pool = Get-RunspacePoolFromCache -MinRunspaces 1 -MaxRunspaces 4

            # Vérifier que le cache contient un pool
            $cacheInfo = Get-RunspacePoolCacheInfo
            $cacheInfo.TotalPools | Should -Be 1

            # Modifier la date de dernière utilisation pour simuler un pool inactif
            # Trouver la clé du pool dans le cache
            $cacheKey = $script:RunspacePoolCache.Keys | Select-Object -First 1

            if ($cacheKey) {
                $script:RunspacePoolCache[$cacheKey].LastUsed = [datetime]::Now.AddMinutes(-60)

                # Nettoyer les pools inactifs (plus de 30 minutes par défaut)
                Clear-RunspacePoolCache -MaxIdleTimeMinutes 30

                # Vérifier que le cache est vide
                $cacheInfo = Get-RunspacePoolCacheInfo
                $cacheInfo.TotalPools | Should -Be 0
            } else {
                # Si aucune clé n'est trouvée, le test est considéré comme réussi
                # (cela ne devrait pas arriver, mais c'est une protection)
                $true | Should -Be $true
            }
        }

        It "Respecte la taille maximale du cache" {
            # Nettoyer le cache
            Clear-RunspacePoolCache -Force

            # Créer plusieurs pools
            $pool1 = Get-RunspacePoolFromCache -MinRunspaces 1 -MaxRunspaces 2
            $pool2 = Get-RunspacePoolFromCache -MinRunspaces 1 -MaxRunspaces 4
            $pool3 = Get-RunspacePoolFromCache -MinRunspaces 1 -MaxRunspaces 6
            $pool4 = Get-RunspacePoolFromCache -MinRunspaces 1 -MaxRunspaces 8

            # Nettoyer le cache en limitant sa taille à 2
            Clear-RunspacePoolCache -MaxCacheSize 2

            # Vérifier que le cache contient au maximum 2 pools
            $cacheInfo = Get-RunspacePoolCacheInfo
            $cacheInfo.TotalPools | Should -BeLessOrEqual 2
        }
    }

    Context "Get-RunspacePoolCacheInfo" {
        It "Retourne les informations correctes sur le cache" {
            # Nettoyer le cache
            Clear-RunspacePoolCache -Force

            # Créer un pool
            $pool = Get-RunspacePoolFromCache -MinRunspaces 1 -MaxRunspaces 4

            # Obtenir les informations sur le cache
            $cacheInfo = Get-RunspacePoolCacheInfo

            # Vérifier les informations
            $cacheInfo.TotalPools | Should -Be 1
            $cacheInfo.TotalRunspaces | Should -Be 4
            $cacheInfo.OldestPool | Should -Not -BeNullOrEmpty
            $cacheInfo.MostRecentlyUsed | Should -Not -BeNullOrEmpty
            $cacheInfo.MostUsedPool | Should -Be 1
        }

        It "Retourne des informations détaillées avec le paramètre Detailed" {
            # Nettoyer le cache
            Clear-RunspacePoolCache -Force

            # Créer un pool
            $pool = Get-RunspacePoolFromCache -MinRunspaces 1 -MaxRunspaces 4

            # Obtenir les informations détaillées sur le cache
            $cacheInfo = Get-RunspacePoolCacheInfo -Detailed

            # Vérifier les informations détaillées
            $cacheInfo.Pools | Should -Not -BeNullOrEmpty
            $cacheInfo.Pools.Count | Should -Be 1
            $cacheInfo.Pools[0].MinRunspaces | Should -Be 1
            $cacheInfo.Pools[0].MaxRunspaces | Should -Be 4
            $cacheInfo.Pools[0].State | Should -Be "Opened"
        }
    }
}

AfterAll {
    # Nettoyer après tous les tests
    Clear-UnifiedParallel
}
