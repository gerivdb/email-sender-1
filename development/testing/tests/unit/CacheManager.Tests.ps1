#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module CacheManager.ps1.
.DESCRIPTION
    Ce script contient des tests unitaires pour le module CacheManager.ps1.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-06-06
#>

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Chemins des modules Ã  tester
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$modulesPath = Join-Path -Path $projectRoot -ChildPath "modules"
$cacheManagerPath = Join-Path -Path $modulesPath -ChildPath "CacheManager.ps1"

# DÃ©finir les tests
Describe "Tests du module CacheManager" {
    BeforeAll {
        # Importer le module
        . $cacheManagerPath
        
        # Initialiser le gestionnaire de cache
        Initialize-CacheManager -Enabled $true -MaxItems 10 -DefaultTTL 60 -EvictionPolicy "LRU"
    }
    
    Context "Tests de la fonction Initialize-CacheManager" {
        It "Initialise correctement le gestionnaire de cache" {
            $result = Initialize-CacheManager -Enabled $true -MaxItems 20 -DefaultTTL 120 -EvictionPolicy "LFU"
            $result | Should -Be $true
            
            $stats = Get-CacheStatistics
            $stats.Enabled | Should -Be $true
            $stats.MaxItems | Should -Be 20
            $stats.EvictionPolicy | Should -Be "LFU"
        }
        
        It "RÃ©initialise le cache lors de l'initialisation" {
            # Ajouter un Ã©lÃ©ment au cache
            Set-CacheItem -Key "TestKey" -Value "TestValue"
            
            # RÃ©initialiser le cache
            Initialize-CacheManager -Force
            
            # VÃ©rifier que l'Ã©lÃ©ment a Ã©tÃ© supprimÃ©
            $cachedItem = Get-CacheItem -Key "TestKey"
            $cachedItem | Should -BeNullOrEmpty
        }
    }
    
    Context "Tests des fonctions Get-CacheItem et Set-CacheItem" {
        BeforeEach {
            # RÃ©initialiser le cache avant chaque test
            Initialize-CacheManager -Force -Enabled $true -MaxItems 10 -DefaultTTL 60 -EvictionPolicy "LRU"
        }
        
        It "Ajoute et rÃ©cupÃ¨re correctement un Ã©lÃ©ment du cache" {
            # Ajouter un Ã©lÃ©ment au cache
            Set-CacheItem -Key "TestKey" -Value "TestValue"
            
            # RÃ©cupÃ©rer l'Ã©lÃ©ment du cache
            $cachedItem = Get-CacheItem -Key "TestKey"
            
            # VÃ©rifier que l'Ã©lÃ©ment est correct
            $cachedItem | Should -Be "TestValue"
        }
        
        It "Retourne null pour un Ã©lÃ©ment non prÃ©sent dans le cache" {
            $cachedItem = Get-CacheItem -Key "NonExistentKey"
            $cachedItem | Should -BeNullOrEmpty
        }
        
        It "Met Ã  jour correctement un Ã©lÃ©ment existant dans le cache" {
            # Ajouter un Ã©lÃ©ment au cache
            Set-CacheItem -Key "TestKey" -Value "TestValue"
            
            # Mettre Ã  jour l'Ã©lÃ©ment
            Set-CacheItem -Key "TestKey" -Value "UpdatedValue"
            
            # RÃ©cupÃ©rer l'Ã©lÃ©ment mis Ã  jour
            $cachedItem = Get-CacheItem -Key "TestKey"
            
            # VÃ©rifier que l'Ã©lÃ©ment a Ã©tÃ© mis Ã  jour
            $cachedItem | Should -Be "UpdatedValue"
        }
        
        It "Respecte la durÃ©e de vie (TTL) des Ã©lÃ©ments" {
            # Ajouter un Ã©lÃ©ment au cache avec un TTL court
            Set-CacheItem -Key "ExpiringKey" -Value "ExpiringValue" -TTL 1
            
            # VÃ©rifier que l'Ã©lÃ©ment est prÃ©sent
            $cachedItem = Get-CacheItem -Key "ExpiringKey"
            $cachedItem | Should -Be "ExpiringValue"
            
            # Attendre l'expiration
            Start-Sleep -Seconds 2
            
            # VÃ©rifier que l'Ã©lÃ©ment a expirÃ©
            $expiredItem = Get-CacheItem -Key "ExpiringKey"
            $expiredItem | Should -BeNullOrEmpty
        }
    }
    
    Context "Tests de la fonction Remove-CacheItem" {
        BeforeEach {
            # RÃ©initialiser le cache avant chaque test
            Initialize-CacheManager -Force -Enabled $true -MaxItems 10 -DefaultTTL 60 -EvictionPolicy "LRU"
            
            # Ajouter des Ã©lÃ©ments au cache
            Set-CacheItem -Key "Key1" -Value "Value1"
            Set-CacheItem -Key "Key2" -Value "Value2"
        }
        
        It "Supprime correctement un Ã©lÃ©ment du cache" {
            # Supprimer un Ã©lÃ©ment
            $result = Remove-CacheItem -Key "Key1"
            
            # VÃ©rifier que la suppression a rÃ©ussi
            $result | Should -Be $true
            
            # VÃ©rifier que l'Ã©lÃ©ment a Ã©tÃ© supprimÃ©
            $cachedItem = Get-CacheItem -Key "Key1"
            $cachedItem | Should -BeNullOrEmpty
            
            # VÃ©rifier que les autres Ã©lÃ©ments sont toujours prÃ©sents
            $otherItem = Get-CacheItem -Key "Key2"
            $otherItem | Should -Be "Value2"
        }
        
        It "Retourne false pour un Ã©lÃ©ment non prÃ©sent dans le cache" {
            $result = Remove-CacheItem -Key "NonExistentKey"
            $result | Should -Be $false
        }
    }
    
    Context "Tests de la fonction Clear-Cache" {
        BeforeEach {
            # RÃ©initialiser le cache avant chaque test
            Initialize-CacheManager -Force -Enabled $true -MaxItems 10 -DefaultTTL 60 -EvictionPolicy "LRU"
            
            # Ajouter des Ã©lÃ©ments au cache
            Set-CacheItem -Key "Key1" -Value "Value1"
            Set-CacheItem -Key "Key2" -Value "Value2"
        }
        
        It "Vide correctement le cache" {
            # Vider le cache
            $result = Clear-Cache
            
            # VÃ©rifier que le vidage a rÃ©ussi
            $result | Should -Be $true
            
            # VÃ©rifier que les Ã©lÃ©ments ont Ã©tÃ© supprimÃ©s
            $cachedItem1 = Get-CacheItem -Key "Key1"
            $cachedItem1 | Should -BeNullOrEmpty
            
            $cachedItem2 = Get-CacheItem -Key "Key2"
            $cachedItem2 | Should -BeNullOrEmpty
        }
    }
    
    Context "Tests de la fonction Get-CacheStatistics" {
        BeforeEach {
            # RÃ©initialiser le cache avant chaque test
            Initialize-CacheManager -Force -Enabled $true -MaxItems 10 -DefaultTTL 60 -EvictionPolicy "LRU"
        }
        
        It "Retourne des statistiques correctes" {
            # Ajouter des Ã©lÃ©ments au cache
            Set-CacheItem -Key "Key1" -Value "Value1"
            Set-CacheItem -Key "Key2" -Value "Value2"
            
            # RÃ©cupÃ©rer des Ã©lÃ©ments (hits)
            Get-CacheItem -Key "Key1"
            Get-CacheItem -Key "Key1"
            
            # RÃ©cupÃ©rer des Ã©lÃ©ments non existants (misses)
            Get-CacheItem -Key "NonExistentKey1"
            Get-CacheItem -Key "NonExistentKey2"
            
            # RÃ©cupÃ©rer les statistiques
            $stats = Get-CacheStatistics
            
            # VÃ©rifier les statistiques
            $stats.Enabled | Should -Be $true
            $stats.ItemCount | Should -Be 2
            $stats.MaxItems | Should -Be 10
            $stats.UsagePercentage | Should -Be 20
            $stats.Hits | Should -Be 2
            $stats.Misses | Should -Be 2
            $stats.TotalRequests | Should -Be 4
            $stats.HitRate | Should -Be 0.5
            $stats.EvictionPolicy | Should -Be "LRU"
        }
    }
    
    Context "Tests de la fonction Invoke-CachedFunction" {
        BeforeEach {
            # RÃ©initialiser le cache avant chaque test
            Initialize-CacheManager -Force -Enabled $true -MaxItems 10 -DefaultTTL 60 -EvictionPolicy "LRU"
        }
        
        It "ExÃ©cute correctement une fonction et met en cache le rÃ©sultat" {
            # DÃ©finir une fonction de test
            $scriptBlock = {
                param($a, $b)
                return $a + $b
            }
            
            # ExÃ©cuter la fonction avec mise en cache
            $result1 = Invoke-CachedFunction -ScriptBlock $scriptBlock -CacheKey "Addition_2_3" -Arguments @(2, 3)
            
            # VÃ©rifier le rÃ©sultat
            $result1 | Should -Be 5
            
            # ExÃ©cuter Ã  nouveau la fonction (devrait utiliser le cache)
            $result2 = Invoke-CachedFunction -ScriptBlock $scriptBlock -CacheKey "Addition_2_3" -Arguments @(2, 3)
            
            # VÃ©rifier le rÃ©sultat
            $result2 | Should -Be 5
            
            # VÃ©rifier les statistiques
            $stats = Get-CacheStatistics
            $stats.Hits | Should -Be 1
            $stats.Misses | Should -Be 1
        }
        
        It "ExÃ©cute directement la fonction si le cache est dÃ©sactivÃ©" {
            # DÃ©sactiver le cache
            Initialize-CacheManager -Force -Enabled $false
            
            # DÃ©finir une fonction de test
            $scriptBlock = {
                param($a, $b)
                return $a + $b
            }
            
            # ExÃ©cuter la fonction avec mise en cache
            $result = Invoke-CachedFunction -ScriptBlock $scriptBlock -CacheKey "Addition_2_3" -Arguments @(2, 3)
            
            # VÃ©rifier le rÃ©sultat
            $result | Should -Be 5
            
            # VÃ©rifier les statistiques
            $stats = Get-CacheStatistics
            $stats.Hits | Should -Be 0
            $stats.Misses | Should -Be 0
        }
    }
    
    Context "Tests des politiques d'Ã©viction" {
        It "Applique correctement la politique d'Ã©viction LRU" {
            # Initialiser le cache avec une taille limitÃ©e
            Initialize-CacheManager -Force -Enabled $true -MaxItems 3 -DefaultTTL 60 -EvictionPolicy "LRU"
            
            # Ajouter des Ã©lÃ©ments au cache
            Set-CacheItem -Key "Key1" -Value "Value1"
            Set-CacheItem -Key "Key2" -Value "Value2"
            Set-CacheItem -Key "Key3" -Value "Value3"
            
            # AccÃ©der Ã  Key1 pour le rendre rÃ©cemment utilisÃ©
            Get-CacheItem -Key "Key1"
            
            # Ajouter un nouvel Ã©lÃ©ment pour dÃ©clencher l'Ã©viction
            Set-CacheItem -Key "Key4" -Value "Value4"
            
            # VÃ©rifier que Key2 a Ã©tÃ© Ã©vincÃ© (le moins rÃ©cemment utilisÃ©)
            $cachedItem1 = Get-CacheItem -Key "Key1"
            $cachedItem1 | Should -Be "Value1"
            
            $cachedItem2 = Get-CacheItem -Key "Key2"
            $cachedItem2 | Should -BeNullOrEmpty
            
            $cachedItem3 = Get-CacheItem -Key "Key3"
            $cachedItem3 | Should -Be "Value3"
            
            $cachedItem4 = Get-CacheItem -Key "Key4"
            $cachedItem4 | Should -Be "Value4"
        }
        
        It "Applique correctement la politique d'Ã©viction LFU" {
            # Initialiser le cache avec une taille limitÃ©e
            Initialize-CacheManager -Force -Enabled $true -MaxItems 3 -DefaultTTL 60 -EvictionPolicy "LFU"
            
            # Ajouter des Ã©lÃ©ments au cache
            Set-CacheItem -Key "Key1" -Value "Value1"
            Set-CacheItem -Key "Key2" -Value "Value2"
            Set-CacheItem -Key "Key3" -Value "Value3"
            
            # AccÃ©der Ã  Key1 et Key3 plusieurs fois pour augmenter leur frÃ©quence d'utilisation
            Get-CacheItem -Key "Key1"
            Get-CacheItem -Key "Key1"
            Get-CacheItem -Key "Key3"
            
            # Ajouter un nouvel Ã©lÃ©ment pour dÃ©clencher l'Ã©viction
            Set-CacheItem -Key "Key4" -Value "Value4"
            
            # VÃ©rifier que Key2 a Ã©tÃ© Ã©vincÃ© (le moins frÃ©quemment utilisÃ©)
            $cachedItem1 = Get-CacheItem -Key "Key1"
            $cachedItem1 | Should -Be "Value1"
            
            $cachedItem2 = Get-CacheItem -Key "Key2"
            $cachedItem2 | Should -BeNullOrEmpty
            
            $cachedItem3 = Get-CacheItem -Key "Key3"
            $cachedItem3 | Should -Be "Value3"
            
            $cachedItem4 = Get-CacheItem -Key "Key4"
            $cachedItem4 | Should -Be "Value4"
        }
        
        It "Applique correctement la politique d'Ã©viction FIFO" {
            # Initialiser le cache avec une taille limitÃ©e
            Initialize-CacheManager -Force -Enabled $true -MaxItems 3 -DefaultTTL 60 -EvictionPolicy "FIFO"
            
            # Ajouter des Ã©lÃ©ments au cache
            Set-CacheItem -Key "Key1" -Value "Value1"
            Start-Sleep -Milliseconds 100
            Set-CacheItem -Key "Key2" -Value "Value2"
            Start-Sleep -Milliseconds 100
            Set-CacheItem -Key "Key3" -Value "Value3"
            
            # Ajouter un nouvel Ã©lÃ©ment pour dÃ©clencher l'Ã©viction
            Set-CacheItem -Key "Key4" -Value "Value4"
            
            # VÃ©rifier que Key1 a Ã©tÃ© Ã©vincÃ© (le premier entrÃ©)
            $cachedItem1 = Get-CacheItem -Key "Key1"
            $cachedItem1 | Should -BeNullOrEmpty
            
            $cachedItem2 = Get-CacheItem -Key "Key2"
            $cachedItem2 | Should -Be "Value2"
            
            $cachedItem3 = Get-CacheItem -Key "Key3"
            $cachedItem3 | Should -Be "Value3"
            
            $cachedItem4 = Get-CacheItem -Key "Key4"
            $cachedItem4 | Should -Be "Value4"
        }
    }
    
    Context "Tests de performance" {
        BeforeEach {
            # RÃ©initialiser le cache avant chaque test
            Initialize-CacheManager -Force -Enabled $true -MaxItems 1000 -DefaultTTL 60 -EvictionPolicy "LRU"
        }
        
        It "AmÃ©liore les performances des opÃ©rations rÃ©pÃ©titives" {
            # DÃ©finir une fonction coÃ»teuse
            $expensiveFunction = {
                param($id)
                
                # Simuler une opÃ©ration coÃ»teuse
                Start-Sleep -Milliseconds 100
                
                return "RÃ©sultat pour $id"
            }
            
            # Mesurer le temps sans cache
            $startTime = Get-Date
            $result1 = & $expensiveFunction 123
            $result2 = & $expensiveFunction 123
            $endTime = Get-Date
            $durationWithoutCache = ($endTime - $startTime).TotalMilliseconds
            
            # Mesurer le temps avec cache
            $startTime = Get-Date
            $cachedResult1 = Invoke-CachedFunction -ScriptBlock $expensiveFunction -CacheKey "ExpensiveFunction_123" -Arguments @(123)
            $cachedResult2 = Invoke-CachedFunction -ScriptBlock $expensiveFunction -CacheKey "ExpensiveFunction_123" -Arguments @(123)
            $endTime = Get-Date
            $durationWithCache = ($endTime - $startTime).TotalMilliseconds
            
            # VÃ©rifier que les rÃ©sultats sont corrects
            $result1 | Should -Be $cachedResult1
            $result2 | Should -Be $cachedResult2
            
            # VÃ©rifier que le cache amÃ©liore les performances
            $durationWithCache | Should -BeLessThan $durationWithoutCache
            
            # VÃ©rifier les statistiques
            $stats = Get-CacheStatistics
            $stats.Hits | Should -Be 1
            $stats.Misses | Should -Be 1
        }
    }
    
    AfterAll {
        # Nettoyer le cache
        Clear-Cache
    }
}
