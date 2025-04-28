# Exemples d'utilisation des fonctionnalités CSV et YAML
# Ce script contient des exemples d'utilisation des fonctionnalités CSV et YAML du module UnifiedSegmenter

# Importer le module UnifiedSegmenter
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$modulesPath = Join-Path -Path $projectRoot -ChildPath "modules"
$unifiedSegmenterPath = Join-Path -Path $modulesPath -ChildPath "UnifiedSegmenter.ps1"
. $unifiedSegmenterPath

# Initialiser le segmenteur unifié
$initResult = Initialize-UnifiedSegmenter
if (-not $initResult) {
    Write-Error "Erreur lors de l'initialisation du segmenteur unifié"
    return
}

# Créer un répertoire temporaire pour les exemples
$tempDir = Join-Path -Path $env:TEMP -ChildPath "UnifiedSegmenterExamples"
if (Test-Path -Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

# Créer des fichiers d'exemple
$csvFilePath = Join-Path -Path $tempDir -ChildPath "example.csv"
$yamlFilePath = Join-Path -Path $tempDir -ChildPath "example.yaml"
$jsonFilePath = Join-Path -Path $tempDir -ChildPath "example.json"
$jsonNestedFilePath = Join-Path -Path $tempDir -ChildPath "example_nested.json"
$outputDir = Join-Path -Path $tempDir -ChildPath "output"
New-Item -Path $outputDir -ItemType Directory -Force | Out-Null

# Créer un fichier CSV d'exemple
$csvContent = @"
id,name,value,description
1,Item 1,Value 1,"Description 1"
2,Item 2,Value 2,"Description 2"
3,Item 3,Value 3,"Description 3"
"@
Set-Content -Path $csvFilePath -Value $csvContent -Encoding UTF8

# Créer un fichier YAML d'exemple
$yamlContent = @"
name: Example Object
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

# Créer un fichier JSON d'exemple
$jsonContent = @{
    "name" = "Example Object"
    "items" = @(
        @{ "id" = 1; "value" = "Item 1"; "description" = "Description 1" },
        @{ "id" = 2; "value" = "Item 2"; "description" = "Description 2" },
        @{ "id" = 3; "value" = "Item 3"; "description" = "Description 3" }
    )
    "metadata" = @{
        "created" = "2025-06-06"
        "version" = "1.0.0"
    }
} | ConvertTo-Json -Depth 10
Set-Content -Path $jsonFilePath -Value $jsonContent -Encoding UTF8

# Créer un fichier JSON avec objets imbriqués
$jsonNestedContent = @{
    "name" = "John Doe"
    "age" = 30
    "address" = @{
        "street" = "123 Main St"
        "city" = "New York"
        "country" = "USA"
    }
    "phones" = @(
        "123-456-7890",
        "098-765-4321"
    )
} | ConvertTo-Json -Depth 10
Set-Content -Path $jsonNestedFilePath -Value $jsonNestedContent -Encoding UTF8

# Exemple 1 : Détection de format
Write-Host "`n=== Exemple 1 : Détection de format ===" -ForegroundColor Green
$csvFormat = Get-FileFormat -FilePath $csvFilePath
Write-Host "Format du fichier CSV: $csvFormat"

$yamlFormat = Get-FileFormat -FilePath $yamlFilePath
Write-Host "Format du fichier YAML: $yamlFormat"

$jsonFormat = Get-FileFormat -FilePath $jsonFilePath
Write-Host "Format du fichier JSON: $jsonFormat"

# Exemple 2 : Détection d'encodage
Write-Host "`n=== Exemple 2 : Détection d'encodage ===" -ForegroundColor Green
$csvEncoding = Get-FileEncoding -FilePath $csvFilePath
Write-Host "Encodage du fichier CSV: $($csvEncoding.encoding), Type: $($csvEncoding.file_type)"

$yamlEncoding = Get-FileEncoding -FilePath $yamlFilePath
Write-Host "Encodage du fichier YAML: $($yamlEncoding.encoding), Type: $($yamlEncoding.file_type)"

# Exemple 3 : Validation de fichier
Write-Host "`n=== Exemple 3 : Validation de fichier ===" -ForegroundColor Green
$csvValid = Test-FileValidity -FilePath $csvFilePath -Format "CSV"
Write-Host "Le fichier CSV est valide: $csvValid"

$yamlValid = Test-FileValidity -FilePath $yamlFilePath -Format "YAML"
Write-Host "Le fichier YAML est valide: $yamlValid"

# Exemple 4 : Conversion CSV vers JSON
Write-Host "`n=== Exemple 4 : Conversion CSV vers JSON ===" -ForegroundColor Green
$csvToJsonPath = Join-Path -Path $outputDir -ChildPath "csv_to_json.json"
$csvToJsonResult = Convert-FileFormat -InputFile $csvFilePath -OutputFile $csvToJsonPath -InputFormat "CSV" -OutputFormat "JSON"
Write-Host "Conversion CSV vers JSON réussie: $csvToJsonResult"
if ($csvToJsonResult) {
    Write-Host "Contenu du fichier JSON:"
    Get-Content -Path $csvToJsonPath | ForEach-Object { Write-Host "  $_" }
}

# Exemple 5 : Conversion YAML vers JSON
Write-Host "`n=== Exemple 5 : Conversion YAML vers JSON ===" -ForegroundColor Green
$yamlToJsonPath = Join-Path -Path $outputDir -ChildPath "yaml_to_json.json"
$yamlToJsonResult = Convert-FileFormat -InputFile $yamlFilePath -OutputFile $yamlToJsonPath -InputFormat "YAML" -OutputFormat "JSON"
Write-Host "Conversion YAML vers JSON réussie: $yamlToJsonResult"
if ($yamlToJsonResult) {
    Write-Host "Contenu du fichier JSON:"
    Get-Content -Path $yamlToJsonPath | ForEach-Object { Write-Host "  $_" }
}

# Exemple 6 : Conversion JSON vers CSV avec aplatissement des objets imbriqués
Write-Host "`n=== Exemple 6 : Conversion JSON vers CSV avec aplatissement des objets imbriqués ===" -ForegroundColor Green
$jsonToCsvFlattenedPath = Join-Path -Path $outputDir -ChildPath "json_to_csv_flattened.csv"
$jsonToCsvFlattenedResult = Convert-FileFormat -InputFile $jsonNestedFilePath -OutputFile $jsonToCsvFlattenedPath -InputFormat "JSON" -OutputFormat "CSV" -FlattenNestedObjects $true -NestedSeparator "_"
Write-Host "Conversion JSON vers CSV avec aplatissement réussie: $jsonToCsvFlattenedResult"
if ($jsonToCsvFlattenedResult) {
    Write-Host "Contenu du fichier CSV (aplati):"
    Get-Content -Path $jsonToCsvFlattenedPath | ForEach-Object { Write-Host "  $_" }
}

# Exemple 7 : Conversion JSON vers CSV sans aplatissement des objets imbriqués
Write-Host "`n=== Exemple 7 : Conversion JSON vers CSV sans aplatissement des objets imbriqués ===" -ForegroundColor Green
$jsonToCsvNonFlattenedPath = Join-Path -Path $outputDir -ChildPath "json_to_csv_non_flattened.csv"
$jsonToCsvNonFlattenedResult = Convert-FileFormat -InputFile $jsonNestedFilePath -OutputFile $jsonToCsvNonFlattenedPath -InputFormat "JSON" -OutputFormat "CSV" -FlattenNestedObjects $false
Write-Host "Conversion JSON vers CSV sans aplatissement réussie: $jsonToCsvNonFlattenedResult"
if ($jsonToCsvNonFlattenedResult) {
    Write-Host "Contenu du fichier CSV (non aplati):"
    Get-Content -Path $jsonToCsvNonFlattenedPath | ForEach-Object { Write-Host "  $_" }
}

# Exemple 8 : Analyse de fichier CSV
Write-Host "`n=== Exemple 8 : Analyse de fichier CSV ===" -ForegroundColor Green
$csvAnalysisPath = Join-Path -Path $outputDir -ChildPath "csv_analysis.json"
$csvAnalysisResult = Get-FileAnalysis -FilePath $csvFilePath -Format "CSV" -OutputFile $csvAnalysisPath
Write-Host "Analyse CSV enregistrée dans: $csvAnalysisResult"

# Charger et afficher l'analyse
$csvAnalysis = Get-Content -Path $csvAnalysisPath -Raw | ConvertFrom-Json
Write-Host "Informations sur le fichier CSV:"
Write-Host "  Taille du fichier: $($csvAnalysis.file_info.file_size_kb) KB"
Write-Host "  Nombre de lignes: $($csvAnalysis.structure.total_rows)"
Write-Host "  Nombre de colonnes: $($csvAnalysis.structure.total_columns)"
Write-Host "  En-tête: $($csvAnalysis.structure.header -join ', ')"
Write-Host "  Taux de remplissage: $($csvAnalysis.statistics.fill_rate)"

# Exemple 9 : Analyse de fichier YAML
Write-Host "`n=== Exemple 9 : Analyse de fichier YAML ===" -ForegroundColor Green
$yamlAnalysisPath = Join-Path -Path $outputDir -ChildPath "yaml_analysis.json"
$yamlAnalysisResult = Get-FileAnalysis -FilePath $yamlFilePath -Format "YAML" -OutputFile $yamlAnalysisPath
Write-Host "Analyse YAML enregistrée dans: $yamlAnalysisResult"

# Charger et afficher l'analyse
$yamlAnalysis = Get-Content -Path $yamlAnalysisPath -Raw | ConvertFrom-Json
Write-Host "Informations sur le fichier YAML:"
Write-Host "  Taille du fichier: $($yamlAnalysis.file_info.file_size_kb) KB"
Write-Host "  Type de structure: $($yamlAnalysis.structure.type)"
if ($yamlAnalysis.structure.type -eq "dict") {
    Write-Host "  Clés: $($yamlAnalysis.structure.keys -join ', ')"
    Write-Host "  Nombre de clés: $($yamlAnalysis.structure.key_count)"
}

# Exemple 10 : Segmentation de fichier CSV
Write-Host "`n=== Exemple 10 : Segmentation de fichier CSV ===" -ForegroundColor Green
$csvSegmentDir = Join-Path -Path $outputDir -ChildPath "csv_segments"
New-Item -Path $csvSegmentDir -ItemType Directory -Force | Out-Null
$csvSegmentResult = Split-File -FilePath $csvFilePath -Format "CSV" -OutputDir $csvSegmentDir -ChunkSizeKB 1
Write-Host "Segmentation CSV réussie: $($csvSegmentResult.Count) segments créés"
if ($csvSegmentResult.Count -gt 0) {
    Write-Host "Segments CSV:"
    foreach ($segment in $csvSegmentResult) {
        Write-Host "  $segment"
    }
}

# Exemple 11 : Segmentation de fichier YAML
Write-Host "`n=== Exemple 11 : Segmentation de fichier YAML ===" -ForegroundColor Green
$yamlSegmentDir = Join-Path -Path $outputDir -ChildPath "yaml_segments"
New-Item -Path $yamlSegmentDir -ItemType Directory -Force | Out-Null
$yamlSegmentResult = Split-File -FilePath $yamlFilePath -Format "YAML" -OutputDir $yamlSegmentDir -ChunkSizeKB 1
Write-Host "Segmentation YAML réussie: $($yamlSegmentResult.Count) segments créés"
if ($yamlSegmentResult.Count -gt 0) {
    Write-Host "Segments YAML:"
    foreach ($segment in $yamlSegmentResult) {
        Write-Host "  $segment"
    }
}

# Nettoyer
Write-Host "`nNettoyage des fichiers d'exemple..."
Remove-Item -Path $tempDir -Recurse -Force

Write-Host "`nExemples terminés."
