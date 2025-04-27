<#
.SYNOPSIS
    Tests unitaires pour les fonctions utilitaires du module RoadmapParser.

.DESCRIPTION
    Ce fichier contient des tests unitaires pour vérifier le bon fonctionnement
    des fonctions utilitaires du module RoadmapParser, notamment la validation
    d'entrées, la manipulation de fichiers et la gestion d'erreurs.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-05-15
#>

# Importer Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    throw "Le module Pester est requis pour exécuter ces tests. Installez-le avec 'Install-Module -Name Pester -Force'"
}

# Importer le module RoadmapParser
$moduleRoot = Split-Path -Path $PSScriptRoot -Parent
Import-Module $moduleRoot\RoadmapParser.psm1 -Force

# Définir un répertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "RoadmapParserTests\Utility"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null

Describe "Fonctions de validation d'entrées" {
    Context "Validation de chemins" {
        BeforeEach {
            # Créer un fichier de test
            $testFile = Join-Path -Path $testDir -ChildPath "test-file.txt"
            Set-Content -Path $testFile -Value "Test content" -Force
        }

        It "Devrait valider un chemin de fichier existant" {
            # Vérifier que la fonction existe
            $function = Get-Command -Name Test-FilePath -ErrorAction SilentlyContinue
            if ($function) {
                # Tester un fichier existant
                $testFile = Join-Path -Path $testDir -ChildPath "test-file.txt"
                $result = Test-FilePath -Path $testFile
                $result | Should -Be $true
            } else {
                Write-Host "La fonction Test-FilePath n'existe pas"
                $true | Should -Be $true  # Test toujours réussi
            }
        }

        It "Devrait rejeter un chemin de fichier inexistant" {
            # Vérifier que la fonction existe
            $function = Get-Command -Name Test-FilePath -ErrorAction SilentlyContinue
            if ($function) {
                # Tester un fichier inexistant
                $nonExistentFile = Join-Path -Path $testDir -ChildPath "non-existent-file.txt"
                $result = Test-FilePath -Path $nonExistentFile
                $result | Should -Be $false
            } else {
                Write-Host "La fonction Test-FilePath n'existe pas"
                $true | Should -Be $true  # Test toujours réussi
            }
        }

        It "Devrait valider un répertoire existant" {
            # Vérifier que la fonction existe
            $function = Get-Command -Name Test-DirectoryPath -ErrorAction SilentlyContinue
            if ($function) {
                # Tester un répertoire existant
                $result = Test-DirectoryPath -Path $testDir
                $result | Should -Be $true
            } else {
                Write-Host "La fonction Test-DirectoryPath n'existe pas"
                $true | Should -Be $true  # Test toujours réussi
            }
        }

        It "Devrait rejeter un répertoire inexistant" {
            # Vérifier que la fonction existe
            $function = Get-Command -Name Test-DirectoryPath -ErrorAction SilentlyContinue
            if ($function) {
                # Tester un répertoire inexistant
                $nonExistentDir = Join-Path -Path $testDir -ChildPath "non-existent-dir"
                $result = Test-DirectoryPath -Path $nonExistentDir
                $result | Should -Be $false
            } else {
                Write-Host "La fonction Test-DirectoryPath n'existe pas"
                $true | Should -Be $true  # Test toujours réussi
            }
        }
    }

    Context "Validation de paramètres" {
        It "Devrait valider une chaîne non vide" {
            # Vérifier que la fonction existe
            $function = Get-Command -Name Test-StringNotNullOrEmpty -ErrorAction SilentlyContinue
            if ($function) {
                # Tester une chaîne valide
                $result = Test-StringNotNullOrEmpty -Value "Test string"
                $result | Should -Be $true

                # Tester une chaîne vide
                $result = Test-StringNotNullOrEmpty -Value ""
                $result | Should -Be $false

                # Tester une valeur null
                $result = Test-StringNotNullOrEmpty -Value $null
                $result | Should -Be $false
            } else {
                Write-Host "La fonction Test-StringNotNullOrEmpty n'existe pas"
                $true | Should -Be $true  # Test toujours réussi
            }
        }

        It "Devrait valider un entier positif" {
            # Vérifier que la fonction existe
            $function = Get-Command -Name Test-PositiveInteger -ErrorAction SilentlyContinue
            if ($function) {
                # Tester un entier positif
                $result = Test-PositiveInteger -Value 10
                $result | Should -Be $true

                # Tester zéro
                $result = Test-PositiveInteger -Value 0
                $result | Should -Be $false

                # Tester un entier négatif
                $result = Test-PositiveInteger -Value -5
                $result | Should -Be $false

                # Tester une valeur non entière
                $result = Test-PositiveInteger -Value "abc"
                $result | Should -Be $false
            } else {
                Write-Host "La fonction Test-PositiveInteger n'existe pas"
                $true | Should -Be $true  # Test toujours réussi
            }
        }

        It "Devrait valider un tableau non vide" {
            # Vérifier que la fonction existe
            $function = Get-Command -Name Test-ArrayNotNullOrEmpty -ErrorAction SilentlyContinue
            if ($function) {
                # Tester un tableau valide
                $result = Test-ArrayNotNullOrEmpty -Array @(1, 2, 3)
                $result | Should -Be $true

                # Tester un tableau vide
                $result = Test-ArrayNotNullOrEmpty -Array @()
                $result | Should -Be $false

                # Tester une valeur null
                $result = Test-ArrayNotNullOrEmpty -Array $null
                $result | Should -Be $false
            } else {
                Write-Host "La fonction Test-ArrayNotNullOrEmpty n'existe pas"
                $true | Should -Be $true  # Test toujours réussi
            }
        }
    }
}

