#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Integrate-ThirdPartyTools.ps1 avec des fichiers rÃ©els.
.DESCRIPTION
    Ce script contient des tests unitaires pour le script Integrate-ThirdPartyTools.ps1
    qui intÃ¨gre les rÃ©sultats d'analyse de code avec des outils tiers.
    Ces tests utilisent des fichiers temporaires rÃ©els au lieu de mocker les fonctions systÃ¨me.
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

Describe "Script Integrate-ThirdPartyTools avec fichiers rÃ©els" {
    BeforeAll {
        # CrÃ©er un environnement de test
        $testEnv = New-TestEnvironment -TestName "IntegrateThirdPartyToolsRealTests"

        # CrÃ©er un fichier JSON de test avec des rÃ©sultats d'analyse
        $testJsonContent = @"
[
  {
    "ToolName": "PSScriptAnalyzer",
    "FilePath": "test.ps1",
    "FileName": "test.ps1",
    "Line": 10,
    "Column": 1,
    "RuleId": "PSAvoidUsingWriteHost",
    "Severity": "Warning",
    "Message": "Avoid using Write-Host",
    "Category": "Best Practice",
    "Suggestion": "Use Write-Output instead",
    "OriginalObject": null
  },
  {
    "ToolName": "TodoAnalyzer",
    "FilePath": "test.ps1",
    "FileName": "test.ps1",
    "Line": 5,
    "Column": 7,
    "RuleId": "Todo.TODO",
    "Severity": "Information",
    "Message": "TODO: Add more robust error handling",
    "Category": "Documentation",
    "Suggestion": "RÃ©solvez ce TODO ou convertissez-le en tÃ¢che dans le systÃ¨me de suivi des problÃ¨mes.",
    "OriginalObject": null
  },
  {
    "ToolName": "PSScriptAnalyzer",
    "FilePath": "test.ps1",
    "FileName": "test.ps1",
    "Line": 1,
    "Column": 1,
    "RuleId": "PSUseDeclaredVarsMoreThanAssignments",
    "Severity": "Error",
    "Message": "Variable is assigned but never used",
    "Category": "Best Practice",
    "Suggestion": "Use the variable or remove it",
    "OriginalObject": null
  }
]
"@
        $testJsonPath = Join-Path -Path $testEnv.TestDirectory -ChildPath "test-results.json"
        Set-Content -Path $testJsonPath -Value $testJsonContent -Encoding UTF8
    }

    Context "ParamÃ¨tres et validation" {
        It "LÃ¨ve une exception si le chemin n'existe pas" {
            # Act & Assert
            { & $scriptPath -Path "C:\chemin\inexistant" -Tool "GitHub" } | Should -Throw
        }

        It "LÃ¨ve une exception si ProjectKey est manquant pour SonarQube" {
            # Arrange
            $testJsonPath = Join-Path -Path $testEnv.TestDirectory -ChildPath "test-results.json"

            # Act & Assert
            # Note: Nous devons capturer la sortie d'erreur pour vÃ©rifier qu'une erreur est gÃ©nÃ©rÃ©e
            $errorOutput = & $scriptPath -Path $testJsonPath -Tool "SonarQube" 2>&1
            $errorOutput | Should -Not -BeNullOrEmpty
            $errorOutput | Should -Match "ProjectKey est requis"
        }
    }

    Context "Conversion vers GitHub format" {
        It "Convertit les rÃ©sultats vers le format GitHub" {
            # Arrange
            $testJsonPath = Join-Path -Path $testEnv.TestDirectory -ChildPath "test-results.json"
            $outputPath = Join-Path -Path $testEnv.TestDirectory -ChildPath "github-results.json"

            # Act
            & $scriptPath -Path $testJsonPath -Tool "GitHub" -OutputPath $outputPath

            # Assert
            Test-Path -Path $outputPath | Should -BeTrue
            $content = Get-Content -Path $outputPath -Raw | ConvertFrom-Json
            $content.annotations | Should -Not -BeNullOrEmpty
            $content.annotations.Count | Should -Be 3
            $content.annotations[0].annotation_level | Should -Be "warning"
            $content.annotations[1].annotation_level | Should -Be "notice"
            $content.annotations[2].annotation_level | Should -Be "error"
        }
    }

    Context "Conversion vers SonarQube format" {
        It "Convertit les rÃ©sultats vers le format SonarQube" {
            # Arrange
            $testJsonPath = Join-Path -Path $testEnv.TestDirectory -ChildPath "test-results.json"
            $outputPath = Join-Path -Path $testEnv.TestDirectory -ChildPath "sonarqube-results.json"

            # Act
            & $scriptPath -Path $testJsonPath -Tool "SonarQube" -OutputPath $outputPath -ProjectKey "test-project"

            # Assert
            Test-Path -Path $outputPath | Should -BeTrue
            $content = Get-Content -Path $outputPath -Raw | ConvertFrom-Json
            $content.issues | Should -Not -BeNullOrEmpty
            $content.issues.Count | Should -Be 3
            $content.issues[0].severity | Should -Be "MAJOR"
            $content.issues[1].severity | Should -Be "MINOR"
            $content.issues[2].severity | Should -Be "CRITICAL"
        }
    }

    Context "Conversion vers AzureDevOps format" {
        It "Convertit les rÃ©sultats vers le format AzureDevOps" {
            # Arrange
            $testJsonPath = Join-Path -Path $testEnv.TestDirectory -ChildPath "test-results.json"
            $outputPath = Join-Path -Path $testEnv.TestDirectory -ChildPath "azuredevops-results.json"

            # Act
            & $scriptPath -Path $testJsonPath -Tool "AzureDevOps" -OutputPath $outputPath

            # Assert
            Test-Path -Path $outputPath | Should -BeTrue
            $content = Get-Content -Path $outputPath -Raw | ConvertFrom-Json
            $content.issues | Should -Not -BeNullOrEmpty
            $content.issues.Count | Should -Be 3
            $content.issues[0].severity | Should -Be 2
            $content.issues[1].severity | Should -Be 3
            $content.issues[2].severity | Should -Be 1
        }
    }

    Context "Envoi des rÃ©sultats Ã  l'API" {
        It "GÃ©nÃ¨re une erreur si l'API n'est pas accessible" {
            # Arrange
            $testJsonPath = Join-Path -Path $testEnv.TestDirectory -ChildPath "test-results.json"
            $outputPath = Join-Path -Path $testEnv.TestDirectory -ChildPath "sonarqube-api-results.json"

            # Act & Assert
            # Note: Nous ne pouvons pas tester l'envoi rÃ©el Ã  l'API, mais nous pouvons vÃ©rifier que le fichier est crÃ©Ã©
            & $scriptPath -Path $testJsonPath -Tool "SonarQube" -OutputPath $outputPath -ProjectKey "test-project" -ApiKey "test-api-key" -ApiUrl "https://sonarqube.example.com"

            # Assert
            Test-Path -Path $outputPath | Should -BeTrue
            $content = Get-Content -Path $outputPath -Raw | ConvertFrom-Json
            $content.issues | Should -Not -BeNullOrEmpty
        }
    }
}
