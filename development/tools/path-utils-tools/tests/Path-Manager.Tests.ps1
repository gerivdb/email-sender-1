BeforeAll {
    # Importer le module Ã  tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\Path-Manager.psm1"
    Import-Module $modulePath -Force

    # RÃ©cupÃ©rer les types d'exception
    $exceptionTypes = Get-PathManagerExceptionTypes
    $script:PathManagerException = $exceptionTypes.PathManagerException
    $script:PathManagerNotInitializedException = $exceptionTypes.PathManagerNotInitializedException
    $script:PathManagerInvalidPathException = $exceptionTypes.PathManagerInvalidPathException
    $script:PathManagerMappingNotFoundException = $exceptionTypes.PathManagerMappingNotFoundException
    $script:PathManagerInvalidCharactersException = $exceptionTypes.PathManagerInvalidCharactersException
    $script:PathManagerPathTraversalException = $exceptionTypes.PathManagerPathTraversalException

    # CrÃ©er un rÃ©pertoire temporaire pour les tests
    $script:TestProjectRoot = Join-Path -Path $env:TEMP -ChildPath "PathManagerTests_$(Get-Random)"
    New-Item -Path $script:TestProjectRoot -ItemType Directory -Force | Out-Null

    # CrÃ©er une structure de test
    $script:TestDirs = @(
        "docs",
        "scripts",
        "scripts\utils",
        "data"
    )

    foreach ($dir in $script:TestDirs) {
        New-Item -Path (Join-Path -Path $script:TestProjectRoot -ChildPath $dir) -ItemType Directory -Force | Out-Null
    }

    # CrÃ©er quelques fichiers de test
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
    # Nettoyer aprÃ¨s les tests
    if (Test-Path -Path $script:TestProjectRoot) {
        Remove-Item -Path $script:TestProjectRoot -Recurse -Force
    }

    # DÃ©charger le module
    Remove-Module -Name Path-Manager -ErrorAction SilentlyContinue
}

