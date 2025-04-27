#Requires -Version 5.1
<#
.SYNOPSIS
    Tests d'intÃ©gration simplifiÃ©s pour le systÃ¨me de cache d'analyse des pull requests.
.DESCRIPTION
    Ce fichier contient des tests d'intÃ©gration simplifiÃ©s pour le systÃ¨me de cache d'analyse
    des pull requests, vÃ©rifiant les fonctionnalitÃ©s de base du cache.
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

# Chemin du module Ã  tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\PRAnalysisCache.psm1"

# VÃ©rifier que le module existe
if (-not (Test-Path -Path $modulePath)) {
    throw "Module PRAnalysisCache.psm1 non trouvÃ© Ã  l'emplacement: $modulePath"
}

# Importer le module
Import-Module $modulePath -Force

# Variables globales pour les tests
$script:testCachePath = Join-Path -Path $env:TEMP -ChildPath "PRCacheIntegration"
Write-Host "Chemin du cache de test: $script:testCachePath"

# CrÃ©er des donnÃ©es de test
BeforeAll {
    # CrÃ©er le rÃ©pertoire de cache de test
    if (-not (Test-Path -Path $script:testCachePath)) {
        New-Item -Path $script:testCachePath -ItemType Directory -Force | Out-Null
    } else {
        # Nettoyer le rÃ©pertoire
        Get-ChildItem -Path $script:testCachePath -File | Remove-Item -Force
    }
}

Describe "PRCache Integration Tests" {
    Context "Basic Workflow" {
        It "ExÃ©cute un flux de travail de base avec le cache" {
            # CrÃ©er un cache
            $cache = New-PRAnalysisCache -MaxMemoryItems 100
            $cache | Should -Not -BeNullOrEmpty
            $cache.DiskCachePath = $script:testCachePath

            # Ajouter des Ã©lÃ©ments au cache
            $cache.SetItem("TestKey1", "TestValue1", (New-TimeSpan -Hours 1))
            $cache.SetItem("TestKey2", @{ "Name" = "Test Object"; "Value" = 42 }, (New-TimeSpan -Hours 1))
            $cache.SetItem("TestKey3", @(1, 2, 3, 4, 5), (New-TimeSpan -Hours 1))

            # VÃ©rifier que les Ã©lÃ©ments ont Ã©tÃ© ajoutÃ©s
            $cache.GetItem("TestKey1") | Should -Be "TestValue1"
            $cache.GetItem("TestKey2").Name | Should -Be "Test Object"
            $cache.GetItem("TestKey3")[2] | Should -Be 3

            # VÃ©rifier que les fichiers de cache ont Ã©tÃ© crÃ©Ã©s
            $cacheFiles = Get-ChildItem -Path $script:testCachePath -Filter "*.xml"
            $cacheFiles.Count | Should -Be 3

            # Supprimer un Ã©lÃ©ment du cache
            $cache.RemoveItem("TestKey1")
            $cache.GetItem("TestKey1") | Should -BeNullOrEmpty

            # VÃ©rifier que le fichier de cache a Ã©tÃ© supprimÃ©
            $cacheFiles = Get-ChildItem -Path $script:testCachePath -Filter "*.xml"
            $cacheFiles.Count | Should -Be 2

            # Vider le cache
            $cache.Clear()
            $cache.GetItem("TestKey2") | Should -BeNullOrEmpty
            $cache.GetItem("TestKey3") | Should -BeNullOrEmpty

            # VÃ©rifier que tous les fichiers de cache ont Ã©tÃ© supprimÃ©s
            $cacheFiles = Get-ChildItem -Path $script:testCachePath -Filter "*.xml"
            $cacheFiles.Count | Should -Be 0
        }
    }

    Context "Cache Expiration" {
        It "GÃ¨re correctement l'expiration des Ã©lÃ©ments du cache" {
            # CrÃ©er un cache
            $cache = New-PRAnalysisCache -MaxMemoryItems 100
            $cache | Should -Not -BeNullOrEmpty
            $cache.DiskCachePath = $script:testCachePath

            # Ajouter un Ã©lÃ©ment avec une durÃ©e de vie courte
            $cache.SetItem("ExpiringKey", "ExpiringValue", (New-TimeSpan -Seconds 1))

            # VÃ©rifier que l'Ã©lÃ©ment existe initialement
            $cache.GetItem("ExpiringKey") | Should -Be "ExpiringValue"

            # Attendre l'expiration
            Start-Sleep -Seconds 2

            # VÃ©rifier que l'Ã©lÃ©ment a expirÃ©
            $cache.GetItem("ExpiringKey") | Should -BeNullOrEmpty
        }
    }

    Context "Memory Cache Cleanup" {
        It "Nettoie le cache en mÃ©moire lorsque la limite est atteinte" {
            # CrÃ©er un cache avec une limite de 5 Ã©lÃ©ments
            $cache = New-PRAnalysisCache -MaxMemoryItems 5
            $cache | Should -Not -BeNullOrEmpty
            $cache.DiskCachePath = $script:testCachePath

            # Ajouter plus d'Ã©lÃ©ments que la limite
            for ($i = 1; $i -le 10; $i++) {
                $cache.SetItem("Key$i", "Value$i", (New-TimeSpan -Hours 1))
            }

            # VÃ©rifier que le cache en mÃ©moire contient au maximum 5 Ã©lÃ©ments
            $cache.MemoryCache.Count | Should -BeLessOrEqual 5

            # VÃ©rifier que les Ã©lÃ©ments les plus rÃ©cents sont toujours en mÃ©moire
            $cache.MemoryCache.ContainsKey($cache.NormalizeKey("Key10")) | Should -Be $true
            $cache.MemoryCache.ContainsKey($cache.NormalizeKey("Key9")) | Should -Be $true

            # VÃ©rifier que tous les Ã©lÃ©ments sont accessibles (mÃªme ceux qui ne sont plus en mÃ©moire)
            for ($i = 1; $i -le 10; $i++) {
                $cache.GetItem("Key$i") | Should -Be "Value$i"
            }
        }
    }

    Context "Error Handling" {
        It "GÃ¨re correctement les erreurs de lecture du cache" {
            # CrÃ©er un cache
            $cache = New-PRAnalysisCache -MaxMemoryItems 100
            $cache | Should -Not -BeNullOrEmpty
            $cache.DiskCachePath = $script:testCachePath

            # Ajouter un Ã©lÃ©ment au cache
            $cache.SetItem("TestKey", "TestValue", (New-TimeSpan -Hours 1))

            # Corrompre le fichier de cache
            $cacheFile = Join-Path -Path $script:testCachePath -ChildPath "$($cache.NormalizeKey("TestKey")).xml"
            Set-Content -Path $cacheFile -Value "Invalid XML Content"

            # Vider le cache en mÃ©moire
            $cache.MemoryCache.Clear()

            # VÃ©rifier que la lecture du cache corrompu ne provoque pas d'erreur
            { $cache.GetItem("TestKey") } | Should -Not -Throw

            # VÃ©rifier que la valeur retournÃ©e est null
            $cache.GetItem("TestKey") | Should -BeNullOrEmpty
        }
    }
}
