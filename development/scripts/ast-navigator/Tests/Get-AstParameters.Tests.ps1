<#
.SYNOPSIS
    Tests unitaires pour la fonction Get-AstParameters.

.DESCRIPTION
    Ce script contient des tests Pester pour la fonction Get-AstParameters
    qui permet d'extraire les paramÃ¨tres d'un script ou d'une fonction PowerShell.

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de crÃ©ation: 2023-12-15
#>

# Importer le module Ã  tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".." -Resolve
Import-Module $modulePath -Force

Describe "Get-AstParameters" {
    BeforeAll {
        # CrÃ©er un script PowerShell de test avec des paramÃ¨tres au niveau du script et des fonctions
        $sampleCode = @'
param (
    [Parameter(Mandatory = $true)]
    [string]$ScriptParam1,

    [int]$ScriptParam2 = 10,

    [switch]$ScriptFlag
)

function Test-SimpleFunction {
    param (
        [string]$Name,
        [int]$Count = 0
    )

    "Hello, $Name!"
}

function Test-ComplexFunction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$Recurse,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 10)]
        [int]$Depth = 1,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Full", "Minimal", "Custom")]
        [string]$OutputMode = "Full"
    )

    # Corps de la fonction
}
'@

        # Analyser le code avec l'AST
        $tokens = $errors = $null
        $script:ast = [System.Management.Automation.Language.Parser]::ParseInput($sampleCode, [ref]$tokens, [ref]$errors)
    }

    Context "Extraction des paramÃ¨tres du script" {
        It "Devrait extraire tous les paramÃ¨tres du script" {
            $parameters = Get-AstParameters -Ast $script:ast
            $parameters.Count | Should -Be 3
            $parameters[0].Name | Should -Be "ScriptParam1"
            $parameters[0].Type | Should -Be "string"
            $parameters[1].Name | Should -Be "ScriptParam2"
            $parameters[1].Type | Should -Be "int"
            $parameters[1].DefaultValue | Should -Be "10"
            $parameters[2].Name | Should -Be "ScriptFlag"
            $parameters[2].Type | Should -Be "switch"
        }
    }

    Context "Extraction des paramÃ¨tres d'une fonction" {
        It "Devrait extraire les paramÃ¨tres d'une fonction simple" {
            $parameters = Get-AstParameters -Ast $script:ast -FunctionName "Test-SimpleFunction"
            $parameters.Count | Should -Be 2
            $parameters[0].Name | Should -Be "Name"
            $parameters[0].Type | Should -Be "string"
            $parameters[1].Name | Should -Be "Count"
            $parameters[1].Type | Should -Be "int"
            $parameters[1].DefaultValue | Should -Be "0"
        }

        It "Devrait extraire les paramÃ¨tres d'une fonction complexe" {
            $parameters = Get-AstParameters -Ast $script:ast -FunctionName "Test-ComplexFunction"
            $parameters.Count | Should -Be 4
            $parameters[0].Name | Should -Be "Path"
            $parameters[0].Type | Should -Be "string"
            $parameters[1].Name | Should -Be "Recurse"
            $parameters[1].Type | Should -Be "switch"
            $parameters[2].Name | Should -Be "Depth"
            $parameters[2].Type | Should -Be "int"
            $parameters[2].DefaultValue | Should -Be "1"
            $parameters[3].Name | Should -Be "OutputMode"
            $parameters[3].Type | Should -Be "string"
            $parameters[3].DefaultValue | Should -Be '"Full"'
        }
    }

    Context "Extraction dÃ©taillÃ©e des paramÃ¨tres" {
        It "Devrait extraire les dÃ©tails des paramÃ¨tres avec le paramÃ¨tre -Detailed" {
            $parameters = Get-AstParameters -Ast $script:ast -FunctionName "Test-ComplexFunction" -Detailed
            $parameters.Count | Should -Be 4

            # VÃ©rifier les attributs dÃ©taillÃ©s
            $parameters[0].Name | Should -Be "Path"
            $parameters[0].Mandatory | Should -Be $true
            $parameters[0].Position | Should -Be 0
            $parameters[0].ParameterSetName | Should -Be "__AllParameterSets"
            $parameters[0].Attributes | Should -Contain "ValidateNotNullOrEmpty"

            $parameters[2].Name | Should -Be "Depth"
            $parameters[2].Mandatory | Should -Be $false
            $parameters[2].DefaultValue | Should -Be "1"
            $parameters[2].Attributes | Should -Contain "ValidateRange"

            $parameters[3].Name | Should -Be "OutputMode"
            $parameters[3].Attributes | Should -Contain "ValidateSet"
        }
    }

    Context "Gestion des erreurs" {
        It "Devrait retourner un tableau vide si aucun paramÃ¨tre n'est trouvÃ© dans le script" {
            # CrÃ©er un AST sans paramÃ¨tre de script
            $codeWithoutParams = "# Ceci est un script sans paramÃ¨tres"
            $tokensWithoutParams = $errorsWithoutParams = $null
            $astWithoutParams = [System.Management.Automation.Language.Parser]::ParseInput($codeWithoutParams, [ref]$tokensWithoutParams, [ref]$errorsWithoutParams)

            $parameters = Get-AstParameters -Ast $astWithoutParams
            $parameters | Should -BeOfType System.Array
            $parameters.Count | Should -Be 0
        }

        It "Devrait retourner un tableau vide si la fonction spÃ©cifiÃ©e n'existe pas" {
            $parameters = Get-AstParameters -Ast $script:ast -FunctionName "NonExistentFunction"
            $parameters | Should -BeOfType System.Array
            $parameters.Count | Should -Be 0
        }

        It "Devrait retourner un tableau vide si la fonction spÃ©cifiÃ©e n'a pas de paramÃ¨tres" {
            # CrÃ©er un AST avec une fonction sans paramÃ¨tres
            $codeWithFunctionNoParams = @'
function Test-NoParams {
    "Cette fonction n'a pas de paramÃ¨tres"
}
'@
            $tokensNoParams = $errorsNoParams = $null
            $astNoParams = [System.Management.Automation.Language.Parser]::ParseInput($codeWithFunctionNoParams, [ref]$tokensNoParams, [ref]$errorsNoParams)

            $parameters = Get-AstParameters -Ast $astNoParams -FunctionName "Test-NoParams"
            $parameters | Should -BeOfType System.Array
            $parameters.Count | Should -Be 0
        }
    }
}
