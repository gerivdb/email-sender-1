# Test-TagFormatsConfig.ps1
# Tests unitaires pour le système de configuration des formats de tags
# Version: 1.0
# Date: 2025-05-15

# Importer Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer le module Pester
Import-Module Pester

# Définir le chemin du script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\metadata\Manage-TagFormats.ps1"

# Définir le chemin du fichier de configuration de test
$testConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "TestTagFormats.config.json"

# S'assurer que le répertoire de test existe
if (-not (Test-Path -Path $PSScriptRoot)) {
    New-Item -Path $PSScriptRoot -ItemType Directory -Force | Out-Null
}

# Créer un fichier de configuration de test
$testConfig = @{
    name        = "Tag Formats Configuration"
    description = "Configuration des formats de tags pour les tests"
    version     = "1.0.0"
    updated_at  = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    tag_formats = @{
        test = @{
            name        = "Test"
            description = "Tags pour les tests"
            formats     = @(
                @{
                    name        = "TestFormat1"
                    pattern     = "#test:(\\d+)"
                    description = "Format #test:X"
                    example     = "#test:123"
                    value_group = 1
                    unit        = "units"
                }
            )
        }
    }
}

# Convertir en JSON et écrire le fichier de configuration de test
$testConfigJson = $testConfig | ConvertTo-Json -Depth 10
Set-Content -Path $testConfigPath -Value $testConfigJson -Encoding UTF8 -Force

