#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute les tests de performance pour le module UnifiedSegmenter.
.DESCRIPTION
    Ce script exÃ©cute des tests de performance pour mesurer l'efficacitÃ© des conversions
    et des opÃ©rations sur les formats CSV et YAML.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-06-06
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

# Initialiser le segmenteur unifiÃ©
$initResult = Initialize-UnifiedSegmenter
if (-not $initResult) {
    Write-Error "Erreur lors de l'initialisation du segmenteur unifiÃ©"
    return
}

# CrÃ©er le rÃ©pertoire de rapports s'il n'existe pas
if (-not (Test-Path -Path $ReportsPath)) {
    New-Item -Path $ReportsPath -ItemType Directory -Force | Out-Null
}

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$tempDir = Join-Path -Path $env:TEMP -ChildPath "PerformanceTests"
if (Test-Path -Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

# Fonction pour gÃ©nÃ©rer un fichier CSV de test
function New-TestCsvFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [int]$SizeKB
    )

    # Calculer le nombre approximatif de lignes nÃ©cessaires
    $bytesPerLine = 50  # Estimation moyenne
    $targetBytes = $SizeKB * 1024
    $targetLines = [math]::Ceiling($targetBytes / $bytesPerLine)

    # GÃ©nÃ©rer l'en-tÃªte
    $header = "id,name,value,description,date,number,boolean,email,url,notes"

    # GÃ©nÃ©rer les lignes
    $lines = @($header)
    for ($i = 1; $i -le $targetLines; $i++) {
        $line = "$i,Item $i,Value $i,Description for item $i,2025-06-$($i % 30 + 1),$($i * 1.5),$($i % 2 -eq 0),user$i@example.com,https://example.com/item/$i,Additional notes for item $i"
        $lines += $line
    }

    # Ã‰crire le fichier
    $lines | Set-Content -Path $FilePath -Encoding UTF8

    # VÃ©rifier la taille
    $actualSize = (Get-Item -Path $FilePath).Length / 1KB
    Write-Host "Fichier CSV gÃ©nÃ©rÃ©: $FilePath ($actualSize KB)"
}

# Fonction pour gÃ©nÃ©rer un fichier JSON de test
function New-TestJsonFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [int]$SizeKB
    )

    # Calculer le nombre approximatif d'Ã©lÃ©ments nÃ©cessaires
    $bytesPerItem = 200  # Estimation moyenne
    $targetBytes = $SizeKB * 1024
    $targetItems = [math]::Ceiling($targetBytes / $bytesPerItem)

    # GÃ©nÃ©rer les donnÃ©es
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

    # Ã‰crire le fichier
    $items | ConvertTo-Json -Depth 10 | Set-Content -Path $FilePath -Encoding UTF8

    # VÃ©rifier la taille
    $actualSize = (Get-Item -Path $FilePath).Length / 1KB
    Write-Host "Fichier JSON gÃ©nÃ©rÃ©: $FilePath ($actualSize KB)"
}

# Fonction pour gÃ©nÃ©rer un fichier YAML de test
function New-TestYamlFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [int]$SizeKB
    )

    # GÃ©nÃ©rer d'abord un fichier JSON
    $jsonPath = [System.IO.Path]::ChangeExtension($FilePath, ".json")
    New-TestJsonFile -FilePath $jsonPath -SizeKB $SizeKB

    # Convertir le JSON en YAML
    Convert-FileFormat -InputFile $jsonPath -OutputFile $FilePath -InputFormat "JSON" -OutputFormat "YAML"

    # Supprimer le fichier JSON temporaire
    Remove-Item -Path $jsonPath -Force

    # VÃ©rifier la taille
    $actualSize = (Get-Item -Path $FilePath).Length / 1KB
    Write-Host "Fichier YAML gÃ©nÃ©rÃ©: $FilePath ($actualSize KB)"
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
        Write-Host "ExÃ©cution de $TestName - ItÃ©ration $i/$Iterations..."
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        try {
            & $ScriptBlock
            $success = $true
        } catch {
            Write-Error "Erreur lors de l'exÃ©cution de $TestName : $_"
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
        Write-Host "  DurÃ©e: $duration secondes"
    }

    return $results
}

