# Manage-Roadmap.Tests.ps1
# Tests unitaires pour le script Manage-Roadmap.ps1

BeforeAll {
    # Chemins des fichiers
    $script:scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\development\scripts\maintenance\Manage-Roadmap.ps1"
    $script:splitRoadmapPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\development\scripts\maintenance\Split-Roadmap.ps1"
    $script:updateRoadmapStatusPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\development\scripts\maintenance\Update-RoadmapStatus.ps1"
    $script:navigateRoadmapPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\development\scripts\maintenance\Navigate-Roadmap.ps1"

    # VÃ©rifier que les scripts existent
    if (-not (Test-Path -Path $scriptPath)) {
        throw "Le script Manage-Roadmap.ps1 n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement: $scriptPath"
    }

    if (-not (Test-Path -Path $splitRoadmapPath)) {
        throw "Le script Split-Roadmap.ps1 n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement: $splitRoadmapPath"
    }

    if (-not (Test-Path -Path $updateRoadmapStatusPath)) {
        throw "Le script Update-RoadmapStatus.ps1 n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement: $updateRoadmapStatusPath"
    }

    if (-not (Test-Path -Path $navigateRoadmapPath)) {
        throw "Le script Navigate-Roadmap.ps1 n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement: $navigateRoadmapPath"
    }

    # Mock pour les appels aux scripts externes
    function global:MockScriptCall {
        param (
            [string]$ScriptPath,
            [hashtable]$Parameters
        )

        # Enregistrer l'appel pour vÃ©rification ultÃ©rieure
        $script:lastScriptCall = @{
            ScriptPath = $ScriptPath
            Parameters = $Parameters
        }

        return $true
    }
}

Describe "Manage-Roadmap" {
    BeforeEach {
        # RÃ©initialiser les variables de mock
        $script:lastScriptCall = $null

        # RedÃ©finir les fonctions pour les tests
        function global:MockScriptCall {
            param (
                [string]$ScriptPath,
                [hashtable]$Parameters
            )

            # Enregistrer l'appel pour vÃ©rification ultÃ©rieure
            $script:lastScriptCall = @{
                ScriptPath = $ScriptPath
                Parameters = $Parameters
            }

            return $true
        }

        # CrÃ©er une fonction de mock pour les appels aux scripts
        function global:InvokeScriptMock {
            param (
                [string]$ScriptPath,
                [object[]]$Arguments
            )

            if ($ScriptPath -eq $splitRoadmapPath -or
                $ScriptPath -eq $updateRoadmapStatusPath -or
                $ScriptPath -eq $navigateRoadmapPath) {
                return MockScriptCall -ScriptPath $ScriptPath -Parameters $Arguments[0]
            } else {
                # Pour les autres appels, retourner une valeur par dÃ©faut
                return $null
            }
        }

        # Remplacer la fonction & par notre mock
        Set-Alias -Name "&" -Value InvokeScriptMock -Scope Global -Force

        # RedÃ©finir les commandes externes
        function global:code { param($Path) return $null }
        function global:notepad { param($Path) return $null }
        function global:Get-Command {
            param($Name)
            if ($Name -eq 'code') { return $true }
            else { Microsoft.PowerShell.Core\Get-Command $Name }
        }
    }

    Context "Action Split" {
        It "Devrait appeler Split-Roadmap.ps1 avec les paramÃ¨tres corrects" {
            & $scriptPath -Action "Split" -Force -ArchiveSections

            $script:lastScriptCall | Should -Not -BeNullOrEmpty
            $script:lastScriptCall.ScriptPath | Should -Be $splitRoadmapPath
            $script:lastScriptCall.Parameters.Force | Should -Be $true
            $script:lastScriptCall.Parameters.ArchiveCompletedSections | Should -Be $true
        }
    }

    Context "Action Update" {
        It "Devrait Ã©chouer si TaskId n'est pas spÃ©cifiÃ©" {
            $output = & $scriptPath -Action "Update" -Status "Complete" 2>&1

            $output | Should -Match "L'identifiant de la tÃ¢che est requis"
            $script:lastScriptCall | Should -BeNullOrEmpty
        }

        It "Devrait Ã©chouer si Status n'est pas spÃ©cifiÃ©" {
            $output = & $scriptPath -Action "Update" -TaskId "1.1.2" 2>&1

            $output | Should -Match "Le statut est requis"
            $script:lastScriptCall | Should -BeNullOrEmpty
        }

        It "Devrait appeler Update-RoadmapStatus.ps1 avec les paramÃ¨tres corrects" {
            & $scriptPath -Action "Update" -TaskId "1.1.2" -Status "Complete"

            $script:lastScriptCall | Should -Not -BeNullOrEmpty
            $script:lastScriptCall.ScriptPath | Should -Be $updateRoadmapStatusPath
            $script:lastScriptCall.Parameters.TaskId | Should -Be "1.1.2"
            $script:lastScriptCall.Parameters.Status | Should -Be "Complete"
            $script:lastScriptCall.Parameters.AutoArchive | Should -Be $true
        }
    }

    Context "Action Navigate" {
        It "Devrait appeler Navigate-Roadmap.ps1 avec les paramÃ¨tres corrects" {
            & $scriptPath -Action "Navigate" -NavigateMode "Search" -SearchTerm "test" -DetailLevel 3 -OpenInEditor

            $script:lastScriptCall | Should -Not -BeNullOrEmpty
            $script:lastScriptCall.ScriptPath | Should -Be $navigateRoadmapPath
            $script:lastScriptCall.Parameters.Mode | Should -Be "Search"
            $script:lastScriptCall.Parameters.SearchTerm | Should -Be "test"
            $script:lastScriptCall.Parameters.DetailLevel | Should -Be 3
            $script:lastScriptCall.Parameters.OpenInEditor | Should -Be $true
        }

        It "Devrait transmettre SectionId si spÃ©cifiÃ©" {
            & $scriptPath -Action "Navigate" -SectionId "1.1.2"

            $script:lastScriptCall | Should -Not -BeNullOrEmpty
            $script:lastScriptCall.ScriptPath | Should -Be $navigateRoadmapPath
            $script:lastScriptCall.Parameters.SectionId | Should -Be "1.1.2"
        }
    }

    Context "Action Report" {
        It "Devrait appeler Update-RoadmapStatus.ps1 avec le paramÃ¨tre GenerateReport" {
            & $scriptPath -Action "Report"

            $script:lastScriptCall | Should -Not -BeNullOrEmpty
            $script:lastScriptCall.ScriptPath | Should -Be $updateRoadmapStatusPath
            $script:lastScriptCall.Parameters.GenerateReport | Should -Be $true
        }
    }

    Context "Action Help" {
        It "Devrait afficher l'aide" {
            $output = & $scriptPath -Action "Help" 2>&1

            $output | Should -Match "GESTION DE LA ROADMAP"
            $output | Should -Match "SYNTAXE"
            $output | Should -Match "ACTIONS"
            $output | Should -Match "OPTIONS"
            $output | Should -Match "EXEMPLES"
        }
    }

    Context "Action non reconnue" {
        It "Devrait afficher un message d'erreur et l'aide" {
            $output = & $scriptPath -Action "InvalidAction" 2>&1

            $output | Should -Match "Action non reconnue"
            $output | Should -Match "GESTION DE LA ROADMAP"
        }
    }
}
