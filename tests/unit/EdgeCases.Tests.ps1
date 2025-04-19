#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour les cas limites et les erreurs.
.DESCRIPTION
    Ce script contient des tests unitaires pour les cas limites et les erreurs
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
$testTempDir = Join-Path -Path $env:TEMP -ChildPath "EdgeCasesTests"
if (Test-Path -Path $testTempDir) {
    Remove-Item -Path $testTempDir -Recurse -Force
}
New-Item -Path $testTempDir -ItemType Directory -Force | Out-Null

# Créer des fichiers de test
$emptyFilePath = Join-Path -Path $testTempDir -ChildPath "empty.txt"
$binaryFilePath = Join-Path -Path $testTempDir -ChildPath "binary.bin"
$largeFilePath = Join-Path -Path $testTempDir -ChildPath "large.json"
$invalidJsonPath = Join-Path -Path $testTempDir -ChildPath "invalid.json"
$invalidXmlPath = Join-Path -Path $testTempDir -ChildPath "invalid.xml"
$invalidCsvPath = Join-Path -Path $testTempDir -ChildPath "invalid.csv"
$invalidYamlPath = Join-Path -Path $testTempDir -ChildPath "invalid.yaml"
$outputDir = Join-Path -Path $testTempDir -ChildPath "output"
New-Item -Path $outputDir -ItemType Directory -Force | Out-Null

# Créer un fichier vide
Set-Content -Path $emptyFilePath -Value "" -Encoding UTF8

# Créer un fichier binaire
$binaryData = [byte[]]@(0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09)
[System.IO.File]::WriteAllBytes($binaryFilePath, $binaryData)

# Créer un fichier JSON volumineux
$largeJsonContent = @{
    "array" = (1..10000 | ForEach-Object { @{ "id" = $_; "value" = "Value $_" } })
} | ConvertTo-Json -Depth 10
Set-Content -Path $largeFilePath -Value $largeJsonContent -Encoding UTF8