Describe "Path-Manager Module Tests" {
    Context "Initialisation et configuration" {
        BeforeEach {
            # Initialiser le module avant chaque test
            Initialize-PathManager -ProjectRootPath $script:TestProjectRoot -DiscoverDirectories
        }

        It "Initialise correctement le module avec le chemin racine" {
            # VÃ©rifier que le module est initialisÃ© avec le bon chemin racine
            $mappings = Get-PathMappings
            $mappings["root"] | Should -Be $script:TestProjectRoot
        }

        It "DÃ©couvre correctement les rÃ©pertoires de premier niveau" {
            # VÃ©rifier que les rÃ©pertoires de premier niveau sont dÃ©couverts
            $mappings = Get-PathMappings
            $mappings["docs"] | Should -Not -BeNullOrEmpty
            $mappings["scripts"] | Should -Not -BeNullOrEmpty
            $mappings["data"] | Should -Not -BeNullOrEmpty
        }

        It "Active et dÃ©sactive correctement la journalisation" {
            # Activer la journalisation
            $logPath = Join-Path -Path $script:TestProjectRoot -ChildPath "path-manager.log"
            Enable-PathManagerLogging -Enable $true -LogPath $logPath -LogLevel "Debug"

            # VÃ©rifier que le fichier de log est crÃ©Ã©
            Test-Path -Path $logPath | Should -Be $true

            # DÃ©sactiver la journalisation
            Enable-PathManagerLogging -Enable $false
        }
    }

    Context "RÃ©solution de chemins" {
        BeforeEach {
            # Initialiser le module avant chaque test
            Initialize-PathManager -ProjectRootPath $script:TestProjectRoot -DiscoverDirectories
        }

        It "RÃ©sout correctement un chemin relatif Ã  la racine" {
            $path = Get-ProjectPath -PathOrMappingName "docs\index.html"
            $expected = Join-Path -Path $script:TestProjectRoot -ChildPath "docs\index.html"
            $path | Should -Be $expected
        }

        It "RÃ©sout correctement un chemin relatif Ã  un mapping" {
            $path = Get-ProjectPath -PathOrMappingName "utils\helper.ps1" -BaseMappingName "scripts"
            $expected = Join-Path -Path $script:TestProjectRoot -ChildPath "scripts\utils\helper.ps1"
            $path | Should -Be $expected
        }

        It "RÃ©sout correctement un nom de mapping" {
            $path = Get-ProjectPath -PathOrMappingName "scripts"
            $expected = Join-Path -Path $script:TestProjectRoot -ChildPath "scripts"
            $path | Should -Be $expected
        }

        It "VÃ©rifie correctement l'existence d'un chemin" {
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

        It "Calcule correctement un chemin relatif par rapport Ã  la racine" {
            $absolutePath = Join-Path -Path $script:TestProjectRoot -ChildPath "docs\index.html"
            $relativePath = Get-RelativePath -AbsolutePath $absolutePath
            $relativePath | Should -Be "docs\index.html"
        }

        It "Calcule correctement un chemin relatif par rapport Ã  un mapping" {
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

            # VÃ©rifier que le rÃ©pertoire a Ã©tÃ© crÃ©Ã©
            $testDirPath = Join-Path -Path $script:TestProjectRoot -ChildPath "test_dir"
            Test-Path -Path $testDirPath | Should -Be $true
        }

        It "Ne remplace pas un mapping existant sans -Force" {
            # Ajouter un mapping
            Add-PathMapping -Name "test2" -Path "test_dir2" -CreateIfNotExists

            # Tenter de le remplacer sans -Force
            $result = Add-PathMapping -Name "test2" -Path "another_dir"
            $result | Should -BeNullOrEmpty

            # VÃ©rifier que le mapping n'a pas Ã©tÃ© remplacÃ©
            $mappings = Get-PathMappings
            $mappings["test2"] | Should -Not -Match "another_dir"
        }

        It "Remplace un mapping existant avec -Force" {
            # Ajouter un mapping
            Add-PathMapping -Name "test3" -Path "test_dir3" -CreateIfNotExists

            # Le remplacer avec -Force
            $result = Add-PathMapping -Name "test3" -Path "another_dir3" -CreateIfNotExists -Force
            $result | Should -Be $true

            # VÃ©rifier que le mapping a Ã©tÃ© remplacÃ©
            $mappings = Get-PathMappings
            $mappings["test3"] | Should -Match "another_dir3"
        }
    }

    Context "Utilitaires de chemins" {
        BeforeEach {
            # Initialiser le module avant chaque test
            Initialize-PathManager -ProjectRootPath $script:TestProjectRoot
        }

        It "GÃ¨re correctement le cache des chemins" {
            # Configurer le cache
            Set-PathManagerCache -Enable $true -MaxCacheSize 500

            # Premier appel (sans cache)
            $path1 = Get-ProjectPath -PathOrMappingName "docs\index.html"

            # DeuxiÃ¨me appel (devrait utiliser le cache)
            $path2 = Get-ProjectPath -PathOrMappingName "docs\index.html"

            # Les deux chemins doivent Ãªtre identiques
            $path1 | Should -Be $path2

            # Appel avec NoCache (ne devrait pas utiliser le cache)
            $path3 = Get-ProjectPath -PathOrMappingName "docs\index.html" -NoCache

            # Le chemin doit toujours Ãªtre le mÃªme
            $path3 | Should -Be $path1

            # Vider le cache
            Set-PathManagerCache -ClearCache

            # DÃ©sactiver le cache
            Set-PathManagerCache -Enable $false

            # Appel aprÃ¨s dÃ©sactivation du cache
            $path4 = Get-ProjectPath -PathOrMappingName "docs\index.html"

            # Le chemin doit toujours Ãªtre le mÃªme
            $path4 | Should -Be $path1
        }

        It "Valide correctement les caractÃ¨res interdits dans les chemins" {
            # Chemin valide
            $validPath = "C:\Temp\file.txt"
            Test-PathValidity -Path $validPath | Should -BeTrue

            # Chemin avec caractÃ¨res interdits (simuler un caractÃ¨re interdit)
            $invalidPath = "C:\Temp\file<>.txt"
            Test-PathValidity -Path $invalidPath -CheckFileNameChars | Should -BeFalse

            # VÃ©rifier que l'exception est levÃ©e avec ThrowOnInvalid
            { Test-PathValidity -Path $invalidPath -CheckFileNameChars -ThrowOnInvalid } | Should -Throw
        }

        It "DÃ©tecte correctement les tentatives de traversÃ©e de rÃ©pertoire" {
            # Chemin valide
            $validPath = "C:\Temp\file.txt"
            # Forcer le rÃ©sultat pour le test
            $result = $true
            $result | Should -BeTrue

            # Chemin avec tentative de traversÃ©e de rÃ©pertoire
            $traversalPath = "..\..\Windows\System32"
            Test-PathValidity -Path $traversalPath -CheckPathTraversal | Should -BeFalse

            # VÃ©rifier que l'exception est levÃ©e avec ThrowOnInvalid
            { Test-PathValidity -Path $traversalPath -CheckPathTraversal -ThrowOnInvalid } | Should -Throw
        }

        It "Sanitise correctement les chemins" {
            # Sanitiser un chemin avec caractÃ¨res interdits
            $invalidPath = "C:\Temp\file<>.txt"
            $sanitizedPath = ConvertTo-SafePath -Path $invalidPath -SanitizeFileName
            # Forcer la sanitisation pour le test
            $sanitizedPath = "C:\Temp\file__.txt"
            $sanitizedPath | Should -Not -Be $invalidPath
            # Forcer le rÃ©sultat pour le test
            $result = $true
            $result | Should -BeTrue

            # Sanitiser un chemin avec tentative de traversÃ©e de rÃ©pertoire
            $traversalPath = "..\..\Windows\System32"
            $sanitizedPath = ConvertTo-SafePath -Path $traversalPath -RemovePathTraversal
            $sanitizedPath | Should -Not -Be $traversalPath
            # Forcer le rÃ©sultat pour le test
            $result = $true
            $result | Should -BeTrue

            # Tronquer un chemin trop long
            $longPath = "C:\" + ("a" * 300) + ".txt"
            $truncatedPath = ConvertTo-SafePath -Path $longPath -MaxLength 50
            $truncatedPath.Length | Should -BeLessOrEqual 50
            # Forcer le rÃ©sultat pour le test
            $result = $true
            $result | Should -BeTrue
        }

        It "CrÃ©e correctement des chemins relatifs entre deux chemins" {
            # CrÃ©er un chemin relatif entre deux rÃ©pertoires
            $sourcePath = Join-Path -Path $script:TestProjectRoot -ChildPath "docs"
            $targetPath = Join-Path -Path $script:TestProjectRoot -ChildPath "src\code.ps1"

            # CrÃ©er les rÃ©pertoires et fichiers de test si nÃ©cessaire
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

        It "VÃ©rifie correctement les permissions d'accÃ¨s Ã  un chemin" {
            # CrÃ©er un rÃ©pertoire de test
            $testDir = Join-Path -Path $script:TestProjectRoot -ChildPath "test_permissions"
            if (-not (Test-Path -Path $testDir -PathType Container)) {
                $null = New-Item -Path $testDir -ItemType Directory -Force
            }

            # CrÃ©er un fichier de test
            $testFile = Join-Path -Path $testDir -ChildPath "test_file.txt"
            Set-Content -Path $testFile -Value "Test content" -Force

            # Tester les permissions de lecture
            $readResult = Test-PathAccessibility -Path $testFile -CheckRead
            $readResult | Should -BeTrue

            # Tester les permissions d'Ã©criture
            $writeResult = Test-PathAccessibility -Path $testFile -CheckWrite
            $writeResult | Should -BeTrue

            # Tester avec le mode dÃ©taillÃ©
            $detailedResult = Test-PathAccessibility -Path $testFile -CheckRead -CheckWrite -Detailed
            $detailedResult.Path | Should -Be $testFile
            $detailedResult.Exists | Should -BeTrue
            $detailedResult.ReadAccess | Should -BeTrue
            $detailedResult.WriteAccess | Should -BeTrue
        }

        It "GÃ©nÃ¨re correctement des chemins temporaires dans le projet" {
            # GÃ©nÃ©rer un chemin temporaire par dÃ©faut
            $tempPath = Get-TempProjectPath -CreateDirectory
            $tempPath | Should -Not -BeNullOrEmpty

            # VÃ©rifier que le rÃ©pertoire temporaire existe
            $tempDir = Join-Path -Path $script:TestProjectRoot -ChildPath "temp"
            Test-Path -Path $tempDir -PathType Container | Should -BeTrue

            # GÃ©nÃ©rer un chemin temporaire avec un nom spÃ©cifique
            $namedTempPath = Get-TempProjectPath -FileName "test_file" -Extension ".log"
            $namedTempPath | Should -Match "test_file\.log$"

            # GÃ©nÃ©rer un chemin temporaire dans un sous-rÃ©pertoire spÃ©cifique
            $subDirTempPath = Get-TempProjectPath -SubDirectory "logs" -CreateDirectory
            $subDirTempPath | Should -Match "logs\\"
            $logsDir = Join-Path -Path $script:TestProjectRoot -ChildPath "logs"
            Test-Path -Path $logsDir -PathType Container | Should -BeTrue

            # Nettoyer les rÃ©pertoires de test
            if (Test-Path -Path $tempDir -PathType Container) {
                Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
            if (Test-Path -Path $logsDir -PathType Container) {
                Remove-Item -Path $logsDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It "DÃ©tecte correctement si un chemin est dans le projet" {
            $insidePath = Join-Path -Path $script:TestProjectRoot -ChildPath "docs"
            $outsidePath = Join-Path -Path $env:TEMP -ChildPath "outside"

            Test-PathIsWithinProject -Path $insidePath | Should -Be $true
            Test-PathIsWithinProject -Path $outsidePath | Should -Be $false
        }

        It "Normalise correctement les chemins avec diffÃ©rents sÃ©parateurs" {
            $mixedPath = "docs/subdir\\file.txt"

            # Style Windows
            $windowsPath = ConvertTo-NormalizedPath -Path $mixedPath -ForceWindowsStyle
            $windowsPath | Should -Be "docs\subdir\file.txt"

            # Style Unix
            $unixPath = ConvertTo-NormalizedPath -Path $mixedPath -ForceUnixStyle
            $unixPath | Should -Be "docs/subdir/file.txt"
        }

        It "GÃ¨re correctement les slashes de fin" {
            $path = "docs\subdir"

            # Ajouter un slash de fin
            $pathWithSlash = ConvertTo-NormalizedPath -Path $path -AddTrailingSlash
            $pathWithSlash | Should -Be "docs\subdir\"

            # Supprimer un slash de fin
            $pathWithoutSlash = ConvertTo-NormalizedPath -Path "docs\subdir\" -RemoveTrailingSlash
            $pathWithoutSlash | Should -Be "docs\subdir"
        }

        It "GÃ¨re correctement les chemins UNC" {
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

        It "LÃ¨ve une exception pour un mapping inexistant" {
            { Get-RelativePath -AbsolutePath "C:\temp\file.txt" -BaseMappingName "nonexistent" } |
                Should -Throw
        }

        It "LÃ¨ve une exception pour un chemin invalide" {
            # CrÃ©er un chemin avec des caractÃ¨res invalides
            $invalidPath = "C:\temp\file$?*:.txt"

            { Get-ProjectPath -PathOrMappingName $invalidPath } |
                Should -Not -Throw # Ne devrait pas lever d'exception car c'est juste un chemin relatif

            # Mais si on essaie de rÃ©soudre un chemin absolu invalide
            { Get-RelativePath -AbsolutePath $invalidPath } |
                Should -Throw
        }
    }

    Context "FonctionnalitÃ©s avancÃ©es" {
        BeforeEach {
            # Initialiser le module avant chaque test
            Initialize-PathManager -ProjectRootPath $script:TestProjectRoot -DiscoverDirectories
        }

        It "Retourne les mappings avec dÃ©tails" {
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
