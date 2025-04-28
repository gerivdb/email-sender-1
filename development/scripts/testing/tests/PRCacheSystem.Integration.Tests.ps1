#Requires -Version 5.1
<#
.SYNOPSIS
    Tests d'intÃ©gration pour le systÃ¨me de cache d'analyse des pull requests.
.DESCRIPTION
    Ce fichier contient des tests d'intÃ©gration pour le systÃ¨me complet de cache d'analyse
    des pull requests, vÃ©rifiant l'interaction entre les diffÃ©rents composants.
.NOTES
    Author: Augment Agent
    Version: 1.0
    Requires: Pester v5.0+, PRAnalysisCache.psm1
#>

# Importer Pester si nÃ©cessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Chemins des scripts Ã  tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\PRAnalysisCache.psm1"
$initializePath = Join-Path -Path $PSScriptRoot -ChildPath "..\Initialize-PRCachePersistence.ps1"
$validityPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Test-PRCacheValidity.ps1"
$updatePath = Join-Path -Path $PSScriptRoot -ChildPath "..\Update-PRCacheSelectively.ps1"
$statisticsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Get-PRCacheStatistics.ps1"

# VÃ©rifier que tous les scripts existent
$scripts = @($modulePath, $initializePath, $validityPath, $updatePath, $statisticsPath)
foreach ($script in $scripts) {
    if (-not (Test-Path -Path $script)) {
        throw "Script non trouvÃ©: $script"
    }
}

# Importer le module
Import-Module $modulePath -Force

# Variables globales pour les tests
$script:testCachePath = Join-Path -Path $env:TEMP -ChildPath "PRCacheIntegration"

# CrÃ©er des donnÃ©es de test
BeforeAll {
    # CrÃ©er le rÃ©pertoire de cache de test
    New-Item -Path $script:testCachePath -ItemType Directory -Force | Out-Null

    # Fonction pour exÃ©cuter les scripts avec des paramÃ¨tres
    function Invoke-InitializeScript {
        param(
            [string]$CachePath,
            [int]$MaxMemoryItems = 1000,
            [int]$DefaultTTLSeconds = 86400,
            [string]$EvictionPolicy = "LRU",
            [switch]$Force
        )

        $params = @{
            CachePath         = $CachePath
            MaxMemoryItems    = $MaxMemoryItems
            DefaultTTLSeconds = $DefaultTTLSeconds
            EvictionPolicy    = $EvictionPolicy
        }

        if ($Force) {
            $params.Add("Force", $true)
        }

        & $initializePath @params
    }

    function Invoke-ValidityScript {
        param(
            [string]$CachePath,
            [int]$TestCount = 5,
            [int]$TestDataSize = 5,
            [switch]$DetailedReport
        )

        $params = @{
            CachePath    = $CachePath
            TestCount    = $TestCount
            TestDataSize = $TestDataSize
        }

        if ($DetailedReport) {
            $params.Add("DetailedReport", $true)
        }

        & $validityPath @params
    }

    function Invoke-UpdateScript {
        param(
            [string]$CachePath,
            [string]$Pattern,
            [string[]]$Keys,
            [switch]$RemoveMatching,
            [switch]$Force
        )

        $params = @{
            CachePath = $CachePath
        }

        if ($Pattern) {
            $params.Add("Pattern", $Pattern)
        }

        if ($Keys) {
            $params.Add("Keys", $Keys)
        }

        if ($RemoveMatching) {
            $params.Add("RemoveMatching", $true)
        }

        if ($Force) {
            $params.Add("Force", $true)
        }

        & $updatePath @params
    }

    function Invoke-StatisticsScript {
        param(
            [string]$CachePath,
            [string]$OutputFormat = "Console",
            [string]$OutputPath = ""
        )

        $params = @{
            CachePath    = $CachePath
            OutputFormat = $OutputFormat
        }

        if ($OutputPath) {
            $params.Add("OutputPath", $OutputPath)
        }

        & $statisticsPath @params
    }
}

