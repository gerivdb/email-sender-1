<#
.SYNOPSIS
    Tests unitaires pour le module PSCacheManager.
.DESCRIPTION
    Ce script contient des tests unitaires complets pour le module PSCacheManager,
    couvrant toutes les fonctionnalitÃ©s principales et les cas d'utilisation.
.NOTES
    Auteur: SystÃ¨me de test automatisÃ©
    Date de crÃ©ation: 09/04/2025
    Version: 1.0
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation..."
    try {
        Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
    } catch {
        Write-Error "Impossible d'installer Pester. Les tests ne peuvent pas Ãªtre exÃ©cutÃ©s."
        exit 1
    }
}

# Importer le module PSCacheManager
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\PSCacheManager.psm1"
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module PSCacheManager introuvable Ã  l'emplacement: $modulePath"
    exit 1
}

Import-Module $modulePath -Force

# CrÃ©er un dossier temporaire pour les tests
$testCachePath = Join-Path -Path $env:TEMP -ChildPath "PSCacheManagerTests"
if (-not (Test-Path -Path $testCachePath)) {
    New-Item -Path $testCachePath -ItemType Directory -Force | Out-Null
}

Describe "PSCacheManager - Tests fonctionnels" {
    BeforeAll {
        # CrÃ©er une instance de cache pour les tests
        $script:testCache = New-PSCache -Name "TestCache" -CachePath $testCachePath -MaxMemoryItems 100 -DefaultTTLSeconds 60
    }
    
    AfterAll {
        # Nettoyer le dossier de cache aprÃ¨s les tests
        if (Test-Path -Path $testCachePath) {
            Remove-Item -Path $testCachePath -Recurse -Force
        }
    }
    
    Context "CrÃ©ation et configuration du cache" {
        It "CrÃ©e une nouvelle instance de cache avec les paramÃ¨tres par dÃ©faut" {
            $cache = New-PSCache -Name "DefaultCache"
            $cache | Should -Not -BeNullOrEmpty
            $stats = Get-PSCacheStatistics -Cache $cache
            $stats.Name | Should -Be "DefaultCache"
        }
        
        It "CrÃ©e une instance de cache avec des paramÃ¨tres personnalisÃ©s" {
            $cache = New-PSCache -Name "CustomCache" -MaxMemoryItems 50 -DefaultTTLSeconds 120 -EnableDiskCache $false
            $cache | Should -Not -BeNullOrEmpty
            $stats = Get-PSCacheStatistics -Cache $cache
            $stats.Name | Should -Be "CustomCache"
            $stats.DiskCacheEnabled | Should -Be $false
        }
    }
    
    Context "OpÃ©rations CRUD de base" {
        It "Ajoute un Ã©lÃ©ment au cache" {
            Set-PSCacheItem -Cache $script:testCache -Key "test1" -Value "TestValue"
            $result = Get-PSCacheItem -Cache $script:testCache -Key "test1"
            $result | Should -Be "TestValue"
        }
        
        It "Met Ã  jour un Ã©lÃ©ment existant" {
            Set-PSCacheItem -Cache $script:testCache -Key "test1" -Value "UpdatedValue"
            $result = Get-PSCacheItem -Cache $script:testCache -Key "test1"
            $result | Should -Be "UpdatedValue"
        }
        
        It "Supprime un Ã©lÃ©ment du cache" {
            Set-PSCacheItem -Cache $script:testCache -Key "test2" -Value "ValueToRemove"
            Remove-PSCacheItem -Cache $script:testCache -Key "test2"
            $result = Get-PSCacheItem -Cache $script:testCache -Key "test2"
            $result | Should -BeNullOrEmpty
        }
        
        It "VÃ©rifie l'existence d'une clÃ© dans le cache" {
            Set-PSCacheItem -Cache $script:testCache -Key "test3" -Value "TestValue"
            $exists = Test-PSCacheItem -Cache $script:testCache -Key "test3"
            $exists | Should -Be $true
            
            $notExists = Test-PSCacheItem -Cache $script:testCache -Key "nonexistent"
            $notExists | Should -Be $false
        }
    }
    
    Context "Gestion des expirations" {
        It "Respecte le TTL par dÃ©faut" {
            $cache = New-PSCache -Name "TTLCache" -DefaultTTLSeconds 1
            Set-PSCacheItem -Cache $cache -Key "expiring" -Value "ExpiringValue"
            $result1 = Get-PSCacheItem -Cache $cache -Key "expiring"
            $result1 | Should -Be "ExpiringValue"
            
            # Attendre l'expiration
            Start-Sleep -Seconds 2
            
            $result2 = Get-PSCacheItem -Cache $cache -Key "expiring"
            $result2 | Should -BeNullOrEmpty
        }
        
        It "Respecte le TTL spÃ©cifique Ã  l'Ã©lÃ©ment" {
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
        It "Ajoute des Ã©lÃ©ments avec des tags" {
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
        
        It "Supprime des Ã©lÃ©ments par tag" {
            Remove-PSCacheItem -Cache $script:testCache -Tag "Group1"
            
            $result1 = Get-PSCacheItem -Cache $script:testCache -Key "tag1"
            $result2 = Get-PSCacheItem -Cache $script:testCache -Key "tag2"
            $result3 = Get-PSCacheItem -Cache $script:testCache -Key "tag3"
            
            $result1 | Should -BeNullOrEmpty
            $result2 | Should -BeNullOrEmpty
            $result3 | Should -Be "Value3"
        }
    }
    
    Context "GÃ©nÃ©ration automatique de valeurs" {
        It "GÃ©nÃ¨re une valeur si elle n'existe pas dans le cache" {
            $generatedValue = Get-PSCacheItem -Cache $script:testCache -Key "generated" -GenerateValue {
                return "GeneratedValue"
            }
            
            $generatedValue | Should -Be "GeneratedValue"
            
            # VÃ©rifier que la valeur est mise en cache
            $cachedValue = Get-PSCacheItem -Cache $script:testCache -Key "generated"
            $cachedValue | Should -Be "GeneratedValue"
        }
        
        It "Utilise la valeur en cache si elle existe" {
            # Ajouter une valeur au cache
            Set-PSCacheItem -Cache $script:testCache -Key "existing" -Value "ExistingValue"
            
            # Tenter de gÃ©nÃ©rer une nouvelle valeur
            $result = Get-PSCacheItem -Cache $script:testCache -Key "existing" -GenerateValue {
                return "NewValue"
            }
            
            # La valeur existante doit Ãªtre utilisÃ©e
            $result | Should -Be "ExistingValue"
        }
    }
    
    Context "Nettoyage et statistiques" {
        It "Nettoie les Ã©lÃ©ments expirÃ©s" {
            # Ajouter des Ã©lÃ©ments avec un TTL court
            Set-PSCacheItem -Cache $script:testCache -Key "expire1" -Value "Value1" -TTLSeconds 1
            Set-PSCacheItem -Cache $script:testCache -Key "expire2" -Value "Value2" -TTLSeconds 1
            
            # Attendre l'expiration
            Start-Sleep -Seconds 2
            
            # Nettoyer les Ã©lÃ©ments expirÃ©s
            Clear-PSCache -Cache $script:testCache -ExpiredOnly
            
            # VÃ©rifier que les Ã©lÃ©ments sont supprimÃ©s
            $result1 = Get-PSCacheItem -Cache $script:testCache -Key "expire1"
            $result2 = Get-PSCacheItem -Cache $script:testCache -Key "expire2"
            
            $result1 | Should -BeNullOrEmpty
            $result2 | Should -BeNullOrEmpty
        }
        
        It "Nettoie tous les Ã©lÃ©ments" {
            # Ajouter des Ã©lÃ©ments
            Set-PSCacheItem -Cache $script:testCache -Key "clear1" -Value "Value1"
            Set-PSCacheItem -Cache $script:testCache -Key "clear2" -Value "Value2"
            
            # Nettoyer tous les Ã©lÃ©ments
            Clear-PSCache -Cache $script:testCache
            
            # VÃ©rifier que les Ã©lÃ©ments sont supprimÃ©s
            $result1 = Get-PSCacheItem -Cache $script:testCache -Key "clear1"
            $result2 = Get-PSCacheItem -Cache $script:testCache -Key "clear2"
            
            $result1 | Should -BeNullOrEmpty
            $result2 | Should -BeNullOrEmpty
        }
        
        It "Fournit des statistiques prÃ©cises" {
            # Ajouter des Ã©lÃ©ments
            Set-PSCacheItem -Cache $script:testCache -Key "stat1" -Value "Value1"
            Set-PSCacheItem -Cache $script:testCache -Key "stat2" -Value "Value2"
            
            # AccÃ©der Ã  un Ã©lÃ©ment pour incrÃ©menter les hits
            $null = Get-PSCacheItem -Cache $script:testCache -Key "stat1"
            $null = Get-PSCacheItem -Cache $script:testCache -Key "stat1"
            
            # AccÃ©der Ã  un Ã©lÃ©ment inexistant pour incrÃ©menter les misses
            $null = Get-PSCacheItem -Cache $script:testCache -Key "nonexistent"
            
            # Obtenir les statistiques
            $stats = Get-PSCacheStatistics -Cache $script:testCache
            
            $stats.MemoryItemCount | Should -BeGreaterOrEqual 2
            $stats.Hits | Should -BeGreaterOrEqual 2
            $stats.Misses | Should -BeGreaterOrEqual 1
        }
    }
    
    Context "Types de donnÃ©es complexes" {
        It "GÃ¨re les objets PowerShell complexes" {
            # CrÃ©er un objet complexe
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
            
            # RÃ©cupÃ©rer l'objet
            $result = Get-PSCacheItem -Cache $script:testCache -Key "complex"
            
            # VÃ©rifier que l'objet est correctement rÃ©cupÃ©rÃ©
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be "TestObject"
            $result.Properties.Property1 | Should -Be "Value1"
            $result.Properties.Property2 | Should -Be 123
            $result.Properties.Property3 | Should -Be $true
            $result.Items.Count | Should -Be 3
            $result.Items[0] | Should -Be "Item1"
            $result.NestedObject.NestedProperty | Should -Be "NestedValue"
        }
        
        It "GÃ¨re les valeurs null" {
            # Mettre une valeur null en cache
            Set-PSCacheItem -Cache $script:testCache -Key "nullValue" -Value $null
            
            # RÃ©cupÃ©rer la valeur
            $result = Get-PSCacheItem -Cache $script:testCache -Key "nullValue"
            
            # VÃ©rifier que la valeur est correctement rÃ©cupÃ©rÃ©e
            $result | Should -BeNullOrEmpty
            
            # VÃ©rifier que la clÃ© existe malgrÃ© la valeur null
            $exists = Test-PSCacheItem -Cache $script:testCache -Key "nullValue"
            $exists | Should -Be $true
        }
    }
}

Describe "PSCacheManager - Tests de performance" {
    BeforeAll {
        # CrÃ©er une instance de cache pour les tests
        $script:perfCache = New-PSCache -Name "PerfCache" -CachePath $testCachePath -MaxMemoryItems 1000 -DefaultTTLSeconds 3600
    }
    
    AfterAll {
        # Nettoyer le dossier de cache aprÃ¨s les tests
        if (Test-Path -Path $testCachePath) {
            Remove-Item -Path $testCachePath -Recurse -Force
        }
    }
    
    It "DÃ©montre l'amÃ©lioration des performances avec le cache" {
        # Fonction coÃ»teuse simulÃ©e
        function Get-ExpensiveData {
            param (
                [int]$Id
            )
            
            # Simuler une opÃ©ration coÃ»teuse
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
        
        # VÃ©rifier les rÃ©sultats
        $data1 | Should -Be $data2
        $data1Again | Should -Be $data2Again
        
        # VÃ©rifier l'amÃ©lioration des performances
        $timeWithCache | Should -BeLessThan $timeWithoutCache
        
        # Afficher les temps pour information
        Write-Host "Temps sans cache: $timeWithoutCache ms"
        Write-Host "Temps avec cache: $timeWithCache ms"
        Write-Host "AmÃ©lioration: $([Math]::Round(($timeWithoutCache - $timeWithCache) / $timeWithoutCache * 100, 2))%"
    }
    
    It "GÃ¨re efficacement un grand nombre d'Ã©lÃ©ments" {
        # Ajouter 500 Ã©lÃ©ments au cache
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        
        for ($i = 1; $i -le 500; $i++) {
            Set-PSCacheItem -Cache $script:perfCache -Key "Item_$i" -Value "Value for item $i"
        }
        
        $sw.Stop()
        $timeToAdd = $sw.ElapsedMilliseconds
        
        # RÃ©cupÃ©rer 500 Ã©lÃ©ments du cache
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        
        for ($i = 1; $i -le 500; $i++) {
            $value = Get-PSCacheItem -Cache $script:perfCache -Key "Item_$i"
            $value | Should -Be "Value for item $i"
        }
        
        $sw.Stop()
        $timeToRetrieve = $sw.ElapsedMilliseconds
        
        # VÃ©rifier les performances
        $timeToAdd | Should -BeLessThan 5000  # Moins de 5 secondes pour ajouter 500 Ã©lÃ©ments
        $timeToRetrieve | Should -BeLessThan 1000  # Moins de 1 seconde pour rÃ©cupÃ©rer 500 Ã©lÃ©ments
        
        # Afficher les temps pour information
        Write-Host "Temps pour ajouter 500 Ã©lÃ©ments: $timeToAdd ms"
        Write-Host "Temps pour rÃ©cupÃ©rer 500 Ã©lÃ©ments: $timeToRetrieve ms"
        Write-Host "Temps moyen par Ã©lÃ©ment: $([Math]::Round($timeToRetrieve / 500, 2)) ms"
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Output Detailed