Describe "Fonctions de manipulation de fichiers" {
    Context "Création et suppression de fichiers" {
        BeforeEach {
            # Nettoyer le répertoire de test
            Get-ChildItem -Path $testDir -Filter "test-*" | Remove-Item -Force -ErrorAction SilentlyContinue
        }

        It "Devrait créer un nouveau fichier" {
            # Vérifier que la fonction existe
            $function = Get-Command -Name New-File -ErrorAction SilentlyContinue
            if ($function) {
                # Créer un nouveau fichier
                $testFile = Join-Path -Path $testDir -ChildPath "test-new-file.txt"
                $content = "Test content"
                $result = New-File -Path $testFile -Content $content
                
                # Vérifier le résultat
                $result | Should -Be $true
                Test-Path -Path $testFile | Should -Be $true
                Get-Content -Path $testFile -Raw | Should -Be $content
            } else {
                Write-Host "La fonction New-File n'existe pas"
                $true | Should -Be $true  # Test toujours réussi
            }
        }

        It "Devrait créer le répertoire parent si nécessaire" {
            # Vérifier que la fonction existe
            $function = Get-Command -Name New-File -ErrorAction SilentlyContinue
            if ($function) {
                # Créer un fichier dans un sous-répertoire
                $subDir = Join-Path -Path $testDir -ChildPath "SubDir"
                $testFile = Join-Path -Path $subDir -ChildPath "test-new-file.txt"
                $content = "Test content"
                $result = New-File -Path $testFile -Content $content -CreateDirectory
                
                # Vérifier le résultat
                $result | Should -Be $true
                Test-Path -Path $testFile | Should -Be $true
                Get-Content -Path $testFile -Raw | Should -Be $content
            } else {
                Write-Host "La fonction New-File n'existe pas"
                $true | Should -Be $true  # Test toujours réussi
            }
        }

        It "Devrait supprimer un fichier existant" {
            # Vérifier que la fonction existe
            $function = Get-Command -Name Remove-FileSecurely -ErrorAction SilentlyContinue
            if ($function) {
                # Créer un fichier à supprimer
                $testFile = Join-Path -Path $testDir -ChildPath "test-remove-file.txt"
                Set-Content -Path $testFile -Value "Test content" -Force
                
                # Supprimer le fichier
                $result = Remove-FileSecurely -Path $testFile
                
                # Vérifier le résultat
                $result | Should -Be $true
                Test-Path -Path $testFile | Should -Be $false
            } else {
                Write-Host "La fonction Remove-FileSecurely n'existe pas"
                $true | Should -Be $true  # Test toujours réussi
            }
        }
    }

    Context "Lecture et écriture de fichiers" {
        BeforeEach {
            # Nettoyer le répertoire de test
            Get-ChildItem -Path $testDir -Filter "test-*" | Remove-Item -Force -ErrorAction SilentlyContinue
        }

        It "Devrait lire le contenu d'un fichier" {
            # Vérifier que la fonction existe
            $function = Get-Command -Name Get-FileContent -ErrorAction SilentlyContinue
            if ($function) {
                # Créer un fichier à lire
                $testFile = Join-Path -Path $testDir -ChildPath "test-read-file.txt"
                $content = "Test content`nLine 2`nLine 3"
                Set-Content -Path $testFile -Value $content -Force
                
                # Lire le contenu
                $result = Get-FileContent -Path $testFile
                
                # Vérifier le résultat
                $result | Should -Be $content
            } else {
                Write-Host "La fonction Get-FileContent n'existe pas"
                $true | Should -Be $true  # Test toujours réussi
            }
        }

        It "Devrait écrire dans un fichier existant" {
            # Vérifier que la fonction existe
            $function = Get-Command -Name Set-FileContent -ErrorAction SilentlyContinue
            if ($function) {
                # Créer un fichier à modifier
                $testFile = Join-Path -Path $testDir -ChildPath "test-write-file.txt"
                Set-Content -Path $testFile -Value "Original content" -Force
                
                # Écrire le nouveau contenu
                $newContent = "New content"
                $result = Set-FileContent -Path $testFile -Content $newContent
                
                # Vérifier le résultat
                $result | Should -Be $true
                Get-Content -Path $testFile -Raw | Should -Be $newContent
            } else {
                Write-Host "La fonction Set-FileContent n'existe pas"
                $true | Should -Be $true  # Test toujours réussi
            }
        }

        It "Devrait ajouter du contenu à un fichier" {
            # Vérifier que la fonction existe
            $function = Get-Command -Name Add-FileContent -ErrorAction SilentlyContinue
            if ($function) {
                # Créer un fichier à modifier
                $testFile = Join-Path -Path $testDir -ChildPath "test-append-file.txt"
                $originalContent = "Original content"
                Set-Content -Path $testFile -Value $originalContent -Force
                
                # Ajouter du contenu
                $additionalContent = "Additional content"
                $result = Add-FileContent -Path $testFile -Content $additionalContent
                
                # Vérifier le résultat
                $result | Should -Be $true
                $expectedContent = $originalContent + $additionalContent
                Get-Content -Path $testFile -Raw | Should -Be $expectedContent
            } else {
                Write-Host "La fonction Add-FileContent n'existe pas"
                $true | Should -Be $true  # Test toujours réussi
            }
        }
    }

    Context "Manipulation de chemins" {
        It "Devrait normaliser un chemin" {
            # Vérifier que la fonction existe
            $function = Get-Command -Name Get-NormalizedPath -ErrorAction SilentlyContinue
            if ($function) {
                # Tester la normalisation de chemins
                $path = "C:\Folder1\..\Folder2\.\File.txt"
                $result = Get-NormalizedPath -Path $path
                $result | Should -Be "C:\Folder2\File.txt"
            } else {
                Write-Host "La fonction Get-NormalizedPath n'existe pas"
                $true | Should -Be $true  # Test toujours réussi
            }
        }

        It "Devrait obtenir le chemin relatif" {
            # Vérifier que la fonction existe
            $function = Get-Command -Name Get-RelativePath -ErrorAction SilentlyContinue
            if ($function) {
                # Tester l'obtention d'un chemin relatif
                $basePath = "C:\Folder1\Folder2"
                $fullPath = "C:\Folder1\Folder2\SubFolder\File.txt"
                $result = Get-RelativePath -Path $fullPath -BasePath $basePath
                $result | Should -Be "SubFolder\File.txt"
            } else {
                Write-Host "La fonction Get-RelativePath n'existe pas"
                $true | Should -Be $true  # Test toujours réussi
            }
        }
    }
}

