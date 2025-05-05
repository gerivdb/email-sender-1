#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour les segmenteurs de formats JSON, XML et texte.
.DESCRIPTION
    Ce script contient des tests unitaires pour les modules JsonSegmenter.py,
    XmlSegmenter.py, TextSegmenter.py et UnifiedSegmenter.ps1.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-06-06
#>

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Chemins des modules Ã  tester
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$modulesPath = Join-Path -Path $projectRoot -ChildPath "modules"
$unifiedSegmenterPath = Join-Path -Path $modulesPath -ChildPath "UnifiedSegmenter.ps1"
$jsonSegmenterPath = Join-Path -Path $modulesPath -ChildPath "JsonSegmenter.py"
$xmlSegmenterPath = Join-Path -Path $modulesPath -ChildPath "XmlSegmenter.py"
$textSegmenterPath = Join-Path -Path $modulesPath -ChildPath "TextSegmenter.py"
$csvSegmenterPath = Join-Path -Path $modulesPath -ChildPath "CsvSegmenter.py"
$yamlSegmenterPath = Join-Path -Path $modulesPath -ChildPath "YamlSegmenter.py"
$encodingDetectorPath = Join-Path -Path $modulesPath -ChildPath "EncodingDetector.py"

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testTempDir = Join-Path -Path $env:TEMP -ChildPath "FormatSegmentersTests"
if (Test-Path -Path $testTempDir) {
    Remove-Item -Path $testTempDir -Recurse -Force
}
New-Item -Path $testTempDir -ItemType Directory -Force | Out-Null

# CrÃ©er des fichiers de test
$jsonFilePath = Join-Path -Path $testTempDir -ChildPath "test.json"
$xmlFilePath = Join-Path -Path $testTempDir -ChildPath "test.xml"
$textFilePath = Join-Path -Path $testTempDir -ChildPath "test.txt"
$csvFilePath = Join-Path -Path $testTempDir -ChildPath "test.csv"
$yamlFilePath = Join-Path -Path $testTempDir -ChildPath "test.yaml"
$outputDir = Join-Path -Path $testTempDir -ChildPath "output"

# CrÃ©er un fichier JSON de test
$jsonContent = @{
    "name"     = "Test Object"
    "items"    = @(
        @{ "id" = 1; "value" = "Item 1" },
        @{ "id" = 2; "value" = "Item 2" },
        @{ "id" = 3; "value" = "Item 3" }
    )
    "metadata" = @{
        "created" = "2025-06-06"
        "version" = "1.0.0"
    }
} | ConvertTo-Json -Depth 10
Set-Content -Path $jsonFilePath -Value $jsonContent -Encoding UTF8

# CrÃ©er un fichier XML de test
$xmlContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<root>
    <name>Test Object</name>
    <items>
        <item id="1">
            <value>Item 1</value>
        </item>
        <item id="2">
            <value>Item 2</value>
        </item>
        <item id="3">
            <value>Item 3</value>
        </item>
    </items>
    <metadata>
        <created>2025-06-06</created>
        <version>1.0.0</version>
    </metadata>
</root>
"@
Set-Content -Path $xmlFilePath -Value $xmlContent -Encoding UTF8

# CrÃ©er un fichier texte de test
$textContent = @"
# Test Document

This is a test document for the TextSegmenter module.

## Section 1

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.

## Section 2

Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
"@
Set-Content -Path $textFilePath -Value $textContent -Encoding UTF8

# CrÃ©er un fichier CSV de test
$csvContent = @"
id,name,value
1,Item 1,Value 1
2,Item 2,Value 2
3,Item 3,Value 3
"@
Set-Content -Path $csvFilePath -Value $csvContent -Encoding UTF8

# CrÃ©er un fichier YAML de test
$yamlContent = @"
name: Test Object
items:
  - id: 1
    value: Item 1
  - id: 2
    value: Item 2
  - id: 3
    value: Item 3
metadata:
  created: 2025-06-06
  version: 1.0.0
"@
Set-Content -Path $yamlFilePath -Value $yamlContent -Encoding UTF8

