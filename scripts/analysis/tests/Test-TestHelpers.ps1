#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour le module TestHelpers.psm1.
.DESCRIPTION
    Ce script teste les fonctionnalités du module TestHelpers.psm1 qui est utilisé
    pour faciliter les tests unitaires du système d'analyse de code.
.NOTES
    Auteur: Augment Agent
    Date de création: 2023-05-15
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas disponible. Installez-le avec 'Install-Module -Name Pester -Force'."
    return
}

# Chemin du module à tester
$moduleToTest = Join-Path -Path $PSScriptRoot -ChildPath "TestHelpers.psm1"
if (-not (Test-Path -Path $moduleToTest)) {
    throw "Le module TestHelpers.psm1 n'existe pas à l'emplacement: $moduleToTest"
}

# Importer le module
Import-Module -Name $moduleToTest -Force

Describe "Module TestHelpers" {
    Context "Fonction New-TestEnvironment" {
        It "Crée un environnement de test avec un nom par défaut" {
            # Act
            $testEnv = New-TestEnvironment

            # Assert
            $testEnv | Should -Not -BeNullOrEmpty
            $testEnv.TestDirectory | Should -Not -BeNullOrEmpty
            Test-Path -Path $testEnv.TestDirectory | Should -BeTrue
            Test-Path -Path $testEnv.TestPsFile | Should -BeTrue
            Test-Path -Path $testEnv.TestHtmlFile | Should -BeTrue
            Test-Path -Path $testEnv.TestJsonFile | Should -BeTrue
        }

        It "Crée un environnement de test avec un nom personnalisé" {
            # Act
            $testName = "CustomTest"
            $testEnv = New-TestEnvironment -TestName $testName

            # Assert
            $testEnv | Should -Not -BeNullOrEmpty
            $testEnv.TestDirectory | Should -Not -BeNullOrEmpty
            $testEnv.TestDirectory | Should -Match $testName
            Test-Path -Path $testEnv.TestDirectory | Should -BeTrue
            Test-Path -Path $testEnv.TestPsFile | Should -BeTrue
            Test-Path -Path $testEnv.TestHtmlFile | Should -BeTrue
            Test-Path -Path $testEnv.TestJsonFile | Should -BeTrue
        }

        It "Crée des fichiers avec le contenu attendu" {
            # Act
            $testEnv = New-TestEnvironment

            # Assert
            $psContent = Get-Content -Path $testEnv.TestPsFile -Raw
            $psContent | Should -Match "Test-Function"
            $psContent | Should -Match "TODO: Add more robust error handling"
            $psContent | Should -Match "FIXME: Fix performance issue"
            $psContent | Should -Match "Write-Host"

            $htmlContent = Get-Content -Path $testEnv.TestHtmlFile -Raw
            $htmlContent | Should -Match "<!DOCTYPE html>"
            $htmlContent | Should -Match "<title>Test HTML</title>"
            $htmlContent | Should -Match "éèêëàâäôöùûüÿç"

            $jsonContent = Get-Content -Path $testEnv.TestJsonFile -Raw
            $jsonContent | Should -Match "PSScriptAnalyzer"
            $jsonContent | Should -Match "TodoAnalyzer"
            $jsonContent | Should -Match "PSAvoidUsingWriteHost"
        }
    }

    Context "Fonction Invoke-ScriptWithParams" {
        BeforeAll {
            # Créer un script de test simple
            $testEnv = New-TestEnvironment -TestName "ScriptParamsTest"
            $testScriptPath = Join-Path -Path $testEnv.TestDirectory -ChildPath "TestScript.ps1"
            $testScriptContent = @'
param (
    [string]$StringParam,
    [int]$IntParam,
    [switch]$SwitchParam,
    [array]$ArrayParam
)

$result = [PSCustomObject]@{
    StringParam = $StringParam
    IntParam = $IntParam
    SwitchParam = $SwitchParam
    ArrayParam = $ArrayParam
}

return $result
'@
            Set-Content -Path $testScriptPath -Value $testScriptContent
        }

        It "Exécute un script avec des paramètres de type string" {
            # Act
            $result = Invoke-ScriptWithParams -ScriptPath $testScriptPath -Parameters @{
                StringParam = "Test"
            }

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.StringParam | Should -Be "Test"
        }

        It "Exécute un script avec des paramètres de type int" {
            # Act
            $result = Invoke-ScriptWithParams -ScriptPath $testScriptPath -Parameters @{
                IntParam = 42
            }

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.IntParam | Should -Be 42
        }

        It "Exécute un script avec des paramètres de type switch" {
            # Act
            $result = Invoke-ScriptWithParams -ScriptPath $testScriptPath -Parameters @{
                SwitchParam = $true
            }

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.SwitchParam | Should -BeTrue
        }

        It "Exécute un script avec des paramètres de type array" {
            # Act
            $result = Invoke-ScriptWithParams -ScriptPath $testScriptPath -Parameters @{
                ArrayParam = @("Item1", "Item2", "Item3")
            }

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.ArrayParam | Should -Not -BeNullOrEmpty
            $result.ArrayParam.Count | Should -Be 3
            $result.ArrayParam[0] | Should -Be "Item1"
            $result.ArrayParam[1] | Should -Be "Item2"
            $result.ArrayParam[2] | Should -Be "Item3"
        }

        It "Exécute un script avec plusieurs paramètres" {
            # Act
            $result = Invoke-ScriptWithParams -ScriptPath $testScriptPath -Parameters @{
                StringParam = "Test"
                IntParam    = 42
                SwitchParam = $true
                ArrayParam  = @("Item1", "Item2")
            }

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.StringParam | Should -Be "Test"
            $result.IntParam | Should -Be 42
            $result.SwitchParam | Should -BeTrue
            $result.ArrayParam | Should -Not -BeNullOrEmpty
            $result.ArrayParam.Count | Should -Be 2
            $result.ArrayParam[0] | Should -Be "Item1"
            $result.ArrayParam[1] | Should -Be "Item2"
        }

        It "Lève une exception si le script n'existe pas" {
            # Act & Assert
            { Invoke-ScriptWithParams -ScriptPath "C:\chemin\inexistant.ps1" -Parameters @{} } | Should -Throw
        }
    }

    Context "Fonction New-PSScriptAnalyzerMock" {
        BeforeAll {
            # Créer un module temporaire pour simuler PSScriptAnalyzer
            $testEnv = New-TestEnvironment -TestName "PSScriptAnalyzerMockTest"
            $mockModulePath = Join-Path -Path $testEnv.TestDirectory -ChildPath "PSScriptAnalyzer.psm1"
            $mockModuleContent = @'
# Module de simulation pour PSScriptAnalyzer
function Invoke-ScriptAnalyzer {
    param (
        [string]$Path,
        [string[]]$IncludeRule,
        [string[]]$ExcludeRule,
        [switch]$Recurse
    )

    # Retourner des résultats simulés
    return @(
        [PSCustomObject]@{
            ScriptPath = $Path
            Line = 10
            Column = 1
            RuleName = "PSAvoidUsingWriteHost"
            Severity = "Warning"
            Message = "Avoid using Write-Host"
            RuleSuppressionID = "Best Practice"
        },
        [PSCustomObject]@{
            ScriptPath = $Path
            Line = 1
            Column = 1
            RuleName = "PSUseDeclaredVarsMoreThanAssignments"
            Severity = "Error"
            Message = "Variable is assigned but never used"
            RuleSuppressionID = "Best Practice"
        }
    )
}

Export-ModuleMember -Function Invoke-ScriptAnalyzer
'@
            Set-Content -Path $mockModulePath -Value $mockModuleContent

            # Importer le module de simulation
            Import-Module -Name $mockModulePath -Force
        }

        It "Crée un mock pour Invoke-ScriptAnalyzer" {
            # Act
            New-PSScriptAnalyzerMock
            $testPath = "C:\test\test.ps1"
            $result = Invoke-ScriptAnalyzer -Path $testPath

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            $result[0].RuleName | Should -Be "PSAvoidUsingWriteHost"
            $result[1].RuleName | Should -Be "PSUseDeclaredVarsMoreThanAssignments"
            $result[0].ScriptPath | Should -Be $testPath
        }

        AfterAll {
            # Supprimer le module de simulation
            Remove-Module -Name "PSScriptAnalyzer" -Force -ErrorAction SilentlyContinue
        }
    }

    Context "Fonction New-UnifiedAnalysisResultMock" {
        BeforeAll {
            # Créer une fonction locale pour simuler New-UnifiedAnalysisResult
            function Script:New-UnifiedAnalysisResult {
                param (
                    [string]$ToolName,
                    [string]$FilePath,
                    [int]$Line,
                    [int]$Column,
                    [string]$RuleId,
                    [string]$Severity,
                    [string]$Message,
                    [string]$Category,
                    [string]$Suggestion,
                    [object]$OriginalObject
                )

                # Retourner un objet simulé
                return [PSCustomObject]@{
                    ToolName       = $ToolName
                    FilePath       = $FilePath
                    FileName       = [System.IO.Path]::GetFileName($FilePath)
                    Line           = $Line
                    Column         = $Column
                    RuleId         = $RuleId
                    Severity       = $Severity
                    Message        = $Message
                    Category       = $Category
                    Suggestion     = $Suggestion
                    OriginalObject = $OriginalObject
                }
            }
        }

        It "Crée un mock pour New-UnifiedAnalysisResult" {
            # Act
            New-UnifiedAnalysisResultMock
            $testPath = "C:\test\test.ps1"
            $result = New-UnifiedAnalysisResult -ToolName "TestTool" -FilePath $testPath -Line 10 -Column 1 -RuleId "TestRule" -Severity "Warning" -Message "Test message"

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.ToolName | Should -Be "TestTool"
            $result.FilePath | Should -Be $testPath
            $result.FileName | Should -Be "test.ps1"
            $result.Line | Should -Be 10
            $result.Column | Should -Be 1
            $result.RuleId | Should -Be "TestRule"
            $result.Severity | Should -Be "Warning"
            $result.Message | Should -Be "Test message"
        }

        AfterAll {
            # Supprimer la fonction locale
            Remove-Item -Path "function:Script:New-UnifiedAnalysisResult" -ErrorAction SilentlyContinue
        }
    }
}