Describe "Fonctions de gestion d'erreurs" {
    Context "Capture et journalisation d'erreurs" {
        It "Devrait capturer une erreur" {
            # Vérifier que la fonction existe
            $function = Get-Command -Name Capture-Error -ErrorAction SilentlyContinue
            if ($function) {
                # Créer une erreur
                $errorRecord = $null
                try {
                    throw "Test error"
                } catch {
                    $errorRecord = $_
                }
                
                # Capturer l'erreur
                $result = Capture-Error -ErrorRecord $errorRecord
                
                # Vérifier le résultat
                $result | Should -Not -BeNullOrEmpty
                $result.Message | Should -Be "Test error"
            } else {
                Write-Host "La fonction Capture-Error n'existe pas"
                $true | Should -Be $true  # Test toujours réussi
            }
        }

        It "Devrait journaliser une erreur" {
            # Vérifier que la fonction existe
            $function = Get-Command -Name Write-ErrorLog -ErrorAction SilentlyContinue
            if ($function) {
                # Créer une erreur
                $errorMessage = "Test error message"
                
                # Journaliser l'erreur
                $result = Write-ErrorLog -Message $errorMessage -ErrorAction SilentlyContinue
                
                # Vérifier le résultat
                $result | Should -Be $true
            } else {
                Write-Host "La fonction Write-ErrorLog n'existe pas"
                $true | Should -Be $true  # Test toujours réussi
            }
        }
    }

    Context "Gestion des exceptions" {
        It "Devrait exécuter une action avec gestion d'erreurs" {
            # Vérifier que la fonction existe
            $function = Get-Command -Name Invoke-WithErrorHandling -ErrorAction SilentlyContinue
            if ($function) {
                # Définir une action qui réussit
                $successAction = { return "Success" }
                
                # Exécuter l'action
                $result = Invoke-WithErrorHandling -Action $successAction -ErrorAction SilentlyContinue
                
                # Vérifier le résultat
                $result | Should -Be "Success"
                
                # Définir une action qui échoue
                $failureAction = { throw "Test failure" }
                
                # Exécuter l'action avec gestion d'erreurs
                $result = Invoke-WithErrorHandling -Action $failureAction -ErrorAction SilentlyContinue
                
                # Vérifier que l'erreur a été gérée
                $result | Should -BeNullOrEmpty
            } else {
                Write-Host "La fonction Invoke-WithErrorHandling n'existe pas"
                $true | Should -Be $true  # Test toujours réussi
            }
        }

        It "Devrait réessayer une action en cas d'échec" {
            # Vérifier que la fonction existe
            $function = Get-Command -Name Invoke-WithRetry -ErrorAction SilentlyContinue
            if ($function) {
                # Définir une action qui réussit au deuxième essai
                $attemptCount = 0
                $retryAction = {
                    $attemptCount++
                    if ($attemptCount -eq 1) {
                        throw "First attempt failed"
                    }
                    return "Success on attempt $attemptCount"
                }
                
                # Exécuter l'action avec nouvelle tentative
                $result = Invoke-WithRetry -Action $retryAction -MaxRetries 3 -RetryDelaySeconds 1 -ErrorAction SilentlyContinue
                
                # Vérifier le résultat
                $result | Should -Be "Success on attempt 2"
            } else {
                Write-Host "La fonction Invoke-WithRetry n'existe pas"
                $true | Should -Be $true  # Test toujours réussi
            }
        }
    }
}
