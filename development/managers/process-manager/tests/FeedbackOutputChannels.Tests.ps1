<#
.SYNOPSIS
    Tests de validation des canaux de sortie du système de feedback.

.DESCRIPTION
    Ce script contient les tests pour valider les différents canaux de sortie
    du système de feedback, y compris la console, les fichiers de log,
    les événements et les sorties personnalisées.

.NOTES
    Version: 1.0.0
    Auteur: Process Manager Team
    Date de création: 2025-05-15
#>

# Importer Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Définir les chemins des modules à tester
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules"
$feedbackManagerPath = Join-Path -Path $modulesPath -ChildPath "FeedbackManager\FeedbackManager.psm1"
$feedbackCollectorPath = Join-Path -Path $modulesPath -ChildPath "FeedbackCollector\FeedbackCollector.psm1"
$feedbackExporterPath = Join-Path -Path $modulesPath -ChildPath "FeedbackExporter\FeedbackExporter.psm1"

# Importer les modules à tester
if (Test-Path -Path $feedbackManagerPath) {
    Import-Module $feedbackManagerPath -Force
}
else {
    throw "Module FeedbackManager introuvable : $feedbackManagerPath"
}

if (Test-Path -Path $feedbackCollectorPath) {
    Import-Module $feedbackCollectorPath -Force
}
else {
    throw "Module FeedbackCollector introuvable : $feedbackCollectorPath"
}

if (Test-Path -Path $feedbackExporterPath) {
    Import-Module $feedbackExporterPath -Force
}
else {
    throw "Module FeedbackExporter introuvable : $feedbackExporterPath"
}

