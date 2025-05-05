<#
.SYNOPSIS
    Tests de performance et de charge pour le systÃ¨me de feedback.

.DESCRIPTION
    Ce script contient les tests de performance et de charge pour Ã©valuer
    les performances du systÃ¨me de feedback sous diffÃ©rentes conditions de charge.

.NOTES
    Version: 1.0.0
    Auteur: Process Manager Team
    Date de crÃ©ation: 2025-05-15
#>

# Importer Pester si nÃ©cessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# DÃ©finir les chemins des modules Ã  tester
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules"
$feedbackManagerPath = Join-Path -Path $modulesPath -ChildPath "FeedbackManager\FeedbackManager.psm1"
$feedbackCollectorPath = Join-Path -Path $modulesPath -ChildPath "FeedbackCollector\FeedbackCollector.psm1"
$feedbackExporterPath = Join-Path -Path $modulesPath -ChildPath "FeedbackExporter\FeedbackExporter.psm1"

# Importer les modules Ã  tester
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

# DÃ©finir les tests
Describe "SystÃ¨me de feedback - Tests de performance et de charge" {
    BeforeAll {
        # CrÃ©er un rÃ©pertoire temporaire pour les tests
        $script:TestDir = Join-Path -Path $TestDrive -ChildPath "FeedbackPerformanceTests"
        New-Item -Path $script:TestDir -ItemType Directory -Force | Out-Null

        # CrÃ©er les sous-rÃ©pertoires nÃ©cessaires
        $script:ConfigDir = Join-Path -Path $script:TestDir -ChildPath "config"
        $script:DataDir = Join-Path -Path $script:TestDir -ChildPath "data"
        $script:ExportDir = Join-Path -Path $script:TestDir -ChildPath "exports"

        New-Item -Path $script:ConfigDir -ItemType Directory -Force | Out-Null
        New-Item -Path $script:DataDir -ItemType Directory -Force | Out-Null
        New-Item -Path $script:ExportDir -ItemType Directory -Force | Out-Null

        # Initialiser les modules avec les configurations de test
        Initialize-FeedbackCollector -StoragePath $script:DataDir -MaxCollectionSize 100000
        Initialize-FeedbackExporter -ExportPath $script:ExportDir

        # Fonction pour gÃ©nÃ©rer des messages de test
        function New-TestMessage {
            param (
                [Parameter(Mandatory = $false)]
                [int]$Index = 0,
                
                [Parameter(Mandatory = $false)]
                [int]$Size = 100,
                
                [Parameter(Mandatory = $false)]
                [FeedbackType]$Type = [FeedbackType]::Information
            )
            
            # GÃ©nÃ©rer un message de la taille spÃ©cifiÃ©e
            $message = "Test message $Index: " + "X" * ($Size - 15 - $Index.ToString().Length)
            
            return [FeedbackMessage]::new($Type, $message)
        }

        # Fonction pour mesurer le temps d'exÃ©cution
        function Measure-ExecutionTime {
            param (
                [Parameter(Mandatory = $true)]
                [scriptblock]$ScriptBlock
            )
            
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            & $ScriptBlock
            $stopwatch.Stop()
            
            return $stopwatch.ElapsedMilliseconds
        }
    }

    Context "Performance de l'envoi de messages" {
        It "Doit pouvoir envoyer 1000 messages en moins de 5 secondes" {
            # DÃ©sactiver la sortie console pour le test
            Mock Write-Host { }
            
            $time = Measure-ExecutionTime {
                for ($i = 0; $i -lt 1000; $i++) {
                    Send-ProcessManagerInformation -Message "Test message $i" -NoOutput
                }
            }
            
            $time | Should -BeLessThan 5000
        }
    }

    Context "Performance de la collecte de messages" {
        It "Doit pouvoir collecter 1000 messages en moins de 5 secondes" {
            $time = Measure-ExecutionTime {
                for ($i = 0; $i -lt 1000; $i++) {
                    $message = New-TestMessage -Index $i
                    Add-MessageToCollection -Message $message
                }
            }
            
            $time | Should -BeLessThan 5000
            $script:MessageCollection.Messages.Count | Should -BeGreaterThan 0
        }
    }

    Context "Performance de l'exportation de messages" {
        BeforeAll {
            # PrÃ©parer une collection de messages pour les tests d'exportation
            $script:MessageCollection.Clear()
            
            for ($i = 0; $i -lt 1000; $i++) {
                $type = switch ($i % 5) {
                    0 { [FeedbackType]::Error }
                    1 { [FeedbackType]::Warning }
                    2 { [FeedbackType]::Information }
                    3 { [FeedbackType]::Success }
                    4 { [FeedbackType]::Debug }
                }
                
                $message = New-TestMessage -Index $i -Type $type
                Add-MessageToCollection -Message $message
            }
        }

        It "Doit pouvoir exporter 1000 messages au format JSON en moins de 3 secondes" {
            $exportPath = Join-Path -Path $script:ExportDir -ChildPath "performance_test_json.json"
            
            $time = Measure-ExecutionTime {
                Export-CollectedMessages -Format "JSON" -OutputPath $exportPath
            }
            
            $time | Should -BeLessThan 3000
            Test-Path -Path $exportPath | Should -Be $true
        }

        It "Doit pouvoir exporter 1000 messages au format CSV en moins de 2 secondes" {
            $exportPath = Join-Path -Path $script:ExportDir -ChildPath "performance_test_csv.csv"
            
            $time = Measure-ExecutionTime {
                Export-CollectedMessages -Format "CSV" -OutputPath $exportPath
            }
            
            $time | Should -BeLessThan 2000
            Test-Path -Path $exportPath | Should -Be $true
        }
    }

    Context "Tests de charge avec diffÃ©rentes tailles de messages" {
        It "Doit gÃ©rer efficacement des messages de grande taille" {
            $script:MessageCollection.Clear()
            
            $sizes = @(100, 500, 1000, 5000, 10000)
            $counts = @(100, 50, 20, 10, 5)
            
            for ($i = 0; $i -lt $sizes.Length; $i++) {
                $size = $sizes[$i]
                $count = $counts[$i]
                
                $time = Measure-ExecutionTime {
                    for ($j = 0; $j -lt $count; $j++) {
                        $message = New-TestMessage -Index $j -Size $size
                        Add-MessageToCollection -Message $message
                    }
                }
                
                # VÃ©rifier que le temps d'exÃ©cution est proportionnel Ã  la taille des messages
                $timePerMessage = $time / $count
                $timePerMessage | Should -BeLessThan ($size / 10)
            }
        }
    }

    Context "Tests de charge avec filtrage" {
        BeforeAll {
            # PrÃ©parer une collection de messages variÃ©s pour les tests de filtrage
            $script:MessageCollection.Clear()
            
            $types = @([FeedbackType]::Error, [FeedbackType]::Warning, [FeedbackType]::Information, [FeedbackType]::Success, [FeedbackType]::Debug)
            $sources = @("Source1", "Source2", "Source3", "Source4", "Source5")
            
            for ($i = 0; $i -lt 1000; $i++) {
                $type = $types[$i % 5]
                $source = $sources[$i % 5]
                $severity = ($i % 5) + 1
                
                $message = [FeedbackMessage]::new($type, "Test message $i")
                $message.Source = $source
                $message.Severity = $severity
                
                Add-MessageToCollection -Message $message
            }
        }

        It "Doit filtrer efficacement par type" {
            $filter = [FeedbackFilter]::ForTypes(@([FeedbackType]::Error))
            
            $time = Measure-ExecutionTime {
                $filteredMessages = $script:MessageCollection.GetFilteredMessages($filter)
            }
            
            $time | Should -BeLessThan 1000
            $filteredMessages.Count | Should -Be 200  # 1000 / 5 = 200 messages d'erreur
        }

        It "Doit filtrer efficacement par source" {
            $filter = [FeedbackFilter]::ForSources(@("Source1"))
            
            $time = Measure-ExecutionTime {
                $filteredMessages = $script:MessageCollection.GetFilteredMessages($filter)
            }
            
            $time | Should -BeLessThan 1000
            $filteredMessages.Count | Should -Be 200  # 1000 / 5 = 200 messages de Source1
        }

        It "Doit filtrer efficacement par sÃ©vÃ©ritÃ©" {
            $filter = [FeedbackFilter]::ForSeverity(1, 2)
            
            $time = Measure-ExecutionTime {
                $filteredMessages = $script:MessageCollection.GetFilteredMessages($filter)
            }
            
            $time | Should -BeLessThan 1000
            $filteredMessages.Count | Should -Be 400  # 1000 / 5 * 2 = 400 messages de sÃ©vÃ©ritÃ© 1 ou 2
        }
    }

    Context "Tests de charge avec rotation" {
        It "Doit effectuer la rotation efficacement pour une grande collection" {
            $script:MessageCollection.Clear()
            
            # Ajouter un grand nombre de messages
            for ($i = 0; $i -lt 5000; $i++) {
                $message = New-TestMessage -Index $i
                Add-MessageToCollection -Message $message
            }
            
            $time = Measure-ExecutionTime {
                Invoke-CollectionRotation
            }
            
            $time | Should -BeLessThan 5000
            $script:MessageCollection.Messages.Count | Should -Be 0
        }
    }

    AfterAll {
        # Nettoyer les ressources
        if (Test-Path -Path $script:TestDir) {
            Remove-Item -Path $script:TestDir -Recurse -Force
        }
    }
}