# Définir les tests
Describe "Manage-TagFormats" {
    BeforeAll {
        # Charger les fonctions du script
        . $scriptPath
    }

    AfterAll {
        # Nettoyer les fichiers de test
        if (Test-Path -Path $testConfigPath) {
            Remove-Item -Path $testConfigPath -Force
        }
    }

    Context "Get-TagFormatsConfig" {
        It "Devrait charger correctement la configuration" {
            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath
            $config | Should -Not -BeNullOrEmpty
            $config.tag_formats.test | Should -Not -BeNullOrEmpty
            $config.tag_formats.test.formats.Count | Should -Be 1
            $config.tag_formats.test.formats[0].name | Should -Be "TestFormat1"
        }

        It "Devrait retourner null si le fichier n'existe pas" {
            $config = Get-TagFormatsConfig -ConfigPath "fichier_inexistant.json" -ErrorAction SilentlyContinue
            $config | Should -BeNullOrEmpty
        }

        It "Devrait créer un fichier de configuration par défaut si demandé" {
            $tempConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "TempConfig.json"

            # Supprimer le fichier s'il existe déjà
            if (Test-Path -Path $tempConfigPath) {
                Remove-Item -Path $tempConfigPath -Force
            }

            $config = Get-TagFormatsConfig -ConfigPath $tempConfigPath -CreateIfNotExists
            $config | Should -Not -BeNullOrEmpty
            $config.tag_formats | Should -Not -BeNullOrEmpty

            # Nettoyer
            if (Test-Path -Path $tempConfigPath) {
                Remove-Item -Path $tempConfigPath -Force
            }
        }
    }

    Context "Save-TagFormatsConfig" {
        It "Devrait sauvegarder correctement la configuration" {
            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath
            $config.tag_formats.test.description = "Description modifiée"

            $result = Save-TagFormatsConfig -Config $config -ConfigPath $testConfigPath
            $result | Should -Be $true

            $newConfig = Get-TagFormatsConfig -ConfigPath $testConfigPath
            $newConfig.tag_formats.test.description | Should -Be "Description modifiée"
        }
    }

    Context "Get-TagFormat" {
        It "Devrait retourner le format spécifié" {
            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath
            $format = Get-TagFormat -Config $config -TagType "test" -FormatName "TestFormat1"

            $format | Should -Not -BeNullOrEmpty
            $format.name | Should -Be "TestFormat1"
            $format.pattern | Should -Be "#test:(\\d+)"
        }

        It "Devrait retourner null si le type de tag n'existe pas" {
            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath
            $format = Get-TagFormat -Config $config -TagType "inexistant" -FormatName "TestFormat1"

            $format | Should -BeNullOrEmpty
        }

        It "Devrait retourner null si le format n'existe pas" {
            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath
            $format = Get-TagFormat -Config $config -TagType "test" -FormatName "Inexistant"

            $format | Should -BeNullOrEmpty
        }
    }

    Context "Add-TagFormat" {
        It "Devrait ajouter un nouveau format à un type existant" {
            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath

            $result = Add-TagFormat -Config $config -TagType "test" -FormatName "TestFormat2" -Pattern "#test\\((\\d+)\\)" -Description "Format #test(X)" -Example "#test(123)" -Unit "units" -ValueGroup 1

            $result | Should -Be $true
            $config.tag_formats.test.formats.Count | Should -Be 2
            $config.tag_formats.test.formats[1].name | Should -Be "TestFormat2"
            $config.tag_formats.test.formats[1].pattern | Should -Be "#test\\((\\d+)\\)"
        }

        It "Devrait créer un nouveau type de tag si nécessaire" {
            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath

            $result = Add-TagFormat -Config $config -TagType "nouveau" -FormatName "NouveauFormat" -Pattern "#nouveau:(\\d+)" -Description "Format #nouveau:X" -Example "#nouveau:123" -Unit "units" -ValueGroup 1

            $result | Should -Be $true
            $config.tag_formats.nouveau | Should -Not -BeNullOrEmpty
            $config.tag_formats.nouveau.formats.Count | Should -Be 1
            $config.tag_formats.nouveau.formats[0].name | Should -Be "NouveauFormat"
        }

        It "Devrait échouer si le format existe déjà" {
            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath

            $result = Add-TagFormat -Config $config -TagType "test" -FormatName "TestFormat1" -Pattern "#test:(\\d+)" -Description "Format #test:X" -Example "#test:123" -Unit "units" -ValueGroup 1

            $result | Should -Be $false
        }
    }

    Context "Update-TagFormat" {
        It "Devrait mettre à jour un format existant" {
            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath

            $result = Update-TagFormat -Config $config -TagType "test" -FormatName "TestFormat1" -Pattern "#test:(\\d+\\.\\d+)" -Description "Format modifié" -Example "#test:123.45" -Unit "decimal_units" -ValueGroup 1

            $result | Should -Be $true
            $config.tag_formats.test.formats[0].pattern | Should -Be "#test:(\\d+\\.\\d+)"
            $config.tag_formats.test.formats[0].description | Should -Be "Format modifié"
            $config.tag_formats.test.formats[0].example | Should -Be "#test:123.45"
            $config.tag_formats.test.formats[0].unit | Should -Be "decimal_units"
        }

        It "Devrait échouer si le type de tag n'existe pas" {
            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath

            $result = Update-TagFormat -Config $config -TagType "inexistant" -FormatName "TestFormat1" -Pattern "#test:(\\d+)" -Description "Format #test:X" -Example "#test:123" -Unit "units" -ValueGroup 1

            $result | Should -Be $false
        }

        It "Devrait échouer si le format n'existe pas" {
            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath

            $result = Update-TagFormat -Config $config -TagType "test" -FormatName "Inexistant" -Pattern "#test:(\\d+)" -Description "Format #test:X" -Example "#test:123" -Unit "units" -ValueGroup 1

            $result | Should -Be $false
        }
    }

    Context "Remove-TagFormat" {
        It "Devrait supprimer un format existant" {
            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath

            # Ajouter un format supplémentaire pour le test
            Add-TagFormat -Config $config -TagType "test" -FormatName "FormatToRemove" -Pattern "#test:remove(\\d+)" -Description "Format à supprimer" -Example "#test:remove123" -Unit "units" -ValueGroup 1

            $initialCount = $config.tag_formats.test.formats.Count

            $result = Remove-TagFormat -Config $config -TagType "test" -FormatName "FormatToRemove"

            $result | Should -Be $true
            $config.tag_formats.test.formats.Count | Should -Be ($initialCount - 1)
            $config.tag_formats.test.formats | Where-Object { $_.name -eq "FormatToRemove" } | Should -BeNullOrEmpty
        }

        It "Devrait échouer si le type de tag n'existe pas" {
            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath

            $result = Remove-TagFormat -Config $config -TagType "inexistant" -FormatName "TestFormat1"

            $result | Should -Be $false
        }

        It "Devrait échouer si le format n'existe pas" {
            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath

            $result = Remove-TagFormat -Config $config -TagType "test" -FormatName "Inexistant"

            $result | Should -Be $false
        }
    }

    Context "List-TagFormats" {
        It "Devrait lister tous les formats pour un type spécifique" {
            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath

            # Rediriger la sortie pour le test
            $output = $null
            $result = List-TagFormats -Config $config -TagType "test" 6>&1

            $result | Should -Be $true
        }

        It "Devrait lister tous les formats pour tous les types" {
            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath

            # Rediriger la sortie pour le test
            $output = $null
            $result = List-TagFormats -Config $config 6>&1

            $result | Should -Be $true
        }
    }

    Context "Invoke-TagFormatsManager" {
        It "Devrait exécuter l'action Get correctement" {
            # Rediriger la sortie pour le test
            $output = $null
            $result = Invoke-TagFormatsManager -Action "Get" -TagType "test" -FormatName "TestFormat1" -ConfigPath $testConfigPath 6>&1

            $result | Should -Be $true
        }

        It "Devrait exécuter l'action Add correctement" {
            $result = Invoke-TagFormatsManager -Action "Add" -TagType "test" -FormatName "TestFormatManager" -Pattern "#test:manager(\\d+)" -Description "Format ajouté par le manager" -Example "#test:manager123" -Unit "units" -ValueGroup 1 -ConfigPath $testConfigPath

            $result | Should -Be $true

            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath
            $config.tag_formats.test.formats | Where-Object { $_.name -eq "TestFormatManager" } | Should -Not -BeNullOrEmpty
        }

        It "Devrait exécuter l'action Update correctement" {
            $result = Invoke-TagFormatsManager -Action "Update" -TagType "test" -FormatName "TestFormatManager" -Description "Description mise à jour" -ConfigPath $testConfigPath

            $result | Should -Be $true

            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath
            $format = $config.tag_formats.test.formats | Where-Object { $_.name -eq "TestFormatManager" }
            $format.description | Should -Be "Description mise à jour"
        }

        It "Devrait exécuter l'action Remove correctement" {
            $result = Invoke-TagFormatsManager -Action "Remove" -TagType "test" -FormatName "TestFormatManager" -ConfigPath $testConfigPath

            $result | Should -Be $true

            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath
            $config.tag_formats.test.formats | Where-Object { $_.name -eq "TestFormatManager" } | Should -BeNullOrEmpty
        }

        It "Devrait exécuter l'action List correctement" {
            # Rediriger la sortie pour le test
            $output = $null
            $result = Invoke-TagFormatsManager -Action "List" -ConfigPath $testConfigPath 6>&1

            $result | Should -Be $true
        }

        It "Devrait exécuter l'action Export correctement" {
            $exportPath = Join-Path -Path $PSScriptRoot -ChildPath "ExportedConfig.json"

            $result = Invoke-TagFormatsManager -Action "Export" -ConfigPath $testConfigPath -OutputPath $exportPath

            $result | Should -Be $true
            Test-Path -Path $exportPath | Should -Be $true

            # Nettoyer
            if (Test-Path -Path $exportPath) {
                Remove-Item -Path $exportPath -Force
            }
        }

        It "Devrait exécuter l'action Import correctement" {
            # Créer un fichier d'importation
            $importConfig = @{
                name        = "Imported Configuration"
                description = "Configuration importée pour les tests"
                version     = "1.0.0"
                updated_at  = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
                tag_formats = @{
                    imported = @{
                        name        = "Imported"
                        description = "Tags importés"
                        formats     = @(
                            @{
                                name        = "ImportedFormat"
                                pattern     = "#imported:(\\d+)"
                                description = "Format importé"
                                example     = "#imported:123"
                                value_group = 1
                                unit        = "units"
                            }
                        )
                    }
                }
            } | ConvertTo-Json -Depth 10

            $importPath = Join-Path -Path $PSScriptRoot -ChildPath "ImportConfig.json"
            $importConfig | Set-Content -Path $importPath -Encoding UTF8

            $result = Invoke-TagFormatsManager -Action "Import" -ConfigPath $testConfigPath -ImportPath $importPath

            $result | Should -Be $true

            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath
            $config.tag_formats.imported | Should -Not -BeNullOrEmpty

            # Nettoyer
            if (Test-Path -Path $importPath) {
                Remove-Item -Path $importPath -Force
            }
        }
    }
}

# Exécuter les tests
Invoke-Pester -Path $PSScriptRoot\Test-TagFormatsConfig.ps1 -Output Detailed
