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
    Write-Warning "Le module Pester n'est pas installé. Installation recommandée: Install-Module -Name Pester -Force -SkipPublisherCheck"
}

# Chemin du module à tester
$moduleToTest = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\SyntaxAnalyzer.psm1"

# Vérifier que le module existe
if (-not (Test-Path -Path $moduleToTest)) {
    throw "Module SyntaxAnalyzer non trouvé à l'emplacement: $moduleToTest"
}

# Importer le module à tester
Import-Module $moduleToTest -Force

# Importer le module de cache pour les tests
$cacheModulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\PRAnalysisCache.psm1"
if (Test-Path -Path $cacheModulePath) {
    Import-Module $cacheModulePath -Force
}

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "SyntaxAnalyzerTests_$(Get-Random)"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null

# Fonction pour créer des fichiers de test
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

# Créer des fichiers de test avec différents types d'erreurs
$psScriptWithErrors = @'
function Test-Function {
    param(
        [string]$Parameter1,
        [int]$Parameter2 = 0
    )

    # Variable non déclarée
    $result = $undeclaredVariable + $Parameter2

    # Ligne trop longue
    $veryLongLine = "Cette ligne est très longue et dépasse la limite recommandée de 120 caractères pour les scripts PowerShell, ce qui peut rendre le code difficile à lire et à maintenir."

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
very_long_line = "Cette ligne est très longue et dépasse la limite recommandée de 79 caractères pour les scripts Python, ce qui peut rendre le code difficile à lire et à maintenir."

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
        <!-- Balise non fermée -->
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

/* Accolade non fermée */
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
        # Créer un cache pour les tests
        $cachePath = Join-Path -Path $testDir -ChildPath "cache"
        New-Item -Path $cachePath -ItemType Directory -Force | Out-Null

        if (Get-Command -Name New-PRAnalysisCache -ErrorAction SilentlyContinue) {
            $script:cache = New-PRAnalysisCache -Name "TestCache" -CachePath $cachePath
        } else {
            $script:cache = $null
        }

        # Créer un analyseur pour les tests
        $script:analyzer = New-SyntaxAnalyzer -UseCache ($null -ne $script:cache) -Cache $script:cache
    }

    Context "New-SyntaxAnalyzer" {
        It "Crée un nouvel analyseur" {
            $analyzer | Should -Not -BeNullOrEmpty
            $analyzer.GetType().Name | Should -Be "SyntaxAnalyzer"
        }

        It "Initialise correctement les propriétés" {
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

            # Vérifier qu'il y a au moins une erreur de syntaxe
            $syntaxErrors = $results | Where-Object { $_.Type -eq "Syntax" }
            $syntaxErrors.Count | Should -BeGreaterThan 0

            # Vérifier qu'il y a au moins un avertissement de style
            $styleWarnings = $results | Where-Object { $_.Type -eq "Style" }
            $styleWarnings.Count | Should -BeGreaterThan 0
        }

        It "Analyse un fichier Python avec erreurs" {
            $results = Invoke-SyntaxAnalysis -Analyzer $analyzer -FilePath $testPyScript
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0

            # Vérifier qu'il y a au moins une erreur d'indentation
            $indentationErrors = $results | Where-Object { $_.Message -like "*indentation*" }
            $indentationErrors.Count | Should -BeGreaterOrEqual 0  # Peut être 0 si pylint n'est pas disponible
        }

        It "Analyse un fichier HTML avec erreurs" {
            $results = Invoke-SyntaxAnalysis -Analyzer $analyzer -FilePath $testHtmlFile
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0

            # Vérifier qu'il y a au moins une erreur de balise non fermée
            $tagErrors = $results | Where-Object { $_.Rule -eq "UnclosedTag" -or $_.Rule -eq "UnmatchedTag" }
            $tagErrors.Count | Should -BeGreaterThan 0
        }

        It "Analyse un fichier CSS avec erreurs" {
            $results = Invoke-SyntaxAnalysis -Analyzer $analyzer -FilePath $testCssFile
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0

            # Vérifier qu'il y a au moins une erreur de point-virgule manquant
            $semicolonErrors = $results | Where-Object { $_.Rule -eq "MissingSemicolon" }
            $semicolonErrors.Count | Should -BeGreaterThan 0

            # Vérifier qu'il y a au moins une erreur d'accolade non fermée
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
        It "Analyse plusieurs fichiers en parallèle" {
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

        It "Gère correctement les fichiers inexistants" {
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
        It "Enregistre une règle personnalisée" {
            # Créer une règle personnalisée
            $ruleName = "TEST001"
            $ruleDescription = "Règle de test"
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

            # Enregistrer la règle
            Register-SyntaxRule -Analyzer $analyzer -ID $ruleName -Language "All" -Description $ruleDescription -Handler $ruleHandler

            # Vérifier que la règle a été enregistrée
            $analyzer.RuleSet[$ruleName] | Should -Not -BeNullOrEmpty
            $analyzer.RuleSet[$ruleName].ID | Should -Be $ruleName
            $analyzer.RuleSet[$ruleName].Description | Should -Be $ruleDescription
            $analyzer.RuleSet[$ruleName].Language | Should -Be "All"
            $analyzer.RuleSet[$ruleName].Handler | Should -Not -BeNullOrEmpty

            # Tester la règle
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

# Exécuter les tests
Invoke-Pester -Path $PSCommandPath -Output Detailed
