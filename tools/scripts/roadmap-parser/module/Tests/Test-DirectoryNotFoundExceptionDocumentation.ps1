<#
.SYNOPSIS
    Tests pour valider la documentation de DirectoryNotFoundException et ses contextes.

.DESCRIPTION
    Ce script contient des tests unitaires pour valider les exemples et les informations
    fournies dans la documentation de DirectoryNotFoundException et ses contextes.

.NOTES
    Version:        1.0
    Author:         Augment Code
    Creation Date:  2023-06-17
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Définir les tests
Describe "Tests de la documentation de DirectoryNotFoundException et ses contextes" {
    Context "DirectoryNotFoundException" {
        It "Devrait être une sous-classe de IOException" {
            [System.IO.DirectoryNotFoundException] | Should -BeOfType [System.Type]
            [System.IO.DirectoryNotFoundException].IsSubclassOf([System.IO.IOException]) | Should -Be $true
        }
        
        It "Devrait permettre de spécifier un message" {
            $exception = [System.IO.DirectoryNotFoundException]::new("Message de test")
            $exception.Message | Should -Be "Message de test"
        }
        
        It "Exemple 1: Devrait gérer l'accès à un fichier dans un répertoire inexistant" {
            function Access-FileInNonExistentDirectory {
                param (
                    [string]$FilePath
                )
                
                try {
                    $content = [System.IO.File]::ReadAllText($FilePath)
                    return "Success"
                } catch [System.IO.DirectoryNotFoundException] {
                    return "DirectoryNotFound"
                } catch [System.IO.FileNotFoundException] {
                    return "FileNotFound"
                } catch {
                    return "OtherError"
                }
            }
            
            # Test avec un fichier dans un répertoire inexistant
            $nonExistentDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "dossier_inexistant_" + [Guid]::NewGuid().ToString())
            $fileInNonExistentDir = [System.IO.Path]::Combine($nonExistentDir, "fichier.txt")
            
            Access-FileInNonExistentDirectory -FilePath $fileInNonExistentDir | Should -Be "DirectoryNotFound"
        }
        
        It "Exemple 2: Devrait créer un répertoire s'il n'existe pas" {
            function Create-DirectoryIfNotExists {
                param (
                    [string]$DirectoryPath
                )
                
                try {
                    # Tenter d'obtenir les informations sur le répertoire
                    $dirInfo = [System.IO.DirectoryInfo]::new($DirectoryPath)
                    $files = $dirInfo.GetFiles()
                    return "DirectoryExists"
                } catch [System.IO.DirectoryNotFoundException] {
                    try {
                        [System.IO.Directory]::CreateDirectory($DirectoryPath) | Out-Null
                        return "DirectoryCreated"
                    } catch {
                        return "CreationError"
                    }
                } catch {
                    return "OtherError"
                }
            }
            
            # Test avec un répertoire inexistant
            $tempDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "test_dir_" + [Guid]::NewGuid().ToString())
            Create-DirectoryIfNotExists -DirectoryPath $tempDir | Should -Be "DirectoryCreated"
            
            # Test avec un répertoire existant
            Create-DirectoryIfNotExists -DirectoryPath $tempDir | Should -Be "DirectoryExists"
            
            # Nettoyer
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        It "Exemple 3: Devrait gérer l'accès à un lecteur ou partage réseau inexistant" {
            function Access-NonExistentDrive {
                param (
                    [string]$DrivePath
                )
                
                try {
                    $files = [System.IO.Directory]::GetFiles($DrivePath)
                    return "Success"
                } catch [System.IO.DirectoryNotFoundException] {
                    return "DirectoryNotFound"
                } catch {
                    return "OtherError"
                }
            }
            
            # Test avec un lecteur inexistant (ajustez la lettre de lecteur selon votre système)
            # Nous utilisons Z: car c'est rarement utilisé, mais cela pourrait échouer si Z: existe
            Access-NonExistentDrive -DrivePath "Z:\Documents" | Should -BeIn @("DirectoryNotFound", "OtherError")
        }
        
        It "Exemple 4: Devrait vérifier récursivement l'existence des répertoires parents" {
            function Verify-DirectoryPath {
                param (
                    [string]$Path
                )
                
                $result = @{
                    Exists = $false
                    MissingParts = @()
                    FullPath = [System.IO.Path]::GetFullPath($Path)
                }
                
                # Vérifier si le chemin existe déjà
                if ([System.IO.Directory]::Exists($Path)) {
                    $result.Exists = $true
                    return $result
                }
                
                # Décomposer le chemin et vérifier chaque partie
                $parts = $result.FullPath.Split([System.IO.Path]::DirectorySeparatorChar)
                $currentPath = ""
                
                # Construire le chemin progressivement et vérifier chaque partie
                for ($i = 0; $i -lt $parts.Length; $i++) {
                    $part = $parts[$i]
                    
                    # Ignorer les parties vides (comme après le séparateur de lecteur)
                    if ([string]::IsNullOrEmpty($part)) {
                        continue
                    }
                    
                    # Ajouter le séparateur de lecteur pour le premier élément sous Windows
                    if ($i -eq 0 -and $part.EndsWith(":")) {
                        $currentPath = $part + [System.IO.Path]::DirectorySeparatorChar
                    } else {
                        # Pour les autres parties, ajouter le séparateur et la partie
                        if (-not [string]::IsNullOrEmpty($currentPath)) {
                            $currentPath = [System.IO.Path]::Combine($currentPath, $part)
                        } else {
                            $currentPath = $part
                        }
                    }
                    
                    # Vérifier si cette partie du chemin existe
                    if (-not [System.IO.Directory]::Exists($currentPath)) {
                        $result.MissingParts += $currentPath
                    }
                }
                
                return $result
            }
            
            # Test avec un chemin à plusieurs niveaux
            $deepPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "level1", "level2", "level3")
            $verificationResult = Verify-DirectoryPath -Path $deepPath
            
            $verificationResult.Exists | Should -Be $false
            $verificationResult.MissingParts.Count | Should -BeGreaterThan 0
        }
        
        It "Exemple 5: Devrait créer récursivement des répertoires" {
            function Create-DirectoryRecursively {
                param (
                    [string]$Path
                )
                
                try {
                    # CreateDirectory crée automatiquement tous les répertoires parents nécessaires
                    $dirInfo = [System.IO.Directory]::CreateDirectory($Path)
                    return $true
                } catch {
                    return $false
                }
            }
            
            # Test avec un chemin à plusieurs niveaux
            $deepPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "level1", "level2", "level3")
            
            # Supprimer le répertoire s'il existe déjà
            $level1 = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "level1")
            if ([System.IO.Directory]::Exists($level1)) {
                Remove-Item -Path $level1 -Recurse -Force
            }
            
            # Créer les répertoires
            Create-DirectoryRecursively -Path $deepPath | Should -Be $true
            
            # Vérifier que tous les répertoires ont été créés
            $level2 = [System.IO.Path]::Combine($level1, "level2")
            $level3 = [System.IO.Path]::Combine($level2, "level3")
            
            [System.IO.Directory]::Exists($level1) | Should -Be $true
            [System.IO.Directory]::Exists($level2) | Should -Be $true
            [System.IO.Directory]::Exists($level3) | Should -Be $true
            
            # Nettoyer
            Remove-Item -Path $level1 -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    
    Context "Différence entre DirectoryNotFoundException et FileNotFoundException" {
        It "Devrait distinguer entre DirectoryNotFoundException et FileNotFoundException" {
            function Test-FileVsDirectoryNotFound {
                param (
                    [string]$Path
                )
                
                try {
                    [System.IO.File]::ReadAllText($Path)
                    return "Success"
                } catch [System.IO.DirectoryNotFoundException] {
                    return "DirectoryNotFound"
                } catch [System.IO.FileNotFoundException] {
                    return "FileNotFound"
                } catch {
                    return "OtherError"
                }
            }
            
            # Créer un répertoire temporaire pour le test
            $tempDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "test_dir")
            [System.IO.Directory]::CreateDirectory($tempDir) | Out-Null
            
            # Cas 1: Fichier inexistant dans un répertoire existant
            $nonExistentFile = [System.IO.Path]::Combine($tempDir, "fichier_inexistant.txt")
            Test-FileVsDirectoryNotFound -Path $nonExistentFile | Should -Be "FileNotFound"
            
            # Cas 2: Fichier dans un répertoire inexistant
            $nonExistentDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "dossier_inexistant")
            $fileInNonExistentDir = [System.IO.Path]::Combine($nonExistentDir, "fichier.txt")
            Test-FileVsDirectoryNotFound -Path $fileInNonExistentDir | Should -Be "DirectoryNotFound"
            
            # Nettoyer
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    
    Context "Prévention des DirectoryNotFoundException" {
        It "Technique 1: Devrait vérifier l'existence du répertoire" {
            function Ensure-DirectoryExists {
                param (
                    [string]$DirectoryPath
                )
                
                if (-not [System.IO.Directory]::Exists($DirectoryPath)) {
                    return "DirectoryNotFound"
                }
                
                return "DirectoryExists"
            }
            
            # Créer un répertoire temporaire pour le test
            $tempDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "test_dir")
            [System.IO.Directory]::CreateDirectory($tempDir) | Out-Null
            
            # Test avec un répertoire existant
            Ensure-DirectoryExists -DirectoryPath $tempDir | Should -Be "DirectoryExists"
            
            # Test avec un répertoire inexistant
            $nonExistentDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "dossier_inexistant")
            Ensure-DirectoryExists -DirectoryPath $nonExistentDir | Should -Be "DirectoryNotFound"
            
            # Nettoyer
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        It "Technique 2: Devrait créer le répertoire s'il n'existe pas" {
            function Create-DirectoryIfNotExists {
                param (
                    [string]$DirectoryPath
                )
                
                $result = @{
                    Created = $false
                    Exists = $false
                }
                
                if (-not [System.IO.Directory]::Exists($DirectoryPath)) {
                    try {
                        [System.IO.Directory]::CreateDirectory($DirectoryPath) | Out-Null
                        $result.Created = $true
                    } catch {
                        return $result
                    }
                }
                
                $result.Exists = [System.IO.Directory]::Exists($DirectoryPath)
                return $result
            }
            
            # Test avec un répertoire inexistant
            $tempDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "test_dir")
            
            # Supprimer le répertoire s'il existe déjà
            if ([System.IO.Directory]::Exists($tempDir)) {
                Remove-Item -Path $tempDir -Recurse -Force
            }
            
            $result1 = Create-DirectoryIfNotExists -DirectoryPath $tempDir
            $result1.Created | Should -Be $true
            $result1.Exists | Should -Be $true
            
            # Test avec un répertoire existant
            $result2 = Create-DirectoryIfNotExists -DirectoryPath $tempDir
            $result2.Created | Should -Be $false
            $result2.Exists | Should -Be $true
            
            # Nettoyer
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        It "Technique 3: Devrait utiliser des chemins absolus" {
            function Get-AbsoluteDirectoryPath {
                param (
                    [string]$RelativePath
                )
                
                return [System.IO.Path]::GetFullPath($RelativePath)
            }
            
            # Test avec un chemin relatif
            $relativePath = "test_dir"
            $absolutePath = Get-AbsoluteDirectoryPath -RelativePath $relativePath
            
            $absolutePath | Should -Not -Be $relativePath
            [System.IO.Path]::IsPathRooted($absolutePath) | Should -Be $true
        }
        
        It "Technique 4: Devrait vérifier la disponibilité des lecteurs et partages réseau" {
            function Check-DriveAvailability {
                param (
                    [string]$DrivePath
                )
                
                # Extraire la lettre de lecteur ou le nom de partage réseau
                $root = [System.IO.Path]::GetPathRoot($DrivePath)
                
                if ([string]::IsNullOrEmpty($root)) {
                    return "InvalidPath"
                }
                
                # Vérifier si le lecteur ou le partage réseau existe
                if (-not [System.IO.Directory]::Exists($root)) {
                    return "DriveNotFound"
                }
                
                return "DriveAvailable"
            }
            
            # Test avec un lecteur existant (C: devrait exister sur la plupart des systèmes Windows)
            Check-DriveAvailability -DrivePath "C:\Windows" | Should -Be "DriveAvailable"
            
            # Test avec un lecteur inexistant (Z: est rarement utilisé)
            # Cela pourrait échouer si Z: existe sur le système de test
            Check-DriveAvailability -DrivePath "Z:\Documents" | Should -BeIn @("DriveNotFound", "DriveAvailable")
            
            # Test avec un chemin invalide
            Check-DriveAvailability -DrivePath "InvalidPath" | Should -Be "InvalidPath"
        }
        
        It "Technique 5: Devrait utiliser des méthodes qui créent automatiquement les répertoires parents" {
            function Write-FileWithDirectoryCreation {
                param (
                    [string]$FilePath,
                    [string]$Content
                )
                
                $result = @{
                    Success = $false
                    DirectoryCreated = $false
                    FileWritten = $false
                }
                
                try {
                    # Extraire le répertoire parent
                    $directory = [System.IO.Path]::GetDirectoryName($FilePath)
                    
                    # Créer le répertoire parent s'il n'existe pas
                    if (-not [string]::IsNullOrEmpty($directory) -and -not [System.IO.Directory]::Exists($directory)) {
                        [System.IO.Directory]::CreateDirectory($directory) | Out-Null
                        $result.DirectoryCreated = $true
                    }
                    
                    # Écrire le fichier
                    [System.IO.File]::WriteAllText($FilePath, $Content)
                    $result.FileWritten = $true
                    $result.Success = $true
                } catch {
                    # Ne rien faire, le résultat indique déjà l'échec
                }
                
                return $result
            }
            
            # Test avec un fichier dans un répertoire inexistant
            $tempDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "test_dir")
            $tempFile = [System.IO.Path]::Combine($tempDir, "test_file.txt")
            
            # Supprimer le répertoire s'il existe déjà
            if ([System.IO.Directory]::Exists($tempDir)) {
                Remove-Item -Path $tempDir -Recurse -Force
            }
            
            $result = Write-FileWithDirectoryCreation -FilePath $tempFile -Content "Test content"
            $result.Success | Should -Be $true
            $result.DirectoryCreated | Should -Be $true
            $result.FileWritten | Should -Be $true
            
            # Vérifier que le fichier a été créé
            [System.IO.File]::Exists($tempFile) | Should -Be $true
            [System.IO.File]::ReadAllText($tempFile) | Should -Be "Test content"
            
            # Nettoyer
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    
    Context "Débogage des DirectoryNotFoundException" {
        It "Devrait fournir des informations de débogage utiles" {
            function Debug-DirectoryNotFoundException {
                param (
                    [string]$Path
                )
                
                $result = @{
                    IsAbsolute = [System.IO.Path]::IsPathRooted($Path)
                    AbsolutePath = [System.IO.Path]::GetFullPath($Path)
                    PathExists = [System.IO.Directory]::Exists($Path)
                    PathParts = @()
                    RootExists = $false
                }
                
                if (-not $result.PathExists) {
                    # Décomposer le chemin et vérifier chaque partie
                    $parts = $result.AbsolutePath.Split([System.IO.Path]::DirectorySeparatorChar)
                    $currentPath = ""
                    
                    for ($i = 0; $i -lt $parts.Length; $i++) {
                        $part = $parts[$i]
                        
                        # Ignorer les parties vides
                        if ([string]::IsNullOrEmpty($part)) {
                            continue
                        }
                        
                        # Construire le chemin progressivement
                        if ($i -eq 0 -and $part.EndsWith(":")) {
                            $currentPath = $part + [System.IO.Path]::DirectorySeparatorChar
                        } else {
                            if (-not [string]::IsNullOrEmpty($currentPath)) {
                                $currentPath = [System.IO.Path]::Combine($currentPath, $part)
                            } else {
                                $currentPath = $part
                            }
                        }
                        
                        # Vérifier si cette partie du chemin existe
                        $exists = [System.IO.Directory]::Exists($currentPath)
                        $result.PathParts += @{
                            Path = $currentPath
                            Exists = $exists
                        }
                    }
                    
                    # Vérifier si le lecteur ou partage réseau existe
                    $root = [System.IO.Path]::GetPathRoot($Path)
                    $result.RootExists = [System.IO.Directory]::Exists($root)
                }
                
                return $result
            }
            
            # Test avec un répertoire existant
            $existingDir = [System.IO.Path]::GetTempPath()
            $result1 = Debug-DirectoryNotFoundException -Path $existingDir
            $result1.PathExists | Should -Be $true
            
            # Test avec un répertoire inexistant
            $nonExistentDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "dossier_inexistant")
            $result2 = Debug-DirectoryNotFoundException -Path $nonExistentDir
            $result2.PathExists | Should -Be $false
            $result2.PathParts.Count | Should -BeGreaterThan 0
            $result2.RootExists | Should -Be $true
        }
    }
}

# Exécuter les tests
Invoke-Pester -Script $PSCommandPath -Output Detailed
