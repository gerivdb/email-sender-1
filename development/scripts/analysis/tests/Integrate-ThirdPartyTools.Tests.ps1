#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Integrate-ThirdPartyTools.ps1.
.DESCRIPTION
    Ce script contient des tests unitaires pour le script Integrate-ThirdPartyTools.ps1
    qui intÃ¨gre les rÃ©sultats d'analyse de code avec des outils tiers.
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas disponible. Installez-le avec 'Install-Module -Name Pester -Force'."
    return
}

# Importer le module d'aide pour les tests
$testHelpersPath = Join-Path -Path $PSScriptRoot -ChildPath "TestHelpers.psm1"
if (Test-Path -Path $testHelpersPath) {
    Import-Module -Name $testHelpersPath -Force
} else {
    throw "Le module TestHelpers.psm1 n'existe pas Ã  l'emplacement: $testHelpersPath"
}

# Chemin du script Ã  tester
$scriptPath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath "Integrate-ThirdPartyTools.ps1"
if (-not (Test-Path -Path $scriptPath)) {
    throw "Le script Integrate-ThirdPartyTools.ps1 n'existe pas Ã  l'emplacement: $scriptPath"
}

Describe "Script Integrate-ThirdPartyTools" {
    BeforeAll {
        # CrÃ©er un environnement de test
        $testEnv = New-TestEnvironment -TestName "IntegrateThirdPartyToolsTests"
        $testDir = $testEnv.TestDirectory
        $testJsonPath = $testEnv.TestJsonFile
    }

    Context "ParamÃ¨tres et validation" {
        It "LÃ¨ve une exception si le chemin n'existe pas" {
            # Act & Assert
            { Invoke-ScriptWithParams -ScriptPath $scriptPath -Parameters @{ Path = "C:\chemin\inexistant"; Tool = "GitHub" } } | Should -Throw
        }

        It "LÃ¨ve une exception si ProjectKey est manquant pour SonarQube" {
            # Act & Assert
            { Invoke-ScriptWithParams -ScriptPath $scriptPath -Parameters @{ Path = $testEnv.TestJsonFile; Tool = "SonarQube" } } | Should -Throw
        }
    }

    Context "Conversion vers GitHub format" {
        It "Convertit les rÃ©sultats vers le format GitHub" {
            # Arrange
            $outputPath = Join-Path -Path $testEnv.TestDirectory -ChildPath "github-results.json"

            # Mock la fonction ConvertTo-Json pour qu'elle retourne un JSON valide
            Mock ConvertTo-Json { return '{"annotations":[{"path":"test.ps1","start_line":10,"end_line":10,"start_column":1,"end_column":1,"annotation_level":"warning","message":"Avoid using Write-Host","title":"PSAvoidUsingWriteHost"},{"path":"test.ps1","start_line":5,"end_line":5,"start_column":7,"end_column":7,"annotation_level":"notice","message":"TODO: Add more robust error handling","title":"Todo.TODO"},{"path":"test.ps1","start_line":1,"end_line":1,"start_column":1,"end_column":1,"annotation_level":"failure","message":"Variable is assigned but never used","title":"PSUseDeclaredVarsMoreThanAssignments"}]}' }

            # Mock la fonction Out-File pour qu'elle ne fasse rien
            Mock Out-File { }

            # Mock la fonction Test-Path pour qu'elle retourne $true
            Mock Test-Path { return $true } -ParameterFilter { $Path -eq $testEnv.TestJsonFile }

            # Mock la fonction Get-Content pour qu'elle retourne un JSON valide
            Mock Get-Content { return '[{"ToolName":"PSScriptAnalyzer","FilePath":"test.ps1","FileName":"test.ps1","Line":10,"Column":1,"RuleId":"PSAvoidUsingWriteHost","Severity":"Warning","Message":"Avoid using Write-Host","Category":"Best Practice","Suggestion":"Use Write-Output instead","OriginalObject":null},{"ToolName":"TodoAnalyzer","FilePath":"test.ps1","FileName":"test.ps1","Line":5,"Column":7,"RuleId":"Todo.TODO","Severity":"Information","Message":"TODO: Add more robust error handling","Category":"Documentation","Suggestion":"RÃ©solvez ce TODO ou convertissez-le en tÃ¢che dans le systÃ¨me de suivi des problÃ¨mes.","OriginalObject":null},{"ToolName":"PSScriptAnalyzer","FilePath":"test.ps1","FileName":"test.ps1","Line":1,"Column":1,"RuleId":"PSUseDeclaredVarsMoreThanAssignments","Severity":"Error","Message":"Variable is assigned but never used","Category":"Best Practice","Suggestion":"Use the variable or remove it","OriginalObject":null}]' }

            # Act
            Invoke-ScriptWithParams -ScriptPath $scriptPath -Parameters @{
                Path       = $testEnv.TestJsonFile
                Tool       = "GitHub"
                OutputPath = $outputPath
            }

            # Assert
            Should -Invoke Test-Path -Times 1 -ParameterFilter { $Path -eq $testEnv.TestJsonFile }
            Should -Invoke Get-Content -Times 1 -ParameterFilter { $Path -eq $testEnv.TestJsonFile }
            Should -Invoke ConvertTo-Json -Times 1
            Should -Invoke Out-File -Times 1 -ParameterFilter { $FilePath -eq $outputPath }
        }
    }

    Context "Conversion vers SonarQube format" {
        It "Convertit les rÃ©sultats vers le format SonarQube" {
            # Arrange
            $outputPath = Join-Path -Path $testEnv.TestDirectory -ChildPath "sonarqube-results.json"

            # Mock la fonction ConvertTo-Json pour qu'elle retourne un JSON valide
            Mock ConvertTo-Json { return '{"issues":[{"engineId":"PSScriptAnalyzer","ruleId":"PSAvoidUsingWriteHost","severity":"MAJOR","type":"CODE_SMELL","primaryLocation":{"message":"Avoid using Write-Host","filePath":"test.ps1","textRange":{"startLine":10,"endLine":10,"startColumn":1,"endColumn":1}},"effortMinutes":5},{"engineId":"TodoAnalyzer","ruleId":"Todo.TODO","severity":"MINOR","type":"CODE_SMELL","primaryLocation":{"message":"TODO: Add more robust error handling","filePath":"test.ps1","textRange":{"startLine":5,"endLine":5,"startColumn":7,"endColumn":7}},"effortMinutes":5},{"engineId":"PSScriptAnalyzer","ruleId":"PSUseDeclaredVarsMoreThanAssignments","severity":"CRITICAL","type":"CODE_SMELL","primaryLocation":{"message":"Variable is assigned but never used","filePath":"test.ps1","textRange":{"startLine":1,"endLine":1,"startColumn":1,"endColumn":1}},"effortMinutes":5}]}' }

            # Mock la fonction Out-File pour qu'elle ne fasse rien
            Mock Out-File { }

            # Mock la fonction Test-Path pour qu'elle retourne $true
            Mock Test-Path { return $true } -ParameterFilter { $Path -eq $testEnv.TestJsonFile }

            # Mock la fonction Get-Content pour qu'elle retourne un JSON valide
            Mock Get-Content { return '[{"ToolName":"PSScriptAnalyzer","FilePath":"test.ps1","FileName":"test.ps1","Line":10,"Column":1,"RuleId":"PSAvoidUsingWriteHost","Severity":"Warning","Message":"Avoid using Write-Host","Category":"Best Practice","Suggestion":"Use Write-Output instead","OriginalObject":null},{"ToolName":"TodoAnalyzer","FilePath":"test.ps1","FileName":"test.ps1","Line":5,"Column":7,"RuleId":"Todo.TODO","Severity":"Information","Message":"TODO: Add more robust error handling","Category":"Documentation","Suggestion":"RÃ©solvez ce TODO ou convertissez-le en tÃ¢che dans le systÃ¨me de suivi des problÃ¨mes.","OriginalObject":null},{"ToolName":"PSScriptAnalyzer","FilePath":"test.ps1","FileName":"test.ps1","Line":1,"Column":1,"RuleId":"PSUseDeclaredVarsMoreThanAssignments","Severity":"Error","Message":"Variable is assigned but never used","Category":"Best Practice","Suggestion":"Use the variable or remove it","OriginalObject":null}]' }

            # Act
            Invoke-ScriptWithParams -ScriptPath $scriptPath -Parameters @{
                Path       = $testEnv.TestJsonFile
                Tool       = "SonarQube"
                OutputPath = $outputPath
                ProjectKey = "test-project"
            }

            # Assert
            Should -Invoke Test-Path -Times 1 -ParameterFilter { $Path -eq $testEnv.TestJsonFile }
            Should -Invoke Get-Content -Times 1 -ParameterFilter { $Path -eq $testEnv.TestJsonFile }
            Should -Invoke ConvertTo-Json -Times 1
            Should -Invoke Out-File -Times 1 -ParameterFilter { $FilePath -eq $outputPath }
        }
    }

    Context "Conversion vers AzureDevOps format" {
        It "Convertit les rÃ©sultats vers le format AzureDevOps" {
            # Arrange
            $outputPath = Join-Path -Path $testEnv.TestDirectory -ChildPath "azuredevops-results.json"

            # Mock la fonction ConvertTo-Json pour qu'elle retourne un JSON valide
            Mock ConvertTo-Json { return '{"issues":[{"filePath":"test.ps1","lineNumber":10,"columnNumber":1,"message":"Avoid using Write-Host","ruleId":"PSAvoidUsingWriteHost","severity":2,"source":"PSScriptAnalyzer"},{"filePath":"test.ps1","lineNumber":5,"columnNumber":7,"message":"TODO: Add more robust error handling","ruleId":"Todo.TODO","severity":3,"source":"TodoAnalyzer"},{"filePath":"test.ps1","lineNumber":1,"columnNumber":1,"message":"Variable is assigned but never used","ruleId":"PSUseDeclaredVarsMoreThanAssignments","severity":1,"source":"PSScriptAnalyzer"}]}' }

            # Mock la fonction Out-File pour qu'elle ne fasse rien
            Mock Out-File { }

            # Mock la fonction Test-Path pour qu'elle retourne $true
            Mock Test-Path { return $true } -ParameterFilter { $Path -eq $testEnv.TestJsonFile }

            # Mock la fonction Get-Content pour qu'elle retourne un JSON valide
            Mock Get-Content { return '[{"ToolName":"PSScriptAnalyzer","FilePath":"test.ps1","FileName":"test.ps1","Line":10,"Column":1,"RuleId":"PSAvoidUsingWriteHost","Severity":"Warning","Message":"Avoid using Write-Host","Category":"Best Practice","Suggestion":"Use Write-Output instead","OriginalObject":null},{"ToolName":"TodoAnalyzer","FilePath":"test.ps1","FileName":"test.ps1","Line":5,"Column":7,"RuleId":"Todo.TODO","Severity":"Information","Message":"TODO: Add more robust error handling","Category":"Documentation","Suggestion":"RÃ©solvez ce TODO ou convertissez-le en tÃ¢che dans le systÃ¨me de suivi des problÃ¨mes.","OriginalObject":null},{"ToolName":"PSScriptAnalyzer","FilePath":"test.ps1","FileName":"test.ps1","Line":1,"Column":1,"RuleId":"PSUseDeclaredVarsMoreThanAssignments","Severity":"Error","Message":"Variable is assigned but never used","Category":"Best Practice","Suggestion":"Use the variable or remove it","OriginalObject":null}]' }

            # Act
            Invoke-ScriptWithParams -ScriptPath $scriptPath -Parameters @{
                Path       = $testEnv.TestJsonFile
                Tool       = "AzureDevOps"
                OutputPath = $outputPath
            }

            # Assert
            Should -Invoke Test-Path -Times 1 -ParameterFilter { $Path -eq $testEnv.TestJsonFile }
            Should -Invoke Get-Content -Times 1 -ParameterFilter { $Path -eq $testEnv.TestJsonFile }
            Should -Invoke ConvertTo-Json -Times 1
            Should -Invoke Out-File -Times 1 -ParameterFilter { $FilePath -eq $outputPath }
        }
    }

    Context "Envoi des rÃ©sultats Ã  l'API" {
        It "Envoie les rÃ©sultats Ã  l'API SonarQube si ApiKey et ApiUrl sont spÃ©cifiÃ©s" {
            # Arrange
            $outputPath = Join-Path -Path $testEnv.TestDirectory -ChildPath "sonarqube-api-results.json"

            # Mock la fonction ConvertTo-Json pour qu'elle retourne un JSON valide
            Mock ConvertTo-Json { return '{"issues":[{"engineId":"PSScriptAnalyzer","ruleId":"PSAvoidUsingWriteHost","severity":"MAJOR","type":"CODE_SMELL","primaryLocation":{"message":"Avoid using Write-Host","filePath":"test.ps1","textRange":{"startLine":10,"endLine":10,"startColumn":1,"endColumn":1}},"effortMinutes":5}]}' }

            # Mock la fonction Out-File pour qu'elle ne fasse rien
            Mock Out-File { }

            # Mock la fonction Test-Path pour qu'elle retourne $true
            Mock Test-Path { return $true } -ParameterFilter { $Path -eq $testEnv.TestJsonFile }

            # Mock la fonction Get-Content pour qu'elle retourne un JSON valide
            Mock Get-Content { return '[{"ToolName":"PSScriptAnalyzer","FilePath":"test.ps1","FileName":"test.ps1","Line":10,"Column":1,"RuleId":"PSAvoidUsingWriteHost","Severity":"Warning","Message":"Avoid using Write-Host","Category":"Best Practice","Suggestion":"Use Write-Output instead","OriginalObject":null}]' }

            # Mock la fonction Invoke-RestMethod pour qu'elle ne fasse rien
            Mock Invoke-RestMethod { }

            # Act
            Invoke-ScriptWithParams -ScriptPath $scriptPath -Parameters @{
                Path       = $testEnv.TestJsonFile
                Tool       = "SonarQube"
                OutputPath = $outputPath
                ProjectKey = "test-project"
                ApiKey     = "test-api-key"
                ApiUrl     = "https://sonarqube.example.com"
            }

            # Assert
            Should -Invoke Test-Path -Times 1 -ParameterFilter { $Path -eq $testEnv.TestJsonFile }
            Should -Invoke Get-Content -Times 1 -ParameterFilter { $Path -eq $testEnv.TestJsonFile }
            Should -Invoke ConvertTo-Json -Times 2 # Une fois pour le fichier, une fois pour l'API
            Should -Invoke Out-File -Times 1 -ParameterFilter { $FilePath -eq $outputPath }
            Should -Invoke Invoke-RestMethod -Times 1
        }
    }
}
