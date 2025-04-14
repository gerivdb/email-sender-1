BeforeAll {
    # Importer le module à tester
    $global:modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\maintenance\paths\PathResolver.psm1"
    Import-Module $global:modulePath -Force

    # Créer un dossier temporaire pour les tests
    $global:testFolder = Join-Path -Path $TestDrive -ChildPath "PathResolverTests"
    New-Item -Path $global:testFolder -ItemType Directory -Force | Out-Null

    # Créer une structure de répertoires et de fichiers pour les tests
    $global:subFolder1 = Join-Path -Path $global:testFolder -ChildPath "subfolder1"
    $global:subFolder2 = Join-Path -Path $global:testFolder -ChildPath "subfolder2"
    $global:subSubFolder = Join-Path -Path $global:subFolder1 -ChildPath "subsubfolder"

    New-Item -Path $global:subFolder1 -ItemType Directory -Force | Out-Null
    New-Item -Path $global:subFolder2 -ItemType Directory -Force | Out-Null
    New-Item -Path $global:subSubFolder -ItemType Directory -Force | Out-Null

    # Créer des fichiers de test
    $global:testFile1 = Join-Path -Path $global:testFolder -ChildPath "testfile1.txt"
    $global:testFile2 = Join-Path -Path $global:subFolder1 -ChildPath "testfile2.json"
    $global:testFile3 = Join-Path -Path $global:subSubFolder -ChildPath "testfile3.ps1"

    "Test file 1 content" | Out-File -FilePath $global:testFile1 -Encoding utf8
    "{ `"test`": `"value`" }" | Out-File -FilePath $global:testFile2 -Encoding utf8
    "Write-Host 'Test file 3 content'" | Out-File -FilePath $global:testFile3 -Encoding utf8

    # Initialiser le module avec les chemins de test
    Initialize-PathResolver -AdditionalSearchPaths @($global:testFolder)

    # Ajouter des mappings de test
    Add-PathMapping -Prefix "test" -Target $global:testFolder
    Add-PathMapping -Prefix "sub1" -Target $global:subFolder1
    Add-PathMapping -Prefix "sub2" -Target $global:subFolder2
}

Describe "Get-ScriptPath" {
    BeforeEach {
        # Réinitialiser le cache avant chaque test
        Clear-PathCache
    }

    It "Résout un chemin absolu" {
        $result = Get-ScriptPath -Path $global:testFile1
        $result | Should -Be $global:testFile1
    }

    It "Résout un chemin relatif" {
        # Changer le répertoire courant pour le test
        Push-Location -Path $global:testFolder

        $result = Get-ScriptPath -Path "testfile1.txt"
        $result | Should -Be $global:testFile1

        # Restaurer le répertoire courant
        Pop-Location
    }

    It "Résout un chemin en utilisant les chemins de recherche" {
        $result = Get-ScriptPath -Path "testfile1.txt"
        $result | Should -Be $global:testFile1
    }

    It "Résout un chemin en utilisant les mappings" {
        $result = Get-ScriptPath -Path "test\testfile1.txt"
        $result | Should -Be $global:testFile1

        $result = Get-ScriptPath -Path "sub1\testfile2.json"
        $result | Should -Be $global:testFile2
    }

    It "Résout un chemin en utilisant la recherche récursive" {
        $result = Get-ScriptPath -Path "testfile3.ps1" -SearchDepth 2
        $result | Should -Be $global:testFile3
    }

    It "Retourne null pour un chemin inexistant" {
        $result = Get-ScriptPath -Path "nonexistent_file.txt"
        $result | Should -Be $null
    }

    It "Lève une exception pour un chemin inexistant avec ThrowOnError" {
        { Get-ScriptPath -Path "nonexistent_file.txt" -ThrowOnError } | Should -Throw
    }

    It "Utilise le cache lorsque spécifié" {
        # Premier appel pour remplir le cache
        $result1 = Get-ScriptPath -Path "testfile1.txt" -UseCache

        # Supprimer le fichier
        Remove-Item -Path $global:testFile1 -Force

        # Deuxième appel avec cache
        $result2 = Get-ScriptPath -Path "testfile1.txt" -UseCache

        # Les résultats devraient être identiques
        $result2 | Should -Be $result1

        # Recréer le fichier pour les tests suivants
        "Test file 1 content" | Out-File -FilePath $global:testFile1 -Encoding utf8
    }
}

