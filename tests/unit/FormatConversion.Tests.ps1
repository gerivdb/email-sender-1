#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour les conversions entre formats.
.DESCRIPTION
    Ce script contient des tests unitaires pour les fonctionnalités de conversion
    entre formats du module UnifiedSegmenter.ps1.
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

# Créer un répertoire temporaire pour les tests
$testTempDir = Join-Path -Path $env:TEMP -ChildPath "FormatConversionTests"
if (Test-Path -Path $testTempDir) {
    Remove-Item -Path $testTempDir -Recurse -Force
}
New-Item -Path $testTempDir -ItemType Directory -Force | Out-Null

# Créer des fichiers de test
$jsonFilePath = Join-Path -Path $testTempDir -ChildPath "test.json"
$xmlFilePath = Join-Path -Path $testTempDir -ChildPath "test.xml"
$csvFilePath = Join-Path -Path $testTempDir -ChildPath "test.csv"
$yamlFilePath = Join-Path -Path $testTempDir -ChildPath "test.yaml"
$textFilePath = Join-Path -Path $testTempDir -ChildPath "test.txt"
$outputDir = Join-Path -Path $testTempDir -ChildPath "output"
New-Item -Path $outputDir -ItemType Directory -Force | Out-Null

# Créer un fichier JSON de test (objet)
$jsonContent = @{
    "name" = "Test Object"
    "items" = @(
        @{ "id" = 1; "value" = "Item 1" },
        @{ "id" = 2; "value" = "Item 2" },
        @{ "id" = 3; "value" = "Item 3" }
    )
} | ConvertTo-Json -Depth 10
Set-Content -Path $jsonFilePath -Value $jsonContent -Encoding UTF8

# Créer un fichier JSON de test (tableau)
$jsonArrayPath = Join-Path -Path $testTempDir -ChildPath "array.json"
$jsonArrayContent = @(
    @{ "id" = 1; "name" = "Item 1"; "value" = "Value 1" },
    @{ "id" = 2; "name" = "Item 2"; "value" = "Value 2" },
    @{ "id" = 3; "name" = "Item 3"; "value" = "Value 3" }
) | ConvertTo-Json -Depth 10
Set-Content -Path $jsonArrayPath -Value $jsonArrayContent -Encoding UTF8

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

# Créer un fichier texte de test
$textContent = @"
Ceci est un fichier texte de test.
Il contient plusieurs lignes.
Ligne 1
Ligne 2
Ligne 3
"@
Set-Content -Path $textFilePath -Value $textContent -Encoding UTF8

