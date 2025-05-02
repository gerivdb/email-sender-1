#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires Pester pour le module ImportParameterAnalyzer.

.DESCRIPTION
    Ce script contient des tests unitaires Pester pour le module ImportParameterAnalyzer
    qui analyse les paramètres d'importation dans les scripts PowerShell.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-12-15
#>

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\ImportParameterAnalyzer.psm1"

Describe "ImportParameterAnalyzer" {
    BeforeAll {
        Import-Module $modulePath -Force

        # Créer un script PowerShell de test avec différentes instructions Import-Module
        $script:sampleCode = @'
# Import simple avec paramètre positionnel
Import-Module PSScriptAnalyzer

# Import avec paramètre nommé
Import-Module -Name Pester

# Import avec chemin
Import-Module -Path "C:\Modules\MyModule.psm1"

# Import avec version
Import-Module -Name PSScriptAnalyzer -RequiredVersion 1.18.0

# Import avec caractères spéciaux
Import-Module -Name "Module-With-Hyphens"

# Import avec plusieurs paramètres
Import-Module -Name PSScriptAnalyzer -Global -Force -Verbose

# Import avec chemin relatif
Import-Module -Path "..\Modules\MyModule.psm1"

# Import avec variable
$moduleName = "MyModule"
Import-Module -Name $moduleName

# Import avec MinimumVersion et MaximumVersion
Import-Module -Name PSScriptAnalyzer -MinimumVersion 1.18.0 -MaximumVersion 2.0.0
'@

        # Analyser le code avec l'AST
        $tokens = $errors = $null
        $script:ast = [System.Management.Automation.Language.Parser]::ParseInput($script:sampleCode, [ref]$tokens, [ref]$errors)

        # Trouver toutes les instructions Import-Module
        $script:importModuleCalls = $script:ast.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.CommandAst] -and
            $node.CommandElements.Count -gt 0 -and
            $node.CommandElements[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
            $node.CommandElements[0].Value -eq 'Import-Module'
        }, $true)
    }

    Context "Get-ImportParameterTypes" {
        It "Devrait analyser correctement les paramètres d'importation" {
            $parameterTypes = Get-ImportParameterTypes -CommandAst $script:importModuleCalls[0]
            $parameterTypes | Should -Not -BeNullOrEmpty
            $parameterTypes.PositionalParameters.Count | Should -BeGreaterThan 0
            $parameterTypes.AllParameters | Should -Not -BeNullOrEmpty
        }

        It "Devrait détecter correctement le paramètre Name" {
            $parameterTypes = Get-ImportParameterTypes -CommandAst $script:importModuleCalls[1]
            $parameterTypes.HasNameParameter | Should -Be $true
            $parameterTypes.HasPathParameter | Should -Be $false
        }

        It "Devrait détecter correctement le paramètre Path" {
            $parameterTypes = Get-ImportParameterTypes -CommandAst $script:importModuleCalls[2]
            $parameterTypes.HasPathParameter | Should -Be $true
            $parameterTypes.HasNameParameter | Should -Be $false
        }

        It "Devrait détecter correctement les paramètres de version" {
            $parameterTypes = Get-ImportParameterTypes -CommandAst $script:importModuleCalls[3]
            $parameterTypes.HasVersionParameter | Should -Be $true
        }

        It "Devrait détecter correctement les caractères spéciaux" {
            $parameterTypes = Get-ImportParameterTypes -CommandAst $script:importModuleCalls[4]
            $parameterTypes.HasSpecialCharacters | Should -Be $true
        }

        It "Devrait identifier correctement les paramètres optionnels et requis" {
            $parameterTypes = Get-ImportParameterTypes -CommandAst $script:importModuleCalls[5]
            $parameterTypes.RequiredParameters | Should -Contain "Name"
            $parameterTypes.OptionalParameters | Should -Contain "Global"
            $parameterTypes.OptionalParameters | Should -Contain "Force"
        }
    }

    Context "Get-NamedParameters" {
        It "Devrait détecter tous les paramètres nommés" {
            $namedParameters = Get-NamedParameters -CommandAst $script:importModuleCalls[5]
            $namedParameters.Keys | Should -Contain "Name"
            $namedParameters.Keys | Should -Contain "Global"
            $namedParameters.Keys | Should -Contain "Force"
            $namedParameters.Keys | Should -Contain "Verbose"
        }

        It "Devrait correctement identifier les paramètres avec et sans valeur" {
            $namedParameters = Get-NamedParameters -CommandAst $script:importModuleCalls[5]
            $namedParameters["Name"].HasValue | Should -Be $true
            $namedParameters["Global"].HasValue | Should -Be $false
            $namedParameters["Force"].HasValue | Should -Be $false
        }
    }

    Context "Get-ParameterValue" {
        It "Devrait extraire correctement la valeur du paramètre Name" {
            $nameValue = Get-ParameterValue -CommandAst $script:importModuleCalls[1] -ParameterName "Name"
            $nameValue | Should -Be "Pester"
        }

        It "Devrait extraire correctement la valeur du paramètre Path" {
            $pathValue = Get-ParameterValue -CommandAst $script:importModuleCalls[2] -ParameterName "Path"
            $pathValue | Should -Be "C:\Modules\MyModule.psm1"
        }

        It "Devrait extraire correctement la valeur du paramètre positionnel" {
            $nameValue = Get-ParameterValue -CommandAst $script:importModuleCalls[0] -ParameterName "Name"
            $nameValue | Should -Be "PSScriptAnalyzer"
        }

        It "Devrait retourner $null pour un paramètre inexistant" {
            $value = Get-ParameterValue -CommandAst $script:importModuleCalls[0] -ParameterName "NonExistentParam"
            $value | Should -Be $null
        }
    }

    Context "Test-SpecialCharactersInParameter" {
        It "Devrait détecter les caractères spéciaux dans le paramètre Name" {
            $hasSpecialChars = Test-SpecialCharactersInParameter -CommandAst $script:importModuleCalls[4] -ParameterName "Name"
            $hasSpecialChars | Should -Be $true
        }

        It "Ne devrait pas détecter de caractères spéciaux dans un paramètre normal" {
            $hasSpecialChars = Test-SpecialCharactersInParameter -CommandAst $script:importModuleCalls[1] -ParameterName "Name"
            $hasSpecialChars | Should -Be $false
        }
    }

    Context "Get-OptionalParameters" {
        It "Devrait identifier correctement les paramètres optionnels" {
            $optionalParams = Get-OptionalParameters -CommandAst $script:importModuleCalls[5]
            $optionalParams | Should -Contain "Global"
            $optionalParams | Should -Contain "Force"
            $optionalParams | Should -Contain "Verbose"
        }

        It "Ne devrait pas inclure les paramètres requis dans les paramètres optionnels" {
            $optionalParams = Get-OptionalParameters -CommandAst $script:importModuleCalls[1]
            $optionalParams | Should -Not -Contain "Name"
        }
    }
}
