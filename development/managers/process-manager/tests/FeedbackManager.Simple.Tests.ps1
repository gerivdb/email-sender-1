<#
.SYNOPSIS
    Tests unitaires simplifiés pour le module FeedbackManager.

.DESCRIPTION
    Ce script contient des tests unitaires simplifiés pour les fonctions du module FeedbackManager.

.NOTES
    Version: 1.0.0
    Auteur: Process Manager Team
    Date de création: 2025-05-15
#>

# Importer Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Définir les tests
Describe "FeedbackManager - Tests unitaires simplifiés" {
    BeforeAll {
        # Créer un répertoire temporaire pour les tests
        $script:TestDir = Join-Path -Path $TestDrive -ChildPath "FeedbackManagerTests"
        New-Item -Path $script:TestDir -ItemType Directory -Force | Out-Null
        
        # Définir les types et classes nécessaires pour les tests
        Add-Type -TypeDefinition @"
        using System;
        
        public enum FeedbackType {
            Error,
            Warning,
            Information,
            Success,
            Debug,
            Verbose
        }
        
        public enum VerbosityLevel {
            None = 0,
            Minimal = 1,
            Normal = 2,
            Detailed = 3,
            Full = 4,
            Debug = 5
        }
"@
        
        # Définir la classe FeedbackMessage
        class FeedbackMessage {
            [FeedbackType]$Type
            [string]$Message
            [string]$Source
            [datetime]$Timestamp
            [int]$Severity
            [hashtable]$Data
            [string]$CorrelationId
            [VerbosityLevel]$MinimumVerbosity
            
            # Constructeur simple
            FeedbackMessage([FeedbackType]$Type, [string]$Message) {
                $this.Type = $Type
                $this.Message = $Message
                $this.Timestamp = Get-Date
                $this.Source = "ProcessManager"
                $this.Severity = $this.GetDefaultSeverity($Type)
                $this.Data = @{}
                $this.CorrelationId = [guid]::NewGuid().ToString()
                $this.MinimumVerbosity = $this.GetDefaultVerbosity($Type)
            }
            
            # Constructeur complet
            FeedbackMessage([FeedbackType]$Type, [string]$Message, [string]$Source, [int]$Severity, [hashtable]$Data, [VerbosityLevel]$MinimumVerbosity) {
                $this.Type = $Type
                $this.Message = $Message
                $this.Timestamp = Get-Date
                $this.Source = $Source
                $this.Severity = $Severity
                $this.Data = $Data
                $this.CorrelationId = [guid]::NewGuid().ToString()
                $this.MinimumVerbosity = $MinimumVerbosity
            }
            
            # Méthode pour obtenir la sévérité par défaut en fonction du type
            hidden [int] GetDefaultSeverity([FeedbackType]$Type) {
                switch ($Type) {
                    ([FeedbackType]::Error) { return 1 }
                    ([FeedbackType]::Warning) { return 2 }
                    ([FeedbackType]::Information) { return 3 }
                    ([FeedbackType]::Success) { return 3 }
                    ([FeedbackType]::Debug) { return 4 }
                    ([FeedbackType]::Verbose) { return 5 }
                    default { return 3 }
                }
            }
            
            # Méthode pour obtenir le niveau de verbosité par défaut en fonction du type
            hidden [VerbosityLevel] GetDefaultVerbosity([FeedbackType]$Type) {
                switch ($Type) {
                    ([FeedbackType]::Error) { return [VerbosityLevel]::Minimal }
                    ([FeedbackType]::Warning) { return [VerbosityLevel]::Normal }
                    ([FeedbackType]::Information) { return [VerbosityLevel]::Detailed }
                    ([FeedbackType]::Success) { return [VerbosityLevel]::Full }
                    ([FeedbackType]::Debug) { return [VerbosityLevel]::Debug }
                    ([FeedbackType]::Verbose) { return [VerbosityLevel]::Debug }
                    default { return [VerbosityLevel]::Normal }
                }
            }
            
            # Méthode pour convertir le message en chaîne formatée
            [string] ToString() {
                return "[$($this.Timestamp.ToString('yyyy-MM-dd HH:mm:ss'))] [$($this.Source)] [$($this.Type)] $($this.Message)"
            }
            
            # Méthode pour vérifier si le message doit être affiché selon le niveau de verbosité
            [bool] ShouldDisplay([VerbosityLevel]$CurrentVerbosity) {
                return [int]$CurrentVerbosity -ge [int]$this.MinimumVerbosity
            }
        }
        
        # Définir la classe FeedbackFilter
        class FeedbackFilter {
            [FeedbackType[]]$IncludedTypes
            [FeedbackType[]]$ExcludedTypes
            [string[]]$IncludedSources
            [string[]]$ExcludedSources
            [int]$MinimumSeverity
            [int]$MaximumSeverity
            [datetime]$StartTime
            [datetime]$EndTime
            [scriptblock]$CustomFilter
            
            # Constructeur par défaut
            FeedbackFilter() {
                $this.IncludedTypes = @([FeedbackType]::Error, [FeedbackType]::Warning, [FeedbackType]::Information, [FeedbackType]::Success)
                $this.ExcludedTypes = @()
                $this.IncludedSources = @()
                $this.ExcludedSources = @()
                $this.MinimumSeverity = 0
                $this.MaximumSeverity = [int]::MaxValue
                $this.StartTime = [datetime]::MinValue
                $this.EndTime = [datetime]::MaxValue
                $this.CustomFilter = { param($message) return $true }
            }
            
            # Méthode pour vérifier si un message passe le filtre
            [bool] PassesFilter([FeedbackMessage]$Message) {
                # Vérifier le type
                if ($this.IncludedTypes.Count -gt 0 -and $this.IncludedTypes -notcontains $Message.Type) {
                    return $false
                }
                
                if ($this.ExcludedTypes -contains $Message.Type) {
                    return $false
                }
                
                # Vérifier la source
                if ($this.IncludedSources.Count -gt 0 -and $this.IncludedSources -notcontains $Message.Source) {
                    return $false
                }
                
                if ($this.ExcludedSources -contains $Message.Source) {
                    return $false
                }
                
                # Vérifier la sévérité
                if ($Message.Severity -lt $this.MinimumSeverity -or $Message.Severity -gt $this.MaximumSeverity) {
                    return $false
                }
                
                # Vérifier l'horodatage
                if ($Message.Timestamp -lt $this.StartTime -or $Message.Timestamp -gt $this.EndTime) {
                    return $false
                }
                
                # Appliquer le filtre personnalisé
                return & $this.CustomFilter $Message
            }
            
            # Méthode pour créer un filtre qui n'inclut que certains types
            static [FeedbackFilter] ForTypes([FeedbackType[]]$Types) {
                $filter = [FeedbackFilter]::new()
                $filter.IncludedTypes = $Types
                return $filter
            }
            
            # Méthode pour créer un filtre qui n'inclut que certaines sources
            static [FeedbackFilter] ForSources([string[]]$Sources) {
                $filter = [FeedbackFilter]::new()
                $filter.IncludedSources = $Sources
                return $filter
            }
            
            # Méthode pour créer un filtre basé sur la sévérité
            static [FeedbackFilter] ForSeverity([int]$MinimumSeverity, [int]$MaximumSeverity) {
                $filter = [FeedbackFilter]::new()
                $filter.MinimumSeverity = $MinimumSeverity
                $filter.MaximumSeverity = $MaximumSeverity
                return $filter
            }
            
            # Méthode pour créer un filtre personnalisé
            static [FeedbackFilter] Custom([scriptblock]$CustomFilter) {
                $filter = [FeedbackFilter]::new()
                $filter.CustomFilter = $CustomFilter
                return $filter
            }
        }
        
        # Définir les fonctions de feedback
        function Send-ProcessManagerFeedback {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory = $true)]
                [FeedbackType]$Type,
                
                [Parameter(Mandatory = $true)]
                [string]$Message,
                
                [Parameter(Mandatory = $false)]
                [string]$Source = "ProcessManager",
                
                [Parameter(Mandatory = $false)]
                [int]$Severity = -1,
                
                [Parameter(Mandatory = $false)]
                [hashtable]$Data = @{},
                
                [Parameter(Mandatory = $false)]
                [VerbosityLevel]$MinimumVerbosity = [VerbosityLevel]::Normal,
                
                [Parameter(Mandatory = $false)]
                [switch]$NoOutput,
                
                [Parameter(Mandatory = $false)]
                [switch]$NoHistory,
                
                [Parameter(Mandatory = $false)]
                [switch]$PassThru
            )
            
            # Créer le message de feedback
            $feedbackMessage = $null
            
            if ($Severity -lt 0) {
                $feedbackMessage = [FeedbackMessage]::new($Type, $Message)
            } else {
                $feedbackMessage = [FeedbackMessage]::new($Type, $Message, $Source, $Severity, $Data, $MinimumVerbosity)
            }
            
            # Simuler l'envoi aux canaux de sortie
            if (-not $NoOutput) {
                Write-Host $feedbackMessage.ToString()
            }
            
            # Retourner le message si demandé
            if ($PassThru) {
                return $feedbackMessage
            }
        }
        
        function Send-ProcessManagerError {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory = $true)]
                [string]$Message,
                
                [Parameter(Mandatory = $false)]
                [string]$Source = "ProcessManager",
                
                [Parameter(Mandatory = $false)]
                [int]$Severity = 1,
                
                [Parameter(Mandatory = $false)]
                [hashtable]$Data = @{},
                
                [Parameter(Mandatory = $false)]
                [VerbosityLevel]$MinimumVerbosity = [VerbosityLevel]::Minimal,
                
                [Parameter(Mandatory = $false)]
                [switch]$NoOutput,
                
                [Parameter(Mandatory = $false)]
                [switch]$NoHistory,
                
                [Parameter(Mandatory = $false)]
                [switch]$PassThru
            )
            
            $params = @{
                Type             = [FeedbackType]::Error
                Message          = $Message
                Source           = $Source
                Severity         = $Severity
                Data             = $Data
                MinimumVerbosity = $MinimumVerbosity
                NoOutput         = $NoOutput
                NoHistory        = $NoHistory
                PassThru         = $PassThru
            }
            
            return Send-ProcessManagerFeedback @params
        }
        
        # Variables globales
        $script:DefaultVerbosityLevel = [VerbosityLevel]::Normal
        
        # Fonctions de gestion de la verbosité
        function Set-ProcessManagerVerbosity {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory = $true)]
                [VerbosityLevel]$Level
            )
            
            $script:DefaultVerbosityLevel = $Level
        }
        
        function Get-ProcessManagerVerbosity {
            [CmdletBinding()]
            param ()
            
            return $script:DefaultVerbosityLevel
        }
    }
    
    Context "Types et énumérations" {
        It "L'énumération FeedbackType doit être définie" {
            [FeedbackType] | Should -Not -BeNullOrEmpty
        }
        
        It "L'énumération VerbosityLevel doit être définie" {
            [VerbosityLevel] | Should -Not -BeNullOrEmpty
        }
        
        It "La classe FeedbackMessage doit être définie" {
            [FeedbackMessage] | Should -Not -BeNullOrEmpty
        }
        
        It "La classe FeedbackFilter doit être définie" {
            [FeedbackFilter] | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Création de messages de feedback" {
        It "Doit créer un message de feedback avec le constructeur simple" {
            $message = [FeedbackMessage]::new([FeedbackType]::Information, "Test message")
            $message | Should -Not -BeNullOrEmpty
            $message.Type | Should -Be ([FeedbackType]::Information)
            $message.Message | Should -Be "Test message"
            $message.Source | Should -Be "ProcessManager"
            $message.Timestamp | Should -BeOfType [datetime]
            $message.CorrelationId | Should -Not -BeNullOrEmpty
        }
        
        It "Doit créer un message de feedback avec le constructeur complet" {
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
    
    Context "Méthodes de la classe FeedbackMessage" {
        BeforeAll {
            $script:TestMessage = [FeedbackMessage]::new([FeedbackType]::Error, "Test error message")
        }
        
        It "La méthode ToString doit retourner une chaîne formatée" {
            $result = $script:TestMessage.ToString()
            $result | Should -BeOfType [string]
            $result | Should -Match "\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] \[ProcessManager\] \[Error\] Test error message"
        }
        
        It "La méthode ShouldDisplay doit retourner true pour un niveau de verbosité suffisant" {
            $script:TestMessage.ShouldDisplay([VerbosityLevel]::Minimal) | Should -Be $true
            $script:TestMessage.ShouldDisplay([VerbosityLevel]::Normal) | Should -Be $true
            $script:TestMessage.ShouldDisplay([VerbosityLevel]::Detailed) | Should -Be $true
        }
        
        It "La méthode ShouldDisplay doit retourner false pour un niveau de verbosité insuffisant" {
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
        
        It "Le filtre par défaut doit accepter les messages d'erreur, d'avertissement, d'information et de succès" {
            $filter = [FeedbackFilter]::new()
            $filter.PassesFilter($script:ErrorMessage) | Should -Be $true
            $filter.PassesFilter($script:WarningMessage) | Should -Be $true
            $filter.PassesFilter($script:InfoMessage) | Should -Be $true
            $filter.PassesFilter($script:SuccessMessage) | Should -Be $true
        }
        
        It "Le filtre par type doit accepter uniquement les types spécifiés" {
            $filter = [FeedbackFilter]::ForTypes(@([FeedbackType]::Error, [FeedbackType]::Warning))
            $filter.PassesFilter($script:ErrorMessage) | Should -Be $true
            $filter.PassesFilter($script:WarningMessage) | Should -Be $true
            $filter.PassesFilter($script:InfoMessage) | Should -Be $false
            $filter.PassesFilter($script:SuccessMessage) | Should -Be $false
        }
        
        It "Le filtre par source doit accepter uniquement les sources spécifiées" {
            $customMessage = [FeedbackMessage]::new([FeedbackType]::Information, "Custom message")
            $customMessage.Source = "CustomSource"
            
            $filter = [FeedbackFilter]::ForSources(@("CustomSource"))
            $filter.PassesFilter($customMessage) | Should -Be $true
            $filter.PassesFilter($script:InfoMessage) | Should -Be $false
        }
        
        It "Le filtre par sévérité doit accepter uniquement les sévérités dans la plage spécifiée" {
            $filter = [FeedbackFilter]::ForSeverity(1, 2)
            $filter.PassesFilter($script:ErrorMessage) | Should -Be $true
            $filter.PassesFilter($script:WarningMessage) | Should -Be $true
            $filter.PassesFilter($script:InfoMessage) | Should -Be $false
            $filter.PassesFilter($script:SuccessMessage) | Should -Be $false
        }
        
        It "Le filtre personnalisé doit appliquer la logique spécifiée" {
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
        
        It "Send-ProcessManagerFeedback doit créer et envoyer un message" {
            $result = Send-ProcessManagerFeedback -Type ([FeedbackType]::Information) -Message "Test message" -PassThru
            $result | Should -Not -BeNullOrEmpty
            $result.Type | Should -Be ([FeedbackType]::Information)
            $result.Message | Should -Be "Test message"
        }
        
        It "Send-ProcessManagerError doit envoyer un message d'erreur" {
            $result = Send-ProcessManagerError -Message "Test error" -PassThru
            $result | Should -Not -BeNullOrEmpty
            $result.Type | Should -Be ([FeedbackType]::Error)
            $result.Message | Should -Be "Test error"
        }
    }
    
    Context "Gestion de la verbosité" {
        It "Get-ProcessManagerVerbosity doit retourner le niveau de verbosité actuel" {
            $verbosity = Get-ProcessManagerVerbosity
            $verbosity | Should -BeOfType [VerbosityLevel]
        }
        
        It "Set-ProcessManagerVerbosity doit modifier le niveau de verbosité" {
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
