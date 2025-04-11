#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour la fonction Detect-FileFormat.

.DESCRIPTION
    Ce script contient des tests unitaires pour vérifier le bon fonctionnement de la fonction
    Detect-FileFormat du module Format-Converters. Il utilise le framework Pester pour exécuter les tests.

.EXAMPLE
    Invoke-Pester -Path .\Detect-FileFormat.Tests.ps1
    Exécute les tests unitaires pour la fonction Detect-FileFormat.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation..."
    try {
        Install-Module -Name Pester -Force -SkipPublisherCheck
    }
    catch {
        Write-Error "Impossible d'installer le module Pester : $_"
        exit 1
    }
}

# Chemin du module à tester
$moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$modulePath = Join-Path -Path $moduleRoot -ChildPath "Format-Converters.psm1"

# Créer un répertoire temporaire pour les tests
$testTempDir = Join-Path -Path $env:TEMP -ChildPath "FormatConvertersTests_$(Get-Random)"
New-Item -Path $testTempDir -ItemType Directory -Force | Out-Null

# Fonction pour créer des fichiers de test
function New-TestFile {
    param (
        [string]$FileName,
        [string]$Content,
        [string]$Directory = $testTempDir
    )
    
    $filePath = Join-Path -Path $Directory -ChildPath $FileName
    $Content | Set-Content -Path $filePath -Encoding UTF8
    return $filePath
}

# Créer des fichiers d'exemple pour les tests
$jsonContent = @"
{
    "name": "Test",
    "version": "1.0.0",
    "description": "This is a test file"
}
"@

$xmlContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<root>
    <element>Test</element>
    <element>Example</element>
</root>
"@

$htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Test Page</title>
</head>
<body>
    <h1>Hello World</h1>
    <p>This is a test page.</p>
</body>
</html>
"@

$csvContent = @"
Name,Age,Email
John Doe,30,john.doe@example.com
Jane Smith,25,jane.smith@example.com
"@

$yamlContent = @"
---
name: Test
version: 1.0.0
description: This is a test file
dependencies:
  - name: dep1
    version: 1.0.0
  - name: dep2
    version: 2.0.0
"@

$markdownContent = @"
# Test Document

This is a test markdown document.

## Section 1

- Item 1
- Item 2
- Item 3

## Section 2

1. First item
2. Second item
3. Third item
"@

$jsContent = @"
function test() {
    console.log("Hello World");
    var x = 10;
    let y = 20;
    const z = 30;
    return x + y + z;
}
"@

$cssContent = @"
body {
    font-family: Arial, sans-serif;
    background-color: #f0f0f0;
    color: #333;
}

h1 {
    color: #0066cc;
    font-size: 24px;
}

.container {
    width: 80%;
    margin: 0 auto;
    padding: 20px;
}
"@

