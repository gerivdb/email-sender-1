<#
.SYNOPSIS
    Tests unitaires pour les fonctions du systÃ¨me d'apprentissage des erreurs.
.DESCRIPTION
    Ce script contient des tests unitaires pour les fonctions du systÃ¨me d'apprentissage des erreurs.
.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date crÃ©ation:  09/04/2025
#>

# DÃ©finir les tests Pester
Describe "Tests des fonctions du systÃ¨me d'apprentissage des erreurs" {
    Context "Fonctions de base" {
        It "Devrait pouvoir crÃ©er une erreur" {
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
        
        It "Devrait pouvoir convertir une erreur en chaÃ®ne" {
            # CrÃ©er une erreur factice
            $exception = New-Object System.Exception("Erreur de test")
            $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                $exception,
                "TestError",
                [System.Management.Automation.ErrorCategory]::NotSpecified,
                $null
            )
            
            # Convertir l'erreur en chaÃ®ne
            $errorString = $errorRecord.ToString()
            
            # VÃ©rifier que la chaÃ®ne contient les informations de l'erreur
            $errorString | Should -Not -BeNullOrEmpty
            $errorString | Should -Match "Erreur de test"
        }
        
        It "Devrait pouvoir crÃ©er un objet d'analyse d'erreur" {
            # CrÃ©er un objet d'analyse d'erreur
            $errorAnalysis = [PSCustomObject]@{
                Errors = @(
                    [PSCustomObject]@{
                        ErrorId = "TestError1"
                        Message = "Erreur de test 1"
                        Category = "TestCategory1"
                        Source = "TestSource1"
                        Timestamp = Get-Date
                    },
                    [PSCustomObject]@{
                        ErrorId = "TestError2"
                        Message = "Erreur de test 2"
                        Category = "TestCategory2"
                        Source = "TestSource2"
                        Timestamp = Get-Date
                    }
                )
                Statistics = [PSCustomObject]@{
                    TotalErrors = 2
                    ErrorsByCategory = @{
                        TestCategory1 = 1
                        TestCategory2 = 1
                    }
                    ErrorsBySource = @{
                        TestSource1 = 1
                        TestSource2 = 1
                    }
                }
            }
            
            # VÃ©rifier que l'objet d'analyse d'erreur a Ã©tÃ© crÃ©Ã© correctement
            $errorAnalysis | Should -Not -BeNullOrEmpty
            $errorAnalysis.Errors.Count | Should -Be 2
            $errorAnalysis.Errors[0].ErrorId | Should -Be "TestError1"
            $errorAnalysis.Errors[1].ErrorId | Should -Be "TestError2"
            $errorAnalysis.Statistics.TotalErrors | Should -Be 2
            $errorAnalysis.Statistics.ErrorsByCategory.TestCategory1 | Should -Be 1
            $errorAnalysis.Statistics.ErrorsByCategory.TestCategory2 | Should -Be 1
            $errorAnalysis.Statistics.ErrorsBySource.TestSource1 | Should -Be 1
            $errorAnalysis.Statistics.ErrorsBySource.TestSource2 | Should -Be 1
        }
    }
}
