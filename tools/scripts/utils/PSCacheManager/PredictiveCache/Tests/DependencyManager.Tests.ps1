#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module DependencyManager.
.DESCRIPTION
    Ce script contient les tests unitaires pour le module DependencyManager
    du système de cache prédictif.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 12/04/2025
#>

# Importer Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer le module de types simulés
$mockTypesPath = Join-Path -Path $PSScriptRoot -ChildPath "MockTypes.psm1"
Import-Module $mockTypesPath -Force

# Créer un chemin temporaire pour la base de données de test
$testDatabasePath = Join-Path -Path $env:TEMP -ChildPath "PSCacheManager_Tests\DependencyManager_Test.db"
$testDatabaseDir = Split-Path -Path $testDatabasePath -Parent
if (-not (Test-Path -Path $testDatabaseDir)) {
    New-Item -Path $testDatabaseDir -ItemType Directory -Force | Out-Null
}

# Nettoyer les tests précédents
if (Test-Path -Path $testDatabasePath) {
    Remove-Item -Path $testDatabasePath -Force
}

Describe "DependencyManager Module Tests" {
    BeforeAll {
        # Créer un UsageCollector réel à partir de la classe définie dans MockTypes.psm1
        $testCachePath = Join-Path -Path $env:TEMP -ChildPath "PSCacheManager_Tests\Cache"
        if (-not (Test-Path -Path $testCachePath)) {
            New-Item -Path $testCachePath -ItemType Directory -Force | Out-Null
        }

        $script:mockCacheManager = [CacheManager]::new("TestCache", $testCachePath)
        $script:mockUsageCollector = [UsageCollector]::new($testDatabasePath, "TestCache")

        # Ajouter des données de test au UsageCollector
        $script:mockUsageCollector.RecordAccess("Key1", $true)
        $script:mockUsageCollector.RecordAccess("Key2", $true)
        $script:mockUsageCollector.RecordAccess("Key3", $true)
    }

    # Mock pour New-UsageCollector
    Mock -CommandName New-UsageCollector -MockWith {
        return $mockUsageCollector
    }
}

Context "New-DependencyManager Function" {
    It "Should create a new DependencyManager object" {
        $manager = New-DependencyManager -BaseCache $mockCacheManager -UsageCollector $mockUsageCollector
        $manager | Should -Not -BeNullOrEmpty
        $manager.GetType().Name | Should -Be "DependencyManager"
    }
}

Context "Add-CacheDependency Function" {
    It "Should add a dependency between keys" {
        # Arrange
        $manager = New-DependencyManager -BaseCache $mockCacheManager -UsageCollector $mockUsageCollector
        $sourceKey = "Source"
        $targetKey = "Target"
        $strength = 0.8

        # Act
        $result = Add-CacheDependency -DependencyManager $manager -SourceKey $sourceKey -TargetKey $targetKey -Strength $strength

        # Assert
        $result | Should -Be $true
        $dependencies = $manager.GetDependencies($sourceKey)
        $dependencies[$targetKey] | Should -Be $strength
    }
}

Context "Remove-CacheDependency Function" {
    It "Should remove a dependency between keys" {
        # Arrange
        $manager = New-DependencyManager -BaseCache $mockCacheManager -UsageCollector $mockUsageCollector
        $sourceKey = "Source"
        $targetKey = "Target"
        Add-CacheDependency -DependencyManager $manager -SourceKey $sourceKey -TargetKey $targetKey -Strength 0.8

        # Act
        $result = Remove-CacheDependency -DependencyManager $manager -SourceKey $sourceKey -TargetKey $targetKey

        # Assert
        $result | Should -Be $true
        $dependencies = $manager.GetDependencies($sourceKey)
        $dependencies.ContainsKey($targetKey) | Should -Be $false
    }
}

Context "Set-DependencyManagerOptions Function" {
    It "Should update dependency manager options" {
        # Arrange
        $manager = New-DependencyManager -BaseCache $mockCacheManager -UsageCollector $mockUsageCollector
        $autoDetect = $true
        $maxDependencies = 20

        # Act
        $result = Set-DependencyManagerOptions -DependencyManager $manager -AutoDetectDependencies $autoDetect -MaxDependenciesPerKey $maxDependencies

        # Assert
        $result | Should -Be $true
        $manager.AutoDetectDependencies | Should -Be $autoDetect
        $manager.MaxDependenciesPerKey | Should -Be $maxDependencies
    }
}

Context "DependencyManager Methods" {
    BeforeEach {
        # Cette variable est utilisée dans chaque test de ce contexte
        $script:manager = New-DependencyManager -BaseCache $mockCacheManager -UsageCollector $mockUsageCollector
    }

    It "Should add and retrieve dependencies" {
        # Arrange
        $sourceKey = "Source"
        $targetKey = "Target"
        $strength = 0.8

        # Act
        $manager.AddDependency($sourceKey, $targetKey, $strength)
        $dependencies = $manager.GetDependencies($sourceKey)

        # Assert
        $dependencies[$targetKey] | Should -Be $strength
    }

    It "Should add and retrieve dependents" {
        # Arrange
        $sourceKey = "Source"
        $targetKey = "Target"
        $strength = 0.8

        # Act
        $manager.AddDependency($sourceKey, $targetKey, $strength)
        $dependents = $manager.GetDependents($targetKey)

        # Assert
        $dependents[$sourceKey] | Should -Be $strength
    }

    It "Should detect dependencies automatically" {
        # Act
        { $manager.DetectDependencies() } | Should -Not -Throw
    }

    It "Should calculate dependency strength" {
        # Arrange
        $sequence = [PSCustomObject]@{
            FirstKey          = "Key1"
            SecondKey         = "Key2"
            SequenceCount     = 5
            AvgTimeDifference = 1000
            LastOccurrence    = (Get-Date).AddMinutes(-5)
        }

        # Act
        $strength = $manager.CalculateDependencyStrength($sequence)

        # Assert
        $strength | Should -BeGreaterThan 0
        $strength | Should -BeLessOrEqual 1
    }

    It "Should get dependency statistics" {
        # Arrange
        $manager.AddDependency("Source1", "Target1", 0.8)
        $manager.AddDependency("Source2", "Target2", 0.7)

        # Act
        $stats = $manager.GetDependencyStatistics()

        # Assert
        $stats | Should -Not -BeNullOrEmpty
        $stats.TotalSources | Should -Be 2
        $stats.TotalTargets | Should -Be 2
        $stats.TotalDependencies | Should -Be 2
        $stats.AverageStrength | Should -BeGreaterThan 0
    }
}

AfterAll {
    # Nettoyage
    if (Test-Path -Path $testDatabasePath) {
        Remove-Item -Path $testDatabasePath -Force -ErrorAction SilentlyContinue
    }
}