# GÃ©nÃ©rer les fichiers de test
$csvFilePath = Join-Path -Path $tempDir -ChildPath "test.csv"
$jsonFilePath = Join-Path -Path $tempDir -ChildPath "test.json"
$yamlFilePath = Join-Path -Path $tempDir -ChildPath "test.yaml"
$outputDir = Join-Path -Path $tempDir -ChildPath "output"
New-Item -Path $outputDir -ItemType Directory -Force | Out-Null

Write-Host "GÃ©nÃ©ration des fichiers de test..."
New-TestCsvFile -FilePath $csvFilePath -SizeKB $FileSizeKB
New-TestJsonFile -FilePath $jsonFilePath -SizeKB $FileSizeKB
New-TestYamlFile -FilePath $yamlFilePath -SizeKB $FileSizeKB

# DÃ©finir les tests de performance
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
        Description = "Conversion d'un fichier JSON en CSV avec aplatissement des objets imbriquÃ©s"
        ScriptBlock = {
            $outputPath = Join-Path -Path $outputDir -ChildPath "json_to_csv_flattened.csv"
            Convert-FileFormat -InputFile $jsonFilePath -OutputFile $outputPath -InputFormat "JSON" -OutputFormat "CSV" -FlattenNestedObjects $true
        }
    },
    @{
        Name        = "JSON_to_CSV_NonFlattened"
        Category    = "Conversion"
        Description = "Conversion d'un fichier JSON en CSV sans aplatissement des objets imbriquÃ©s"
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

    # Tests de dÃ©tection de format
    @{
        Name        = "Format_Detection"
        Category    = "DÃ©tection"
        Description = "DÃ©tection du format d'un fichier"
        ScriptBlock = {
            Get-FileFormat -FilePath $csvFilePath
            Get-FileFormat -FilePath $jsonFilePath
            Get-FileFormat -FilePath $yamlFilePath
        }
    },
    @{
        Name        = "Format_Detection_With_Encoding"
        Category    = "DÃ©tection"
        Description = "DÃ©tection du format d'un fichier avec dÃ©tection d'encodage"
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
        Description = "DÃ©tection de l'encodage d'un fichier"
        ScriptBlock = {
            Get-FileEncoding -FilePath $csvFilePath
            Get-FileEncoding -FilePath $jsonFilePath
            Get-FileEncoding -FilePath $yamlFilePath
        }
    }
)

# ExÃ©cuter les tests de performance
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

# Enregistrer les rÃ©sultats
$resultsPath = Join-Path -Path $ReportsPath -ChildPath "PerformanceResults.csv"
$allResults | Export-Csv -Path $resultsPath -NoTypeInformation

$statisticsPath = Join-Path -Path $ReportsPath -ChildPath "PerformanceStatistics.csv"
$statistics | Export-Csv -Path $statisticsPath -NoTypeInformation

# Afficher les statistiques
Write-Host "`nStatistiques de performance :"

# Afficher les statistiques par catÃ©gorie
foreach ($category in ($statistics | Select-Object -Property Category -Unique).Category) {
    Write-Host "`nCatÃ©gorie: $category" -ForegroundColor Green
    $statistics | Where-Object { $_.Category -eq $category } | Format-Table -Property TestName, Description, AverageDuration, MinDuration, MaxDuration, StdDeviation, SuccessRate -AutoSize
}

# Afficher un rÃ©sumÃ© global
Write-Host "`nRÃ©sumÃ© global:" -ForegroundColor Yellow
$statistics | Sort-Object -Property AverageDuration | Select-Object -First 5 | Format-Table -Property TestName, Category, AverageDuration, SuccessRate -AutoSize

# Afficher les tests les plus lents
Write-Host "Tests les plus lents:" -ForegroundColor Yellow
$statistics | Sort-Object -Property AverageDuration -Descending | Select-Object -First 5 | Format-Table -Property TestName, Category, AverageDuration, SuccessRate -AutoSize

