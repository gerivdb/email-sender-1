---
to: development/scripts/modes/tests/<%= nameLower %>-mode.tests.ps1
---
<#
.SYNOPSIS
    Tests unitaires pour le mode <%= name %>

.DESCRIPTION
    Tests unitaires pour le mode <%= name %> (<%= description %>).
    Généré automatiquement le <%= date %>

.NOTES
    Auteur: Généré automatiquement
    Date de création: <%= date %>
#>

# Importer Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer le module de test
Import-Module Pester -Force

# Chemin vers le script à tester
$scriptPath = "$PSScriptRoot/../<%= nameLower %>-mode.ps1"

Describe "Tests du mode <%= name %>" {
    BeforeAll {
        # Mock des fonctions du module ModesCommon
        Mock -CommandName Import-Module -MockWith { }
        Mock -CommandName Initialize-Mode -MockWith { }
        Mock -CommandName Write-Log -MockWith { }
    }

    Context "Tests de base" {
        It "Le script existe" {
            Test-Path $scriptPath | Should -Be $true
        }

        It "Le script est valide syntaxiquement" {
            $psFile = Get-Item -Path $scriptPath
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize($psFile.FullName, [ref]$errors)
            $errors.Count | Should -Be 0
        }
    }

    Context "Tests des commandes standard" {
        BeforeEach {
            # Mocks pour les fonctions standard
            Mock -CommandName Invoke-<%= name %>Run -MockWith { }
            Mock -CommandName Get-<%= name %>Status -MockWith { }
            Mock -CommandName Start-<%= name %>Debug -MockWith { }
            Mock -CommandName Invoke-<%= name %>Test -MockWith { }
            Mock -CommandName Get-<%= name %>Help -MockWith { }
        }

        It "La commande RUN appelle Invoke-<%= name %>Run" {
            & $scriptPath -Command "RUN" -Target "test" -Options @{}
            Should -Invoke -CommandName Invoke-<%= name %>Run -Times 1 -Exactly
        }

        It "La commande CHECK appelle Get-<%= name %>Status" {
            & $scriptPath -Command "CHECK" -Target "test" -Options @{}
            Should -Invoke -CommandName Get-<%= name %>Status -Times 1 -Exactly
        }

        It "La commande DEBUG appelle Start-<%= name %>Debug" {
            & $scriptPath -Command "DEBUG" -Target "test" -Options @{}
            Should -Invoke -CommandName Start-<%= name %>Debug -Times 1 -Exactly
        }

        It "La commande TEST appelle Invoke-<%= name %>Test" {
            & $scriptPath -Command "TEST" -Target "test" -Options @{}
            Should -Invoke -CommandName Invoke-<%= name %>Test -Times 1 -Exactly
        }

        It "La commande HELP appelle Get-<%= name %>Help" {
            & $scriptPath -Command "HELP" -Target "test" -Options @{}
            Should -Invoke -CommandName Get-<%= name %>Help -Times 1 -Exactly
        }
    }

    Context "Tests des commandes spécifiques" {
<% commands.forEach(function(cmd) { 
    if (!['RUN', 'CHECK', 'DEBUG', 'TEST', 'HELP'].includes(cmd.name)) { %>
        It "La commande <%= cmd.name %> appelle <%= cmd.function %>" {
            Mock -CommandName <%= cmd.function %> -MockWith { }
            & $scriptPath -Command "<%= cmd.name %>" -Target "test" -Options @{}
            Should -Invoke -CommandName <%= cmd.function %> -Times 1 -Exactly
        }

<% }
}); %>
    }

    Context "Tests des fonctions standard" {
        It "Invoke-<%= name %>Run fonctionne correctement" {
            # TODO: Implémenter des tests spécifiques pour Invoke-<%= name %>Run
            $true | Should -Be $true
        }

        It "Get-<%= name %>Status fonctionne correctement" {
            # TODO: Implémenter des tests spécifiques pour Get-<%= name %>Status
            $true | Should -Be $true
        }

        It "Start-<%= name %>Debug fonctionne correctement" {
            # TODO: Implémenter des tests spécifiques pour Start-<%= name %>Debug
            $true | Should -Be $true
        }

        It "Invoke-<%= name %>Test fonctionne correctement" {
            # TODO: Implémenter des tests spécifiques pour Invoke-<%= name %>Test
            $true | Should -Be $true
        }

        It "Get-<%= name %>Help fonctionne correctement" {
            # TODO: Implémenter des tests spécifiques pour Get-<%= name %>Help
            $true | Should -Be $true
        }
    }

    Context "Tests des fonctions spécifiques" {
<% commands.forEach(function(cmd) { 
    if (!['RUN', 'CHECK', 'DEBUG', 'TEST', 'HELP'].includes(cmd.name)) { %>
        It "<%= cmd.function %> fonctionne correctement" {
            # TODO: Implémenter des tests spécifiques pour <%= cmd.function %>
            $true | Should -Be $true
        }

<% }
}); %>
    }
}
