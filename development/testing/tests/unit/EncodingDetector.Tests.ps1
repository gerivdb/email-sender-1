#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module EncodingDetector.
.DESCRIPTION
    Ce script contient des tests unitaires pour le module EncodingDetector.py.
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
$encodingDetectorPath = Join-Path -Path $modulesPath -ChildPath "EncodingDetector.py"
$unifiedSegmenterPath = Join-Path -Path $modulesPath -ChildPath "UnifiedSegmenter.ps1"

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testTempDir = Join-Path -Path $env:TEMP -ChildPath "EncodingDetectorTests"
if (Test-Path -Path $testTempDir) {
    Remove-Item -Path $testTempDir -Recurse -Force
}
New-Item -Path $testTempDir -ItemType Directory -Force | Out-Null

# CrÃ©er des fichiers de test avec diffÃ©rents encodages
$utf8FilePath = Join-Path -Path $testTempDir -ChildPath "utf8.txt"
$utf8BomFilePath = Join-Path -Path $testTempDir -ChildPath "utf8-bom.txt"
$utf16FilePath = Join-Path -Path $testTempDir -ChildPath "utf16.txt"
$asciiFilePath = Join-Path -Path $testTempDir -ChildPath "ascii.txt"

# Contenu de test
$testContent = "Ceci est un test avec des caractÃ¨res spÃ©ciaux : Ã©Ã¨ÃªÃ«Ã Ã¢Ã¤Ã´Ã¶Ã¹Ã»Ã¼Ã¿Ã§"

# CrÃ©er les fichiers avec diffÃ©rents encodages
$utf8Encoding = [System.Text.Encoding]::UTF8
$utf8BomEncoding = New-Object System.Text.UTF8Encoding $true
$utf16Encoding = [System.Text.Encoding]::Unicode
$asciiEncoding = [System.Text.Encoding]::ASCII

[System.IO.File]::WriteAllText($utf8FilePath, $testContent, $utf8Encoding)
[System.IO.File]::WriteAllText($utf8BomFilePath, $testContent, $utf8BomEncoding)
[System.IO.File]::WriteAllText($utf16FilePath, $testContent, $utf16Encoding)
[System.IO.File]::WriteAllText($asciiFilePath, $testContent, $asciiEncoding)

# CrÃ©er des fichiers de test pour diffÃ©rents formats
$jsonFilePath = Join-Path -Path $testTempDir -ChildPath "test.json"
$xmlFilePath = Join-Path -Path $testTempDir -ChildPath "test.xml"
$csvFilePath = Join-Path -Path $testTempDir -ChildPath "test.csv"
$yamlFilePath = Join-Path -Path $testTempDir -ChildPath "test.yaml"
$binaryFilePath = Join-Path -Path $testTempDir -ChildPath "test.bin"

# CrÃ©er un fichier JSON de test
$jsonContent = @{
    "name" = "Test Object"
    "items" = @(
        @{ "id" = 1; "value" = "Item 1" },
        @{ "id" = 2; "value" = "Item 2" },
        @{ "id" = 3; "value" = "Item 3" }
    )
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
</root>
"@
Set-Content -Path $xmlFilePath -Value $xmlContent -Encoding UTF8

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
"@
Set-Content -Path $yamlFilePath -Value $yamlContent -Encoding UTF8

# CrÃ©er un fichier binaire de test
$binaryData = [byte[]]@(0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09)
[System.IO.File]::WriteAllBytes($binaryFilePath, $binaryData)

# DÃ©finir les tests
Describe "Tests du module EncodingDetector" {
    BeforeAll {
        # Importer le module UnifiedSegmenter
        . $unifiedSegmenterPath
        
        # Initialiser le segmenteur unifiÃ©
        $initResult = Initialize-UnifiedSegmenter
    }
    
    Context "Tests de base" {
        It "Le fichier EncodingDetector.py existe" {
            Test-Path -Path $encodingDetectorPath | Should -Be $true
        }
        
        It "La fonction Get-FileEncoding est disponible" {
            Get-Command -Name Get-FileEncoding -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Tests de dÃ©tection d'encodage" {
        It "DÃ©tecte correctement l'encodage UTF-8" {
            $encodingInfo = Get-FileEncoding -FilePath $utf8FilePath
            $encodingInfo | Should -Not -BeNullOrEmpty
            $encodingInfo.encoding | Should -Match "utf-8"
            $encodingInfo.has_bom | Should -Be $false
        }
        
        It "DÃ©tecte correctement l'encodage UTF-8 avec BOM" {
            $encodingInfo = Get-FileEncoding -FilePath $utf8BomFilePath
            $encodingInfo | Should -Not -BeNullOrEmpty
            $encodingInfo.encoding | Should -Match "utf-8"
            $encodingInfo.has_bom | Should -Be $true
        }
        
        It "DÃ©tecte correctement l'encodage UTF-16" {
            $encodingInfo = Get-FileEncoding -FilePath $utf16FilePath
            $encodingInfo | Should -Not -BeNullOrEmpty
            $encodingInfo.encoding | Should -Match "utf-16"
        }
        
        It "DÃ©tecte correctement l'encodage ASCII" {
            $encodingInfo = Get-FileEncoding -FilePath $asciiFilePath
            $encodingInfo | Should -Not -BeNullOrEmpty
            $encodingInfo.encoding | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Tests de dÃ©tection de format" {
        It "DÃ©tecte correctement le format JSON" {
            $encodingInfo = Get-FileEncoding -FilePath $jsonFilePath
            $encodingInfo | Should -Not -BeNullOrEmpty
            $encodingInfo.file_type | Should -Be "JSON"
        }
        
        It "DÃ©tecte correctement le format XML" {
            $encodingInfo = Get-FileEncoding -FilePath $xmlFilePath
            $encodingInfo | Should -Not -BeNullOrEmpty
            $encodingInfo.file_type | Should -Be "XML"
        }
        
        It "DÃ©tecte correctement le format CSV comme TEXT" {
            $encodingInfo = Get-FileEncoding -FilePath $csvFilePath
            $encodingInfo | Should -Not -BeNullOrEmpty
            $encodingInfo.file_type | Should -Be "TEXT"
        }
        
        It "DÃ©tecte correctement le format YAML comme TEXT" {
            $encodingInfo = Get-FileEncoding -FilePath $yamlFilePath
            $encodingInfo | Should -Not -BeNullOrEmpty
            $encodingInfo.file_type | Should -Be "TEXT"
        }
        
        It "DÃ©tecte correctement le format binaire" {
            $encodingInfo = Get-FileEncoding -FilePath $binaryFilePath
            $encodingInfo | Should -Not -BeNullOrEmpty
            $encodingInfo.file_type | Should -Be "BINARY"
        }
    }
    
    Context "Tests d'intÃ©gration avec Get-FileFormat" {
        It "Get-FileFormat utilise correctement EncodingDetector" {
            $format = Get-FileFormat -FilePath $jsonFilePath -UseEncodingDetector
            $format | Should -Be "JSON"
            
            $format = Get-FileFormat -FilePath $xmlFilePath -UseEncodingDetector
            $format | Should -Be "XML"
            
            $format = Get-FileFormat -FilePath $binaryFilePath -UseEncodingDetector
            $format | Should -Be "TEXT"  # Les fichiers binaires sont traitÃ©s comme du texte par dÃ©faut
        }
    }
    
    AfterAll {
        # Nettoyer les fichiers de test
        if (Test-Path -Path $testTempDir) {
            Remove-Item -Path $testTempDir -Recurse -Force
        }
    }
}
