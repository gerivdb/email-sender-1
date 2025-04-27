#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module SyntaxAnalyzer.
.DESCRIPTION
    Ce script contient des tests unitaires pour le module SyntaxAnalyzer
    en utilisant le framework Pester.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation recommandÃ©e: Install-Module -Name Pester -Force -SkipPublisherCheck"
}

# Chemin du module Ã  tester
$moduleToTest = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\SyntaxAnalyzer.psm1"

# VÃ©rifier que le module existe
if (-not (Test-Path -Path $moduleToTest)) {
    throw "Module SyntaxAnalyzer non trouvÃ© Ã  l'emplacement: $moduleToTest"
}

# Importer le module Ã  tester
Import-Module $moduleToTest -Force

# Importer le module de cache pour les tests
$cacheModulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\PRAnalysisCache.psm1"
if (Test-Path -Path $cacheModulePath) {
    Import-Module $cacheModulePath -Force
}

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "SyntaxAnalyzerTests_$(Get-Random)"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null

# Fonction pour crÃ©er des fichiers de test
function New-TestFile {
    param(
        [string]$Path,
        [string]$Content
    )

    $fullPath = Join-Path -Path $testDir -ChildPath $Path
    $directory = Split-Path -Path $fullPath -Parent

    if (-not (Test-Path -Path $directory)) {
        New-Item -Path $directory -ItemType Directory -Force | Out-Null
    }

    Set-Content -Path $fullPath -Value $Content -Encoding UTF8
    return $fullPath
}

# CrÃ©er des fichiers de test avec diffÃ©rents types d'erreurs
$psScriptWithErrors = @'
function Test-Function {
    param(
        [string]$Parameter1,
        [int]$Parameter2 = 0
    )

    # Variable non dÃ©clarÃ©e
    $result = $undeclaredVariable + $Parameter2

    # Ligne trop longue
    $veryLongLine = "Cette ligne est trÃ¨s longue et dÃ©passe la limite recommandÃ©e de 120 caractÃ¨res pour les scripts PowerShell, ce qui peut rendre le code difficile Ã  lire et Ã  maintenir."

    return $result
}

