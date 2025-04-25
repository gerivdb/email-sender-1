<#
.SYNOPSIS
    Tests unitaires pour les fonctions de configuration.

.DESCRIPTION
    Ce script contient des tests unitaires pour les fonctions de configuration
    du module RoadmapParser.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-16
#>

# Importer le module Pester s'il n'est pas déjà chargé
if (-not (Get-Module -Name Pester)) {
    Import-Module Pester -ErrorAction Stop
}

# Importer le module de test
$moduleTestPath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapParserTest.psm1"
Import-Module $moduleTestPath -Force

Describe "Configuration Functions" {
    BeforeAll {
        # Créer un répertoire temporaire pour les tests
        $testDir = Join-Path -Path $env:TEMP -ChildPath "RoadmapParserTests_$(Get-Random)"
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null

        # Créer un fichier de configuration JSON de test
        $testJsonConfig = @{
            General = @{
                LogLevel     = "INFO"
                LogPath      = "logs"
                OutputFormat = "Markdown"
            }
            Modes   = @{
                DEBUG = @{
                    GeneratePatch     = $true
                    IncludeStackTrace = $true
                }
                TEST  = @{
                    CoverageThreshold = 80
                    GenerateReport    = $true
                }
            }
            Paths   = @{
                ModulePath    = "roadmap-parser\module"
                FunctionsPath = "roadmap-parser\module\Functions"
                OutputPath    = "output"
            }
        }

        $testJsonFile = Join-Path -Path $testDir -ChildPath "config.json"
        $testJsonConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $testJsonFile -Encoding UTF8

        # Créer une configuration incomplète pour les tests
        $testIncompleteConfig = @{
            General = @{
                LogLevel = "INFO"
            }
            Paths   = @{
                OutputPath = "custom-output"
            }
        }

        $testIncompleteFile = Join-Path -Path $testDir -ChildPath "incomplete.json"
        $testIncompleteConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $testIncompleteFile -Encoding UTF8
    }

    AfterAll {
        # Nettoyer le répertoire temporaire
        if (Test-Path -Path $testDir) {
            Remove-Item -Path $testDir -Recurse -Force
        }
    }

    Context "Get-DefaultConfiguration" {
        It "Should return a valid default configuration" {
            $config = Get-DefaultConfiguration
            $config | Should -Not -BeNullOrEmpty
            $config.General | Should -Not -BeNullOrEmpty
            $config.Modes | Should -Not -BeNullOrEmpty
            $config.Paths | Should -Not -BeNullOrEmpty
        }

        It "Should include all required modes" {
            $config = Get-DefaultConfiguration
            $requiredModes = @("ARCHI", "DEBUG", "TEST", "OPTI", "REVIEW", "DEV-R", "PREDIC", "C-BREAK", "GIT", "CHECK", "GRAN")
            foreach ($mode in $requiredModes) {
                $config.Modes.ContainsKey($mode) | Should -BeTrue
            }
        }
    }

    Context "Get-Configuration" {
        It "Should load a JSON configuration file" {
            $config = Get-Configuration -ConfigFile $testJsonFile
            $config | Should -Not -BeNullOrEmpty
            $config.General.LogLevel | Should -Be "INFO"
            $config.Modes.DEBUG.GeneratePatch | Should -BeTrue
            $config.Paths.OutputPath | Should -Be "output"
        }

        It "Should apply defaults when requested" {
            $config = Get-Configuration -ConfigFile $testIncompleteFile -ApplyDefaults
            $config | Should -Not -BeNullOrEmpty
            $config.General.LogPath | Should -Not -BeNullOrEmpty
            $config.Modes | Should -Not -BeNullOrEmpty
            $config.Paths.ModulePath | Should -Not -BeNullOrEmpty
        }

        It "Should validate the configuration when requested" {
            { Get-Configuration -ConfigFile $testIncompleteFile -Validate } | Should -Not -Throw
        }

        It "Should handle non-existent files gracefully" {
            $nonExistentFile = Join-Path -Path $testDir -ChildPath "nonexistent.json"
            $result = Get-Configuration -ConfigFile $nonExistentFile
            $result | Should -BeNullOrEmpty
        }
    }

    Context "Merge-Configuration" {
        It "Should merge two configurations correctly" {
            $defaultConfig = @{
                General = @{
                    LogLevel     = "INFO"
                    LogPath      = "logs"
                    OutputFormat = "Markdown"
                }
                Modes   = @{
                    DEBUG = @{
                        GeneratePatch = $true
                    }
                }
            }

            $customConfig = @{
                General = @{
                    LogLevel = "DEBUG"
                }
                Modes   = @{
                    DEBUG = @{
                        IncludeStackTrace = $true
                    }
                }
            }

            $mergedConfig = Merge-Configuration -DefaultConfig $defaultConfig -CustomConfig $customConfig
            $mergedConfig.General.LogLevel | Should -Be "DEBUG"
            $mergedConfig.General.LogPath | Should -Be "logs"
            $mergedConfig.Modes.DEBUG.GeneratePatch | Should -BeTrue
            $mergedConfig.Modes.DEBUG.IncludeStackTrace | Should -BeTrue
        }

        It "Should support different merge strategies" {
            $defaultConfig = @{
                Tags = @("tag1", "tag2")
            }

            $customConfig = @{
                Tags = @("tag3", "tag4")
            }

            # Test Replace strategy
            $mergedConfig1 = Merge-Configuration -DefaultConfig $defaultConfig -CustomConfig $customConfig -Strategy "Replace"
            $mergedConfig1.Tags | Should -Be @("tag3", "tag4")

            # Test Append strategy
            $mergedConfig2 = Merge-Configuration -DefaultConfig $defaultConfig -CustomConfig $customConfig -Strategy "Append"
            $mergedConfig2.Tags.Count | Should -Be 4
            $mergedConfig2.Tags | Should -Contain "tag1"
            $mergedConfig2.Tags | Should -Contain "tag4"
        }

        It "Should support section inclusion and exclusion" {
            $defaultConfig = @{
                General = @{
                    LogLevel = "INFO"
                    LogPath  = "logs"
                }
                Modes   = @{
                    DEBUG = @{
                        GeneratePatch = $true
                    }
                }
                Paths   = @{
                    OutputPath = "output"
                }
            }

            $customConfig = @{
                General = @{
                    LogLevel = "DEBUG"
                }
                Modes   = @{
                    DEBUG = @{
                        IncludeStackTrace = $true
                    }
                }
                Paths   = @{
                    OutputPath = "custom-output"
                }
            }

            # Test IncludeSections
            $mergedConfig1 = Merge-Configuration -DefaultConfig $defaultConfig -CustomConfig $customConfig -IncludeSections @("General")
            $mergedConfig1.General.LogLevel | Should -Be "DEBUG"
            $mergedConfig1.Modes.DEBUG.IncludeStackTrace | Should -BeNullOrEmpty

            # Test ExcludeSections
            $mergedConfig2 = Merge-Configuration -DefaultConfig $defaultConfig -CustomConfig $customConfig -ExcludeSections @("Paths")
            $mergedConfig2.General.LogLevel | Should -Be "DEBUG"
            $mergedConfig2.Paths.OutputPath | Should -Be "output"
        }
    }

    Context "Test-Configuration" {
        It "Should validate a complete configuration" {
            $config = Get-Configuration -ConfigFile $testJsonFile

            # Créer des règles de validation personnalisées pour ce test
            $customRules = @{
                "General"          = @{
                    Type     = "Hashtable"
                    Required = $true
                }
                "Modes"            = @{
                    Type     = "Hashtable"
                    Required = $true
                }
                "Paths"            = @{
                    Type     = "Hashtable"
                    Required = $true
                }
                "General.LogLevel" = @{
                    Type          = "String"
                    Required      = $true
                    AllowedValues = @("ERROR", "WARNING", "INFO", "VERBOSE", "DEBUG")
                }
            }

            $isValid = Test-Configuration -Config $config -ValidationRules $customRules -SkipMissingKeys
            $isValid | Should -BeTrue
        }

        It "Should detect missing required keys" {
            $config = Get-Configuration -ConfigFile $testIncompleteFile
            $isValid = Test-Configuration -Config $config
            $isValid | Should -BeFalse
        }

        It "Should support detailed validation reports" {
            $config = Get-Configuration -ConfigFile $testIncompleteFile
            $report = Test-Configuration -Config $config -Detailed
            $report.IsValid | Should -BeFalse
            $report.MissingKeys.Count | Should -BeGreaterThan 0
        }

        It "Should support custom validation rules" {
            $config = Get-Configuration -ConfigFile $testJsonFile
            $customRules = @{
                "General.LogLevel" = @{
                    AllowedValues = @("DEBUG", "ERROR")
                }
            }

            $isValid = Test-Configuration -Config $config -ValidationRules $customRules
            $isValid | Should -BeFalse
        }
    }

    Context "Set-DefaultConfiguration" {
        It "Should apply default values to an incomplete configuration" {
            $config = Get-Configuration -ConfigFile $testIncompleteFile
            $completeConfig = Set-DefaultConfiguration -Config $config

            $completeConfig.General.LogPath | Should -Not -BeNullOrEmpty
            $completeConfig.Modes | Should -Not -BeNullOrEmpty
            $completeConfig.Paths.ModulePath | Should -Not -BeNullOrEmpty
        }

        It "Should preserve existing values" {
            $config = Get-Configuration -ConfigFile $testIncompleteFile
            $completeConfig = Set-DefaultConfiguration -Config $config

            $completeConfig.General.LogLevel | Should -Be "INFO"
            $completeConfig.Paths.OutputPath | Should -Be "custom-output"
        }

        It "Should support custom validation rules" {
            $config = Get-Configuration -ConfigFile $testIncompleteFile
            $customRules = @{
                "General.CustomKey" = @{
                    DefaultValue = "CustomValue"
                }
            }

            $completeConfig = Set-DefaultConfiguration -Config $config -ValidationRules $customRules
            $completeConfig.General.CustomKey | Should -Be "CustomValue"
        }
    }

    Context "Save-Configuration" {
        It "Should save a configuration to a JSON file" {
            $config = Get-DefaultConfiguration
            $outputFile = Join-Path -Path $testDir -ChildPath "output.json"

            Save-Configuration -Config $config -ConfigFile $outputFile -Format "JSON"

            Test-Path -Path $outputFile | Should -BeTrue
            $loadedConfig = Get-Configuration -ConfigFile $outputFile
            $loadedConfig.General.LogLevel | Should -Be $config.General.LogLevel
        }
    }

    Context "Convert-ConfigurationToString" {
        It "Should convert a configuration to a JSON string" {
            $config = @{
                General = @{
                    LogLevel = "INFO"
                }
            }

            $jsonString = Convert-ConfigurationToString -Config $config -Format "JSON"
            $jsonString | Should -Not -BeNullOrEmpty
            $jsonString | Should -Match "General"
            $jsonString | Should -Match "INFO"
        }
    }
}
