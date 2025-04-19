#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour la détection d'encodage.
.DESCRIPTION
    Ce script contient des tests unitaires pour la fonctionnalité de détection d'encodage
    du module UnifiedSegmenter.ps1.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-06-06
#>

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Chemins des modules à tester
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$modulesPath = Join-Path -Path $projectRoot -ChildPath "modules"
$unifiedSegmenterPath = Join-Path -Path $modulesPath -ChildPath "UnifiedSegmenter.ps1"
$encodingDetectorPath = Join-Path -Path $modulesPath -ChildPath "EncodingDetector.py"

# Créer un répertoire temporaire pour les tests
$testTempDir = Join-Path -Path $env:TEMP -ChildPath "EncodingTests"
if (Test-Path -Path $testTempDir) {
    Remove-Item -Path $testTempDir -Recurse -Force
}
New-Item -Path $testTempDir -ItemType Directory -Force | Out-Null

# Créer des fichiers de test avec différents encodages
$utf8FilePath = Join-Path -Path $testTempDir -ChildPath "utf8.txt"
$utf8BomFilePath = Join-Path -Path $testTempDir -ChildPath "utf8-bom.txt"
$utf16FilePath = Join-Path -Path $testTempDir -ChildPath "utf16.txt"
$asciiFilePath = Join-Path -Path $testTempDir -ChildPath "ascii.txt"
$binaryFilePath = Join-Path -Path $testTempDir -ChildPath "binary.bin"

# Contenu de test
$testContent = "Ceci est un test avec des caractères spéciaux : éèêëàâäôöùûüÿç"

# Créer les fichiers avec différents encodages
$utf8Encoding = [System.Text.Encoding]::UTF8
$utf8BomEncoding = New-Object System.Text.UTF8Encoding $true
$utf16Encoding = [System.Text.Encoding]::Unicode
$asciiEncoding = [System.Text.Encoding]::ASCII

[System.IO.File]::WriteAllText($utf8FilePath, $testContent, $utf8Encoding)
[System.IO.File]::WriteAllText($utf8BomFilePath, $testContent, $utf8BomEncoding)
[System.IO.File]::WriteAllText($utf16FilePath, $testContent, $utf16Encoding)
[System.IO.File]::WriteAllText($asciiFilePath, $testContent, $asciiEncoding)

# Créer un fichier binaire
$binaryData = [byte[]]@(0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09)
[System.IO.File]::WriteAllBytes($binaryFilePath, $binaryData)

# Créer des fichiers de test pour différents formats
$jsonFilePath = Join-Path -Path $testTempDir -ChildPath "test.json"
$xmlFilePath = Join-Path -Path $testTempDir -ChildPath "test.xml"
$csvFilePath = Join-Path -Path $testTempDir -ChildPath "test.csv"
$yamlFilePath = Join-Path -Path $testTempDir -ChildPath "test.yaml"

# Créer un fichier JSON de test
$jsonContent = @{
    "name" = "Test Object"
    "items" = @(
        @{ "id" = 1; "value" = "Item 1" },
        @{ "id" = 2; "value" = "Item 2" },
        @{ "id" = 3; "value" = "Item 3" }
    )
} | ConvertTo-Json -Depth 10
Set-Content -Path $jsonFilePath -Value $jsonContent -Encoding UTF8

# Créer un fichier XML de test
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

# Créer un fichier CSV de test
$csvContent = @"
id,name,value
1,Item 1,Value 1
2,Item 2,Value 2
3,Item 3,Value 3
"@
Set-Content -Path $csvFilePath -Value $csvContent -Encoding UTF8

# Créer un fichier YAML de test
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

# Définir les tests
Describe "Tests de détection d'encodage" {
    BeforeAll {
        # Importer le module UnifiedSegmenter
        . $unifiedSegmenterPath
        
        # Initialiser le segmenteur unifié
        $initResult = Initialize-UnifiedSegmenter
        $initResult | Should -Be $true
    }
    
    Context "Tests de base" {
        It "Le fichier EncodingDetector.py existe" {
            Test-Path -Path $encodingDetectorPath | Should -Be $true
        }
        
        It "La fonction Get-FileEncoding est disponible" {
            Get-Command -Name Get-FileEncoding -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Tests de détection d'encodage" {
        It "Détecte correctement l'encodage UTF-8" {
            $encodingInfo = Get-FileEncoding -FilePath $utf8FilePath
            $encodingInfo | Should -Not -BeNullOrEmpty
            $encodingInfo.encoding | Should -Match "utf-8"
            $encodingInfo.has_bom | Should -Be $false
        }
        
        It "Détecte correctement l'encodage UTF-8 avec BOM" {
            $encodingInfo = Get-FileEncoding -FilePath $utf8BomFilePath
            $encodingInfo | Should -Not -BeNullOrEmpty
            $encodingInfo.encoding | Should -Match "utf-8"
            $encodingInfo.has_bom | Should -Be $true
        }
        
        It "Détecte correctement l'encodage UTF-16" {
            $encodingInfo = Get-FileEncoding -FilePath $utf16FilePath
            $encodingInfo | Should -Not -BeNullOrEmpty
            $encodingInfo.encoding | Should -Match "utf-16"
        }
        
        It "Détecte correctement l'encodage ASCII" {
            $encodingInfo = Get-FileEncoding -FilePath $asciiFilePath
            $encodingInfo | Should -Not -BeNullOrEmpty
            $encodingInfo.encoding | Should -Not -BeNullOrEmpty
        }
        
        It "Détecte correctement un fichier binaire" {
            $encodingInfo = Get-FileEncoding -FilePath $binaryFilePath
            $encodingInfo | Should -Not -BeNullOrEmpty
            $encodingInfo.file_type | Should -Be "BINARY"
        }
    }
    
    Context "Tests de détection de format" {
        It "Détecte correctement le format JSON" {
            $encodingInfo = Get-FileEncoding -FilePath $jsonFilePath
            $encodingInfo | Should -Not -BeNullOrEmpty
            $encodingInfo.file_type | Should -Be "JSON"
        }
        
        It "Détecte correctement le format XML" {
            $encodingInfo = Get-FileEncoding -FilePath $xmlFilePath
            $encodingInfo | Should -Not -BeNullOrEmpty
            $encodingInfo.file_type | Should -Be "XML"
        }
        
        It "Détecte correctement le format CSV comme TEXT" {
            $encodingInfo = Get-FileEncoding -FilePath $csvFilePath
            $encodingInfo | Should -Not -BeNullOrEmpty
            $encodingInfo.file_type | Should -Be "TEXT"
        }
        
        It "Détecte correctement le format YAML comme TEXT" {
            $encodingInfo = Get-FileEncoding -FilePath $yamlFilePath
            $encodingInfo | Should -Not -BeNullOrEmpty
            $encodingInfo.file_type | Should -Be "TEXT"
        }
    }
    
    Context "Tests d'intégration avec Get-FileFormat" {
        It "Get-FileFormat utilise correctement EncodingDetector" {
            $format = Get-FileFormat -FilePath $jsonFilePath -UseEncodingDetector
            $format | Should -Be "JSON"
            
            $format = Get-FileFormat -FilePath $xmlFilePath -UseEncodingDetector
            $format | Should -Be "XML"
            
            $format = Get-FileFormat -FilePath $binaryFilePath -UseEncodingDetector
            $format | Should -Be "TEXT"  # Les fichiers binaires sont traités comme du texte par défaut
        }
    }
    
    AfterAll {
        # Nettoyer les fichiers de test
        if (Test-Path -Path $testTempDir) {
            Remove-Item -Path $testTempDir -Recurse -Force
        }
    }
}
