#Requires -Version 5.1
<#
.SYNOPSIS
    Tests d'intégration simplifiés pour le système de cache d'analyse des pull requests.
.DESCRIPTION
    Ce fichier contient des tests d'intégration simplifiés pour le système de cache d'analyse
    des pull requests, vérifiant les fonctionnalités de base du cache.
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

# Chemin du module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\PRAnalysisCache.psm1"

# Vérifier que le module existe
if (-not (Test-Path -Path $modulePath)) {
    throw "Module PRAnalysisCache.psm1 non trouvé à l'emplacement: $modulePath"
}

# Importer le module
Import-Module $modulePath -Force

# Variables globales pour les tests
$script:testCachePath = Join-Path -Path $env:TEMP -ChildPath "PRCacheIntegration"
Write-Host "Chemin du cache de test: $script:testCachePath"

# Créer des données de test
BeforeAll {
    # Créer le répertoire de cache de test
    if (-not (Test-Path -Path $script:testCachePath)) {
        New-Item -Path $script:testCachePath -ItemType Directory -Force | Out-Null
    } else {
        # Nettoyer le répertoire
        Get-ChildItem -Path $script:testCachePath -File | Remove-Item -Force
    }
}

Describe "PRCache Integration Tests" {
    Context "Basic Workflow" {
        It "Exécute un flux de travail de base avec le cache" {
            # Créer un cache
            $cache = New-PRAnalysisCache -MaxMemoryItems 100
            $cache | Should -Not -BeNullOrEmpty
            $cache.DiskCachePath = $script:testCachePath

            # Ajouter des éléments au cache
            $cache.SetItem("TestKey1", "TestValue1", (New-TimeSpan -Hours 1))
            $cache.SetItem("TestKey2", @{ "Name" = "Test Object"; "Value" = 42 }, (New-TimeSpan -Hours 1))
            $cache.SetItem("TestKey3", @(1, 2, 3, 4, 5), (New-TimeSpan -Hours 1))

            # Vérifier que les éléments ont été ajoutés
            $cache.GetItem("TestKey1") | Should -Be "TestValue1"
            $cache.GetItem("TestKey2").Name | Should -Be "Test Object"
            $cache.GetItem("TestKey3")[2] | Should -Be 3

            # Vérifier que les fichiers de cache ont été créés
            $cacheFiles = Get-ChildItem -Path $script:testCachePath -Filter "*.xml"
            $cacheFiles.Count | Should -Be 3

            # Supprimer un élément du cache
            $cache.RemoveItem("TestKey1")
            $cache.GetItem("TestKey1") | Should -BeNullOrEmpty

            # Vérifier que le fichier de cache a été supprimé
            $cacheFiles = Get-ChildItem -Path $script:testCachePath -Filter "*.xml"
            $cacheFiles.Count | Should -Be 2

            # Vider le cache
            $cache.Clear()
            $cache.GetItem("TestKey2") | Should -BeNullOrEmpty
            $cache.GetItem("TestKey3") | Should -BeNullOrEmpty

            # Vérifier que tous les fichiers de cache ont été supprimés
            $cacheFiles = Get-ChildItem -Path $script:testCachePath -Filter "*.xml"
            $cacheFiles.Count | Should -Be 0
        }
    }

    Context "Cache Expiration" {
        It "Gère correctement l'expiration des éléments du cache" {
            # Créer un cache
            $cache = New-PRAnalysisCache -MaxMemoryItems 100
            $cache | Should -Not -BeNullOrEmpty
            $cache.DiskCachePath = $script:testCachePath

            # Ajouter un élément avec une durée de vie courte
            $cache.SetItem("ExpiringKey", "ExpiringValue", (New-TimeSpan -Seconds 1))

            # Vérifier que l'élément existe initialement
            $cache.GetItem("ExpiringKey") | Should -Be "ExpiringValue"

            # Attendre l'expiration
            Start-Sleep -Seconds 2

            # Vérifier que l'élément a expiré
            $cache.GetItem("ExpiringKey") | Should -BeNullOrEmpty
        }
    }

    Context "Memory Cache Cleanup" {
        It "Nettoie le cache en mémoire lorsque la limite est atteinte" {
            # Créer un cache avec une limite de 5 éléments
            $cache = New-PRAnalysisCache -MaxMemoryItems 5
            $cache | Should -Not -BeNullOrEmpty
            $cache.DiskCachePath = $script:testCachePath

            # Ajouter plus d'éléments que la limite
            for ($i = 1; $i -le 10; $i++) {
                $cache.SetItem("Key$i", "Value$i", (New-TimeSpan -Hours 1))
            }

            # Vérifier que le cache en mémoire contient au maximum 5 éléments
            $cache.MemoryCache.Count | Should -BeLessOrEqual 5

            # Vérifier que les éléments les plus récents sont toujours en mémoire
            $cache.MemoryCache.ContainsKey($cache.NormalizeKey("Key10")) | Should -Be $true
            $cache.MemoryCache.ContainsKey($cache.NormalizeKey("Key9")) | Should -Be $true

            # Vérifier que tous les éléments sont accessibles (même ceux qui ne sont plus en mémoire)
            for ($i = 1; $i -le 10; $i++) {
                $cache.GetItem("Key$i") | Should -Be "Value$i"
            }
        }
    }

    Context "Error Handling" {
        It "Gère correctement les erreurs de lecture du cache" {
            # Créer un cache
            $cache = New-PRAnalysisCache -MaxMemoryItems 100
            $cache | Should -Not -BeNullOrEmpty
            $cache.DiskCachePath = $script:testCachePath

            # Ajouter un élément au cache
            $cache.SetItem("TestKey", "TestValue", (New-TimeSpan -Hours 1))

            # Corrompre le fichier de cache
            $cacheFile = Join-Path -Path $script:testCachePath -ChildPath "$($cache.NormalizeKey("TestKey")).xml"
            Set-Content -Path $cacheFile -Value "Invalid XML Content"

            # Vider le cache en mémoire
            $cache.MemoryCache.Clear()

            # Vérifier que la lecture du cache corrompu ne provoque pas d'erreur
            { $cache.GetItem("TestKey") } | Should -Not -Throw

            # Vérifier que la valeur retournée est null
            $cache.GetItem("TestKey") | Should -BeNullOrEmpty
        }
    }
}
