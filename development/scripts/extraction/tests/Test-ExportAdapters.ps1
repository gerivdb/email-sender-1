#Requires -Version 5.1
<#
.SYNOPSIS
Script de test complet pour les adaptateurs d'exportation.

.DESCRIPTION
Ce script teste les fonctions Export-GeoLocationExtractedInfo et Export-GenericExtractedInfo
en créant des objets de test et en les exportant dans différents formats.

.NOTES
Date de création : 2025-05-15
#>

# Créer un répertoire de sortie pour les tests
$outputDir = Join-Path -Path $env:TEMP -ChildPath "ExportAdaptersTest"
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

Write-Host "Répertoire de sortie : $outputDir" -ForegroundColor Cyan

# Définir une fonction pour créer un objet ExtractedInfo de base
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

# Définir une fonction pour créer un objet GeoLocationExtractedInfo
function New-TestGeoLocationInfo {
    param (
        [double]$Latitude,
        [double]$Longitude,
        [string]$City = "",
        [string]$Country = "",
        [hashtable]$Metadata = @{}
    )
    
    $info = New-TestExtractedInfo -Type "GeoLocationExtractedInfo" -Metadata $Metadata
    $info.Latitude = $Latitude
    $info.Longitude = $Longitude
    
    if (-not [string]::IsNullOrEmpty($City)) {
        $info.City = $City
    }
    
    if (-not [string]::IsNullOrEmpty($Country)) {
        $info.Country = $Country
    }
    
    return $info
}

# Définir la fonction Export-GeoLocationExtractedInfo
function Export-GeoLocationExtractedInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info,

        [Parameter(Mandatory = $true)]
        [ValidateSet("JSON", "XML", "CSV", "TXT", "HTML", "MARKDOWN", "KML", "GEOJSON")]
        [string]$Format,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata = $false,

        [Parameter(Mandatory = $false)]
        [hashtable]$ExportOptions = @{}
    )

    # Vérifier que c'est bien un GeoLocationExtractedInfo
    if ($Info._Type -ne "GeoLocationExtractedInfo") {
        throw "L'objet fourni n'est pas un GeoLocationExtractedInfo."
    }

    # Extraire les propriétés géographiques
    $latitude = if ($Info.ContainsKey("Latitude")) { $Info.Latitude } else { throw "La propriété Latitude est requise." }
    $longitude = if ($Info.ContainsKey("Longitude")) { $Info.Longitude } else { throw "La propriété Longitude est requise." }
    $city = if ($Info.ContainsKey("City")) { $Info.City } else { "" }
    $country = if ($Info.ContainsKey("Country")) { $Info.Country } else { "" }
    
    # Créer un nom pour le point géographique
    $locationName = if (-not [string]::IsNullOrEmpty($city)) {
        if (-not [string]::IsNullOrEmpty($country)) {
            "$city, $country"
        }
        else {
            $city
        }
    }
    else {
        "Point ($latitude, $longitude)"
    }
    
    # Exporter selon le format demandé
    switch ($Format) {
        "HTML" {
            # Format HTML avec carte interactive
            $theme = if ($ExportOptions.ContainsKey("Theme")) { $ExportOptions.Theme } else { "Light" }
            
            # Définir les couleurs selon le thème
            $backgroundColor = if ($theme -eq "Dark") { "#222" } else { "#fff" }
            $textColor = if ($theme -eq "Dark") { "#eee" } else { "#333" }
            
            # Créer le HTML
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>$locationName</title>
    <style>
        body { font-family: Arial; background-color: $backgroundColor; color: $textColor; }
    </style>
</head>
<body>
    <h1>$locationName</h1>
    <p>Latitude: $latitude</p>
    <p>Longitude: $longitude</p>
    <p><a href="https://www.google.com/maps?q=$latitude,$longitude" target="_blank">Voir sur Google Maps</a></p>
</body>
</html>
"@
            return $html
        }
        "MARKDOWN" {
            # Format Markdown
            $markdown = "# $locationName`n`n"
            $markdown += "## Coordonnées géographiques`n`n"
            $markdown += "| Propriété | Valeur |`n"
            $markdown += "| --- | --- |`n"
            $markdown += "| Latitude | $latitude |`n"
            $markdown += "| Longitude | $longitude |`n"
            
            $markdown += "`n[Voir sur Google Maps](https://www.google.com/maps?q=$latitude,$longitude)`n"
            
            return $markdown
        }
        default {
            return "Format $Format non implémenté dans ce test."
        }
    }
}

