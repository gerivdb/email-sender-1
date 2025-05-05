#Requires -Version 5.1
<#
.SYNOPSIS
Script de test complet pour le module ExtractedInfoModuleV2.

.DESCRIPTION
Ce script teste les fonctions d'exportation du module ExtractedInfoModuleV2
en important le module complet.

.NOTES
Date de création : 2025-05-15
#>

# Créer un répertoire de sortie pour les tests
$outputDir = Join-Path -Path $env:TEMP -ChildPath "CompleteModuleTest"
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

Write-Host "Répertoire de sortie : $outputDir" -ForegroundColor Cyan

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\ExtractedInfoModuleV2.psm1"
Write-Host "Importation du module : $modulePath" -ForegroundColor Green

try {
    Import-Module $modulePath -Force -ErrorAction Stop
    Write-Host "Module importé avec succès" -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors de l'importation du module : $_" -ForegroundColor Red
    exit 1
}

# Vérifier que les fonctions sont disponibles
$requiredFunctions = @(
    'New-GeoLocationExtractedInfo',
    'Export-GeoLocationExtractedInfo',
    'Export-GenericExtractedInfo'
)

$missingFunctions = @()
foreach ($function in $requiredFunctions) {
    if (-not (Get-Command -Name $function -ErrorAction SilentlyContinue)) {
        $missingFunctions += $function
    }
}

if ($missingFunctions.Count -gt 0) {
    Write-Host "Fonctions manquantes : $($missingFunctions -join ', ')" -ForegroundColor Red
    exit 1
}

Write-Host "Toutes les fonctions requises sont disponibles" -ForegroundColor Green

# Créer des objets de test
Write-Host "Création des objets de test..." -ForegroundColor Green

# GeoLocationExtractedInfo
try {
    $paris = New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522 -City "Paris" -Country "France"
    $paris = Add-ExtractedInfoMetadata -Info $paris -Metadata @{
        Population = 2161000
        TimeZone = "Europe/Paris"
    }
    Write-Host "Objet GeoLocationExtractedInfo créé avec succès" -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors de la création de l'objet GeoLocationExtractedInfo : $_" -ForegroundColor Red
}

# ExtractedInfo générique
try {
    $customInfo = New-ExtractedInfo -Source "data.json"
    $customInfo = Add-ExtractedInfoMetadata -Info $customInfo -Metadata @{
        Author = "Test User"
        Tags = @("test", "generic", "export")
    }
    Write-Host "Objet ExtractedInfo générique créé avec succès" -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors de la création de l'objet ExtractedInfo générique : $_" -ForegroundColor Red
}

# Test d'exportation GeoLocationExtractedInfo
Write-Host "Test d'exportation GeoLocationExtractedInfo..." -ForegroundColor Green

try {
    # HTML
    $htmlParis = Export-GeoLocationExtractedInfo -Info $paris -Format "HTML" -IncludeMetadata
    $htmlParisPath = Join-Path -Path $outputDir -ChildPath "paris_complete.html"
    $htmlParis | Out-File -FilePath $htmlParisPath -Encoding utf8
    Write-Host "Fichier HTML créé : $htmlParisPath" -ForegroundColor Green

    # Markdown
    $mdParis = Export-GeoLocationExtractedInfo -Info $paris -Format "MARKDOWN"
    $mdParisPath = Join-Path -Path $outputDir -ChildPath "paris_complete.md"
    $mdParis | Out-File -FilePath $mdParisPath -Encoding utf8
    Write-Host "Fichier Markdown créé : $mdParisPath" -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors de l'exportation GeoLocationExtractedInfo : $_" -ForegroundColor Red
}

# Test d'exportation GenericExtractedInfo
Write-Host "Test d'exportation GenericExtractedInfo..." -ForegroundColor Green

try {
    # JSON
    $jsonCustom = Export-GenericExtractedInfo -Info $customInfo -Format "JSON" -IncludeMetadata
    $jsonCustomPath = Join-Path -Path $outputDir -ChildPath "custom_complete.json"
    $jsonCustom | Out-File -FilePath $jsonCustomPath -Encoding utf8
    Write-Host "Fichier JSON créé : $jsonCustomPath" -ForegroundColor Green

    # HTML
    $htmlCustom = Export-GenericExtractedInfo -Info $customInfo -Format "HTML"
    $htmlCustomPath = Join-Path -Path $outputDir -ChildPath "custom_complete.html"
    $htmlCustom | Out-File -FilePath $htmlCustomPath -Encoding utf8
    Write-Host "Fichier HTML créé : $htmlCustomPath" -ForegroundColor Green

    # Markdown
    $mdCustom = Export-GenericExtractedInfo -Info $customInfo -Format "MARKDOWN"
    $mdCustomPath = Join-Path -Path $outputDir -ChildPath "custom_complete.md"
    $mdCustom | Out-File -FilePath $mdCustomPath -Encoding utf8
    Write-Host "Fichier Markdown créé : $mdCustomPath" -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors de l'exportation GenericExtractedInfo : $_" -ForegroundColor Red
}

# Ouvrir les fichiers générés
Write-Host "Ouverture des fichiers générés..." -ForegroundColor Yellow
Start-Process $htmlParisPath
Start-Process $mdParisPath
Start-Process $htmlCustomPath
Start-Process $mdCustomPath

Write-Host "Tests terminés avec succès !" -ForegroundColor Green
