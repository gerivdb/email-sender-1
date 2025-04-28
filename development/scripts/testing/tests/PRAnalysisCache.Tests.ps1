#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module PRAnalysisCache.
.DESCRIPTION
    Ce fichier contient des tests unitaires pour le module PRAnalysisCache.psm1
    qui implÃ©mente un systÃ¨me de cache multi-niveaux pour l'analyse des pull requests.
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

# CrÃ©er des donnÃ©es de test
BeforeAll {
    # Initialiser le chemin du cache de test
    $script:testCachePath = Join-Path -Path $env:TEMP -ChildPath "PRAnalysisCache"

    # CrÃ©er le rÃ©pertoire de cache de test
    New-Item -Path $script:testCachePath -ItemType Directory -Force | Out-Null

    # CrÃ©er des donnÃ©es de test
    $script:testData = @{
        "TestKey1" = "TestValue1"
        "TestKey2" = @{
            "Name"  = "Test Object"
            "Value" = 42
            "Items" = @("Item1", "Item2", "Item3")
        }
        "TestKey3" = @(1, 2, 3, 4, 5)
    }
}

Describe "PRAnalysisCache Module Tests" {
    Context "Module Loading" {
        It "Le module PRAnalysisCache est chargÃ©" {
            Get-Module -name "PRAnalysisCache" | Should -Not -BeNullOrEmpty
        }

        It "La fonction New-PRAnalysisCache est disponible" {
            Get-Command -name "New-PRAnalysisCache" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context "Cache Creation" {
        It "CrÃ©e une nouvelle instance de cache avec les paramÃ¨tres par dÃ©faut" {
            $cache = New-PRAnalysisCache
            $cache | Should -Not -BeNullOrEmpty
            $cache.MaxMemoryItems | Should -Be 1000
            $cache.MemoryCache | Should -BeOfType [System.Collections.Hashtable]
            $cache.MemoryCache.Count | Should -Be 0
        }

        It "CrÃ©e une instance de cache avec des paramÃ¨tres personnalisÃ©s" {
            $cache = New-PRAnalysisCache -MaxMemoryItems 500
            $cache | Should -Not -BeNullOrEmpty
            $cache.MaxMemoryItems | Should -Be 500
        }
    }

    Context "Basic Cache Operations" {
        BeforeEach {
            # CrÃ©er un nouveau cache pour chaque test
            $script:cache = New-PRAnalysisCache -MaxMemoryItems 10
            # Rediriger le chemin du cache vers le rÃ©pertoire de test
            $script:cache.DiskCachePath = $script:testCachePath
        }

        It "Ajoute un Ã©lÃ©ment au cache" {
            # Act
            $script:cache.SetItem("TestKey", "TestValue", (New-TimeSpan -Hours 1))

            # Assert - VÃ©rifier le cache en mÃ©moire
            $script:cache.MemoryCache.Count | Should -Be 1
            $script:cache.MemoryCache.ContainsKey($script:cache.NormalizeKey("TestKey")) | Should -Be $true

            # Assert - VÃ©rifier le cache sur disque
            $diskCacheFile = Join-Path -Path $script:testCachePath -ChildPath "$($script:cache.NormalizeKey("TestKey")).xml"
            Test-Path -Path $diskCacheFile | Should -Be $true
        }

        It "RÃ©cupÃ¨re un Ã©lÃ©ment du cache" {
            # Arrange
            $script:cache.SetItem("TestKey", "TestValue", (New-TimeSpan -Hours 1))

            # Act
            $value = $script:cache.GetItem("TestKey")

            # Assert
            $value | Should -Be "TestValue"
        }

        It "Retourne null pour une clÃ© inexistante" {
            # Act
            $value = $script:cache.GetItem("NonExistentKey")

            # Assert
            $value | Should -BeNullOrEmpty
        }

        It "Supprime un Ã©lÃ©ment du cache" {
            # Arrange
            $script:cache.SetItem("TestKey", "TestValue", (New-TimeSpan -Hours 1))

            # Act
            $script:cache.RemoveItem("TestKey")

            # Assert - VÃ©rifier le cache en mÃ©moire
            $script:cache.MemoryCache.ContainsKey($script:cache.NormalizeKey("TestKey")) | Should -Be $false

            # Assert - VÃ©rifier le cache sur disque
            $diskCacheFile = Join-Path -Path $script:testCachePath -ChildPath "$($script:cache.NormalizeKey("TestKey")).xml"
            Test-Path -Path $diskCacheFile | Should -Be $false
        }

        It "Vide le cache" {
            # Arrange
            $script:cache.SetItem("TestKey1", "TestValue1", (New-TimeSpan -Hours 1))
            $script:cache.SetItem("TestKey2", "TestValue2", (New-TimeSpan -Hours 1))
            $script:cache.SetItem("TestKey3", "TestValue3", (New-TimeSpan -Hours 1))

            # Act
            $script:cache.Clear()

            # Assert - VÃ©rifier le cache en mÃ©moire
            $script:cache.MemoryCache.Count | Should -Be 0

            # Assert - VÃ©rifier le cache sur disque
            $diskCacheFiles = Get-ChildItem -Path $script:testCachePath -Filter "*.xml"
            $diskCacheFiles.Count | Should -Be 0
        }
    }

    Context "Cache Expiration" {
        BeforeEach {
            # CrÃ©er un nouveau cache pour chaque test
            $script:cache = New-PRAnalysisCache -MaxMemoryItems 10
            # Rediriger le chemin du cache vers le rÃ©pertoire de test
            $script:cache.DiskCachePath = $script:testCachePath
        }

        It "Respecte la durÃ©e de vie spÃ©cifiÃ©e" {
            # Arrange - Ajouter un Ã©lÃ©ment avec une durÃ©e de vie de 1 seconde
            $script:cache.SetItem("ExpiringKey", "ExpiringValue", (New-TimeSpan -Seconds 1))

            # Act - VÃ©rifier que l'Ã©lÃ©ment existe initialement
            $initialValue = $script:cache.GetItem("ExpiringKey")

            # Assert
            $initialValue | Should -Be "ExpiringValue"

            # Act - Attendre l'expiration et vÃ©rifier Ã  nouveau
            Start-Sleep -Seconds 2
            $expiredValue = $script:cache.GetItem("ExpiringKey")

            # Assert
            $expiredValue | Should -BeNullOrEmpty
        }
    }

    Context "Memory Cache Cleanup" {
        BeforeEach {
            # CrÃ©er un nouveau cache avec une limite de 3 Ã©lÃ©ments
            $script:cache = New-PRAnalysisCache -MaxMemoryItems 3
            # Rediriger le chemin du cache vers le rÃ©pertoire de test
            $script:cache.DiskCachePath = $script:testCachePath
        }

        It "Nettoie le cache en mÃ©moire lorsque la limite est atteinte" {
            # Arrange - Ajouter plus d'Ã©lÃ©ments que la limite
            $script:cache.SetItem("Key1", "Value1", (New-TimeSpan -Hours 1))
            $script:cache.SetItem("Key2", "Value2", (New-TimeSpan -Hours 1))
            $script:cache.SetItem("Key3", "Value3", (New-TimeSpan -Hours 1))

            # VÃ©rifier que le cache contient 3 Ã©lÃ©ments
            $script:cache.MemoryCache.Count | Should -Be 3

            # Act - Ajouter un Ã©lÃ©ment supplÃ©mentaire
            $script:cache.SetItem("Key4", "Value4", (New-TimeSpan -Hours 1))

            # Assert - VÃ©rifier que le cache contient toujours 3 Ã©lÃ©ments
            $script:cache.MemoryCache.Count | Should -Be 3

            # VÃ©rifier que l'Ã©lÃ©ment le plus ancien a Ã©tÃ© supprimÃ© (Key1)
            $script:cache.MemoryCache.ContainsKey($script:cache.NormalizeKey("Key1")) | Should -Be $false

            # VÃ©rifier que les Ã©lÃ©ments plus rÃ©cents sont toujours prÃ©sents
            $script:cache.MemoryCache.ContainsKey($script:cache.NormalizeKey("Key2")) | Should -Be $true
            $script:cache.MemoryCache.ContainsKey($script:cache.NormalizeKey("Key3")) | Should -Be $true
            $script:cache.MemoryCache.ContainsKey($script:cache.NormalizeKey("Key4")) | Should -Be $true
        }
    }

    Context "Key Normalization" {
        BeforeEach {
            # CrÃ©er un nouveau cache pour chaque test
            $script:cache = New-PRAnalysisCache
        }

        It "Normalise les clÃ©s correctement" {
            # Act
            $normalizedKey1 = $script:cache.NormalizeKey("Test Key")
            $normalizedKey2 = $script:cache.NormalizeKey("TEST KEY")
            $normalizedKey3 = $script:cache.NormalizeKey("test/key")
            $normalizedKey4 = $script:cache.NormalizeKey("MIXED_case-KEY/123")

            # Assert - VÃ©rifie que la casse est prÃ©servÃ©e
            $normalizedKey1 | Should -Be "Test Key"
            $normalizedKey2 | Should -Be "TEST KEY"
            # VÃ©rifie le remplacement des caractÃ¨res spÃ©ciaux
            $normalizedKey3 | Should -Be "test_key"
            $normalizedKey4 | Should -Be "MIXED_case-KEY_123"
        }

        It "Utilise des clÃ©s normalisÃ©es pour les opÃ©rations de cache" {
            # Arrange - Test avec diffÃ©rentes casses et caractÃ¨res spÃ©ciaux
            $script:cache.SetItem("Test Key", "TestValue", (New-TimeSpan -Hours 1))
            $script:cache.SetItem("TEST KEY", "TestValue", (New-TimeSpan -Hours 1))
            $script:cache.SetItem("test/key", "TestValue", (New-TimeSpan -Hours 1))

            # Act & Assert - VÃ©rifie que chaque clÃ© retourne la mÃªme valeur
            $script:cache.GetItem("Test Key") | Should -Be "TestValue"
            $script:cache.GetItem("TEST KEY") | Should -Be "TestValue"
            $script:cache.GetItem("test/key") | Should -Be "TestValue"
        }
    }

    Context "Complex Data Types" {
        BeforeEach {
            # CrÃ©er un nouveau cache pour chaque test
            $script:cache = New-PRAnalysisCache
            # Rediriger le chemin du cache vers le rÃ©pertoire de test
            $script:cache.DiskCachePath = $script:testCachePath
        }

        It "GÃ¨re correctement les objets complexes" {
            # Arrange
            $complexObject = $script:testData["TestKey2"]

            # Act
            $script:cache.SetItem("ComplexObject", $complexObject, (New-TimeSpan -Hours 1))
            $retrievedObject = $script:cache.GetItem("ComplexObject")

            # Assert
            $retrievedObject | Should -Not -BeNullOrEmpty
            $retrievedObject.Name | Should -Be $complexObject.Name
            $retrievedObject.Value | Should -Be $complexObject.Value
            $retrievedObject.Items.Count | Should -Be $complexObject.Items.Count
            $retrievedObject.Items[0] | Should -Be $complexObject.Items[0]
        }

        It "GÃ¨re correctement les tableaux" {
            # Arrange
            $array = $script:testData["TestKey3"]

            # Act
            $script:cache.SetItem("Array", $array, (New-TimeSpan -Hours 1))
            $retrievedArray = $script:cache.GetItem("Array")

            # Assert
            $retrievedArray | Should -Not -BeNullOrEmpty
            $retrievedArray.Count | Should -Be $array.Count
            $retrievedArray[0] | Should -Be $array[0]
            $retrievedArray[4] | Should -Be $array[4]
        }
    }

    Context "Error Handling" {
        BeforeEach {
            # CrÃ©er un nouveau cache pour chaque test
            $script:cache = New-PRAnalysisCache
            # Rediriger le chemin du cache vers un rÃ©pertoire en lecture seule
            $readOnlyPath = Join-Path -Path $env:TEMP -ChildPath "ReadOnlyCache"
            New-Item -Path $readOnlyPath -ItemType Directory -Force | Out-Null
            $script:cache.DiskCachePath = $readOnlyPath
        }

        It "GÃ¨re les erreurs de lecture du cache sur disque" {
            # Arrange - CrÃ©er un fichier XML invalide
            $invalidXmlPath = Join-Path -Path $script:cache.DiskCachePath -ChildPath "$($script:cache.NormalizeKey("InvalidKey")).xml"
            Set-Content -Path $invalidXmlPath -Value "Invalid XML Content"

            # Act & Assert - La rÃ©cupÃ©ration ne devrait pas Ã©chouer mais retourner null
            { $script:cache.GetItem("InvalidKey") } | Should -Not -Throw
            $script:cache.GetItem("InvalidKey") | Should -BeNullOrEmpty
        }
    }
}
