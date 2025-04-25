# Exemple d'utilisation du traitement parallèle
# Ce script montre comment utiliser le module ParallelProcessing pour traiter des fichiers en parallèle

# Importer le module ParallelProcessing
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$modulesPath = Join-Path -Path $projectRoot -ChildPath "modules"
$parallelProcessingPath = Join-Path -Path $modulesPath -ChildPath "ParallelProcessing.ps1"
. $parallelProcessingPath

# Créer un répertoire temporaire pour les exemples
$tempDir = Join-Path -Path $env:TEMP -ChildPath "ParallelProcessingExample"
if (Test-Path -Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

# Créer des sous-répertoires
$inputDir = Join-Path -Path $tempDir -ChildPath "input"
$outputDir = Join-Path -Path $tempDir -ChildPath "output"
$analysisDir = Join-Path -Path $tempDir -ChildPath "analysis"
New-Item -Path $inputDir -ItemType Directory -Force | Out-Null
New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
New-Item -Path $analysisDir -ItemType Directory -Force | Out-Null

# Créer plusieurs fichiers CSV d'exemple
Write-Host "Création de fichiers CSV d'exemple..."
$csvFiles = @()
for ($i = 1; $i -le 5; $i++) {
    $csvPath = Join-Path -Path $inputDir -ChildPath "data$i.csv"
    $csvContent = "id,name,value,description`n"

    # Ajouter des lignes au CSV
    for ($j = 1; $j -le 100; $j++) {
        $id = ($i - 1) * 100 + $j
        $csvContent += "$id,Item $id,Value $id,`"Description for item $id`"`n"
    }

    Set-Content -Path $csvPath -Value $csvContent -Encoding UTF8
    $csvFiles += $csvPath
}

# Créer plusieurs fichiers JSON d'exemple
Write-Host "Création de fichiers JSON d'exemple..."
$jsonFiles = @()
for ($i = 1; $i -le 5; $i++) {
    $jsonPath = Join-Path -Path $inputDir -ChildPath "data$i.json"

    # Créer un objet JSON
    $jsonObject = @{
        "name"  = "Data Set $i"
        "items" = @()
    }

    # Ajouter des éléments à l'objet JSON
    for ($j = 1; $j -le 100; $j++) {
        $id = ($i - 1) * 100 + $j
        $jsonObject.items += @{
            "id"          = $id
            "name"        = "Item $id"
            "value"       = "Value $id"
            "description" = "Description for item $id"
            "metadata"    = @{
                "created"  = "2025-06-06"
                "category" = "Category $($j % 5 + 1)"
                "tags"     = @("tag1", "tag2", "tag$($j % 10 + 1)")
            }
        }
    }

    $jsonObject | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8
    $jsonFiles += $jsonPath
}

# Exemple 1 : Conversion parallèle de fichiers CSV en JSON
Write-Host "`n=== Exemple 1 : Conversion parallèle de fichiers CSV en JSON ===" -ForegroundColor Green
$startTime = Get-Date
$csvToJsonResults = Convert-FilesInParallel -InputFiles $csvFiles -OutputDir $outputDir -InputFormat "CSV" -OutputFormat "JSON" -ThrottleLimit 3
$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

Write-Host "Conversion terminée en $duration secondes"
Write-Host "Résultats de la conversion :"
$csvToJsonResults | Format-Table -Property InputFile, OutputFile, Success

# Exemple 2 : Conversion parallèle de fichiers JSON en YAML
Write-Host "`n=== Exemple 2 : Conversion parallèle de fichiers JSON en YAML ===" -ForegroundColor Green
$startTime = Get-Date
$jsonToYamlResults = Convert-FilesInParallel -InputFiles $jsonFiles -OutputDir $outputDir -InputFormat "JSON" -OutputFormat "YAML" -ThrottleLimit 3
$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

Write-Host "Conversion terminée en $duration secondes"
Write-Host "Résultats de la conversion :"
$jsonToYamlResults | Format-Table -Property InputFile, OutputFile, Success

# Exemple 3 : Analyse parallèle de fichiers CSV
Write-Host "`n=== Exemple 3 : Analyse parallèle de fichiers CSV ===" -ForegroundColor Green
$startTime = Get-Date
$csvAnalysisResults = Get-FileAnalysisInParallel -FilePaths $csvFiles -Format "CSV" -OutputDir $analysisDir -ThrottleLimit 3
$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

Write-Host "Analyse terminée en $duration secondes"
Write-Host "Résultats de l'analyse :"
$csvAnalysisResults | Format-Table -Property InputFile, OutputFile, Format, Success

# Exemple 4 : Analyse parallèle de fichiers JSON
Write-Host "`n=== Exemple 4 : Analyse parallèle de fichiers JSON ===" -ForegroundColor Green
$startTime = Get-Date
$jsonAnalysisResults = Get-FileAnalysisInParallel -FilePaths $jsonFiles -Format "JSON" -OutputDir $analysisDir -ThrottleLimit 3
$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

Write-Host "Analyse terminée en $duration secondes"
Write-Host "Résultats de l'analyse :"
$jsonAnalysisResults | Format-Table -Property InputFile, OutputFile, Format, Success

# Exemple 5 : Comparaison des performances (séquentiel vs parallèle)
Write-Host "`n=== Exemple 5 : Comparaison des performances (séquentiel vs parallèle) ===" -ForegroundColor Green

# Importer le module UnifiedSegmenter
$unifiedSegmenterPath = Join-Path -Path $modulesPath -ChildPath "UnifiedSegmenter.ps1"
. $unifiedSegmenterPath
Initialize-UnifiedSegmenter | Out-Null

# Traitement séquentiel
Write-Host "Traitement séquentiel..."
$sequentialOutputDir = Join-Path -Path $tempDir -ChildPath "sequential_output"
New-Item -Path $sequentialOutputDir -ItemType Directory -Force | Out-Null

$startTime = Get-Date
foreach ($csvFile in $csvFiles) {
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($csvFile)
    $outputPath = Join-Path -Path $sequentialOutputDir -ChildPath "$fileName.json"
    Convert-FileFormat -InputFile $csvFile -OutputFile $outputPath -InputFormat "CSV" -OutputFormat "JSON"
}
$endTime = Get-Date
$sequentialDuration = ($endTime - $startTime).TotalSeconds

# Traitement parallèle
Write-Host "Traitement parallèle..."
$parallelOutputDir = Join-Path -Path $tempDir -ChildPath "parallel_output"
New-Item -Path $parallelOutputDir -ItemType Directory -Force | Out-Null

$startTime = Get-Date
Convert-FilesInParallel -InputFiles $csvFiles -OutputDir $parallelOutputDir -InputFormat "CSV" -OutputFormat "JSON" -ThrottleLimit 5 | Out-Null
$endTime = Get-Date
$parallelDuration = ($endTime - $startTime).TotalSeconds

# Afficher les résultats
Write-Host "Durée du traitement séquentiel : $sequentialDuration secondes"
Write-Host "Durée du traitement parallèle : $parallelDuration secondes"
Write-Host "Gain de performance : $([math]::Round(($sequentialDuration - $parallelDuration) / $sequentialDuration * 100, 2))%"

# Nettoyer
Write-Host "`nNettoyage des fichiers d'exemple..."
Remove-Item -Path $tempDir -Recurse -Force

Write-Host "`nExemples terminés."