# DÃ©finir les tests
Describe "Tests des segmenteurs de formats" {
    BeforeAll {
        # Importer le module UnifiedSegmenter
        . $unifiedSegmenterPath

        # Initialiser le segmenteur unifiÃ©
        $initResult = Initialize-UnifiedSegmenter -MaxInputSizeKB 10 -DefaultChunkSizeKB 5
    }

    Context "Tests du module UnifiedSegmenter" {
        It "Initialise correctement le segmenteur unifiÃ©" {
            $initResult | Should -Be $true
        }

        It "DÃ©tecte correctement le format JSON" {
            $format = Get-FileFormat -FilePath $jsonFilePath
            $format | Should -Be "JSON"
        }

        It "DÃ©tecte correctement le format XML" {
            $format = Get-FileFormat -FilePath $xmlFilePath
            $format | Should -Be "XML"
        }

        It "DÃ©tecte correctement le format texte" {
            $format = Get-FileFormat -FilePath $textFilePath
            $format | Should -Be "TEXT"
        }

        It "DÃ©tecte correctement le format CSV" {
            $format = Get-FileFormat -FilePath $csvFilePath
            $format | Should -Be "CSV"
        }

        It "DÃ©tecte correctement le format YAML" {
            $format = Get-FileFormat -FilePath $yamlFilePath
            $format | Should -Be "YAML"
        }

        It "DÃ©tecte correctement l'encodage d'un fichier" {
            $encodingInfo = Get-FileEncoding -FilePath $jsonFilePath
            $encodingInfo | Should -Not -BeNullOrEmpty
            $encodingInfo.encoding | Should -Not -BeNullOrEmpty
        }

        It "Valide correctement un fichier JSON" {
            $isValid = Test-FileValidity -FilePath $jsonFilePath -Format "JSON"
            $isValid | Should -Be $true
        }

        It "Valide correctement un fichier XML" {
            $isValid = Test-FileValidity -FilePath $xmlFilePath -Format "XML"
            $isValid | Should -Be $true
        }

        It "Valide correctement un fichier CSV" {
            $isValid = Test-FileValidity -FilePath $csvFilePath -Format "CSV"
            $isValid | Should -Be $true
        }

        It "Valide correctement un fichier YAML" {
            $isValid = Test-FileValidity -FilePath $yamlFilePath -Format "YAML"
            $isValid | Should -Be $true
        }
    }

    Context "Tests du module JsonSegmenter" {
        It "Le fichier JsonSegmenter.py existe" {
            Test-Path -Path $jsonSegmenterPath | Should -Be $true
        }

        It "Peut analyser un fichier JSON" {
            $outputFile = Join-Path -Path $testTempDir -ChildPath "json_analysis.json"
            $result = Get-FileAnalysis -FilePath $jsonFilePath -Format "JSON" -OutputFile $outputFile
            Test-Path -Path $outputFile | Should -Be $true
        }

        It "Peut segmenter un fichier JSON" {
            $jsonOutputDir = Join-Path -Path $outputDir -ChildPath "json"
            $result = Split-File -FilePath $jsonFilePath -Format "JSON" -OutputDir $jsonOutputDir -ChunkSizeKB 1
            $result | Should -Not -BeNullOrEmpty

            # VÃ©rifier que les fichiers ont Ã©tÃ© crÃ©Ã©s
            $segmentFiles = Get-ChildItem -Path $jsonOutputDir -Filter "*.json"
            $segmentFiles.Count | Should -BeGreaterThan 0
        }
    }

    Context "Tests du module XmlSegmenter" {
        It "Le fichier XmlSegmenter.py existe" {
            Test-Path -Path $xmlSegmenterPath | Should -Be $true
        }

        It "Peut analyser un fichier XML" {
            $outputFile = Join-Path -Path $testTempDir -ChildPath "xml_analysis.json"
            $result = Get-FileAnalysis -FilePath $xmlFilePath -Format "XML" -OutputFile $outputFile
            Test-Path -Path $outputFile | Should -Be $true
        }

        It "Peut segmenter un fichier XML" {
            $xmlOutputDir = Join-Path -Path $outputDir -ChildPath "xml"
            $result = Split-File -FilePath $xmlFilePath -Format "XML" -OutputDir $xmlOutputDir -ChunkSizeKB 1
            $result | Should -Not -BeNullOrEmpty

            # VÃ©rifier que les fichiers ont Ã©tÃ© crÃ©Ã©s
            $segmentFiles = Get-ChildItem -Path $xmlOutputDir -Filter "*.xml"
            $segmentFiles.Count | Should -BeGreaterThan 0
        }

        It "Peut exÃ©cuter une requÃªte XPath" {
            $result = Invoke-XPathQuery -FilePath $xmlFilePath -XPathExpression "//item[@id='2']/value"
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Contain "--- Ã‰lÃ©ment 1 ---"
        }
    }

    Context "Tests du module TextSegmenter" {
        It "Le fichier TextSegmenter.py existe" {
            Test-Path -Path $textSegmenterPath | Should -Be $true
        }

        It "Peut analyser un fichier texte" {
            $outputFile = Join-Path -Path $testTempDir -ChildPath "text_analysis.json"
            $result = Get-FileAnalysis -FilePath $textFilePath -Format "TEXT" -OutputFile $outputFile
            Test-Path -Path $outputFile | Should -Be $true
        }

        It "Peut segmenter un fichier texte" {
            $textOutputDir = Join-Path -Path $outputDir -ChildPath "text"
            $result = Split-File -FilePath $textFilePath -Format "TEXT" -OutputDir $textOutputDir -ChunkSizeKB 1
            $result | Should -Not -BeNullOrEmpty

            # VÃ©rifier que les fichiers ont Ã©tÃ© crÃ©Ã©s
            $segmentFiles = Get-ChildItem -Path $textOutputDir -Filter "*.txt"
            $segmentFiles.Count | Should -BeGreaterThan 0
        }

        It "Peut segmenter un fichier texte par paragraphes" {
            $textOutputDir = Join-Path -Path $outputDir -ChildPath "text_paragraphs"
            $result = Split-File -FilePath $textFilePath -Format "TEXT" -OutputDir $textOutputDir -TextMethod "paragraph"
            $result | Should -Not -BeNullOrEmpty

            # VÃ©rifier que les fichiers ont Ã©tÃ© crÃ©Ã©s
            $segmentFiles = Get-ChildItem -Path $textOutputDir -Filter "*.txt"
            $segmentFiles.Count | Should -BeGreaterThan 0
        }
    }

    Context "Tests du module CsvSegmenter" {
        It "Le fichier CsvSegmenter.py existe" {
            Test-Path -Path $csvSegmenterPath | Should -Be $true
        }

        It "Peut analyser un fichier CSV" {
            $outputFile = Join-Path -Path $testTempDir -ChildPath "csv_analysis.json"
            $result = Get-FileAnalysis -FilePath $csvFilePath -Format "CSV" -OutputFile $outputFile
            Test-Path -Path $outputFile | Should -Be $true
        }

        It "Peut segmenter un fichier CSV" {
            $csvOutputDir = Join-Path -Path $outputDir -ChildPath "csv"
            $result = Split-File -FilePath $csvFilePath -Format "CSV" -OutputDir $csvOutputDir -ChunkSizeKB 1
            $result | Should -Not -BeNullOrEmpty

            # VÃ©rifier que les fichiers ont Ã©tÃ© crÃ©Ã©s
            $segmentFiles = Get-ChildItem -Path $csvOutputDir -Filter "*.csv"
            $segmentFiles.Count | Should -BeGreaterThan 0
        }
    }

    Context "Tests du module YamlSegmenter" {
        It "Le fichier YamlSegmenter.py existe" {
            Test-Path -Path $yamlSegmenterPath | Should -Be $true
        }

        It "Peut analyser un fichier YAML" {
            $outputFile = Join-Path -Path $testTempDir -ChildPath "yaml_analysis.json"
            $result = Get-FileAnalysis -FilePath $yamlFilePath -Format "YAML" -OutputFile $outputFile
            Test-Path -Path $outputFile | Should -Be $true
        }

        It "Peut segmenter un fichier YAML" {
            $yamlOutputDir = Join-Path -Path $outputDir -ChildPath "yaml"
            $result = Split-File -FilePath $yamlFilePath -Format "YAML" -OutputDir $yamlOutputDir -ChunkSizeKB 1
            $result | Should -Not -BeNullOrEmpty

            # VÃ©rifier que les fichiers ont Ã©tÃ© crÃ©Ã©s
            $segmentFiles = Get-ChildItem -Path $yamlOutputDir -Filter "*.yaml"
            $segmentFiles.Count | Should -BeGreaterThan 0
        }
    }

    Context "Tests de conversion entre formats" {
        It "Peut convertir de JSON Ã  XML" {
            $outputFile = Join-Path -Path $testTempDir -ChildPath "json_to_xml.xml"
            $result = Convert-FileFormat -InputFile $jsonFilePath -OutputFile $outputFile -InputFormat "JSON" -OutputFormat "XML"
            $result | Should -Be $true
            Test-Path -Path $outputFile | Should -Be $true

            # VÃ©rifier que le fichier est un XML valide
            $isValid = Test-FileValidity -FilePath $outputFile -Format "XML"
            $isValid | Should -Be $true
        }

        It "Peut convertir de XML Ã  JSON" {
            $outputFile = Join-Path -Path $testTempDir -ChildPath "xml_to_json.json"
            $result = Convert-FileFormat -InputFile $xmlFilePath -OutputFile $outputFile -InputFormat "XML" -OutputFormat "JSON"
            $result | Should -Be $true
            Test-Path -Path $outputFile | Should -Be $true

            # VÃ©rifier que le fichier est un JSON valide
            $isValid = Test-FileValidity -FilePath $outputFile -Format "JSON"
            $isValid | Should -Be $true
        }

        It "Peut convertir de JSON Ã  texte" {
            $outputFile = Join-Path -Path $testTempDir -ChildPath "json_to_text.txt"
            $result = Convert-FileFormat -InputFile $jsonFilePath -OutputFile $outputFile -InputFormat "JSON" -OutputFormat "TEXT"
            $result | Should -Be $true
            Test-Path -Path $outputFile | Should -Be $true
        }

        It "Peut convertir de XML Ã  texte" {
            $outputFile = Join-Path -Path $testTempDir -ChildPath "xml_to_text.txt"
            $result = Convert-FileFormat -InputFile $xmlFilePath -OutputFile $outputFile -InputFormat "XML" -OutputFormat "TEXT"
            $result | Should -Be $true
            Test-Path -Path $outputFile | Should -Be $true
        }

        It "Peut convertir de JSON Ã  CSV" {
            $outputFile = Join-Path -Path $testTempDir -ChildPath "json_to_csv.csv"
            $result = Convert-FileFormat -InputFile $jsonFilePath -OutputFile $outputFile -InputFormat "JSON" -OutputFormat "CSV"
            $result | Should -Be $true
            Test-Path -Path $outputFile | Should -Be $true
        }

        It "Peut convertir de JSON Ã  YAML" {
            $outputFile = Join-Path -Path $testTempDir -ChildPath "json_to_yaml.yaml"
            $result = Convert-FileFormat -InputFile $jsonFilePath -OutputFile $outputFile -InputFormat "JSON" -OutputFormat "YAML"
            $result | Should -Be $true
            Test-Path -Path $outputFile | Should -Be $true
        }

        It "Peut convertir de CSV Ã  JSON" {
            $outputFile = Join-Path -Path $testTempDir -ChildPath "csv_to_json.json"
            $result = Convert-FileFormat -InputFile $csvFilePath -OutputFile $outputFile -InputFormat "CSV" -OutputFormat "JSON"
            $result | Should -Be $true
            Test-Path -Path $outputFile | Should -Be $true

            # VÃ©rifier que le fichier est un JSON valide
            $isValid = Test-FileValidity -FilePath $outputFile -Format "JSON"
            $isValid | Should -Be $true
        }

        It "Peut convertir de YAML Ã  JSON" {
            $outputFile = Join-Path -Path $testTempDir -ChildPath "yaml_to_json.json"
            $result = Convert-FileFormat -InputFile $yamlFilePath -OutputFile $outputFile -InputFormat "YAML" -OutputFormat "JSON"
            $result | Should -Be $true
            Test-Path -Path $outputFile | Should -Be $true

            # VÃ©rifier que le fichier est un JSON valide
            $isValid = Test-FileValidity -FilePath $outputFile -Format "JSON"
            $isValid | Should -Be $true
        }
    }

    AfterAll {
        # Nettoyer les fichiers de test
        if (Test-Path -Path $testTempDir) {
            Remove-Item -Path $testTempDir -Recurse -Force
        }
    }
}
