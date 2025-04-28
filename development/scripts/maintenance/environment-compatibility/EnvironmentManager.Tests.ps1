<#
.SYNOPSIS
    Tests unitaires pour le module EnvironmentManager.

.DESCRIPTION
    Ce script contient des tests unitaires pour le module EnvironmentManager
    en utilisant le framework Pester.

.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date crÃ©ation:  09/04/2025
    PrÃ©requis:      Pester 5.0 ou supÃ©rieur
#>

# VÃ©rifier si Pester est installÃ©
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# DÃ©finir le chemin du module Ã  tester
$moduleRoot = $PSScriptRoot
$modulePath = Join-Path -Path $moduleRoot -ChildPath "EnvironmentManager.psm1"

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testRoot = Join-Path -Path $env:TEMP -ChildPath "EnvironmentManagerTests"
if (Test-Path -Path $testRoot) {
    Remove-Item -Path $testRoot -Recurse -Force
}
New-Item -Path $testRoot -ItemType Directory -Force | Out-Null

# DÃ©finir les tests Pester
Describe "Module EnvironmentManager" {
    BeforeAll {
        # Importer le module Ã  tester
        Import-Module $modulePath -Force

        # Initialiser le module
        Initialize-EnvironmentManager
    }

    Context "Initialisation du module" {
        It "Devrait initialiser le module avec succÃ¨s" {
            $result = Initialize-EnvironmentManager -Force
            $result | Should -BeNullOrEmpty
        }
    }

    Context "DÃ©tection d'environnement" {
        It "Devrait dÃ©tecter l'environnement d'exÃ©cution" {
            $envInfo = Get-EnvironmentInfo
            $envInfo | Should -Not -BeNullOrEmpty
            $envInfo.PSVersion | Should -Be $PSVersionTable.PSVersion
        }

        It "Devrait dÃ©tecter correctement Windows" {
            $envInfo = Get-EnvironmentInfo
            if ($PSVersionTable.PSVersion.Major -lt 6) {
                $envInfo.IsWindows | Should -BeTrue
                $envInfo.IsLinux | Should -BeFalse
                $envInfo.IsMacOS | Should -BeFalse
            }
            elseif ($IsWindows) {
                $envInfo.IsWindows | Should -BeTrue
                $envInfo.IsLinux | Should -BeFalse
                $envInfo.IsMacOS | Should -BeFalse
            }
            elseif ($IsLinux) {
                $envInfo.IsWindows | Should -BeFalse
                $envInfo.IsLinux | Should -BeTrue
                $envInfo.IsMacOS | Should -BeFalse
            }
            elseif ($IsMacOS) {
                $envInfo.IsWindows | Should -BeFalse
                $envInfo.IsLinux | Should -BeFalse
                $envInfo.IsMacOS | Should -BeTrue
            }
        }
    }

    Context "CompatibilitÃ© d'environnement" {
        It "Devrait vÃ©rifier la compatibilitÃ© avec Windows" {
            $result = Test-EnvironmentCompatibility -TargetOS "Windows"
            $result | Should -Not -BeNullOrEmpty
            $result.IsCompatible | Should -BeOfType [bool]
        }

        It "Devrait vÃ©rifier la compatibilitÃ© avec Linux" {
            $result = Test-EnvironmentCompatibility -TargetOS "Linux"
            $result | Should -Not -BeNullOrEmpty
            $result.IsCompatible | Should -BeOfType [bool]
        }

        It "Devrait vÃ©rifier la compatibilitÃ© avec macOS" {
            $result = Test-EnvironmentCompatibility -TargetOS "MacOS"
            $result | Should -Not -BeNullOrEmpty
            $result.IsCompatible | Should -BeOfType [bool]
        }

        It "Devrait vÃ©rifier la compatibilitÃ© avec une version PowerShell" {
            $result = Test-EnvironmentCompatibility -MinimumPSVersion "5.0"
            $result | Should -Not -BeNullOrEmpty
            $result.PSVersionCompatible | Should -BeOfType [bool]
        }

        It "Devrait lancer une exception si demandÃ©" {
            # CrÃ©er une version incompatible
            $incompatibleVersion = [version]"99.0"
            { Test-EnvironmentCompatibility -MinimumPSVersion $incompatibleVersion -ThrowOnIncompatible } | Should -Throw
        }
    }

    Context "Gestion des chemins" {
        It "Devrait normaliser un chemin Windows" {
            $path = "C:\Users\user\Documents\file.txt"
            $result = ConvertTo-CrossPlatformPath -Path $path -TargetOS "Windows"
            $result | Should -Be "C:\Users\user\Documents\file.txt"
        }

        It "Devrait normaliser un chemin Unix" {
            $path = "C:\Users\user\Documents\file.txt"
            $result = ConvertTo-CrossPlatformPath -Path $path -TargetOS "Linux"
            $result | Should -Be "C:/Users/user/Documents/file.txt"
        }

        It "Devrait normaliser un chemin avec des sÃ©parateurs mixtes" {
            $path = "C:\Users/user\Documents/file.txt"
            $result = ConvertTo-CrossPlatformPath -Path $path -TargetOS "Windows"
            $result | Should -Be "C:\Users\user\Documents\file.txt"
        }

        It "Devrait retourner une chaÃ®ne vide pour un chemin vide" {
            $result = ConvertTo-CrossPlatformPath -Path "" -TargetOS "Windows"
            $result | Should -Be ""
        }
    }

    Context "Test de chemins" {
        BeforeAll {
            # CrÃ©er un fichier de test
            $testFilePath = Join-Path -Path $testRoot -ChildPath "test.txt"
            Set-Content -Path $testFilePath -Value "Test" -Force

            # CrÃ©er un rÃ©pertoire de test
            $testDirPath = Join-Path -Path $testRoot -ChildPath "testdir"
            New-Item -Path $testDirPath -ItemType Directory -Force | Out-Null
        }

        It "Devrait vÃ©rifier si un fichier existe" {
            $testFilePath = Join-Path -Path $testRoot -ChildPath "test.txt"
            $result = Test-CrossPlatformPath -Path $testFilePath -PathType "Leaf"
            $result | Should -BeTrue
        }

        It "Devrait vÃ©rifier si un rÃ©pertoire existe" {
            $testDirPath = Join-Path -Path $testRoot -ChildPath "testdir"
            $result = Test-CrossPlatformPath -Path $testDirPath -PathType "Container"
            $result | Should -BeTrue
        }

        It "Devrait retourner False pour un chemin inexistant" {
            $nonExistentPath = Join-Path -Path $testRoot -ChildPath "nonexistent.txt"
            $result = Test-CrossPlatformPath -Path $nonExistentPath
            $result | Should -BeFalse
        }

        It "Devrait retourner False pour un chemin vide" {
            $result = Test-CrossPlatformPath -Path ""
            $result | Should -BeFalse
        }
    }

    Context "Jointure de chemins" {
        It "Devrait joindre des chemins Windows" {
            $result = Join-CrossPlatformPath -Path "C:\Users" -ChildPath "user", "Documents", "file.txt" -TargetOS "Windows"
            $result | Should -Be "C:\Users\user\Documents\file.txt"
        }

        It "Devrait joindre des chemins Unix" {
            $result = Join-CrossPlatformPath -Path "/home" -ChildPath "user", "documents", "file.txt" -TargetOS "Linux"
            $result | Should -Be "/home/user/documents/file.txt"
        }

        It "Devrait gÃ©rer les sÃ©parateurs redondants" {
            $result = Join-CrossPlatformPath -Path "C:\Users\" -ChildPath "\user", "\Documents\", "file.txt" -TargetOS "Windows"
            $result | Should -Be "C:\Users\user\Documents\file.txt"
        }

        It "Devrait retourner une chaÃ®ne vide pour un chemin vide" {
            $result = Join-CrossPlatformPath -Path "" -ChildPath "user"
            $result | Should -Be ""
        }
    }

    Context "Wrappers de commandes" {
        It "Devrait retourner la commande Windows sur Windows" {
            $windowsCommand = "dir"
            $unixCommand = "ls -la"
            $result = Invoke-CrossPlatformCommand -WindowsCommand $windowsCommand -UnixCommand $unixCommand -PassThru

            if ($PSVersionTable.PSVersion.Major -lt 6 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)) {
                $result | Should -Be $windowsCommand
            }
            else {
                $result | Should -Be $unixCommand
            }
        }

        It "Devrait retourner la commande macOS sur macOS" {
            $windowsCommand = "dir"
            $unixCommand = "ls -la"
            $macOSCommand = "ls -la -G"
            $result = Invoke-CrossPlatformCommand -WindowsCommand $windowsCommand -UnixCommand $unixCommand -MacOSCommand $macOSCommand -PassThru

            if ($PSVersionTable.PSVersion.Major -lt 6 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)) {
                $result | Should -Be $windowsCommand
            }
            elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS) {
                $result | Should -Be $macOSCommand
            }
            else {
                $result | Should -Be $unixCommand
            }
        }
    }

    Context "Lecture et Ã©criture de fichiers" {
        BeforeAll {
            # CrÃ©er un fichier de test
            $script:testFilePath = Join-Path -Path $testRoot -ChildPath "content-test.txt"
            $script:testContent = "Test de contenu`nLigne 2`nLigne 3"
        }

        It "Devrait Ã©crire dans un fichier" {
            $result = Set-CrossPlatformContent -Path $testFilePath -Content $testContent -Force
            $result | Should -BeTrue
            Test-Path -Path $testFilePath | Should -BeTrue
        }

        It "Devrait lire le contenu d'un fichier" {
            $content = Get-CrossPlatformContent -Path $testFilePath
            $content.TrimEnd() | Should -Be $testContent.TrimEnd()
        }

        It "Devrait retourner une chaÃ®ne vide pour un fichier inexistant" {
            $nonExistentPath = Join-Path -Path $testRoot -ChildPath "nonexistent.txt"
            $content = Get-CrossPlatformContent -Path $nonExistentPath
            $content | Should -Be ""
        }

        It "Devrait retourner False pour une Ã©criture dans un fichier inexistant sans Force" {
            $nonExistentPath = Join-Path -Path $testRoot -ChildPath "nonexistent2.txt"
            $result = Set-CrossPlatformContent -Path $nonExistentPath -Content "Test"
            $result | Should -BeFalse
        }
    }

    AfterAll {
        # Nettoyer
        Remove-Module -Name EnvironmentManager -Force -ErrorAction SilentlyContinue

        # Supprimer le rÃ©pertoire de test
        if (Test-Path -Path $testRoot) {
            Remove-Item -Path $testRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Path $PSCommandPath -Output Detailed
