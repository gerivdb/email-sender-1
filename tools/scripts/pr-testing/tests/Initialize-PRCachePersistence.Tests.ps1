#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Initialize-PRCachePersistence.ps1.
.DESCRIPTION
    Ce fichier contient des tests unitaires pour le script Initialize-PRCachePersistence.ps1
    qui initialise un systÃ¨me de cache persistant pour l'analyse des pull requests.
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
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Initialize-PRCachePersistence.ps1"

# VÃ©rifier que le script existe
if (-not (Test-Path -Path $scriptPath)) {
    throw "Script Initialize-PRCachePersistence.ps1 non trouvÃ© Ã  l'emplacement: $scriptPath"
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
$script:testCachePath = Join-Path -Path $env:TEMP -ChildPath "PRCachePersistence"

# CrÃ©er des donnÃ©es de test
BeforeAll {
    # CrÃ©er le rÃ©pertoire de cache de test
    New-Item -Path $script:testCachePath -ItemType Directory -Force | Out-Null

    # Fonction pour exÃ©cuter le script avec des paramÃ¨tres
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

        & $scriptPath @params
    }
}

Describe "Initialize-PRCachePersistence Script Tests" {
    Context "Script Execution" {
        It "Le script s'exÃ©cute sans erreur avec les paramÃ¨tres par dÃ©faut" {
            # Act & Assert
            { Invoke-InitializeScript -CachePath $script:testCachePath } | Should -Not -Throw
        }
    }

    Context "Cache Initialization" {
        It "CrÃ©e un nouveau cache si le rÃ©pertoire n'existe pas" {
            # Arrange
            $newCachePath = Join-Path -Path $env:TEMP -ChildPath "NewCache"
            Remove-Item -Path $newCachePath -Recurse -Force -ErrorAction SilentlyContinue

            # Act
            $cache = Invoke-InitializeScript -CachePath $newCachePath

            # Assert
            $cache | Should -Not -BeNullOrEmpty
            Test-Path -Path $newCachePath | Should -Be $true
            Test-Path -Path (Join-Path -Path $newCachePath -ChildPath "cache_config.json") | Should -Be $true
        }

        It "Utilise le cache existant si le rÃ©pertoire existe dÃ©jÃ " {
            # Arrange
            $existingCachePath = Join-Path -Path $env:TEMP -ChildPath "ExistingCache"
            New-Item -Path $existingCachePath -ItemType Directory -Force | Out-Null

            # CrÃ©er une configuration de cache
            $cacheConfig = @{
                Name              = "PRAnalysisCache"
                CachePath         = $existingCachePath
                DefaultTTLSeconds = 3600
                MaxMemoryItems    = 500
                EvictionPolicy    = "LRU"
                CreatedAt         = (Get-Date).ToString("o")
                LastResetAt       = (Get-Date).ToString("o")
            } | ConvertTo-Json

            Set-Content -Path (Join-Path -Path $existingCachePath -ChildPath "cache_config.json") -Value $cacheConfig

            # Act
            $cache = Invoke-InitializeScript -CachePath $existingCachePath

            # Assert
            $cache | Should -Not -BeNullOrEmpty
        }

        It "RÃ©initialise le cache existant si Force est spÃ©cifiÃ©" {
            # Arrange
            $resetCachePath = Join-Path -Path $env:TEMP -ChildPath "ResetCache"
            New-Item -Path $resetCachePath -ItemType Directory -Force | Out-Null

            # CrÃ©er une configuration de cache
            $cacheConfig = @{
                Name              = "PRAnalysisCache"
                CachePath         = $resetCachePath
                DefaultTTLSeconds = 3600
                MaxMemoryItems    = 500
                EvictionPolicy    = "LRU"
                CreatedAt         = (Get-Date).AddDays(-1).ToString("o")
                LastResetAt       = (Get-Date).AddDays(-1).ToString("o")
            } | ConvertTo-Json

            Set-Content -Path (Join-Path -Path $resetCachePath -ChildPath "cache_config.json") -Value $cacheConfig

            # CrÃ©er quelques fichiers de cache
            Set-Content -Path (Join-Path -Path $resetCachePath -ChildPath "test_key.xml") -Value "<cache item>"

            # Act
            $cache = Invoke-InitializeScript -CachePath $resetCachePath -Force

            # Assert
            $cache | Should -Not -BeNullOrEmpty

            # VÃ©rifier que la configuration a Ã©tÃ© mise Ã  jour
            $newConfig = Get-Content -Path (Join-Path -Path $resetCachePath -ChildPath "cache_config.json") | ConvertFrom-Json
            $newConfig.LastResetAt | Should -Not -Be $cacheConfig.LastResetAt

            # VÃ©rifier que les fichiers de cache ont Ã©tÃ© supprimÃ©s
            Test-Path -Path (Join-Path -Path $resetCachePath -ChildPath "test_key.xml") | Should -Be $false
        }
    }

    Context "Parameter Validation" {
        It "Accepte des paramÃ¨tres personnalisÃ©s" {
            # Arrange
            $customCachePath = Join-Path -Path $env:TEMP -ChildPath "CustomCache"
            Remove-Item -Path $customCachePath -Recurse -Force -ErrorAction SilentlyContinue

            # Act
            $cache = Invoke-InitializeScript -CachePath $customCachePath -MaxMemoryItems 2000 -DefaultTTLSeconds 172800 -EvictionPolicy "LFU"

            # Assert
            $cache | Should -Not -BeNullOrEmpty

            # VÃ©rifier que la configuration a Ã©tÃ© crÃ©Ã©e avec les paramÃ¨tres personnalisÃ©s
            $config = Get-Content -Path (Join-Path -Path $customCachePath -ChildPath "cache_config.json") | ConvertFrom-Json
            $config.MaxMemoryItems | Should -Be 2000
            $config.DefaultTTLSeconds | Should -Be 172800
            $config.EvictionPolicy | Should -Be "LFU"
        }

        It "Valide la politique d'Ã©viction" {
            # Act & Assert
            { Invoke-InitializeScript -CachePath $script:testCachePath -EvictionPolicy "LRU" } | Should -Not -Throw
            { Invoke-InitializeScript -CachePath $script:testCachePath -EvictionPolicy "LFU" } | Should -Not -Throw
        }
    }
}
