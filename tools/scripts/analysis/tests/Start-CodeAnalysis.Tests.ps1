#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Start-CodeAnalysis.ps1.
.DESCRIPTION
    Ce script contient des tests unitaires pour le script Start-CodeAnalysis.ps1
    qui analyse du code avec diffÃ©rents outils et gÃ©nÃ¨re des rapports.
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
$scriptPath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath "Start-CodeAnalysis.ps1"
if (-not (Test-Path -Path $scriptPath)) {
    throw "Le script Start-CodeAnalysis.ps1 n'existe pas Ã  l'emplacement: $scriptPath"
}

Describe "Script Start-CodeAnalysis" {
    BeforeAll {
        # CrÃ©er un environnement de test
        $testEnv = New-TestEnvironment -TestName "CodeAnalysisTests"
        $testDir = $testEnv.TestDirectory
        $testPsPath = $testEnv.TestPsFile
        $testPs2Path = $testEnv.TestPs2File

        # CrÃ©er un mock pour PSScriptAnalyzer
        New-PSScriptAnalyzerMock | Import-Module -Force

        # CrÃ©er un mock pour New-UnifiedAnalysisResult
        New-UnifiedAnalysisResultMock | Import-Module -Force
    }

    Context "ParamÃ¨tres et validation" {
        It "LÃ¨ve une exception si le chemin n'existe pas" {
            # Act & Assert
            { Invoke-ScriptWithParams -ScriptPath $scriptPath -Parameters @{ Path = "C:\chemin\inexistant" } } | Should -Throw
        }
    }

    Context "Analyse d'un fichier unique" {
        It "Analyse un fichier PowerShell avec PSScriptAnalyzer" {
            # Arrange
            $outputPath = Join-Path -Path $testEnv.TestDirectory -ChildPath "psa-results.json"

            # Mock la fonction ConvertTo-Json pour qu'elle retourne un JSON valide
            Mock ConvertTo-Json { return '[{"ToolName":"PSScriptAnalyzer","FilePath":"test.ps1","FileName":"test.ps1","Line":10,"Column":1,"RuleId":"PSAvoidUsingWriteHost","Severity":"Warning","Message":"Avoid using Write-Host","Category":"Best Practice","Suggestion":"Use Write-Output instead","OriginalObject":null}]' }

            # Mock la fonction Out-File pour qu'elle ne fasse rien
            Mock Out-File { }

            # Mock la fonction Test-Path pour qu'elle retourne $true
            Mock Test-Path { return $true } -ParameterFilter { $Path -eq $outputPath }

            # Mock la fonction Get-Content pour qu'elle retourne un JSON valide
            Mock Get-Content { return '[{"ToolName":"PSScriptAnalyzer","FilePath":"test.ps1","FileName":"test.ps1","Line":10,"Column":1,"RuleId":"PSAvoidUsingWriteHost","Severity":"Warning","Message":"Avoid using Write-Host","Category":"Best Practice","Suggestion":"Use Write-Output instead","OriginalObject":null}]' }

            # Act
            Invoke-ScriptWithParams -ScriptPath $scriptPath -Parameters @{
                Path       = $testEnv.TestPsFile
                Tools      = @("PSScriptAnalyzer")
                OutputPath = $outputPath
            }

            # Assert
            Should -Invoke Test-Path -ParameterFilter { $Path -eq $outputPath }
            Should -Invoke Get-Content -ParameterFilter { $Path -eq $outputPath }
        }

        It "Analyse un fichier PowerShell avec TodoAnalyzer" {
            # Arrange
            $outputPath = Join-Path -Path $testEnv.TestDirectory -ChildPath "todo-results.json"

            # Mock la fonction ConvertTo-Json pour qu'elle retourne un JSON valide
            Mock ConvertTo-Json { return '[{"ToolName":"TodoAnalyzer","FilePath":"test.ps1","FileName":"test.ps1","Line":5,"Column":7,"RuleId":"Todo.TODO","Severity":"Information","Message":"TODO: Add more robust error handling","Category":"Documentation","Suggestion":"RÃ©solvez ce TODO ou convertissez-le en tÃ¢che dans le systÃ¨me de suivi des problÃ¨mes.","OriginalObject":null}]' }

            # Mock la fonction Out-File pour qu'elle ne fasse rien
            Mock Out-File { }

            # Mock la fonction Test-Path pour qu'elle retourne $true
            Mock Test-Path { return $true } -ParameterFilter { $Path -eq $outputPath }

            # Mock la fonction Get-Content pour qu'elle retourne un JSON valide
            Mock Get-Content { return '[{"ToolName":"TodoAnalyzer","FilePath":"test.ps1","FileName":"test.ps1","Line":5,"Column":7,"RuleId":"Todo.TODO","Severity":"Information","Message":"TODO: Add more robust error handling","Category":"Documentation","Suggestion":"RÃ©solvez ce TODO ou convertissez-le en tÃ¢che dans le systÃ¨me de suivi des problÃ¨mes.","OriginalObject":null}]' }

            # Act
            Invoke-ScriptWithParams -ScriptPath $scriptPath -Parameters @{
                Path       = $testEnv.TestPsFile
                Tools      = @("TodoAnalyzer")
                OutputPath = $outputPath
            }

            # Assert
            Should -Invoke Test-Path -ParameterFilter { $Path -eq $outputPath }
            Should -Invoke Get-Content -ParameterFilter { $Path -eq $outputPath }
        }

        It "GÃ©nÃ¨re un rapport HTML si demandÃ©" {
            # Arrange
            $outputPath = Join-Path -Path $testEnv.TestDirectory -ChildPath "html-results.json"
            $htmlPath = Join-Path -Path $testEnv.TestDirectory -ChildPath "html-results.html"

            # Mock la fonction ConvertTo-Json pour qu'elle retourne un JSON valide
            Mock ConvertTo-Json { return '[{"ToolName":"PSScriptAnalyzer","FilePath":"test.ps1","FileName":"test.ps1","Line":10,"Column":1,"RuleId":"PSAvoidUsingWriteHost","Severity":"Warning","Message":"Avoid using Write-Host","Category":"Best Practice","Suggestion":"Use Write-Output instead","OriginalObject":null}]' }

            # Mock la fonction Out-File pour qu'elle ne fasse rien
            Mock Out-File { }

            # Mock la fonction Test-Path pour qu'elle retourne $true
            Mock Test-Path { return $true } -ParameterFilter { $Path -eq $htmlPath -or $Path -eq $outputPath }

            # Mock la fonction Get-Content pour qu'elle retourne un contenu HTML valide
            Mock Get-Content { return "<!DOCTYPE html><html><head><title>Rapport d'analyse</title></head><body></body></html>" } -ParameterFilter { $Path -eq $htmlPath }

            # Act
            Invoke-ScriptWithParams -ScriptPath $scriptPath -Parameters @{
                Path               = $testEnv.TestPsFile
                Tools              = @("PSScriptAnalyzer", "TodoAnalyzer")
                OutputPath         = $outputPath
                GenerateHtmlReport = $true
            }

            # Assert
            Should -Invoke Test-Path -ParameterFilter { $Path -eq $htmlPath }
            Should -Invoke Get-Content -ParameterFilter { $Path -eq $htmlPath }
        }
    }

    Context "Analyse d'un rÃ©pertoire" {
        It "Analyse rÃ©cursivement un rÃ©pertoire avec le paramÃ¨tre -Recurse" {
            # Arrange
            $outputPath = Join-Path -Path $testEnv.TestDirectory -ChildPath "dir-results.json"

            # Mock la fonction ConvertTo-Json pour qu'elle retourne un JSON valide
            Mock ConvertTo-Json { return '[{"ToolName":"PSScriptAnalyzer","FilePath":"test.ps1","FileName":"test.ps1","Line":10,"Column":1,"RuleId":"PSAvoidUsingWriteHost","Severity":"Warning","Message":"Avoid using Write-Host","Category":"Best Practice","Suggestion":"Use Write-Output instead","OriginalObject":null},{"ToolName":"PSScriptAnalyzer","FilePath":"subdir\\test2.ps1","FileName":"test2.ps1","Line":10,"Column":1,"RuleId":"PSAvoidUsingWriteHost","Severity":"Warning","Message":"Avoid using Write-Host","Category":"Best Practice","Suggestion":"Use Write-Output instead","OriginalObject":null}]' }

            # Mock la fonction Out-File pour qu'elle ne fasse rien
            Mock Out-File { }

            # Mock la fonction Test-Path pour qu'elle retourne $true
            Mock Test-Path { return $true } -ParameterFilter { $Path -eq $outputPath }

            # Mock la fonction Get-Content pour qu'elle retourne un JSON valide
            Mock Get-Content { return '[{"ToolName":"PSScriptAnalyzer","FilePath":"test.ps1","FileName":"test.ps1","Line":10,"Column":1,"RuleId":"PSAvoidUsingWriteHost","Severity":"Warning","Message":"Avoid using Write-Host","Category":"Best Practice","Suggestion":"Use Write-Output instead","OriginalObject":null},{"ToolName":"PSScriptAnalyzer","FilePath":"subdir\\test2.ps1","FileName":"test2.ps1","Line":10,"Column":1,"RuleId":"PSAvoidUsingWriteHost","Severity":"Warning","Message":"Avoid using Write-Host","Category":"Best Practice","Suggestion":"Use Write-Output instead","OriginalObject":null}]' }

            # Act
            Invoke-ScriptWithParams -ScriptPath $scriptPath -Parameters @{
                Path       = $testEnv.TestDirectory
                Tools      = @("PSScriptAnalyzer")
                OutputPath = $outputPath
                Recurse    = $true
            }

            # Assert
            Should -Invoke Test-Path -ParameterFilter { $Path -eq $outputPath }
            Should -Invoke Get-Content -ParameterFilter { $Path -eq $outputPath }
        }
    }

    Context "Analyse avec plusieurs outils" {
        It "Analyse avec tous les outils disponibles si Tools=All" {
            # Arrange
            $outputPath = Join-Path -Path $testEnv.TestDirectory -ChildPath "all-results.json"

            # Mock la fonction ConvertTo-Json pour qu'elle retourne un JSON valide
            Mock ConvertTo-Json { return '[{"ToolName":"PSScriptAnalyzer","FilePath":"test.ps1","FileName":"test.ps1","Line":10,"Column":1,"RuleId":"PSAvoidUsingWriteHost","Severity":"Warning","Message":"Avoid using Write-Host","Category":"Best Practice","Suggestion":"Use Write-Output instead","OriginalObject":null},{"ToolName":"TodoAnalyzer","FilePath":"test.ps1","FileName":"test.ps1","Line":5,"Column":7,"RuleId":"Todo.TODO","Severity":"Information","Message":"TODO: Add more robust error handling","Category":"Documentation","Suggestion":"RÃ©solvez ce TODO ou convertissez-le en tÃ¢che dans le systÃ¨me de suivi des problÃ¨mes.","OriginalObject":null}]' }

            # Mock la fonction Out-File pour qu'elle ne fasse rien
            Mock Out-File { }

            # Mock la fonction Test-Path pour qu'elle retourne $true
            Mock Test-Path { return $true } -ParameterFilter { $Path -eq $outputPath }

            # Mock la fonction Get-Content pour qu'elle retourne un JSON valide
            Mock Get-Content { return '[{"ToolName":"PSScriptAnalyzer","FilePath":"test.ps1","FileName":"test.ps1","Line":10,"Column":1,"RuleId":"PSAvoidUsingWriteHost","Severity":"Warning","Message":"Avoid using Write-Host","Category":"Best Practice","Suggestion":"Use Write-Output instead","OriginalObject":null},{"ToolName":"TodoAnalyzer","FilePath":"test.ps1","FileName":"test.ps1","Line":5,"Column":7,"RuleId":"Todo.TODO","Severity":"Information","Message":"TODO: Add more robust error handling","Category":"Documentation","Suggestion":"RÃ©solvez ce TODO ou convertissez-le en tÃ¢che dans le systÃ¨me de suivi des problÃ¨mes.","OriginalObject":null}]' }

            # Act
            Invoke-ScriptWithParams -ScriptPath $scriptPath -Parameters @{
                Path       = $testEnv.TestPsFile
                Tools      = @("All")
                OutputPath = $outputPath
            }

            # Assert
            Should -Invoke Test-Path -ParameterFilter { $Path -eq $outputPath }
            Should -Invoke Get-Content -ParameterFilter { $Path -eq $outputPath }
        }
    }

    Context "Analyse parallÃ¨le" {
        It "Analyse en parallÃ¨le avec le paramÃ¨tre -UseParallel" {
            # Arrange
            $outputPath = Join-Path -Path $testEnv.TestDirectory -ChildPath "parallel-results.json"

            # Mock la fonction ConvertTo-Json pour qu'elle retourne un JSON valide
            Mock ConvertTo-Json { return '[{"ToolName":"PSScriptAnalyzer","FilePath":"test.ps1","FileName":"test.ps1","Line":10,"Column":1,"RuleId":"PSAvoidUsingWriteHost","Severity":"Warning","Message":"Avoid using Write-Host","Category":"Best Practice","Suggestion":"Use Write-Output instead","OriginalObject":null}]' }

            # Mock la fonction Out-File pour qu'elle ne fasse rien
            Mock Out-File { }

            # Mock la fonction Test-Path pour qu'elle retourne $true
            Mock Test-Path { return $true } -ParameterFilter { $Path -eq $outputPath }

            # Mock la fonction Get-Content pour qu'elle retourne un JSON valide
            Mock Get-Content { return '[{"ToolName":"PSScriptAnalyzer","FilePath":"test.ps1","FileName":"test.ps1","Line":10,"Column":1,"RuleId":"PSAvoidUsingWriteHost","Severity":"Warning","Message":"Avoid using Write-Host","Category":"Best Practice","Suggestion":"Use Write-Output instead","OriginalObject":null}]' }

            # Act
            Invoke-ScriptWithParams -ScriptPath $scriptPath -Parameters @{
                Path        = $testEnv.TestDirectory
                Tools       = @("PSScriptAnalyzer")
                OutputPath  = $outputPath
                UseParallel = $true
                MaxThreads  = 2
            }

            # Assert
            Should -Invoke Test-Path -ParameterFilter { $Path -eq $outputPath }
            Should -Invoke Get-Content -ParameterFilter { $Path -eq $outputPath }
        }
    }
}
