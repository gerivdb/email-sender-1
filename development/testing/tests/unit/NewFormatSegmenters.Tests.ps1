#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour les segmenteurs de formats CSV et YAML.
.DESCRIPTION
    Ce script contient des tests unitaires pour les modules CsvSegmenter.py,
    YamlSegmenter.py et leur intégration avec UnifiedSegmenter.ps1.
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
$csvSegmenterPath = Join-Path -Path $modulesPath -ChildPath "CsvSegmenter.py"
$yamlSegmenterPath = Join-Path -Path $modulesPath -ChildPath "YamlSegmenter.py"

# Créer un répertoire temporaire pour les tests
$testTempDir = Join-Path -Path $env:TEMP -ChildPath "NewFormatSegmentersTests"
if (Test-Path -Path $testTempDir) {
    Remove-Item -Path $testTempDir -Recurse -Force
}
New-Item -Path $testTempDir -ItemType Directory -Force | Out-Null

# Créer des fichiers de test
$csvFilePath = Join-Path -Path $testTempDir -ChildPath "test.csv"
$yamlFilePath = Join-Path -Path $testTempDir -ChildPath "test.yaml"
$outputDir = Join-Path -Path $testTempDir -ChildPath "output"

# Créer un fichier CSV de test
$csvContent = @"
id,name,value,description
1,Item 1,Value 1,"This is a description for item 1"
2,Item 2,Value 2,"This is a description for item 2"
3,Item 3,Value 3,"This is a description for item 3"
4,Item 4,Value 4,"This is a description for item 4"
5,Item 5,Value 5,"This is a description for item 5"
6,Item 6,Value 6,"This is a description for item 6"
7,Item 7,Value 7,"This is a description for item 7"
8,Item 8,Value 8,"This is a description for item 8"
9,Item 9,Value 9,"This is a description for item 9"
10,Item 10,Value 10,"This is a description for item 10"
"@
Set-Content -Path $csvFilePath -Value $csvContent -Encoding UTF8

# Créer un fichier YAML de test
$yamlContent = @"
name: Test Object
items:
  - id: 1
    value: Item 1
    description: This is a description for item 1
  - id: 2
    value: Item 2
    description: This is a description for item 2
  - id: 3
    value: Item 3
    description: This is a description for item 3
  - id: 4
    value: Item 4
    description: This is a description for item 4
  - id: 5
    value: Item 5
    description: This is a description for item 5
metadata:
  created: 2025-06-06
  version: 1.0.0
  author: EMAIL_SENDER_1 Team
  description: >
    This is a test YAML file for the YamlSegmenter module.
    It contains multiple items and metadata.
"@
Set-Content -Path $yamlFilePath -Value $yamlContent -Encoding UTF8

