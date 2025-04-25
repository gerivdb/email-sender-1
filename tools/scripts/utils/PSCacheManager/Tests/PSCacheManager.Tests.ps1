<#
.SYNOPSIS
    Tests unitaires pour le module PSCacheManager.
.DESCRIPTION
    Ce script contient des tests unitaires complets pour le module PSCacheManager,
    couvrant toutes les fonctionnalités principales et les cas d'utilisation.
.NOTES
    Auteur: Système de test automatisé
    Date de création: 09/04/2025
    Version: 1.0
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation..."
    try {
        Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
    } catch {
        Write-Error "Impossible d'installer Pester. Les tests ne peuvent pas être exécutés."
        exit 1
    }
}

# Importer le module PSCacheManager
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\PSCacheManager.psm1"
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module PSCacheManager introuvable à l'emplacement: $modulePath"
    exit 1
}

Import-Module $modulePath -Force

# Créer un dossier temporaire pour les tests
$testCachePath = Join-Path -Path $env:TEMP -ChildPath "PSCacheManagerTests"
if (-not (Test-Path -Path $testCachePath)) {
    New-Item -Path $testCachePath -ItemType Directory -Force | Out-Null
}

Describe "PSCacheManager - Tests fonctionnels" {
    BeforeAll {
        # Créer une instance de cache pour les tests
        $script:testCache = New-PSCache -Name "TestCache" -CachePath $testCachePath -MaxMemoryItems 100 -DefaultTTLSeconds 60
    }
    
    AfterAll {
        # Nettoyer le dossier de cache après les tests
        if (Test-Path -Path $testCachePath) {
            Remove-Item -Path $testCachePath -Recurse -Force
        }
    }
    
    Context "Création et configuration du cache" {
        It "Crée une nouvelle instance de cache avec les paramètres par défaut" {
            $cache = New-PSCache -Name "DefaultCache"
            $cache | Should -Not -BeNullOrEmpty
            $stats = Get-PSCacheStatistics -Cache $cache
            $stats.Name | Should -Be "DefaultCache"
        }
        
        It "Crée une instance de cache avec des paramètres personnalisés" {
            $cache = New-PSCache -Name "CustomCache" -MaxMemoryItems 50 -DefaultTTLSeconds 120 -EnableDiskCache $false
            $cache | Should -Not -BeNullOrEmpty
            $stats = Get-PSCacheStatistics -Cache $cache
            $stats.Name | Should -Be "CustomCache"
            $stats.DiskCacheEnabled | Should -Be $false
        }
    }
    
    Context "Opérations CRUD de base" {
        It "Ajoute un élément au cache" {
            Set-PSCacheItem -Cache $script:testCache -Key "test1" -Value "TestValue"
            $result = Get-PSCacheItem -Cache $script:testCache -Key "test1"
            $result | Should -Be "TestValue"
        }
        
        It "Met à jour un élément existant" {
            Set-PSCacheItem -Cache $script:testCache -Key "test1" -Value "UpdatedValue"
            $result = Get-PSCacheItem -Cache $script:testCache -Key "test1"
            $result | Should -Be "UpdatedValue"
        }
        
        It "Supprime un élément du cache" {
            Set-PSCacheItem -Cache $script:testCache -Key "test2" -Value "ValueToRemove"
            Remove-PSCacheItem -Cache $script:testCache -Key "test2"
            $result = Get-PSCacheItem -Cache $script:testCache -Key "test2"
            $result | Should -BeNullOrEmpty
        }
        
        It "Vérifie l'existence d'une clé dans le cache" {
            Set-PSCacheItem -Cache $script:testCache -Key "test3" -Value "TestValue"
            $exists = Test-PSCacheItem -Cache $script:testCache -Key "test3"
            $exists | Should -Be $true
            
            $notExists = Test-PSCacheItem -Cache $script:testCache -Key "nonexistent"
            $notExists | Should -Be $false
        }
    }
    
    Context "Gestion des expirations" {
        It "Respecte le TTL par défaut" {
            $cache = New-PSCache -Name "TTLCache" -DefaultTTLSeconds 1
            Set-PSCacheItem -Cache $cache -Key "expiring" -Value "ExpiringValue"
            $result1 = Get-PSCacheItem -Cache $cache -Key "expiring"
            $result1 | Should -Be "ExpiringValue"
            
            # Attendre l'expiration
            Start-Sleep -Seconds 2
            
            $result2 = Get-PSCacheItem -Cache $cache -Key "expiring"
            $result2 | Should -BeNullOrEmpty
        }
        
        It "Respecte le TTL spécifique à l'élément" {
            Set-PSCacheItem -Cache $script:testCache -Key "customTTL" -Value "CustomTTLValue" -TTLSeconds 1
            $result1 = Get-PSCacheItem -Cache $script:testCache -Key "customTTL"
            $result1 | Should -Be "CustomTTLValue"
            
            # Attendre l'expiration
            Start-Sleep -Seconds 2
            
            $result2 = Get-PSCacheItem -Cache $script:testCache -Key "customTTL"
            $result2 | Should -BeNullOrEmpty
        }
    }
    
    Context "Gestion des tags" {
        It "Ajoute des éléments avec des tags" {
            Set-PSCacheItem -Cache $script:testCache -Key "tag1" -Value "Value1" -Tags "Group1", "Test"
            Set-PSCacheItem -Cache $script:testCache -Key "tag2" -Value "Value2" -Tags "Group1"
            Set-PSCacheItem -Cache $script:testCache -Key "tag3" -Value "Value3" -Tags "Group2"
            
            $result1 = Get-PSCacheItem -Cache $script:testCache -Key "tag1"
            $result2 = Get-PSCacheItem -Cache $script:testCache -Key "tag2"
            $result3 = Get-PSCacheItem -Cache $script:testCache -Key "tag3"
            
            $result1 | Should -Be "Value1"
            $result2 | Should -Be "Value2"
            $result3 | Should -Be "Value3"
        }
        
        It "Supprime des éléments par tag" {
            Remove-PSCacheItem -Cache $script:testCache -Tag "Group1"
            
            $result1 = Get-PSCacheItem -Cache $script:testCache -Key "tag1"
            $result2 = Get-PSCacheItem -Cache $script:testCache -Key "tag2"
            $result3 = Get-PSCacheItem -Cache $script:testCache -Key "tag3"
            
            $result1 | Should -BeNullOrEmpty
            $result2 | Should -BeNullOrEmpty
            $result3 | Should -Be "Value3"
        }
    }
    
    Context "Génération automatique de valeurs" {
        It "Génère une valeur si elle n'existe pas dans le cache" {
            $generatedValue = Get-PSCacheItem -Cache $script:testCache -Key "generated" -GenerateValue {
                return "GeneratedValue"
            }
            
            $generatedValue | Should -Be "GeneratedValue"
            
            # Vérifier que la valeur est mise en cache
            $cachedValue = Get-PSCacheItem -Cache $script:testCache -Key "generated"
            $cachedValue | Should -Be "GeneratedValue"
        }
        
        It "Utilise la valeur en cache si elle existe" {
            # Ajouter une valeur au cache
            Set-PSCacheItem -Cache $script:testCache -Key "existing" -Value "ExistingValue"
            
            # Tenter de générer une nouvelle valeur
            $result = Get-PSCacheItem -Cache $script:testCache -Key "existing" -GenerateValue {
                return "NewValue"
            }
            
            # La valeur existante doit être utilisée
            $result | Should -Be "ExistingValue"
        }
    }
    
    Context "Nettoyage et statistiques" {
        It "Nettoie les éléments expirés" {
            # Ajouter des éléments avec un TTL court
            Set-PSCacheItem -Cache $script:testCache -Key "expire1" -Value "Value1" -TTLSeconds 1
            Set-PSCacheItem -Cache $script:testCache -Key "expire2" -Value "Value2" -TTLSeconds 1
            
            # Attendre l'expiration
            Start-Sleep -Seconds 2
            
            # Nettoyer les éléments expirés
            Clear-PSCache -Cache $script:testCache -ExpiredOnly
            
            # Vérifier que les éléments sont supprimés
            $result1 = Get-PSCacheItem -Cache $script:testCache -Key "expire1"
            $result2 = Get-PSCacheItem -Cache $script:testCache -Key "expire2"
            
            $result1 | Should -BeNullOrEmpty
            $result2 | Should -BeNullOrEmpty
        }
        
        It "Nettoie tous les éléments" {
            # Ajouter des éléments
            Set-PSCacheItem -Cache $script:testCache -Key "clear1" -Value "Value1"
            Set-PSCacheItem -Cache $script:testCache -Key "clear2" -Value "Value2"
            
            # Nettoyer tous les éléments
            Clear-PSCache -Cache $script:testCache
            
            # Vérifier que les éléments sont supprimés
            $result1 = Get-PSCacheItem -Cache $script:testCache -Key "clear1"
            $result2 = Get-PSCacheItem -Cache $script:testCache -Key "clear2"
            
            $result1 | Should -BeNullOrEmpty
            $result2 | Should -BeNullOrEmpty
        }
        
        It "Fournit des statistiques précises" {
            # Ajouter des éléments
            Set-PSCacheItem -Cache $script:testCache -Key "stat1" -Value "Value1"
            Set-PSCacheItem -Cache $script:testCache -Key "stat2" -Value "Value2"
            
            # Accéder à un élément pour incrémenter les hits
            $null = Get-PSCacheItem -Cache $script:testCache -Key "stat1"
            $null = Get-PSCacheItem -Cache $script:testCache -Key "stat1"
            
            # Accéder à un élément inexistant pour incrémenter les misses
            $null = Get-PSCacheItem -Cache $script:testCache -Key "nonexistent"
            
            # Obtenir les statistiques
            $stats = Get-PSCacheStatistics -Cache $script:testCache
            
            $stats.MemoryItemCount | Should -BeGreaterOrEqual 2
            $stats.Hits | Should -BeGreaterOrEqual 2
            $stats.Misses | Should -BeGreaterOrEqual 1
        }
    }
    
    Context "Types de données complexes" {
        It "Gère les objets PowerShell complexes" {
            # Créer un objet complexe
            $complexObject = [PSCustomObject]@{
                Name = "TestObject"
                Properties = @{
                    Property1 = "Value1"
                    Property2 = 123
                    Property3 = $true
                }
                Items = @(
                    "Item1",
                    "Item2",
                    "Item3"
                )
                NestedObject = [PSCustomObject]@{
                    NestedProperty = "NestedValue"
                }
            }
            
            # Mettre l'objet en cache
            Set-PSCacheItem -Cache $script:testCache -Key "complex" -Value $complexObject
            
            # Récupérer l'objet
            $result = Get-PSCacheItem -Cache $script:testCache -Key "complex"
            
            # Vérifier que l'objet est correctement récupéré
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be "TestObject"
            $result.Properties.Property1 | Should -Be "Value1"
            $result.Properties.Property2 | Should -Be 123
            $result.Properties.Property3 | Should -Be $true
            $result.Items.Count | Should -Be 3
            $result.Items[0] | Should -Be "Item1"
            $result.NestedObject.NestedProperty | Should -Be "NestedValue"
        }
        
        It "Gère les valeurs null" {
            # Mettre une valeur null en cache
            Set-PSCacheItem -Cache $script:testCache -Key "nullValue" -Value $null
            
            # Récupérer la valeur
            $result = Get-PSCacheItem -Cache $script:testCache -Key "nullValue"
            
            # Vérifier que la valeur est correctement récupérée
            $result | Should -BeNullOrEmpty
            
            # Vérifier que la clé existe malgré la valeur null
            $exists = Test-PSCacheItem -Cache $script:testCache -Key "nullValue"
            $exists | Should -Be $true
        }
    }
}

