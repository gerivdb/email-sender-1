#Requires -Version 5.1
<#
.SYNOPSIS
Exemple d'utilisation de la fonction Get-ExtractedInfoStatistics.

.DESCRIPTION
Ce script montre comment utiliser la fonction Get-ExtractedInfoStatistics pour
générer des statistiques sur des objets d'information extraite et des collections.

.NOTES
Date de création : 2025-05-15
#>

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force

# Créer un répertoire de sortie pour les exemples
$outputDir = Join-Path -Path $env:TEMP -ChildPath "StatisticsExamples"
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

Write-Host "Répertoire de sortie : $outputDir" -ForegroundColor Cyan

# Exemple 1: Créer une collection d'objets d'information extraite
Write-Host "Exemple 1: Création d'une collection d'objets d'information extraite" -ForegroundColor Green
$collection = New-ExtractedInfoCollection -Name "Exemple de collection"

# Créer des objets TextExtractedInfo
$text1 = New-TextExtractedInfo -Source "article1.txt" -Text "Ceci est un article sur l'intelligence artificielle. L'IA est un domaine en pleine expansion qui transforme de nombreux secteurs." -Language "fr"
$text1.ExtractedAt = [datetime]::Now.AddDays(-5)
$text1.ConfidenceScore = 95
$text1 = Add-ExtractedInfoMetadata -Info $text1 -Metadata @{
    Author = "Jean Dupont"
    Category = "Technologie"
    Keywords = @("IA", "intelligence artificielle", "technologie")
}

$text2 = New-TextExtractedInfo -Source "article2.txt" -Text "Le changement climatique est l'un des plus grands défis de notre époque. Les scientifiques alertent sur la nécessité d'agir rapidement pour limiter ses effets." -Language "fr"
$text2.ExtractedAt = [datetime]::Now.AddDays(-3)
$text2.ConfidenceScore = 90
$text2 = Add-ExtractedInfoMetadata -Info $text2 -Metadata @{
    Author = "Marie Martin"
    Category = "Environnement"
    Keywords = @("climat", "environnement", "réchauffement")
}

# Créer des objets StructuredDataExtractedInfo
$data1 = New-StructuredDataExtractedInfo -Source "stats.json" -Data @{
    Population = @{
        "2020" = 67000000
        "2021" = 67500000
        "2022" = 68000000
    }
    PIB = @{
        "2020" = 2300000000000
        "2021" = 2500000000000
        "2022" = 2700000000000
    }
} -DataFormat "Hashtable"
$data1.ExtractedAt = [datetime]::Now.AddDays(-10)
$data1.ConfidenceScore = 85
$data1 = Add-ExtractedInfoMetadata -Info $data1 -Metadata @{
    Source = "INSEE"
    Region = "France"
    LastUpdate = "2023-01-15"
}

# Créer des objets GeoLocationExtractedInfo
$geo1 = New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522 -City "Paris" -Country "France"
$geo1.ExtractedAt = [datetime]::Now.AddDays(-15)
$geo1.ConfidenceScore = 98
$geo1 = Add-ExtractedInfoMetadata -Info $geo1 -Metadata @{
    Population = 2161000
    Area = 105.4
    Density = 20500
    TimeZone = "Europe/Paris"
}

$geo2 = New-GeoLocationExtractedInfo -Latitude 40.7128 -Longitude -74.0060 -City "New York" -Country "USA"
$geo2.ExtractedAt = [datetime]::Now.AddDays(-12)
$geo2.ConfidenceScore = 97
$geo2 = Add-ExtractedInfoMetadata -Info $geo2 -Metadata @{
    Population = 8804190
    Area = 783.8
    Density = 11000
    TimeZone = "America/New_York"
}

# Ajouter les objets à la collection
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info $text1
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info $text2
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info $data1
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info $geo1
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info $geo2

Write-Host "  Collection créée avec $($collection.Items.Count) éléments" -ForegroundColor Green

# Exemple 2: Générer des statistiques de base sur un objet individuel
Write-Host "Exemple 2: Statistiques de base sur un objet individuel" -ForegroundColor Green
$basicStats = Get-ExtractedInfoStatistics -Info $text1 -StatisticsType "Basic" -OutputFormat "Text"
$basicStatsPath = Join-Path -Path $outputDir -ChildPath "basic_stats_single.txt"
$basicStats | Out-File -FilePath $basicStatsPath -Encoding utf8
Write-Host "  Statistiques de base générées : $basicStatsPath" -ForegroundColor Green

