#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute les tests de performance pour le module UnifiedSegmenter.
.DESCRIPTION
    Ce script exécute des tests de performance pour mesurer l'efficacité des conversions
    et des opérations sur les formats CSV et YAML.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-06-06
#>

param (
    [Parameter(Mandatory = $false)]
    [string]$ReportsPath = (Join-Path -Path $PSScriptRoot -ChildPath "..\reports"),

    [Parameter(Mandatory = $false)]
    [int]$Iterations = 5,

    [Parameter(Mandatory = $false)]
    [int]$FileSizeKB = 1000,

    [Parameter(Mandatory = $false)]
    [switch]$GenerateCharts
)

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

# Créer le répertoire de rapports s'il n'existe pas
if (-not (Test-Path -Path $ReportsPath)) {
    New-Item -Path $ReportsPath -ItemType Directory -Force | Out-Null
}

# Créer un répertoire temporaire pour les tests
$tempDir = Join-Path -Path $env:TEMP -ChildPath "PerformanceTests"
if (Test-Path -Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

# Fonction pour générer un fichier CSV de test
function New-TestCsvFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [int]$SizeKB
    )

    # Calculer le nombre approximatif de lignes nécessaires
    $bytesPerLine = 50  # Estimation moyenne
    $targetBytes = $SizeKB * 1024
    $targetLines = [math]::Ceiling($targetBytes / $bytesPerLine)

    # Générer l'en-tête
    $header = "id,name,value,description,date,number,boolean,email,url,notes"

    # Générer les lignes
    $lines = @($header)
    for ($i = 1; $i -le $targetLines; $i++) {
        $line = "$i,Item $i,Value $i,Description for item $i,2025-06-$($i % 30 + 1),$($i * 1.5),$($i % 2 -eq 0),user$i@example.com,https://example.com/item/$i,Additional notes for item $i"
        $lines += $line
    }

    # Écrire le fichier
    $lines | Set-Content -Path $FilePath -Encoding UTF8

    # Vérifier la taille
    $actualSize = (Get-Item -Path $FilePath).Length / 1KB
    Write-Host "Fichier CSV généré: $FilePath ($actualSize KB)"
}

# Fonction pour générer un fichier JSON de test
function New-TestJsonFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [int]$SizeKB
    )

    # Calculer le nombre approximatif d'éléments nécessaires
    $bytesPerItem = 200  # Estimation moyenne
    $targetBytes = $SizeKB * 1024
    $targetItems = [math]::Ceiling($targetBytes / $bytesPerItem)

    # Générer les données
    $items = @()
    for ($i = 1; $i -le $targetItems; $i++) {
        $item = @{
            "id"          = $i
            "name"        = "Item $i"
            "value"       = "Value $i"
            "description" = "Description for item $i"
            "date"        = "2025-06-$($i % 30 + 1)"
            "number"      = $i * 1.5
            "boolean"     = ($i % 2 -eq 0)
            "email"       = "user$i@example.com"
            "url"         = "https://example.com/item/$i"
            "notes"       = "Additional notes for item $i"
            "metadata"    = @{
                "created"  = "2025-06-06T12:00:00"
                "modified" = "2025-06-07T15:30:00"
                "version"  = "1.0.$i"
                "tags"     = @("tag1", "tag2", "tag$i")
            }
        }
        $items += $item
    }

    # Écrire le fichier
    $items | ConvertTo-Json -Depth 10 | Set-Content -Path $FilePath -Encoding UTF8

    # Vérifier la taille
    $actualSize = (Get-Item -Path $FilePath).Length / 1KB
    Write-Host "Fichier JSON généré: $FilePath ($actualSize KB)"
}

# Fonction pour générer un fichier YAML de test
function New-TestYamlFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [int]$SizeKB
    )

    # Générer d'abord un fichier JSON
    $jsonPath = [System.IO.Path]::ChangeExtension($FilePath, ".json")
    New-TestJsonFile -FilePath $jsonPath -SizeKB $SizeKB

    # Convertir le JSON en YAML
    Convert-FileFormat -InputFile $jsonPath -OutputFile $FilePath -InputFormat "JSON" -OutputFormat "YAML"

    # Supprimer le fichier JSON temporaire
    Remove-Item -Path $jsonPath -Force

    # Vérifier la taille
    $actualSize = (Get-Item -Path $FilePath).Length / 1KB
    Write-Host "Fichier YAML généré: $FilePath ($actualSize KB)"
}