Describe "PRCache System Integration Tests" {
    Context "End-to-End Workflow" {
        It "ExÃ©cute un flux de travail complet avec tous les composants" {
            # Ã‰tape 1: Initialiser le cache
            $cache = Invoke-InitializeScript -CachePath $script:testCachePath -Force
            $cache | Should -Not -BeNullOrEmpty

            # VÃ©rifier que le cache a Ã©tÃ© initialisÃ© correctement
            Test-Path -Path (Join-Path -Path $script:testCachePath -ChildPath "cache_config.json") | Should -Be $true

            # Ã‰tape 2: Ajouter des Ã©lÃ©ments au cache
            $cache.SetItem("PR:42:File:script1.ps1", "Content1", (New-TimeSpan -Hours 1))
            $cache.SetItem("PR:42:File:script2.ps1", "Content2", (New-TimeSpan -Hours 1))
            $cache.SetItem("PR:43:File:script1.ps1", "Content3", (New-TimeSpan -Hours 1))

            # VÃ©rifier que les Ã©lÃ©ments ont Ã©tÃ© ajoutÃ©s
            $cache.GetItem("PR:42:File:script1.ps1") | Should -Be "Content1"
            $cache.GetItem("PR:42:File:script2.ps1") | Should -Be "Content2"
            $cache.GetItem("PR:43:File:script1.ps1") | Should -Be "Content3"

            # Ã‰tape 3: Tester la validitÃ© du cache
            $validityResult = Invoke-ValidityScript -CachePath $script:testCachePath
            $validityResult | Should -Not -BeNullOrEmpty
            $validityResult.IsValid | Should -Be $true

            # Ã‰tape 4: Mettre Ã  jour sÃ©lectivement le cache
            Invoke-UpdateScript -CachePath $script:testCachePath -Pattern "PR:42:*" -Force

            # VÃ©rifier que les Ã©lÃ©ments sont toujours accessibles
            $cache.GetItem("PR:42:File:script1.ps1") | Should -BeNullOrEmpty # Devrait Ãªtre supprimÃ© par la mise Ã  jour
            $cache.GetItem("PR:43:File:script1.ps1") | Should -Be "Content3" # Ne devrait pas Ãªtre affectÃ©

            # Ã‰tape 5: Obtenir les statistiques du cache
            $statsResult = Invoke-StatisticsScript -CachePath $script:testCachePath
            $statsResult | Should -Not -BeNullOrEmpty
            $statsResult.Name | Should -Be "PRAnalysisCache"
        }
    }

    Context "Performance Tests" {
        It "GÃ¨re efficacement un grand nombre d'Ã©lÃ©ments" {
            # Initialiser le cache
            $cache = Invoke-InitializeScript -CachePath $script:testCachePath -MaxMemoryItems 1000 -Force
            $cache | Should -Not -BeNullOrEmpty

            # Ajouter un grand nombre d'Ã©lÃ©ments
            $itemCount = 100
            $startTime = Get-Date

            for ($i = 1; $i -le $itemCount; $i++) {
                $cache.SetItem("TestKey$i", "TestValue$i", (New-TimeSpan -Hours 1))
            }

            $endTime = Get-Date
            $duration = ($endTime - $startTime).TotalSeconds

            Write-Host "Temps pour ajouter $itemCount Ã©lÃ©ments: $duration secondes"

            # VÃ©rifier que les Ã©lÃ©ments ont Ã©tÃ© ajoutÃ©s
            $cache.GetItem("TestKey1") | Should -Be "TestValue1"
            $cache.GetItem("TestKey$itemCount") | Should -Be "TestValue$itemCount"

            # Mesurer le temps d'accÃ¨s
            $startTime = Get-Date

            for ($i = 1; $i -le $itemCount; $i++) {
                $value = $cache.GetItem("TestKey$i")
            }

            $endTime = Get-Date
            $duration = ($endTime - $startTime).TotalSeconds

            Write-Host "Temps pour accÃ©der Ã  $itemCount Ã©lÃ©ments: $duration secondes"

            # Obtenir les statistiques
            $statsResult = Invoke-StatisticsScript -CachePath $script:testCachePath
            $statsResult | Should -Not -BeNullOrEmpty
            $statsResult.ItemCount | Should -BeGreaterOrEqual $itemCount
        }
    }

    Context "Error Recovery" {
        It "RÃ©cupÃ¨re d'un cache corrompu" {
            # Initialiser le cache
            $cache = Invoke-InitializeScript -CachePath $script:testCachePath -Force
            $cache | Should -Not -BeNullOrEmpty

            # Ajouter des Ã©lÃ©ments au cache
            $cache.SetItem("TestKey1", "TestValue1", (New-TimeSpan -Hours 1))
            $cache.SetItem("TestKey2", "TestValue2", (New-TimeSpan -Hours 1))

            # Corrompre un fichier de cache
            $corruptedFile = Join-Path -Path $script:testCachePath -ChildPath "$($cache.NormalizeKey("TestKey1")).xml"
            Set-Content -Path $corruptedFile -Value "Invalid XML Content"

            # VÃ©rifier que l'Ã©lÃ©ment corrompu n'est pas accessible
            $cache.GetItem("TestKey1") | Should -BeNullOrEmpty

            # VÃ©rifier que l'Ã©lÃ©ment non corrompu est toujours accessible
            $cache.GetItem("TestKey2") | Should -Be "TestValue2"

            # RÃ©initialiser le cache
            $cache = Invoke-InitializeScript -CachePath $script:testCachePath -Force
            $cache | Should -Not -BeNullOrEmpty

            # VÃ©rifier que le cache est Ã  nouveau valide
            $validityResult = Invoke-ValidityScript -CachePath $script:testCachePath
            $validityResult | Should -Not -BeNullOrEmpty
            $validityResult.IsValid | Should -Be $true
        }
    }
}
