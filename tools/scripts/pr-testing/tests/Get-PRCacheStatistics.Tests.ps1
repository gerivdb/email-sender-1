#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Get-PRCacheStatistics.ps1.
.DESCRIPTION
    Ce fichier contient des tests unitaires pour le script Get-PRCacheStatistics.ps1
    qui rÃ©cupÃ¨re et affiche des statistiques dÃ©taillÃ©es sur l'utilisation et les performances du cache.
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

# Chemin du script Ã  tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Get-PRCacheStatistics.ps1"

# VÃ©rifier que le script existe
if (-not (Test-Path -Path $scriptPath)) {
    throw "Script Get-PRCacheStatistics.ps1 non trouvÃ© Ã  l'emplacement: $scriptPath"
}

# Chemin du module de cache
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\PRAnalysisCache.psm1"

# VÃ©rifier que le module existe
if (-not (Test-Path -Path $modulePath)) {
    throw "Module PRAnalysisCache.psm1 non trouvÃ© Ã  l'emplacement: $modulePath"
}

# Importer le module
Import-Module $modulePath -Force

# Variables globales pour les tests
$script:testCachePath = Join-Path -Path $env:TEMP -ChildPath "PRCacheStatistics"

# CrÃ©er des donnÃ©es de test
BeforeAll {
    # CrÃ©er le rÃ©pertoire de cache de test
    New-Item -Path $script:testCachePath -ItemType Directory -Force | Out-Null

    # Fonction pour exÃ©cuter le script avec des paramÃ¨tres
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

        & $scriptPath @params
    }

    # CrÃ©er un cache pour les tests
    $script:cache = New-PRAnalysisCache
    $script:cache.DiskCachePath = $script:testCachePath

    # Ajouter des Ã©lÃ©ments au cache
    $script:cache.SetItem("TestKey1", "TestValue1", (New-TimeSpan -Hours 1))
    $script:cache.SetItem("TestKey2", @{ "Name" = "Test Object"; "Value" = 42 }, (New-TimeSpan -Hours 1))
    $script:cache.SetItem("TestKey3", @(1, 2, 3, 4, 5), (New-TimeSpan -Hours 1))

    # Simuler des accÃ¨s au cache
    $script:cache.GetItem("TestKey1")
    $script:cache.GetItem("TestKey1")
    $script:cache.GetItem("TestKey2")
    $script:cache.GetItem("NonExistentKey")

    # CrÃ©er un fichier de configuration du cache
    $cacheConfig = @{
        Name              = "PRAnalysisCache"
        CachePath         = $script:testCachePath
        DefaultTTLSeconds = 86400
        MaxMemoryItems    = 1000
        EvictionPolicy    = "LRU"
        CreatedAt         = (Get-Date).ToString("o")
        LastResetAt       = (Get-Date).ToString("o")
    } | ConvertTo-Json

    Set-Content -Path (Join-Path -Path $script:testCachePath -ChildPath "cache_config.json") -Value $cacheConfig
}

Describe "Get-PRCacheStatistics Script Tests" {
    Context "Script Execution" {
        It "Le script s'exÃ©cute sans erreur avec les paramÃ¨tres par dÃ©faut" {
            # Act & Assert
            { Invoke-StatisticsScript -CachePath $script:testCachePath } | Should -Not -Throw
        }
    }

    Context "Output Formats" {
        It "GÃ©nÃ¨re une sortie console par dÃ©faut" {
            # Act
            $result = Invoke-StatisticsScript -CachePath $script:testCachePath

            # Assert
            $result | Should -Not -BeNullOrEmpty
        }

        It "GÃ©nÃ¨re une sortie JSON" {
            # Arrange
            $jsonOutputPath = Join-Path -Path $env:TEMP -ChildPath "cache_stats.json"

            # Act
            Invoke-StatisticsScript -CachePath $script:testCachePath -OutputFormat "JSON" -OutputPath $jsonOutputPath

            # Assert
            Test-Path -Path $jsonOutputPath | Should -Be $true
            $jsonContent = Get-Content -Path $jsonOutputPath -Raw
            $jsonContent | Should -Not -BeNullOrEmpty
            { $jsonContent | ConvertFrom-Json } | Should -Not -Throw
        }

        It "GÃ©nÃ¨re une sortie CSV" {
            # Arrange
            $csvOutputPath = Join-Path -Path $env:TEMP -ChildPath "cache_stats.csv"

            # Act
            Invoke-StatisticsScript -CachePath $script:testCachePath -OutputFormat "CSV" -OutputPath $csvOutputPath

            # Assert
            Test-Path -Path $csvOutputPath | Should -Be $true
            $csvContent = Get-Content -Path $csvOutputPath -Raw
            $csvContent | Should -Not -BeNullOrEmpty
            { Import-Csv -Path $csvOutputPath } | Should -Not -Throw
        }

        It "GÃ©nÃ¨re une sortie HTML" {
            # Arrange
            $htmlOutputPath = Join-Path -Path $env:TEMP -ChildPath "cache_stats.html"

            # Act
            Invoke-StatisticsScript -CachePath $script:testCachePath -OutputFormat "HTML" -OutputPath $htmlOutputPath

            # Assert
            Test-Path -Path $htmlOutputPath | Should -Be $true
            $htmlContent = Get-Content -Path $htmlOutputPath -Raw
            $htmlContent | Should -Not -BeNullOrEmpty
            $htmlContent | Should -Match "<html"
            $htmlContent | Should -Match "</html>"
        }
    }

    Context "Statistics Content" {
        It "Inclut les statistiques de base" {
            # Act
            $result = Invoke-StatisticsScript -CachePath $script:testCachePath

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be "PRAnalysisCache"
            $result.ItemCount | Should -BeGreaterOrEqual 3
            $result.DiskItemCount | Should -BeGreaterOrEqual 3
            $result.TotalSize | Should -BeGreaterThan 0
        }

        It "Calcule correctement le taux de succÃ¨s (hit ratio)" {
            # Act
            $result = Invoke-StatisticsScript -CachePath $script:testCachePath

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Hits | Should -BeGreaterOrEqual 3
            $result.Misses | Should -BeGreaterOrEqual 1
            $result.HitRatio | Should -BeGreaterThan 0
        }
    }

    Context "Error Handling" {
        It "GÃ¨re correctement un chemin de cache inexistant" {
            # Arrange
            $nonExistentPath = Join-Path -Path $env:TEMP -ChildPath "NonExistentCache"

            # Act & Assert
            { Invoke-StatisticsScript -CachePath $nonExistentPath } | Should -Throw
        }
    }
}