# Définir les tests
Describe "Système de feedback - Tests des canaux de sortie" {
    BeforeAll {
        # Créer un répertoire temporaire pour les tests
        $script:TestDir = Join-Path -Path $TestDrive -ChildPath "FeedbackOutputTests"
        New-Item -Path $script:TestDir -ItemType Directory -Force | Out-Null

        # Créer les sous-répertoires nécessaires
        $script:LogDir = Join-Path -Path $script:TestDir -ChildPath "logs"
        New-Item -Path $script:LogDir -ItemType Directory -Force | Out-Null

        # Fonction pour créer un canal de sortie vers un fichier de log
        function New-FileLogChannel {
            param (
                [Parameter(Mandatory = $true)]
                [string]$LogPath
            )
            
            return {
                param (
                    [Parameter(Mandatory = $true)]
                    [FeedbackMessage]$Message
                )
                
                $logEntry = "$($Message.Timestamp.ToString('yyyy-MM-dd HH:mm:ss')) [$($Message.Type)] $($Message.Message)"
                $logEntry | Out-File -FilePath $LogPath -Append -Encoding utf8
            }
        }

        # Fonction pour créer un canal de sortie vers une variable
        function New-VariableChannel {
            param (
                [Parameter(Mandatory = $true)]
                [ref]$VariableRef
            )
            
            return {
                param (
                    [Parameter(Mandatory = $true)]
                    [FeedbackMessage]$Message
                )
                
                $VariableRef.Value += $Message
            }
        }

        # Fonction pour créer un canal de sortie qui déclenche un événement
        function New-EventChannel {
            param (
                [Parameter(Mandatory = $true)]
                [string]$EventName
            )
            
            return {
                param (
                    [Parameter(Mandatory = $true)]
                    [FeedbackMessage]$Message
                )
                
                # Créer un événement PowerShell
                $event = New-Event -SourceIdentifier $EventName -MessageData $Message
            }
        }

        # Fonction pour créer un canal de sortie formaté
        function New-FormattedChannel {
            param (
                [Parameter(Mandatory = $true)]
                [string]$Format,
                
                [Parameter(Mandatory = $true)]
                [ref]$OutputRef
            )
            
            return {
                param (
                    [Parameter(Mandatory = $true)]
                    [FeedbackMessage]$Message
                )
                
                $formattedMessage = $Format -replace '\{Type\}', $Message.Type -replace '\{Message\}', $Message.Message -replace '\{Timestamp\}', $Message.Timestamp.ToString('yyyy-MM-dd HH:mm:ss') -replace '\{Source\}', $Message.Source -replace '\{Severity\}', $Message.Severity
                
                $OutputRef.Value += $formattedMessage
            }
        }
    }

    Context "Canal de sortie console" {
        BeforeEach {
            # Rediriger la sortie console pour les tests
            $script:ConsoleOutput = $null
            Mock Write-Host { $script:ConsoleOutput = $args[0] }
        }

        It "Doit écrire les messages dans la console" {
            $message = Send-ProcessManagerInformation -Message "Test console output" -PassThru
            
            $script:ConsoleOutput | Should -Not -BeNullOrEmpty
            $script:ConsoleOutput | Should -Match "Test console output"
        }

        It "Doit formater les messages avec la couleur appropriée" {
            $message = Send-ProcessManagerError -Message "Test error output" -PassThru
            
            $script:ConsoleOutput | Should -Not -BeNullOrEmpty
            $script:ConsoleOutput | Should -Match "Test error output"
            
            # Vérifier que Write-Host a été appelé avec la couleur rouge
            Should -Invoke Write-Host -ParameterFilter { $ForegroundColor -eq "Red" }
        }
    }

    Context "Canal de sortie fichier" {
        It "Doit écrire les messages dans un fichier de log" {
            # Créer un fichier de log pour le test
            $logPath = Join-Path -Path $script:LogDir -ChildPath "test_log.txt"
            
            # Créer un canal de sortie vers le fichier de log
            $fileChannel = New-FileLogChannel -LogPath $logPath
            
            # Ajouter le canal à la liste des canaux de sortie
            $script:FeedbackChannels = @($fileChannel)
            
            # Envoyer un message
            $message = Send-ProcessManagerInformation -Message "Test file output" -PassThru
            
            # Vérifier que le fichier de log existe et contient le message
            Test-Path -Path $logPath | Should -Be $true
            $logContent = Get-Content -Path $logPath -Raw
            $logContent | Should -Match "Test file output"
            
            # Restaurer les canaux de sortie par défaut
            $script:FeedbackChannels = @()
        }
    }

    Context "Canal de sortie variable" {
        It "Doit stocker les messages dans une variable" {
            # Créer une variable pour stocker les messages
            $messages = @()
            
            # Créer un canal de sortie vers la variable
            $variableChannel = New-VariableChannel -VariableRef ([ref]$messages)
            
            # Ajouter le canal à la liste des canaux de sortie
            $script:FeedbackChannels = @($variableChannel)
            
            # Envoyer plusieurs messages
            $message1 = Send-ProcessManagerInformation -Message "Test variable output 1" -PassThru
            $message2 = Send-ProcessManagerWarning -Message "Test variable output 2" -PassThru
            $message3 = Send-ProcessManagerError -Message "Test variable output 3" -PassThru
            
            # Vérifier que les messages ont été stockés dans la variable
            $messages.Count | Should -Be 3
            $messages[0].Message | Should -Be "Test variable output 1"
            $messages[1].Message | Should -Be "Test variable output 2"
            $messages[2].Message | Should -Be "Test variable output 3"
            
            # Restaurer les canaux de sortie par défaut
            $script:FeedbackChannels = @()
        }
    }

    Context "Canal de sortie événement" {
        It "Doit déclencher des événements pour les messages" {
            # Créer un canal de sortie qui déclenche des événements
            $eventChannel = New-EventChannel -EventName "FeedbackTest"
            
            # Ajouter le canal à la liste des canaux de sortie
            $script:FeedbackChannels = @($eventChannel)
            
            # S'abonner à l'événement
            $eventReceived = $false
            $eventMessage = $null
            
            Register-EngineEvent -SourceIdentifier "FeedbackTest" -Action {
                $eventReceived = $true
                $eventMessage = $Event.MessageData
            }
            
            # Envoyer un message
            $message = Send-ProcessManagerInformation -Message "Test event output" -PassThru
            
            # Attendre que l'événement soit traité
            Start-Sleep -Milliseconds 100
            
            # Vérifier que l'événement a été déclenché
            $eventReceived | Should -Be $true
            $eventMessage | Should -Not -BeNullOrEmpty
            $eventMessage.Message | Should -Be "Test event output"
            
            # Nettoyer
            Unregister-Event -SourceIdentifier "FeedbackTest" -Force
            $script:FeedbackChannels = @()
        }
    }

    Context "Canal de sortie formaté" {
        It "Doit formater les messages selon un modèle personnalisé" {
            # Créer une variable pour stocker les messages formatés
            $formattedOutput = @()
            
            # Créer un canal de sortie formaté
            $format = "[{Timestamp}] <{Type}> {Message} (Severity: {Severity})"
            $formattedChannel = New-FormattedChannel -Format $format -OutputRef ([ref]$formattedOutput)
            
            # Ajouter le canal à la liste des canaux de sortie
            $script:FeedbackChannels = @($formattedChannel)
            
            # Envoyer un message
            $message = Send-ProcessManagerWarning -Message "Test formatted output" -Severity 2 -PassThru
            
            # Vérifier que le message a été formaté correctement
            $formattedOutput.Count | Should -Be 1
            $formattedOutput[0] | Should -Match "\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] <Warning> Test formatted output \(Severity: 2\)"
            
            # Restaurer les canaux de sortie par défaut
            $script:FeedbackChannels = @()
        }
    }

    Context "Canaux de sortie multiples" {
        It "Doit envoyer les messages à plusieurs canaux simultanément" {
            # Créer des variables pour stocker les sorties
            $consoleOutput = $null
            $fileOutput = Join-Path -Path $script:LogDir -ChildPath "multi_channel_test.txt"
            $variableOutput = @()
            
            # Créer les canaux de sortie
            Mock Write-Host { $consoleOutput = $args[0] }
            $fileChannel = New-FileLogChannel -LogPath $fileOutput
            $variableChannel = New-VariableChannel -VariableRef ([ref]$variableOutput)
            
            # Ajouter les canaux à la liste des canaux de sortie
            $script:FeedbackChannels = @($fileChannel, $variableChannel)
            
            # Envoyer un message
            $message = Send-ProcessManagerInformation -Message "Test multi-channel output" -PassThru
            
            # Vérifier que le message a été envoyé à tous les canaux
            $consoleOutput | Should -Not -BeNullOrEmpty
            $consoleOutput | Should -Match "Test multi-channel output"
            
            Test-Path -Path $fileOutput | Should -Be $true
            $fileContent = Get-Content -Path $fileOutput -Raw
            $fileContent | Should -Match "Test multi-channel output"
            
            $variableOutput.Count | Should -Be 1
            $variableOutput[0].Message | Should -Be "Test multi-channel output"
            
            # Restaurer les canaux de sortie par défaut
            $script:FeedbackChannels = @()
        }
    }

    Context "Exportation vers différents formats" {
        BeforeAll {
            # Préparer une collection de messages pour les tests d'exportation
            $script:MessageCollection.Clear()
            
            for ($i = 0; $i -lt 10; $i++) {
                $type = switch ($i % 5) {
                    0 { [FeedbackType]::Error }
                    1 { [FeedbackType]::Warning }
                    2 { [FeedbackType]::Information }
                    3 { [FeedbackType]::Success }
                    4 { [FeedbackType]::Debug }
                }
                
                $message = [FeedbackMessage]::new($type, "Test message $i")
                Add-MessageToCollection -Message $message
            }
        }

        It "Doit exporter au format JSON" {
            $exportPath = Join-Path -Path $script:TestDir -ChildPath "export_test.json"
            
            Export-CollectedMessages -Format "JSON" -OutputPath $exportPath
            
            Test-Path -Path $exportPath | Should -Be $true
            $content = Get-Content -Path $exportPath -Raw
            $content | Should -Not -BeNullOrEmpty
            
            # Vérifier que le contenu est un JSON valide
            { ConvertFrom-Json -InputObject $content } | Should -Not -Throw
            $json = ConvertFrom-Json -InputObject $content
            $json.Messages.Count | Should -Be 10
        }

        It "Doit exporter au format CSV" {
            $exportPath = Join-Path -Path $script:TestDir -ChildPath "export_test.csv"
            
            Export-CollectedMessages -Format "CSV" -OutputPath $exportPath
            
            Test-Path -Path $exportPath | Should -Be $true
            $content = Get-Content -Path $exportPath -Raw
            $content | Should -Not -BeNullOrEmpty
            
            # Vérifier que le contenu est un CSV valide
            $content | Should -Match "Timestamp,Type,Source,Severity,Message"
            $lines = $content -split "`n"
            $lines.Count | Should -BeGreaterThan 10  # En-tête + 10 messages
        }
    }

    AfterAll {
        # Nettoyer les ressources
        if (Test-Path -Path $script:TestDir) {
            Remove-Item -Path $script:TestDir -Recurse -Force
        }
        
        # Restaurer les canaux de sortie par défaut
        $script:FeedbackChannels = @()
    }
}