# Fonction pour mesurer les performances
function Measure-Performance {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestName,

        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $true)]
        [int]$Iterations
    )

    $results = @()

    for ($i = 1; $i -le $Iterations; $i++) {
        Write-Host "Exécution de $TestName - Itération $i/$Iterations..."
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        try {
            & $ScriptBlock
            $success = $true
        } catch {
            Write-Error "Erreur lors de l'exécution de $TestName : $_"
            $success = $false
        }

        $stopwatch.Stop()
        $duration = $stopwatch.Elapsed.TotalSeconds

        $result = [PSCustomObject]@{
            TestName        = $TestName
            Iteration       = $i
            DurationSeconds = $duration
            Success         = $success
        }

        $results += $result
        Write-Host "  Durée: $duration secondes"
    }

    return $results
}

# Générer les fichiers de test
$csvFilePath = Join-Path -Path $tempDir -ChildPath "test.csv"
$jsonFilePath = Join-Path -Path $tempDir -ChildPath "test.json"
$yamlFilePath = Join-Path -Path $tempDir -ChildPath "test.yaml"
$outputDir = Join-Path -Path $tempDir -ChildPath "output"
New-Item -Path $outputDir -ItemType Directory -Force | Out-Null

Write-Host "Génération des fichiers de test..."
New-TestCsvFile -FilePath $csvFilePath -SizeKB $FileSizeKB
New-TestJsonFile -FilePath $jsonFilePath -SizeKB $FileSizeKB
New-TestYamlFile -FilePath $yamlFilePath -SizeKB $FileSizeKB