$ps1Content = @"
function Test-Function {
    param (
        [string]`$Name
    )
    
    Write-Host "Hello, `$Name!"
}

Test-Function -Name "World"
"@

$iniContent = @"
[General]
Name=Test Configuration
Version=1.0.0
Description=This is a test configuration file

[Settings]
Debug=true
LogLevel=INFO
MaxConnections=10
"@

$textContent = @"
This is a plain text file.
It contains multiple lines of text.
No special formatting or structure.
Just plain text.
"@

# Créer les fichiers de test
$jsonPath = New-TestFile -FileName "test.json" -Content $jsonContent
$xmlPath = New-TestFile -FileName "test.xml" -Content $xmlContent
$htmlPath = New-TestFile -FileName "test.html" -Content $htmlContent
$csvPath = New-TestFile -FileName "test.csv" -Content $csvContent
$yamlPath = New-TestFile -FileName "test.yaml" -Content $yamlContent
$mdPath = New-TestFile -FileName "test.md" -Content $markdownContent
$jsPath = New-TestFile -FileName "test.js" -Content $jsContent
$cssPath = New-TestFile -FileName "test.css" -Content $cssContent
$ps1Path = New-TestFile -FileName "test.ps1" -Content $ps1Content
$iniPath = New-TestFile -FileName "test.ini" -Content $iniContent
$textPath = New-TestFile -FileName "test.txt" -Content $textContent

# Créer des fichiers avec extension incorrecte
$jsonWithTxtExtPath = New-TestFile -FileName "json_with_txt_ext.txt" -Content $jsonContent
$xmlWithTxtExtPath = New-TestFile -FileName "xml_with_txt_ext.txt" -Content $xmlContent
$htmlWithTxtExtPath = New-TestFile -FileName "html_with_txt_ext.txt" -Content $htmlContent

# Créer des fichiers ambigus
$jsonJsAmbiguousContent = @"
{
    "function": "test",
    "code": "function test() { return 'Hello World'; }"
}
"@

$xmlHtmlAmbiguousContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<html>
    <head>
        <title>Test Page</title>
    </head>
    <body>
        <h1>Hello World</h1>
        <p>This is a test page.</p>
    </body>
</html>
"@

$jsonJsAmbiguousPath = New-TestFile -FileName "ambiguous_json_js.txt" -Content $jsonJsAmbiguousContent
$xmlHtmlAmbiguousPath = New-TestFile -FileName "ambiguous_xml_html.txt" -Content $xmlHtmlAmbiguousContent

# Tests Pester
Describe "Fonction Detect-FileFormat" {
    BeforeAll {
        # Importer le module Format-Converters
        Import-Module $modulePath -Force
    }
    
    Context "Détection de format avec extension correcte" {
        It "Détecte correctement le format JSON" {
            $result = Detect-FileFormat -FilePath $jsonPath
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "JSON"
            $result.ConfidenceScore | Should -BeGreaterThan 70
        }
        
        It "Détecte correctement le format XML" {
            $result = Detect-FileFormat -FilePath $xmlPath
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "XML"
            $result.ConfidenceScore | Should -BeGreaterThan 70
        }
        
        It "Détecte correctement le format HTML" {
            $result = Detect-FileFormat -FilePath $htmlPath
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "HTML"
            $result.ConfidenceScore | Should -BeGreaterThan 70
        }
        
        It "Détecte correctement le format CSV" {
            $result = Detect-FileFormat -FilePath $csvPath
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "CSV"
            $result.ConfidenceScore | Should -BeGreaterThan 70
        }
        
        It "Détecte correctement le format YAML" {
            $result = Detect-FileFormat -FilePath $yamlPath
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "YAML"
            $result.ConfidenceScore | Should -BeGreaterThan 70
        }
        
        It "Détecte correctement le format Markdown" {
            $result = Detect-FileFormat -FilePath $mdPath
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "MARKDOWN"
            $result.ConfidenceScore | Should -BeGreaterThan 70
        }
        
        It "Détecte correctement le format JavaScript" {
            $result = Detect-FileFormat -FilePath $jsPath
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "JAVASCRIPT"
            $result.ConfidenceScore | Should -BeGreaterThan 70
        }
        
        It "Détecte correctement le format CSS" {
            $result = Detect-FileFormat -FilePath $cssPath
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "CSS"
            $result.ConfidenceScore | Should -BeGreaterThan 70
        }
        
        It "Détecte correctement le format PowerShell" {
            $result = Detect-FileFormat -FilePath $ps1Path
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "POWERSHELL"
            $result.ConfidenceScore | Should -BeGreaterThan 70
        }
        
        It "Détecte correctement le format INI" {
            $result = Detect-FileFormat -FilePath $iniPath
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "INI"
            $result.ConfidenceScore | Should -BeGreaterThan 70
        }
        
        It "Détecte correctement le format TEXT" {
            $result = Detect-FileFormat -FilePath $textPath
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "TEXT"
            $result.ConfidenceScore | Should -BeGreaterThan 70
        }
    }
    
    Context "Détection de format avec extension incorrecte" {
        It "Détecte correctement le format JSON malgré l'extension .txt" {
            $result = Detect-FileFormat -FilePath $jsonWithTxtExtPath
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "JSON"
            $result.ConfidenceScore | Should -BeGreaterThan 50
        }
        
        It "Détecte correctement le format XML malgré l'extension .txt" {
            $result = Detect-FileFormat -FilePath $xmlWithTxtExtPath
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "XML"
            $result.ConfidenceScore | Should -BeGreaterThan 50
        }
        
        It "Détecte correctement le format HTML malgré l'extension .txt" {
            $result = Detect-FileFormat -FilePath $htmlWithTxtExtPath
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "HTML"
            $result.ConfidenceScore | Should -BeGreaterThan 50
        }
    }
    
    Context "Détection de format avec cas ambigus" {
        It "Détecte un cas ambigu entre JSON et JavaScript" {
            $result = Detect-FileFormat -FilePath $jsonJsAmbiguousPath -IncludeAllFormats
            $result | Should -Not -BeNullOrEmpty
            
            $topFormats = $result.AllFormats | Sort-Object -Property Score -Descending | Select-Object -First 2
            $scoreDifference = [Math]::Abs($topFormats[0].Score - $topFormats[1].Score)
            
            $scoreDifference | Should -BeLessThan 30
            $topFormats[0].Format | Should -BeIn @("JSON", "JAVASCRIPT")
            $topFormats[1].Format | Should -BeIn @("JSON", "JAVASCRIPT")
        }
        
        It "Détecte un cas ambigu entre XML et HTML" {
            $result = Detect-FileFormat -FilePath $xmlHtmlAmbiguousPath -IncludeAllFormats
            $result | Should -Not -BeNullOrEmpty
            
            $topFormats = $result.AllFormats | Sort-Object -Property Score -Descending | Select-Object -First 2
            $scoreDifference = [Math]::Abs($topFormats[0].Score - $topFormats[1].Score)
            
            $scoreDifference | Should -BeLessThan 30
            $topFormats[0].Format | Should -BeIn @("XML", "HTML")
            $topFormats[1].Format | Should -BeIn @("XML", "HTML")
        }
    }
    
    Context "Options de la fonction Detect-FileFormat" {
        It "L'option -IncludeAllFormats inclut tous les formats détectés" {
            $result = Detect-FileFormat -FilePath $jsonPath -IncludeAllFormats
            $result | Should -Not -BeNullOrEmpty
            $result.AllFormats | Should -Not -BeNullOrEmpty
            $result.AllFormats.Count | Should -BeGreaterThan 0
        }
        
        It "L'option -MinimumScore filtre les formats avec un score inférieur" {
            $result = Detect-FileFormat -FilePath $jsonPath -IncludeAllFormats -MinimumScore 90
            $result | Should -Not -BeNullOrEmpty
            
            if ($result.AllFormats) {
                $result.AllFormats | ForEach-Object {
                    $_.Score | Should -BeGreaterOrEqual 90
                }
            }
        }
    }
    
    Context "Gestion des erreurs" {
        It "Lève une erreur si le fichier n'existe pas" {
            { Detect-FileFormat -FilePath "fichier_inexistant.txt" } | Should -Throw
        }
        
        It "Lève une erreur si le fichier de critères n'existe pas" {
            { Detect-FileFormat -FilePath $jsonPath -CriteriaPath "criteres_inexistants.json" } | Should -Throw
        }
    }
}

# Nettoyer après les tests
AfterAll {
    # Supprimer le répertoire temporaire
    if (Test-Path -Path $testTempDir) {
        Remove-Item -Path $testTempDir -Recurse -Force
    }
    
    # Décharger le module
    Remove-Module -Name Format-Converters -ErrorAction SilentlyContinue
}
