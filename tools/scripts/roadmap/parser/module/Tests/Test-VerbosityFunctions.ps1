<#
.SYNOPSIS
    Tests unitaires pour les fonctions de verbosité configurable.

.DESCRIPTION
    Ce script contient des tests unitaires pour les fonctions de verbosité configurable
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

# Chemin vers le module à tester
$modulePath = (Split-Path -Parent $PSScriptRoot)
$functionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\VerbosityFunctions.ps1"

# Importer les fonctions à tester
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
            # Définir le niveau de verbosité
            Set-VerbosityLevel -Level "Detailed"

            # Vérifier que le niveau a été mis à jour
            $level = Get-VerbosityLevel
            $level | Should -Be "Detailed"
        }

        It "Should set and get the verbosity format" {
            # Définir le format de verbosité
            $testFormat = "[{0}] [{1}] [{2}] Test: {3}"
            Set-VerbosityFormat -Level "Detailed" -Format $testFormat

            # Vérifier que le format a été mis à jour
            $format = Get-VerbosityFormat -Level "Detailed"
            $format | Should -Be $testFormat
        }

        It "Should set and get the verbosity categories" {
            # Définir les catégories de verbosité
            $testCategories = @("Error", "Warning", "Info", "Test")
            Set-VerbosityCategories -Level "Detailed" -Categories $testCategories

            # Vérifier que les catégories ont été mises à jour
            $categories = Get-VerbosityCategories -Level "Detailed"
            $categories | Should -Be $testCategories
        }
    }

    Context "Verbosity Presets" {
        It "Should apply the 'Silent' preset" {
            # Appliquer le préréglage
            Set-VerbosityPreset -PresetName "Silent"

            # Vérifier que la configuration a été mise à jour
            $config = Get-VerbosityConfig
            $config.Level | Should -Be $config.Presets["Silent"].Level
        }

        It "Should apply the 'Production' preset" {
            # Appliquer le préréglage
            Set-VerbosityPreset -PresetName "Production"

            # Vérifier que la configuration a été mise à jour
            $config = Get-VerbosityConfig
            $config.Level | Should -Be $config.Presets["Production"].Level
        }

        It "Should apply the 'Development' preset" {
            # Appliquer le préréglage
            Set-VerbosityPreset -PresetName "Development"

            # Vérifier que la configuration a été mise à jour
            $config = Get-VerbosityConfig
            $config.Level | Should -Be $config.Presets["Development"].Level
        }

        It "Should apply the 'Debugging' preset" {
            # Appliquer le préréglage
            Set-VerbosityPreset -PresetName "Debugging"

            # Vérifier que la configuration a été mise à jour
            $config = Get-VerbosityConfig
            $config.Level | Should -Be $config.Presets["Debugging"].Level
        }

        It "Should apply the 'Diagnostic' preset" {
            # Appliquer le préréglage
            Set-VerbosityPreset -PresetName "Diagnostic"

            # Vérifier que la configuration a été mise à jour
            $config = Get-VerbosityConfig
            $config.Level | Should -Be $config.Presets["Diagnostic"].Level
        }
    }

    Context "Logging Decision" {
        It "Should log messages in enabled categories" {
            # Configurer pour le test
            Set-VerbosityLevel -Level "Normal"
            Set-VerbosityCategories -Level "Normal" -Categories @("Error", "Warning", "Info")

            # Vérifier que les messages des catégories activées sont journalisés
            Should-LogByVerbosity -Category "Error" | Should -Be $true
            Should-LogByVerbosity -Category "Warning" | Should -Be $true
            Should-LogByVerbosity -Category "Info" | Should -Be $true
        }

        It "Should not log messages in disabled categories" {
            # Configurer pour le test
            Set-VerbosityLevel -Level "Normal"
            Set-VerbosityCategories -Level "Normal" -Categories @("Error", "Warning", "Info")

            # Vérifier que les messages des catégories désactivées ne sont pas journalisés
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

            # Vérifier le format
            $message | Should -Match "^\[Error\] Test message$"
        }

        It "Should format messages according to the 'Normal' level" {
            # Configurer pour le test
            Set-VerbosityLevel -Level "Normal"
            Set-VerbosityFormat -Level "Normal" -Format "[{0}] [{1}] {2}"

            # Formater un message
            $message = Format-MessageByVerbosity -Message "Test message" -Level "Error"

            # Vérifier le format (avec timestamp)
            $message | Should -Match "^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] \[Error\] Test message$"
        }

        It "Should format messages according to the 'Detailed' level" {
            # Configurer pour le test
            Set-VerbosityLevel -Level "Detailed"
            Set-VerbosityFormat -Level "Detailed" -Format "[{0}] [{1}] [{2}] {3}"

            # Formater un message
            $message = Format-MessageByVerbosity -Message "Test message" -Level "Error" -Category "TestCategory"

            # Vérifier le format (avec timestamp et catégorie)
            $message | Should -Match "^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] \[Error\] \[TestCategory\] Test message$"
        }

        It "Should format messages according to the 'Debug' level" {
            # Configurer pour le test
            Set-VerbosityLevel -Level "Debug"
            Set-VerbosityFormat -Level "Debug" -Format "[{0}] [{1}] [{2}] [{3}] {4}"

            # Formater un message
            $message = Format-MessageByVerbosity -Message "Test message" -Level "Error" -Category "TestCategory" -Source "TestSource"

            # Vérifier le format (avec timestamp, catégorie et source)
            $message | Should -Match "^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] \[Error\] \[TestCategory\] \[TestSource\] Test message$"
        }

        It "Should format messages according to the 'Diagnostic' level" {
            # Configurer pour le test
            Set-VerbosityLevel -Level "Diagnostic"
            Set-VerbosityFormat -Level "Diagnostic" -Format "[{0}] [{1}] [{2}] [{3}] [{4}] {5}"

            # Formater un message
            $message = Format-MessageByVerbosity -Message "Test message" -Level "Error" -Category "TestCategory" -Source "TestSource" -Id "TEST001"

            # Vérifier le format (avec timestamp, catégorie, source et ID)
            $message | Should -Match "^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] \[Error\] \[TestCategory\] \[TestSource\] \[TEST001\] Test message$"
        }
    }

    Context "Write-LogWithVerbosity" {
        BeforeEach {
            # Créer un répertoire temporaire pour les tests
            $testDir = Join-Path -Path $TestDrive -ChildPath "logs"
            New-Item -Path $testDir -ItemType Directory -Force | Out-Null

            # Créer un fichier de journal de test
            $testLogFile = Join-Path -Path $testDir -ChildPath "verbosity_test.log"

            # Configurer pour le test
            Set-VerbosityLevel -Level "Diagnostic"
            Set-VerbosityCategories -Level "Diagnostic" -Categories @("Critical", "Error", "Warning", "Info", "Verbose", "Debug", "Trace")
        }

        It "Should write log messages with verbosity" {
            # Journaliser un message
            Write-LogWithVerbosity -Message "Test message" -Level "Error" -Category "TestCategory" -Source "TestSource" -Id "TEST001" -LogFile $testLogFile

            # Vérifier que le message a été journalisé
            $content = Get-Content -Path $testLogFile -Raw
            $content | Should -Not -BeNullOrEmpty
            $content | Should -Match "Test message"
        }

        It "Should not write log messages for disabled categories" {
            # Configurer pour le test
            Set-VerbosityLevel -Level "Minimal"
            Set-VerbosityCategories -Level "Minimal" -Categories @("Critical", "Error")

            # Journaliser un message dans une catégorie désactivée
            Write-LogWithVerbosity -Message "Test message" -Level "Info" -LogFile $testLogFile

            # Vérifier que le message n'a pas été journalisé
            if (Test-Path -Path $testLogFile) {
                $content = Get-Content -Path $testLogFile -Raw
                $content | Should -Not -Match "Test message"
            } else {
                # Le fichier n'a pas été créé, ce qui est aussi valide
                $true | Should -Be $true
            }
        }
    }
}
