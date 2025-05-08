# Configuration-Tests.ps1
# Tests pour les fonctions de configuration

# Importer le module Pester si disponible
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Warning "Le module Pester n'est pas installé. Les tests ne peuvent pas être exécutés."
    exit
}

# Importer le module
$modulePath = "$PSScriptRoot\..\ExtractedInfoModule.psm1"
Import-Module $modulePath -Force

# Créer un fichier de configuration temporaire pour les tests
$tempConfigPath = [System.IO.Path]::GetTempFileName()
$tempConfigContent = @"
{
    "DefaultSerializationFormat": "Json",
    "DefaultValidationEnabled": true,
    "DefaultConfidenceThreshold": 80,
    "DefaultLanguage": "en",
    "AdvancedOptions": {
        "Performance": {
            "EnableParallelProcessing": true,
            "MaxParallelJobs": 8
        }
    }
}
"@
Set-Content -Path $tempConfigPath -Value $tempConfigContent

Describe "Tests des fonctions de configuration" {
    BeforeAll {
        # Sauvegarder la configuration actuelle
        $originalConfig = Get-ExtractedInfoConfiguration
    }

    AfterAll {
        # Restaurer la configuration originale
        Set-ExtractedInfoConfiguration -Config $originalConfig
        
        # Supprimer le fichier temporaire
        if (Test-Path -Path $tempConfigPath) {
            Remove-Item -Path $tempConfigPath -Force
        }
    }

    Context "Get-ExtractedInfoConfiguration" {
        It "Devrait retourner la configuration complète" {
            $config = Get-ExtractedInfoConfiguration
            $config | Should -Not -BeNullOrEmpty
            $config | Should -BeOfType [hashtable]
        }

        It "Devrait retourner une valeur spécifique" {
            $language = Get-ExtractedInfoConfiguration -Key "DefaultLanguage"
            $language | Should -Not -BeNullOrEmpty
        }

        It "Devrait retourner null pour une clé inexistante" {
            $nonExistent = Get-ExtractedInfoConfiguration -Key "NonExistentKey"
            $nonExistent | Should -BeNullOrEmpty
        }
    }

    Context "Set-ExtractedInfoConfiguration" {
        It "Devrait modifier une valeur simple" {
            Set-ExtractedInfoConfiguration -Key "DefaultLanguage" -Value "es"
            $language = Get-ExtractedInfoConfiguration -Key "DefaultLanguage"
            $language | Should -Be "es"
        }

        It "Devrait modifier une valeur complexe" {
            $performance = @{
                EnableParallelProcessing = $false
                MaxParallelJobs = 2
            }
            Set-ExtractedInfoConfiguration -Key "AdvancedOptions.Performance" -Value $performance
            $newPerformance = Get-ExtractedInfoConfiguration -Key "AdvancedOptions.Performance"
            $newPerformance.EnableParallelProcessing | Should -Be $false
            $newPerformance.MaxParallelJobs | Should -Be 2
        }

        It "Devrait remplacer toute la configuration" {
            $newConfig = @{
                DefaultSerializationFormat = "Xml"
                DefaultLanguage = "fr"
            }
            Set-ExtractedInfoConfiguration -Config $newConfig
            $config = Get-ExtractedInfoConfiguration
            $config.DefaultSerializationFormat | Should -Be "Xml"
            $config.DefaultLanguage | Should -Be "fr"
        }
    }

    Context "Import-ExtractedInfoConfiguration" {
        It "Devrait importer la configuration depuis un fichier" {
            Import-ExtractedInfoConfiguration -Path $tempConfigPath
            $config = Get-ExtractedInfoConfiguration
            $config.DefaultLanguage | Should -Be "en"
            $config.DefaultConfidenceThreshold | Should -Be 80
            $config.AdvancedOptions.Performance.EnableParallelProcessing | Should -Be $true
        }

        It "Devrait fusionner la configuration importée avec l'existante" {
            # D'abord, définir une configuration de base
            $baseConfig = @{
                DefaultSerializationFormat = "Xml"
                DefaultLanguage = "fr"
                CustomSetting = "Value"
            }
            Set-ExtractedInfoConfiguration -Config $baseConfig

            # Ensuite, importer et fusionner
            Import-ExtractedInfoConfiguration -Path $tempConfigPath -Merge
            $config = Get-ExtractedInfoConfiguration
            $config.DefaultLanguage | Should -Be "en"  # Remplacé par l'import
            $config.DefaultSerializationFormat | Should -Be "Json"  # Remplacé par l'import
            $config.CustomSetting | Should -Be "Value"  # Conservé de la config de base
        }
    }

    Context "Export-ExtractedInfoConfiguration" {
        It "Devrait exporter la configuration vers un fichier" {
            $exportPath = [System.IO.Path]::GetTempFileName()
            
            # Définir une configuration connue
            $testConfig = @{
                DefaultSerializationFormat = "Json"
                DefaultLanguage = "it"
                TestValue = 123
            }
            Set-ExtractedInfoConfiguration -Config $testConfig
            
            # Exporter
            Export-ExtractedInfoConfiguration -Path $exportPath -Format "JSON" -Force
            
            # Vérifier que le fichier existe
            Test-Path -Path $exportPath | Should -Be $true
            
            # Vérifier le contenu
            $content = Get-Content -Path $exportPath -Raw | ConvertFrom-Json
            $content.DefaultLanguage | Should -Be "it"
            $content.TestValue | Should -Be 123
            
            # Nettoyer
            Remove-Item -Path $exportPath -Force
        }
    }

    Context "Initialize-ExtractedInfoConfiguration" {
        It "Devrait initialiser la configuration avec les valeurs par défaut" {
            # D'abord, définir une configuration non standard
            $nonStandardConfig = @{
                DefaultSerializationFormat = "Custom"
                DefaultLanguage = "xx"
                NonStandardKey = "Value"
            }
            Set-ExtractedInfoConfiguration -Config $nonStandardConfig
            
            # Réinitialiser
            Initialize-ExtractedInfoConfiguration -SkipFileLoad -SkipEnvLoad
            
            # Vérifier
            $config = Get-ExtractedInfoConfiguration
            $config.DefaultSerializationFormat | Should -Be "Json"  # Valeur par défaut
            $config.DefaultLanguage | Should -Be "fr"  # Valeur par défaut
            $config.NonStandardKey | Should -BeNullOrEmpty  # Supprimé
        }
    }
}

# Exécuter les tests
Invoke-Pester -Path $PSScriptRoot\Configuration-Tests.ps1 -Output Detailed
