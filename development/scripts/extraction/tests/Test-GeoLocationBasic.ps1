#Requires -Version 5.1
<#
.SYNOPSIS
Script de test basique pour les fonctions GeoLocationExtractedInfo.
#>

# Définir une fonction simple pour créer un objet GeoLocationExtractedInfo
function New-TestGeoLocationInfo {
    param (
        [double]$Latitude,
        [double]$Longitude,
        [string]$City,
        [string]$Country
    )
    
    $info = @{
        Id = [guid]::NewGuid().ToString()
        _Type = "GeoLocationExtractedInfo"
        Latitude = $Latitude
        Longitude = $Longitude
        City = $City
        Country = $Country
        Source = "Test"
        ExtractedAt = [datetime]::Now
        LastModifiedDate = [datetime]::Now
        ProcessingState = "Raw"
        ConfidenceScore = 80
        Metadata = @{}
    }
    
    return $info
}

# Définir une fonction simple pour exporter en HTML
function Export-TestGeoLocationHTML {
    param (
        [hashtable]$Info
    )
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>$($Info.City), $($Info.Country)</title>
</head>
<body>
    <h1>$($Info.City), $($Info.Country)</h1>
    <p>Latitude: $($Info.Latitude)</p>
    <p>Longitude: $($Info.Longitude)</p>
    <p><a href="https://www.google.com/maps?q=$($Info.Latitude),$($Info.Longitude)" target="_blank">Voir sur Google Maps</a></p>
</body>
</html>
"@
    
    return $html
}

# Définir une fonction simple pour exporter en Markdown
function Export-TestGeoLocationMarkdown {
    param (
        [hashtable]$Info
    )
    
    $markdown = @"
# $($Info.City), $($Info.Country)

- Latitude: $($Info.Latitude)
- Longitude: $($Info.Longitude)

[Voir sur Google Maps](https://www.google.com/maps?q=$($Info.Latitude),$($Info.Longitude))
"@
    
    return $markdown
}

# Créer un répertoire de sortie pour les tests
$outputDir = Join-Path -Path $env:TEMP -ChildPath "GeoLocationBasicTest"
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

Write-Host "Répertoire de sortie : $outputDir" -ForegroundColor Cyan

# Créer un objet de test
$paris = New-TestGeoLocationInfo -Latitude 48.8566 -Longitude 2.3522 -City "Paris" -Country "France"

# Exporter en HTML
$htmlParis = Export-TestGeoLocationHTML -Info $paris
$htmlParisPath = Join-Path -Path $outputDir -ChildPath "paris_basic.html"
$htmlParis | Out-File -FilePath $htmlParisPath -Encoding utf8
Write-Host "Fichier HTML créé : $htmlParisPath" -ForegroundColor Green

# Exporter en Markdown
$mdParis = Export-TestGeoLocationMarkdown -Info $paris
$mdParisPath = Join-Path -Path $outputDir -ChildPath "paris_basic.md"
$mdParis | Out-File -FilePath $mdParisPath -Encoding utf8
Write-Host "Fichier Markdown créé : $mdParisPath" -ForegroundColor Green

# Ouvrir les fichiers générés
Write-Host "Ouverture des fichiers générés..." -ForegroundColor Yellow
Start-Process $htmlParisPath
Start-Process $mdParisPath

Write-Host "Tests terminés avec succès !" -ForegroundColor Green
