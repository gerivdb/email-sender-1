<#
.SYNOPSIS
    Tests pour les fonctions utilitaires de gestion des chemins d'accÃ¨s.

.DESCRIPTION
    Ce script contient des tests unitaires pour les fonctions utilitaires
    de gestion des chemins d'accÃ¨s.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2025-04-25
#>

# Importer les fonctions Ã  tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".."
$pathPermissionHelperPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\PathUtils\PathPermissionHelper.ps1"
$pathResolverPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\PathUtils\PathResolver.ps1"

# DÃ©finir la variable d'environnement pour le mode test
$env:ROADMAPPARSER_TEST_MODE = "true"

# Importer les scripts directement
. $pathPermissionHelperPath
. $pathResolverPath

Describe "Fonctions de gestion des permissions des chemins" {
    Context "Test-PathPermissions" {
        BeforeAll {
            # CrÃ©er des fichiers temporaires pour les tests
            $tempDir = [System.IO.Path]::GetTempPath()
            $testDir = Join-Path -Path $tempDir -ChildPath "TestPathPermissions"
            $testFile = Join-Path -Path $testDir -ChildPath "TestFile.txt"

            # CrÃ©er le rÃ©pertoire et le fichier
            New-Item -Path $testDir -ItemType Directory -Force | Out-Null
            Set-Content -Path $testFile -Value "Test content" -Force
        }

        AfterAll {
            # Supprimer les fichiers temporaires
            Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
        }

        It "DÃ©tecte correctement un chemin existant" {
            $result = Test-PathPermissions -Path $testDir
            $result | Should -BeOfType [bool]
            $result | Should -BeTrue
        }

        It "DÃ©tecte correctement un chemin inexistant" {
            $result = Test-PathPermissions -Path (Join-Path -Path $testDir -ChildPath "NonExistentFile.txt")
            $result | Should -BeOfType [bool]
            $result | Should -BeFalse
        }

        It "Retourne des informations dÃ©taillÃ©es si demandÃ©" {
            $result = Test-PathPermissions -Path $testFile -Detailed
            $result | Should -BeOfType [PSCustomObject]
            $result.Path | Should -Be $testFile
            $result.Exists | Should -BeTrue
            $result.IsContainer | Should -BeFalse
        }

        It "Teste l'accÃ¨s en lecture si demandÃ©" {
            $result = Test-PathPermissions -Path $testFile -TestRead -Detailed
            $result.TestResults.Read | Should -BeTrue
        }

        It "Teste l'accÃ¨s en Ã©criture si demandÃ©" {
            $result = Test-PathPermissions -Path $testFile -TestWrite -Detailed
            $result.TestResults.Write | Should -BeTrue
        }
    }

    Context "Test-ReadAccess" {
        BeforeAll {
            # CrÃ©er des fichiers temporaires pour les tests
            $tempDir = [System.IO.Path]::GetTempPath()
            $testDir = Join-Path -Path $tempDir -ChildPath "TestReadAccess"
            $testFile = Join-Path -Path $testDir -ChildPath "TestFile.txt"

            # CrÃ©er le rÃ©pertoire et le fichier
            New-Item -Path $testDir -ItemType Directory -Force | Out-Null
            Set-Content -Path $testFile -Value "Test content" -Force
        }

        AfterAll {
            # Supprimer les fichiers temporaires
            Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
        }

        It "DÃ©tecte correctement l'accÃ¨s en lecture pour un fichier" {
            $result = Test-ReadAccess -Path $testFile
            $result | Should -BeTrue
        }

        It "DÃ©tecte correctement l'accÃ¨s en lecture pour un rÃ©pertoire" {
            $result = Test-ReadAccess -Path $testDir
            $result | Should -BeTrue
        }

        It "DÃ©tecte correctement l'absence d'accÃ¨s en lecture pour un chemin inexistant" {
            $result = Test-ReadAccess -Path (Join-Path -Path $testDir -ChildPath "NonExistentFile.txt")
            $result | Should -BeFalse
        }
    }

    Context "Test-WriteAccess" {
        BeforeAll {
            # CrÃ©er des fichiers temporaires pour les tests
            $tempDir = [System.IO.Path]::GetTempPath()
            $testDir = Join-Path -Path $tempDir -ChildPath "TestWriteAccess"
            $testFile = Join-Path -Path $testDir -ChildPath "TestFile.txt"

            # CrÃ©er le rÃ©pertoire et le fichier
            New-Item -Path $testDir -ItemType Directory -Force | Out-Null
            Set-Content -Path $testFile -Value "Test content" -Force
        }

        AfterAll {
            # Supprimer les fichiers temporaires
            Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
        }

        It "DÃ©tecte correctement l'accÃ¨s en Ã©criture pour un fichier" {
            $result = Test-WriteAccess -Path $testFile
            $result | Should -BeTrue
        }

        It "DÃ©tecte correctement l'accÃ¨s en Ã©criture pour un rÃ©pertoire" {
            $result = Test-WriteAccess -Path $testDir
            $result | Should -BeTrue
        }

        It "DÃ©tecte correctement l'absence d'accÃ¨s en Ã©criture pour un chemin inexistant" {
            $result = Test-WriteAccess -Path (Join-Path -Path $testDir -ChildPath "NonExistentFile.txt")
            $result | Should -BeFalse
        }
    }
}

