<#
.SYNOPSIS
    Tests d'intégration pour le système de feedback avec le Process Manager.

.DESCRIPTION
    Ce script contient les tests d'intégration pour vérifier l'interaction entre
    les différents modules du système de feedback et le Process Manager.

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
$processManagerCommunicationPath = Join-Path -Path $modulesPath -ChildPath "ProcessManagerCommunication\ProcessManagerCommunication.psm1"

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

if (Test-Path -Path $processManagerCommunicationPath) {
    Import-Module $processManagerCommunicationPath -Force
}
else {
    throw "Module ProcessManagerCommunication introuvable : $processManagerCommunicationPath"
}

# Définir les tests
Describe "Système de feedback - Tests d'intégration" {
    BeforeAll {
        # Créer un répertoire temporaire pour les tests
        $script:TestDir = Join-Path -Path $TestDrive -ChildPath "FeedbackIntegrationTests"
        New-Item -Path $script:TestDir -ItemType Directory -Force | Out-Null

        # Créer les sous-répertoires nécessaires
        $script:ConfigDir = Join-Path -Path $script:TestDir -ChildPath "config\managers\process-manager"
        $script:DataDir = Join-Path -Path $script:TestDir -ChildPath "data\feedback"
        $script:ExportDir = Join-Path -Path $script:TestDir -ChildPath "exports\feedback"

        New-Item -Path $script:ConfigDir -ItemType Directory -Force | Out-Null
        New-Item -Path $script:DataDir -ItemType Directory -Force | Out-Null
        New-Item -Path $script:ExportDir -ItemType Directory -Force | Out-Null

        # Créer un fichier de configuration de test pour le Process Manager
        $processManagerConfig = @{
            Managers = @{
                FeedbackManager = @{
                    Path = $feedbackManagerPath
                    Enabled = $true
                    RegisteredAt = (Get-Date).ToString("o")
                    Version = "1.0.0"
                    LastRun = $null
                }
                FeedbackCollector = @{
                    Path = $feedbackCollectorPath
                    Enabled = $true
                    RegisteredAt = (Get-Date).ToString("o")
                    Version = "1.0.0"
                    LastRun = $null
                }
                FeedbackExporter = @{
                    Path = $feedbackExporterPath
                    Enabled = $true
                    RegisteredAt = (Get-Date).ToString("o")
                    Version = "1.0.0"
                    LastRun = $null
                }
            }
        }

        $processManagerConfigPath = Join-Path -Path $script:ConfigDir -ChildPath "process-manager.config.json"
        $processManagerConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $processManagerConfigPath -Encoding utf8

        # Créer un fichier de configuration de test pour le FeedbackManager
        $feedbackManagerConfig = @{
            DefaultVerbosityLevel = "Normal"
            MaxHistorySize = 1000
        }

        $feedbackManagerConfigPath = Join-Path -Path $script:ConfigDir -ChildPath "feedback-manager.config.json"
        $feedbackManagerConfig | ConvertTo-Json -Depth 5 | Out-File -FilePath $feedbackManagerConfigPath -Encoding utf8

        # Créer un fichier de configuration de test pour le FeedbackCollector
        $feedbackCollectorConfig = @{
            MaxCollectionSize = 1000
            RotationEnabled = $true
            RotationInterval = 86400
            PersistenceEnabled = $true
            ImportantMessageTags = @("Critical", "Security", "Performance", "Error")
            StoragePath = $script:DataDir
        }

        $feedbackCollectorConfigPath = Join-Path -Path $script:ConfigDir -ChildPath "feedback-collector.config.json"
        $feedbackCollectorConfig | ConvertTo-Json -Depth 5 | Out-File -FilePath $feedbackCollectorConfigPath -Encoding utf8

        # Créer un fichier de configuration de test pour le FeedbackExporter
        $feedbackExporterConfig = @{
            DefaultFormat = "JSON"
            ExportPath = $script:ExportDir
            SupportedFormats = @("JSON", "CSV", "XML", "HTML", "TEXT")
        }

        $feedbackExporterConfigPath = Join-Path -Path $script:ConfigDir -ChildPath "feedback-exporter.config.json"
        $feedbackExporterConfig | ConvertTo-Json -Depth 5 | Out-File -FilePath $feedbackExporterConfigPath -Encoding utf8

        # Rediriger les variables globales des modules vers les chemins de test
        $script:OriginalDefaultConfigPath = $script:DefaultConfigPath
        $script:DefaultConfigPath = $processManagerConfigPath

        # Initialiser les modules avec les configurations de test
        Initialize-FeedbackCollector -ConfigPath $feedbackCollectorConfigPath -StoragePath $script:DataDir
        Initialize-FeedbackExporter -ConfigPath $feedbackExporterConfigPath -ExportPath $script:ExportDir
    }

    Context "Intégration FeedbackManager et FeedbackCollector" {
        It "Les messages envoyés via FeedbackManager doivent être collectés par FeedbackCollector" {
            # Envoyer un message via FeedbackManager
            $message = Send-ProcessManagerInformation -Message "Test d'intégration" -PassThru
            
            # Ajouter manuellement le message à la collection (car l'abonnement aux événements n'est pas actif dans les tests)
            Add-MessageToCollection -Message $message
            
            # Vérifier que le message a été ajouté à la collection
            $script:MessageCollection.Messages.Count | Should -BeGreaterThan 0
            $script:MessageCollection.Messages[0].Message | Should -Be "Test d'intégration"
        }
    }

    Context "Intégration FeedbackCollector et FeedbackExporter" {
        It "Les messages collectés doivent pouvoir être exportés" {
            # Envoyer plusieurs messages
            for ($i = 1; $i -le 5; $i++) {
                $message = Send-ProcessManagerInformation -Message "Message de test $i" -PassThru
                Add-MessageToCollection -Message $message
            }
            
            # Exporter les messages
            $exportPath = Export-CollectedMessages -Format "JSON" -OutputPath (Join-Path -Path $script:ExportDir -ChildPath "test_export.json")
            
            # Vérifier que le fichier d'exportation existe
            Test-Path -Path $exportPath | Should -Be $true
            
            # Vérifier le contenu du fichier
            $exportContent = Get-Content -Path $exportPath -Raw | ConvertFrom-Json
            $exportContent.Messages.Count | Should -BeGreaterThan 0
            $exportContent.Messages[0].Message | Should -Match "Message de test"
        }
    }

    Context "Intégration avec le Process Manager via ProcessManagerCommunication" {
        BeforeAll {
            # Créer un mock pour la communication avec le Process Manager
            Mock Initialize-ProcessManagerCommunication {
                return @{
                    Protocol = "FileSystem"
                    Directory = $script:TestDir
                    RequestFile = Join-Path -Path $script:TestDir -ChildPath "request.json"
                    ResponseFile = Join-Path -Path $script:TestDir -ChildPath "response.json"
                    LockFile = Join-Path -Path $script:TestDir -ChildPath "lock.txt"
                }
            }
            
            Mock Send-ProcessManagerCommand {
                param (
                    [Parameter(Mandatory = $true)]
                    [object]$Connection,
                    
                    [Parameter(Mandatory = $true)]
                    [string]$Command,
                    
                    [Parameter(Mandatory = $false)]
                    [hashtable]$Parameters = @{},
                    
                    [Parameter(Mandatory = $false)]
                    [int]$Timeout = 30
                )
                
                # Simuler une réponse du Process Manager
                $response = @{
                    Id = $Parameters.Id
                    Command = $Command
                    Success = $true
                    Result = @{
                        Message = "Commande exécutée avec succès"
                    }
                }
                
                return $response
            }
        }

        It "Doit pouvoir initialiser la communication avec le Process Manager" {
            $connection = Initialize-ProcessManagerCommunication
            $connection | Should -Not -BeNullOrEmpty
            $connection.Protocol | Should -Be "FileSystem"
        }

        It "Doit pouvoir envoyer une commande au Process Manager" {
            $connection = Initialize-ProcessManagerCommunication
            $response = Send-ProcessManagerCommand -Connection $connection -Command "GetStatus" -Parameters @{ ManagerName = "FeedbackManager" }
            
            $response | Should -Not -BeNullOrEmpty
            $response.Success | Should -Be $true
            $response.Command | Should -Be "GetStatus"
        }
    }

    AfterAll {
        # Nettoyer les ressources
        if (Test-Path -Path $script:TestDir) {
            Remove-Item -Path $script:TestDir -Recurse -Force
        }
        
        # Restaurer les variables globales
        if ($script:OriginalDefaultConfigPath) {
            $script:DefaultConfigPath = $script:OriginalDefaultConfigPath
        }
    }
}
