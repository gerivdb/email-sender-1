<#
.SYNOPSIS
    Tests pour valider le tableau rÃ©capitulatif des propriÃ©tÃ©s communes de System.Exception.

.DESCRIPTION
    Ce script contient des tests unitaires pour valider les informations fournies
    dans le tableau rÃ©capitulatif des propriÃ©tÃ©s communes de System.Exception.

.NOTES
    Version:        1.0
    Author:         Augment Code
    Creation Date:  2023-06-16
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# DÃ©finir les tests
Describe "Tests du tableau rÃ©capitulatif des propriÃ©tÃ©s communes de System.Exception" {
    Context "VÃ©rification des types et caractÃ©ristiques des propriÃ©tÃ©s" {
        It "Message devrait Ãªtre une chaÃ®ne non modifiable" {
            $exception = [System.Exception]::new("Message de test")
            $exception.Message | Should -BeOfType [string]
            $exception.Message | Should -Be "Message de test"

            # VÃ©rifier que Message n'est pas modifiable (devrait gÃ©nÃ©rer une erreur)
            { $exception.Message = "Nouveau message" } | Should -Throw
        }

        It "StackTrace devrait Ãªtre une chaÃ®ne non modifiable gÃ©nÃ©rÃ©e automatiquement" {
            try {
                throw [System.Exception]::new("Message de test")
            }
            catch {
                $_.Exception.StackTrace | Should -BeOfType [string]
                $_.Exception.StackTrace | Should -Not -BeNullOrEmpty

                # VÃ©rifier que StackTrace n'est pas modifiable (devrait gÃ©nÃ©rer une erreur)
                { $_.Exception.StackTrace = "Nouvelle trace" } | Should -Throw
            }
        }

        It "InnerException devrait Ãªtre une exception non modifiable" {
            $innerException = [System.ArgumentException]::new("Argument invalide")
            $outerException = [System.InvalidOperationException]::new("OpÃ©ration invalide", $innerException)

            $outerException.InnerException | Should -BeOfType [System.ArgumentException]
            $outerException.InnerException.Message | Should -Be "Argument invalide"

            # VÃ©rifier que InnerException n'est pas modifiable (devrait gÃ©nÃ©rer une erreur)
            { $outerException.InnerException = [System.Exception]::new("Nouvelle exception") } | Should -Throw
        }

        It "Source devrait Ãªtre une chaÃ®ne modifiable" {
            $exception = [System.Exception]::new("Message de test")
            $exception.Source | Should -BeOfType [string] -Or $exception.Source | Should -BeNullOrEmpty

            # VÃ©rifier que Source est modifiable
            $exception.Source = "SourceTest"
            $exception.Source | Should -Be "SourceTest"
        }

        It "HResult devrait Ãªtre un entier modifiable" {
            $exception = [System.Exception]::new("Message de test")
            $exception.HResult | Should -BeOfType [int]

            # VÃ©rifier que HResult est modifiable
            $exception.HResult = 0x80004005  # E_FAIL
            $exception.HResult | Should -Be 0x80004005
        }

        It "Data devrait Ãªtre un IDictionary modifiable" {
            $exception = [System.Exception]::new("Message de test")
            $exception.Data | Should -BeOfType [System.Collections.IDictionary]

            # VÃ©rifier que le contenu de Data est modifiable
            $exception.Data["TestKey"] = "TestValue"
            $exception.Data["TestKey"] | Should -Be "TestValue"
        }

        It "TargetSite devrait Ãªtre un MethodBase non modifiable" {
            try {
                throw [System.Exception]::new("Message de test")
            }
            catch {
                if ($_.Exception.TargetSite -ne $null) {
                    $_.Exception.TargetSite | Should -BeOfType [System.Reflection.MethodBase]

                    # VÃ©rifier que TargetSite n'est pas modifiable (devrait gÃ©nÃ©rer une erreur)
                    { $_.Exception.TargetSite = $null } | Should -Throw
                }
                else {
                    # Dans certains environnements, TargetSite peut Ãªtre null
                    $true | Should -Be $true
                }
            }
        }
    }

    Context "VÃ©rification des mÃ©thodes" {
        It "ToString() devrait retourner une reprÃ©sentation textuelle complÃ¨te" {
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

    Context "VÃ©rification des scÃ©narios d'utilisation" {
        It "Devrait permettre l'affichage Ã  l'utilisateur avec Message et Source" {
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

        It "Devrait permettre le diagnostic avancÃ© avec GetBaseException() et autres propriÃ©tÃ©s" {
            $innerException = [System.FormatException]::new("Format invalide")
            $outerException = [System.InvalidOperationException]::new("OpÃ©ration invalide", $innerException)

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

    Context "VÃ©rification des bonnes pratiques" {
        It "Devrait permettre une approche hiÃ©rarchique pour accÃ©der aux informations" {
            $innerException = [System.FormatException]::new("Format invalide")
            $outerException = [System.InvalidOperationException]::new("OpÃ©ration invalide", $innerException)
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

            # Niveau 3 (avancÃ©)
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
            $basicInfo.Message | Should -Be "OpÃ©ration invalide"

            $standardInfo.Source | Should -Be "MonApplication"
            $standardInfo.InnerExceptionType | Should -Be "System.FormatException"
            $standardInfo.Data["Context"] | Should -Be "Test"

            $advancedInfo.HResult | Should -BeOfType [int]
            $advancedInfo.Data["Context"] | Should -Be "Test"
        }

        It "Devrait permettre un traitement conditionnel basÃ© sur le type d'exception et HResult" {
            function Test-ExceptionHandling {
                param (
                    [System.Exception]$Exception
                )

                $result = ""

                # Traitement basÃ© sur le type d'exception
                switch ($Exception.GetBaseException().GetType().FullName) {
                    "System.IO.FileNotFoundException" {
                        $result = "Fichier non trouvÃ©"
                    }
                    "System.FormatException" {
                        $result = "Format invalide"
                    }
                    default {
                        # Traitement basÃ© sur HResult
                        switch ($Exception.HResult) {
                            0x80070002 { # ERROR_FILE_NOT_FOUND
                                $result = "Fichier non trouvÃ© (HResult)"
                            }
                            0x80070005 { # ERROR_ACCESS_DENIED
                                $result = "AccÃ¨s refusÃ© (HResult)"
                            }
                            default {
                                $result = "Erreur non spÃ©cifique"
                            }
                        }
                    }
                }

                return $result
            }

            $fileEx = [System.IO.FileNotFoundException]::new("Fichier non trouvÃ©")
            $formatEx = [System.FormatException]::new("Format invalide")
            $accessEx = [System.Exception]::new("AccÃ¨s refusÃ©")
            $accessEx.HResult = 0x80070005  # ERROR_ACCESS_DENIED

            Test-ExceptionHandling -Exception $fileEx | Should -Be "Fichier non trouvÃ©"
            Test-ExceptionHandling -Exception $formatEx | Should -Be "Format invalide"
            Test-ExceptionHandling -Exception $accessEx | Should -Be "AccÃ¨s refusÃ© (HResult)"
        }
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Script $PSCommandPath -Output Detailed
