# Exemple d'utilisation de la façade de traitement de fichiers
# Ce script montre comment utiliser la façade de traitement de fichiers pour simplifier l'utilisation du module UnifiedSegmenter

# Importer la façade de traitement de fichiers
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$modulesPath = Join-Path -Path $projectRoot -ChildPath "modules"
$facadePath = Join-Path -Path $modulesPath -ChildPath "FileProcessingFacade.ps1"
. $facadePath

# Initialiser la façade
$initResult = Initialize-FileProcessingFacade
if (-not $initResult) {
    Write-Error "Erreur lors de l'initialisation de la façade de traitement de fichiers"
    return
}

# Créer un répertoire temporaire pour les exemples
$tempDir = Join-Path -Path $env:TEMP -ChildPath "FileProcessingFacadeExample"
if (Test-Path -Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

# Créer des fichiers d'exemple
$csvFilePath = Join-Path -Path $tempDir -ChildPath "example.csv"
$jsonFilePath = Join-Path -Path $tempDir -ChildPath "example.json"
$yamlFilePath = Join-Path -Path $tempDir -ChildPath "example.yaml"
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

# Exemple 1 : Obtenir des informations sur un fichier
Write-Host "`n=== Exemple 1 : Obtenir des informations sur un fichier ===" -ForegroundColor Green
$fileInfo = Get-FileInfo -FilePath $csvFilePath -IncludeEncoding
Write-Host "Informations sur le fichier CSV :"
$fileInfo | Format-List

# Exemple 2 : Obtenir des informations détaillées sur un fichier
Write-Host "`n=== Exemple 2 : Obtenir des informations détaillées sur un fichier ===" -ForegroundColor Green
$fileInfoDetailed = Get-FileInfo -FilePath $jsonFilePath -IncludeEncoding -IncludeAnalysis
Write-Host "Informations détaillées sur le fichier JSON :"
$fileInfoDetailed | Format-List Path, Name, Format, IsValid, SizeKB

Write-Host "`nAnalyse du fichier JSON :"
$fileInfoDetailed.Analysis | ConvertTo-Json -Depth 5

# Exemple 3 : Convertir un fichier
Write-Host "`n=== Exemple 3 : Convertir un fichier ===" -ForegroundColor Green
$csvToJsonPath = Join-Path -Path $outputDir -ChildPath "csv_to_json.json"
$conversionResult = Convert-File -InputFile $csvFilePath -OutputFile $csvToJsonPath -OutputFormat "JSON"
Write-Host "Conversion CSV vers JSON réussie : $conversionResult"

if ($conversionResult) {
    $jsonContent = Get-Content -Path $csvToJsonPath -Raw
    Write-Host "Contenu du fichier JSON :"
    Write-Host $jsonContent
}

# Exemple 4 : Segmenter un fichier
Write-Host "`n=== Exemple 4 : Segmenter un fichier ===" -ForegroundColor Green
$segmentDir = Join-Path -Path $outputDir -ChildPath "segments"
New-Item -Path $segmentDir -ItemType Directory -Force | Out-Null

# Créer un fichier CSV plus volumineux
$largeCsvContent = "id,name,value,description`n"
for ($i = 1; $i -le 1000; $i++) {
    $largeCsvContent += "$i,Item $i,Value $i,`"Description $i`"`n"
}
$largeCsvPath = Join-Path -Path $tempDir -ChildPath "large.csv"
Set-Content -Path $largeCsvPath -Value $largeCsvContent -Encoding UTF8

# Segmenter le fichier
$segmentResult = Split-FileIntoChunks -FilePath $largeCsvPath -OutputDir $segmentDir -ChunkSizeKB 10
Write-Host "Segmentation réussie : $($segmentResult.Count) segments créés"

if ($segmentResult.Count -gt 0) {
    Write-Host "Segments créés :"
    $segmentResult | ForEach-Object { Write-Host "  $_" }
}

# Exemple 5 : Générer un rapport d'analyse
Write-Host "`n=== Exemple 5 : Générer un rapport d'analyse ===" -ForegroundColor Green
$analysisJsonPath = Join-Path -Path $outputDir -ChildPath "analysis.json"
$analysisResult = Get-FileAnalysisReport -FilePath $yamlFilePath -Format "YAML" -OutputFile $analysisJsonPath
Write-Host "Analyse YAML enregistrée dans : $analysisResult"

# Générer un rapport HTML
$htmlReportPath = Get-FileAnalysisReport -FilePath $yamlFilePath -Format "YAML" -AsHtml
Write-Host "Rapport HTML généré : $htmlReportPath"

# Ouvrir le rapport HTML
if ($htmlReportPath) {
    Start-Process $htmlReportPath
}

# Exemple 6 : Valider un fichier
Write-Host "`n=== Exemple 6 : Valider un fichier ===" -ForegroundColor Green
$isValid = Test-FileIsValid -FilePath $jsonFilePath
Write-Host "Le fichier JSON est valide : $isValid"

# Créer un fichier JSON invalide
$invalidJsonPath = Join-Path -Path $tempDir -ChildPath "invalid.json"
$invalidJsonContent = @"
{
    "name": "Invalid JSON",
    "items": [
        {"id": 1, "value": "Item 1"},
        {"id": 2, "value": "Item 2"},
        {"id": 3, "value": "Item 3"
    ]
}
"@
Set-Content -Path $invalidJsonPath -Value $invalidJsonContent -Encoding UTF8

$isInvalid = Test-FileIsValid -FilePath $invalidJsonPath
Write-Host "Le fichier JSON invalide est valide : $isInvalid"

# Nettoyer
Write-Host "`nNettoyage des fichiers d'exemple..."
Remove-Item -Path $tempDir -Recurse -Force

Write-Host "`nExemples terminés."
