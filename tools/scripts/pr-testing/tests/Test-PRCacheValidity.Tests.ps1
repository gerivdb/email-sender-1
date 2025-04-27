#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Test-PRCacheValidity.ps1.
.DESCRIPTION
    Ce fichier contient des tests unitaires pour le script Test-PRCacheValidity.ps1
    qui vÃ©rifie la validitÃ© et l'intÃ©gritÃ© du cache d'analyse des pull requests.
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
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Test-PRCacheValidity.ps1"

# VÃ©rifier que le script existe
if (-not (Test-Path -Path $scriptPath)) {
    throw "Script Test-PRCacheValidity.ps1 non trouvÃ© Ã  l'emplacement: $scriptPath"
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
$script:testCachePath = Join-Path -Path $env:TEMP -ChildPath "PRCacheValidity"

# CrÃ©er des donnÃ©es de test
BeforeAll {
    # CrÃ©er le rÃ©pertoire de cache de test
    New-Item -Path $script:testCachePath -ItemType Directory -Force | Out-Null

    # Fonction pour exÃ©cuter le script avec des paramÃ¨tres
    function Invoke-ValidityScript {
        param(
            [string]$CachePath,
            [int]$TestCount = 10,
            [int]$TestDataSize = 10,
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

        & $scriptPath @params
    }

    # CrÃ©er un cache valide pour les tests
    $cache = New-PRAnalysisCache
    $cache.DiskCachePath = $script:testCachePath

    # Ajouter quelques Ã©lÃ©ments au cache
    $cache.SetItem("TestKey1", "TestValue1", (New-TimeSpan -Hours 1))
    $cache.SetItem("TestKey2", @{ "Name" = "Test Object"; "Value" = 42 }, (New-TimeSpan -Hours 1))
    $cache.SetItem("TestKey3", @(1, 2, 3, 4, 5), (New-TimeSpan -Hours 1))
}

Describe "Test-PRCacheValidity Script Tests" {
    Context "Script Execution" {
        It "Le script s'exÃ©cute sans erreur avec les paramÃ¨tres par dÃ©faut" {
            # Act & Assert
            { Invoke-ValidityScript -CachePath $script:testCachePath } | Should -Not -Throw
        }

        It "Le script s'exÃ©cute sans erreur avec un rapport dÃ©taillÃ©" {
            # Act & Assert
            { Invoke-ValidityScript -CachePath $script:testCachePath -DetailedReport } | Should -Not -Throw
        }
    }

    Context "Cache Validation" {
        It "Valide un cache existant et correctement formÃ©" {
            # Act
            $result = Invoke-ValidityScript -CachePath $script:testCachePath

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.IsValid | Should -Be $true
        }

        It "DÃ©tecte un cache corrompu" {
            # Arrange - CrÃ©er un fichier XML invalide
            $corruptedCachePath = Join-Path -Path $env:TEMP -ChildPath "CorruptedCache"
            New-Item -Path $corruptedCachePath -ItemType Directory -Force | Out-Null
            Set-Content -Path (Join-Path -Path $corruptedCachePath -ChildPath "invalid_key.xml") -Value "Invalid XML Content"

            # Act
            $result = Invoke-ValidityScript -CachePath $corruptedCachePath

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.IsValid | Should -Be $false
        }
    }

    Context "Performance Tests" {
        It "ExÃ©cute des tests de performance avec diffÃ©rentes tailles de donnÃ©es" {
            # Act
            $result = Invoke-ValidityScript -CachePath $script:testCachePath -TestCount 5 -TestDataSize 5

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.PerformanceTests | Should -Not -BeNullOrEmpty
            $result.PerformanceTests.Count | Should -Be 5
        }
    }

    Context "Detailed Reporting" {
        It "GÃ©nÃ¨re un rapport dÃ©taillÃ© lorsque demandÃ©" {
            # Act
            $result = Invoke-ValidityScript -CachePath $script:testCachePath -DetailedReport

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.DetailedReport | Should -Not -BeNullOrEmpty
        }
    }
}
