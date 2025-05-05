#Requires -Version 5.1
<#
.SYNOPSIS
Script de test pour les adaptateurs d'exportation du module.

.DESCRIPTION
Ce script teste les fonctions Export-GeoLocationExtractedInfo et Export-GenericExtractedInfo
en important directement les fichiers sources.

.NOTES
Date de création : 2025-05-15
#>

# Créer un répertoire de sortie pour les tests
$outputDir = Join-Path -Path $env:TEMP -ChildPath "ModuleExportAdaptersTest"
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

Write-Host "Répertoire de sortie : $outputDir" -ForegroundColor Cyan

# Importer les fonctions nécessaires
Write-Host "Importation des fonctions..." -ForegroundColor Green

# Fonction pour créer un objet ExtractedInfo de base
function New-TestExtractedInfo {
    param (
        [string]$Source = "Test",
        [string]$Type = "ExtractedInfo",
        [hashtable]$Properties = @{},
        [hashtable]$Metadata = @{}
    )
    
    $info = @{
        Id = [guid]::NewGuid().ToString()
        _Type = $Type
        Source = $Source
        ExtractedAt = [datetime]::Now
        LastModifiedDate = [datetime]::Now
        ProcessingState = "Raw"
        ConfidenceScore = 75
        Metadata = $Metadata.Clone()
    }
    
    # Ajouter les propriétés spécifiques
    foreach ($key in $Properties.Keys) {
        $info[$key] = $Properties[$key]
    }
    
    return $info
}

# Importer les fonctions d'exportation
$geoLocationExportPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Public\Types\Export-GeoLocationExtractedInfo.ps1"
$genericExportPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Public\Types\Export-GenericExtractedInfo.ps1"

Write-Host "Importation de $geoLocationExportPath" -ForegroundColor Green
. $geoLocationExportPath

Write-Host "Importation de $genericExportPath" -ForegroundColor Green
. $genericExportPath

# Créer des objets de test
Write-Host "Création des objets de test..." -ForegroundColor Green

# GeoLocationExtractedInfo
$paris = New-TestExtractedInfo -Type "GeoLocationExtractedInfo" -Properties @{
    Latitude = 48.8566
    Longitude = 2.3522
    City = "Paris"
    Country = "France"
} -Metadata @{
    Population = 2161000
    TimeZone = "Europe/Paris"
}

# CustomExtractedInfo
$customInfo = New-TestExtractedInfo -Type "CustomExtractedInfo" -Properties @{
    CustomProperty1 = "Value1"
    CustomProperty2 = 42
} -Metadata @{
    Author = "Test User"
    Tags = @("test", "generic", "export")
}

# Test d'exportation GeoLocationExtractedInfo
Write-Host "Test d'exportation GeoLocationExtractedInfo..." -ForegroundColor Green

try {
    # HTML
    $htmlParis = Export-GeoLocationExtractedInfo -Info $paris -Format "HTML" -IncludeMetadata
    $htmlParisPath = Join-Path -Path $outputDir -ChildPath "paris_module.html"
    $htmlParis | Out-File -FilePath $htmlParisPath -Encoding utf8
    Write-Host "Fichier HTML créé : $htmlParisPath" -ForegroundColor Green

    # Markdown
    $mdParis = Export-GeoLocationExtractedInfo -Info $paris -Format "MARKDOWN"
    $mdParisPath = Join-Path -Path $outputDir -ChildPath "paris_module.md"
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
    $jsonCustomPath = Join-Path -Path $outputDir -ChildPath "custom_module.json"
    $jsonCustom | Out-File -FilePath $jsonCustomPath -Encoding utf8
    Write-Host "Fichier JSON créé : $jsonCustomPath" -ForegroundColor Green

    # HTML
    $htmlCustom = Export-GenericExtractedInfo -Info $customInfo -Format "HTML"
    $htmlCustomPath = Join-Path -Path $outputDir -ChildPath "custom_module.html"
    $htmlCustom | Out-File -FilePath $htmlCustomPath -Encoding utf8
    Write-Host "Fichier HTML créé : $htmlCustomPath" -ForegroundColor Green

    # Markdown
    $mdCustom = Export-GenericExtractedInfo -Info $customInfo -Format "MARKDOWN"
    $mdCustomPath = Join-Path -Path $outputDir -ChildPath "custom_module.md"
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
