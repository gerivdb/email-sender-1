#Requires -Version 5.1
<#
.SYNOPSIS
Script de test pour la fonction Export-GeoLocationExtractedInfo.

.DESCRIPTION
Ce script teste l'exportation d'objets GeoLocationExtractedInfo vers différents formats,
notamment HTML et Markdown.

.NOTES
Date de création : 2025-05-15
#>

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force

# Créer un répertoire de sortie pour les tests
$outputDir = Join-Path -Path $env:TEMP -ChildPath "GeoLocationExportTest"
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

Write-Host "Répertoire de sortie : $outputDir" -ForegroundColor Cyan

# Créer des objets GeoLocationExtractedInfo pour les tests
$paris = New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522 -City "Paris" -Country "France" -LocationType "GPS"
$newYork = New-GeoLocationExtractedInfo -Latitude 40.7128 -Longitude -74.0060 -City "New York" -Country "USA" -LocationType "GPS"
$tokyo = New-GeoLocationExtractedInfo -Latitude 35.6762 -Longitude 139.6503 -City "Tokyo" -Country "Japan" -LocationType "GPS"

# Ajouter des métadonnées
$paris = Add-ExtractedInfoMetadata -Info $paris -Metadata @{
    Population = 2161000
    TimeZone = "Europe/Paris"
    IsCapital = $true
    FamousLandmarks = @("Tour Eiffel", "Arc de Triomphe", "Louvre")
}

# Test d'exportation en HTML
Write-Host "Test d'exportation en HTML..." -ForegroundColor Green
$htmlParis = Export-GeoLocationExtractedInfo -Info $paris -Format "HTML" -IncludeMetadata
$htmlParisPath = Join-Path -Path $outputDir -ChildPath "paris.html"
$htmlParis | Out-File -FilePath $htmlParisPath -Encoding utf8
Write-Host "Fichier HTML créé : $htmlParisPath" -ForegroundColor Green

# Test d'exportation en Markdown
Write-Host "Test d'exportation en Markdown..." -ForegroundColor Green
$mdNewYork = Export-GeoLocationExtractedInfo -Info $newYork -Format "MARKDOWN"
$mdNewYorkPath = Join-Path -Path $outputDir -ChildPath "new_york.md"
$mdNewYork | Out-File -FilePath $mdNewYorkPath -Encoding utf8
Write-Host "Fichier Markdown créé : $mdNewYorkPath" -ForegroundColor Green

# Test d'exportation en HTML avec options personnalisées
Write-Host "Test d'exportation en HTML avec thème sombre..." -ForegroundColor Green
$htmlTokyo = Export-GeoLocationExtractedInfo -Info $tokyo -Format "HTML" -ExportOptions @{ Theme = "Dark" }
$htmlTokyoPath = Join-Path -Path $outputDir -ChildPath "tokyo_dark.html"
$htmlTokyo | Out-File -FilePath $htmlTokyoPath -Encoding utf8
Write-Host "Fichier HTML (thème sombre) créé : $htmlTokyoPath" -ForegroundColor Green

# Ouvrir les fichiers générés
Write-Host "Ouverture des fichiers générés..." -ForegroundColor Yellow
Start-Process $htmlParisPath
Start-Process $mdNewYorkPath
Start-Process $htmlTokyoPath

Write-Host "Tests terminés avec succès !" -ForegroundColor Green