Describe "PSCacheManager - Tests de performance" {
    BeforeAll {
        # Créer une instance de cache pour les tests
        $script:perfCache = New-PSCache -Name "PerfCache" -CachePath $testCachePath -MaxMemoryItems 1000 -DefaultTTLSeconds 3600
    }
    
    AfterAll {
        # Nettoyer le dossier de cache après les tests
        if (Test-Path -Path $testCachePath) {
            Remove-Item -Path $testCachePath -Recurse -Force
        }
    }
    
    It "Démontre l'amélioration des performances avec le cache" {
        # Fonction coûteuse simulée
        function Get-ExpensiveData {
            param (
                [int]$Id
            )
            
            # Simuler une opération coûteuse
            Start-Sleep -Milliseconds 500
            
            return "Data for ID $Id"
        }
        
        # Mesurer le temps sans cache
        $sw1 = [System.Diagnostics.Stopwatch]::StartNew()
        $data1 = Get-ExpensiveData -Id 1
        $data1Again = Get-ExpensiveData -Id 1
        $sw1.Stop()
        $timeWithoutCache = $sw1.ElapsedMilliseconds
        
        # Mesurer le temps avec cache
        $sw2 = [System.Diagnostics.Stopwatch]::StartNew()
        $data2 = Get-PSCacheItem -Cache $script:perfCache -Key "ExpensiveData_1" -GenerateValue {
            Get-ExpensiveData -Id 1
        }
        $data2Again = Get-PSCacheItem -Cache $script:perfCache -Key "ExpensiveData_1" -GenerateValue {
            Get-ExpensiveData -Id 1
        }
        $sw2.Stop()
        $timeWithCache = $sw2.ElapsedMilliseconds
        
        # Vérifier les résultats
        $data1 | Should -Be $data2
        $data1Again | Should -Be $data2Again
        
        # Vérifier l'amélioration des performances
        $timeWithCache | Should -BeLessThan $timeWithoutCache
        
        # Afficher les temps pour information
        Write-Host "Temps sans cache: $timeWithoutCache ms"
        Write-Host "Temps avec cache: $timeWithCache ms"
        Write-Host "Amélioration: $([Math]::Round(($timeWithoutCache - $timeWithCache) / $timeWithoutCache * 100, 2))%"
    }
    
    It "Gère efficacement un grand nombre d'éléments" {
        # Ajouter 500 éléments au cache
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        
        for ($i = 1; $i -le 500; $i++) {
            Set-PSCacheItem -Cache $script:perfCache -Key "Item_$i" -Value "Value for item $i"
        }
        
        $sw.Stop()
        $timeToAdd = $sw.ElapsedMilliseconds
        
        # Récupérer 500 éléments du cache
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        
        for ($i = 1; $i -le 500; $i++) {
            $value = Get-PSCacheItem -Cache $script:perfCache -Key "Item_$i"
            $value | Should -Be "Value for item $i"
        }
        
        $sw.Stop()
        $timeToRetrieve = $sw.ElapsedMilliseconds
        
        # Vérifier les performances
        $timeToAdd | Should -BeLessThan 5000  # Moins de 5 secondes pour ajouter 500 éléments
        $timeToRetrieve | Should -BeLessThan 1000  # Moins de 1 seconde pour récupérer 500 éléments
        
        # Afficher les temps pour information
        Write-Host "Temps pour ajouter 500 éléments: $timeToAdd ms"
        Write-Host "Temps pour récupérer 500 éléments: $timeToRetrieve ms"
        Write-Host "Temps moyen par élément: $([Math]::Round($timeToRetrieve / 500, 2)) ms"
    }
}

# Exécuter les tests
Invoke-Pester -Output Detailed
