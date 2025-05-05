#Requires -Version 5.1
<#
.SYNOPSIS
Exemple d'utilisation de l'exportation de GeoLocationExtractedInfo.

.DESCRIPTION
Ce script montre comment créer et exporter des objets GeoLocationExtractedInfo
dans différents formats (HTML, Markdown, JSON, etc.).

.NOTES
Date de création : 2025-05-15
#>

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force

# Créer un répertoire de sortie pour les exemples
$outputDir = Join-Path -Path $env:TEMP -ChildPath "ExportExamples\GeoLocation"
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

Write-Host "Répertoire de sortie : $outputDir" -ForegroundColor Cyan

# Exemple 1: Créer et exporter une localisation simple
Write-Host "Exemple 1: Localisation simple" -ForegroundColor Green
$paris = New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522 -City "Paris" -Country "France"

# Exporter en HTML
$htmlParis = Export-GeoLocationExtractedInfo -Info $paris -Format "HTML"
$htmlParisPath = Join-Path -Path $outputDir -ChildPath "paris.html"
$htmlParis | Out-File -FilePath $htmlParisPath -Encoding utf8
Write-Host "  Fichier HTML créé : $htmlParisPath" -ForegroundColor Green

# Exporter en Markdown
$mdParis = Export-GeoLocationExtractedInfo -Info $paris -Format "MARKDOWN"
$mdParisPath = Join-Path -Path $outputDir -ChildPath "paris.md"
$mdParis | Out-File -FilePath $mdParisPath -Encoding utf8
Write-Host "  Fichier Markdown créé : $mdParisPath" -ForegroundColor Green

# Exemple 2: Localisation avec métadonnées
Write-Host "Exemple 2: Localisation avec métadonnées" -ForegroundColor Green
$tokyo = New-GeoLocationExtractedInfo -Latitude 35.6762 -Longitude 139.6503 -City "Tokyo" -Country "Japan"
$tokyo = Add-ExtractedInfoMetadata -Info $tokyo -Metadata @{
    Population = 13960000
    TimeZone = "Asia/Tokyo"
    IsCapital = $true
    FamousLandmarks = @("Tokyo Tower", "Shibuya Crossing", "Imperial Palace")
}

# Exporter en HTML avec métadonnées
$htmlTokyo = Export-GeoLocationExtractedInfo -Info $tokyo -Format "HTML" -IncludeMetadata
$htmlTokyoPath = Join-Path -Path $outputDir -ChildPath "tokyo_with_metadata.html"
$htmlTokyo | Out-File -FilePath $htmlTokyoPath -Encoding utf8
Write-Host "  Fichier HTML avec métadonnées créé : $htmlTokyoPath" -ForegroundColor Green

# Exemple 3: Localisation avec options personnalisées
Write-Host "Exemple 3: Localisation avec options personnalisées" -ForegroundColor Green
$newYork = New-GeoLocationExtractedInfo -Latitude 40.7128 -Longitude -74.0060 -City "New York" -Country "USA"

# Exporter en HTML avec thème sombre
$htmlNewYork = Export-GeoLocationExtractedInfo -Info $newYork -Format "HTML" -ExportOptions @{ Theme = "Dark" }
$htmlNewYorkPath = Join-Path -Path $outputDir -ChildPath "new_york_dark.html"
$htmlNewYork | Out-File -FilePath $htmlNewYorkPath -Encoding utf8
Write-Host "  Fichier HTML avec thème sombre créé : $htmlNewYorkPath" -ForegroundColor Green

# Exemple 4: Utilisation de l'adaptateur générique avec GeoLocationExtractedInfo
Write-Host "Exemple 4: Utilisation de l'adaptateur générique" -ForegroundColor Green
$sydney = New-GeoLocationExtractedInfo -Latitude -33.8688 -Longitude 151.2093 -City "Sydney" -Country "Australia"

# Exporter en JSON avec l'adaptateur générique
$jsonSydney = Export-GenericExtractedInfo -Info $sydney -Format "JSON"
$jsonSydneyPath = Join-Path -Path $outputDir -ChildPath "sydney.json"
$jsonSydney | Out-File -FilePath $jsonSydneyPath -Encoding utf8
Write-Host "  Fichier JSON créé : $jsonSydneyPath" -ForegroundColor Green

# Ouvrir les fichiers générés
Write-Host "Ouverture des fichiers générés..." -ForegroundColor Yellow
Start-Process $htmlParisPath
Start-Process $mdParisPath
Start-Process $htmlTokyoPath
Start-Process $htmlNewYorkPath
Start-Process $jsonSydneyPath

Write-Host "Exemples terminés avec succès !" -ForegroundColor Green