# Définir les tests de performance
$performanceTests = @(
    # Tests de conversion de base
    @{
        Name        = "CSV_to_JSON"
        Category    = "Conversion"
        Description = "Conversion d'un fichier CSV en JSON"
        ScriptBlock = {
            $outputPath = Join-Path -Path $outputDir -ChildPath "csv_to_json.json"
            Convert-FileFormat -InputFile $csvFilePath -OutputFile $outputPath -InputFormat "CSV" -OutputFormat "JSON"
        }
    },
    @{
        Name        = "JSON_to_CSV"
        Category    = "Conversion"
        Description = "Conversion d'un fichier JSON en CSV"
        ScriptBlock = {
            $outputPath = Join-Path -Path $outputDir -ChildPath "json_to_csv.csv"
            Convert-FileFormat -InputFile $jsonFilePath -OutputFile $outputPath -InputFormat "JSON" -OutputFormat "CSV"
        }
    },
    @{
        Name        = "JSON_to_CSV_Flattened"
        Category    = "Conversion"
        Description = "Conversion d'un fichier JSON en CSV avec aplatissement des objets imbriqués"
        ScriptBlock = {
            $outputPath = Join-Path -Path $outputDir -ChildPath "json_to_csv_flattened.csv"
            Convert-FileFormat -InputFile $jsonFilePath -OutputFile $outputPath -InputFormat "JSON" -OutputFormat "CSV" -FlattenNestedObjects $true
        }
    },
    @{
        Name        = "JSON_to_CSV_NonFlattened"
        Category    = "Conversion"
        Description = "Conversion d'un fichier JSON en CSV sans aplatissement des objets imbriqués"
        ScriptBlock = {
            $outputPath = Join-Path -Path $outputDir -ChildPath "json_to_csv_non_flattened.csv"
            Convert-FileFormat -InputFile $jsonFilePath -OutputFile $outputPath -InputFormat "JSON" -OutputFormat "CSV" -FlattenNestedObjects $false
        }
    },
    @{
        Name        = "YAML_to_JSON"
        Category    = "Conversion"
        Description = "Conversion d'un fichier YAML en JSON"
        ScriptBlock = {
            $outputPath = Join-Path -Path $outputDir -ChildPath "yaml_to_json.json"
            Convert-FileFormat -InputFile $yamlFilePath -OutputFile $outputPath -InputFormat "YAML" -OutputFormat "JSON"
        }
    },
    @{
        Name        = "JSON_to_YAML"
        Category    = "Conversion"
        Description = "Conversion d'un fichier JSON en YAML"
        ScriptBlock = {
            $outputPath = Join-Path -Path $outputDir -ChildPath "json_to_yaml.yaml"
            Convert-FileFormat -InputFile $jsonFilePath -OutputFile $outputPath -InputFormat "JSON" -OutputFormat "YAML"
        }
    },
    @{
        Name        = "CSV_to_YAML"
        Category    = "Conversion"
        Description = "Conversion d'un fichier CSV en YAML"
        ScriptBlock = {
            $outputPath = Join-Path -Path $outputDir -ChildPath "csv_to_yaml.yaml"
            Convert-FileFormat -InputFile $csvFilePath -OutputFile $outputPath -InputFormat "CSV" -OutputFormat "YAML"
        }
    },
    @{
        Name        = "YAML_to_CSV"
        Category    = "Conversion"
        Description = "Conversion d'un fichier YAML en CSV"
        ScriptBlock = {
            $outputPath = Join-Path -Path $outputDir -ChildPath "yaml_to_csv.csv"
            Convert-FileFormat -InputFile $yamlFilePath -OutputFile $outputPath -InputFormat "YAML" -OutputFormat "CSV"
        }
    },
    @{
        Name        = "CSV_to_XML"
        Category    = "Conversion"
        Description = "Conversion d'un fichier CSV en XML"
        ScriptBlock = {
            $outputPath = Join-Path -Path $outputDir -ChildPath "csv_to_xml.xml"
            Convert-FileFormat -InputFile $csvFilePath -OutputFile $outputPath -InputFormat "CSV" -OutputFormat "XML"
        }
    },
    @{
        Name        = "YAML_to_XML"
        Category    = "Conversion"
        Description = "Conversion d'un fichier YAML en XML"
        ScriptBlock = {
            $outputPath = Join-Path -Path $outputDir -ChildPath "yaml_to_xml.xml"
            Convert-FileFormat -InputFile $yamlFilePath -OutputFile $outputPath -InputFormat "YAML" -OutputFormat "XML"
        }
    },

    # Tests d'analyse
    @{
        Name        = "CSV_Analysis"
        Category    = "Analyse"
        Description = "Analyse d'un fichier CSV"
        ScriptBlock = {
            $outputPath = Join-Path -Path $outputDir -ChildPath "csv_analysis.json"
            Get-FileAnalysis -FilePath $csvFilePath -Format "CSV" -OutputFile $outputPath
        }
    },
    @{
        Name        = "YAML_Analysis"
        Category    = "Analyse"
        Description = "Analyse d'un fichier YAML"
        ScriptBlock = {
            $outputPath = Join-Path -Path $outputDir -ChildPath "yaml_analysis.json"
            Get-FileAnalysis -FilePath $yamlFilePath -Format "YAML" -OutputFile $outputPath
        }
    },

    # Tests de validation
    @{
        Name        = "CSV_Validation"
        Category    = "Validation"
        Description = "Validation d'un fichier CSV"
        ScriptBlock = {
            Test-FileValidity -FilePath $csvFilePath -Format "CSV"
        }
    },
    @{
        Name        = "YAML_Validation"
        Category    = "Validation"
        Description = "Validation d'un fichier YAML"
        ScriptBlock = {
            Test-FileValidity -FilePath $yamlFilePath -Format "YAML"
        }
    },
    @{
        Name        = "JSON_Validation"
        Category    = "Validation"
        Description = "Validation d'un fichier JSON"
        ScriptBlock = {
            Test-FileValidity -FilePath $jsonFilePath -Format "JSON"
        }
    },

    # Tests de segmentation
    @{
        Name        = "CSV_Segmentation"
        Category    = "Segmentation"
        Description = "Segmentation d'un fichier CSV"
        ScriptBlock = {
            $segmentDir = Join-Path -Path $outputDir -ChildPath "csv_segments"
            if (Test-Path -Path $segmentDir) {
                Remove-Item -Path $segmentDir -Recurse -Force
            }
            New-Item -Path $segmentDir -ItemType Directory -Force | Out-Null
            Split-File -FilePath $csvFilePath -Format "CSV" -OutputDir $segmentDir -ChunkSizeKB 100
        }
    },
    @{
        Name        = "YAML_Segmentation"
        Category    = "Segmentation"
        Description = "Segmentation d'un fichier YAML"
        ScriptBlock = {
            $segmentDir = Join-Path -Path $outputDir -ChildPath "yaml_segments"
            if (Test-Path -Path $segmentDir) {
                Remove-Item -Path $segmentDir -Recurse -Force
            }
            New-Item -Path $segmentDir -ItemType Directory -Force | Out-Null
            Split-File -FilePath $yamlFilePath -Format "YAML" -OutputDir $segmentDir -ChunkSizeKB 100
        }
    },
    @{
        Name        = "JSON_Segmentation"
        Category    = "Segmentation"
        Description = "Segmentation d'un fichier JSON"
        ScriptBlock = {
            $segmentDir = Join-Path -Path $outputDir -ChildPath "json_segments"
            if (Test-Path -Path $segmentDir) {
                Remove-Item -Path $segmentDir -Recurse -Force
            }
            New-Item -Path $segmentDir -ItemType Directory -Force | Out-Null
            Split-File -FilePath $jsonFilePath -Format "JSON" -OutputDir $segmentDir -ChunkSizeKB 100
        }
    },

    # Tests de détection de format
    @{
        Name        = "Format_Detection"
        Category    = "Détection"
        Description = "Détection du format d'un fichier"
        ScriptBlock = {
            Get-FileFormat -FilePath $csvFilePath
            Get-FileFormat -FilePath $jsonFilePath
            Get-FileFormat -FilePath $yamlFilePath
        }
    },
    @{
        Name        = "Format_Detection_With_Encoding"
        Category    = "Détection"
        Description = "Détection du format d'un fichier avec détection d'encodage"
        ScriptBlock = {
            Get-FileFormat -FilePath $csvFilePath -UseEncodingDetector
            Get-FileFormat -FilePath $jsonFilePath -UseEncodingDetector
            Get-FileFormat -FilePath $yamlFilePath -UseEncodingDetector
        }
    },

    # Tests d'encodage
    @{
        Name        = "Encoding_Detection"
        Category    = "Encodage"
        Description = "Détection de l'encodage d'un fichier"
        ScriptBlock = {
            Get-FileEncoding -FilePath $csvFilePath
            Get-FileEncoding -FilePath $jsonFilePath
            Get-FileEncoding -FilePath $yamlFilePath
        }
    }
)

