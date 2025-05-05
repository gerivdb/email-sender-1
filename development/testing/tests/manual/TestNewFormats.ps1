# Script de test manuel pour les nouveaux formats et la dÃ©tection d'encodage

# Chemins des modules Ã  tester
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$modulesPath = Join-Path -Path $projectRoot -ChildPath "modules"
$unifiedSegmenterPath = Join-Path -Path $modulesPath -ChildPath "UnifiedSegmenter.ps1"

# Importer le module
. $unifiedSegmenterPath

# Initialiser le segmenteur unifiÃ©
Write-Host "Initialisation du segmenteur unifiÃ©..."
$initResult = Initialize-UnifiedSegmenter
Write-Host "Initialisation rÃ©ussie: $initResult"

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "ManualTest"
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}
New-Item -Path $testDir -ItemType Directory -Force | Out-Null

# CrÃ©er des fichiers de test
$jsonFilePath = Join-Path -Path $testDir -ChildPath "test.json"
$xmlFilePath = Join-Path -Path $testDir -ChildPath "test.xml"
$csvFilePath = Join-Path -Path $testDir -ChildPath "test.csv"
$yamlFilePath = Join-Path -Path $testDir -ChildPath "test.yaml"
$outputDir = Join-Path -Path $testDir -ChildPath "output"

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
metadata:
  created: 2025-06-06
  version: 1.0.0
"@
Set-Content -Path $yamlFilePath -Value $yamlContent -Encoding UTF8

# Test 1: DÃ©tection de format
Write-Host "`n=== Test 1: DÃ©tection de format ==="
Write-Host "JSON: $(Get-FileFormat -FilePath $jsonFilePath)"
Write-Host "XML: $(Get-FileFormat -FilePath $xmlFilePath)"
Write-Host "CSV: $(Get-FileFormat -FilePath $csvFilePath)"
Write-Host "YAML: $(Get-FileFormat -FilePath $yamlFilePath)"

# Test 2: DÃ©tection d'encodage
Write-Host "`n=== Test 2: DÃ©tection d'encodage ==="
$jsonEncoding = Get-FileEncoding -FilePath $jsonFilePath
Write-Host "JSON Encoding: $($jsonEncoding.encoding), Type: $($jsonEncoding.file_type)"

$xmlEncoding = Get-FileEncoding -FilePath $xmlFilePath
Write-Host "XML Encoding: $($xmlEncoding.encoding), Type: $($xmlEncoding.file_type)"

$csvEncoding = Get-FileEncoding -FilePath $csvFilePath
Write-Host "CSV Encoding: $($csvEncoding.encoding), Type: $($csvEncoding.file_type)"

$yamlEncoding = Get-FileEncoding -FilePath $yamlFilePath
Write-Host "YAML Encoding: $($yamlEncoding.encoding), Type: $($yamlEncoding.file_type)"

# Test 3: Validation de fichier
Write-Host "`n=== Test 3: Validation de fichier ==="
Write-Host "JSON valide: $(Test-FileValidity -FilePath $jsonFilePath -Format 'JSON')"
Write-Host "XML valide: $(Test-FileValidity -FilePath $xmlFilePath -Format 'XML')"
Write-Host "CSV valide: $(Test-FileValidity -FilePath $csvFilePath -Format 'CSV')"
Write-Host "YAML valide: $(Test-FileValidity -FilePath $yamlFilePath -Format 'YAML')"

# Test 4: Conversion entre formats
Write-Host "`n=== Test 4: Conversion entre formats ==="

# JSON vers CSV
$jsonToCsvPath = Join-Path -Path $testDir -ChildPath "json_to_csv.csv"
$jsonToCsvResult = Convert-FileFormat -InputFile $jsonFilePath -OutputFile $jsonToCsvPath -InputFormat "JSON" -OutputFormat "CSV"
Write-Host "JSON vers CSV: $jsonToCsvResult"
if ($jsonToCsvResult) {
    Write-Host "Contenu CSV:"
    Get-Content -Path $jsonToCsvPath | ForEach-Object { Write-Host "  $_" }
}

# JSON vers YAML
$jsonToYamlPath = Join-Path -Path $testDir -ChildPath "json_to_yaml.yaml"
$jsonToYamlResult = Convert-FileFormat -InputFile $jsonFilePath -OutputFile $jsonToYamlPath -InputFormat "JSON" -OutputFormat "YAML"
Write-Host "`nJSON vers YAML: $jsonToYamlResult"
if ($jsonToYamlResult) {
    Write-Host "Contenu YAML:"
    Get-Content -Path $jsonToYamlPath | ForEach-Object { Write-Host "  $_" }
}

# CSV vers JSON
$csvToJsonPath = Join-Path -Path $testDir -ChildPath "csv_to_json.json"
$csvToJsonResult = Convert-FileFormat -InputFile $csvFilePath -OutputFile $csvToJsonPath -InputFormat "CSV" -OutputFormat "JSON"
Write-Host "`nCSV vers JSON: $csvToJsonResult"
if ($csvToJsonResult) {
    Write-Host "Contenu JSON:"
    Get-Content -Path $csvToJsonPath | ForEach-Object { Write-Host "  $_" }
}

# YAML vers JSON
$yamlToJsonPath = Join-Path -Path $testDir -ChildPath "yaml_to_json.json"
$yamlToJsonResult = Convert-FileFormat -InputFile $yamlFilePath -OutputFile $yamlToJsonPath -InputFormat "YAML" -OutputFormat "JSON"
Write-Host "`nYAML vers JSON: $yamlToJsonResult"
if ($yamlToJsonResult) {
    Write-Host "Contenu JSON:"
    Get-Content -Path $yamlToJsonPath | ForEach-Object { Write-Host "  $_" }
}

# Nettoyer
Write-Host "`nNettoyage des fichiers de test..."
Remove-Item -Path $testDir -Recurse -Force

Write-Host "`nTests terminÃ©s."