# GÃ©nÃ©rer des graphiques si demandÃ©
if ($GenerateCharts) {
    $chartScriptPath = Join-Path -Path $ReportsPath -ChildPath "GeneratePerformanceCharts.ps1"
    $chartScript = @"
# Script pour gÃ©nÃ©rer des graphiques de performance
# NÃ©cessite le module PSChart

# Installer PSChart si nÃ©cessaire
if (-not (Get-Module -Name PSChart -ListAvailable)) {
    Install-Module -Name PSChart -Force -SkipPublisherCheck
}

Import-Module PSChart

# Charger les donnÃ©es
`$results = Import-Csv -Path "$resultsPath"
`$statistics = Import-Csv -Path "$statisticsPath"

# CrÃ©er des graphiques par catÃ©gorie
foreach (`$category in (`$statistics | Select-Object -Property Category -Unique).Category) {
    # Filtrer les statistiques par catÃ©gorie
    `$categoryStats = `$statistics | Where-Object { `$_.Category -eq `$category }

    # CrÃ©er un graphique Ã  barres pour les durÃ©es moyennes
    `$chartPath = Join-Path -Path "$ReportsPath" -ChildPath "`$category-DurationChart.png"
    New-BarChart -InputObject `$categoryStats -LabelProperty "TestName" -DataProperty "AverageDuration" -Title "DurÃ©e moyenne - `$category" -XLabel "Test" -YLabel "DurÃ©e (secondes)" -Width 800 -Height 600 -OutputPath `$chartPath

    # CrÃ©er un graphique Ã  barres pour les taux de rÃ©ussite
    `$successChartPath = Join-Path -Path "$ReportsPath" -ChildPath "`$category-SuccessRateChart.png"
    New-BarChart -InputObject `$categoryStats -LabelProperty "TestName" -DataProperty "SuccessRate" -Title "Taux de rÃ©ussite - `$category" -XLabel "Test" -YLabel "Taux de rÃ©ussite" -Width 800 -Height 600 -OutputPath `$successChartPath

    Write-Host "Graphiques gÃ©nÃ©rÃ©s pour la catÃ©gorie `$category :"
    Write-Host "- `$chartPath"
    Write-Host "- `$successChartPath"
}

# CrÃ©er un graphique comparÃ© des performances par catÃ©gorie
`$categoryAvgPath = Join-Path -Path "$ReportsPath" -ChildPath "CategoryPerformanceChart.png"
`$categoryAvg = `$statistics | Group-Object -Property Category | ForEach-Object {
    [PSCustomObject]@{
        Category = `$_.Name
        AverageDuration = (`$_.Group | Measure-Object -Property AverageDuration -Average).Average
        SuccessRate = (`$_.Group | Measure-Object -Property SuccessRate -Average).Average
    }
}
New-BarChart -InputObject `$categoryAvg -LabelProperty "Category" -DataProperty "AverageDuration" -Title "DurÃ©e moyenne par catÃ©gorie" -XLabel "CatÃ©gorie" -YLabel "DurÃ©e (secondes)" -Width 800 -Height 600 -OutputPath `$categoryAvgPath

# CrÃ©er un graphique de dispersion pour visualiser la relation entre durÃ©e et taux de rÃ©ussite
`$scatterPath = Join-Path -Path "$ReportsPath" -ChildPath "PerformanceScatterChart.png"
New-ScatterChart -InputObject `$statistics -XProperty "AverageDuration" -YProperty "SuccessRate" -LabelProperty "TestName" -Title "Relation entre durÃ©e et taux de rÃ©ussite" -XLabel "DurÃ©e (secondes)" -YLabel "Taux de rÃ©ussite" -Width 800 -Height 600 -OutputPath `$scatterPath

Write-Host "Graphiques globaux gÃ©nÃ©rÃ©s :"
Write-Host "- `$categoryAvgPath"
Write-Host "- `$scatterPath"
"@

    Set-Content -Path $chartScriptPath -Value $chartScript -Encoding UTF8
    Write-Host "`nScript de gÃ©nÃ©ration de graphiques crÃ©Ã© : $chartScriptPath"
    Write-Host "Pour gÃ©nÃ©rer les graphiques, exÃ©cutez ce script aprÃ¨s avoir installÃ© le module PSChart."
}

# Nettoyer
Write-Host "`nNettoyage des fichiers temporaires..."
Remove-Item -Path $tempDir -Recurse -Force

Write-Host "`nTests de performance terminÃ©s."
Write-Host "RÃ©sultats enregistrÃ©s dans : $resultsPath"
Write-Host "Statistiques enregistrÃ©es dans : $statisticsPath"

return $statistics
