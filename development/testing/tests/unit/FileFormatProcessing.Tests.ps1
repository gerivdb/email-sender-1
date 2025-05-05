#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le traitement des formats CSV et YAML.
.DESCRIPTION
    Ce script contient des tests unitaires pour les fonctionnalitÃ©s de traitement des formats CSV et YAML.
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

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testTempDir = Join-Path -Path $env:TEMP -ChildPath "FileFormatProcessingTests"
if (Test-Path -Path $testTempDir) {
    Remove-Item -Path $testTempDir -Recurse -Force
}
New-Item -Path $testTempDir -ItemType Directory -Force | Out-Null

# CrÃ©er des sous-rÃ©pertoires pour les tests
$inputDir = Join-Path -Path $testTempDir -ChildPath "input"
$outputDir = Join-Path -Path $testTempDir -ChildPath "output"
$analysisDir = Join-Path -Path $testTempDir -ChildPath "analysis"
New-Item -Path $inputDir -ItemType Directory -Force | Out-Null
New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
New-Item -Path $analysisDir -ItemType Directory -Force | Out-Null

# CrÃ©er des fichiers de test
$csvSimplePath = Join-Path -Path $inputDir -ChildPath "simple.csv"
$csvComplexPath = Join-Path -Path $inputDir -ChildPath "complex.csv"
$yamlSimplePath = Join-Path -Path $inputDir -ChildPath "simple.yaml"
$yamlComplexPath = Join-Path -Path $inputDir -ChildPath "complex.yaml"
$invalidCsvPath = Join-Path -Path $inputDir -ChildPath "invalid.csv"
$invalidYamlPath = Join-Path -Path $inputDir -ChildPath "invalid.yaml"

# CrÃ©er un fichier CSV simple
$csvSimpleContent = @"
id,name,value
1,Item 1,Value 1
2,Item 2,Value 2
3,Item 3,Value 3
"@
Set-Content -Path $csvSimplePath -Value $csvSimpleContent -Encoding UTF8

# CrÃ©er un fichier CSV complexe
$csvComplexContent = @"
id,name,value,description,date,numeric,boolean
1,"Item 1, with comma",123.45,"Description with ""quotes""",2025-01-01,1000,true
2,"Item 2",67.89,"Multi-line
description",2025-02-01,2000,false
3,"Item 3",0,"Description with special chars: @#$%^&*()",2025-03-01,-500,true
"@
Set-Content -Path $csvComplexPath -Value $csvComplexContent -Encoding UTF8

# CrÃ©er un fichier YAML simple
$yamlSimpleContent = @"
name: Simple Object
items:
  - id: 1
    value: Item 1
  - id: 2
    value: Item 2
  - id: 3
    value: Item 3
"@
Set-Content -Path $yamlSimplePath -Value $yamlSimpleContent -Encoding UTF8

# CrÃ©er un fichier YAML complexe
$yamlComplexContent = @"
name: Complex Object
metadata:
  created: 2025-06-06
  version: 1.0.0
  tags:
    - test
    - yaml
    - complex
items:
  - id: 1
    name: Item 1
    value: 123.45
    attributes:
      color: red
      size: large
      enabled: true
  - id: 2
    name: Item 2
    value: 67.89
    attributes:
      color: blue
      size: medium
      enabled: false
  - id: 3
    name: Item 3
    value: 0
    attributes:
      color: green
      size: small
      enabled: true
settings:
  timeout: 30
  retries: 3
  logging: verbose
"@
Set-Content -Path $yamlComplexPath -Value $yamlComplexContent -Encoding UTF8

# CrÃ©er un fichier CSV invalide
$invalidCsvContent = @"
id,name,value
1,Item 1,Value 1
2,Item 2
3,Item 3,Value 3,Extra
"@
Set-Content -Path $invalidCsvPath -Value $invalidCsvContent -Encoding UTF8

# CrÃ©er un fichier YAML invalide
$invalidYamlContent = @"
name: Invalid Object
items:
  - id: 1
    value: Item 1
  - id: 2
    value: Item 2
  - id: 3
    value: Item 3
  indentation: wrong
"@
Set-Content -Path $invalidYamlPath -Value $invalidYamlContent -Encoding UTF8

