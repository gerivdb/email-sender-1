﻿<#
.SYNOPSIS
    Tests unitaires pour la fonction Get-AstFunctions.

.DESCRIPTION
    Ce script contient des tests Pester pour la fonction Get-AstFunctions
    qui permet d'extraire les fonctions d'un script PowerShell.

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de crÃ©ation: 2023-12-15
#>

# Importer la fonction Ã  tester directement
. "$PSScriptRoot\..\Public\Get-AstFunctions.ps1"

Describe "Get-AstFunctions" {
    BeforeAll {
        # CrÃ©er un script PowerShell de test
        $sampleCode = @'
function Test-Function1 {
    param (
        [string]$Name,
        [int]$Count = 0
    )

    "Hello, $Name!"
}

function Test-Function2 {
    "This is a simple function"
}

function Get-ComplexData {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [switch]$Recurse,

        [int]$Depth = 1
    )

    $result = @()

    # Logique de la fonction
    if ($Recurse) {
        # Traitement rÃ©cursif
        for ($i = 0; $i -lt $Depth; $i++) {
            $result += "Level $i"
        }
    }
    else {
        $result += "Single level"
    }

    return $result
}
'@

        # Analyser le code avec l'AST
        $tokens = $errors = $null
        $script:ast = [System.Management.Automation.Language.Parser]::ParseInput($sampleCode, [ref]$tokens, [ref]$errors)
    }

    Context "Extraction de base des fonctions" {
        It "Devrait extraire toutes les fonctions du script" {
            $functions = Get-AstFunctions -Ast $script:ast
            $functions.Count | Should -Be 3
            $functions[0].Name | Should -Be "Test-Function1"
            $functions[1].Name | Should -Be "Test-Function2"
            $functions[2].Name | Should -Be "Get-ComplexData"
        }

        It "Devrait extraire une fonction spÃ©cifique avec filtre par nom" {
            $functions = Get-AstFunctions -Ast $script:ast -Name "Test-Function1"
            $functions.Count | Should -Be 1
            $functions[0].Name | Should -Be "Test-Function1"
        }

        It "Devrait extraire des fonctions avec filtre par caractÃ¨re gÃ©nÃ©rique" {
            $functions = Get-AstFunctions -Ast $script:ast -Name "Test-*"
            $functions.Count | Should -Be 2
            $functions[0].Name | Should -Be "Test-Function1"
            $functions[1].Name | Should -Be "Test-Function2"
        }
    }

    Context "Extraction dÃ©taillÃ©e des fonctions" {
        It "Devrait extraire les dÃ©tails des fonctions avec le paramÃ¨tre -Detailed" {
            $functions = Get-AstFunctions -Ast $script:ast -Detailed
            $functions.Count | Should -Be 3

            # VÃ©rifier que les paramÃ¨tres sont inclus
            $functions[0].Parameters | Should -Not -BeNullOrEmpty
            $functions[0].Parameters.Count | Should -Be 2
            $functions[0].Parameters[0].Name | Should -Be "Name"
            $functions[0].Parameters[1].Name | Should -Be "Count"

            # VÃ©rifier qu'une fonction sans paramÃ¨tres a un tableau vide
            $functions[1].Parameters | Should -BeOfType System.Array
            $functions[1].Parameters.Count | Should -Be 0

            # VÃ©rifier les paramÃ¨tres de la fonction complexe
            $functions[2].Parameters.Count | Should -Be 3
            $functions[2].Parameters[0].Name | Should -Be "Path"
            $functions[2].Parameters[0].Mandatory | Should -Be $true
            $functions[2].Parameters[1].Name | Should -Be "Recurse"
            $functions[2].Parameters[2].Name | Should -Be "Depth"
            $functions[2].Parameters[2].DefaultValue | Should -Be "1"
        }
    }

    Context "Extraction du contenu des fonctions" {
        It "Devrait extraire le contenu des fonctions avec le paramÃ¨tre -IncludeContent" {
            $functions = Get-AstFunctions -Ast $script:ast -IncludeContent
            $functions.Count | Should -Be 3

            # VÃ©rifier que le contenu est inclus
            $functions[0].Content | Should -Not -BeNullOrEmpty
            $functions[0].Content | Should -Match "Hello, \$Name!"

            $functions[1].Content | Should -Match "This is a simple function"

            $functions[2].Content | Should -Match "Traitement rÃ©cursif"
            $functions[2].Content | Should -Match "return \$result"
        }
    }

    Context "Gestion des erreurs" {
        It "Devrait retourner un tableau vide si aucune fonction n'est trouvÃ©e" {
            # CrÃ©er un AST sans fonction
            $emptyCode = "# Ceci est un commentaire"
            $emptyTokens = $emptyErrors = $null
            $emptyAst = [System.Management.Automation.Language.Parser]::ParseInput($emptyCode, [ref]$emptyTokens, [ref]$emptyErrors)

            $functions = Get-AstFunctions -Ast $emptyAst
            $functions | Should -BeOfType System.Array
            $functions.Count | Should -Be 0
        }

        It "Devrait retourner un tableau vide si le filtre par nom ne correspond Ã  aucune fonction" {
            $functions = Get-AstFunctions -Ast $script:ast -Name "NonExistentFunction"
            $functions | Should -BeOfType System.Array
            $functions.Count | Should -Be 0
        }
    }
}
