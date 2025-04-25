# Exemple d'utilisation du module UnifiedFileProcessor
# Ce script montre comment utiliser le module UnifiedFileProcessor pour traiter des fichiers de manière sécurisée et performante

# Importer le module UnifiedFileProcessor
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$modulesPath = Join-Path -Path $projectRoot -ChildPath "modules"
$unifiedFileProcessorPath = Join-Path -Path $modulesPath -ChildPath "UnifiedFileProcessor.ps1"
. $unifiedFileProcessorPath

# Initialiser le module
$initResult = Initialize-UnifiedFileProcessor
if (-not $initResult) {
    Write-Error "Erreur lors de l'initialisation du module UnifiedFileProcessor"
    return
}

# Créer un répertoire temporaire pour les exemples
$tempDir = Join-Path -Path $env:TEMP -ChildPath "UnifiedFileProcessorExample"
if (Test-Path -Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

# Créer des sous-répertoires
$inputDir = Join-Path -Path $tempDir -ChildPath "input"
$outputDir = Join-Path -Path $tempDir -ChildPath "output"
$analysisDir = Join-Path -Path $tempDir -ChildPath "analysis"
$segmentsDir = Join-Path -Path $tempDir -ChildPath "segments"
New-Item -Path $inputDir -ItemType Directory -Force | Out-Null
New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
New-Item -Path $analysisDir -ItemType Directory -Force | Out-Null
New-Item -Path $segmentsDir -ItemType Directory -Force | Out-Null

# Créer des fichiers d'exemple
$validJsonPath = Join-Path -Path $inputDir -ChildPath "valid.json"
$validCsvPath = Join-Path -Path $inputDir -ChildPath "valid.csv"
$invalidJsonPath = Join-Path -Path $inputDir -ChildPath "invalid.json"
$suspiciousFilePath = Join-Path -Path $inputDir -ChildPath "suspicious.json"
$largeJsonPath = Join-Path -Path $inputDir -ChildPath "large.json"

# Créer un fichier JSON valide
$validJsonContent = @{
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
Set-Content -Path $validJsonPath -Value $validJsonContent -Encoding UTF8

# Créer un fichier CSV valide
$validCsvContent = @"
id,name,value,description
1,Item 1,Value 1,"Description 1"
2,Item 2,Value 2,"Description 2"
3,Item 3,Value 3,"Description 3"
"@
Set-Content -Path $validCsvPath -Value $validCsvContent -Encoding UTF8

# Créer un fichier JSON invalide
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

# Créer un fichier avec du contenu suspect
$suspiciousContent = @"
{
    "name": "Suspicious Content",
    "script": "Invoke-Expression 'Get-Process'",
    "items": [
        {"id": 1, "value": "Item 1"},
        {"id": 2, "value": "Item 2"},
        {"id": 3, "value": "Item 3"}
    ]
}
"@
Set-Content -Path $suspiciousFilePath -Value $suspiciousContent -Encoding UTF8

# Créer un fichier JSON volumineux
$largeJsonContent = @{
    "array" = (1..1000 | ForEach-Object { 
        @{ 
            "id" = $_ 
            "name" = "Item $_"
            "value" = "Value $_"
            "description" = "Description for item $_"
            "metadata" = @{
                "created" = "2025-06-06"
                "category" = "Category $($_ % 5 + 1)"
                "tags" = @("tag1", "tag2", "tag$($_ % 10 + 1)")
            }
        } 
    })
} | ConvertTo-Json -Depth 10
Set-Content -Path $largeJsonPath -Value $largeJsonContent -Encoding UTF8

# Créer plusieurs fichiers CSV pour le traitement parallèle
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

# Exemple 1 : Traitement sécurisé d'un fichier
Write-Host "`n=== Exemple 1 : Traitement sécurisé d'un fichier ===" -ForegroundColor Green
$outputJsonPath = Join-Path -Path $outputDir -ChildPath "valid_csv_to_json.json"
$processResult = Process-FileSecurely -InputFile $validCsvPath -OutputFile $outputJsonPath -InputFormat "CSV" -OutputFormat "JSON"
Write-Host "Traitement sécurisé du fichier CSV valide : $processResult"

if ($processResult) {
    $jsonContent = Get-Content -Path $outputJsonPath -Raw
    Write-Host "Contenu du fichier JSON :"
    Write-Host $jsonContent
}

# Exemple 2 : Traitement sécurisé d'un fichier avec contenu suspect
Write-Host "`n=== Exemple 2 : Traitement sécurisé d'un fichier avec contenu suspect ===" -ForegroundColor Green
$outputSuspiciousPath = Join-Path -Path $outputDir -ChildPath "suspicious_to_yaml.yaml"
$processSuspiciousResult = Process-FileSecurely -InputFile $suspiciousFilePath -OutputFile $outputSuspiciousPath -InputFormat "JSON" -OutputFormat "YAML" -CheckForExecutableContent
Write-Host "Traitement sécurisé du fichier suspect : $processSuspiciousResult"

# Exemple 3 : Traitement parallèle sécurisé de fichiers
Write-Host "`n=== Exemple 3 : Traitement parallèle sécurisé de fichiers ===" -ForegroundColor Green
$parallelOutputDir = Join-Path -Path $outputDir -ChildPath "parallel"
New-Item -Path $parallelOutputDir -ItemType Directory -Force | Out-Null

$startTime = Get-Date
$parallelResults = Process-FilesInParallel -InputFiles $csvFiles -OutputDir $parallelOutputDir -InputFormat "CSV" -OutputFormat "JSON" -ThrottleLimit 3
$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

Write-Host "Traitement parallèle terminé en $duration secondes"
Write-Host "Résultats du traitement parallèle :"
$parallelResults | Format-Table -Property InputFile, OutputFile, Success

# Exemple 4 : Analyse sécurisée d'un fichier
Write-Host "`n=== Exemple 4 : Analyse sécurisée d'un fichier ===" -ForegroundColor Green
$analysisJsonPath = Join-Path -Path $analysisDir -ChildPath "valid_json_analysis.json"
$analysisResult = Get-SecureFileAnalysis -FilePath $validJsonPath -Format "JSON" -OutputFile $analysisJsonPath
Write-Host "Analyse sécurisée du fichier JSON valide : $analysisResult"

# Générer un rapport HTML
$htmlReportPath = Get-SecureFileAnalysis -FilePath $validJsonPath -Format "JSON" -AsHtml
Write-Host "Rapport HTML généré : $htmlReportPath"

# Exemple 5 : Analyse parallèle sécurisée de fichiers
Write-Host "`n=== Exemple 5 : Analyse parallèle sécurisée de fichiers ===" -ForegroundColor Green
$parallelAnalysisDir = Join-Path -Path $analysisDir -ChildPath "parallel"
New-Item -Path $parallelAnalysisDir -ItemType Directory -Force | Out-Null

$startTime = Get-Date
$parallelAnalysisResults = Get-SecureFileAnalysisInParallel -FilePaths $csvFiles -Format "CSV" -OutputDir $parallelAnalysisDir -ThrottleLimit 3
$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

Write-Host "Analyse parallèle terminée en $duration secondes"
Write-Host "Résultats de l'analyse parallèle :"
$parallelAnalysisResults | Format-Table -Property InputFile, OutputFile, Format, Success

# Exemple 6 : Segmentation sécurisée d'un fichier
Write-Host "`n=== Exemple 6 : Segmentation sécurisée d'un fichier ===" -ForegroundColor Green
$segmentResult = Split-FileSecurely -FilePath $largeJsonPath -OutputDir $segmentsDir -Format "JSON" -ChunkSizeKB 10
Write-Host "Segmentation sécurisée du fichier JSON volumineux : $($segmentResult.Count) segments créés"

if ($segmentResult.Count -gt 0) {
    Write-Host "Segments créés :"
    $segmentResult | ForEach-Object { Write-Host "  $_" }
}

# Exemple 7 : Gestion des erreurs
Write-Host "`n=== Exemple 7 : Gestion des erreurs ===" -ForegroundColor Green

# Traitement d'un fichier JSON invalide
$outputInvalidPath = Join-Path -Path $outputDir -ChildPath "invalid_to_yaml.yaml"
$processInvalidResult = Process-FileSecurely -InputFile $invalidJsonPath -OutputFile $outputInvalidPath -InputFormat "JSON" -OutputFormat "YAML"
Write-Host "Traitement sécurisé du fichier JSON invalide : $processInvalidResult"

# Traitement d'un fichier avec contenu suspect avec vérification du contenu exécutable
$outputSuspiciousPath2 = Join-Path -Path $outputDir -ChildPath "suspicious_to_yaml2.yaml"
$processSuspiciousResult2 = Process-FileSecurely -InputFile $suspiciousFilePath -OutputFile $outputSuspiciousPath2 -InputFormat "JSON" -OutputFormat "YAML" -CheckForExecutableContent
Write-Host "Traitement sécurisé du fichier suspect avec vérification du contenu exécutable : $processSuspiciousResult2"

# Traitement parallèle avec des fichiers valides et invalides
$mixedFiles = @($validJsonPath, $invalidJsonPath, $validCsvPath, $suspiciousFilePath)
$mixedOutputDir = Join-Path -Path $outputDir -ChildPath "mixed"
New-Item -Path $mixedOutputDir -ItemType Directory -Force | Out-Null

$mixedResults = Process-FilesInParallel -InputFiles $mixedFiles -OutputDir $mixedOutputDir -InputFormat "AUTO" -OutputFormat "JSON" -CheckForExecutableContent
Write-Host "Traitement parallèle de fichiers mixtes :"
$mixedResults | Format-Table -Property InputFile, OutputFile, Success

# Nettoyer
Write-Host "`nNettoyage des fichiers d'exemple..."
Remove-Item -Path $tempDir -Recurse -Force

Write-Host "`nExemples terminés."