# Définir les tests
Describe "Tests des segmenteurs de formats CSV et YAML" {
    BeforeAll {
        # Importer le module UnifiedSegmenter
        . $unifiedSegmenterPath
        
        # Initialiser le segmenteur unifié
        $initResult = Initialize-UnifiedSegmenter -MaxInputSizeKB 10 -DefaultChunkSizeKB 5
    }
    
    Context "Tests du module UnifiedSegmenter avec CSV et YAML" {
        It "Initialise correctement le segmenteur unifié" {
            $initResult | Should -Be $true
        }
        
        It "Détecte correctement le format CSV" {
            $format = Get-FileFormat -FilePath $csvFilePath
            $format | Should -Be "CSV"
        }
        
        It "Détecte correctement le format YAML" {
            $format = Get-FileFormat -FilePath $yamlFilePath
            $format | Should -Be "YAML"
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
    
    Context "Tests du module CsvSegmenter" {
        It "Le fichier CsvSegmenter.py existe" {
            Test-Path -Path $csvSegmenterPath | Should -Be $true
        }
        
        It "Peut analyser un fichier CSV" {
            $outputFile = Join-Path -Path $testTempDir -ChildPath "csv_analysis.json"
            $result = Get-FileAnalysis -FilePath $csvFilePath -Format "CSV" -OutputFile $outputFile
            Test-Path -Path $outputFile | Should -Be $true
            
            # Vérifier que l'analyse contient des informations pertinentes
            $analysis = Get-Content -Path $outputFile -Raw | ConvertFrom-Json
            $analysis.total_rows | Should -BeGreaterThan 0
            $analysis.columns | Should -Not -BeNullOrEmpty
        }
        
        It "Peut segmenter un fichier CSV" {
            $csvOutputDir = Join-Path -Path $outputDir -ChildPath "csv"
            $result = Split-File -FilePath $csvFilePath -Format "CSV" -OutputDir $csvOutputDir -ChunkSizeKB 1
            $result | Should -Not -BeNullOrEmpty
            
            # Vérifier que les fichiers ont été créés
            $segmentFiles = Get-ChildItem -Path $csvOutputDir -Filter "*.csv"
            $segmentFiles.Count | Should -BeGreaterThan 0
            
            # Vérifier que chaque segment est un CSV valide
            foreach ($file in $segmentFiles) {
                $isValid = Test-FileValidity -FilePath $file.FullName -Format "CSV"
                $isValid | Should -Be $true
            }
        }
        
        It "Peut segmenter un fichier CSV sans préserver l'en-tête" {
            $csvOutputDir = Join-Path -Path $outputDir -ChildPath "csv_no_header"
            $result = Split-File -FilePath $csvFilePath -Format "CSV" -OutputDir $csvOutputDir -ChunkSizeKB 1 -PreserveStructure:$false
            $result | Should -Not -BeNullOrEmpty
            
            # Vérifier que les fichiers ont été créés
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
            
            # Vérifier que l'analyse contient des informations pertinentes
            $analysis = Get-Content -Path $outputFile -Raw | ConvertFrom-Json
            $analysis.structure | Should -Not -BeNullOrEmpty
        }
        
        It "Peut segmenter un fichier YAML" {
            $yamlOutputDir = Join-Path -Path $outputDir -ChildPath "yaml"
            $result = Split-File -FilePath $yamlFilePath -Format "YAML" -OutputDir $yamlOutputDir -ChunkSizeKB 1
            $result | Should -Not -BeNullOrEmpty
            
            # Vérifier que les fichiers ont été créés
            $segmentFiles = Get-ChildItem -Path $yamlOutputDir -Filter "*.yaml"
            $segmentFiles.Count | Should -BeGreaterThan 0
            
            # Vérifier que chaque segment est un YAML valide
            foreach ($file in $segmentFiles) {
                $isValid = Test-FileValidity -FilePath $file.FullName -Format "YAML"
                $isValid | Should -Be $true
            }
        }
    }
    
    Context "Tests de conversion entre formats avec CSV et YAML" {
        It "Peut convertir de CSV à JSON" {
            $outputFile = Join-Path -Path $testTempDir -ChildPath "csv_to_json.json"
            $result = Convert-FileFormat -InputFile $csvFilePath -OutputFile $outputFile -InputFormat "CSV" -OutputFormat "JSON"
            $result | Should -Be $true
            Test-Path -Path $outputFile | Should -Be $true
            
            # Vérifier que le fichier est un JSON valide
            $isValid = Test-FileValidity -FilePath $outputFile -Format "JSON"
            $isValid | Should -Be $true
        }
        
        It "Peut convertir de CSV à XML" {
            $outputFile = Join-Path -Path $testTempDir -ChildPath "csv_to_xml.xml"
            $result = Convert-FileFormat -InputFile $csvFilePath -OutputFile $outputFile -InputFormat "CSV" -OutputFormat "XML"
            $result | Should -Be $true
            Test-Path -Path $outputFile | Should -Be $true
            
            # Vérifier que le fichier est un XML valide
            $isValid = Test-FileValidity -FilePath $outputFile -Format "XML"
            $isValid | Should -Be $true
        }
        
        It "Peut convertir de CSV à YAML" {
            $outputFile = Join-Path -Path $testTempDir -ChildPath "csv_to_yaml.yaml"
            $result = Convert-FileFormat -InputFile $csvFilePath -OutputFile $outputFile -InputFormat "CSV" -OutputFormat "YAML"
            $result | Should -Be $true
            Test-Path -Path $outputFile | Should -Be $true
            
            # Vérifier que le fichier est un YAML valide
            $isValid = Test-FileValidity -FilePath $outputFile -Format "YAML"
            $isValid | Should -Be $true
        }
        
        It "Peut convertir de YAML à JSON" {
            $outputFile = Join-Path -Path $testTempDir -ChildPath "yaml_to_json.json"
            $result = Convert-FileFormat -InputFile $yamlFilePath -OutputFile $outputFile -InputFormat "YAML" -OutputFormat "JSON"
            $result | Should -Be $true
            Test-Path -Path $outputFile | Should -Be $true
            
            # Vérifier que le fichier est un JSON valide
            $isValid = Test-FileValidity -FilePath $outputFile -Format "JSON"
            $isValid | Should -Be $true
        }
        
        It "Peut convertir de YAML à XML" {
            $outputFile = Join-Path -Path $testTempDir -ChildPath "yaml_to_xml.xml"
            $result = Convert-FileFormat -InputFile $yamlFilePath -OutputFile $outputFile -InputFormat "YAML" -OutputFormat "XML"
            $result | Should -Be $true
            Test-Path -Path $outputFile | Should -Be $true
            
            # Vérifier que le fichier est un XML valide
            $isValid = Test-FileValidity -FilePath $outputFile -Format "XML"
            $isValid | Should -Be $true
        }
        
        It "Peut convertir de YAML à CSV" {
            $outputFile = Join-Path -Path $testTempDir -ChildPath "yaml_to_csv.csv"
            $result = Convert-FileFormat -InputFile $yamlFilePath -OutputFile $outputFile -InputFormat "YAML" -OutputFormat "CSV"
            $result | Should -Be $true
            Test-Path -Path $outputFile | Should -Be $true
            
            # Vérifier que le fichier est un CSV valide
            $isValid = Test-FileValidity -FilePath $outputFile -Format "CSV"
            $isValid | Should -Be $true
        }
        
        It "Peut convertir de JSON à CSV" {
            # D'abord, convertir YAML en JSON
            $jsonFilePath = Join-Path -Path $testTempDir -ChildPath "temp.json"
            $result1 = Convert-FileFormat -InputFile $yamlFilePath -OutputFile $jsonFilePath -InputFormat "YAML" -OutputFormat "JSON"
            $result1 | Should -Be $true
            
            # Ensuite, convertir JSON en CSV
            $outputFile = Join-Path -Path $testTempDir -ChildPath "json_to_csv.csv"
            $result2 = Convert-FileFormat -InputFile $jsonFilePath -OutputFile $outputFile -InputFormat "JSON" -OutputFormat "CSV"
            $result2 | Should -Be $true
            Test-Path -Path $outputFile | Should -Be $true
            
            # Vérifier que le fichier est un CSV valide
            $isValid = Test-FileValidity -FilePath $outputFile -Format "CSV"
            $isValid | Should -Be $true
        }
        
        It "Peut convertir de JSON à YAML" {
            # D'abord, convertir CSV en JSON
            $jsonFilePath = Join-Path -Path $testTempDir -ChildPath "temp2.json"
            $result1 = Convert-FileFormat -InputFile $csvFilePath -OutputFile $jsonFilePath -InputFormat "CSV" -OutputFormat "JSON"
            $result1 | Should -Be $true
            
            # Ensuite, convertir JSON en YAML
            $outputFile = Join-Path -Path $testTempDir -ChildPath "json_to_yaml.yaml"
            $result2 = Convert-FileFormat -InputFile $jsonFilePath -OutputFile $outputFile -InputFormat "JSON" -OutputFormat "YAML"
            $result2 | Should -Be $true
            Test-Path -Path $outputFile | Should -Be $true
            
            # Vérifier que le fichier est un YAML valide
            $isValid = Test-FileValidity -FilePath $outputFile -Format "YAML"
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