# Exécuter les tests de performance
$allResults = @()

foreach ($test in $performanceTests) {
    $results = Measure-Performance -TestName $test.Name -ScriptBlock $test.ScriptBlock -Iterations $Iterations
    $allResults += $results
}

# Calculer les statistiques
$statistics = $allResults | Group-Object -Property TestName | ForEach-Object {
    $testName = $_.Name
    $testResults = $_.Group
    $testCategory = ($performanceTests | Where-Object { $_.Name -eq $testName }).Category
    $testDescription = ($performanceTests | Where-Object { $_.Name -eq $testName }).Description
    $successCount = ($testResults | Where-Object { $_.Success -eq $true }).Count
    $successRate = $successCount / $testResults.Count
    $avgDuration = ($testResults | Measure-Object -Property DurationSeconds -Average).Average
    $minDuration = ($testResults | Measure-Object -Property DurationSeconds -Minimum).Minimum
    $maxDuration = ($testResults | Measure-Object -Property DurationSeconds -Maximum).Maximum
    $stdDeviation = [Math]::Sqrt(($testResults | ForEach-Object { [Math]::Pow($_.DurationSeconds - $avgDuration, 2) } | Measure-Object -Average).Average)

    [PSCustomObject]@{
        TestName        = $testName
        Category        = $testCategory
        Description     = $testDescription
        AverageDuration = $avgDuration
        MinDuration     = $minDuration
        MaxDuration     = $maxDuration
        StdDeviation    = $stdDeviation
        SuccessRate     = $successRate
        Iterations      = $testResults.Count
    }
}

# Enregistrer les résultats
$resultsPath = Join-Path -Path $ReportsPath -ChildPath "PerformanceResults.csv"
$allResults | Export-Csv -Path $resultsPath -NoTypeInformation

$statisticsPath = Join-Path -Path $ReportsPath -ChildPath "PerformanceStatistics.csv"
$statistics | Export-Csv -Path $statisticsPath -NoTypeInformation

# Afficher les statistiques
Write-Host "`nStatistiques de performance :"

# Afficher les statistiques par catégorie
foreach ($category in ($statistics | Select-Object -Property Category -Unique).Category) {
    Write-Host "`nCatégorie: $category" -ForegroundColor Green
    $statistics | Where-Object { $_.Category -eq $category } | Format-Table -Property TestName, Description, AverageDuration, MinDuration, MaxDuration, StdDeviation, SuccessRate -AutoSize
}

# Afficher un résumé global
Write-Host "`nRésumé global:" -ForegroundColor Yellow
$statistics | Sort-Object -Property AverageDuration | Select-Object -First 5 | Format-Table -Property TestName, Category, AverageDuration, SuccessRate -AutoSize

