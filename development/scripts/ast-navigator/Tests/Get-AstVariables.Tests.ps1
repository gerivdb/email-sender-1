<#
.SYNOPSIS
    Tests unitaires pour la fonction Get-AstVariables.

.DESCRIPTION
    Ce script contient des tests Pester pour la fonction Get-AstVariables
    qui permet d'extraire les variables d'un script PowerShell.

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de crÃ©ation: 2023-12-15
#>

# Importer le module Ã  tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".." -Resolve
Import-Module $modulePath -Force

Describe "Get-AstVariables" {
    BeforeAll {
        # CrÃ©er un script PowerShell de test avec diffÃ©rents types de variables
        $sampleCode = @'
# Variables globales et de script
$Global:GlobalVar = "Valeur globale"
$script:ScriptVar = "Valeur de script"

# Variables locales
$localVar1 = "Valeur locale 1"
$localVar2 = 42
$localVar3 = @{
    Key1 = "Value1"
    Key2 = "Value2"
}

function Test-Variables {
    # Variables de fonction
    $functionVar1 = "Variable dans une fonction"
    $private:privateVar = "Variable privÃ©e"

    # Utilisation de variables
    $result = $localVar1 + " modifiÃ©e"
    $Global:GlobalVar = "Nouvelle valeur globale"

    # Boucle avec variable
    for ($i = 0; $i -lt 5; $i++) {
        $loopVar = "ItÃ©ration $i"
        Write-Output $loopVar
    }

    return $result
}

# Utilisation de variables automatiques
$PSVersionTable.PSVersion
$PWD.Path
$Host.Name
'@

        # Analyser le code avec l'AST
        $tokens = $errors = $null
        $script:ast = [System.Management.Automation.Language.Parser]::ParseInput($sampleCode, [ref]$tokens, [ref]$errors)
    }

    Context "Extraction de base des variables" {
        It "Devrait extraire toutes les variables du script" {
            $variables = Get-AstVariables -Ast $script:ast
            $variables.Count | Should -BeGreaterThan 10

            # VÃ©rifier que les variables principales sont prÃ©sentes
            $variableNames = $variables | ForEach-Object { $_.Name }
            $variableNames | Should -Contain "GlobalVar"
            $variableNames | Should -Contain "ScriptVar"
            $variableNames | Should -Contain "localVar1"
            $variableNames | Should -Contain "localVar2"
            $variableNames | Should -Contain "localVar3"
            $variableNames | Should -Contain "functionVar1"
            $variableNames | Should -Contain "privateVar"
            $variableNames | Should -Contain "result"
            $variableNames | Should -Contain "i"
            $variableNames | Should -Contain "loopVar"
        }

        It "Devrait extraire les variables avec leur portÃ©e correcte" {
            $variables = Get-AstVariables -Ast $script:ast

            # VÃ©rifier les portÃ©es des variables
            $globalVar = $variables | Where-Object { $_.Name -eq "GlobalVar" } | Select-Object -First 1
            $globalVar.Scope | Should -Be "Global"

            $scriptVar = $variables | Where-Object { $_.Name -eq "ScriptVar" } | Select-Object -First 1
            $scriptVar.Scope | Should -Be "Script"

            $privateVar = $variables | Where-Object { $_.Name -eq "privateVar" } | Select-Object -First 1
            $privateVar.Scope | Should -Be "Private"

            # Les variables locales n'ont pas de portÃ©e explicite
            $localVar = $variables | Where-Object { $_.Name -eq "localVar1" } | Select-Object -First 1
            $localVar.Scope | Should -BeNullOrEmpty
        }
    }

    Context "Filtrage des variables" {
        It "Devrait filtrer les variables par nom" {
            $variables = Get-AstVariables -Ast $script:ast -Name "local*"
            $variables.Count | Should -Be 3
            $variableNames = $variables | ForEach-Object { $_.Name }
            $variableNames | Should -Contain "localVar1"
            $variableNames | Should -Contain "localVar2"
            $variableNames | Should -Contain "localVar3"
        }

        It "Devrait filtrer les variables par portÃ©e" {
            $variables = Get-AstVariables -Ast $script:ast -Scope "Global"
            $variables.Count | Should -Be 1
            $variables[0].Name | Should -Be "GlobalVar"
            $variables[0].Scope | Should -Be "Global"
        }

        It "Devrait exclure les variables automatiques" {
            $allVariables = Get-AstVariables -Ast $script:ast
            $filteredVariables = Get-AstVariables -Ast $script:ast -ExcludeAutomaticVariables

            # VÃ©rifier que le nombre de variables est rÃ©duit
            $allVariables.Count | Should -BeGreaterThan $filteredVariables.Count

            # VÃ©rifier que les variables automatiques sont exclues
            $filteredNames = $filteredVariables | ForEach-Object { $_.Name }
            $filteredNames | Should -Not -Contain "PSVersionTable"
            $filteredNames | Should -Not -Contain "PWD"
            $filteredNames | Should -Not -Contain "Host"
        }
    }

    Context "Extraction des assignations de variables" {
        It "Devrait inclure les assignations de variables" {
            $variables = Get-AstVariables -Ast $script:ast -IncludeAssignments

            # VÃ©rifier que les assignations sont incluses
            $globalVar = $variables | Where-Object { $_.Name -eq "GlobalVar" } | Select-Object -First 1
            $globalVar.Assignments | Should -Not -BeNullOrEmpty
            $globalVar.Assignments.Count | Should -Be 2  # Assignation initiale et dans la fonction
            $globalVar.Assignments[0].Value | Should -Be '"Valeur globale"'

            $localVar1 = $variables | Where-Object { $_.Name -eq "localVar1" } | Select-Object -First 1
            $localVar1.Assignments | Should -Not -BeNullOrEmpty
            $localVar1.Assignments.Count | Should -Be 1
            $localVar1.Assignments[0].Value | Should -Be '"Valeur locale 1"'
        }
    }

    Context "Gestion des erreurs" {
        It "Devrait retourner un tableau vide si aucune variable n'est trouvÃ©e" {
            # CrÃ©er un AST sans variable
            $emptyCode = "# Ceci est un commentaire sans variable"
            $emptyTokens = $emptyErrors = $null
            $emptyAst = [System.Management.Automation.Language.Parser]::ParseInput($emptyCode, [ref]$emptyTokens, [ref]$emptyErrors)

            $variables = Get-AstVariables -Ast $emptyAst
            $variables | Should -BeOfType System.Array
            $variables.Count | Should -Be 0
        }

        It "Devrait retourner un tableau vide si le filtre par nom ne correspond Ã  aucune variable" {
            $variables = Get-AstVariables -Ast $script:ast -Name "NonExistentVariable"
            $variables | Should -BeOfType System.Array
            $variables.Count | Should -Be 0
        }

        It "Devrait retourner un tableau vide si le filtre par portÃ©e ne correspond Ã  aucune variable" {
            $variables = Get-AstVariables -Ast $script:ast -Scope "Workflow"  # PortÃ©e non utilisÃ©e dans l'exemple
            $variables | Should -BeOfType System.Array
            $variables.Count | Should -Be 0
        }
    }
}
