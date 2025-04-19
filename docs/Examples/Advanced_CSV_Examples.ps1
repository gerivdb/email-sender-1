# Exemples avancés d'utilisation des fonctionnalités CSV
# Ce script contient des exemples avancés d'utilisation des fonctionnalités CSV du module UnifiedSegmenter

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
$tempDir = Join-Path -Path $env:TEMP -ChildPath "AdvancedCsvExamples"
if (Test-Path -Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

# Créer des fichiers d'exemple
$csvFilePath = Join-Path -Path $tempDir -ChildPath "example.csv"
$csvLargeFilePath = Join-Path -Path $tempDir -ChildPath "large_example.csv"
$csvInvalidFilePath = Join-Path -Path $tempDir -ChildPath "invalid_example.csv"
$outputDir = Join-Path -Path $tempDir -ChildPath "output"
New-Item -Path $outputDir -ItemType Directory -Force | Out-Null

# Créer un fichier CSV d'exemple
$csvContent = @"
id,name,value,description,date,number,boolean,email,url
1,Item 1,Value 1,"Description 1",2025-01-01,10.5,true,user1@example.com,https://example.com/1
2,Item 2,Value 2,"Description 2",2025-01-02,20.5,false,user2@example.com,https://example.com/2
3,Item 3,Value 3,"Description 3",2025-01-03,30.5,true,user3@example.com,https://example.com/3
4,Item 4,Value 4,"Description 4",2025-01-04,40.5,false,user4@example.com,https://example.com/4
5,Item 5,Value 5,"Description 5",2025-01-05,50.5,true,user5@example.com,https://example.com/5
"@
Set-Content -Path $csvFilePath -Value $csvContent -Encoding UTF8

# Créer un fichier CSV invalide
$csvInvalidContent = @"
id,name,value,description
1,Item 1,Value 1,"Description 1"
2,Item 2,"Description 2"
3,Item 3,Value 3,"Description 3"
"@
Set-Content -Path $csvInvalidFilePath -Value $csvInvalidContent -Encoding UTF8

# Créer un fichier CSV volumineux
$csvLargeContent = "id,name,value,description,date,number,boolean,email,url`n"
for ($i = 1; $i -le 1000; $i++) {
    $csvLargeContent += "$i,Item $i,Value $i,`"Description $i`",2025-01-$($i % 28 + 1),$($i * 1.5),$($i % 2 -eq 0),user$i@example.com,https://example.com/$i`n"
}
Set-Content -Path $csvLargeFilePath -Value $csvLargeContent -Encoding UTF8

# Exemple 1 : Validation avancée de fichier CSV
Write-Host "`n=== Exemple 1 : Validation avancée de fichier CSV ===" -ForegroundColor Green
Write-Host "Validation d'un fichier CSV valide..."
$isValid = Test-FileValidity -FilePath $csvFilePath -Format "CSV"
Write-Host "Le fichier CSV est valide: $isValid"

Write-Host "`nValidation d'un fichier CSV invalide..."
$isInvalid = Test-FileValidity -FilePath $csvInvalidFilePath -Format "CSV"
Write-Host "Le fichier CSV est valide: $isInvalid"

# Exemple 2 : Analyse détaillée d'un fichier CSV
Write-Host "`n=== Exemple 2 : Analyse détaillée d'un fichier CSV ===" -ForegroundColor Green
$csvAnalysisPath = Join-Path -Path $outputDir -ChildPath "csv_analysis.json"
$csvAnalysisResult = Get-FileAnalysis -FilePath $csvFilePath -Format "CSV" -OutputFile $csvAnalysisPath
Write-Host "Analyse CSV enregistrée dans: $csvAnalysisResult"

# Créer un script Python pour analyser le fichier CSV
$pythonScriptPath = Join-Path -Path $tempDir -ChildPath "analyze_csv.py"
$pythonScript = @"
import json
import sys

# Charger l'analyse CSV
with open(r'$csvAnalysisPath', 'r', encoding='utf-8') as f:
    analysis = json.load(f)

# Afficher les informations générales
print("Informations générales:")
print(f"  Taille du fichier: {analysis['file_info']['file_size_kb']:.2f} KB")
print(f"  Encodage: {analysis['file_info']['encoding']}")
print(f"  Nombre de lignes: {analysis['structure']['total_rows']}")
print(f"  Nombre de colonnes: {analysis['structure']['total_columns']}")
print(f"  En-tête: {', '.join(analysis['structure']['header'])}")
print(f"  Taux de remplissage: {analysis['statistics']['fill_rate']:.2%}")

# Afficher les statistiques par colonne
print("\nStatistiques par colonne:")
for column, stats in analysis['columns'].items():
    print(f"  Colonne '{column}':")
    print(f"    Type détecté: {stats['detected_type']}")
    print(f"    Nombre de valeurs: {stats['count']}")
    print(f"    Valeurs vides: {stats['empty_count']} ({stats['empty_count'] / stats['count']:.2%})")
    print(f"    Valeurs uniques: {stats['unique_count']} ({stats['unique_count'] / stats['count']:.2%})")
    
    # Afficher les statistiques spécifiques au type
    if stats['detected_type'] in ('int', 'float') and 'min' in stats:
        print(f"    Min: {stats['min']}")
        print(f"    Max: {stats['max']}")
        print(f"    Moyenne: {stats['mean']}")
        print(f"    Médiane: {stats['median']}")
    
    # Afficher les valeurs les plus fréquentes
    if 'most_common' in stats:
        print("    Valeurs les plus fréquentes:")
        for value, count in stats['most_common']:
            print(f"      '{value}': {count} fois")
"@
Set-Content -Path $pythonScriptPath -Value $pythonScript -Encoding UTF8

# Exécuter le script Python
Write-Host "`nAnalyse détaillée du fichier CSV:"
& python $pythonScriptPath

# Exemple 3 : Segmentation d'un fichier CSV volumineux
Write-Host "`n=== Exemple 3 : Segmentation d'un fichier CSV volumineux ===" -ForegroundColor Green
$csvSegmentDir = Join-Path -Path $outputDir -ChildPath "csv_segments"
New-Item -Path $csvSegmentDir -ItemType Directory -Force | Out-Null
$csvSegmentResult = Split-File -FilePath $csvLargeFilePath -Format "CSV" -OutputDir $csvSegmentDir -ChunkSizeKB 10
Write-Host "Segmentation CSV réussie: $($csvSegmentResult.Count) segments créés"

# Analyser chaque segment
Write-Host "`nAnalyse des segments:"
$segmentStats = @()
foreach ($segment in $csvSegmentResult) {
    $segmentName = Split-Path -Leaf $segment
    $segmentSize = (Get-Item -Path $segment).Length / 1KB
    $segmentLines = (Get-Content -Path $segment).Count
    
    $segmentStat = [PSCustomObject]@{
        Segment = $segmentName
        SizeKB = [math]::Round($segmentSize, 2)
        Lines = $segmentLines
    }
    
    $segmentStats += $segmentStat
}

$segmentStats | Format-Table -AutoSize

# Exemple 4 : Traitement par lots d'un fichier CSV volumineux
Write-Host "`n=== Exemple 4 : Traitement par lots d'un fichier CSV volumineux ===" -ForegroundColor Green
Write-Host "Traitement de chaque segment..."

$processedDir = Join-Path -Path $outputDir -ChildPath "processed"
New-Item -Path $processedDir -ItemType Directory -Force | Out-Null

foreach ($segment in $csvSegmentResult) {
    $segmentName = Split-Path -Leaf $segment
    Write-Host "  Traitement du segment: $segmentName"
    
    # Convertir le segment en JSON
    $jsonOutputPath = Join-Path -Path $processedDir -ChildPath "$([System.IO.Path]::GetFileNameWithoutExtension($segmentName)).json"
    $conversionResult = Convert-FileFormat -InputFile $segment -OutputFile $jsonOutputPath -InputFormat "CSV" -OutputFormat "JSON"
    
    if ($conversionResult) {
        Write-Host "    Conversion réussie: $segment -> $jsonOutputPath"
    } else {
        Write-Host "    Échec de la conversion: $segment -> $jsonOutputPath"
    }
}

# Exemple 5 : Fusion de fichiers CSV
Write-Host "`n=== Exemple 5 : Fusion de fichiers CSV ===" -ForegroundColor Green
$mergedCsvPath = Join-Path -Path $outputDir -ChildPath "merged.csv"

# Créer un script PowerShell pour fusionner les fichiers CSV
$mergeScriptPath = Join-Path -Path $tempDir -ChildPath "merge_csv.ps1"
$mergeScript = @"
# Script pour fusionner des fichiers CSV
param (
    [Parameter(Mandatory = `$true)]
    [string[]]`$InputFiles,
    
    [Parameter(Mandatory = `$true)]
    [string]`$OutputFile
)

# Vérifier que les fichiers d'entrée existent
foreach (`$file in `$InputFiles) {
    if (-not (Test-Path -Path `$file)) {
        Write-Error "Le fichier n'existe pas: `$file"
        return
    }
}

# Lire l'en-tête du premier fichier
`$header = Get-Content -Path `$InputFiles[0] -TotalCount 1

# Écrire l'en-tête dans le fichier de sortie
Set-Content -Path `$OutputFile -Value `$header -Encoding UTF8

# Ajouter le contenu de chaque fichier (sans l'en-tête)
foreach (`$file in `$InputFiles) {
    `$content = Get-Content -Path `$file | Select-Object -Skip 1
    Add-Content -Path `$OutputFile -Value `$content -Encoding UTF8
}

Write-Host "Fusion réussie: `$(`$InputFiles.Count) fichiers fusionnés dans `$OutputFile"
"@
Set-Content -Path $mergeScriptPath -Value $mergeScript -Encoding UTF8

# Exécuter le script de fusion
& $mergeScriptPath -InputFiles $csvSegmentResult -OutputFile $mergedCsvPath

# Vérifier que le fichier fusionné est valide
$isMergedValid = Test-FileValidity -FilePath $mergedCsvPath -Format "CSV"
Write-Host "Le fichier CSV fusionné est valide: $isMergedValid"

# Comparer le fichier fusionné avec le fichier original
$originalLines = (Get-Content -Path $csvLargeFilePath).Count
$mergedLines = (Get-Content -Path $mergedCsvPath).Count
Write-Host "Lignes dans le fichier original: $originalLines"
Write-Host "Lignes dans le fichier fusionné: $mergedLines"

# Nettoyer
Write-Host "`nNettoyage des fichiers d'exemple..."
Remove-Item -Path $tempDir -Recurse -Force

Write-Host "`nExemples terminés."