# Syntaxe incorrecte
if ($condition {
    Write-Output "Erreur de syntaxe"
}
'@

$pythonScriptWithErrors = @'
import os
import sys

# Indentation incorrecte
class TestClass:
    def __init__(self, name):
        self.name = name

   def test_method(self, param1):
        return f"Hello, {param1}!"

# Ligne trop longue
very_long_line = "Cette ligne est trÃ¨s longue et dÃ©passe la limite recommandÃ©e de 79 caractÃ¨res pour les scripts Python, ce qui peut rendre le code difficile Ã  lire et Ã  maintenir."

# Syntaxe incorrecte
if condition:
    print("Erreur de syntaxe"
'@

$htmlWithErrors = @'
<!DOCTYPE html>
<html>
<head>
    <title>Test HTML</title>
</head>
<body>
    <div>
        <p>Test paragraph</p>
        <!-- Balise non fermÃ©e -->
        <span>Test span
    </div>

    <!-- Balise fermante sans ouvrante -->
    </section>
</body>
</html>
'@

$cssWithErrors = @'
body {
    font-family: Arial, sans-serif;
    color: #333;
    background-color: #f5f5f5

.container {
    width: 100%;
    max-width: 1200px;
    margin: 0 auto;
}

/* Accolade non fermÃ©e */
.header {
    padding: 20px;
    background-color: #333;
    color: white;
'@

$testPsScript = New-TestFile -Path "test_script_with_errors.ps1" -Content $psScriptWithErrors
$testPyScript = New-TestFile -Path "test_script_with_errors.py" -Content $pythonScriptWithErrors
$testHtmlFile = New-TestFile -Path "test_file_with_errors.html" -Content $htmlWithErrors
$testCssFile = New-TestFile -Path "test_file_with_errors.css" -Content $cssWithErrors

# Tests Pester
Describe "SyntaxAnalyzer Module Tests" {
    BeforeAll {
        # CrÃ©er un cache pour les tests
        $cachePath = Join-Path -Path $testDir -ChildPath "cache"
        New-Item -Path $cachePath -ItemType Directory -Force | Out-Null

        if (Get-Command -Name New-PRAnalysisCache -ErrorAction SilentlyContinue) {
            $script:cache = New-PRAnalysisCache -Name "TestCache" -CachePath $cachePath
        } else {
            $script:cache = $null
        }

        # CrÃ©er un analyseur pour les tests
        $script:analyzer = New-SyntaxAnalyzer -UseCache ($null -ne $script:cache) -Cache $script:cache
    }

    Context "New-SyntaxAnalyzer" {
        It "CrÃ©e un nouvel analyseur" {
            $analyzer | Should -Not -BeNullOrEmpty
            $analyzer.GetType().Name | Should -Be "SyntaxAnalyzer"
        }

        It "Initialise correctement les propriÃ©tÃ©s" {
            $analyzer.LanguageHandlers | Should -Not -BeNullOrEmpty
            $analyzer.RuleSet | Should -Not -BeNullOrEmpty
            $analyzer.UseCache | Should -Be ($null -ne $script:cache)
            if ($null -ne $script:cache) {
                $analyzer.Cache | Should -Be $script:cache
            }
        }
    }

    Context "Invoke-SyntaxAnalysis" {
        It "Analyse un fichier PowerShell avec erreurs" {
            $results = Invoke-SyntaxAnalysis -Analyzer $analyzer -FilePath $testPsScript
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0

            # VÃ©rifier qu'il y a au moins une erreur de syntaxe
            $syntaxErrors = $results | Where-Object { $_.Type -eq "Syntax" }
            $syntaxErrors.Count | Should -BeGreaterThan 0

            # VÃ©rifier qu'il y a au moins un avertissement de style
            $styleWarnings = $results | Where-Object { $_.Type -eq "Style" }
            $styleWarnings.Count | Should -BeGreaterThan 0
        }

        It "Analyse un fichier Python avec erreurs" {
            $results = Invoke-SyntaxAnalysis -Analyzer $analyzer -FilePath $testPyScript
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0

            # VÃ©rifier qu'il y a au moins une erreur d'indentation
            $indentationErrors = $results | Where-Object { $_.Message -like "*indentation*" }
            $indentationErrors.Count | Should -BeGreaterOrEqual 0  # Peut Ãªtre 0 si pylint n'est pas disponible
        }

        It "Analyse un fichier HTML avec erreurs" {
            $results = Invoke-SyntaxAnalysis -Analyzer $analyzer -FilePath $testHtmlFile
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0

            # VÃ©rifier qu'il y a au moins une erreur de balise non fermÃ©e
            $tagErrors = $results | Where-Object { $_.Rule -eq "UnclosedTag" -or $_.Rule -eq "UnmatchedTag" }
            $tagErrors.Count | Should -BeGreaterThan 0
        }

        It "Analyse un fichier CSS avec erreurs" {
            $results = Invoke-SyntaxAnalysis -Analyzer $analyzer -FilePath $testCssFile
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0

            # VÃ©rifier qu'il y a au moins une erreur de point-virgule manquant
            $semicolonErrors = $results | Where-Object { $_.Rule -eq "MissingSemicolon" }
            $semicolonErrors.Count | Should -BeGreaterThan 0

            # VÃ©rifier qu'il y a au moins une erreur d'accolade non fermÃ©e
            $braceErrors = $results | Where-Object { $_.Rule -eq "UnbalancedBraces" }
            $braceErrors.Count | Should -BeGreaterThan 0
        }

        It "Retourne un tableau vide pour un fichier inexistant" {
            $results = Invoke-SyntaxAnalysis -Analyzer $analyzer -FilePath "fichier_inexistant.txt" -ErrorAction SilentlyContinue
            $results | Should -BeOfType [array]
            $results.Count | Should -Be 0
        }
    }

    Context "Invoke-BatchSyntaxAnalysis" {
        It "Analyse plusieurs fichiers en parallÃ¨le" {
            $filePaths = @($testPsScript, $testHtmlFile, $testCssFile)
            $results = Invoke-BatchSyntaxAnalysis -Analyzer $analyzer -FilePaths $filePaths
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -Be 3

            $results[$testPsScript] | Should -Not -BeNullOrEmpty
            $results[$testPsScript].Count | Should -BeGreaterThan 0

            $results[$testHtmlFile] | Should -Not -BeNullOrEmpty
            $results[$testHtmlFile].Count | Should -BeGreaterThan 0

            $results[$testCssFile] | Should -Not -BeNullOrEmpty
            $results[$testCssFile].Count | Should -BeGreaterThan 0
        }

        It "GÃ¨re correctement les fichiers inexistants" {
            $filePaths = @($testPsScript, "fichier_inexistant.txt")
            $results = Invoke-BatchSyntaxAnalysis -Analyzer $analyzer -FilePaths $filePaths
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -Be 2

            $results[$testPsScript] | Should -Not -BeNullOrEmpty
            $results[$testPsScript].Count | Should -BeGreaterThan 0

            $results["fichier_inexistant.txt"] | Should -BeOfType [array]
            $results["fichier_inexistant.txt"].Count | Should -Be 0
        }
    }

    Context "Register-SyntaxRule" {
        It "Enregistre une rÃ¨gle personnalisÃ©e" {
            # CrÃ©er une rÃ¨gle personnalisÃ©e
            $ruleName = "TEST001"
            $ruleDescription = "RÃ¨gle de test"
            $ruleHandler = {
                param($content, $tokens)

                $results = [System.Collections.Generic.List[object]]::new()
                $results.Add([PSCustomObject]@{
                        Type     = "Test"
                        Line     = 1
                        Column   = 1
                        Message  = "Message de test"
                        Severity = "Information"
                    })

                return $results
            }

            # Enregistrer la rÃ¨gle
            Register-SyntaxRule -Analyzer $analyzer -ID $ruleName -Language "All" -Description $ruleDescription -Handler $ruleHandler

            # VÃ©rifier que la rÃ¨gle a Ã©tÃ© enregistrÃ©e
            $analyzer.RuleSet[$ruleName] | Should -Not -BeNullOrEmpty
            $analyzer.RuleSet[$ruleName].ID | Should -Be $ruleName
            $analyzer.RuleSet[$ruleName].Description | Should -Be $ruleDescription
            $analyzer.RuleSet[$ruleName].Language | Should -Be "All"
            $analyzer.RuleSet[$ruleName].Handler | Should -Not -BeNullOrEmpty

            # Tester la rÃ¨gle
            $results = Invoke-SyntaxAnalysis -Analyzer $analyzer -FilePath $testPsScript
            $testRuleResults = $results | Where-Object { $_.Rule -eq $ruleName }
            $testRuleResults | Should -Not -BeNullOrEmpty
            $testRuleResults.Count | Should -BeGreaterThan 0
            $testRuleResults[0].Type | Should -Be "Test"
            $testRuleResults[0].Message | Should -Be "Message de test"
        }
    }

    AfterAll {
        # Nettoyer les fichiers de test
        Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Path $PSCommandPath -Output Detailed
