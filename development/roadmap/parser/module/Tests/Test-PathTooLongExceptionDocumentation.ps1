<#
.SYNOPSIS
    Tests pour valider la documentation de PathTooLongException et ses limites.

.DESCRIPTION
    Ce script contient des tests unitaires pour valider les exemples et les informations
    fournies dans la documentation de PathTooLongException et ses limites.

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
Describe "Tests de la documentation de PathTooLongException et ses limites" {
    Context "PathTooLongException" {
        It "Devrait Ãªtre une sous-classe de IOException" {
            [System.IO.PathTooLongException] | Should -BeOfType [System.Type]
            [System.IO.PathTooLongException].IsSubclassOf([System.IO.IOException]) | Should -Be $true
        }
        
        It "Devrait permettre de spÃ©cifier un message" {
            $exception = [System.IO.PathTooLongException]::new("Message de test")
            $exception.Message | Should -Be "Message de test"
        }
        
        It "Exemple 1: Devrait crÃ©er un chemin trop long" {
            function New-LongPath {
                param (
                    [int]$Length = 300
                )
                
                # CrÃ©er un chemin de base dans le rÃ©pertoire temporaire
                $basePath = [System.IO.Path]::GetTempPath()
                
                # Calculer la longueur nÃ©cessaire pour le nom de fichier
                $baseLength = $basePath.Length
                $fileNameLength = $Length - $baseLength - 1  # -1 pour le sÃ©parateur
                
                # CrÃ©er un nom de fichier de la longueur requise
                $fileName = "A" * $fileNameLength + ".txt"
                
                # Construire le chemin complet
                $longPath = [System.IO.Path]::Combine($basePath, $fileName)
                
                return @{
                    Path = $longPath
                    Length = $longPath.Length
                    BaseLength = $baseLength
                    FileNameLength = $fileNameLength
                }
            }
            
            # CrÃ©er un chemin qui dÃ©passe la limite standard de Windows (260 caractÃ¨res)
            $result = New-LongPath -Length 300
            
            $result.Length | Should -Be 300
            $result.Path.Length | Should -Be 300
            $result.FileNameLength | Should -BeGreaterThan 0
        }
        
        It "Exemple 2: Devrait gÃ©rer la tentative d'accÃ¨s Ã  un fichier avec un chemin trop long" {
            function Get-LongPath {
                param (
                    [string]$FilePath
                )
                
                try {
                    # Tenter de crÃ©er le fichier
                    [System.IO.File]::WriteAllText($FilePath, "Test content")
                    return "Success"
                } catch [System.IO.PathTooLongException] {
                    return "PathTooLong"
                } catch {
                    return "OtherError"
                }
            }
            
            # CrÃ©er un chemin trop long
            $basePath = [System.IO.Path]::GetTempPath()
            $fileName = "A" * 260 + ".txt"  # Garantit un chemin trop long
            $longPath = [System.IO.Path]::Combine($basePath, $fileName)
            
            # Le test peut Ã©chouer si le chemin temporaire est trÃ¨s court
            # ou si le systÃ¨me supporte les chemins longs
            $result = Get-LongPath -FilePath $longPath
            $result | Should -BeIn @("PathTooLong", "OtherError")
        }
        
        It "Exemple 5: Devrait raccourcir un chemin trop long" {
            function Limit-Path {
                param (
                    [string]$LongPath,
                    [int]$MaxLength = 259
                )
                
                # Si le chemin est dÃ©jÃ  assez court, le retourner tel quel
                if ($LongPath.Length -le $MaxLength) {
                    return @{
                        Path = $LongPath
                        Shortened = $false
                    }
                }
                
                # DÃ©composer le chemin
                $directory = [System.IO.Path]::GetDirectoryName($LongPath)
                $fileName = [System.IO.Path]::GetFileName($LongPath)
                $extension = [System.IO.Path]::GetExtension($LongPath)
                $fileNameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($LongPath)
                
                # Calculer la longueur maximale pour le nom de fichier
                $maxFileNameLength = $MaxLength - $directory.Length - $extension.Length - 1  # -1 pour le sÃ©parateur
                
                # Si le nom de fichier est trop long, le tronquer
                if ($fileNameWithoutExt.Length > $maxFileNameLength) {
                    $shortenedFileName = $fileNameWithoutExt.Substring(0, $maxFileNameLength) + $extension
                    $shortenedPath = [System.IO.Path]::Combine($directory, $shortenedFileName)
                    
                    return @{
                        Path = $shortenedPath
                        Shortened = $true
                        OriginalLength = $LongPath.Length
                        NewLength = $shortenedPath.Length
                    }
                }
                
                # Si le problÃ¨me n'est pas le nom de fichier, retourner le chemin original
                return @{
                    Path = $LongPath
                    Shortened = $false
                    DirectoryTooLong = $true
                }
            }
            
            # CrÃ©er un chemin avec un nom de fichier trÃ¨s long
            $basePath = [System.IO.Path]::GetTempPath()
            $fileName = "A" * 260 + ".txt"
            $longPath = [System.IO.Path]::Combine($basePath, $fileName)
            
            $result = Limit-Path -LongPath $longPath -MaxLength 259
            
            $result.Shortened | Should -Be $true
            $result.Path.Length | Should -BeLessOrEqual 259
            $result.OriginalLength | Should -BeGreaterThan 259
        }
    }
    
    Context "PrÃ©vention des PathTooLongException" {
        It "Technique 1: Devrait valider la longueur du chemin" {
            function Test-PathLength {
                param (
                    [string]$Path,
                    [int]$MaxLength = 259
                )
                
                if ($Path.Length > $MaxLength) {
                    return $false
                }
                
                return $true
            }
            
            # Test avec un chemin court
            $shortPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "test.txt")
            Test-PathLength -Path $shortPath | Should -Be $true
            
            # Test avec un chemin long
            $longFileName = "A" * 260 + ".txt"
            $longPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), $longFileName)
            Test-PathLength -Path $longPath | Should -Be $false
        }
        
        It "Technique 2: Devrait utiliser des chemins relatifs courts" {
            function Invoke-RelativePath {
                param (
                    [string]$BasePath,
                    [string]$TargetPath
                )
                
                # Obtenir le chemin relatif
                $relativePath = [System.IO.Path]::GetRelativePath($BasePath, $TargetPath)
                
                return @{
                    AbsolutePath = $TargetPath
                    RelativePath = $relativePath
                    AbsoluteLength = $TargetPath.Length
                    RelativeLength = $relativePath.Length
                }
            }
            
            # CrÃ©er un scÃ©nario oÃ¹ le chemin relatif est plus court
            $basePath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "BaseDir")
            $targetPath = [System.IO.Path]::Combine($basePath, "SubDir", "test.txt")
            
            $result = Invoke-RelativePath -BasePath $basePath -TargetPath $targetPath
            
            $result.RelativeLength | Should -BeLessThan $result.AbsoluteLength
            $result.RelativePath | Should -Be "SubDir\test.txt"
        }
        
        It "Technique 4: Devrait utiliser le prÃ©fixe \\?\ sous Windows" {
            function Invoke-ExtendedLengthPath {
                param (
                    [string]$Path
                )
                
                # VÃ©rifier si le chemin est dÃ©jÃ  prÃ©fixÃ©
                if ($Path.StartsWith("\\?\")) {
                    return $Path
                }
                
                # Convertir en chemin absolu si ce n'est pas dÃ©jÃ  le cas
                if (-not [System.IO.Path]::IsPathRooted($Path)) {
                    $Path = [System.IO.Path]::GetFullPath($Path)
                }
                
                # Ajouter le prÃ©fixe
                $extendedPath = "\\?\" + $Path
                
                return $extendedPath
            }
            
            # Test avec un chemin absolu
            $path = "C:\Windows\System32\notepad.exe"
            $extendedPath = Invoke-ExtendedLengthPath -Path $path
            $extendedPath | Should -Be "\\?\C:\Windows\System32\notepad.exe"
            
            # Test avec un chemin dÃ©jÃ  prÃ©fixÃ©
            $prefixedPath = "\\?\C:\Windows\System32\notepad.exe"
            $result = Invoke-ExtendedLengthPath -Path $prefixedPath
            $result | Should -Be $prefixedPath
        }
    }
    
    Context "DÃ©bogage des PathTooLongException" {
        It "Devrait fournir des informations de dÃ©bogage utiles" {
            function Debug-PathTooLongException {
                param (
                    [string]$Path
                )
                
                $result = @{
                    TotalLength = $Path.Length
                    Directory = [System.IO.Path]::GetDirectoryName($Path)
                    FileName = [System.IO.Path]::GetFileName($Path)
                    Extension = [System.IO.Path]::GetExtension($Path)
                    FileNameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($Path)
                    Components = $Path.Split([System.IO.Path]::DirectorySeparatorChar)
                    LongComponents = @()
                }
                
                $result.DirectoryLength = $result.Directory.Length
                $result.FileNameLength = $result.FileName.Length
                
                # Identifier les composants longs
                $longComponents = $result.Components | Where-Object { $_.Length -gt 20 }
                if ($longComponents) {
                    $result.LongComponents = $longComponents
                }
                
                # VÃ©rifier si le prÃ©fixe \\?\ pourrait aider
                $result.CouldUseLongPathPrefix = (-not $Path.StartsWith("\\?\") -and $Path.Length -gt 259 -and $Path.Length -lt 32767)
                
                return $result
            }
            
            # CrÃ©er un chemin avec des composants longs
            $longComponent = "VeryLongDirectoryNameForTesting" * 2
            $path = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), $longComponent, "test.txt")
            
            $result = Debug-PathTooLongException -Path $path
            
            $result.TotalLength | Should -Be $path.Length
            $result.FileName | Should -Be "test.txt"
            $result.Extension | Should -Be ".txt"
            $result.LongComponents.Count | Should -BeGreaterThan 0
            $result.LongComponents[0].Length | Should -BeGreaterThan 20
        }
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Script $PSCommandPath -Output Detailed


