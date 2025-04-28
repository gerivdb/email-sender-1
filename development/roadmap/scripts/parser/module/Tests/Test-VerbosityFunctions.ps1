<#
.SYNOPSIS
    Tests unitaires pour les fonctions de verbositÃ© configurable.

.DESCRIPTION
    Ce script contient des tests unitaires pour les fonctions de verbositÃ© configurable
    du module RoadmapParser.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-16
#>

# Importer le module Pester s'il n'est pas dÃ©jÃ  chargÃ©
if (-not (Get-Module -Name Pester)) {
    Import-Module Pester -ErrorAction Stop
}

# Chemin vers le module Ã  tester
$modulePath = (Split-Path -Parent $PSScriptRoot)
$functionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\VerbosityFunctions.ps1"

# Importer les fonctions Ã  tester
. $functionsPath

Describe "Verbosity Functions" {
    BeforeAll {
        # Sauvegarder la configuration actuelle
        $originalConfig = Get-VerbosityConfig
    }

    AfterAll {
        # Restaurer la configuration originale
        $script:VerbosityConfig = $originalConfig
    }

    Context "Configuration Functions" {
        It "Should get the default verbosity configuration" {
            $config = Get-VerbosityConfig
            $config | Should -Not -BeNullOrEmpty
            $config.Level | Should -Not -BeNullOrEmpty
            $config.Formats | Should -Not -BeNullOrEmpty
            $config.Categories | Should -Not -BeNullOrEmpty
            $config.Presets | Should -Not -BeNullOrEmpty
        }

        It "Should set and get the verbosity level" {
            # DÃ©finir le niveau de verbositÃ©
            Set-VerbosityLevel -Level "Detailed"

            # VÃ©rifier que le niveau a Ã©tÃ© mis Ã  jour
            $level = Get-VerbosityLevel
            $level | Should -Be "Detailed"
        }

        It "Should set and get the verbosity format" {
            # DÃ©finir le format de verbositÃ©
            $testFormat = "[{0}] [{1}] [{2}] Test: {3}"
            Set-VerbosityFormat -Level "Detailed" -Format $testFormat

            # VÃ©rifier que le format a Ã©tÃ© mis Ã  jour
            $format = Get-VerbosityFormat -Level "Detailed"
            $format | Should -Be $testFormat
        }

        It "Should set and get the verbosity categories" {
            # DÃ©finir les catÃ©gories de verbositÃ©
            $testCategories = @("Error", "Warning", "Info", "Test")
            Set-VerbosityCategories -Level "Detailed" -Categories $testCategories

            # VÃ©rifier que les catÃ©gories ont Ã©tÃ© mises Ã  jour
            $categories = Get-VerbosityCategories -Level "Detailed"
            $categories | Should -Be $testCategories
        }
    }

    Context "Verbosity Presets" {
        It "Should apply the 'Silent' preset" {
            # Appliquer le prÃ©rÃ©glage
            Set-VerbosityPreset -PresetName "Silent"

            # VÃ©rifier que la configuration a Ã©tÃ© mise Ã  jour
            $config = Get-VerbosityConfig
            $config.Level | Should -Be $config.Presets["Silent"].Level
        }

        It "Should apply the 'Production' preset" {
            # Appliquer le prÃ©rÃ©glage
            Set-VerbosityPreset -PresetName "Production"

            # VÃ©rifier que la configuration a Ã©tÃ© mise Ã  jour
            $config = Get-VerbosityConfig
            $config.Level | Should -Be $config.Presets["Production"].Level
        }

        It "Should apply the 'Development' preset" {
            # Appliquer le prÃ©rÃ©glage
            Set-VerbosityPreset -PresetName "Development"

            # VÃ©rifier que la configuration a Ã©tÃ© mise Ã  jour
            $config = Get-VerbosityConfig
            $config.Level | Should -Be $config.Presets["Development"].Level
        }

        It "Should apply the 'Debugging' preset" {
            # Appliquer le prÃ©rÃ©glage
            Set-VerbosityPreset -PresetName "Debugging"

            # VÃ©rifier que la configuration a Ã©tÃ© mise Ã  jour
            $config = Get-VerbosityConfig
            $config.Level | Should -Be $config.Presets["Debugging"].Level
        }

        It "Should apply the 'Diagnostic' preset" {
            # Appliquer le prÃ©rÃ©glage
            Set-VerbosityPreset -PresetName "Diagnostic"

            # VÃ©rifier que la configuration a Ã©tÃ© mise Ã  jour
            $config = Get-VerbosityConfig
            $config.Level | Should -Be $config.Presets["Diagnostic"].Level
        }
    }

    Context "Logging Decision" {
        It "Should log messages in enabled categories" {
            # Configurer pour le test
            Set-VerbosityLevel -Level "Normal"
            Set-VerbosityCategories -Level "Normal" -Categories @("Error", "Warning", "Info")

            # VÃ©rifier que les messages des catÃ©gories activÃ©es sont journalisÃ©s
            Should-LogByVerbosity -Category "Error" | Should -Be $true
            Should-LogByVerbosity -Category "Warning" | Should -Be $true
            Should-LogByVerbosity -Category "Info" | Should -Be $true
        }

        It "Should not log messages in disabled categories" {
            # Configurer pour le test
            Set-VerbosityLevel -Level "Normal"
            Set-VerbosityCategories -Level "Normal" -Categories @("Error", "Warning", "Info")

            # VÃ©rifier que les messages des catÃ©gories dÃ©sactivÃ©es ne sont pas journalisÃ©s
            Should-LogByVerbosity -Category "Debug" | Should -Be $false
            Should-LogByVerbosity -Category "Trace" | Should -Be $false
        }
    }

    Context "Message Formatting" {
        It "Should format messages according to the 'Minimal' level" {
            # Configurer pour le test
            Set-VerbosityLevel -Level "Minimal"
            Set-VerbosityFormat -Level "Minimal" -Format "[{0}] {1}"

            # Formater un message
            $message = Format-MessageByVerbosity -Message "Test message" -Level "Error"

            # VÃ©rifier le format
            $message | Should -Match "^\[Error\] Test message$"
        }

        It "Should format messages according to the 'Normal' level" {
            # Configurer pour le test
            Set-VerbosityLevel -Level "Normal"
            Set-VerbosityFormat -Level "Normal" -Format "[{0}] [{1}] {2}"

            # Formater un message
            $message = Format-MessageByVerbosity -Message "Test message" -Level "Error"

            # VÃ©rifier le format (avec timestamp)
            $message | Should -Match "^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] \[Error\] Test message$"
        }

        It "Should format messages according to the 'Detailed' level" {
            # Configurer pour le test
            Set-VerbosityLevel -Level "Detailed"
            Set-VerbosityFormat -Level "Detailed" -Format "[{0}] [{1}] [{2}] {3}"

            # Formater un message
            $message = Format-MessageByVerbosity -Message "Test message" -Level "Error" -Category "TestCategory"

            # VÃ©rifier le format (avec timestamp et catÃ©gorie)
            $message | Should -Match "^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] \[Error\] \[TestCategory\] Test message$"
        }

        It "Should format messages according to the 'Debug' level" {
            # Configurer pour le test
            Set-VerbosityLevel -Level "Debug"
            Set-VerbosityFormat -Level "Debug" -Format "[{0}] [{1}] [{2}] [{3}] {4}"

            # Formater un message
            $message = Format-MessageByVerbosity -Message "Test message" -Level "Error" -Category "TestCategory" -Source "TestSource"

            # VÃ©rifier le format (avec timestamp, catÃ©gorie et source)
            $message | Should -Match "^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] \[Error\] \[TestCategory\] \[TestSource\] Test message$"
        }

        It "Should format messages according to the 'Diagnostic' level" {
            # Configurer pour le test
            Set-VerbosityLevel -Level "Diagnostic"
            Set-VerbosityFormat -Level "Diagnostic" -Format "[{0}] [{1}] [{2}] [{3}] [{4}] {5}"

            # Formater un message
            $message = Format-MessageByVerbosity -Message "Test message" -Level "Error" -Category "TestCategory" -Source "TestSource" -Id "TEST001"

            # VÃ©rifier le format (avec timestamp, catÃ©gorie, source et ID)
            $message | Should -Match "^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] \[Error\] \[TestCategory\] \[TestSource\] \[TEST001\] Test message$"
        }
    }

    Context "Write-LogWithVerbosity" {
        BeforeEach {
            # CrÃ©er un rÃ©pertoire temporaire pour les tests
            $testDir = Join-Path -Path $TestDrive -ChildPath "logs"
            New-Item -Path $testDir -ItemType Directory -Force | Out-Null

            # CrÃ©er un fichier de journal de test
            $testLogFile = Join-Path -Path $testDir -ChildPath "verbosity_test.log"

            # Configurer pour le test
            Set-VerbosityLevel -Level "Diagnostic"
            Set-VerbosityCategories -Level "Diagnostic" -Categories @("Critical", "Error", "Warning", "Info", "Verbose", "Debug", "Trace")
        }

        It "Should write log messages with verbosity" {
            # Journaliser un message
            Write-LogWithVerbosity -Message "Test message" -Level "Error" -Category "TestCategory" -Source "TestSource" -Id "TEST001" -LogFile $testLogFile

            # VÃ©rifier que le message a Ã©tÃ© journalisÃ©
            $content = Get-Content -Path $testLogFile -Raw
            $content | Should -Not -BeNullOrEmpty
            $content | Should -Match "Test message"
        }

        It "Should not write log messages for disabled categories" {
            # Configurer pour le test
            Set-VerbosityLevel -Level "Minimal"
            Set-VerbosityCategories -Level "Minimal" -Categories @("Critical", "Error")

            # Journaliser un message dans une catÃ©gorie dÃ©sactivÃ©e
            Write-LogWithVerbosity -Message "Test message" -Level "Info" -LogFile $testLogFile

            # VÃ©rifier que le message n'a pas Ã©tÃ© journalisÃ©
            if (Test-Path -Path $testLogFile) {
                $content = Get-Content -Path $testLogFile -Raw
                $content | Should -Not -Match "Test message"
            } else {
                # Le fichier n'a pas Ã©tÃ© crÃ©Ã©, ce qui est aussi valide
                $true | Should -Be $true
            }
        }
    }
}
