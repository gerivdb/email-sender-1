#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour les formats CSV et YAML.
.DESCRIPTION
    Ce script contient des tests unitaires pour les fonctionnalités CSV et YAML
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

# Créer un répertoire temporaire pour les tests
$testTempDir = Join-Path -Path $env:TEMP -ChildPath "CsvYamlTests"
if (Test-Path -Path $testTempDir) {
    Remove-Item -Path $testTempDir -Recurse -Force
}
New-Item -Path $testTempDir -ItemType Directory -Force | Out-Null

# Créer des fichiers de test
$csvFilePath = Join-Path -Path $testTempDir -ChildPath "test.csv"
$yamlFilePath = Join-Path -Path $testTempDir -ChildPath "test.yaml"
$jsonFilePath = Join-Path -Path $testTempDir -ChildPath "test.json"
$outputDir = Join-Path -Path $testTempDir -ChildPath "output"
New-Item -Path $outputDir -ItemType Directory -Force | Out-Null

# Créer un fichier CSV valide
$csvContent = @"
id,name,value,description
1,Item 1,Value 1,"Description 1"
2,Item 2,Value 2,"Description 2"
3,Item 3,Value 3,"Description 3"
"@
Set-Content -Path $csvFilePath -Value $csvContent -Encoding UTF8

# Créer un fichier CSV invalide (colonnes incohérentes)
$invalidCsvPath = Join-Path -Path $testTempDir -ChildPath "invalid.csv"
$invalidCsvContent = @"
id,name,value,description
1,Item 1,Value 1,"Description 1"
2,Item 2,"Description 2"
3,Item 3,Value 3,"Description 3"
"@
Set-Content -Path $invalidCsvPath -Value $invalidCsvContent -Encoding UTF8

# Créer un fichier YAML valide
$yamlContent = @"
name: Test Object
items:
  - id: 1
    value: Item 1
    description: Description 1
  - id: 2
    value: Item 2
    description: Description 2
  - id: 3
    value: Item 3
    description: Description 3
metadata:
  created: 2025-06-06
  version: 1.0.0
"@
Set-Content -Path $yamlFilePath -Value $yamlContent -Encoding UTF8

# Créer un fichier YAML invalide
$invalidYamlPath = Join-Path -Path $testTempDir -ChildPath "invalid.yaml"
$invalidYamlContent = @"
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
Set-Content -Path $invalidYamlPath -Value $invalidYamlContent -Encoding UTF8

# Créer un fichier JSON pour les tests de conversion
$jsonContent = @"
{
  "name": "Test Object",
  "items": [
    {
      "id": 1,
      "value": "Item 1",
      "description": "Description 1"
    },
    {
      "id": 2,
      "value": "Item 2",
      "description": "Description 2"
    },
    {
      "id": 3,
      "value": "Item 3",
      "description": "Description 3"
    }
  ],
  "metadata": {
    "created": "2025-06-06",
    "version": "1.0.0"
  }
}
"@
Set-Content -Path $jsonFilePath -Value $jsonContent -Encoding UTF8

# Créer un fichier JSON avec un tableau pour les tests de conversion CSV
$jsonArrayPath = Join-Path -Path $testTempDir -ChildPath "array.json"
$jsonArrayContent = @"
[
  {
    "id": 1,
    "name": "Item 1",
    "value": "Value 1",
    "description": "Description 1"
  },
  {
    "id": 2,
    "name": "Item 2",
    "value": "Value 2",
    "description": "Description 2"
  },
  {
    "id": 3,
    "name": "Item 3",
    "value": "Value 3",
    "description": "Description 3"
  }
]
"@
Set-Content -Path $jsonArrayPath -Value $jsonArrayContent -Encoding UTF8