# Exemple 3: Générer des statistiques complètes sur une collection
Write-Host "Exemple 3: Statistiques complètes sur une collection" -ForegroundColor Green
$allStats = Get-ExtractedInfoStatistics -Collection $collection -StatisticsType "All" -IncludeMetadata -OutputFormat "Text"
$allStatsPath = Join-Path -Path $outputDir -ChildPath "all_stats_collection.txt"
$allStats | Out-File -FilePath $allStatsPath -Encoding utf8
Write-Host "  Statistiques complètes générées : $allStatsPath" -ForegroundColor Green

# Exemple 4: Générer des statistiques au format HTML
Write-Host "Exemple 4: Statistiques au format HTML" -ForegroundColor Green
$htmlStats = Get-ExtractedInfoStatistics -Collection $collection -StatisticsType "All" -IncludeMetadata -OutputFormat "HTML"
$htmlStatsPath = Join-Path -Path $outputDir -ChildPath "stats_report.html"
$htmlStats | Out-File -FilePath $htmlStatsPath -Encoding utf8
Write-Host "  Rapport HTML généré : $htmlStatsPath" -ForegroundColor Green

# Exemple 5: Générer des statistiques temporelles
Write-Host "Exemple 5: Statistiques temporelles" -ForegroundColor Green
$temporalStats = Get-ExtractedInfoStatistics -Collection $collection -StatisticsType "Temporal" -OutputFormat "Text"
$temporalStatsPath = Join-Path -Path $outputDir -ChildPath "temporal_stats.txt"
$temporalStats | Out-File -FilePath $temporalStatsPath -Encoding utf8
Write-Host "  Statistiques temporelles générées : $temporalStatsPath" -ForegroundColor Green

# Exemple 6: Générer des statistiques de confiance
Write-Host "Exemple 6: Statistiques de confiance" -ForegroundColor Green
$confidenceStats = Get-ExtractedInfoStatistics -Collection $collection -StatisticsType "Confidence" -OutputFormat "Text"
$confidenceStatsPath = Join-Path -Path $outputDir -ChildPath "confidence_stats.txt"
$confidenceStats | Out-File -FilePath $confidenceStatsPath -Encoding utf8
Write-Host "  Statistiques de confiance générées : $confidenceStatsPath" -ForegroundColor Green

# Exemple 7: Générer des statistiques de contenu
Write-Host "Exemple 7: Statistiques de contenu" -ForegroundColor Green
$contentStats = Get-ExtractedInfoStatistics -Collection $collection -StatisticsType "Content" -OutputFormat "Text"
$contentStatsPath = Join-Path -Path $outputDir -ChildPath "content_stats.txt"
$contentStats | Out-File -FilePath $contentStatsPath -Encoding utf8
Write-Host "  Statistiques de contenu générées : $contentStatsPath" -ForegroundColor Green

# Exemple 8: Générer des statistiques au format JSON
Write-Host "Exemple 8: Statistiques au format JSON" -ForegroundColor Green
$jsonStats = Get-ExtractedInfoStatistics -Collection $collection -StatisticsType "All" -IncludeMetadata -OutputFormat "JSON"
$jsonStatsPath = Join-Path -Path $outputDir -ChildPath "stats_report.json"
$jsonStats | Out-File -FilePath $jsonStatsPath -Encoding utf8
Write-Host "  Rapport JSON généré : $jsonStatsPath" -ForegroundColor Green

# Exemple 9: Filtrer une collection et générer des statistiques
Write-Host "Exemple 9: Statistiques sur une collection filtrée" -ForegroundColor Green
$filteredCollection = Get-ExtractedInfoFromCollection -Collection $collection -Filter { $_.ConfidenceScore -gt 90 }
$filteredStats = Get-ExtractedInfoStatistics -Collection $filteredCollection -StatisticsType "Basic" -OutputFormat "Text"
$filteredStatsPath = Join-Path -Path $outputDir -ChildPath "filtered_stats.txt"
$filteredStats | Out-File -FilePath $filteredStatsPath -Encoding utf8
Write-Host "  Statistiques sur collection filtrée générées : $filteredStatsPath" -ForegroundColor Green

# Ouvrir les fichiers générés
Write-Host "Ouverture des fichiers générés..." -ForegroundColor Yellow
Start-Process $outputDir
Start-Process $htmlStatsPath

Write-Host "Exemples terminés avec succès !" -ForegroundColor Green
