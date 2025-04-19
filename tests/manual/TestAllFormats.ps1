# Script de test manuel pour tous les formats et la détection d'encodage

# Chemins des modules à tester
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$modulesPath = Join-Path -Path $projectRoot -ChildPath "modules"
$unifiedSegmenterPath = Join-Path -Path $modulesPath -ChildPath "UnifiedSegmenter.ps1"

# Importer le module
. $unifiedSegmenterPath

# Initialiser le segmenteur unifié
Write-Host "Initialisation du segmenteur unifié..."
$initResult = Initialize-UnifiedSegmenter
Write-Host "Initialisation réussie: $initResult"

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "AllFormatsTest"
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}
New-Item -Path $testDir -ItemType Directory -Force | Out-Null

# Créer des fichiers de test
$jsonFilePath = Join-Path -Path $testDir -ChildPath "test.json"
$xmlFilePath = Join-Path -Path $testDir -ChildPath "test.xml"
$csvFilePath = Join-Path -Path $testDir -ChildPath "test.csv"
$yamlFilePath = Join-Path -Path $testDir -ChildPath "test.yaml"
$textFilePath = Join-Path -Path $testDir -ChildPath "test.txt"
$jsonArrayPath = Join-Path -Path $testDir -ChildPath "array.json"
$outputDir = Join-Path -Path $testDir -ChildPath "output"
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

# Test 1: Détection de format
Write-Host "`n=== Test 1: Détection de format ==="
Write-Host "JSON: $(Get-FileFormat -FilePath $jsonFilePath)"
Write-Host "XML: $(Get-FileFormat -FilePath $xmlFilePath)"
Write-Host "CSV: $(Get-FileFormat -FilePath $csvFilePath)"
Write-Host "YAML: $(Get-FileFormat -FilePath $yamlFilePath)"
Write-Host "TEXT: $(Get-FileFormat -FilePath $textFilePath)"
Write-Host "JSON Array: $(Get-FileFormat -FilePath $jsonArrayPath)"

# Test 2: Détection d'encodage
Write-Host "`n=== Test 2: Détection d'encodage ==="
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

# JSON (objet) vers CSV
$jsonToCsvPath = Join-Path -Path $outputDir -ChildPath "json_to_csv.csv"
$jsonToCsvResult = Convert-FileFormat -InputFile $jsonFilePath -OutputFile $jsonToCsvPath -InputFormat "JSON" -OutputFormat "CSV"
Write-Host "JSON (objet) vers CSV: $jsonToCsvResult"
if ($jsonToCsvResult -and (Test-Path -Path $jsonToCsvPath)) {
    Write-Host "Contenu CSV:"
    Get-Content -Path $jsonToCsvPath | ForEach-Object { Write-Host "  $_" }
}

# JSON (tableau) vers CSV
$jsonArrayToCsvPath = Join-Path -Path $outputDir -ChildPath "jsonarray_to_csv.csv"
$jsonArrayToCsvResult = Convert-FileFormat -InputFile $jsonArrayPath -OutputFile $jsonArrayToCsvPath -InputFormat "JSON" -OutputFormat "CSV"
Write-Host "`nJSON (tableau) vers CSV: $jsonArrayToCsvResult"
if ($jsonArrayToCsvResult -and (Test-Path -Path $jsonArrayToCsvPath)) {
    Write-Host "Contenu CSV:"
    Get-Content -Path $jsonArrayToCsvPath | ForEach-Object { Write-Host "  $_" }
}

# JSON vers YAML
$jsonToYamlPath = Join-Path -Path $outputDir -ChildPath "json_to_yaml.yaml"
$jsonToYamlResult = Convert-FileFormat -InputFile $jsonFilePath -OutputFile $jsonToYamlPath -InputFormat "JSON" -OutputFormat "YAML"
Write-Host "`nJSON vers YAML: $jsonToYamlResult"
if ($jsonToYamlResult -and (Test-Path -Path $jsonToYamlPath)) {
    Write-Host "Contenu YAML:"
    Get-Content -Path $jsonToYamlPath | ForEach-Object { Write-Host "  $_" }
}

# CSV vers JSON
$csvToJsonPath = Join-Path -Path $outputDir -ChildPath "csv_to_json.json"
$csvToJsonResult = Convert-FileFormat -InputFile $csvFilePath -OutputFile $csvToJsonPath -InputFormat "CSV" -OutputFormat "JSON"
Write-Host "`nCSV vers JSON: $csvToJsonResult"
if ($csvToJsonResult -and (Test-Path -Path $csvToJsonPath)) {
    Write-Host "Contenu JSON:"
    Get-Content -Path $csvToJsonPath | ForEach-Object { Write-Host "  $_" }
}

