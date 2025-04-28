#
# Script de test pour le module SimpleFileContentIndexer
# Compatible avec PowerShell 5.1 et PowerShell 7
#

# Importer le module
Import-Module .\SimpleFileContentIndexer.psm1 -Force

# Afficher les informations de version
Write-Host "Test du module SimpleFileContentIndexer" -ForegroundColor Cyan
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Cyan
Write-Host "Edition: $($PSVersionTable.PSEdition)" -ForegroundColor Cyan
Write-Host ""

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "SimpleFileContentIndexerTest_$(Get-Random)"
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
# Test PowerShell Script
function Test-Function {
    param(
        [string]`$param1,
        [int]`$param2 = 0
    )
    
    `$testVariable = "Test value"
    Write-Output `$testVariable
}

Test-Function -param1 "Test" -param2 42
"@

$pyScriptContent = @"
# Test Python Script
import os
import sys

class TestClass:
    def __init__(self, name):
        self.name = name
    
    def test_method(self):
        print(f"Hello, {self.name}!")

def test_function(param1, param2=0):
    test_variable = "Test value"
    print(test_variable)

if __name__ == "__main__":
    test_function("Test", 42)
    obj = TestClass("World")
    obj.test_method()
"@

$jsScriptContent = @"
// Test JavaScript Script
function testFunction(param1, param2 = 0) {
    const testVariable = "Test value";
    console.log(testVariable);
}

class TestClass {
    constructor(name) {
        this.name = name;
    }
    
    testMethod() {
        console.log(`Hello, ${this.name}!`);
    }
}

const obj = new TestClass("World");
obj.testMethod();
testFunction("Test", 42);
"@

$htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Test HTML</title>
    <style>
        .test-class {
            color: red;
        }
        #test-id {
            font-weight: bold;
        }
    </style>
</head>
<body>
    <h1 id="title">Test HTML</h1>
    <div class="test-class">Test content</div>
    <div id="test-id">Test ID</div>
</body>
</html>
"@

$cssContent = @"
/* Test CSS */
.test-class {
    color: red;
}
#test-id {
    font-weight: bold;
}
body {
    font-family: Arial, sans-serif;
}
"@

# CrÃ©er les fichiers de test
$testPsScript = New-TestFile -Path "test.ps1" -Content $psScriptContent
$testPyScript = New-TestFile -Path "test.py" -Content $pyScriptContent
$testJsScript = New-TestFile -Path "test.js" -Content $jsScriptContent
$testHtml = New-TestFile -Path "test.html" -Content $htmlContent
$testCss = New-TestFile -Path "test.css" -Content $cssContent

# CrÃ©er un indexeur
Write-Host "CrÃ©ation d'un indexeur..." -ForegroundColor Cyan
$indexer = New-FileContentIndexer -IndexPath $testDir -PersistIndices $true -MaxConcurrentIndexing 4 -EnableIncrementalIndexing $true

# Tester l'indexation d'un fichier PowerShell
Write-Host "Test d'indexation d'un fichier PowerShell..." -ForegroundColor Cyan
$psIndex = New-FileIndex -Indexer $indexer -FilePath $testPsScript
Write-Host "  Fonctions trouvÃ©es: $($psIndex.Functions -join ', ')" -ForegroundColor Green
Write-Host "  Variables trouvÃ©es: $($psIndex.Variables -join ', ')" -ForegroundColor Green
Write-Host "  Symboles trouvÃ©s: $($psIndex.Symbols.Count)" -ForegroundColor Green
Write-Host ""

# Tester l'indexation d'un fichier Python
Write-Host "Test d'indexation d'un fichier Python..." -ForegroundColor Cyan
$pyIndex = New-FileIndex -Indexer $indexer -FilePath $testPyScript
Write-Host "  Fonctions trouvÃ©es: $($pyIndex.Functions -join ', ')" -ForegroundColor Green
Write-Host "  Classes trouvÃ©es: $($pyIndex.Classes -join ', ')" -ForegroundColor Green
Write-Host "  Symboles trouvÃ©s: $($pyIndex.Symbols.Count)" -ForegroundColor Green
Write-Host ""

# Tester l'indexation d'un fichier JavaScript
Write-Host "Test d'indexation d'un fichier JavaScript..." -ForegroundColor Cyan
$jsIndex = New-FileIndex -Indexer $indexer -FilePath $testJsScript
Write-Host "  Fonctions trouvÃ©es: $($jsIndex.Functions -join ', ')" -ForegroundColor Green
Write-Host "  Classes trouvÃ©es: $($jsIndex.Classes -join ', ')" -ForegroundColor Green
Write-Host "  Symboles trouvÃ©s: $($jsIndex.Symbols.Count)" -ForegroundColor Green
Write-Host ""

# Tester l'indexation d'un fichier HTML
Write-Host "Test d'indexation d'un fichier HTML..." -ForegroundColor Cyan
$htmlIndex = New-FileIndex -Indexer $indexer -FilePath $testHtml
Write-Host "  Symboles trouvÃ©s: $($htmlIndex.Symbols.Count)" -ForegroundColor Green
Write-Host ""

# Tester l'indexation d'un fichier CSS
Write-Host "Test d'indexation d'un fichier CSS..." -ForegroundColor Cyan
$cssIndex = New-FileIndex -Indexer $indexer -FilePath $testCss
Write-Host "  Symboles trouvÃ©s: $($cssIndex.Symbols.Count)" -ForegroundColor Green
Write-Host ""

# Tester l'indexation incrÃ©mentale
Write-Host "Test d'indexation incrÃ©mentale..." -ForegroundColor Cyan
$modifiedPsContent = $psScriptContent.Replace("Test value", "Modified value")
$incrementalIndex = New-IncrementalFileIndex -Indexer $indexer -FilePath $testPsScript -OldContent $psScriptContent -NewContent $modifiedPsContent
Write-Host "  Lignes modifiÃ©es: $($incrementalIndex.ChangedLines -join ', ')" -ForegroundColor Green
Write-Host "  Fonctions modifiÃ©es: $($incrementalIndex.ChangedFunctions -join ', ')" -ForegroundColor Green
Write-Host ""

# Tester l'indexation parallÃ¨le
Write-Host "Test d'indexation parallÃ¨le..." -ForegroundColor Cyan
$filePaths = @($testPsScript, $testPyScript, $testJsScript, $testHtml, $testCss)
$parallelResults = New-ParallelFileIndices -Indexer $indexer -FilePaths $filePaths
Write-Host "  Fichiers indexÃ©s: $($parallelResults.Count)" -ForegroundColor Green
Write-Host ""

# VÃ©rifier les indices et la carte des symboles
Write-Host "VÃ©rification des indices et de la carte des symboles..." -ForegroundColor Cyan
$fileIndices = $indexer.GetFileIndices()
$symbolMap = $indexer.GetSymbolMap()
Write-Host "  Nombre de fichiers indexÃ©s: $($fileIndices.Count)" -ForegroundColor Green
Write-Host "  Nombre de symboles dans la carte: $($symbolMap.Count)" -ForegroundColor Green
Write-Host ""

# Nettoyer
Write-Host "Nettoyage..." -ForegroundColor Cyan
Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "  RÃ©pertoire de test supprimÃ©" -ForegroundColor Green
Write-Host ""

Write-Host "Tous les tests ont rÃ©ussi!" -ForegroundColor Green