# Créer un fichier JSON invalide
$invalidJsonContent = @"
{
    "name": "Invalid JSON",
    "value": 123,
    "array": [1, 2, 3,
    "missing": "closing bracket"
}
"@
Set-Content -Path $invalidJsonPath -Value $invalidJsonContent -Encoding UTF8

# Créer un fichier XML invalide
$invalidXmlContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<root>
    <name>Invalid XML</name>
    <value>123</value>
    <array>
        <item>1</item>
        <item>2</item>
        <item>3</item>
    </array>
    <missing>closing tag
</root>
"@
Set-Content -Path $invalidXmlPath -Value $invalidXmlContent -Encoding UTF8

# Créer un fichier CSV invalide
$invalidCsvContent = @"
id,name,value
1,Item 1,Value 1
2,Item 2,Value 2,Extra Column
3,Item 3
"@
Set-Content -Path $invalidCsvPath -Value $invalidCsvContent -Encoding UTF8

# Créer un fichier YAML invalide
$invalidYamlContent = @"
name: Invalid YAML
items:
  - id: 1
    name: Item 1
  - id: 2
    name: Item 2
  - id: 3
  name: Item 3  # Indentation incorrecte
"@
Set-Content -Path $invalidYamlPath -Value $invalidYamlContent -Encoding UTF8

# Définir les tests
Describe "Tests des cas limites et des erreurs" {
    BeforeAll {
        # Importer le module UnifiedSegmenter
        . $unifiedSegmenterPath
        
        # Initialiser le segmenteur unifié
        $initResult = Initialize-UnifiedSegmenter
        $initResult | Should -Be $true
    }
    
    Context "Tests avec des fichiers vides" {
        It "Détecte correctement un fichier vide" {
            $format = Get-FileFormat -FilePath $emptyFilePath
            $format | Should -Be "TEXT"
        }
        
        It "Valide correctement un fichier vide comme TEXT" {
            $isValid = Test-FileValidity -FilePath $emptyFilePath -Format "TEXT"
            $isValid | Should -Be $true
        }
        
        It "Échoue à valider un fichier vide comme JSON" {
            $isValid = Test-FileValidity -FilePath $emptyFilePath -Format "JSON"
            $isValid | Should -Be $false
        }
        
        It "Échoue à valider un fichier vide comme XML" {
            $isValid = Test-FileValidity -FilePath $emptyFilePath -Format "XML"
            $isValid | Should -Be $false
        }
        
        It "Échoue à valider un fichier vide comme CSV" {
            $isValid = Test-FileValidity -FilePath $emptyFilePath -Format "CSV"
            $isValid | Should -Be $false
        }
        
        It "Échoue à valider un fichier vide comme YAML" {
            $isValid = Test-FileValidity -FilePath $emptyFilePath -Format "YAML"
            $isValid | Should -Be $false
        }
    }
    
    Context "Tests avec des fichiers binaires" {
        It "Détecte correctement un fichier binaire" {
            $format = Get-FileFormat -FilePath $binaryFilePath -UseEncodingDetector
            $format | Should -Be "TEXT"  # Les fichiers binaires sont traités comme du texte par défaut
        }
        
        It "Échoue à valider un fichier binaire comme JSON" {
            $isValid = Test-FileValidity -FilePath $binaryFilePath -Format "JSON"
            $isValid | Should -Be $false
        }
        
        It "Échoue à valider un fichier binaire comme XML" {
            $isValid = Test-FileValidity -FilePath $binaryFilePath -Format "XML"
            $isValid | Should -Be $false
        }
        
        It "Échoue à valider un fichier binaire comme CSV" {
            $isValid = Test-FileValidity -FilePath $binaryFilePath -Format "CSV"
            $isValid | Should -Be $false
        }
        
        It "Échoue à valider un fichier binaire comme YAML" {
            $isValid = Test-FileValidity -FilePath $binaryFilePath -Format "YAML"
            $isValid | Should -Be $false
        }
    }
    
    Context "Tests avec des fichiers volumineux" {
        It "Valide correctement un fichier JSON volumineux" {
            $isValid = Test-FileValidity -FilePath $largeFilePath -Format "JSON"
            $isValid | Should -Be $true
        }
        
        It "Segmente correctement un fichier JSON volumineux" {
            $segmentDir = Join-Path -Path $outputDir -ChildPath "large_segments"
            New-Item -Path $segmentDir -ItemType Directory -Force | Out-Null
            
            $result = Split-File -FilePath $largeFilePath -Format "JSON" -OutputDir $segmentDir -ChunkSizeKB 10
            $result.Count | Should -BeGreaterThan 0
            
            # Vérifier que chaque segment est un JSON valide
            foreach ($segment in $result) {
                $isValid = Test-FileValidity -FilePath $segment -Format "JSON"
                $isValid | Should -Be $true
            }
        }
    }
    
    Context "Tests avec des fichiers invalides" {
        It "Détecte correctement un fichier JSON invalide" {
            $isValid = Test-FileValidity -FilePath $invalidJsonPath -Format "JSON"
            $isValid | Should -Be $false
        }
        
        It "Détecte correctement un fichier XML invalide" {
            $isValid = Test-FileValidity -FilePath $invalidXmlPath -Format "XML"
            $isValid | Should -Be $false
        }
        
        It "Détecte correctement un fichier CSV invalide" {
            $isValid = Test-FileValidity -FilePath $invalidCsvPath -Format "CSV"
            $isValid | Should -Be $false
        }
        
        It "Détecte correctement un fichier YAML invalide" {
            $isValid = Test-FileValidity -FilePath $invalidYamlPath -Format "YAML"
            $isValid | Should -Be $false
        }
    }
    
    Context "Tests avec des chemins de fichier invalides" {
        It "Échoue correctement avec un chemin de fichier inexistant" {
            $nonExistentPath = Join-Path -Path $testTempDir -ChildPath "non_existent.txt"
            { Get-FileFormat -FilePath $nonExistentPath } | Should -Throw
        }
        
        It "Échoue correctement avec un format invalide" {
            { Test-FileValidity -FilePath $emptyFilePath -Format "INVALID" } | Should -Throw
        }
    }
    
    Context "Tests de conversion avec des fichiers invalides" {
        It "Échoue correctement à convertir un fichier JSON invalide" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "invalid_json_to_xml.xml"
            $result = Convert-FileFormat -InputFile $invalidJsonPath -OutputFile $outputPath -InputFormat "JSON" -OutputFormat "XML"
            $result | Should -Be $false
        }
        
        It "Échoue correctement à convertir un fichier XML invalide" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "invalid_xml_to_json.json"
            $result = Convert-FileFormat -InputFile $invalidXmlPath -OutputFile $outputPath -InputFormat "XML" -OutputFormat "JSON"
            $result | Should -Be $false
        }
        
        It "Échoue correctement à convertir un fichier CSV invalide" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "invalid_csv_to_json.json"
            $result = Convert-FileFormat -InputFile $invalidCsvPath -OutputFile $outputPath -InputFormat "CSV" -OutputFormat "JSON"
            $result | Should -Be $false
        }
        
        It "Échoue correctement à convertir un fichier YAML invalide" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "invalid_yaml_to_json.json"
            $result = Convert-FileFormat -InputFile $invalidYamlPath -OutputFile $outputPath -InputFormat "YAML" -OutputFormat "JSON"
            $result | Should -Be $false
        }
    }
    
    AfterAll {
        # Nettoyer les fichiers de test
        if (Test-Path -Path $testTempDir) {
            Remove-Item -Path $testTempDir -Recurse -Force
        }
    }
}
