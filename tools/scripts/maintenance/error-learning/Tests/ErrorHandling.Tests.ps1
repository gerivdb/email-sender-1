<#
.SYNOPSIS
    Tests unitaires pour la gestion des erreurs PowerShell.
.DESCRIPTION
    Ce script contient des tests unitaires pour la gestion des erreurs PowerShell.
.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date création:  09/04/2025
#>

# Définir les tests Pester
Describe "Tests de gestion des erreurs PowerShell" {
    Context "Création et manipulation d'erreurs" {
        It "Devrait créer une erreur PowerShell" {
            # Créer une erreur factice
            $exception = New-Object System.Exception("Erreur de test")
            $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                $exception,
                "TestError",
                [System.Management.Automation.ErrorCategory]::NotSpecified,
                $null
            )
            
            # Vérifier que l'erreur a été créée correctement
            $errorRecord | Should -Not -BeNullOrEmpty
            $errorRecord.Exception.Message | Should -Be "Erreur de test"
            $errorRecord.FullyQualifiedErrorId | Should -Be "TestError"
        }
        
        It "Devrait capturer une erreur avec try/catch" {
            # Définir une variable pour vérifier si l'erreur a été capturée
            $errorCaptured = $false
            
            # Essayer d'exécuter une commande qui génère une erreur
            try {
                Get-Item -Path "C:\CeCheminNExistePas" -ErrorAction Stop
            }
            catch {
                $errorCaptured = $true
                $_.Exception | Should -Not -BeNullOrEmpty
                $_.Exception.Message | Should -Match "Impossible de trouver le chemin"
            }
            
            # Vérifier que l'erreur a été capturée
            $errorCaptured | Should -BeTrue
        }
        
        It "Devrait enregistrer une erreur dans la variable $Error" {
            # Vider la variable $Error
            $Error.Clear()
            
            # Exécuter une commande qui génère une erreur
            Get-Item -Path "C:\CeCheminNExistePas" -ErrorAction SilentlyContinue
            
            # Vérifier que l'erreur a été enregistrée dans la variable $Error
            $Error.Count | Should -BeGreaterThan 0
            $Error[0].Exception.Message | Should -Match "Impossible de trouver le chemin"
        }
    }
    
    Context "Analyse des erreurs" {
        It "Devrait extraire des informations d'une erreur" {
            # Créer une erreur factice
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
            
            # Vérifier que les informations ont été extraites correctement
            $errorInfo.Message | Should -Be "Erreur de test"
            $errorInfo.ErrorId | Should -Be "TestError"
            $errorInfo.Category | Should -Be "NotSpecified"
        }
    }
}
