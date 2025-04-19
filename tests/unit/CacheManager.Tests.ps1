#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module CacheManager.ps1.
.DESCRIPTION
    Ce script contient des tests unitaires pour le module CacheManager.ps1.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-06-06
#>

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Chemins des modules à tester
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$modulesPath = Join-Path -Path $projectRoot -ChildPath "modules"
$cacheManagerPath = Join-Path -Path $modulesPath -ChildPath "CacheManager.ps1"

# Définir les tests
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
        
        It "Réinitialise le cache lors de l'initialisation" {
            # Ajouter un élément au cache
            Set-CacheItem -Key "TestKey" -Value "TestValue"
            
            # Réinitialiser le cache
            Initialize-CacheManager -Force
            
            # Vérifier que l'élément a été supprimé
            $cachedItem = Get-CacheItem -Key "TestKey"
            $cachedItem | Should -BeNullOrEmpty
        }
    }
    
    Context "Tests des fonctions Get-CacheItem et Set-CacheItem" {
        BeforeEach {
            # Réinitialiser le cache avant chaque test
            Initialize-CacheManager -Force -Enabled $true -MaxItems 10 -DefaultTTL 60 -EvictionPolicy "LRU"
        }
        
        It "Ajoute et récupère correctement un élément du cache" {
            # Ajouter un élément au cache
            Set-CacheItem -Key "TestKey" -Value "TestValue"
            
            # Récupérer l'élément du cache
            $cachedItem = Get-CacheItem -Key "TestKey"
            
            # Vérifier que l'élément est correct
            $cachedItem | Should -Be "TestValue"
        }
        
        It "Retourne null pour un élément non présent dans le cache" {
            $cachedItem = Get-CacheItem -Key "NonExistentKey"
            $cachedItem | Should -BeNullOrEmpty
        }
        
        It "Met à jour correctement un élément existant dans le cache" {
            # Ajouter un élément au cache
            Set-CacheItem -Key "TestKey" -Value "TestValue"
            
            # Mettre à jour l'élément
            Set-CacheItem -Key "TestKey" -Value "UpdatedValue"
            
            # Récupérer l'élément mis à jour
            $cachedItem = Get-CacheItem -Key "TestKey"
            
            # Vérifier que l'élément a été mis à jour
            $cachedItem | Should -Be "UpdatedValue"
        }
        
        It "Respecte la durée de vie (TTL) des éléments" {
            # Ajouter un élément au cache avec un TTL court
            Set-CacheItem -Key "ExpiringKey" -Value "ExpiringValue" -TTL 1
            
            # Vérifier que l'élément est présent
            $cachedItem = Get-CacheItem -Key "ExpiringKey"
            $cachedItem | Should -Be "ExpiringValue"
            
            # Attendre l'expiration
            Start-Sleep -Seconds 2
            
            # Vérifier que l'élément a expiré
            $expiredItem = Get-CacheItem -Key "ExpiringKey"
            $expiredItem | Should -BeNullOrEmpty
        }
    }
    
    Context "Tests de la fonction Remove-CacheItem" {
        BeforeEach {
            # Réinitialiser le cache avant chaque test
            Initialize-CacheManager -Force -Enabled $true -MaxItems 10 -DefaultTTL 60 -EvictionPolicy "LRU"
            
            # Ajouter des éléments au cache
            Set-CacheItem -Key "Key1" -Value "Value1"
            Set-CacheItem -Key "Key2" -Value "Value2"
        }
        
        It "Supprime correctement un élément du cache" {
            # Supprimer un élément
            $result = Remove-CacheItem -Key "Key1"
            
            # Vérifier que la suppression a réussi
            $result | Should -Be $true
            
            # Vérifier que l'élément a été supprimé
            $cachedItem = Get-CacheItem -Key "Key1"
            $cachedItem | Should -BeNullOrEmpty
            
            # Vérifier que les autres éléments sont toujours présents
            $otherItem = Get-CacheItem -Key "Key2"
            $otherItem | Should -Be "Value2"
        }
        
        It "Retourne false pour un élément non présent dans le cache" {
            $result = Remove-CacheItem -Key "NonExistentKey"
            $result | Should -Be $false
        }
    }
    
    Context "Tests de la fonction Clear-Cache" {
        BeforeEach {
            # Réinitialiser le cache avant chaque test
            Initialize-CacheManager -Force -Enabled $true -MaxItems 10 -DefaultTTL 60 -EvictionPolicy "LRU"
            
            # Ajouter des éléments au cache
            Set-CacheItem -Key "Key1" -Value "Value1"
            Set-CacheItem -Key "Key2" -Value "Value2"
        }
        
        It "Vide correctement le cache" {
            # Vider le cache
            $result = Clear-Cache
            
            # Vérifier que le vidage a réussi
            $result | Should -Be $true
            
            # Vérifier que les éléments ont été supprimés
            $cachedItem1 = Get-CacheItem -Key "Key1"
            $cachedItem1 | Should -BeNullOrEmpty
            
            $cachedItem2 = Get-CacheItem -Key "Key2"
            $cachedItem2 | Should -BeNullOrEmpty
        }
    }
    
    Context "Tests de la fonction Get-CacheStatistics" {
        BeforeEach {
            # Réinitialiser le cache avant chaque test
            Initialize-CacheManager -Force -Enabled $true -MaxItems 10 -DefaultTTL 60 -EvictionPolicy "LRU"
        }
        
        It "Retourne des statistiques correctes" {
            # Ajouter des éléments au cache
            Set-CacheItem -Key "Key1" -Value "Value1"
            Set-CacheItem -Key "Key2" -Value "Value2"
            
            # Récupérer des éléments (hits)
            Get-CacheItem -Key "Key1"
            Get-CacheItem -Key "Key1"
            
            # Récupérer des éléments non existants (misses)
            Get-CacheItem -Key "NonExistentKey1"
            Get-CacheItem -Key "NonExistentKey2"
            
            # Récupérer les statistiques
            $stats = Get-CacheStatistics
            
            # Vérifier les statistiques
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
            # Réinitialiser le cache avant chaque test
            Initialize-CacheManager -Force -Enabled $true -MaxItems 10 -DefaultTTL 60 -EvictionPolicy "LRU"
        }
        
        It "Exécute correctement une fonction et met en cache le résultat" {
            # Définir une fonction de test
            $scriptBlock = {
                param($a, $b)
                return $a + $b
            }
            
            # Exécuter la fonction avec mise en cache
            $result1 = Invoke-CachedFunction -ScriptBlock $scriptBlock -CacheKey "Addition_2_3" -Arguments @(2, 3)
            
            # Vérifier le résultat
            $result1 | Should -Be 5
            
            # Exécuter à nouveau la fonction (devrait utiliser le cache)
            $result2 = Invoke-CachedFunction -ScriptBlock $scriptBlock -CacheKey "Addition_2_3" -Arguments @(2, 3)
            
            # Vérifier le résultat
            $result2 | Should -Be 5
            
            # Vérifier les statistiques
            $stats = Get-CacheStatistics
            $stats.Hits | Should -Be 1
            $stats.Misses | Should -Be 1
        }
        
        It "Exécute directement la fonction si le cache est désactivé" {
            # Désactiver le cache
            Initialize-CacheManager -Force -Enabled $false
            
            # Définir une fonction de test
            $scriptBlock = {
                param($a, $b)
                return $a + $b
            }
            
            # Exécuter la fonction avec mise en cache
            $result = Invoke-CachedFunction -ScriptBlock $scriptBlock -CacheKey "Addition_2_3" -Arguments @(2, 3)
            
            # Vérifier le résultat
            $result | Should -Be 5
            
            # Vérifier les statistiques
            $stats = Get-CacheStatistics
            $stats.Hits | Should -Be 0
            $stats.Misses | Should -Be 0
        }
    }
    
    Context "Tests des politiques d'éviction" {
        It "Applique correctement la politique d'éviction LRU" {
            # Initialiser le cache avec une taille limitée
            Initialize-CacheManager -Force -Enabled $true -MaxItems 3 -DefaultTTL 60 -EvictionPolicy "LRU"
            
            # Ajouter des éléments au cache
            Set-CacheItem -Key "Key1" -Value "Value1"
            Set-CacheItem -Key "Key2" -Value "Value2"
            Set-CacheItem -Key "Key3" -Value "Value3"
            
            # Accéder à Key1 pour le rendre récemment utilisé
            Get-CacheItem -Key "Key1"
            
            # Ajouter un nouvel élément pour déclencher l'éviction
            Set-CacheItem -Key "Key4" -Value "Value4"
            
            # Vérifier que Key2 a été évincé (le moins récemment utilisé)
            $cachedItem1 = Get-CacheItem -Key "Key1"
            $cachedItem1 | Should -Be "Value1"
            
            $cachedItem2 = Get-CacheItem -Key "Key2"
            $cachedItem2 | Should -BeNullOrEmpty
            
            $cachedItem3 = Get-CacheItem -Key "Key3"
            $cachedItem3 | Should -Be "Value3"
            
            $cachedItem4 = Get-CacheItem -Key "Key4"
            $cachedItem4 | Should -Be "Value4"
        }
        
        It "Applique correctement la politique d'éviction LFU" {
            # Initialiser le cache avec une taille limitée
            Initialize-CacheManager -Force -Enabled $true -MaxItems 3 -DefaultTTL 60 -EvictionPolicy "LFU"
            
            # Ajouter des éléments au cache
            Set-CacheItem -Key "Key1" -Value "Value1"
            Set-CacheItem -Key "Key2" -Value "Value2"
            Set-CacheItem -Key "Key3" -Value "Value3"
            
            # Accéder à Key1 et Key3 plusieurs fois pour augmenter leur fréquence d'utilisation
            Get-CacheItem -Key "Key1"
            Get-CacheItem -Key "Key1"
            Get-CacheItem -Key "Key3"
            
            # Ajouter un nouvel élément pour déclencher l'éviction
            Set-CacheItem -Key "Key4" -Value "Value4"
            
            # Vérifier que Key2 a été évincé (le moins fréquemment utilisé)
            $cachedItem1 = Get-CacheItem -Key "Key1"
            $cachedItem1 | Should -Be "Value1"
            
            $cachedItem2 = Get-CacheItem -Key "Key2"
            $cachedItem2 | Should -BeNullOrEmpty
            
            $cachedItem3 = Get-CacheItem -Key "Key3"
            $cachedItem3 | Should -Be "Value3"
            
            $cachedItem4 = Get-CacheItem -Key "Key4"
            $cachedItem4 | Should -Be "Value4"
        }
        
        It "Applique correctement la politique d'éviction FIFO" {
            # Initialiser le cache avec une taille limitée
            Initialize-CacheManager -Force -Enabled $true -MaxItems 3 -DefaultTTL 60 -EvictionPolicy "FIFO"
            
            # Ajouter des éléments au cache
            Set-CacheItem -Key "Key1" -Value "Value1"
            Start-Sleep -Milliseconds 100
            Set-CacheItem -Key "Key2" -Value "Value2"
            Start-Sleep -Milliseconds 100
            Set-CacheItem -Key "Key3" -Value "Value3"
            
            # Ajouter un nouvel élément pour déclencher l'éviction
            Set-CacheItem -Key "Key4" -Value "Value4"
            
            # Vérifier que Key1 a été évincé (le premier entré)
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
            # Réinitialiser le cache avant chaque test
            Initialize-CacheManager -Force -Enabled $true -MaxItems 1000 -DefaultTTL 60 -EvictionPolicy "LRU"
        }
        
        It "Améliore les performances des opérations répétitives" {
            # Définir une fonction coûteuse
            $expensiveFunction = {
                param($id)
                
                # Simuler une opération coûteuse
                Start-Sleep -Milliseconds 100
                
                return "Résultat pour $id"
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
            
            # Vérifier que les résultats sont corrects
            $result1 | Should -Be $cachedResult1
            $result2 | Should -Be $cachedResult2
            
            # Vérifier que le cache améliore les performances
            $durationWithCache | Should -BeLessThan $durationWithoutCache
            
            # Vérifier les statistiques
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
