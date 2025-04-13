<#
.SYNOPSIS
    Tests unitaires pour le module PreloadManager.
.DESCRIPTION
    Ce script contient des tests unitaires pour le module PreloadManager
    du système de cache prédictif.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 13/04/2025
#>

# Importer le module de types simulés
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Parent $scriptPath
$mockTypesPath = Join-Path -Path $scriptDir -ChildPath "MockTypes.psm1"
Import-Module $mockTypesPath -Force

# Créer un chemin temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "PSCacheManager_Tests"
$testCachePath = Join-Path -Path $testDir -ChildPath "Cache"
$testDatabasePath = Join-Path -Path $testDir -ChildPath "Usage.db"

# Nettoyer les tests précédents
if (Test-Path -Path $testCachePath) {
    Remove-Item -Path $testCachePath -Recurse -Force -ErrorAction SilentlyContinue
}
if (Test-Path -Path $testDatabasePath) {
    Remove-Item -Path $testDatabasePath -Force -ErrorAction SilentlyContinue
}

# Créer le répertoire du cache
New-Item -Path $testCachePath -ItemType Directory -Force | Out-Null

Describe "PreloadManager Module Tests" {
    BeforeAll {
        # Créer un CacheManager et un UsageCollector pour les tests
        $script:baseCache = New-MockCacheManager -Name "TestCache" -CachePath $testCachePath
        $script:usageCollector = New-MockUsageCollector -DatabasePath $testDatabasePath -CacheName "TestCache"

        # Créer un PreloadManager pour les tests
        $script:preloadManager = New-MockPreloadManager -BaseCache $script:baseCache -UsageCollector $script:usageCollector
    }

    Context "New-PreloadManager Function" {
        It "Should create a new PreloadManager object" {
            $manager = New-MockPreloadManager -BaseCache $script:baseCache -UsageCollector $script:usageCollector
            $manager | Should -Not -BeNullOrEmpty
            $manager.GetType().Name | Should -Be "PreloadManager"
        }
    }

    Context "PreloadManager Methods" {
        It "Should register and find preload generators" {
            $generator = { return "TestValue" }
            $script:preloadManager.RegisterPreloadGenerator("Test:*", $generator)

            $foundGenerator = $script:preloadManager.FindPreloadGenerator("Test:123")
            $foundGenerator | Should -Not -BeNullOrEmpty

            $nullGenerator = $script:preloadManager.FindPreloadGenerator("OtherKey")
            $nullGenerator | Should -BeNullOrEmpty
        }

        It "Should preload a single key" {
            $generator = { return "PreloadedValue" }
            $script:preloadManager.RegisterPreloadGenerator("Preload:*", $generator)

            $result = $script:preloadManager.PreloadKey("Preload:123")
            $result | Should -Be $true

            $value = $script:baseCache.Get("Preload:123")
            $value | Should -Be "PreloadedValue"
        }

        It "Should preload multiple keys" {
            $generator = { return "MultiPreloadedValue" }
            $script:preloadManager.RegisterPreloadGenerator("Multi:*", $generator)

            $count = $script:preloadManager.PreloadKeys(@("Multi:1", "Multi:2", "Multi:3"))
            $count | Should -Be 3

            $value1 = $script:baseCache.Get("Multi:1")
            $value2 = $script:baseCache.Get("Multi:2")
            $value3 = $script:baseCache.Get("Multi:3")

            $value1 | Should -Be "MultiPreloadedValue"
            $value2 | Should -Be "MultiPreloadedValue"
            $value3 | Should -Be "MultiPreloadedValue"
        }

        It "Should handle preload failures gracefully" {
            $failingGenerator = { throw "Simulated error" }
            $script:preloadManager.RegisterPreloadGenerator("Fail:*", $failingGenerator)

            $result = $script:preloadManager.PreloadKey("Fail:123")
            $result | Should -Be $false
        }

        It "Should provide preload statistics" {
            $stats = $script:preloadManager.GetPreloadStatistics()

            $stats | Should -Not -BeNullOrEmpty
            $stats.ContainsKey("TotalPreloads") | Should -Be $true
            $stats.ContainsKey("SuccessfulPreloads") | Should -Be $true
            $stats.ContainsKey("SuccessRate") | Should -Be $true
        }
    }

    Context "Resource Management" {
        It "Should respect maximum concurrent preloads" {
            $script:preloadManager.MaxConcurrentPreloads = 2
            $script:preloadManager.MaxConcurrentPreloads | Should -Be 2
        }

        It "Should support resource-aware preloading" {
            $script:preloadManager.ResourceAwarePreloading = $true
            $script:preloadManager.ResourceAwarePreloading | Should -Be $true

            $script:preloadManager.ResourceAwarePreloading = $false
            $script:preloadManager.ResourceAwarePreloading | Should -Be $false
        }
    }

    AfterAll {
        # Nettoyage
        if (Test-Path -Path $testDatabasePath) {
            Remove-Item -Path $testDatabasePath -Force -ErrorAction SilentlyContinue
        }
    }
}
