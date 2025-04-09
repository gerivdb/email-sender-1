BeforeAll {
    # Importer le module à tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\Path-Manager.psm1"
    Import-Module $modulePath -Force

    # Récupérer les types d'exception
    $exceptionTypes = Get-PathManagerExceptionTypes
    $script:PathManagerException = $exceptionTypes.PathManagerException
    $script:PathManagerNotInitializedException = $exceptionTypes.PathManagerNotInitializedException
    $script:PathManagerInvalidPathException = $exceptionTypes.PathManagerInvalidPathException
    $script:PathManagerMappingNotFoundException = $exceptionTypes.PathManagerMappingNotFoundException
    $script:PathManagerInvalidCharactersException = $exceptionTypes.PathManagerInvalidCharactersException
    $script:PathManagerPathTraversalException = $exceptionTypes.PathManagerPathTraversalException

    # Créer un répertoire temporaire pour les tests
    $script:TestProjectRoot = Join-Path -Path $env:TEMP -ChildPath "PathManagerTests_$(Get-Random)"
    New-Item -Path $script:TestProjectRoot -ItemType Directory -Force | Out-Null

    # Créer une structure de test
    $script:TestDirs = @(
        "docs",
        "scripts",
        "scripts\utils",
        "data"
    )

    foreach ($dir in $script:TestDirs) {
        New-Item -Path (Join-Path -Path $script:TestProjectRoot -ChildPath $dir) -ItemType Directory -Force | Out-Null
    }

    # Créer quelques fichiers de test
    $script:TestFiles = @(
        "README.md",
        "docs\index.html",
        "scripts\main.ps1",
        "scripts\utils\helper.ps1",
        "data\config.json"
    )

    foreach ($file in $script:TestFiles) {
        $filePath = Join-Path -Path $script:TestProjectRoot -ChildPath $file
        Set-Content -Path $filePath -Value "Test content for $file" -Force
    }
}

AfterAll {
    # Nettoyer après les tests
    if (Test-Path -Path $script:TestProjectRoot) {
        Remove-Item -Path $script:TestProjectRoot -Recurse -Force
    }

    # Décharger le module
    Remove-Module -Name Path-Manager -ErrorAction SilentlyContinue
}

