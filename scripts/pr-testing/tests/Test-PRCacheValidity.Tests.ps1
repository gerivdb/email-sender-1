#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Test-PRCacheValidity.ps1.
.DESCRIPTION
    Ce fichier contient des tests unitaires pour le script Test-PRCacheValidity.ps1
    qui vérifie la validité et l'intégrité du cache d'analyse des pull requests.
.NOTES
    Author: Augment Agent
    Version: 1.0
    Requires: Pester v5.0+, PRAnalysisCache.psm1
#>

# Importer Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Chemin du script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Test-PRCacheValidity.ps1"

# Vérifier que le script existe
if (-not (Test-Path -Path $scriptPath)) {
    throw "Script Test-PRCacheValidity.ps1 non trouvé à l'emplacement: $scriptPath"
}

# Chemin du module de cache
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\PRAnalysisCache.psm1"

# Vérifier que le module existe
if (-not (Test-Path -Path $modulePath)) {
    throw "Module PRAnalysisCache.psm1 non trouvé à l'emplacement: $modulePath"
}

# Importer le module
Import-Module $modulePath -Force

# Variables globales pour les tests
$script:testCachePath = Join-Path -Path $env:TEMP -ChildPath "PRCacheValidity"

# Créer des données de test
BeforeAll {
    # Créer le répertoire de cache de test
    New-Item -Path $script:testCachePath -ItemType Directory -Force | Out-Null

    # Fonction pour exécuter le script avec des paramètres
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

    # Créer un cache valide pour les tests
    $cache = New-PRAnalysisCache
    $cache.DiskCachePath = $script:testCachePath

    # Ajouter quelques éléments au cache
    $cache.SetItem("TestKey1", "TestValue1", (New-TimeSpan -Hours 1))
    $cache.SetItem("TestKey2", @{ "Name" = "Test Object"; "Value" = 42 }, (New-TimeSpan -Hours 1))
    $cache.SetItem("TestKey3", @(1, 2, 3, 4, 5), (New-TimeSpan -Hours 1))
}

Describe "Test-PRCacheValidity Script Tests" {
    Context "Script Execution" {
        It "Le script s'exécute sans erreur avec les paramètres par défaut" {
            # Act & Assert
            { Invoke-ValidityScript -CachePath $script:testCachePath } | Should -Not -Throw
        }

        It "Le script s'exécute sans erreur avec un rapport détaillé" {
            # Act & Assert
            { Invoke-ValidityScript -CachePath $script:testCachePath -DetailedReport } | Should -Not -Throw
        }
    }

    Context "Cache Validation" {
        It "Valide un cache existant et correctement formé" {
            # Act
            $result = Invoke-ValidityScript -CachePath $script:testCachePath

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.IsValid | Should -Be $true
        }

        It "Détecte un cache corrompu" {
            # Arrange - Créer un fichier XML invalide
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
        It "Exécute des tests de performance avec différentes tailles de données" {
            # Act
            $result = Invoke-ValidityScript -CachePath $script:testCachePath -TestCount 5 -TestDataSize 5

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.PerformanceTests | Should -Not -BeNullOrEmpty
            $result.PerformanceTests.Count | Should -Be 5
        }
    }

    Context "Detailed Reporting" {
        It "Génère un rapport détaillé lorsque demandé" {
            # Act
            $result = Invoke-ValidityScript -CachePath $script:testCachePath -DetailedReport

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.DetailedReport | Should -Not -BeNullOrEmpty
        }
    }
}
