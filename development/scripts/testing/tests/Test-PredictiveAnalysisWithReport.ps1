#Requires -Version 5.1
<#
.SYNOPSIS
    Teste le systÃ¨me d'analyse prÃ©dictive et gÃ©nÃ¨re un rapport permanent.
.DESCRIPTION
    Ce script teste le systÃ¨me d'analyse prÃ©dictive en crÃ©ant des fichiers de test
    avec diffÃ©rents types d'erreurs et en exÃ©cutant l'analyse prÃ©dictive sur ces fichiers.
    Le rapport gÃ©nÃ©rÃ© est conservÃ© dans un emplacement permanent.
.PARAMETER OutputPath
    Chemin oÃ¹ enregistrer le rapport d'analyse prÃ©dictive.
.EXAMPLE
    .\Test-PredictiveAnalysisWithReport.ps1
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-30
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$OutputPath = "$PSScriptRoot\reports\PredictiveAnalysisReport.html"
)

# CrÃ©er le rÃ©pertoire des rapports s'il n'existe pas
$reportsDir = Join-Path -Path $PSScriptRoot -ChildPath "reports"
if (-not (Test-Path -Path $reportsDir)) {
    New-Item -Path $reportsDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "PredictiveAnalysisTest_$(Get-Random)"
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
Write-Host "CrÃ©ation de fichiers de test..." -ForegroundColor Cyan

# PowerShell avec erreurs
$psScriptWithErrors = @"
# Test PowerShell Script with Errors
function Test-Function {
    param(
        [string]`$param1,
        [int]`$param2 = 0
    )

    `$testVariable = "Test value"

    # Erreur: Utilisation d'un alias
    gci -Path "C:\" | Where { `$_.Name -like "*.txt" }

    # Erreur: Utilisation de Invoke-Expression
    Invoke-Expression "Get-Process"

    # Erreur: Suppression rÃ©cursive
    Remove-Item -Path "C:\Temp\*" -Recurse -Force

    # Erreur: Comparaison incorrecte avec null
    if (`$param1 == `$null) {
        Write-Output "Param1 is null"
    }

    Write-Output `$testVariable
}

Test-Function -param1 "Test"
"@

# Python avec erreurs
$pyScriptWithErrors = @"
# Test Python Script with Errors
import os
import sys

class TestClass:
    def __init__(self, name):
        self.name = name

    def test_method(self):
        print(f"Hello, {self.name}!")

def test_function(param1, param2=0):
    test_variable = "Test value"

    # Erreur: Utilisation de eval()
    result = eval("2 + 2")

    # Erreur: Appel systÃ¨me direct
    os.system("ls -la")

    # Erreur: Exception gÃ©nÃ©rique
    try:
        x = 1 / 0
    except:
        pass

    # Erreur: Indentation incohÃ©rente
    if param1:
      print("Indentation incorrecte")

    print(test_variable)

if __name__ == "__main__":
    test_function("Test", 42)
    obj = TestClass("World")
    obj.test_method()
"@

# JavaScript avec erreurs
$jsScriptWithErrors = @"
// Test JavaScript Script with Errors

function testFunction(param1, param2 = 0) {
    const testVariable = "Test value";

    // Erreur: Utilisation de eval()
    const result = eval("2 + 2");

    // Erreur: Utilisation de document.write()
    document.write("<p>Hello World</p>");

    // Erreur: Utilisation du stockage local
    localStorage.setItem("test", "value");

    // Erreur: Utilisation de console.log()
    console.log(testVariable);

    // Erreur: Point-virgule manquant
    return result
}

// Erreur: Mode strict manquant

class TestClass {
    constructor(name) {
        this.name = name;
    }

    testMethod() {
        console.log(`Hello, \${this.name}!`);
    }
}

const obj = new TestClass("World");
obj.testMethod();
testFunction("Test", 42);
"@

# HTML avec erreurs
$htmlWithErrors = @"
<!DOCTYPE html>
<html>
<head>
    <title>Test HTML with Errors</title>
    <style>
        .test-class {
            color: red
        }
        #test-id {
            font-weight: bold;
        }
    </style>
</head>
<body>
    <h1 id="title">Test HTML with Errors</h1>

    <!-- Erreur: Balise non fermÃ©e -->
    <div class="test-class">Test content

    <!-- Erreur: Balise fermante ne correspond pas -->
    <div id="test-id">Test ID</p>

    <!-- Erreur: Balise fermante sans balise ouvrante -->
    </span>
</body>
</html>
"@

# CSS avec erreurs
$cssWithErrors = @"
/* Test CSS with Errors */

/* Erreur: Point-virgule manquant */
.test-class {
    color: red
    font-size: 16px;
}

/* Erreur: Accolade non fermÃ©e */
#test-id {
    font-weight: bold;
    text-decoration: underline;

body {
    font-family: Arial, sans-serif;
}

/* Erreur: Accolade fermante inattendue */
}
"@

# CrÃ©er les fichiers de test
$testFiles = @(
    (New-TestFile -Path "powershell/test_with_errors.ps1" -Content $psScriptWithErrors),
    (New-TestFile -Path "python/test_with_errors.py" -Content $pyScriptWithErrors),
    (New-TestFile -Path "javascript/test_with_errors.js" -Content $jsScriptWithErrors),
    (New-TestFile -Path "html/test_with_errors.html" -Content $htmlWithErrors),
    (New-TestFile -Path "css/test_with_errors.css" -Content $cssWithErrors)
)

Write-Host "  $($testFiles.Count) fichiers de test crÃ©Ã©s" -ForegroundColor Green
Write-Host ""

# ExÃ©cuter l'analyse prÃ©dictive
Write-Host "ExÃ©cution de l'analyse prÃ©dictive..." -ForegroundColor Cyan

# Chemin du script d'analyse prÃ©dictive
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Start-PredictiveFileAnalysis.ps1"

if (Test-Path -Path $scriptPath) {
    # ExÃ©cuter le script d'analyse prÃ©dictive
    $errorHistoryPath = Join-Path -Path $reportsDir -ChildPath "error_history.json"
    & $scriptPath -RepositoryPath $testDir -OutputPath $OutputPath -ErrorHistoryPath $errorHistoryPath -UseCache | Out-Null

    Write-Host "  Analyse terminÃ©e" -ForegroundColor Green
    Write-Host "  Rapport gÃ©nÃ©rÃ©: $OutputPath" -ForegroundColor Green

    # Ouvrir le rapport dans le navigateur par dÃ©faut
    Start-Process $OutputPath
} else {
    Write-Error "Le script d'analyse prÃ©dictive n'existe pas: $scriptPath"
}

Write-Host ""

# Nettoyer
Write-Host "Nettoyage..." -ForegroundColor Cyan
Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "  RÃ©pertoire de test supprimÃ©" -ForegroundColor Green
Write-Host ""

Write-Host "Test terminÃ©!" -ForegroundColor Green
Write-Host "Le rapport est disponible Ã  l'adresse: $OutputPath" -ForegroundColor Green
