#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour les fonctionnalitÃ©s de performance du module SyntaxAnalyzer.
.DESCRIPTION
    Ce script contient des tests unitaires pour les fonctionnalitÃ©s de performance
    et d'analyse parallÃ¨le du module SyntaxAnalyzer en utilisant le framework Pester.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-30
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

# Importer le module de cache si disponible
$cacheModulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\PRAnalysisCache.psm1"
if (Test-Path -Path $cacheModulePath) {
    Import-Module $cacheModulePath -Force
    $script:cache = New-PRAnalysisCache -MaxMemoryItems 100
} else {
    $script:cache = $null
}

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "SyntaxAnalyzerPerformanceTests_$(Get-Random)"
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

# CrÃ©er des fichiers de test
$psScriptContent = @"
# Test PowerShell Script with Syntax Errors
function Test-Function {
    param(
        [string]`$param1,
        [int]`$param2 = 0
    )

    `$testVariable = "Test value"
    Write-Output `$testVariable

    # Syntax error: missing closing parenthesis
    if (`$param2 -gt 0 {
        Write-Output "Param2 is greater than 0"
    }

    # Style warning: using alias
    gci -Path "C:\" -Filter "*.txt"
}

# Unused variable
`$unusedVar = 42

Test-Function -param1 "Test" -param2 42
"@

$pyScriptContent = @"
# Test Python Script with Syntax Errors
import os
import sys

class TestClass:
    def __init__(self, name):
        self.name = name

    def test_method(self):
        print(f"Hello, {self.name}!")

# Indentation error
def test_function(param1, param2=0):
    test_variable = "Test value"
print(test_variable)  # Not indented properly

if __name__ == "__main__":
    test_function("Test", 42)
    obj = TestClass("World")
    obj.test_method()
"@

# CrÃ©er le fichier PowerShell pour les tests
$testPsScript = New-TestFile -Path "test_syntax.ps1" -Content $psScriptContent

# Nous n'utilisons pas directement le fichier Python dans les tests, mais nous le crÃ©ons quand mÃªme
# pour complÃ©tude et pour les tests futurs qui pourraient l'utiliser
New-TestFile -Path "test_syntax.py" -Content $pyScriptContent | Out-Null

# CrÃ©er plusieurs fichiers pour les tests de performance
for ($i = 1; $i -le 5; $i++) {
    $content = $psScriptContent.Replace("Test-Function", "Test-Function$i")
    New-TestFile -Path "test_perf_$i.ps1" -Content $content
}

# Tests Pester
Describe "SyntaxAnalyzer Performance Tests" {
    BeforeAll {
        # CrÃ©er un analyseur pour les tests
        $script:analyzer = New-SyntaxAnalyzer -UseCache ($null -ne $script:cache) -Cache $script:cache
    }

    Context "MÃ©triques de performance" {
        It "Collecte des mÃ©triques de performance lors de l'analyse d'un fichier" {
            $results = $analyzer.AnalyzeFile($testPsScript)

            $results | Should -Not -BeNullOrEmpty
            $analyzer.PerformanceMetrics | Should -Not -BeNullOrEmpty
            $analyzer.PerformanceMetrics.FileCount | Should -BeGreaterThan 0
            $analyzer.PerformanceMetrics.TotalFileSize | Should -BeGreaterThan 0
        }
    }

    Context "Analyse parallÃ¨le" {
        It "Analyse plusieurs fichiers en parallÃ¨le" {
            $files = Get-ChildItem -Path $testDir -Filter "test_perf_*.ps1" | Select-Object -ExpandProperty FullName
            $results = $analyzer.AnalyzeFiles($files)

            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -Be $files.Count

            foreach ($file in $files) {
                $results.ContainsKey($file) | Should -Be $true
                $results[$file] | Should -Not -BeNullOrEmpty
            }
        }

        It "Collecte des mÃ©triques de performance pour l'analyse parallÃ¨le" {
            $files = Get-ChildItem -Path $testDir -Filter "test_perf_*.ps1" | Select-Object -ExpandProperty FullName
            # ExÃ©cuter l'analyse et ignorer les rÃ©sultats car nous testons seulement les mÃ©triques
            $analyzer.AnalyzeFiles($files) | Out-Null

            $analyzer.PerformanceMetrics.ParallelJobs | Should -BeGreaterThan 0
            $analyzer.PerformanceMetrics.TotalAnalysisTime.ElapsedMilliseconds | Should -BeGreaterThan 0
        }
    }

    Context "Optimisation des performances" {
        It "Utilise le cache pour amÃ©liorer les performances" {
            if ($null -ne $script:cache) {
                # PremiÃ¨re analyse (sans cache)
                $startTime1 = [System.Diagnostics.Stopwatch]::StartNew()
                # ExÃ©cuter l'analyse et ignorer les rÃ©sultats car nous testons seulement le temps d'exÃ©cution
                $analyzer.AnalyzeFile($testPsScript) | Out-Null
                $startTime1.Stop()
                $time1 = $startTime1.ElapsedMilliseconds

                # DeuxiÃ¨me analyse (avec cache)
                $startTime2 = [System.Diagnostics.Stopwatch]::StartNew()
                # ExÃ©cuter l'analyse et ignorer les rÃ©sultats car nous testons seulement le temps d'exÃ©cution
                $analyzer.AnalyzeFile($testPsScript) | Out-Null
                $startTime2.Stop()
                $time2 = $startTime2.ElapsedMilliseconds

                # La deuxiÃ¨me analyse devrait Ãªtre plus rapide
                $time2 | Should -BeLessThan $time1
            } else {
                Set-ItResult -Skipped -Because "Le module de cache n'est pas disponible"
            }
        }
    }

    AfterAll {
        # Nettoyer les fichiers de test
        Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Path $PSCommandPath -Output Detailed
