#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires Pester pour les nouvelles fonctionnalitÃ©s du module ImplicitModuleDependencyDetector.

.DESCRIPTION
    Ce script contient des tests unitaires Pester pour les nouvelles fonctionnalitÃ©s du module
    ImplicitModuleDependencyDetector, notamment la dÃ©tection des alias de modules, des variables
    de modules, l'analyse des commentaires et la validation des modules.
#>

# DÃ©finir le chemin absolu du module Ã  tester
$modulePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\scripts\dependency-management\ImplicitModuleDependencyDetector.psm1"
Write-Host "Module path: $modulePath"

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $modulePath -PathType Leaf)) {
    throw "Module not found at path: $modulePath"
}

# Importer le module
Import-Module $modulePath -Force -ErrorAction Stop

Describe "Nouvelles fonctionnalitÃ©s du module ImplicitModuleDependencyDetector" {
    BeforeAll {

        # CrÃ©er un script PowerShell de test avec diffÃ©rentes rÃ©fÃ©rences
        $script:scriptWithAliases = @'
# Ce script utilise des alias de modules sans les importer explicitement
# RÃ©fÃ©rence Ã  AD (ActiveDirectory)
$adUser = Get-ADUser -Identity "jdoe"

# RÃ©fÃ©rence Ã  Azure dans une chaÃ®ne
$message = "Connexion Ã  Azure en cours..."

# RÃ©fÃ©rence Ã  SQL dans une variable
$SQLConnection = "Server=localhost;Database=master;Integrated Security=True;"

# RÃ©fÃ©rence Ã  Pester dans un commentaire
# Utiliser Pester pour les tests unitaires
'@

        $script:scriptWithComments = @'
# Ce script contient des rÃ©fÃ©rences Ã  des modules dans les commentaires
# Utiliser ActiveDirectory pour la gestion des utilisateurs
# Az.Accounts pour la gestion des comptes Azure
# SqlServer pour les requÃªtes SQL
# Pester pour les tests unitaires

# RÃ©fÃ©rence Ã  des cmdlets dans les commentaires
# Get-ADUser, New-AzVM, Invoke-Sqlcmd, Describe

# RÃ©fÃ©rence Ã  des types dans les commentaires
# Microsoft.ActiveDirectory.Management.ADUser
# Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine

# Directive Requires
#Requires -Modules ActiveDirectory, Az.Accounts
'@

        $script:scriptWithVariables = @'
# Ce script utilise des variables globales de modules sans les importer explicitement
# RÃ©fÃ©rence Ã  PSVersionTable (Microsoft.PowerShell.Core)
$version = $PSVersionTable.PSVersion

# RÃ©fÃ©rence Ã  AzContext (Az.Accounts)
$subscription = $AzContext.Subscription.Name

# RÃ©fÃ©rence Ã  PesterPreference (Pester)
$PesterPreference.Output.Verbosity = 'Detailed'

# RÃ©fÃ©rence Ã  une variable avec un nom qui suit un modÃ¨le de module
$ADUserInfo = Get-UserInfo -Identity "jdoe"
'@

        $script:scriptWithDependencies = @'
# Ce script utilise des cmdlets sans importer explicitement les modules
# Utilisation de cmdlets de Microsoft.PowerShell.Management
Get-Process | Where-Object { $_.CPU -gt 10 } | Stop-Process -Force

# Utilisation de cmdlets de Microsoft.PowerShell.Utility
Write-Output "Processus arrÃªtÃ©s"
'@
    }

    Context "Find-ModuleAliasWithoutExplicitImport" {
        It "Devrait dÃ©tecter les rÃ©fÃ©rences Ã  des alias de modules dans un script" {
            $results = Find-ModuleAliasWithoutExplicitImport -ScriptContent $script:scriptWithAliases
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0
        }

        It "Devrait identifier correctement les modules correspondant aux alias" {
            $results = Find-ModuleAliasWithoutExplicitImport -ScriptContent $script:scriptWithAliases
            $adAlias = $results | Where-Object { $_.AliasName -eq "AD" }
            $adAlias | Should -Not -BeNullOrEmpty
            $adAlias.ModuleName | Should -Be "ActiveDirectory"
        }
    }

    Context "Find-ModuleReferenceInComments" {
        It "Devrait dÃ©tecter les rÃ©fÃ©rences Ã  des modules dans les commentaires" {
            $results = Find-ModuleReferenceInComments -ScriptContent $script:scriptWithComments
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0
        }

        It "Devrait identifier correctement les types de rÃ©fÃ©rences" {
            $results = Find-ModuleReferenceInComments -ScriptContent $script:scriptWithComments
            $explicitModuleRefs = $results | Where-Object { $_.Type -eq "ExplicitModule" }
            $explicitModuleRefs | Should -Not -BeNullOrEmpty
        }
    }

    Context "Test-ModuleAvailability" {
        It "Devrait vÃ©rifier correctement la disponibilitÃ© des modules intÃ©grÃ©s" {
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

    Context "Confirm-ModuleDependencies" {
        It "Devrait dÃ©tecter et valider correctement les dÃ©pendances implicites" {
            $results = Confirm-ModuleDependencies -ScriptContent $script:scriptWithDependencies
            $results | Should -Not -BeNullOrEmpty
            $results.Status | Should -Be "AllModulesAvailable"
            $results.ValidationPassed | Should -BeTrue
        }

        It "Devrait gÃ©nÃ©rer correctement les instructions Import-Module si demandÃ©" {
            $results = Confirm-ModuleDependencies -ScriptContent $script:scriptWithDependencies -GenerateImportStatements
            $results.ImportStatements | Should -Not -BeNullOrEmpty
            $results.ImportStatements.Count | Should -BeGreaterThan 0
        }
    }
}
