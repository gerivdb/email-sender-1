#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module UnifiedResultsFormat.
.DESCRIPTION
    Ce script contient des tests unitaires pour le module UnifiedResultsFormat
    qui définit un format unifié pour les résultats d'analyse de différents outils.
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas disponible. Installez-le avec 'Install-Module -Name Pester -Force'."
    return
}

# Importer le module à tester
$modulePath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath "modules\UnifiedResultsFormat.psm1"
if (-not (Test-Path -Path $modulePath)) {
    throw "Le module UnifiedResultsFormat.psm1 n'existe pas à l'emplacement: $modulePath"
}

Import-Module -Name $modulePath -Force

Describe "Module UnifiedResultsFormat" {
    Context "New-UnifiedAnalysisResult" {
        It "Crée un résultat d'analyse avec les propriétés requises" {
            # Arrange
            $toolName = "TestTool"
            $filePath = "C:\test\file.ps1"
            $line = 10
            $column = 5
            $ruleId = "TestRule"
            $severity = "Warning"
            $message = "Test message"

            # Act
            $result = New-UnifiedAnalysisResult -ToolName $toolName -FilePath $filePath -Line $line -Column $column -RuleId $ruleId -Severity $severity -Message $message

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.ToolName | Should -Be $toolName
            $result.FilePath | Should -Be $filePath
            $result.FileName | Should -Be "file.ps1"
            $result.Line | Should -Be $line
            $result.Column | Should -Be $column
            $result.RuleId | Should -Be $ruleId
            $result.Severity | Should -Be $severity
            $result.Message | Should -Be $message
        }

        It "Accepte des paramètres optionnels" {
            # Arrange
            $toolName = "TestTool"
            $filePath = "C:\test\file.ps1"
            $line = 10
            $column = 5
            $ruleId = "TestRule"
            $severity = "Warning"
            $message = "Test message"
            $category = "TestCategory"
            $suggestion = "Test suggestion"

            # Act
            $result = New-UnifiedAnalysisResult -ToolName $toolName -FilePath $filePath -Line $line -Column $column -RuleId $ruleId -Severity $severity -Message $message -Category $category -Suggestion $suggestion

            # Assert
            $result.Category | Should -Be $category
            $result.Suggestion | Should -Be $suggestion
        }

        It "Valide les valeurs de sévérité" {
            # Arrange
            $toolName = "TestTool"
            $filePath = "C:\test\file.ps1"
            $line = 10
            $column = 5
            $ruleId = "TestRule"
            $message = "Test message"

            # Act & Assert
            { New-UnifiedAnalysisResult -ToolName $toolName -FilePath $filePath -Line $line -Column $column -RuleId $ruleId -Severity "Error" -Message $message } | Should -Not -Throw
            { New-UnifiedAnalysisResult -ToolName $toolName -FilePath $filePath -Line $line -Column $column -RuleId $ruleId -Severity "Warning" -Message $message } | Should -Not -Throw
            { New-UnifiedAnalysisResult -ToolName $toolName -FilePath $filePath -Line $line -Column $column -RuleId $ruleId -Severity "Information" -Message $message } | Should -Not -Throw
            { New-UnifiedAnalysisResult -ToolName $toolName -FilePath $filePath -Line $line -Column $column -RuleId $ruleId -Severity "InvalidValue" -Message $message } | Should -Throw
        }
    }

    Context "ConvertFrom-PSScriptAnalyzerResult" {
        It "Convertit les résultats de PSScriptAnalyzer vers le format unifié" {
            # Arrange
            $psaResult = [PSCustomObject]@{
                ScriptPath        = "C:\test\file.ps1"
                Line              = 10
                Column            = 5
                RuleName          = "PSAvoidUsingWriteHost"
                Severity          = "Warning"
                Message           = "Avoid using Write-Host"
                RuleSuppressionID = "Style"
            }

            # Act
            $result = ConvertFrom-PSScriptAnalyzerResult -Results @($psaResult)

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result[0].ToolName | Should -Be "PSScriptAnalyzer"
            $result[0].FilePath | Should -Be $psaResult.ScriptPath
            $result[0].Line | Should -Be $psaResult.Line
            $result[0].Column | Should -Be $psaResult.Column
            $result[0].RuleId | Should -Be $psaResult.RuleName
            $result[0].Severity | Should -Be $psaResult.Severity
            $result[0].Message | Should -Be $psaResult.Message
            $result[0].Category | Should -Be $psaResult.RuleSuppressionID
        }

        It "Gère correctement un tableau vide" {
            # Act
            $result = ConvertFrom-PSScriptAnalyzerResult -Results @()

            # Assert
            $result | Should -BeNullOrEmpty
        }

        It "Mappe correctement les sévérités" {
            # Arrange
            $severities = @("Error", "Warning", "Information", "Unknown")
            $results = @()

            foreach ($severity in $severities) {
                $results += [PSCustomObject]@{
                    ScriptPath        = "C:\test\file.ps1"
                    Line              = 10
                    Column            = 5
                    RuleName          = "TestRule"
                    Severity          = $severity
                    Message           = "Test message"
                    RuleSuppressionID = "Style"
                }
            }

            # Act
            $convertedResults = ConvertFrom-PSScriptAnalyzerResult -Results $results

            # Assert
            $convertedResults.Count | Should -Be $severities.Count
            $convertedResults[0].Severity | Should -Be "Error"
            $convertedResults[1].Severity | Should -Be "Warning"
            $convertedResults[2].Severity | Should -Be "Information"
            $convertedResults[3].Severity | Should -Be "Information" # Unknown devrait être mappé à Information
        }
    }

    # Ajouter d'autres tests pour les fonctions du module si nécessaire
}