# Définir les tests
Describe "Tests des formats CSV et YAML" {
    BeforeAll {
        # Importer le module UnifiedSegmenter
        . $unifiedSegmenterPath
        
        # Initialiser le segmenteur unifié
        $initResult = Initialize-UnifiedSegmenter
        $initResult | Should -Be $true
    }
    
    Context "Tests de détection de format" {
        It "Détecte correctement le format CSV" {
            $format = Get-FileFormat -FilePath $csvFilePath
            $format | Should -Be "CSV"
        }
        
        It "Détecte correctement le format YAML" {
            $format = Get-FileFormat -FilePath $yamlFilePath
            $format | Should -Be "YAML"
        }
        
        It "Détecte correctement le format CSV avec EncodingDetector" {
            $format = Get-FileFormat -FilePath $csvFilePath -UseEncodingDetector
            $format | Should -Be "CSV"
        }
        
        It "Détecte correctement le format YAML avec EncodingDetector" {
            $format = Get-FileFormat -FilePath $yamlFilePath -UseEncodingDetector
            $format | Should -Be "YAML"
        }
    }
    
    Context "Tests de validation de fichier" {
        It "Valide correctement un fichier CSV valide" {
            $isValid = Test-FileValidity -FilePath $csvFilePath -Format "CSV"
            $isValid | Should -Be $true
        }
        
        It "Détecte correctement un fichier CSV invalide" {
            $isValid = Test-FileValidity -FilePath $invalidCsvPath -Format "CSV"
            $isValid | Should -Be $false
        }
        
        It "Valide correctement un fichier YAML valide" {
            $isValid = Test-FileValidity -FilePath $yamlFilePath -Format "YAML"
            $isValid | Should -Be $true
        }
        
        It "Détecte correctement un fichier YAML invalide" {
            $isValid = Test-FileValidity -FilePath $invalidYamlPath -Format "YAML"
            $isValid | Should -Be $false
        }
    }
    
    Context "Tests de conversion CSV" {
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
            $content[0].name | Should -Be "Item 1"
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
    
    Context "Tests de conversion YAML" {
        It "Convertit correctement YAML vers JSON" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "yaml_to_json.json"
            $result = Convert-FileFormat -InputFile $yamlFilePath -OutputFile $outputPath -InputFormat "YAML" -OutputFormat "JSON"
            $result | Should -Be $true
            Test-Path -Path $outputPath | Should -Be $true
            
            # Vérifier que le fichier JSON est valide
            $isValid = Test-FileValidity -FilePath $outputPath -Format "JSON"
            $isValid | Should -Be $true
            
            # Vérifier le contenu
            $content = Get-Content -Path $outputPath -Raw | ConvertFrom-Json
            $content | Should -Not -BeNullOrEmpty
            $content.name | Should -Be "Test Object"
            $content.items.Count | Should -Be 3
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
    
    Context "Tests de conversion JSON vers CSV/YAML" {
        It "Convertit correctement JSON (objet) vers CSV" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "json_to_csv.csv"
            $result = Convert-FileFormat -InputFile $jsonFilePath -OutputFile $outputPath -InputFormat "JSON" -OutputFormat "CSV"
            $result | Should -Be $true
            Test-Path -Path $outputPath | Should -Be $true
            
            # Vérifier que le fichier CSV est valide
            $isValid = Test-FileValidity -FilePath $outputPath -Format "CSV"
            $isValid | Should -Be $true
        }
        
        It "Convertit correctement JSON (tableau) vers CSV" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "jsonarray_to_csv.csv"
            $result = Convert-FileFormat -InputFile $jsonArrayPath -OutputFile $outputPath -InputFormat "JSON" -OutputFormat "CSV"
            $result | Should -Be $true
            Test-Path -Path $outputPath | Should -Be $true
            
            # Vérifier que le fichier CSV est valide
            $isValid = Test-FileValidity -FilePath $outputPath -Format "CSV"
            $isValid | Should -Be $true
            
            # Vérifier le contenu
            $content = Get-Content -Path $outputPath
            $content.Count | Should -BeGreaterThan 1
            $content[0] | Should -Match "id,name,value,description"
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
    
    Context "Tests d'analyse de fichier" {
        It "Analyse correctement un fichier CSV" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "csv_analysis.json"
            $result = Get-FileAnalysis -FilePath $csvFilePath -Format "CSV" -OutputFile $outputPath
            $result | Should -Be $outputPath
            Test-Path -Path $outputPath | Should -Be $true
            
            # Vérifier le contenu de l'analyse
            $analysis = Get-Content -Path $outputPath -Raw | ConvertFrom-Json
            $analysis | Should -Not -BeNullOrEmpty
            $analysis.total_rows | Should -Be 4  # En-tête + 3 lignes
            $analysis.columns | Should -Be 4     # 4 colonnes
        }
        
        It "Analyse correctement un fichier YAML" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "yaml_analysis.json"
            $result = Get-FileAnalysis -FilePath $yamlFilePath -Format "YAML" -OutputFile $outputPath
            $result | Should -Be $outputPath
            Test-Path -Path $outputPath | Should -Be $true
            
            # Vérifier le contenu de l'analyse
            $analysis = Get-Content -Path $outputPath -Raw | ConvertFrom-Json
            $analysis | Should -Not -BeNullOrEmpty
            $analysis.structure | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Tests de segmentation de fichier" {
        It "Segmente correctement un fichier CSV" {
            $csvSegmentDir = Join-Path -Path $outputDir -ChildPath "csv_segments"
            New-Item -Path $csvSegmentDir -ItemType Directory -Force | Out-Null
            
            $result = Split-File -FilePath $csvFilePath -Format "CSV" -OutputDir $csvSegmentDir -ChunkSizeKB 1
            $result | Should -Not -BeNullOrEmpty
            
            # Vérifier que les fichiers ont été créés
            $segmentFiles = Get-ChildItem -Path $csvSegmentDir -Filter "*.csv"
            $segmentFiles.Count | Should -BeGreaterThan 0
            
            # Vérifier que chaque segment est un CSV valide
            foreach ($file in $segmentFiles) {
                $isValid = Test-FileValidity -FilePath $file.FullName -Format "CSV"
                $isValid | Should -Be $true
            }
        }
        
        It "Segmente correctement un fichier YAML" {
            $yamlSegmentDir = Join-Path -Path $outputDir -ChildPath "yaml_segments"
            New-Item -Path $yamlSegmentDir -ItemType Directory -Force | Out-Null
            
            $result = Split-File -FilePath $yamlFilePath -Format "YAML" -OutputDir $yamlSegmentDir -ChunkSizeKB 1
            $result | Should -Not -BeNullOrEmpty
            
            # Vérifier que les fichiers ont été créés
            $segmentFiles = Get-ChildItem -Path $yamlSegmentDir -Filter "*.yaml"
            $segmentFiles.Count | Should -BeGreaterThan 0
            
            # Vérifier que chaque segment est un YAML valide
            foreach ($file in $segmentFiles) {
                $isValid = Test-FileValidity -FilePath $file.FullName -Format "YAML"
                $isValid | Should -Be $true
            }
        }
    }
    
    AfterAll {
        # Nettoyer les fichiers de test
        if (Test-Path -Path $testTempDir) {
            Remove-Item -Path $testTempDir -Recurse -Force
        }
    }
}
