#Requires -Version 5.1
<#
.SYNOPSIS
Script de test simple pour les fonctions GeoLocationExtractedInfo.
#>

# Importer les fonctions directement
. "$PSScriptRoot\..\Public\Types\New-GeoLocationExtractedInfo.ps1"
. "$PSScriptRoot\..\Public\Types\Export-GeoLocationExtractedInfo.ps1"
. "$PSScriptRoot\..\Public\Base\New-BaseExtractedInfo.ps1"

# Créer un répertoire de sortie pour les tests
$outputDir = Join-Path -Path $env:TEMP -ChildPath "GeoLocationExportTest"
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

Write-Host "Répertoire de sortie : $outputDir" -ForegroundColor Cyan

# Créer un objet ExtractedInfo de base pour simuler New-ExtractedInfo
function New-ExtractedInfo {
    param (
        [string]$Source = "",
        [string]$ExtractorName = ""
    )
    
    $info = @{
        Id = [guid]::NewGuid().ToString()
        Source = $Source
        ExtractedAt = [datetime]::Now
        ExtractorName = $ExtractorName
        Metadata = @{}
        ProcessingState = "Raw"
        ConfidenceScore = 0
        IsValid = $false
        _Type = "ExtractedInfo"
        LastModifiedDate = [datetime]::Now
    }
    
    return $info
}

# Créer un objet GeoLocationExtractedInfo pour les tests
$paris = New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522 -City "Paris" -Country "France" -LocationType "GPS"

# Ajouter des métadonnées
$paris.Metadata["Population"] = 2161000
$paris.Metadata["TimeZone"] = "Europe/Paris"
$paris.Metadata["IsCapital"] = $true
$paris.Metadata["FamousLandmarks"] = @("Tour Eiffel", "Arc de Triomphe", "Louvre")

# Test d'exportation en HTML
Write-Host "Test d'exportation en HTML..." -ForegroundColor Green
$htmlParis = Export-GeoLocationExtractedInfo -Info $paris -Format "HTML" -IncludeMetadata
$htmlParisPath = Join-Path -Path $outputDir -ChildPath "paris.html"
$htmlParis | Out-File -FilePath $htmlParisPath -Encoding utf8
Write-Host "Fichier HTML créé : $htmlParisPath" -ForegroundColor Green

# Test d'exportation en Markdown
Write-Host "Test d'exportation en Markdown..." -ForegroundColor Green
$mdParis = Export-GeoLocationExtractedInfo -Info $paris -Format "MARKDOWN"
$mdParisPath = Join-Path -Path $outputDir -ChildPath "paris.md"
$mdParis | Out-File -FilePath $mdParisPath -Encoding utf8
Write-Host "Fichier Markdown créé : $mdParisPath" -ForegroundColor Green

# Ouvrir les fichiers générés
Write-Host "Ouverture des fichiers générés..." -ForegroundColor Yellow
Start-Process $htmlParisPath
Start-Process $mdParisPath

Write-Host "Tests terminés avec succès !" -ForegroundColor Green