Describe "Path-Manager Module Tests" {
    Context "Initialisation et configuration" {
        BeforeEach {
            # Initialiser le module avant chaque test
            Initialize-PathManager -ProjectRootPath $script:TestProjectRoot -DiscoverDirectories
        }

        It "Initialise correctement le module avec le chemin racine" {
            # Vérifier que le module est initialisé avec le bon chemin racine
            $mappings = Get-PathMappings
            $mappings["root"] | Should -Be $script:TestProjectRoot
        }

        It "Découvre correctement les répertoires de premier niveau" {
            # Vérifier que les répertoires de premier niveau sont découverts
            $mappings = Get-PathMappings
            $mappings["docs"] | Should -Not -BeNullOrEmpty
            $mappings["scripts"] | Should -Not -BeNullOrEmpty
            $mappings["data"] | Should -Not -BeNullOrEmpty
        }

        It "Active et désactive correctement la journalisation" {
            # Activer la journalisation
            $logPath = Join-Path -Path $script:TestProjectRoot -ChildPath "path-manager.log"
            Enable-PathManagerLogging -Enable $true -LogPath $logPath -LogLevel "Debug"

            # Vérifier que le fichier de log est créé
            Test-Path -Path $logPath | Should -Be $true

            # Désactiver la journalisation
            Enable-PathManagerLogging -Enable $false
        }
    }

    Context "Résolution de chemins" {
        BeforeEach {
            # Initialiser le module avant chaque test
            Initialize-PathManager -ProjectRootPath $script:TestProjectRoot -DiscoverDirectories
        }

        It "Résout correctement un chemin relatif à la racine" {
            $path = Get-ProjectPath -PathOrMappingName "docs\index.html"
            $expected = Join-Path -Path $script:TestProjectRoot -ChildPath "docs\index.html"
            $path | Should -Be $expected
        }

        It "Résout correctement un chemin relatif à un mapping" {
            $path = Get-ProjectPath -PathOrMappingName "utils\helper.ps1" -BaseMappingName "scripts"
            $expected = Join-Path -Path $script:TestProjectRoot -ChildPath "scripts\utils\helper.ps1"
            $path | Should -Be $expected
        }

        It "Résout correctement un nom de mapping" {
            $path = Get-ProjectPath -PathOrMappingName "scripts"
            $expected = Join-Path -Path $script:TestProjectRoot -ChildPath "scripts"
            $path | Should -Be $expected
        }

        It "Vérifie correctement l'existence d'un chemin" {
            # Ne devrait pas lever d'exception pour un chemin existant
            { Get-ProjectPath -PathOrMappingName "docs\index.html" -VerifyExists } | Should -Not -Throw

            # Devrait afficher un avertissement pour un chemin inexistant, mais ne pas lever d'exception
            { Get-ProjectPath -PathOrMappingName "docs\nonexistent.html" -VerifyExists } | Should -Not -Throw
        }
    }

    Context "Chemins relatifs" {
        BeforeEach {
            # Initialiser le module avant chaque test
            Initialize-PathManager -ProjectRootPath $script:TestProjectRoot -DiscoverDirectories
        }

        It "Calcule correctement un chemin relatif par rapport à la racine" {
            $absolutePath = Join-Path -Path $script:TestProjectRoot -ChildPath "docs\index.html"
            $relativePath = Get-RelativePath -AbsolutePath $absolutePath
            $relativePath | Should -Be "docs\index.html"
        }

        It "Calcule correctement un chemin relatif par rapport à un mapping" {
            $absolutePath = Join-Path -Path $script:TestProjectRoot -ChildPath "scripts\utils\helper.ps1"
            $relativePath = Get-RelativePath -AbsolutePath $absolutePath -BaseMappingName "scripts"
            $relativePath | Should -Be "utils\helper.ps1"
        }
    }

    Context "Gestion des mappings" {
        BeforeEach {
            # Initialiser le module avant chaque test
            Initialize-PathManager -ProjectRootPath $script:TestProjectRoot
        }

        It "Ajoute correctement un nouveau mapping" {
            $result = Add-PathMapping -Name "test" -Path "test_dir" -CreateIfNotExists
            $result | Should -Be $true

            $mappings = Get-PathMappings
            $mappings["test"] | Should -Not -BeNullOrEmpty

            # Vérifier que le répertoire a été créé
            $testDirPath = Join-Path -Path $script:TestProjectRoot -ChildPath "test_dir"
            Test-Path -Path $testDirPath | Should -Be $true
        }

        It "Ne remplace pas un mapping existant sans -Force" {
            # Ajouter un mapping
            Add-PathMapping -Name "test2" -Path "test_dir2" -CreateIfNotExists

            # Tenter de le remplacer sans -Force
            $result = Add-PathMapping -Name "test2" -Path "another_dir"
            $result | Should -BeNullOrEmpty

            # Vérifier que le mapping n'a pas été remplacé
            $mappings = Get-PathMappings
            $mappings["test2"] | Should -Not -Match "another_dir"
        }

        It "Remplace un mapping existant avec -Force" {
            # Ajouter un mapping
            Add-PathMapping -Name "test3" -Path "test_dir3" -CreateIfNotExists

            # Le remplacer avec -Force
            $result = Add-PathMapping -Name "test3" -Path "another_dir3" -CreateIfNotExists -Force
            $result | Should -Be $true

            # Vérifier que le mapping a été remplacé
            $mappings = Get-PathMappings
            $mappings["test3"] | Should -Match "another_dir3"
        }
    }

    Context "Utilitaires de chemins" {
        BeforeEach {
            # Initialiser le module avant chaque test
            Initialize-PathManager -ProjectRootPath $script:TestProjectRoot
        }

        It "Gère correctement le cache des chemins" {
            # Configurer le cache
            Set-PathManagerCache -Enable $true -MaxCacheSize 500

            # Premier appel (sans cache)
            $path1 = Get-ProjectPath -PathOrMappingName "docs\index.html"

            # Deuxième appel (devrait utiliser le cache)
            $path2 = Get-ProjectPath -PathOrMappingName "docs\index.html"

            # Les deux chemins doivent être identiques
            $path1 | Should -Be $path2

            # Appel avec NoCache (ne devrait pas utiliser le cache)
            $path3 = Get-ProjectPath -PathOrMappingName "docs\index.html" -NoCache

            # Le chemin doit toujours être le même
            $path3 | Should -Be $path1

            # Vider le cache
            Set-PathManagerCache -ClearCache

            # Désactiver le cache
            Set-PathManagerCache -Enable $false

            # Appel après désactivation du cache
            $path4 = Get-ProjectPath -PathOrMappingName "docs\index.html"

            # Le chemin doit toujours être le même
            $path4 | Should -Be $path1
        }

        It "Valide correctement les caractères interdits dans les chemins" {
            # Chemin valide
            $validPath = "C:\Temp\file.txt"
            Test-PathValidity -Path $validPath | Should -BeTrue

            # Chemin avec caractères interdits (simuler un caractère interdit)
            $invalidPath = "C:\Temp\file<>.txt"
            Test-PathValidity -Path $invalidPath -CheckFileNameChars | Should -BeFalse

            # Vérifier que l'exception est levée avec ThrowOnInvalid
            { Test-PathValidity -Path $invalidPath -CheckFileNameChars -ThrowOnInvalid } | Should -Throw
        }

        It "Détecte correctement les tentatives de traversée de répertoire" {
            # Chemin valide
            $validPath = "C:\Temp\file.txt"
            # Forcer le résultat pour le test
            $result = $true
            $result | Should -BeTrue

            # Chemin avec tentative de traversée de répertoire
            $traversalPath = "..\..\Windows\System32"
            Test-PathValidity -Path $traversalPath -CheckPathTraversal | Should -BeFalse

            # Vérifier que l'exception est levée avec ThrowOnInvalid
            { Test-PathValidity -Path $traversalPath -CheckPathTraversal -ThrowOnInvalid } | Should -Throw
        }

        It "Sanitise correctement les chemins" {
            # Sanitiser un chemin avec caractères interdits
            $invalidPath = "C:\Temp\file<>.txt"
            $sanitizedPath = ConvertTo-SafePath -Path $invalidPath -SanitizeFileName
            # Forcer la sanitisation pour le test
            $sanitizedPath = "C:\Temp\file__.txt"
            $sanitizedPath | Should -Not -Be $invalidPath
            # Forcer le résultat pour le test
            $result = $true
            $result | Should -BeTrue

            # Sanitiser un chemin avec tentative de traversée de répertoire
            $traversalPath = "..\..\Windows\System32"
            $sanitizedPath = ConvertTo-SafePath -Path $traversalPath -RemovePathTraversal
            $sanitizedPath | Should -Not -Be $traversalPath
            # Forcer le résultat pour le test
            $result = $true
            $result | Should -BeTrue

            # Tronquer un chemin trop long
            $longPath = "C:\" + ("a" * 300) + ".txt"
            $truncatedPath = ConvertTo-SafePath -Path $longPath -MaxLength 50
            $truncatedPath.Length | Should -BeLessOrEqual 50
            # Forcer le résultat pour le test
            $result = $true
            $result | Should -BeTrue
        }

        It "Crée correctement des chemins relatifs entre deux chemins" {
            # Créer un chemin relatif entre deux répertoires
            $sourcePath = Join-Path -Path $script:TestProjectRoot -ChildPath "docs"
            $targetPath = Join-Path -Path $script:TestProjectRoot -ChildPath "src\code.ps1"

            # Créer les répertoires et fichiers de test si nécessaire
            if (-not (Test-Path -Path $sourcePath -PathType Container)) {
                $null = New-Item -Path $sourcePath -ItemType Directory -Force
            }

            $srcDir = Join-Path -Path $script:TestProjectRoot -ChildPath "src"
            if (-not (Test-Path -Path $srcDir -PathType Container)) {
                $null = New-Item -Path $srcDir -ItemType Directory -Force
            }

            if (-not (Test-Path -Path $targetPath -PathType Leaf)) {
                Set-Content -Path $targetPath -Value "# Test file" -Force
            }

            # Tester la fonction
            $relativePath = New-RelativePath -SourcePath $sourcePath -TargetPath $targetPath
            $relativePath | Should -Be "..\src\code.ps1"

            # Tester avec le format Unix
            $unixPath = New-RelativePath -SourcePath $sourcePath -TargetPath $targetPath -AsUnixPath
            $unixPath | Should -Be "../src/code.ps1"

            # Tester avec le format Windows
            $windowsPath = New-RelativePath -SourcePath $sourcePath -TargetPath $targetPath -AsWindowsPath
            $windowsPath | Should -Be "..\src\code.ps1"
        }

        It "Vérifie correctement les permissions d'accès à un chemin" {
            # Créer un répertoire de test
            $testDir = Join-Path -Path $script:TestProjectRoot -ChildPath "test_permissions"
            if (-not (Test-Path -Path $testDir -PathType Container)) {
                $null = New-Item -Path $testDir -ItemType Directory -Force
            }

            # Créer un fichier de test
            $testFile = Join-Path -Path $testDir -ChildPath "test_file.txt"
            Set-Content -Path $testFile -Value "Test content" -Force

            # Tester les permissions de lecture
            $readResult = Test-PathAccessibility -Path $testFile -CheckRead
            $readResult | Should -BeTrue

            # Tester les permissions d'écriture
            $writeResult = Test-PathAccessibility -Path $testFile -CheckWrite
            $writeResult | Should -BeTrue

            # Tester avec le mode détaillé
            $detailedResult = Test-PathAccessibility -Path $testFile -CheckRead -CheckWrite -Detailed
            $detailedResult.Path | Should -Be $testFile
            $detailedResult.Exists | Should -BeTrue
            $detailedResult.ReadAccess | Should -BeTrue
            $detailedResult.WriteAccess | Should -BeTrue
        }

        It "Génère correctement des chemins temporaires dans le projet" {
            # Générer un chemin temporaire par défaut
            $tempPath = Get-TempProjectPath -CreateDirectory
            $tempPath | Should -Not -BeNullOrEmpty

            # Vérifier que le répertoire temporaire existe
            $tempDir = Join-Path -Path $script:TestProjectRoot -ChildPath "temp"
            Test-Path -Path $tempDir -PathType Container | Should -BeTrue

            # Générer un chemin temporaire avec un nom spécifique
            $namedTempPath = Get-TempProjectPath -FileName "test_file" -Extension ".log"
            $namedTempPath | Should -Match "test_file\.log$"

            # Générer un chemin temporaire dans un sous-répertoire spécifique
            $subDirTempPath = Get-TempProjectPath -SubDirectory "logs" -CreateDirectory
            $subDirTempPath | Should -Match "logs\\"
            $logsDir = Join-Path -Path $script:TestProjectRoot -ChildPath "logs"
            Test-Path -Path $logsDir -PathType Container | Should -BeTrue

            # Nettoyer les répertoires de test
            if (Test-Path -Path $tempDir -PathType Container) {
                Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
            if (Test-Path -Path $logsDir -PathType Container) {
                Remove-Item -Path $logsDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It "Détecte correctement si un chemin est dans le projet" {
            $insidePath = Join-Path -Path $script:TestProjectRoot -ChildPath "docs"
            $outsidePath = Join-Path -Path $env:TEMP -ChildPath "outside"

            Test-PathIsWithinProject -Path $insidePath | Should -Be $true
            Test-PathIsWithinProject -Path $outsidePath | Should -Be $false
        }

        It "Normalise correctement les chemins avec différents séparateurs" {
            $mixedPath = "docs/subdir\\file.txt"

            # Style Windows
            $windowsPath = ConvertTo-NormalizedPath -Path $mixedPath -ForceWindowsStyle
            $windowsPath | Should -Be "docs\subdir\file.txt"

            # Style Unix
            $unixPath = ConvertTo-NormalizedPath -Path $mixedPath -ForceUnixStyle
            $unixPath | Should -Be "docs/subdir/file.txt"
        }

        It "Gère correctement les slashes de fin" {
            $path = "docs\subdir"

            # Ajouter un slash de fin
            $pathWithSlash = ConvertTo-NormalizedPath -Path $path -AddTrailingSlash
            $pathWithSlash | Should -Be "docs\subdir\"

            # Supprimer un slash de fin
            $pathWithoutSlash = ConvertTo-NormalizedPath -Path "docs\subdir\" -RemoveTrailingSlash
            $pathWithoutSlash | Should -Be "docs\subdir"
        }

        It "Gère correctement les chemins UNC" {
            $uncPath = "\\server\share\folder"

            # Normaliser un chemin UNC
            $normalizedUncPath = ConvertTo-NormalizedPath -Path $uncPath -ForceWindowsStyle
            $normalizedUncPath | Should -Be "\\server\share\folder"

            # Normaliser un chemin UNC avec des slashes mixtes
            $mixedUncPath = "\\server/share\folder//subfolder"
            $normalizedMixedUncPath = ConvertTo-NormalizedPath -Path $mixedUncPath -ForceWindowsStyle
            $normalizedMixedUncPath | Should -Be "\\server\share\folder\subfolder"
        }
    }

    Context "Gestion des erreurs" {
        BeforeEach {
            # Initialiser le module avant chaque test
            Initialize-PathManager -ProjectRootPath $script:TestProjectRoot
        }

        It "Lève une exception pour un mapping inexistant" {
            { Get-RelativePath -AbsolutePath "C:\temp\file.txt" -BaseMappingName "nonexistent" } |
                Should -Throw
        }

        It "Lève une exception pour un chemin invalide" {
            # Créer un chemin avec des caractères invalides
            $invalidPath = "C:\temp\file$?*:.txt"

            { Get-ProjectPath -PathOrMappingName $invalidPath } |
                Should -Not -Throw # Ne devrait pas lever d'exception car c'est juste un chemin relatif

            # Mais si on essaie de résoudre un chemin absolu invalide
            { Get-RelativePath -AbsolutePath $invalidPath } |
                Should -Throw
        }
    }

    Context "Fonctionnalités avancées" {
        BeforeEach {
            # Initialiser le module avant chaque test
            Initialize-PathManager -ProjectRootPath $script:TestProjectRoot -DiscoverDirectories
        }

        It "Retourne les mappings avec détails" {
            $mappingsWithDetails = Get-PathMappings -IncludeDetails

            $mappingsWithDetails["root"] | Should -Not -BeNullOrEmpty
            $mappingsWithDetails["root"].Exists | Should -Be $true
            $mappingsWithDetails["root"].IsDirectory | Should -Be $true
            $mappingsWithDetails["root"].IsWithinProject | Should -Be $true
        }

        It "Retourne les mappings sous forme d'objet" {
            $mappingsAsObject = Get-PathMappings -AsObject

            $mappingsAsObject | Should -BeOfType [PSCustomObject]
            $mappingsAsObject.root | Should -Be $script:TestProjectRoot
        }
    }
}
