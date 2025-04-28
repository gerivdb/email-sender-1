<#
.SYNOPSIS
    Tests unitaires pour la gestion des erreurs PowerShell.
.DESCRIPTION
    Ce script contient des tests unitaires pour la gestion des erreurs PowerShell.
.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date crÃ©ation:  09/04/2025
#>

# DÃ©finir les tests Pester
Describe "Tests de gestion des erreurs PowerShell" {
    Context "CrÃ©ation et manipulation d'erreurs" {
        It "Devrait crÃ©er une erreur PowerShell" {
            # CrÃ©er une erreur factice
            $exception = New-Object System.Exception("Erreur de test")
            $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                $exception,
                "TestError",
                [System.Management.Automation.ErrorCategory]::NotSpecified,
                $null
            )
            
            # VÃ©rifier que l'erreur a Ã©tÃ© crÃ©Ã©e correctement
            $errorRecord | Should -Not -BeNullOrEmpty
            $errorRecord.Exception.Message | Should -Be "Erreur de test"
            $errorRecord.FullyQualifiedErrorId | Should -Be "TestError"
        }
        
        It "Devrait capturer une erreur avec try/catch" {
            # DÃ©finir une variable pour vÃ©rifier si l'erreur a Ã©tÃ© capturÃ©e
            $errorCaptured = $false
            
            # Essayer d'exÃ©cuter une commande qui gÃ©nÃ¨re une erreur
            try {
                Get-Item -Path "C:\CeCheminNExistePas" -ErrorAction Stop
            }
            catch {
                $errorCaptured = $true
                $_.Exception | Should -Not -BeNullOrEmpty
                $_.Exception.Message | Should -Match "Impossible de trouver le chemin"
            }
            
            # VÃ©rifier que l'erreur a Ã©tÃ© capturÃ©e
            $errorCaptured | Should -BeTrue
        }
        
        It "Devrait enregistrer une erreur dans la variable $Error" {
            # Vider la variable $Error
            $Error.Clear()
            
            # ExÃ©cuter une commande qui gÃ©nÃ¨re une erreur
            Get-Item -Path "C:\CeCheminNExistePas" -ErrorAction SilentlyContinue
            
            # VÃ©rifier que l'erreur a Ã©tÃ© enregistrÃ©e dans la variable $Error
            $Error.Count | Should -BeGreaterThan 0
            $Error[0].Exception.Message | Should -Match "Impossible de trouver le chemin"
        }
    }
    
    Context "Analyse des erreurs" {
        It "Devrait extraire des informations d'une erreur" {
            # CrÃ©er une erreur factice
            $exception = New-Object System.Exception("Erreur de test")
            $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                $exception,
                "TestError",
                [System.Management.Automation.ErrorCategory]::NotSpecified,
                $null
            )
            
            # Extraire des informations de l'erreur
            $errorInfo = [PSCustomObject]@{
                Message = $errorRecord.Exception.Message
                ErrorId = $errorRecord.FullyQualifiedErrorId
                Category = $errorRecord.CategoryInfo.Category
                TargetObject = $errorRecord.TargetObject
                ScriptStackTrace = $errorRecord.ScriptStackTrace
            }
            
            # VÃ©rifier que les informations ont Ã©tÃ© extraites correctement
            $errorInfo.Message | Should -Be "Erreur de test"
            $errorInfo.ErrorId | Should -Be "TestError"
            $errorInfo.Category | Should -Be "NotSpecified"
        }
    }
}
