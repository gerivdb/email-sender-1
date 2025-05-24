<#
.SYNOPSIS
    Tests pour valider la documentation de FileNotFoundException et ses dÃ©tails.

.DESCRIPTION
    Ce script contient des tests unitaires pour valider les exemples et les informations
    fournies dans la documentation de FileNotFoundException et ses dÃ©tails.

.NOTES
    Version:        1.0
    Author:         Augment Code
    Creation Date:  2023-06-17
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# DÃ©finir les tests
Describe "Tests de la documentation de FileNotFoundException et ses dÃ©tails" {
    Context "FileNotFoundException" {
        It "Devrait Ãªtre une sous-classe de IOException" {
            [System.IO.FileNotFoundException] | Should -BeOfType [System.Type]
            [System.IO.FileNotFoundException].IsSubclassOf([System.IO.IOException]) | Should -Be $true
        }
        
        It "Devrait avoir les propriÃ©tÃ©s FileName et FusionLog" {
            $exception = [System.IO.FileNotFoundException]::new("Message de test", "test.txt")
            $exception.FileName | Should -Be "test.txt"
            $exception | Get-Member -Name FusionLog | Should -Not -BeNullOrEmpty
        }
        
        It "Exemple 1: Devrait gÃ©rer la lecture d'un fichier inexistant" {
            function Read-NonExistentFile {
                param (
                    [string]$FilePath
                )
                
                try {
                    $content = [System.IO.File]::ReadAllText($FilePath)
                    return $content
                } catch [System.IO.FileNotFoundException] {
                    return "FileNotFound: $($_.Exception.FileName)"
                }
            }
            
            Read-NonExistentFile -FilePath "C:\fichier_inexistant.txt" | Should -Be "FileNotFound: C:\fichier_inexistant.txt"
        }
        
        It "Exemple 3: Devrait vÃ©rifier l'existence d'un fichier avant de l'ouvrir" {
            function Open-FileWithCheck {
                param (
                    [string]$FilePath
                )
                
                if (-not [System.IO.File]::Exists($FilePath)) {
                    return "FileNotFound"
                }
                
                try {
                    $content = [System.IO.File]::ReadAllText($FilePath)
                    return $content
                } catch {
                    return "OtherError"
                }
            }
            
            # CrÃ©er un fichier temporaire pour le test
            $tempFile = [System.IO.Path]::GetTempFileName()
            [System.IO.File]::WriteAllText($tempFile, "Contenu de test")
            
            # Test avec un fichier existant
            Open-FileWithCheck -FilePath $tempFile | Should -Be "Contenu de test"
            
            # Test avec un fichier inexistant
            Open-FileWithCheck -FilePath "C:\fichier_inexistant.txt" | Should -Be "FileNotFound"
            
            # Nettoyer
            Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
        }
        
        It "Exemple 4: Devrait crÃ©er un fichier s'il n'existe pas" {
            function Get-OrCreateFile {
                param (
                    [string]$FilePath,
                    [string]$DefaultContent = ""
                )
                
                try {
                    return [System.IO.File]::ReadAllText($FilePath)
                } catch [System.IO.FileNotFoundException] {
                    [System.IO.File]::WriteAllText($FilePath, $DefaultContent)
                    return "Created: $DefaultContent"
                } catch {
                    return "OtherError"
                }
            }
            
            $tempPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "test_file.txt")
            
            # Supprimer le fichier s'il existe dÃ©jÃ 
            if ([System.IO.File]::Exists($tempPath)) {
                Remove-Item -Path $tempPath -Force
            }
            
            # PremiÃ¨re appel - le fichier n'existe pas
            Get-OrCreateFile -FilePath $tempPath -DefaultContent "Contenu par dÃ©faut" | Should -Be "Created: Contenu par dÃ©faut"
            
            # VÃ©rifier que le fichier a Ã©tÃ© crÃ©Ã©
            [System.IO.File]::Exists($tempPath) | Should -Be $true
            
            # Nettoyer
            Remove-Item -Path $tempPath -Force -ErrorAction SilentlyContinue
        }
    }
    
    Context "DiffÃ©rence entre FileNotFoundException et DirectoryNotFoundException" {
        It "Devrait distinguer entre FileNotFoundException et DirectoryNotFoundException" {
            function Test-FileVsDirectoryNotFound {
                param (
                    [string]$Path,
                    [bool]$DirectoryShouldExist
                )
                
                try {
                    [System.IO.File]::ReadAllText($Path)
                    return "Success"
                } catch [System.IO.FileNotFoundException] {
                    return "FileNotFound"
                } catch [System.IO.DirectoryNotFoundException] {
                    return "DirectoryNotFound"
                } catch {
                    return "OtherError"
                }
            }
            
            # CrÃ©er un rÃ©pertoire temporaire pour le test
            $tempDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "test_dir")
            [System.IO.Directory]::CreateDirectory($tempDir) | Out-Null
            
            # Cas 1: Fichier inexistant dans un rÃ©pertoire existant
            $nonExistentFile = [System.IO.Path]::Combine($tempDir, "fichier_inexistant.txt")
            Test-FileVsDirectoryNotFound -Path $nonExistentFile -DirectoryShouldExist $true | Should -Be "FileNotFound"
            
            # Cas 2: Fichier dans un rÃ©pertoire inexistant
            $nonExistentDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "dossier_inexistant")
            $fileInNonExistentDir = [System.IO.Path]::Combine($nonExistentDir, "fichier.txt")
            Test-FileVsDirectoryNotFound -Path $fileInNonExistentDir -DirectoryShouldExist $false | Should -Be "DirectoryNotFound"
            
            # Nettoyer
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    
    Context "PrÃ©vention des FileNotFoundException" {
        It "Technique 1: Devrait vÃ©rifier l'existence du fichier avant de l'ouvrir" {
            function Read-FileIfExists {
                param (
                    [string]$FilePath
                )
                
                if (-not [System.IO.File]::Exists($FilePath)) {
                    return "FileNotFound"
                }
                
                return "FileExists"
            }
            
            # CrÃ©er un fichier temporaire pour le test
            $tempFile = [System.IO.Path]::GetTempFileName()
            
            # Test avec un fichier existant
            Read-FileIfExists -FilePath $tempFile | Should -Be "FileExists"
            
            # Test avec un fichier inexistant
            Read-FileIfExists -FilePath "C:\fichier_inexistant.txt" | Should -Be "FileNotFound"
            
            # Nettoyer
            Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
        }
        
        It "Technique 2: Devrait crÃ©er le fichier s'il n'existe pas" {
            function Confirm-FileExists {
                param (
                    [string]$FilePath,
                    [string]$DefaultContent = ""
                )
                
                $result = @{
                    Created = $false
                    Content = $null
                }
                
                if (-not [System.IO.File]::Exists($FilePath)) {
                    # VÃ©rifier si le rÃ©pertoire parent existe
                    $directory = [System.IO.Path]::GetDirectoryName($FilePath)
                    if (-not [System.IO.Directory]::Exists($directory)) {
                        [System.IO.Directory]::CreateDirectory($directory) | Out-Null
                    }
                    
                    # CrÃ©er le fichier avec le contenu par dÃ©faut
                    [System.IO.File]::WriteAllText($FilePath, $DefaultContent)
                    $result.Created = $true
                }
                
                $result.Content = [System.IO.File]::ReadAllText($FilePath)
                return $result
            }
            
            $tempPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "test_dir", "test_file.txt")
            
            # Supprimer le fichier et le rÃ©pertoire s'ils existent dÃ©jÃ 
            if ([System.IO.File]::Exists($tempPath)) {
                Remove-Item -Path $tempPath -Force
            }
            if ([System.IO.Directory]::Exists([System.IO.Path]::GetDirectoryName($tempPath))) {
                Remove-Item -Path ([System.IO.Path]::GetDirectoryName($tempPath)) -Recurse -Force
            }
            
            # Premier appel - le fichier n'existe pas
            $result1 = Confirm-FileExists -FilePath $tempPath -DefaultContent "Contenu par dÃ©faut"
            $result1.Created | Should -Be $true
            $result1.Content | Should -Be "Contenu par dÃ©faut"
            
            # DeuxiÃ¨me appel - le fichier existe maintenant
            $result2 = Confirm-FileExists -FilePath $tempPath -DefaultContent "Nouveau contenu"
            $result2.Created | Should -Be $false
            $result2.Content | Should -Be "Contenu par dÃ©faut"  # Le contenu ne change pas
            
            # Nettoyer
            Remove-Item -Path ([System.IO.Path]::GetDirectoryName($tempPath)) -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        It "Technique 3: Devrait utiliser des chemins absolus" {
            function Get-AbsolutePath {
                param (
                    [string]$RelativePath
                )
                
                return [System.IO.Path]::GetFullPath($RelativePath)
            }
            
            # Test avec un chemin relatif
            $relativePath = "test.txt"
            $absolutePath = Get-AbsolutePath -RelativePath $relativePath
            
            $absolutePath | Should -Not -Be $relativePath
            [System.IO.Path]::IsPathRooted($absolutePath) | Should -Be $true
        }
        
        It "Technique 4: Devrait rechercher des fichiers dans plusieurs emplacements" {
            function Find-FileInMultipleLocations {
                param (
                    [string]$FileName,
                    [string[]]$SearchPaths
                )
                
                foreach ($path in $SearchPaths) {
                    $filePath = [System.IO.Path]::Combine($path, $FileName)
                    if ([System.IO.File]::Exists($filePath)) {
                        return $filePath
                    }
                }
                
                return $null
            }
            
            # CrÃ©er des fichiers temporaires pour le test
            $tempDir1 = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "test_dir1")
            $tempDir2 = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "test_dir2")
            
            [System.IO.Directory]::CreateDirectory($tempDir1) | Out-Null
            [System.IO.Directory]::CreateDirectory($tempDir2) | Out-Null
            
            $file1 = [System.IO.Path]::Combine($tempDir1, "file1.txt")
            $file2 = [System.IO.Path]::Combine($tempDir2, "file2.txt")
            
            [System.IO.File]::WriteAllText($file1, "Contenu 1")
            [System.IO.File]::WriteAllText($file2, "Contenu 2")
            
            # Test avec un fichier qui existe dans le premier rÃ©pertoire
            Find-FileInMultipleLocations -FileName "file1.txt" -SearchPaths @($tempDir1, $tempDir2) | Should -Be $file1
            
            # Test avec un fichier qui existe dans le deuxiÃ¨me rÃ©pertoire
            Find-FileInMultipleLocations -FileName "file2.txt" -SearchPaths @($tempDir1, $tempDir2) | Should -Be $file2
            
            # Test avec un fichier qui n'existe dans aucun rÃ©pertoire
            Find-FileInMultipleLocations -FileName "file3.txt" -SearchPaths @($tempDir1, $tempDir2) | Should -Be $null
            
            # Nettoyer
            Remove-Item -Path $tempDir1 -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $tempDir2 -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    
    Context "DÃ©bogage des FileNotFoundException" {
        It "Devrait fournir des informations de dÃ©bogage utiles" {
            function Debug-FileNotFoundException {
                param (
                    [string]$FilePath
                )
                
                $result = @{
                    IsAbsolute = [System.IO.Path]::IsPathRooted($FilePath)
                    AbsolutePath = [System.IO.Path]::GetFullPath($FilePath)
                    FileExists = [System.IO.File]::Exists($FilePath)
                    DirectoryExists = $false
                    ParentDirectory = ""
                }
                
                if (-not $result.FileExists) {
                    $result.ParentDirectory = [System.IO.Path]::GetDirectoryName($FilePath)
                    $result.DirectoryExists = [System.IO.Directory]::Exists($result.ParentDirectory)
                }
                
                return $result
            }
            
            # CrÃ©er un fichier temporaire pour le test
            $tempFile = [System.IO.Path]::GetTempFileName()
            
            # Test avec un fichier existant
            $result1 = Debug-FileNotFoundException -FilePath $tempFile
            $result1.FileExists | Should -Be $true
            
            # Test avec un fichier inexistant dans un rÃ©pertoire existant
            $nonExistentFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "fichier_inexistant.txt")
            $result2 = Debug-FileNotFoundException -FilePath $nonExistentFile
            $result2.FileExists | Should -Be $false
            $result2.DirectoryExists | Should -Be $true
            
            # Test avec un fichier dans un rÃ©pertoire inexistant
            $nonExistentDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "dossier_inexistant")
            $fileInNonExistentDir = [System.IO.Path]::Combine($nonExistentDir, "fichier.txt")
            $result3 = Debug-FileNotFoundException -FilePath $fileInNonExistentDir
            $result3.FileExists | Should -Be $false
            $result3.DirectoryExists | Should -Be $false
            
            # Nettoyer
            Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
        }
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Script $PSCommandPath -Output Detailed

