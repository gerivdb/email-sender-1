Describe "Gestion des donnÃ©es de test" {
    Context "Validation des chemins de donnÃ©es" {
        BeforeAll {
            # Fonction pour valider un chemin de donnÃ©es
            function Test-DataPath {
                param (
                    [string]$Path,
                    [switch]$MustExist,
                    [switch]$MustBeDirectory
                )

                if ([string]::IsNullOrEmpty($Path)) {
                    return $false
                }

                if ($MustExist -and -not (Test-Path -Path $Path)) {
                    return $false
                }

                if ($MustBeDirectory -and (Test-Path -Path $Path) -and -not (Test-Path -Path $Path -PathType Container)) {
                    return $false
                }

                return $true
            }

            # CrÃ©er des rÃ©pertoires et fichiers de test
            $testRootDir = Join-Path -Path $TestDrive -ChildPath "TestData"
            $testSubDir = Join-Path -Path $testRootDir -ChildPath "SubDir"
            $testFile = Join-Path -Path $testRootDir -ChildPath "test.txt"

            New-Item -Path $testRootDir -ItemType Directory -Force | Out-Null
            New-Item -Path $testSubDir -ItemType Directory -Force | Out-Null
            Set-Content -Path $testFile -Value "Test content" | Out-Null
        }

        It "Valide correctement un chemin existant" {
            # Tester un chemin existant
            $result = Test-DataPath -Path $testRootDir -MustExist
            $result | Should -Be $true
        }

        It "Valide correctement un chemin de rÃ©pertoire" {
            # Tester un chemin de rÃ©pertoire
            $result = Test-DataPath -Path $testRootDir -MustExist -MustBeDirectory
            $result | Should -Be $true
        }

        It "Rejette correctement un chemin de fichier quand un rÃ©pertoire est requis" {
            # Tester un chemin de fichier quand un rÃ©pertoire est requis
            $result = Test-DataPath -Path $testFile -MustExist -MustBeDirectory
            $result | Should -Be $false
        }

        It "Rejette correctement un chemin inexistant" {
            # Tester un chemin inexistant
            $nonExistentPath = Join-Path -Path $testRootDir -ChildPath "NonExistent"
            $result = Test-DataPath -Path $nonExistentPath -MustExist
            $result | Should -Be $false
        }

        It "Rejette correctement un chemin vide" {
            # Tester un chemin vide
            $result = Test-DataPath -Path "" -MustExist
            $result | Should -Be $false
        }
    }

    Context "GÃ©nÃ©ration de donnÃ©es de test" {
        BeforeAll {
            # Fonction pour gÃ©nÃ©rer des fichiers de test
            function New-TestFiles {
                param (
                    [string]$OutputPath,
                    [int]$FileCount = 10,
                    [int]$MinSize = 1KB,
                    [int]$MaxSize = 10KB
                )

                if (-not (Test-Path -Path $OutputPath -PathType Container)) {
                    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
                }

                $generatedFiles = @()

                for ($i = 1; $i -le $FileCount; $i++) {
                    $fileName = "test_file_$i.txt"
                    $filePath = Join-Path -Path $OutputPath -ChildPath $fileName

                    # GÃ©nÃ©rer une taille alÃ©atoire entre MinSize et MaxSize
                    $fileSize = Get-Random -Minimum $MinSize -Maximum $MaxSize

                    # GÃ©nÃ©rer le contenu du fichier
                    $content = "A" * $fileSize

                    # CrÃ©er le fichier
                    Set-Content -Path $filePath -Value $content | Out-Null

                    $generatedFiles += $filePath
                }

                return $generatedFiles
            }

            # CrÃ©er un rÃ©pertoire de test
            $testOutputDir = Join-Path -Path $TestDrive -ChildPath "GeneratedData"
        }

        It "GÃ©nÃ¨re correctement le nombre de fichiers spÃ©cifiÃ©" {
            # GÃ©nÃ©rer des fichiers de test
            $fileCount = 5
            $generatedFiles = New-TestFiles -OutputPath $testOutputDir -FileCount $fileCount

            # VÃ©rifier que le nombre de fichiers est correct
            $generatedFiles.Count | Should -Be $fileCount

            # VÃ©rifier que les fichiers existent
            foreach ($file in $generatedFiles) {
                Test-Path -Path $file | Should -Be $true
            }
        }

        It "GÃ©nÃ¨re des fichiers avec la taille spÃ©cifiÃ©e" {
            # GÃ©nÃ©rer des fichiers de test avec une taille fixe
            $fileCount = 3
            $fileSize = 2KB
            $generatedFiles = New-TestFiles -OutputPath $testOutputDir -FileCount $fileCount -MinSize ($fileSize - 1) -MaxSize ($fileSize + 1)

            # VÃ©rifier que les fichiers ont une taille proche de celle spÃ©cifiÃ©e
            foreach ($file in $generatedFiles) {
                $actualSize = (Get-Item -Path $file).Length
                # Utiliser une marge d'erreur plus large pour tenir compte des diffÃ©rences de taille
                $actualSize | Should -BeGreaterOrEqual ($fileSize - 100)
                $actualSize | Should -BeLessOrEqual ($fileSize + 100)
            }
        }
    }

    Context "Gestion des chemins relatifs et absolus" {
        BeforeAll {
            # Fonction pour normaliser un chemin
            function ConvertTo-NormalizedPath {
                param (
                    [string]$Path,
                    [string]$BasePath = $PWD.Path
                )

                if ([string]::IsNullOrEmpty($Path)) {
                    return $null
                }

                # Convertir un chemin relatif en chemin absolu
                if (-not [System.IO.Path]::IsPathRooted($Path)) {
                    $Path = Join-Path -Path $BasePath -ChildPath $Path
                }

                # Normaliser le chemin (rÃ©soudre les .. et .)
                try {
                    $normalizedPath = [System.IO.Path]::GetFullPath($Path)
                    return $normalizedPath
                }
                catch {
                    return $null
                }
            }

            # CrÃ©er des rÃ©pertoires de test
            $testRootDir = Join-Path -Path $TestDrive -ChildPath "TestRoot"
            $testSubDir = Join-Path -Path $testRootDir -ChildPath "SubDir"

            New-Item -Path $testRootDir -ItemType Directory -Force | Out-Null
            New-Item -Path $testSubDir -ItemType Directory -Force | Out-Null
        }

        It "Normalise correctement un chemin absolu" {
            # Tester un chemin absolu
            $result = ConvertTo-NormalizedPath -Path $testRootDir
            $result | Should -Be $testRootDir
        }

        It "Normalise correctement un chemin relatif" {
            # Tester un chemin relatif
            $relativePath = "SubDir"
            $result = ConvertTo-NormalizedPath -Path $relativePath -BasePath $testRootDir
            $result | Should -Be $testSubDir
        }

        It "Normalise correctement un chemin avec des composants .. et ." {
            # Tester un chemin avec des composants .. et .
            $complexPath = Join-Path -Path $testRootDir -ChildPath "SubDir\..\SubDir\.\."

            $result = ConvertTo-NormalizedPath -Path $complexPath
            $result | Should -Be $testSubDir
        }

        It "Retourne null pour un chemin vide" {
            # Tester un chemin vide
            $result = ConvertTo-NormalizedPath -Path ""
            $result | Should -Be $null
        }
    }
}
