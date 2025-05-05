<#
.SYNOPSIS
    Tests unitaires pour le module FeedbackManager.

.DESCRIPTION
    Ce script contient les tests unitaires pour les fonctions du module FeedbackManager.

.NOTES
    Version: 1.0.0
    Auteur: Process Manager Team
    Date de crÃ©ation: 2025-05-15
#>

# Importer Pester si nÃ©cessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer le module Ã  tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\FeedbackManager\FeedbackManager.psm1"
if (Test-Path -Path $modulePath) {
    # Importer directement le contenu du module pour Ã©viter les problÃ¨mes de chargement
    . $modulePath
} else {
    throw "Module FeedbackManager introuvable : $modulePath"
}

# DÃ©finir les tests
Describe "FeedbackManager - Tests unitaires" {
    BeforeAll {
        # CrÃ©er un rÃ©pertoire temporaire pour les tests
        $script:TestDir = Join-Path -Path $TestDrive -ChildPath "FeedbackManagerTests"
        New-Item -Path $script:TestDir -ItemType Directory -Force | Out-Null
    }

    Context "Types et Ã©numÃ©rations" {
        It "L'Ã©numÃ©ration FeedbackType doit Ãªtre dÃ©finie" {
            [FeedbackType] | Should -Not -BeNullOrEmpty
        }

        It "L'Ã©numÃ©ration VerbosityLevel doit Ãªtre dÃ©finie" {
            [VerbosityLevel] | Should -Not -BeNullOrEmpty
        }

        It "La classe FeedbackMessage doit Ãªtre dÃ©finie" {
            [FeedbackMessage] | Should -Not -BeNullOrEmpty
        }

        It "La classe FeedbackFilter doit Ãªtre dÃ©finie" {
            [FeedbackFilter] | Should -Not -BeNullOrEmpty
        }
    }

    Context "CrÃ©ation de messages de feedback" {
        It "Doit crÃ©er un message de feedback avec le constructeur simple" {
            $message = [FeedbackMessage]::new([FeedbackType]::Information, "Test message")
            $message | Should -Not -BeNullOrEmpty
            $message.Type | Should -Be ([FeedbackType]::Information)
            $message.Message | Should -Be "Test message"
            $message.Source | Should -Be "ProcessManager"
            $message.Timestamp | Should -BeOfType [datetime]
            $message.CorrelationId | Should -Not -BeNullOrEmpty
        }

        It "Doit crÃ©er un message de feedback avec le constructeur complet" {
            $data = @{ Key = "Value" }
            $message = [FeedbackMessage]::new(
                [FeedbackType]::Warning,
                "Test warning",
                "TestSource",
                2,
                $data,
                [VerbosityLevel]::Normal
            )
            $message | Should -Not -BeNullOrEmpty
            $message.Type | Should -Be ([FeedbackType]::Warning)
            $message.Message | Should -Be "Test warning"
            $message.Source | Should -Be "TestSource"
            $message.Severity | Should -Be 2
            $message.Data.Key | Should -Be "Value"
            $message.MinimumVerbosity | Should -Be ([VerbosityLevel]::Normal)
        }
    }

    Context "MÃ©thodes de la classe FeedbackMessage" {
        BeforeAll {
            $script:TestMessage = [FeedbackMessage]::new([FeedbackType]::Error, "Test error message")
        }

        It "La mÃ©thode ToString doit retourner une chaÃ®ne formatÃ©e" {
            $result = $script:TestMessage.ToString()
            $result | Should -BeOfType [string]
            $result | Should -Match "\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] \[ProcessManager\] \[Error\] Test error message"
        }

        It "La mÃ©thode ToJson doit retourner une chaÃ®ne JSON valide" {
            $result = $script:TestMessage.ToJson()
            $result | Should -BeOfType [string]
            { ConvertFrom-Json -InputObject $result } | Should -Not -Throw
            $json = ConvertFrom-Json -InputObject $result
            $json.Type | Should -Be "Error"
            $json.Message | Should -Be "Test error message"
        }

        It "La mÃ©thode ShouldDisplay doit retourner true pour un niveau de verbositÃ© suffisant" {
            $script:TestMessage.ShouldDisplay([VerbosityLevel]::Minimal) | Should -Be $true
            $script:TestMessage.ShouldDisplay([VerbosityLevel]::Normal) | Should -Be $true
            $script:TestMessage.ShouldDisplay([VerbosityLevel]::Detailed) | Should -Be $true
        }

        It "La mÃ©thode ShouldDisplay doit retourner false pour un niveau de verbositÃ© insuffisant" {
            $script:TestMessage.ShouldDisplay([VerbosityLevel]::None) | Should -Be $false
        }
    }

    Context "Filtrage des messages" {
        BeforeAll {
            $script:ErrorMessage = [FeedbackMessage]::new([FeedbackType]::Error, "Error message")
            $script:WarningMessage = [FeedbackMessage]::new([FeedbackType]::Warning, "Warning message")
            $script:InfoMessage = [FeedbackMessage]::new([FeedbackType]::Information, "Info message")
            $script:SuccessMessage = [FeedbackMessage]::new([FeedbackType]::Success, "Success message")
            $script:DebugMessage = [FeedbackMessage]::new([FeedbackType]::Debug, "Debug message")
            $script:VerboseMessage = [FeedbackMessage]::new([FeedbackType]::Verbose, "Verbose message")
        }

        It "Le filtre par dÃ©faut doit accepter les messages d'erreur, d'avertissement, d'information et de succÃ¨s" {
            $filter = [FeedbackFilter]::new()
            $filter.PassesFilter($script:ErrorMessage) | Should -Be $true
            $filter.PassesFilter($script:WarningMessage) | Should -Be $true
            $filter.PassesFilter($script:InfoMessage) | Should -Be $true
            $filter.PassesFilter($script:SuccessMessage) | Should -Be $true
        }

        It "Le filtre par type doit accepter uniquement les types spÃ©cifiÃ©s" {
            $filter = [FeedbackFilter]::ForTypes(@([FeedbackType]::Error, [FeedbackType]::Warning))
            $filter.PassesFilter($script:ErrorMessage) | Should -Be $true
            $filter.PassesFilter($script:WarningMessage) | Should -Be $true
            $filter.PassesFilter($script:InfoMessage) | Should -Be $false
            $filter.PassesFilter($script:SuccessMessage) | Should -Be $false
        }

        It "Le filtre par source doit accepter uniquement les sources spÃ©cifiÃ©es" {
            $customMessage = [FeedbackMessage]::new([FeedbackType]::Information, "Custom message")
            $customMessage.Source = "CustomSource"

            $filter = [FeedbackFilter]::ForSources(@("CustomSource"))
            $filter.PassesFilter($customMessage) | Should -Be $true
            $filter.PassesFilter($script:InfoMessage) | Should -Be $false
        }

        It "Le filtre par sÃ©vÃ©ritÃ© doit accepter uniquement les sÃ©vÃ©ritÃ©s dans la plage spÃ©cifiÃ©e" {
            $filter = [FeedbackFilter]::ForSeverity(1, 2)
            $filter.PassesFilter($script:ErrorMessage) | Should -Be $true
            $filter.PassesFilter($script:WarningMessage) | Should -Be $true
            $filter.PassesFilter($script:InfoMessage) | Should -Be $false
            $filter.PassesFilter($script:SuccessMessage) | Should -Be $false
        }

        It "Le filtre personnalisÃ© doit appliquer la logique spÃ©cifiÃ©e" {
            $filter = [FeedbackFilter]::Custom({ param($message) $message.Message -like "*message*" })
            $filter.PassesFilter($script:ErrorMessage) | Should -Be $true

            $customMessage = [FeedbackMessage]::new([FeedbackType]::Information, "Custom text")
            $filter.PassesFilter($customMessage) | Should -Be $false
        }
    }

    Context "Fonctions d'envoi de feedback" {
        BeforeEach {
            # Rediriger la sortie pour les tests
            $script:Output = $null
            Mock Write-Host { $script:Output = $args[0] }
        }

        It "Send-ProcessManagerFeedback doit crÃ©er et envoyer un message" {
            $result = Send-ProcessManagerFeedback -Type ([FeedbackType]::Information) -Message "Test message" -PassThru
            $result | Should -Not -BeNullOrEmpty
            $result.Type | Should -Be ([FeedbackType]::Information)
            $result.Message | Should -Be "Test message"
            $script:Output | Should -Match "Test message"
        }

        It "Send-ProcessManagerError doit envoyer un message d'erreur" {
            $result = Send-ProcessManagerError -Message "Test error" -PassThru
            $result | Should -Not -BeNullOrEmpty
            $result.Type | Should -Be ([FeedbackType]::Error)
            $result.Message | Should -Be "Test error"
            $script:Output | Should -Match "Test error"
        }

        It "Send-ProcessManagerWarning doit envoyer un message d'avertissement" {
            $result = Send-ProcessManagerWarning -Message "Test warning" -PassThru
            $result | Should -Not -BeNullOrEmpty
            $result.Type | Should -Be ([FeedbackType]::Warning)
            $result.Message | Should -Be "Test warning"
            $script:Output | Should -Match "Test warning"
        }

        It "Send-ProcessManagerInformation doit envoyer un message d'information" {
            $result = Send-ProcessManagerInformation -Message "Test info" -PassThru
            $result | Should -Not -BeNullOrEmpty
            $result.Type | Should -Be ([FeedbackType]::Information)
            $result.Message | Should -Be "Test info"
            $script:Output | Should -Match "Test info"
        }

        It "Send-ProcessManagerSuccess doit envoyer un message de succÃ¨s" {
            $result = Send-ProcessManagerSuccess -Message "Test success" -PassThru
            $result | Should -Not -BeNullOrEmpty
            $result.Type | Should -Be ([FeedbackType]::Success)
            $result.Message | Should -Be "Test success"
            $script:Output | Should -Match "Test success"
        }

        It "Send-ProcessManagerDebug doit envoyer un message de dÃ©bogage" {
            $result = Send-ProcessManagerDebug -Message "Test debug" -PassThru
            $result | Should -Not -BeNullOrEmpty
            $result.Type | Should -Be ([FeedbackType]::Debug)
            $result.Message | Should -Be "Test debug"
            $script:Output | Should -Match "Test debug"
        }

        It "Send-ProcessManagerVerbose doit envoyer un message verbeux" {
            $result = Send-ProcessManagerVerbose -Message "Test verbose" -PassThru
            $result | Should -Not -BeNullOrEmpty
            $result.Type | Should -Be ([FeedbackType]::Verbose)
            $result.Message | Should -Be "Test verbose"
            $script:Output | Should -Match "Test verbose"
        }
    }

    Context "Gestion de la verbositÃ©" {
        It "Get-ProcessManagerVerbosity doit retourner le niveau de verbositÃ© actuel" {
            $verbosity = Get-ProcessManagerVerbosity
            $verbosity | Should -BeOfType [VerbosityLevel]
        }

        It "Set-ProcessManagerVerbosity doit modifier le niveau de verbositÃ©" {
            Set-ProcessManagerVerbosity -Level ([VerbosityLevel]::Minimal)
            $verbosity = Get-ProcessManagerVerbosity
            $verbosity | Should -Be ([VerbosityLevel]::Minimal)

            Set-ProcessManagerVerbosity -Level ([VerbosityLevel]::Normal)
            $verbosity = Get-ProcessManagerVerbosity
            $verbosity | Should -Be ([VerbosityLevel]::Normal)
        }
    }

    AfterAll {
        # Nettoyer les ressources
        if (Test-Path -Path $script:TestDir) {
            Remove-Item -Path $script:TestDir -Recurse -Force
        }
    }
}
