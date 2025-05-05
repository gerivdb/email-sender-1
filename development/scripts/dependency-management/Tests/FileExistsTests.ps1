#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires Pester pour vÃ©rifier l'existence du fichier du module.

.DESCRIPTION
    Ce script contient des tests unitaires Pester pour vÃ©rifier l'existence du fichier du module.
#>

Describe "Tests d'existence du fichier du module" {
    Context "VÃ©rification du fichier" {
        It "Le fichier du module existe" {
            $modulePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\scripts\dependency-management\ImplicitModuleDependencyDetector.psm1"
            Test-Path -Path $modulePath | Should -Be $true
        }

        It "Le fichier du module est un fichier PowerShell" {
            $modulePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\scripts\dependency-management\ImplicitModuleDependencyDetector.psm1"
            $extension = [System.IO.Path]::GetExtension($modulePath)
            $extension | Should -Be ".psm1"
        }

        It "Le fichier du module contient du contenu" {
            $modulePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\scripts\dependency-management\ImplicitModuleDependencyDetector.psm1"
            $content = Get-Content -Path $modulePath -Raw
            $content | Should -Not -BeNullOrEmpty
        }

        It "Le fichier du module contient la fonction Find-ModuleAliasWithoutExplicitImport" {
            $modulePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\scripts\dependency-management\ImplicitModuleDependencyDetector.psm1"
            $content = Get-Content -Path $modulePath -Raw
            $content | Should -Match "function Find-ModuleAliasWithoutExplicitImport"
        }

        It "Le fichier du module contient la fonction Find-ModuleReferenceInComments" {
            $modulePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\scripts\dependency-management\ImplicitModuleDependencyDetector.psm1"
            $content = Get-Content -Path $modulePath -Raw
            $content | Should -Match "function Find-ModuleReferenceInComments"
        }

        It "Le fichier du module contient la fonction Test-ModuleAvailability" {
            $modulePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\scripts\dependency-management\ImplicitModuleDependencyDetector.psm1"
            $content = Get-Content -Path $modulePath -Raw
            $content | Should -Match "function Test-ModuleAvailability"
        }

        It "Le fichier du module contient la fonction Confirm-ModuleDependencies" {
            $modulePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\scripts\dependency-management\ImplicitModuleDependencyDetector.psm1"
            $content = Get-Content -Path $modulePath -Raw
            $content | Should -Match "function Confirm-ModuleDependencies"
        }

        It "Le fichier du module exporte les fonctions" {
            $modulePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\scripts\dependency-management\ImplicitModuleDependencyDetector.psm1"
            $content = Get-Content -Path $modulePath -Raw
            $content | Should -Match "Export-ModuleMember"
        }

        It "Le fichier du module exporte la fonction Find-ModuleAliasWithoutExplicitImport" {
            $modulePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\scripts\dependency-management\ImplicitModuleDependencyDetector.psm1"
            $content = Get-Content -Path $modulePath -Raw
            $content | Should -Match "Export-ModuleMember.*Find-ModuleAliasWithoutExplicitImport"
        }

        It "Le fichier du module exporte la fonction Find-ModuleReferenceInComments" {
            $modulePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\scripts\dependency-management\ImplicitModuleDependencyDetector.psm1"
            $content = Get-Content -Path $modulePath -Raw
            $content | Should -Match "Export-ModuleMember.*Find-ModuleReferenceInComments"
        }
    }
}