# YAML vers JSON
$yamlToJsonPath = Join-Path -Path $outputDir -ChildPath "yaml_to_json.json"
$yamlToJsonResult = Convert-FileFormat -InputFile $yamlFilePath -OutputFile $yamlToJsonPath -InputFormat "YAML" -OutputFormat "JSON"
Write-Host "`nYAML vers JSON: $yamlToJsonResult"
if ($yamlToJsonResult -and (Test-Path -Path $yamlToJsonPath)) {
    Write-Host "Contenu JSON:"
    Get-Content -Path $yamlToJsonPath | ForEach-Object { Write-Host "  $_" }
}

# YAML vers CSV
$yamlToCsvPath = Join-Path -Path $outputDir -ChildPath "yaml_to_csv.csv"
$yamlToCsvResult = Convert-FileFormat -InputFile $yamlFilePath -OutputFile $yamlToCsvPath -InputFormat "YAML" -OutputFormat "CSV"
Write-Host "`nYAML vers CSV: $yamlToCsvResult"
if ($yamlToCsvResult -and (Test-Path -Path $yamlToCsvPath)) {
    Write-Host "Contenu CSV:"
    Get-Content -Path $yamlToCsvPath | ForEach-Object { Write-Host "  $_" }
}

# Test 5: Analyse de fichier
Write-Host "`n=== Test 5: Analyse de fichier ==="

# Analyse CSV
$csvAnalysisPath = Join-Path -Path $outputDir -ChildPath "csv_analysis.json"
$csvAnalysisResult = Get-FileAnalysis -FilePath $csvFilePath -Format "CSV" -OutputFile $csvAnalysisPath
Write-Host "Analyse CSV: $csvAnalysisResult"
if ($csvAnalysisResult -and (Test-Path -Path $csvAnalysisPath)) {
    Write-Host "Contenu de l'analyse CSV:"
    $csvAnalysis = Get-Content -Path $csvAnalysisPath -Raw | ConvertFrom-Json
    Write-Host "  Total des lignes: $($csvAnalysis.total_rows)"
    Write-Host "  Colonnes: $($csvAnalysis.columns)"
    Write-Host "  En-tête: $($csvAnalysis.header -join ', ')"
}

# Analyse YAML
$yamlAnalysisPath = Join-Path -Path $outputDir -ChildPath "yaml_analysis.json"
$yamlAnalysisResult = Get-FileAnalysis -FilePath $yamlFilePath -Format "YAML" -OutputFile $yamlAnalysisPath
Write-Host "`nAnalyse YAML: $yamlAnalysisResult"
if ($yamlAnalysisResult -and (Test-Path -Path $yamlAnalysisPath)) {
    Write-Host "Contenu de l'analyse YAML:"
    $yamlAnalysis = Get-Content -Path $yamlAnalysisPath -Raw | ConvertFrom-Json
    Write-Host "  Structure: $($yamlAnalysis.structure.type)"
    if ($yamlAnalysis.structure.keys) {
        Write-Host "  Clés: $($yamlAnalysis.structure.keys.PSObject.Properties.Name -join ', ')"
    }
}

# Test 6: Segmentation de fichier
Write-Host "`n=== Test 6: Segmentation de fichier ==="

# Segmentation CSV
$csvSegmentDir = Join-Path -Path $outputDir -ChildPath "csv_segments"
New-Item -Path $csvSegmentDir -ItemType Directory -Force | Out-Null
$csvSegmentResult = Split-File -FilePath $csvFilePath -Format "CSV" -OutputDir $csvSegmentDir -ChunkSizeKB 1
Write-Host "Segmentation CSV: $($csvSegmentResult.Count) segments créés"
if ($csvSegmentResult.Count -gt 0) {
    Write-Host "Segments CSV:"
    foreach ($segment in $csvSegmentResult) {
        Write-Host "  $segment"
    }
}

# Segmentation YAML
$yamlSegmentDir = Join-Path -Path $outputDir -ChildPath "yaml_segments"
New-Item -Path $yamlSegmentDir -ItemType Directory -Force | Out-Null
$yamlSegmentResult = Split-File -FilePath $yamlFilePath -Format "YAML" -OutputDir $yamlSegmentDir -ChunkSizeKB 1
Write-Host "`nSegmentation YAML: $($yamlSegmentResult.Count) segments créés"
if ($yamlSegmentResult.Count -gt 0) {
    Write-Host "Segments YAML:"
    foreach ($segment in $yamlSegmentResult) {
        Write-Host "  $segment"
    }
}

# Nettoyer
Write-Host "`nNettoyage des fichiers de test..."
Remove-Item -Path $testDir -Recurse -Force

Write-Host "`nTests terminés."