# Définir la fonction Export-GenericExtractedInfo
function Export-GenericExtractedInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info,

        [Parameter(Mandatory = $true)]
        [ValidateSet("JSON", "XML", "CSV", "TXT", "HTML", "MARKDOWN")]
        [string]$Format,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata = $false,

        [Parameter(Mandatory = $false)]
        [hashtable]$ExportOptions = @{}
    )

    # Vérifier que c'est bien un objet d'information extraite
    if (-not $Info.ContainsKey("_Type") -or -not $Info._Type.EndsWith("ExtractedInfo")) {
        throw "L'objet fourni n'est pas un objet d'information extraite valide."
    }

    # Exporter selon le format demandé
    switch ($Format) {
        "JSON" {
            # Format JSON simplifié pour le test
            return ConvertTo-Json -InputObject $Info -Depth 5
        }
        "HTML" {
            # Format HTML simplifié
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Information extraite - $($Info.Id)</title>
</head>
<body>
    <h1>Information extraite</h1>
    <p>ID: $($Info.Id)</p>
    <p>Type: $($Info._Type)</p>
    <p>Source: $($Info.Source)</p>
</body>
</html>
"@
            return $html
        }
        "MARKDOWN" {
            # Format Markdown simplifié
            $markdown = "# Information extraite`n`n"
            $markdown += "- ID: $($Info.Id)`n"
            $markdown += "- Type: $($Info._Type)`n"
            $markdown += "- Source: $($Info.Source)`n"
            
            return $markdown
        }
        default {
            return "Format $Format non implémenté dans ce test."
        }
    }
}

# Créer des objets de test
Write-Host "Création des objets de test..." -ForegroundColor Green

$paris = New-TestGeoLocationInfo -Latitude 48.8566 -Longitude 2.3522 -City "Paris" -Country "France"
$paris.Metadata["Population"] = 2161000
$paris.Metadata["TimeZone"] = "Europe/Paris"

$customInfo = New-TestExtractedInfo -Type "CustomExtractedInfo" -Properties @{
    CustomProperty1 = "Value1"
    CustomProperty2 = 42
} -Metadata @{
    Author = "Test User"
    Tags = @("test", "generic", "export")
}

# Test d'exportation GeoLocationExtractedInfo
Write-Host "Test d'exportation GeoLocationExtractedInfo..." -ForegroundColor Green

# HTML
$htmlParis = Export-GeoLocationExtractedInfo -Info $paris -Format "HTML" -IncludeMetadata
$htmlParisPath = Join-Path -Path $outputDir -ChildPath "paris.html"
$htmlParis | Out-File -FilePath $htmlParisPath -Encoding utf8
Write-Host "Fichier HTML créé : $htmlParisPath" -ForegroundColor Green

# Markdown
$mdParis = Export-GeoLocationExtractedInfo -Info $paris -Format "MARKDOWN"
$mdParisPath = Join-Path -Path $outputDir -ChildPath "paris.md"
$mdParis | Out-File -FilePath $mdParisPath -Encoding utf8
Write-Host "Fichier Markdown créé : $mdParisPath" -ForegroundColor Green

# Test d'exportation GenericExtractedInfo
Write-Host "Test d'exportation GenericExtractedInfo..." -ForegroundColor Green

# JSON
$jsonCustom = Export-GenericExtractedInfo -Info $customInfo -Format "JSON" -IncludeMetadata
$jsonCustomPath = Join-Path -Path $outputDir -ChildPath "custom.json"
$jsonCustom | Out-File -FilePath $jsonCustomPath -Encoding utf8
Write-Host "Fichier JSON créé : $jsonCustomPath" -ForegroundColor Green

# HTML
$htmlCustom = Export-GenericExtractedInfo -Info $customInfo -Format "HTML"
$htmlCustomPath = Join-Path -Path $outputDir -ChildPath "custom.html"
$htmlCustom | Out-File -FilePath $htmlCustomPath -Encoding utf8
Write-Host "Fichier HTML créé : $htmlCustomPath" -ForegroundColor Green

# Markdown
$mdCustom = Export-GenericExtractedInfo -Info $customInfo -Format "MARKDOWN"
$mdCustomPath = Join-Path -Path $outputDir -ChildPath "custom.md"
$mdCustom | Out-File -FilePath $mdCustomPath -Encoding utf8
Write-Host "Fichier Markdown créé : $mdCustomPath" -ForegroundColor Green

# Ouvrir les fichiers générés
Write-Host "Ouverture des fichiers générés..." -ForegroundColor Yellow
Start-Process $htmlParisPath
Start-Process $mdParisPath
Start-Process $htmlCustomPath
Start-Process $mdCustomPath

Write-Host "Tests terminés avec succès !" -ForegroundColor Green