Describe "Fonctions de rÃ©solution des chemins" {
    Context "Resolve-RelativePath" {
        BeforeAll {
            # CrÃ©er des fichiers temporaires pour les tests
            $tempDir = [System.IO.Path]::GetTempPath()
            $testDir = Join-Path -Path $tempDir -ChildPath "TestResolveRelativePath"
            $testSubDir = Join-Path -Path $testDir -ChildPath "SubDir"
            $testFile = Join-Path -Path $testSubDir -ChildPath "TestFile.txt"

            # CrÃ©er les rÃ©pertoires et le fichier
            New-Item -Path $testDir -ItemType Directory -Force | Out-Null
            New-Item -Path $testSubDir -ItemType Directory -Force | Out-Null
            Set-Content -Path $testFile -Value "Test content" -Force
        }

        AfterAll {
            # Supprimer les fichiers temporaires
            Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
        }

        It "RÃ©sout correctement un chemin relatif" {
            $result = Resolve-RelativePath -Path "SubDir\TestFile.txt" -BasePath $testDir
            $result | Should -Be $testFile
        }

        It "Retourne un chemin absolu tel quel" {
            $result = Resolve-RelativePath -Path $testFile -BasePath $testDir
            $result | Should -Be $testFile
        }

        It "Retourne null pour un chemin inexistant avec vÃ©rification" {
            $result = Resolve-RelativePath -Path "NonExistentFile.txt" -BasePath $testDir -VerifyExists
            $result | Should -BeNullOrEmpty
        }
    }

    Context "Resolve-AbsolutePath" {
        BeforeAll {
            # CrÃ©er des fichiers temporaires pour les tests
            $tempDir = [System.IO.Path]::GetTempPath()
            $testDir = Join-Path -Path $tempDir -ChildPath "TestResolveAbsolutePath"
            $testSubDir = Join-Path -Path $testDir -ChildPath "SubDir"
            $testFile = Join-Path -Path $testSubDir -ChildPath "TestFile.txt"

            # CrÃ©er les rÃ©pertoires et le fichier
            New-Item -Path $testDir -ItemType Directory -Force | Out-Null
            New-Item -Path $testSubDir -ItemType Directory -Force | Out-Null
            Set-Content -Path $testFile -Value "Test content" -Force
        }

        AfterAll {
            # Supprimer les fichiers temporaires
            Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
        }

        It "RÃ©sout correctement un chemin absolu en chemin relatif" {
            $result = Resolve-AbsolutePath -Path $testFile -BasePath $testDir
            $result | Should -Be "SubDir\TestFile.txt"
        }

        It "Retourne le chemin absolu si le chemin n'est pas sous le chemin de base" {
            $result = Resolve-AbsolutePath -Path $testFile -BasePath $tempDir
            $result | Should -Be $testFile
        }

        It "Retourne null pour un chemin inexistant avec vÃ©rification" {
            $nonExistentFile = Join-Path -Path $testDir -ChildPath "NonExistentFile.txt"
            $result = Resolve-AbsolutePath -Path $nonExistentFile -BasePath $testDir -VerifyExists
            $result | Should -BeNullOrEmpty
        }
    }

    Context "Normalize-Path" {
        It "Normalise correctement un chemin avec des barres obliques" {
            $result = Normalize-Path -Path "C:/Temp/Test/File.txt"
            $result | Should -Be "C:\Temp\Test\File.txt"
        }

        It "Normalise correctement un chemin avec des barres obliques inverses consÃ©cutives" {
            $result = Normalize-Path -Path "C:\\Temp\\\\Test\\File.txt"
            $result | Should -Be "C:\Temp\Test\File.txt"
        }

        It "Normalise correctement un chemin avec des points simples" {
            $result = Normalize-Path -Path "C:\Temp\.\Test\.\File.txt"
            $result | Should -Be "C:\Temp\Test\File.txt"
        }

        It "Normalise correctement un chemin avec des points doubles" {
            $result = Normalize-Path -Path "C:\Temp\Test\..\File.txt"
            $result | Should -Be "C:\Temp\File.txt"
        }

        It "Supprime correctement la barre oblique inverse finale" {
            $result = Normalize-Path -Path "C:\Temp\Test\"
            $result | Should -Be "C:\Temp\Test"
        }
    }

    Context "Find-ProjectRoot" {
        BeforeAll {
            # CrÃ©er des fichiers temporaires pour les tests
            $tempDir = [System.IO.Path]::GetTempPath()
            $testDir = Join-Path -Path $tempDir -ChildPath "TestFindProjectRoot"
            $testSubDir = Join-Path -Path $testDir -ChildPath "SubDir"
            $testSubSubDir = Join-Path -Path $testSubDir -ChildPath "SubSubDir"
            $gitDir = Join-Path -Path $testDir -ChildPath ".git"

            # CrÃ©er les rÃ©pertoires
            New-Item -Path $testDir -ItemType Directory -Force | Out-Null
            New-Item -Path $testSubDir -ItemType Directory -Force | Out-Null
            New-Item -Path $testSubSubDir -ItemType Directory -Force | Out-Null
            New-Item -Path $gitDir -ItemType Directory -Force | Out-Null
        }

        AfterAll {
            # Supprimer les fichiers temporaires
            Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
        }

        It "Trouve correctement le rÃ©pertoire racine du projet" {
            $result = Find-ProjectRoot -StartPath $testSubSubDir
            $result | Should -Be $testDir
        }

        It "Retourne le chemin de dÃ©part si aucun marqueur n'est trouvÃ©" {
            $result = Find-ProjectRoot -StartPath $testSubSubDir -Markers @("non-existent-marker")
            $result | Should -Be $testSubSubDir
        }

        It "Respecte la profondeur maximale" {
            $result = Find-ProjectRoot -StartPath $testSubSubDir -MaxDepth 1
            $result | Should -Be $testSubDir
        }
    }
}