# DÃ©finir les tests
Describe "Tests de traitement des formats CSV et YAML" {
    BeforeAll {
        # Importer le module
        . $unifiedSegmenterPath
        
        # Initialiser le segmenteur unifiÃ©
        $initResult = Initialize-UnifiedSegmenter
        $initResult | Should -Be $true
    }
    
    Context "Tests de dÃ©tection de format" {
        It "DÃ©tecte correctement le format CSV" {
            $format = Get-FileFormat -FilePath $csvSimplePath
            $format | Should -Be "CSV"
        }
        
        It "DÃ©tecte correctement le format YAML" {
            $format = Get-FileFormat -FilePath $yamlSimplePath
            $format | Should -Be "YAML"
        }
    }
    
    Context "Tests de validation de fichier" {
        It "Valide correctement un fichier CSV valide" {
            $isValid = Test-FileValidity -FilePath $csvSimplePath -Format "CSV"
            $isValid | Should -Be $true
        }
        
        It "Valide correctement un fichier YAML valide" {
            $isValid = Test-FileValidity -FilePath $yamlSimplePath -Format "YAML"
            $isValid | Should -Be $true
        }
        
        It "DÃ©tecte correctement un fichier CSV invalide" {
            $isValid = Test-FileValidity -FilePath $invalidCsvPath -Format "CSV"
            $isValid | Should -Be $false
        }
        
        It "DÃ©tecte correctement un fichier YAML invalide" {
            $isValid = Test-FileValidity -FilePath $invalidYamlPath -Format "YAML"
            $isValid | Should -Be $false
        }
    }
    
    Context "Tests de conversion de format" {
        It "Convertit correctement un fichier CSV en JSON" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "csv_to_json.json"
            $result = Convert-FileFormat -InputFile $csvSimplePath -OutputFile $outputPath -InputFormat "CSV" -OutputFormat "JSON"
            
            $result | Should -Be $true
            Test-Path -Path $outputPath | Should -Be $true
            
            # VÃ©rifier que le fichier JSON est valide
            $jsonContent = Get-Content -Path $outputPath -Raw
            $jsonContent | Should -Not -BeNullOrEmpty
            { $jsonContent | ConvertFrom-Json } | Should -Not -Throw
        }
        
        It "Convertit correctement un fichier CSV complexe en JSON" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "csv_complex_to_json.json"
            $result = Convert-FileFormat -InputFile $csvComplexPath -OutputFile $outputPath -InputFormat "CSV" -OutputFormat "JSON"
            
            $result | Should -Be $true
            Test-Path -Path $outputPath | Should -Be $true
            
            # VÃ©rifier que le fichier JSON est valide
            $jsonContent = Get-Content -Path $outputPath -Raw
            $jsonContent | Should -Not -BeNullOrEmpty
            { $jsonContent | ConvertFrom-Json } | Should -Not -Throw
            
            # VÃ©rifier que les donnÃ©es sont correctes
            $jsonObject = $jsonContent | ConvertFrom-Json
            $jsonObject.Count | Should -Be 3
            $jsonObject[0].id | Should -Be "1"
            $jsonObject[0].name | Should -Be "Item 1, with comma"
            $jsonObject[0].value | Should -Be "123.45"
        }
        
        It "Convertit correctement un fichier YAML en JSON" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "yaml_to_json.json"
            $result = Convert-FileFormat -InputFile $yamlSimplePath -OutputFile $outputPath -InputFormat "YAML" -OutputFormat "JSON"
            
            $result | Should -Be $true
            Test-Path -Path $outputPath | Should -Be $true
            
            # VÃ©rifier que le fichier JSON est valide
            $jsonContent = Get-Content -Path $outputPath -Raw
            $jsonContent | Should -Not -BeNullOrEmpty
            { $jsonContent | ConvertFrom-Json } | Should -Not -Throw
        }
        
        It "Convertit correctement un fichier YAML complexe en JSON" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "yaml_complex_to_json.json"
            $result = Convert-FileFormat -InputFile $yamlComplexPath -OutputFile $outputPath -InputFormat "YAML" -OutputFormat "JSON"
            
            $result | Should -Be $true
            Test-Path -Path $outputPath | Should -Be $true
            
            # VÃ©rifier que le fichier JSON est valide
            $jsonContent = Get-Content -Path $outputPath -Raw
            $jsonContent | Should -Not -BeNullOrEmpty
            { $jsonContent | ConvertFrom-Json } | Should -Not -Throw
            
            # VÃ©rifier que les donnÃ©es sont correctes
            $jsonObject = $jsonContent | ConvertFrom-Json
            $jsonObject.name | Should -Be "Complex Object"
            $jsonObject.items.Count | Should -Be 3
            $jsonObject.items[0].id | Should -Be 1
            $jsonObject.items[0].attributes.color | Should -Be "red"
        }
        
        It "Convertit correctement un fichier JSON en CSV" {
            # D'abord, convertir CSV en JSON
            $jsonPath = Join-Path -Path $outputDir -ChildPath "temp.json"
            Convert-FileFormat -InputFile $csvSimplePath -OutputFile $jsonPath -InputFormat "CSV" -OutputFormat "JSON"
            
            # Ensuite, convertir JSON en CSV
            $outputPath = Join-Path -Path $outputDir -ChildPath "json_to_csv.csv"
            $result = Convert-FileFormat -InputFile $jsonPath -OutputFile $outputPath -InputFormat "JSON" -OutputFormat "CSV"
            
            $result | Should -Be $true
            Test-Path -Path $outputPath | Should -Be $true
            
            # VÃ©rifier que le fichier CSV est valide
            $csvContent = Get-Content -Path $outputPath -Raw
            $csvContent | Should -Not -BeNullOrEmpty
            
            # VÃ©rifier que les donnÃ©es sont correctes
            $csvLines = $csvContent -split "`n"
            $csvLines.Count | Should -BeGreaterThan 3  # En-tÃªte + 3 lignes de donnÃ©es
            $csvLines[0] | Should -Match "id,name,value"
        }
        
        It "Convertit correctement un fichier JSON en YAML" {
            # D'abord, convertir YAML en JSON
            $jsonPath = Join-Path -Path $outputDir -ChildPath "temp2.json"
            Convert-FileFormat -InputFile $yamlSimplePath -OutputFile $jsonPath -InputFormat "YAML" -OutputFormat "JSON"
            
            # Ensuite, convertir JSON en YAML
            $outputPath = Join-Path -Path $outputDir -ChildPath "json_to_yaml.yaml"
            $result = Convert-FileFormat -InputFile $jsonPath -OutputFile $outputPath -InputFormat "JSON" -OutputFormat "YAML"
            
            $result | Should -Be $true
            Test-Path -Path $outputPath | Should -Be $true
            
            # VÃ©rifier que le fichier YAML est valide
            $yamlContent = Get-Content -Path $outputPath -Raw
            $yamlContent | Should -Not -BeNullOrEmpty
            
            # VÃ©rifier que les donnÃ©es sont correctes
            $yamlContent | Should -Match "name: Simple Object"
            $yamlContent | Should -Match "items:"
        }
    }
    
    Context "Tests d'analyse de fichier" {
        It "Analyse correctement un fichier CSV" {
            $outputPath = Join-Path -Path $analysisDir -ChildPath "csv_analysis.json"
            $result = Get-FileAnalysis -FilePath $csvSimplePath -Format "CSV" -OutputFile $outputPath
            
            $result | Should -Not -BeNullOrEmpty
            Test-Path -Path $outputPath | Should -Be $true
            
            # VÃ©rifier que le fichier d'analyse est valide
            $analysisContent = Get-Content -Path $outputPath -Raw
            $analysisContent | Should -Not -BeNullOrEmpty
            { $analysisContent | ConvertFrom-Json } | Should -Not -Throw
            
            # VÃ©rifier que l'analyse contient les informations attendues
            $analysis = $analysisContent | ConvertFrom-Json
            $analysis.file_info | Should -Not -BeNullOrEmpty
            $analysis.structure | Should -Not -BeNullOrEmpty
            $analysis.structure.total_rows | Should -Be 3
            $analysis.structure.total_columns | Should -Be 3
            $analysis.structure.header | Should -Contain "id"
            $analysis.structure.header | Should -Contain "name"
            $analysis.structure.header | Should -Contain "value"
        }
        
        It "Analyse correctement un fichier CSV complexe" {
            $outputPath = Join-Path -Path $analysisDir -ChildPath "csv_complex_analysis.json"
            $result = Get-FileAnalysis -FilePath $csvComplexPath -Format "CSV" -OutputFile $outputPath
            
            $result | Should -Not -BeNullOrEmpty
            Test-Path -Path $outputPath | Should -Be $true
            
            # VÃ©rifier que le fichier d'analyse est valide
            $analysisContent = Get-Content -Path $outputPath -Raw
            $analysisContent | Should -Not -BeNullOrEmpty
            { $analysisContent | ConvertFrom-Json } | Should -Not -Throw
            
            # VÃ©rifier que l'analyse contient les informations attendues
            $analysis = $analysisContent | ConvertFrom-Json
            $analysis.structure.total_rows | Should -Be 3
            $analysis.structure.total_columns | Should -Be 7
            $analysis.structure.header | Should -Contain "numeric"
            $analysis.structure.header | Should -Contain "boolean"
            
            # VÃ©rifier les statistiques des colonnes
            $analysis.columns.numeric | Should -Not -BeNullOrEmpty
            $analysis.columns.numeric.detected_type | Should -Be "int"
            $analysis.columns.boolean | Should -Not -BeNullOrEmpty
            $analysis.columns.boolean.detected_type | Should -Be "boolean"
        }
        
        It "Analyse correctement un fichier YAML" {
            $outputPath = Join-Path -Path $analysisDir -ChildPath "yaml_analysis.json"
            $result = Get-FileAnalysis -FilePath $yamlSimplePath -Format "YAML" -OutputFile $outputPath
            
            $result | Should -Not -BeNullOrEmpty
            Test-Path -Path $outputPath | Should -Be $true
            
            # VÃ©rifier que le fichier d'analyse est valide
            $analysisContent = Get-Content -Path $outputPath -Raw
            $analysisContent | Should -Not -BeNullOrEmpty
            { $analysisContent | ConvertFrom-Json } | Should -Not -Throw
            
            # VÃ©rifier que l'analyse contient les informations attendues
            $analysis = $analysisContent | ConvertFrom-Json
            $analysis.file_info | Should -Not -BeNullOrEmpty
            $analysis.structure | Should -Not -BeNullOrEmpty
            $analysis.structure.type | Should -Be "dict"
            $analysis.structure.keys | Should -Contain "name"
            $analysis.structure.keys | Should -Contain "items"
        }
        
        It "Analyse correctement un fichier YAML complexe" {
            $outputPath = Join-Path -Path $analysisDir -ChildPath "yaml_complex_analysis.json"
            $result = Get-FileAnalysis -FilePath $yamlComplexPath -Format "YAML" -OutputFile $outputPath
            
            $result | Should -Not -BeNullOrEmpty
            Test-Path -Path $outputPath | Should -Be $true
            
            # VÃ©rifier que le fichier d'analyse est valide
            $analysisContent = Get-Content -Path $outputPath -Raw
            $analysisContent | Should -Not -BeNullOrEmpty
            { $analysisContent | ConvertFrom-Json } | Should -Not -Throw
            
            # VÃ©rifier que l'analyse contient les informations attendues
            $analysis = $analysisContent | ConvertFrom-Json
            $analysis.structure.type | Should -Be "dict"
            $analysis.structure.keys | Should -Contain "metadata"
            $analysis.structure.keys | Should -Contain "items"
            $analysis.structure.keys | Should -Contain "settings"
        }
    }
    
    Context "Tests de segmentation de fichier" {
        BeforeEach {
            # CrÃ©er un fichier CSV volumineux
            $largeCsvPath = Join-Path -Path $inputDir -ChildPath "large.csv"
            $largeCsvContent = "id,name,value`n"
            for ($i = 1; $i -le 1000; $i++) {
                $largeCsvContent += "$i,Item $i,Value $i`n"
            }
            Set-Content -Path $largeCsvPath -Value $largeCsvContent -Encoding UTF8
            
            # CrÃ©er un fichier YAML volumineux
            $largeYamlPath = Join-Path -Path $inputDir -ChildPath "large.yaml"
            $largeYamlContent = "items:`n"
            for ($i = 1; $i -le 1000; $i++) {
                $largeYamlContent += "  - id: $i`n    name: Item $i`n    value: Value $i`n"
            }
            Set-Content -Path $largeYamlPath -Value $largeYamlContent -Encoding UTF8
        }
        
        It "Segmente correctement un fichier CSV volumineux" {
            $segmentDir = Join-Path -Path $outputDir -ChildPath "csv_segments"
            New-Item -Path $segmentDir -ItemType Directory -Force | Out-Null
            
            $largeCsvPath = Join-Path -Path $inputDir -ChildPath "large.csv"
            $segments = Split-File -FilePath $largeCsvPath -Format "CSV" -OutputDir $segmentDir -ChunkSizeKB 10 -FilePrefix "csv_segment"
            
            $segments | Should -Not -BeNullOrEmpty
            $segments.Count | Should -BeGreaterThan 1
            
            # VÃ©rifier que les segments sont valides
            foreach ($segment in $segments) {
                Test-Path -Path $segment | Should -Be $true
                $isValid = Test-FileValidity -FilePath $segment -Format "CSV"
                $isValid | Should -Be $true
            }
        }
        
        It "Segmente correctement un fichier YAML volumineux" {
            $segmentDir = Join-Path -Path $outputDir -ChildPath "yaml_segments"
            New-Item -Path $segmentDir -ItemType Directory -Force | Out-Null
            
            $largeYamlPath = Join-Path -Path $inputDir -ChildPath "large.yaml"
            $segments = Split-File -FilePath $largeYamlPath -Format "YAML" -OutputDir $segmentDir -ChunkSizeKB 10 -FilePrefix "yaml_segment"
            
            $segments | Should -Not -BeNullOrEmpty
            $segments.Count | Should -BeGreaterThan 1
            
            # VÃ©rifier que les segments sont valides
            foreach ($segment in $segments) {
                Test-Path -Path $segment | Should -Be $true
                $isValid = Test-FileValidity -FilePath $segment -Format "YAML"
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
