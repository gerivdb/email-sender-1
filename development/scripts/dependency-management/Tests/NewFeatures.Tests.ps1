#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires Pester pour les nouvelles fonctionnalités du module ImplicitModuleDependencyDetector.

.DESCRIPTION
    Ce script contient des tests unitaires Pester pour les nouvelles fonctionnalités du module
    ImplicitModuleDependencyDetector, notamment la détection des alias de modules, des variables
    de modules, l'analyse des commentaires et la validation des modules.
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

Describe "Nouvelles fonctionnalités du module ImplicitModuleDependencyDetector" {
    BeforeAll {

        # Créer un script PowerShell de test avec différentes références
        $script:scriptWithAliases = @'
# Ce script utilise des alias de modules sans les importer explicitement
# Référence à AD (ActiveDirectory)
$adUser = Get-ADUser -Identity "jdoe"

# Référence à Azure dans une chaîne
$message = "Connexion à Azure en cours..."

# Référence à SQL dans une variable
$SQLConnection = "Server=localhost;Database=master;Integrated Security=True;"

# Référence à Pester dans un commentaire
# Utiliser Pester pour les tests unitaires
'@

        $script:scriptWithComments = @'
# Ce script contient des références à des modules dans les commentaires
# Utiliser ActiveDirectory pour la gestion des utilisateurs
# Az.Accounts pour la gestion des comptes Azure
# SqlServer pour les requêtes SQL
# Pester pour les tests unitaires

# Référence à des cmdlets dans les commentaires
# Get-ADUser, New-AzVM, Invoke-Sqlcmd, Describe

# Référence à des types dans les commentaires
# Microsoft.ActiveDirectory.Management.ADUser
# Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine

# Directive Requires
#Requires -Modules ActiveDirectory, Az.Accounts
'@

        $script:scriptWithVariables = @'
# Ce script utilise des variables globales de modules sans les importer explicitement
# Référence à PSVersionTable (Microsoft.PowerShell.Core)
$version = $PSVersionTable.PSVersion

# Référence à AzContext (Az.Accounts)
$subscription = $AzContext.Subscription.Name

# Référence à PesterPreference (Pester)
$PesterPreference.Output.Verbosity = 'Detailed'

# Référence à une variable avec un nom qui suit un modèle de module
$ADUserInfo = Get-UserInfo -Identity "jdoe"
'@

        $script:scriptWithDependencies = @'
# Ce script utilise des cmdlets sans importer explicitement les modules
# Utilisation de cmdlets de Microsoft.PowerShell.Management
Get-Process | Where-Object { $_.CPU -gt 10 } | Stop-Process -Force

# Utilisation de cmdlets de Microsoft.PowerShell.Utility
Write-Output "Processus arrêtés"
'@
    }

    Context "Find-ModuleAliasWithoutExplicitImport" {
        It "Devrait détecter les références à des alias de modules dans un script" {
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
        It "Devrait détecter les références à des modules dans les commentaires" {
            $results = Find-ModuleReferenceInComments -ScriptContent $script:scriptWithComments
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0
        }

        It "Devrait identifier correctement les types de références" {
            $results = Find-ModuleReferenceInComments -ScriptContent $script:scriptWithComments
            $explicitModuleRefs = $results | Where-Object { $_.Type -eq "ExplicitModule" }
            $explicitModuleRefs | Should -Not -BeNullOrEmpty
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

    Context "Confirm-ModuleDependencies" {
        It "Devrait détecter et valider correctement les dépendances implicites" {
            $results = Confirm-ModuleDependencies -ScriptContent $script:scriptWithDependencies
            $results | Should -Not -BeNullOrEmpty
            $results.Status | Should -Be "AllModulesAvailable"
            $results.ValidationPassed | Should -BeTrue
        }

        It "Devrait générer correctement les instructions Import-Module si demandé" {
            $results = Confirm-ModuleDependencies -ScriptContent $script:scriptWithDependencies -GenerateImportStatements
            $results.ImportStatements | Should -Not -BeNullOrEmpty
            $results.ImportStatements.Count | Should -BeGreaterThan 0
        }
    }
}
