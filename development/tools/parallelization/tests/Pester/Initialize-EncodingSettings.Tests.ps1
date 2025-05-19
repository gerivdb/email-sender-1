# Tests unitaires pour la fonction Initialize-EncodingSettings
#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    # Chemin du module à tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\UnifiedParallel.psm1"

    # Importer le module
    Import-Module $modulePath -Force
}

Describe "Initialize-EncodingSettings" {
    BeforeEach {
        # Sauvegarder les encodages actuels
        $originalOutputEncoding = $OutputEncoding
        $originalConsoleEncoding = [Console]::OutputEncoding
        $originalDefaultParams = $PSDefaultParameterValues.Clone()

        # Réinitialiser les paramètres par défaut
        $PSDefaultParameterValues = @{}
    }

    AfterEach {
        # Restaurer les encodages originaux
        $OutputEncoding = $originalOutputEncoding
        [Console]::OutputEncoding = $originalConsoleEncoding
        $PSDefaultParameterValues = $originalDefaultParams
    }

    Context "Paramètres par défaut" {
        It "Configure correctement l'encodage de sortie" {
            # Exécuter la fonction à tester
            $result = Initialize-EncodingSettings

            # Vérifier que la fonction a réussi
            $result.Success | Should -Be $true

            # Vérifier que l'encodage de sortie est UTF-8
            $OutputEncoding.WebName | Should -Be "utf-8"
            [Console]::OutputEncoding.WebName | Should -Be "utf-8"

            # Vérifier que les informations d'encodage sont correctes
            $result.PSVersion | Should -Be $PSVersionTable.PSVersion
            $result.PreviousOutputEncoding | Should -Be $originalOutputEncoding
            $result.PreviousConsoleEncoding | Should -Be $originalConsoleEncoding
            $result.CurrentOutputEncoding.WebName | Should -Be "utf-8"
            $result.CurrentConsoleEncoding.WebName | Should -Be "utf-8"
            $result.ConfiguredConsole | Should -Be $true
            $result.ConfiguredParameters | Should -Be $true
            $result.UsedBOM | Should -Be $true
        }

        It "Configure correctement les paramètres par défaut pour les cmdlets" {
            # Exécuter la fonction à tester
            $result = Initialize-EncodingSettings

            # Vérifier que la fonction a réussi
            $result.Success | Should -Be $true

            # Vérifier que les paramètres par défaut sont configurés
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                $PSDefaultParameterValues['Out-File:Encoding'] | Should -Be 'utf8BOM'
                $PSDefaultParameterValues['Set-Content:Encoding'] | Should -Be 'utf8BOM'
                $PSDefaultParameterValues['Add-Content:Encoding'] | Should -Be 'utf8BOM'
                $PSDefaultParameterValues['Export-Csv:Encoding'] | Should -Be 'utf8BOM'
                $PSDefaultParameterValues['Export-Clixml:Encoding'] | Should -Be 'utf8BOM'
                $PSDefaultParameterValues['Export-PSSession:Encoding'] | Should -Be 'utf8BOM'
            } else {
                $PSDefaultParameterValues['Out-File:Encoding'] | Should -Be 'utf8'
                $PSDefaultParameterValues['Set-Content:Encoding'] | Should -Be 'utf8'
                $PSDefaultParameterValues['Add-Content:Encoding'] | Should -Be 'utf8'
                $PSDefaultParameterValues['Export-Csv:Encoding'] | Should -Be 'utf8'
                $PSDefaultParameterValues['Export-Clixml:Encoding'] | Should -Be 'utf8'
                $PSDefaultParameterValues['Export-PSSession:Encoding'] | Should -Be 'utf8'
            }
        }
    }

    Context "Paramètres personnalisés" {
        It "Respecte le paramètre UseBOM = `$false" {
            # Exécuter la fonction à tester avec UseBOM = $false
            $result = Initialize-EncodingSettings -UseBOM $false

            # Vérifier que la fonction a réussi
            $result.Success | Should -Be $true

            # Vérifier que les paramètres par défaut sont configurés sans BOM
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                $PSDefaultParameterValues['Out-File:Encoding'] | Should -Be 'utf8NoBOM'
                $PSDefaultParameterValues['Set-Content:Encoding'] | Should -Be 'utf8NoBOM'
                $PSDefaultParameterValues['Add-Content:Encoding'] | Should -Be 'utf8NoBOM'
            }

            # Vérifier que UsedBOM est correctement défini
            $result.UsedBOM | Should -Be $false
        }

        It "Respecte le paramètre ConfigureConsole = `$false" {
            # Sauvegarder les encodages actuels
            $beforeOutputEncoding = $OutputEncoding
            $beforeConsoleEncoding = [Console]::OutputEncoding

            # Exécuter la fonction à tester avec ConfigureConsole = $false
            $result = Initialize-EncodingSettings -ConfigureConsole $false

            # Vérifier que la fonction a réussi
            $result.Success | Should -Be $true

            # Vérifier que l'encodage de la console n'a pas été modifié
            $OutputEncoding | Should -Be $beforeOutputEncoding
            [Console]::OutputEncoding | Should -Be $beforeConsoleEncoding

            # Vérifier que ConfiguredConsole est correctement défini
            $result.ConfiguredConsole | Should -Be $false
        }

        It "Respecte le paramètre ConfigureDefaultParameters = `$false" {
            # Exécuter la fonction à tester avec ConfigureDefaultParameters = $false
            $result = Initialize-EncodingSettings -ConfigureDefaultParameters $false

            # Vérifier que la fonction a réussi
            $result.Success | Should -Be $true

            # Vérifier que les paramètres par défaut n'ont pas été configurés
            $PSDefaultParameterValues.Count | Should -Be 0

            # Vérifier que ConfiguredParameters est correctement défini
            $result.ConfiguredParameters | Should -Be $false
        }
    }

    Context "Gestion des caractères accentués" {
        It "Gère correctement les caractères accentués" {
            # Exécuter la fonction à tester
            $result = Initialize-EncodingSettings

            # Vérifier que la fonction a réussi
            $result.Success | Should -Be $true

            # Créer un fichier temporaire avec des caractères accentués
            $tempFile = [System.IO.Path]::GetTempFileName()
            $testString = "Caractères accentués : éèêëàâäùûüôöçÉÈÊËÀÂÄÙÛÜÔÖÇ"

            # Écrire dans le fichier
            $testString | Out-File -FilePath $tempFile

            # Lire le contenu du fichier
            $content = Get-Content -Path $tempFile -Raw

            # Vérifier que les caractères accentués sont préservés
            $content.Trim() | Should -Be $testString

            # Nettoyer
            Remove-Item -Path $tempFile -Force
        }
    }

    Context "Gestion des différences entre PowerShell 5.1 et 7.x" {
        It "Gère correctement les différences entre PowerShell 5.1 et 7.x" {
            # Exécuter la fonction à tester
            $result = Initialize-EncodingSettings

            # Vérifier que la fonction a réussi
            $result.Success | Should -Be $true

            # Vérifier que les paramètres sont configurés en fonction de la version de PowerShell
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                $PSDefaultParameterValues['Out-File:Encoding'] | Should -Be 'utf8BOM'
            } else {
                $PSDefaultParameterValues['Out-File:Encoding'] | Should -Be 'utf8'
            }
        }
    }
}

AfterAll {
    # Nettoyer après tous les tests
    # Restaurer les encodages par défaut
    $OutputEncoding = [System.Text.Encoding]::Default
    [Console]::OutputEncoding = [System.Text.Encoding]::Default
    $PSDefaultParameterValues = @{}
}
