# Tests unitaires pour la fonction New-UnifiedError
#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    # Chemin du module à tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\UnifiedParallel.psm1"

    # Importer le module
    Import-Module $modulePath -Force
}

Describe "New-UnifiedError" {
    Context "Création d'objets d'erreur" {
        It "Crée un objet d'erreur avec les paramètres de base" {
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
        
        It "Crée un objet d'erreur avec une catégorie spécifiée" {
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
            
            $result = New-UnifiedError -Message "Test" -Category $errorCategory
            
            $result.Category | Should -Be $errorCategory
            $result.ErrorRecord.CategoryInfo.Category | Should -Be $errorCategory
        }
        
        It "Crée un objet d'erreur avec un ID spécifié" {
            $errorId = "TEST-001"
            
            $result = New-UnifiedError -Message "Test" -ErrorId $errorId
            
            $result.Id | Should -Be $errorId
        }
        
        It "Crée un objet d'erreur avec des informations supplémentaires" {
            $additionalInfo = @{
                "Param1" = "Value1"
                "Param2" = 123
            }
            
            $result = New-UnifiedError -Message "Test" -AdditionalInfo $additionalInfo
            
            $result.AdditionalInfo | Should -Not -BeNullOrEmpty
            $result.AdditionalInfo.Count | Should -Be 2
            $result.AdditionalInfo["Param1"] | Should -Be "Value1"
            $result.AdditionalInfo["Param2"] | Should -Be 123
        }
        
        It "Crée un objet d'erreur à partir d'un ErrorRecord existant" {
            # Créer un ErrorRecord
            $errorRecord = $null
            try {
                throw "Erreur de test"
            } catch {
                $errorRecord = $_
            }
            
            $result = New-UnifiedError -ErrorRecord $errorRecord -Source "Test-Function"
            
            $result | Should -Not -BeNullOrEmpty
            $result.Message | Should -Be "Erreur de test"
            $result.Source | Should -Be "Test-Function"
            $result.ErrorRecord | Should -Be $errorRecord
            $result.Exception | Should -Be $errorRecord.Exception
        }
    }
    
    Context "Options WriteError et ThrowError" {
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
        
        It "Retourne l'objet d'erreur même avec WriteError" {
            $result = New-UnifiedError -Message "Test avec WriteError" -WriteError -ErrorAction SilentlyContinue
            
            $result | Should -Not -BeNullOrEmpty
            $result.Message | Should -Be "Test avec WriteError"
        }
        
        It "Ajoute des informations supplémentaires au message d'erreur" {
            $additionalInfo = @{
                "Param1" = "Value1"
                "Param2" = 123
            }
            
            $errorOutput = $null
            try {
                $errorOutput = New-UnifiedError -Message "Erreur avec infos" -AdditionalInfo $additionalInfo -WriteError -ErrorAction SilentlyContinue 2>&1
            } catch {
                # Ne rien faire
            }
            
            $errorOutput | Should -Not -BeNullOrEmpty
            $errorOutput.ToString() | Should -BeLike "*Erreur avec infos*"
            $errorOutput.ToString() | Should -BeLike "*Informations supplémentaires*"
            $errorOutput.ToString() | Should -BeLike "*Param1 : Value1*"
            $errorOutput.ToString() | Should -BeLike "*Param2 : 123*"
        }
    }
    
    Context "Compatibilité PowerShell 5.1 et 7.x" {
        It "Fonctionne correctement avec PowerShell $($PSVersionTable.PSVersion)" {
            $result = New-UnifiedError -Message "Test de compatibilité"
            
            $result | Should -Not -BeNullOrEmpty
            $result.PSVersion | Should -Be $PSVersionTable.PSVersion
        }
    }
}

AfterAll {
    # Nettoyer après tous les tests
}
