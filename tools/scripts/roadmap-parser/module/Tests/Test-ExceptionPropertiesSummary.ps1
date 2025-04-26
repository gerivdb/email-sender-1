<#
.SYNOPSIS
    Tests pour valider le tableau récapitulatif des propriétés communes de System.Exception.

.DESCRIPTION
    Ce script contient des tests unitaires pour valider les informations fournies
    dans le tableau récapitulatif des propriétés communes de System.Exception.

.NOTES
    Version:        1.0
    Author:         Augment Code
    Creation Date:  2023-06-16
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Définir les tests
Describe "Tests du tableau récapitulatif des propriétés communes de System.Exception" {
    Context "Vérification des types et caractéristiques des propriétés" {
        It "Message devrait être une chaîne non modifiable" {
            $exception = [System.Exception]::new("Message de test")
            $exception.Message | Should -BeOfType [string]
            $exception.Message | Should -Be "Message de test"

            # Vérifier que Message n'est pas modifiable (devrait générer une erreur)
            { $exception.Message = "Nouveau message" } | Should -Throw
        }

        It "StackTrace devrait être une chaîne non modifiable générée automatiquement" {
            try {
                throw [System.Exception]::new("Message de test")
            }
            catch {
                $_.Exception.StackTrace | Should -BeOfType [string]
                $_.Exception.StackTrace | Should -Not -BeNullOrEmpty

                # Vérifier que StackTrace n'est pas modifiable (devrait générer une erreur)
                { $_.Exception.StackTrace = "Nouvelle trace" } | Should -Throw
            }
        }

        It "InnerException devrait être une exception non modifiable" {
            $innerException = [System.ArgumentException]::new("Argument invalide")
            $outerException = [System.InvalidOperationException]::new("Opération invalide", $innerException)

            $outerException.InnerException | Should -BeOfType [System.ArgumentException]
            $outerException.InnerException.Message | Should -Be "Argument invalide"

            # Vérifier que InnerException n'est pas modifiable (devrait générer une erreur)
            { $outerException.InnerException = [System.Exception]::new("Nouvelle exception") } | Should -Throw
        }

        It "Source devrait être une chaîne modifiable" {
            $exception = [System.Exception]::new("Message de test")
            $exception.Source | Should -BeOfType [string] -Or $exception.Source | Should -BeNullOrEmpty

            # Vérifier que Source est modifiable
            $exception.Source = "SourceTest"
            $exception.Source | Should -Be "SourceTest"
        }

        It "HResult devrait être un entier modifiable" {
            $exception = [System.Exception]::new("Message de test")
            $exception.HResult | Should -BeOfType [int]

            # Vérifier que HResult est modifiable
            $exception.HResult = 0x80004005  # E_FAIL
            $exception.HResult | Should -Be 0x80004005
        }

        It "Data devrait être un IDictionary modifiable" {
            $exception = [System.Exception]::new("Message de test")
            $exception.Data | Should -BeOfType [System.Collections.IDictionary]

            # Vérifier que le contenu de Data est modifiable
            $exception.Data["TestKey"] = "TestValue"
            $exception.Data["TestKey"] | Should -Be "TestValue"
        }

        It "TargetSite devrait être un MethodBase non modifiable" {
            try {
                throw [System.Exception]::new("Message de test")
            }
            catch {
                if ($_.Exception.TargetSite -ne $null) {
                    $_.Exception.TargetSite | Should -BeOfType [System.Reflection.MethodBase]

                    # Vérifier que TargetSite n'est pas modifiable (devrait générer une erreur)
                    { $_.Exception.TargetSite = $null } | Should -Throw
                }
                else {
                    # Dans certains environnements, TargetSite peut être null
                    $true | Should -Be $true
                }
            }
        }
    }

    Context "Vérification des méthodes" {
        It "ToString() devrait retourner une représentation textuelle complète" {
            $exception = [System.Exception]::new("Message de test")
            $toString = $exception.ToString()

            $toString | Should -BeOfType [string]
            $toString | Should -Match "System.Exception"
            $toString | Should -Match "Message de test"
        }

        It "GetBaseException() devrait retourner l'exception racine" {
            $level3 = [System.FormatException]::new("Niveau 3")
            $level2 = [System.IO.IOException]::new("Niveau 2", $level3)
            $level1 = [System.InvalidOperationException]::new("Niveau 1", $level2)

            $baseException = $level1.GetBaseException()

            $baseException | Should -Be $level3
            $baseException.GetType().FullName | Should -Be "System.FormatException"
            $baseException.Message | Should -Be "Niveau 3"
        }
    }

    Context "Vérification des scénarios d'utilisation" {
        It "Devrait permettre l'affichage à l'utilisateur avec Message et Source" {
            $exception = [System.Exception]::new("Message d'erreur")
            $exception.Source = "MonApplication"

            $userMessage = "Erreur: $($exception.Message) (Source: $($exception.Source))"

            $userMessage | Should -Match "Erreur: Message d'erreur"
            $userMessage | Should -Match "Source: MonApplication"
        }

        It "Devrait permettre la journalisation avec ToString()" {
            $exception = [System.Exception]::new("Message d'erreur")
            $logEntry = $exception.ToString()

            $logEntry | Should -Match "System.Exception"
            $logEntry | Should -Match "Message d'erreur"
        }

        It "Devrait permettre le diagnostic avancé avec GetBaseException() et autres propriétés" {
            $innerException = [System.FormatException]::new("Format invalide")
            $outerException = [System.InvalidOperationException]::new("Opération invalide", $innerException)

            $diagnosticInfo = [PSCustomObject]@{
                RootExceptionType = $outerException.GetBaseException().GetType().FullName
                RootExceptionMessage = $outerException.GetBaseException().Message
                OriginalHResult = $outerException.HResult
            }

            $diagnosticInfo.RootExceptionType | Should -Be "System.FormatException"
            $diagnosticInfo.RootExceptionMessage | Should -Be "Format invalide"
            $diagnosticInfo.OriginalHResult | Should -BeOfType [int]
        }

        It "Devrait permettre l'enrichissement contextuel avec Data" {
            $exception = [System.Exception]::new("Message d'erreur")
            $exception.Data["Timestamp"] = Get-Date
            $exception.Data["Operation"] = "TestOperation"
            $exception.Data["Parameters"] = @{ Param1 = "Value1"; Param2 = 42 }

            $exception.Data["Timestamp"] | Should -Not -BeNullOrEmpty
            $exception.Data["Operation"] | Should -Be "TestOperation"
            $exception.Data["Parameters"].Param1 | Should -Be "Value1"
            $exception.Data["Parameters"].Param2 | Should -Be 42
        }
    }

    Context "Vérification des bonnes pratiques" {
        It "Devrait permettre une approche hiérarchique pour accéder aux informations" {
            $innerException = [System.FormatException]::new("Format invalide")
            $outerException = [System.InvalidOperationException]::new("Opération invalide", $innerException)
            $outerException.Source = "MonApplication"
            $outerException.Data["Context"] = "Test"

            # Niveau 1 (basique)
            $basicInfo = [PSCustomObject]@{
                Type = $outerException.GetType().FullName
                Message = $outerException.Message
            }

            # Niveau 2 (standard)
            $standardInfo = [PSCustomObject]@{
                Type = $outerException.GetType().FullName
                Message = $outerException.Message
                Source = $outerException.Source
                InnerExceptionType = if ($outerException.InnerException -ne $null) { $outerException.InnerException.GetType().FullName } else { $null }
                Data = @{}
            }
            foreach ($key in $outerException.Data.Keys) {
                $standardInfo.Data[$key] = $outerException.Data[$key]
            }

            # Niveau 3 (avancé)
            $advancedInfo = [PSCustomObject]@{
                Type = $outerException.GetType().FullName
                Message = $outerException.Message
                Source = $outerException.Source
                InnerExceptionType = if ($outerException.InnerException -ne $null) { $outerException.InnerException.GetType().FullName } else { $null }
                Data = @{}
                HResult = $outerException.HResult
                StackTrace = $outerException.StackTrace
                TargetSite = if ($outerException.TargetSite -ne $null) { $outerException.TargetSite.Name } else { $null }
            }
            foreach ($key in $outerException.Data.Keys) {
                $advancedInfo.Data[$key] = $outerException.Data[$key]
            }

            $basicInfo.Type | Should -Be "System.InvalidOperationException"
            $basicInfo.Message | Should -Be "Opération invalide"

            $standardInfo.Source | Should -Be "MonApplication"
            $standardInfo.InnerExceptionType | Should -Be "System.FormatException"
            $standardInfo.Data["Context"] | Should -Be "Test"

            $advancedInfo.HResult | Should -BeOfType [int]
            $advancedInfo.Data["Context"] | Should -Be "Test"
        }

        It "Devrait permettre un traitement conditionnel basé sur le type d'exception et HResult" {
            function Test-ExceptionHandling {
                param (
                    [System.Exception]$Exception
                )

                $result = ""

                # Traitement basé sur le type d'exception
                switch ($Exception.GetBaseException().GetType().FullName) {
                    "System.IO.FileNotFoundException" {
                        $result = "Fichier non trouvé"
                    }
                    "System.FormatException" {
                        $result = "Format invalide"
                    }
                    default {
                        # Traitement basé sur HResult
                        switch ($Exception.HResult) {
                            0x80070002 { # ERROR_FILE_NOT_FOUND
                                $result = "Fichier non trouvé (HResult)"
                            }
                            0x80070005 { # ERROR_ACCESS_DENIED
                                $result = "Accès refusé (HResult)"
                            }
                            default {
                                $result = "Erreur non spécifique"
                            }
                        }
                    }
                }

                return $result
            }

            $fileEx = [System.IO.FileNotFoundException]::new("Fichier non trouvé")
            $formatEx = [System.FormatException]::new("Format invalide")
            $accessEx = [System.Exception]::new("Accès refusé")
            $accessEx.HResult = 0x80070005  # ERROR_ACCESS_DENIED

            Test-ExceptionHandling -Exception $fileEx | Should -Be "Fichier non trouvé"
            Test-ExceptionHandling -Exception $formatEx | Should -Be "Format invalide"
            Test-ExceptionHandling -Exception $accessEx | Should -Be "Accès refusé (HResult)"
        }
    }
}

# Exécuter les tests
Invoke-Pester -Script $PSCommandPath -Output Detailed