# Afficher les tests les plus lents
Write-Host "Tests les plus lents:" -ForegroundColor Yellow
$statistics | Sort-Object -Property AverageDuration -Descending | Select-Object -First 5 | Format-Table -Property TestName, Category, AverageDuration, SuccessRate -AutoSize

# Générer des graphiques si demandé
if ($GenerateCharts) {
    $chartScriptPath = Join-Path -Path $ReportsPath -ChildPath "GeneratePerformanceCharts.ps1"
    $chartScript = @"
# Script pour générer des graphiques de performance
# Nécessite le module PSChart

# Installer PSChart si nécessaire
if (-not (Get-Module -Name PSChart -ListAvailable)) {
    Install-Module -Name PSChart -Force -SkipPublisherCheck
}

Import-Module PSChart

# Charger les données
`$results = Import-Csv -Path "$resultsPath"
`$statistics = Import-Csv -Path "$statisticsPath"

# Créer des graphiques par catégorie
foreach (`$category in (`$statistics | Select-Object -Property Category -Unique).Category) {
    # Filtrer les statistiques par catégorie
    `$categoryStats = `$statistics | Where-Object { `$_.Category -eq `$category }

    # Créer un graphique à barres pour les durées moyennes
    `$chartPath = Join-Path -Path "$ReportsPath" -ChildPath "`$category-DurationChart.png"
    New-BarChart -InputObject `$categoryStats -LabelProperty "TestName" -DataProperty "AverageDuration" -Title "Durée moyenne - `$category" -XLabel "Test" -YLabel "Durée (secondes)" -Width 800 -Height 600 -OutputPath `$chartPath

    # Créer un graphique à barres pour les taux de réussite
    `$successChartPath = Join-Path -Path "$ReportsPath" -ChildPath "`$category-SuccessRateChart.png"
    New-BarChart -InputObject `$categoryStats -LabelProperty "TestName" -DataProperty "SuccessRate" -Title "Taux de réussite - `$category" -XLabel "Test" -YLabel "Taux de réussite" -Width 800 -Height 600 -OutputPath `$successChartPath

    Write-Host "Graphiques générés pour la catégorie `$category :"
    Write-Host "- `$chartPath"
    Write-Host "- `$successChartPath"
}

# Créer un graphique comparé des performances par catégorie
`$categoryAvgPath = Join-Path -Path "$ReportsPath" -ChildPath "CategoryPerformanceChart.png"
`$categoryAvg = `$statistics | Group-Object -Property Category | ForEach-Object {
    [PSCustomObject]@{
        Category = `$_.Name
        AverageDuration = (`$_.Group | Measure-Object -Property AverageDuration -Average).Average
        SuccessRate = (`$_.Group | Measure-Object -Property SuccessRate -Average).Average
    }
}
New-BarChart -InputObject `$categoryAvg -LabelProperty "Category" -DataProperty "AverageDuration" -Title "Durée moyenne par catégorie" -XLabel "Catégorie" -YLabel "Durée (secondes)" -Width 800 -Height 600 -OutputPath `$categoryAvgPath

# Créer un graphique de dispersion pour visualiser la relation entre durée et taux de réussite
`$scatterPath = Join-Path -Path "$ReportsPath" -ChildPath "PerformanceScatterChart.png"
New-ScatterChart -InputObject `$statistics -XProperty "AverageDuration" -YProperty "SuccessRate" -LabelProperty "TestName" -Title "Relation entre durée et taux de réussite" -XLabel "Durée (secondes)" -YLabel "Taux de réussite" -Width 800 -Height 600 -OutputPath `$scatterPath

Write-Host "Graphiques globaux générés :"
Write-Host "- `$categoryAvgPath"
Write-Host "- `$scatterPath"
"@

    Set-Content -Path $chartScriptPath -Value $chartScript -Encoding UTF8
    Write-Host "`nScript de génération de graphiques créé : $chartScriptPath"
    Write-Host "Pour générer les graphiques, exécutez ce script après avoir installé le module PSChart."
}

# Nettoyer
Write-Host "`nNettoyage des fichiers temporaires..."
Remove-Item -Path $tempDir -Recurse -Force

Write-Host "`nTests de performance terminés."
Write-Host "Résultats enregistrés dans : $resultsPath"
Write-Host "Statistiques enregistrées dans : $statisticsPath"

return $statistics
