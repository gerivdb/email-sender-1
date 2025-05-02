#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires Pester simples pour le module ImplicitModuleDependencyDetector.

.DESCRIPTION
    Ce script contient des tests unitaires Pester simples pour le module
    ImplicitModuleDependencyDetector qui détecte les modules requis implicitement dans les scripts PowerShell.
#>

# Définir le chemin absolu du module à tester
$modulePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\scripts\dependency-management\ImplicitModuleDependencyDetector.psm1"
Write-Host "Module path: $modulePath"

# Vérifier si le fichier existe
if (-not (Test-Path -Path $modulePath -PathType Leaf)) {
    throw "Module not found at path: $modulePath"
}

# Importer le module
Import-Module $modulePath -Force -ErrorAction Stop

Describe "Tests simples du module ImplicitModuleDependencyDetector" {
    Context "Vérification de l'existence des fonctions" {
        It "La fonction Find-ModuleAliasWithoutExplicitImport existe" {
            Get-Command -Name Find-ModuleAliasWithoutExplicitImport -Module ImplicitModuleDependencyDetector -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "La fonction Find-ModuleReferenceInComments existe" {
            Get-Command -Name Find-ModuleReferenceInComments -Module ImplicitModuleDependencyDetector -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "La fonction Test-ModuleAvailability existe" {
            Get-Command -Name Test-ModuleAvailability -Module ImplicitModuleDependencyDetector -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "La fonction Confirm-ModuleDependencies existe" {
            Get-Command -Name Confirm-ModuleDependencies -Module ImplicitModuleDependencyDetector -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context "Test-ModuleAvailability" {
        It "Devrait vérifier correctement la disponibilité des modules intégrés" {
            $results = Test-ModuleAvailability -ModuleNames "Microsoft.PowerShell.Management", "Microsoft.PowerShell.Utility"
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -Be 2
            $results | ForEach-Object { $_.ValidationPassed | Should -BeTrue }
        }

        It "Devrait identifier correctement les modules non disponibles" {
            $results = Test-ModuleAvailability -ModuleNames "ModuleInexistant123"
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -Be 1
            $results[0].ValidationPassed | Should -BeFalse
            $results[0].Status | Should -Be "NotFound"
        }
    }

    Context "Tests de base" {
        It "PowerShell fonctionne correctement" {
            $true | Should -Be $true
        }

        It "Le fichier du module existe" {
            Test-Path -Path $modulePath -ErrorAction SilentlyContinue | Should -Be $true
        }

        It "Le module est correctement importé" {
            Get-Module -Name ImplicitModuleDependencyDetector -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}

# Nettoyer après les tests
Remove-Module -Name ImplicitModuleDependencyDetector -Force -ErrorAction SilentlyContinue