Describe "Test-ScriptPath" {
    BeforeEach {
        # Réinitialiser le cache avant chaque test
        Clear-PathCache
    }

    It "Valide un chemin existant" {
        $result = Test-ScriptPath -Path $global:testFile1
        $result | Should -Be $true
    }

    It "Invalide un chemin inexistant" {
        $result = Test-ScriptPath -Path "nonexistent_file.txt"
        $result | Should -Be $false
    }

    It "Valide un chemin avec le type de fichier correct" {
        $result = Test-ScriptPath -Path $global:testFile2 -FileType "json"
        $result | Should -Be $true
    }

    It "Invalide un chemin avec le type de fichier incorrect" {
        $result = Test-ScriptPath -Path $global:testFile1 -FileType "json"
        $result | Should -Be $false
    }

    It "Valide un chemin avec la taille minimale correcte" {
        $result = Test-ScriptPath -Path $global:testFile1 -MinimumSize 1
        $result | Should -Be $true
    }

    It "Invalide un chemin avec la taille minimale incorrecte" {
        $result = Test-ScriptPath -Path $global:testFile1 -MinimumSize 1000000
        $result | Should -Be $false
    }

    It "Lève une exception pour un chemin invalide avec ThrowOnError" {
        { Test-ScriptPath -Path "nonexistent_file.txt" -ThrowOnError } | Should -Throw
    }
}

Describe "Clear-PathCache" {
    BeforeEach {
        # Remplir le cache avec des valeurs
        Get-ScriptPath -Path $global:testFile1 -UseCache
        Get-ScriptPath -Path $global:testFile2 -UseCache
    }

    It "Efface un chemin spécifique du cache" {
        # Vérifier que le chemin est dans le cache
        $statistics = Get-PathStatistics -Path "testfile1.txt"
        $statistics | Should -Not -Be $null

        # Effacer le chemin du cache
        Clear-PathCache -Path "testfile1.txt"

        # Vérifier que le chemin n'est plus dans le cache
        $statistics = Get-PathStatistics -Path "testfile1.txt"
        $statistics.ResolvedPath | Should -Be $null
    }

    It "Efface tout le cache" {
        # Vérifier que le cache n'est pas vide
        $statistics = Get-PathStatistics
        $statistics.CacheEntries | Should -BeGreaterThan 0

        # Effacer tout le cache
        Clear-PathCache

        # Vérifier que le cache est vide
        $statistics = Get-PathStatistics
        $statistics.CacheEntries | Should -Be 0
    }
}

Describe "Get-PathStatistics" {
    BeforeEach {
        # Réinitialiser le cache avant chaque test
        Clear-PathCache

        # Remplir le cache avec des valeurs
        Get-ScriptPath -Path $global:testFile1 -UseCache
        Get-ScriptPath -Path $global:testFile2 -UseCache
    }

    It "Obtient des statistiques pour un chemin spécifique" {
        # Ajouter le chemin au cache
        Get-ScriptPath -Path "testfile1.txt" -UseCache

        $statistics = Get-PathStatistics -Path "testfile1.txt"

        $statistics | Should -Not -Be $null
        $statistics.Path | Should -Be "testfile1.txt"
        $statistics.ResolvedPath | Should -Not -Be $null
    }

    It "Obtient des statistiques globales" {
        $statistics = Get-PathStatistics

        $statistics | Should -Not -Be $null
        $statistics.CacheEntries | Should -Be 2
        $statistics.CacheEnabled | Should -Be $true
        $statistics.SearchPaths | Should -Contain $global:testFolder
        $statistics.PathMappings.Keys | Should -Contain "test"
        $statistics.RecentPaths.Count | Should -Be 2
    }
}

Describe "Add-PathMapping" {
    BeforeEach {
        # Réinitialiser les mappings
        Initialize-PathResolver -AdditionalSearchPaths @($global:testFolder)
    }

    It "Ajoute un nouveau mapping" {
        # Ajouter un nouveau mapping
        Add-PathMapping -Prefix "newmapping" -Target $global:subSubFolder

        # Vérifier que le mapping a été ajouté
        $statistics = Get-PathStatistics
        $statistics.PathMappings.Keys | Should -Contain "newmapping"
        $statistics.PathMappings["newmapping"] | Should -Be $global:subSubFolder
    }

    It "Remplace un mapping existant" {
        # Ajouter un mapping
        Add-PathMapping -Prefix "test" -Target $global:subFolder1

        # Vérifier que le mapping a été remplacé
        $statistics = Get-PathStatistics
        $statistics.PathMappings["test"] | Should -Be $global:subFolder1
    }
}

Describe "Remove-PathMapping" {
    BeforeEach {
        # Réinitialiser les mappings
        Initialize-PathResolver -AdditionalSearchPaths @($global:testFolder)
        Add-PathMapping -Prefix "test" -Target $global:testFolder
    }

    It "Supprime un mapping existant" {
        # Vérifier que le mapping existe
        $statistics = Get-PathStatistics
        $statistics.PathMappings.Keys | Should -Contain "test"

        # Supprimer le mapping
        Remove-PathMapping -Prefix "test"

        # Vérifier que le mapping a été supprimé
        $statistics = Get-PathStatistics
        $statistics.PathMappings.Keys | Should -Not -Contain "test"
    }

    It "Ne fait rien pour un mapping inexistant" {
        # Supprimer un mapping inexistant
        Remove-PathMapping -Prefix "nonexistent"

        # Vérifier que les mappings n'ont pas changé
        $statistics = Get-PathStatistics
        $statistics.PathMappings.Keys | Should -Contain "test"
    }
}