# Définir les tests
Describe "Tests de conversion entre formats" {
    BeforeAll {
        # Importer le module UnifiedSegmenter
        . $unifiedSegmenterPath
        
        # Initialiser le segmenteur unifié
        $initResult = Initialize-UnifiedSegmenter
        $initResult | Should -Be $true
    }
    
    Context "Conversions depuis JSON" {
        It "Convertit correctement JSON vers XML" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "json_to_xml.xml"
            $result = Convert-FileFormat -InputFile $jsonFilePath -OutputFile $outputPath -InputFormat "JSON" -OutputFormat "XML"
            $result | Should -Be $true
            Test-Path -Path $outputPath | Should -Be $true
            
            # Vérifier que le fichier XML est valide
            $isValid = Test-FileValidity -FilePath $outputPath -Format "XML"
            $isValid | Should -Be $true
        }
        
        It "Convertit correctement JSON vers TEXT" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "json_to_text.txt"
            $result = Convert-FileFormat -InputFile $jsonFilePath -OutputFile $outputPath -InputFormat "JSON" -OutputFormat "TEXT"
            $result | Should -Be $true
            Test-Path -Path $outputPath | Should -Be $true
        }
        
        It "Convertit correctement JSON (tableau) vers CSV" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "jsonarray_to_csv.csv"
            $result = Convert-FileFormat -InputFile $jsonArrayPath -OutputFile $outputPath -InputFormat "JSON" -OutputFormat "CSV"
            $result | Should -Be $true
            Test-Path -Path $outputPath | Should -Be $true
            
            # Vérifier que le fichier CSV est valide
            $isValid = Test-FileValidity -FilePath $outputPath -Format "CSV"
            $isValid | Should -Be $true
        }
        
        It "Convertit correctement JSON vers YAML" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "json_to_yaml.yaml"
            $result = Convert-FileFormat -InputFile $jsonFilePath -OutputFile $outputPath -InputFormat "JSON" -OutputFormat "YAML"
            $result | Should -Be $true
            Test-Path -Path $outputPath | Should -Be $true
            
            # Vérifier que le fichier YAML est valide
            $isValid = Test-FileValidity -FilePath $outputPath -Format "YAML"
            $isValid | Should -Be $true
        }
    }
    
    Context "Conversions depuis XML" {
        It "Convertit correctement XML vers JSON" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "xml_to_json.json"
            $result = Convert-FileFormat -InputFile $xmlFilePath -OutputFile $outputPath -InputFormat "XML" -OutputFormat "JSON"
            $result | Should -Be $true
            Test-Path -Path $outputPath | Should -Be $true
            
            # Vérifier que le fichier JSON est valide
            $isValid = Test-FileValidity -FilePath $outputPath -Format "JSON"
            $isValid | Should -Be $true
        }
        
        It "Convertit correctement XML vers TEXT" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "xml_to_text.txt"
            $result = Convert-FileFormat -InputFile $xmlFilePath -OutputFile $outputPath -InputFormat "XML" -OutputFormat "TEXT"
            $result | Should -Be $true
            Test-Path -Path $outputPath | Should -Be $true
        }
        
        It "Convertit correctement XML vers CSV" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "xml_to_csv.csv"
            $result = Convert-FileFormat -InputFile $xmlFilePath -OutputFile $outputPath -InputFormat "XML" -OutputFormat "CSV"
            $result | Should -Be $true
            Test-Path -Path $outputPath | Should -Be $true
        }
        
        It "Convertit correctement XML vers YAML" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "xml_to_yaml.yaml"
            $result = Convert-FileFormat -InputFile $xmlFilePath -OutputFile $outputPath -InputFormat "XML" -OutputFormat "YAML"
            $result | Should -Be $true
            Test-Path -Path $outputPath | Should -Be $true
            
            # Vérifier que le fichier YAML est valide
            $isValid = Test-FileValidity -FilePath $outputPath -Format "YAML"
            $isValid | Should -Be $true
        }
    }
    
    Context "Conversions depuis CSV" {
        It "Convertit correctement CSV vers JSON" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "csv_to_json.json"
            $result = Convert-FileFormat -InputFile $csvFilePath -OutputFile $outputPath -InputFormat "CSV" -OutputFormat "JSON"
            $result | Should -Be $true
            Test-Path -Path $outputPath | Should -Be $true
            
            # Vérifier que le fichier JSON est valide
            $isValid = Test-FileValidity -FilePath $outputPath -Format "JSON"
            $isValid | Should -Be $true
            
            # Vérifier le contenu
            $content = Get-Content -Path $outputPath -Raw | ConvertFrom-Json
            $content | Should -Not -BeNullOrEmpty
            $content.Count | Should -Be 3
            $content[0].id | Should -Be "1"
        }
        
        It "Convertit correctement CSV vers XML" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "csv_to_xml.xml"
            $result = Convert-FileFormat -InputFile $csvFilePath -OutputFile $outputPath -InputFormat "CSV" -OutputFormat "XML"
            $result | Should -Be $true
            Test-Path -Path $outputPath | Should -Be $true
            
            # Vérifier que le fichier XML est valide
            $isValid = Test-FileValidity -FilePath $outputPath -Format "XML"
            $isValid | Should -Be $true
        }
        
        It "Convertit correctement CSV vers TEXT" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "csv_to_text.txt"
            $result = Convert-FileFormat -InputFile $csvFilePath -OutputFile $outputPath -InputFormat "CSV" -OutputFormat "TEXT"
            $result | Should -Be $true
            Test-Path -Path $outputPath | Should -Be $true
        }
        
        It "Convertit correctement CSV vers YAML" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "csv_to_yaml.yaml"
            $result = Convert-FileFormat -InputFile $csvFilePath -OutputFile $outputPath -InputFormat "CSV" -OutputFormat "YAML"
            $result | Should -Be $true
            Test-Path -Path $outputPath | Should -Be $true
            
            # Vérifier que le fichier YAML est valide
            $isValid = Test-FileValidity -FilePath $outputPath -Format "YAML"
            $isValid | Should -Be $true
        }
    }
    
    Context "Conversions depuis YAML" {
        It "Convertit correctement YAML vers JSON" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "yaml_to_json.json"
            $result = Convert-FileFormat -InputFile $yamlFilePath -OutputFile $outputPath -InputFormat "YAML" -OutputFormat "JSON"
            $result | Should -Be $true
            Test-Path -Path $outputPath | Should -Be $true
            
            # Vérifier que le fichier JSON est valide
            $isValid = Test-FileValidity -FilePath $outputPath -Format "JSON"
            $isValid | Should -Be $true
        }
        
        It "Convertit correctement YAML vers XML" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "yaml_to_xml.xml"
            $result = Convert-FileFormat -InputFile $yamlFilePath -OutputFile $outputPath -InputFormat "YAML" -OutputFormat "XML"
            $result | Should -Be $true
            Test-Path -Path $outputPath | Should -Be $true
            
            # Vérifier que le fichier XML est valide
            $isValid = Test-FileValidity -FilePath $outputPath -Format "XML"
            $isValid | Should -Be $true
        }
        
        It "Convertit correctement YAML vers TEXT" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "yaml_to_text.txt"
            $result = Convert-FileFormat -InputFile $yamlFilePath -OutputFile $outputPath -InputFormat "YAML" -OutputFormat "TEXT"
            $result | Should -Be $true
            Test-Path -Path $outputPath | Should -Be $true
        }
        
        It "Convertit correctement YAML vers CSV" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "yaml_to_csv.csv"
            $result = Convert-FileFormat -InputFile $yamlFilePath -OutputFile $outputPath -InputFormat "YAML" -OutputFormat "CSV"
            $result | Should -Be $true
            Test-Path -Path $outputPath | Should -Be $true
            
            # Vérifier que le fichier CSV est valide
            $isValid = Test-FileValidity -FilePath $outputPath -Format "CSV"
            $isValid | Should -Be $true
        }
    }
    
    Context "Conversions depuis TEXT" {
        It "Convertit correctement TEXT vers JSON (si possible)" {
            # Créer un fichier texte au format JSON
            $jsonTextPath = Join-Path -Path $testTempDir -ChildPath "json_text.txt"
            Set-Content -Path $jsonTextPath -Value $jsonContent -Encoding UTF8
            
            $outputPath = Join-Path -Path $outputDir -ChildPath "text_to_json.json"
            $result = Convert-FileFormat -InputFile $jsonTextPath -OutputFile $outputPath -InputFormat "TEXT" -OutputFormat "JSON"
            $result | Should -Be $true
            Test-Path -Path $outputPath | Should -Be $true
            
            # Vérifier que le fichier JSON est valide
            $isValid = Test-FileValidity -FilePath $outputPath -Format "JSON"
            $isValid | Should -Be $true
        }
        
        It "Convertit correctement TEXT vers XML (si possible)" {
            # Créer un fichier texte au format XML
            $xmlTextPath = Join-Path -Path $testTempDir -ChildPath "xml_text.txt"
            Set-Content -Path $xmlTextPath -Value $xmlContent -Encoding UTF8
            
            $outputPath = Join-Path -Path $outputDir -ChildPath "text_to_xml.xml"
            $result = Convert-FileFormat -InputFile $xmlTextPath -OutputFile $outputPath -InputFormat "TEXT" -OutputFormat "XML"
            $result | Should -Be $true
            Test-Path -Path $outputPath | Should -Be $true
            
            # Vérifier que le fichier XML est valide
            $isValid = Test-FileValidity -FilePath $outputPath -Format "XML"
            $isValid | Should -Be $true
        }
    }
    
    Context "Tests de détection automatique de format" {
        It "Détecte et convertit automatiquement JSON vers XML" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "auto_json_to_xml.xml"
            $result = Convert-FileFormat -InputFile $jsonFilePath -OutputFile $outputPath -InputFormat "AUTO" -OutputFormat "XML"
            $result | Should -Be $true
            Test-Path -Path $outputPath | Should -Be $true
            
            # Vérifier que le fichier XML est valide
            $isValid = Test-FileValidity -FilePath $outputPath -Format "XML"
            $isValid | Should -Be $true
        }
        
        It "Détecte et convertit automatiquement CSV vers JSON" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "auto_csv_to_json.json"
            $result = Convert-FileFormat -InputFile $csvFilePath -OutputFile $outputPath -InputFormat "AUTO" -OutputFormat "JSON"
            $result | Should -Be $true
            Test-Path -Path $outputPath | Should -Be $true
            
            # Vérifier que le fichier JSON est valide
            $isValid = Test-FileValidity -FilePath $outputPath -Format "JSON"
            $isValid | Should -Be $true
        }
        
        It "Détecte et convertit automatiquement YAML vers JSON" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "auto_yaml_to_json.json"
            $result = Convert-FileFormat -InputFile $yamlFilePath -OutputFile $outputPath -InputFormat "AUTO" -OutputFormat "JSON"
            $result | Should -Be $true
            Test-Path -Path $outputPath | Should -Be $true
            
            # Vérifier que le fichier JSON est valide
            $isValid = Test-FileValidity -FilePath $outputPath -Format "JSON"
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
