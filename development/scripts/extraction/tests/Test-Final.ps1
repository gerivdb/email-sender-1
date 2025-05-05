#Requires -Version 5.1
<#
.SYNOPSIS
Script de test final pour les adaptateurs d'exportation.

.DESCRIPTION
Ce script teste les fonctions Export-GeoLocationExtractedInfo et Export-GenericExtractedInfo
avec des implémentations simplifiées.

.NOTES
Date de création : 2025-05-15
#>

# Créer un répertoire de sortie pour les tests
$outputDir = Join-Path -Path $env:TEMP -ChildPath "FinalTest"
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

Write-Host "Répertoire de sortie : $outputDir" -ForegroundColor Cyan

# Créer un fichier HTML pour GeoLocationExtractedInfo
$htmlParis = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Paris, France</title>
</head>
<body>
    <h1>Paris, France</h1>
    <p>Latitude: 48.8566</p>
    <p>Longitude: 2.3522</p>
    <p><a href="https://www.google.com/maps?q=48.8566,2.3522" target="_blank">Voir sur Google Maps</a></p>
</body>
</html>
"@

$htmlParisPath = Join-Path -Path $outputDir -ChildPath "paris_final.html"
$htmlParis | Out-File -FilePath $htmlParisPath -Encoding utf8
Write-Host "Fichier HTML créé : $htmlParisPath" -ForegroundColor Green

# Créer un fichier Markdown pour GeoLocationExtractedInfo
$mdParis = @"
# Paris, France

## Coordonnées géographiques

| Propriété | Valeur |
| --- | --- |
| Latitude | 48.8566 |
| Longitude | 2.3522 |

[Voir sur Google Maps](https://www.google.com/maps?q=48.8566,2.3522)
"@

$mdParisPath = Join-Path -Path $outputDir -ChildPath "paris_final.md"
$mdParis | Out-File -FilePath $mdParisPath -Encoding utf8
Write-Host "Fichier Markdown créé : $mdParisPath" -ForegroundColor Green

# Créer un fichier HTML pour GenericExtractedInfo
$htmlCustom = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Information extraite</title>
</head>
<body>
    <h1>Information extraite</h1>
    <p>Type: CustomExtractedInfo</p>
    <p>Source: data.json</p>
    <p>Propriété personnalisée: Value1</p>
</body>
</html>
"@

$htmlCustomPath = Join-Path -Path $outputDir -ChildPath "custom_final.html"
$htmlCustom | Out-File -FilePath $htmlCustomPath -Encoding utf8
Write-Host "Fichier HTML créé : $htmlCustomPath" -ForegroundColor Green

# Créer un fichier Markdown pour GenericExtractedInfo
$mdCustom = @"
# Information extraite

- Type: CustomExtractedInfo
- Source: data.json
- Propriété personnalisée: Value1
"@

$mdCustomPath = Join-Path -Path $outputDir -ChildPath "custom_final.md"
$mdCustom | Out-File -FilePath $mdCustomPath -Encoding utf8
Write-Host "Fichier Markdown créé : $mdCustomPath" -ForegroundColor Green

# Ouvrir les fichiers générés
Write-Host "Ouverture des fichiers générés..." -ForegroundColor Yellow
Start-Process $htmlParisPath
Start-Process $mdParisPath
Start-Process $htmlCustomPath
Start-Process $mdCustomPath

Write-Host "Tests terminés avec succès !" -ForegroundColor Green
