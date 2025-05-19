# Tests unitaires pour la gestion des erreurs dans le module UnifiedParallel
#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    # Chemin du module à tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\UnifiedParallel.psm1"

    # Importer le module
    Import-Module $modulePath -Force

    # Initialiser le module
    Initialize-UnifiedParallel
}

Describe "Gestion des erreurs standardisée" {
    Context "New-UnifiedError" {
        It "Crée un objet d'erreur standardisé" {
            $errorMessage = "Message d'erreur de test"
            $errorSource = "Test-Function"
            
            $result = New-UnifiedError -Message $errorMessage -Source $errorSource
            
            $result | Should -Not -BeNullOrEmpty
            $result.Message | Should -Be $errorMessage
            $result.Source | Should -Be $errorSource
            $result.Id | Should -Not -BeNullOrEmpty
            $result.Timestamp | Should -BeOfType [datetime]
            $result.PSVersion | Should -Be $PSVersionTable.PSVersion
            $result.Category | Should -Be ([System.Management.Automation.ErrorCategory]::NotSpecified)
            $result.Exception | Should -Not -BeNullOrEmpty
            $result.Exception.Message | Should -Be $errorMessage
            $result.ErrorRecord | Should -Not -BeNullOrEmpty
            $result.CallStack | Should -Not -BeNullOrEmpty
            $result.CorrelationId | Should -Not -BeNullOrEmpty
        }
        
        It "Écrit une erreur dans le flux d'erreur avec WriteError" {
            # Capturer les erreurs écrites
            $errorOutput = $null
            try {
                $errorOutput = New-UnifiedError -Message "Erreur à écrire" -Source "Test-WriteError" -WriteError -ErrorAction SilentlyContinue 2>&1
            } catch {
                # Ne rien faire
            }
            
            $errorOutput | Should -Not -BeNullOrEmpty
            $errorOutput.ToString() | Should -BeLike "*[Test-WriteError] Erreur à écrire*"
        }
        
        It "Lance une exception avec ThrowError" {
            # Vérifier que l'erreur est lancée
            { New-UnifiedError -Message "Erreur à lancer" -ThrowError } | Should -Throw "Erreur à lancer"
        }
    }
    
    Context "Initialize-UnifiedParallel" {
        It "Utilise New-UnifiedError pour gérer les erreurs de création de répertoire" {
            # Créer un mock pour New-UnifiedError
            Mock New-UnifiedError { 
                return [PSCustomObject]@{
                    Message = $Message
                    Source = $Source
                    Category = $Category
                }
            }
            
            # Créer un mock pour New-Item qui échoue
            Mock New-Item { throw "Erreur de création de répertoire" }
            
            # Exécuter la fonction avec un chemin qui nécessite la création d'un répertoire
            $tempPath = Join-Path -Path $env:TEMP -ChildPath "TestUnifiedParallel_$(Get-Random)"
            Initialize-UnifiedParallel -LogPath $tempPath
            
            # Vérifier que New-UnifiedError a été appelé avec les bons paramètres
            Should -Invoke New-UnifiedError -Times 1 -ParameterFilter {
                $Message -eq "Impossible de créer le répertoire de logs" -and
                $Source -eq "Initialize-UnifiedParallel" -and
                $Category -eq [System.Management.Automation.ErrorCategory]::ResourceUnavailable
            }
        }
    }
    
    Context "Invoke-UnifiedParallel" {
        It "Utilise New-UnifiedError pour gérer les erreurs d'exécution parallèle" {
            # Créer un mock pour New-UnifiedError
            Mock New-UnifiedError { 
                if ($ThrowError) {
                    throw "Erreur lancée par New-UnifiedError"
                }
                return [PSCustomObject]@{
                    Message = $Message
                    Source = $Source
                    Category = $Category
                }
            }
            
            # Créer un mock pour Get-RunspacePoolFromCache qui échoue
            Mock Get-RunspacePoolFromCache { throw "Erreur de récupération du pool de runspaces" }
            
            # Exécuter la fonction avec IgnoreErrors pour éviter que l'erreur ne soit lancée
            Invoke-UnifiedParallel -ScriptBlock { "Test" } -InputObject @(1) -IgnoreErrors
            
            # Vérifier que New-UnifiedError a été appelé avec les bons paramètres
            Should -Invoke New-UnifiedError -Times 1 -ParameterFilter {
                $Message -eq "Erreur lors de l'exécution parallèle" -and
                $Source -eq "Invoke-UnifiedParallel" -and
                $Category -eq [System.Management.Automation.ErrorCategory]::OperationStopped
            }
        }
        
        It "Lance une exception avec ThrowError si IgnoreErrors n'est pas spécifié" {
            # Créer un mock pour New-UnifiedError qui lance une exception
            Mock New-UnifiedError { 
                if ($ThrowError) {
                    throw "Erreur lancée par New-UnifiedError"
                }
                return [PSCustomObject]@{
                    Message = $Message
                    Source = $Source
                    Category = $Category
                }
            }
            
            # Créer un mock pour Get-RunspacePoolFromCache qui échoue
            Mock Get-RunspacePoolFromCache { throw "Erreur de récupération du pool de runspaces" }
            
            # Exécuter la fonction sans IgnoreErrors pour que l'erreur soit lancée
            { Invoke-UnifiedParallel -ScriptBlock { "Test" } -InputObject @(1) } | Should -Throw "Erreur lancée par New-UnifiedError"
            
            # Vérifier que New-UnifiedError a été appelé avec les bons paramètres
            Should -Invoke New-UnifiedError -Times 1 -ParameterFilter {
                $Message -eq "Erreur lors de l'exécution parallèle" -and
                $Source -eq "Invoke-UnifiedParallel" -and
                $Category -eq [System.Management.Automation.ErrorCategory]::OperationStopped -and
                $ThrowError -eq $true
            }
        }
    }
}

AfterAll {
    # Nettoyer après tous les tests
    Clear-UnifiedParallel
}
