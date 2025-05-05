#Requires -Version 5.1
<#
.SYNOPSIS
Exemple d'utilisation de l'exportation par lot de plusieurs objets.

.DESCRIPTION
Ce script montre comment exporter par lot plusieurs objets d'information extraite
dans différents formats.

.NOTES
Date de création : 2025-05-15
#>

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force

# Créer un répertoire de sortie pour les exemples
$outputDir = Join-Path -Path $env:TEMP -ChildPath "ExportExamples\Batch"
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

Write-Host "Répertoire de sortie : $outputDir" -ForegroundColor Cyan

# Exemple 1: Créer une collection d'objets GeoLocationExtractedInfo
Write-Host "Exemple 1: Collection de localisations" -ForegroundColor Green
$locations = @(
    New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522 -City "Paris" -Country "France",
    New-GeoLocationExtractedInfo -Latitude 40.7128 -Longitude -74.0060 -City "New York" -Country "USA",
    New-GeoLocationExtractedInfo -Latitude 35.6762 -Longitude 139.6503 -City "Tokyo" -Country "Japan",
    New-GeoLocationExtractedInfo -Latitude 51.5074 -Longitude -0.1278 -City "London" -Country "UK",
    New-GeoLocationExtractedInfo -Latitude -33.8688 -Longitude 151.2093 -City "Sydney" -Country "Australia"
)

# Créer une collection
$locationCollection = New-ExtractedInfoCollection -Name "World Cities"
foreach ($location in $locations) {
    $locationCollection = Add-ExtractedInfoToCollection -Collection $locationCollection -Info $location
}

# Exporter la collection en JSON
$jsonCollection = ConvertTo-Json -InputObject $locationCollection -Depth 5
$jsonCollectionPath = Join-Path -Path $outputDir -ChildPath "world_cities_collection.json"
$jsonCollection | Out-File -FilePath $jsonCollectionPath -Encoding utf8
Write-Host "  Collection exportée en JSON : $jsonCollectionPath" -ForegroundColor Green

# Exemple 2: Exporter chaque élément de la collection individuellement
Write-Host "Exemple 2: Exportation individuelle des éléments de la collection" -ForegroundColor Green
$batchDir = Join-Path -Path $outputDir -ChildPath "Locations"
if (-not (Test-Path -Path $batchDir)) {
    New-Item -Path $batchDir -ItemType Directory -Force | Out-Null
}

foreach ($location in $locationCollection.Items) {
    $cityName = $location.City.Replace(" ", "_").ToLower()
    
    # Exporter en HTML
    $htmlLocation = Export-GeoLocationExtractedInfo -Info $location -Format "HTML"
    $htmlLocationPath = Join-Path -Path $batchDir -ChildPath "$cityName.html"
    $htmlLocation | Out-File -FilePath $htmlLocationPath -Encoding utf8
    
    # Exporter en Markdown
    $mdLocation = Export-GeoLocationExtractedInfo -Info $location -Format "MARKDOWN"
    $mdLocationPath = Join-Path -Path $batchDir -ChildPath "$cityName.md"
    $mdLocation | Out-File -FilePath $mdLocationPath -Encoding utf8
    
    Write-Host "  Exporté $($location.City) en HTML et Markdown" -ForegroundColor Green
}

# Exemple 3: Créer et exporter une collection mixte d'objets
Write-Host "Exemple 3: Collection mixte d'objets" -ForegroundColor Green
$mixedCollection = New-ExtractedInfoCollection -Name "Mixed Data"

# Ajouter différents types d'objets
$mixedCollection = Add-ExtractedInfoToCollection -Collection $mixedCollection -Info @(
    # TextExtractedInfo
    (New-TextExtractedInfo -Source "note.txt" -Text "Ceci est une note importante." -Language "fr"),
    
    # StructuredDataExtractedInfo
    (New-StructuredDataExtractedInfo -Source "config.json" -Data @{
        AppName = "ExampleApp"
        Version = "1.0.0"
        Settings = @{ Debug = $true; MaxConnections = 10 }
    }),
    
    # GeoLocationExtractedInfo
    (New-GeoLocationExtractedInfo -Latitude 52.5200 -Longitude 13.4050 -City "Berlin" -Country "Germany"),
    
    # MediaExtractedInfo
    (New-MediaExtractedInfo -Source "image.jpg" -MediaPath "$env:TEMP\sample_image.jpg" -MediaType "Image")
)

# Exporter chaque élément de la collection mixte
Write-Host "Exemple 4: Exportation par lot de la collection mixte" -ForegroundColor Green
$mixedDir = Join-Path -Path $outputDir -ChildPath "Mixed"
if (-not (Test-Path -Path $mixedDir)) {
    New-Item -Path $mixedDir -ItemType Directory -Force | Out-Null
}

# Fonction pour déterminer le nom de fichier en fonction du type
function Get-FileNameFromInfo {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info
    )
    
    switch ($Info._Type) {
        "TextExtractedInfo" { return "text_info" }
        "StructuredDataExtractedInfo" { return "structured_data_info" }
        "GeoLocationExtractedInfo" { return "geo_location_info" }
        "MediaExtractedInfo" { return "media_info" }
        default { return "info_$($Info.Id.Substring(0, 8))" }
    }
}

# Exporter tous les éléments en HTML et JSON
foreach ($item in $mixedCollection.Items) {
    $fileName = Get-FileNameFromInfo -Info $item
    
    # Exporter en HTML
    $htmlItem = Export-GenericExtractedInfo -Info $item -Format "HTML"
    $htmlItemPath = Join-Path -Path $mixedDir -ChildPath "$fileName.html"
    $htmlItem | Out-File -FilePath $htmlItemPath -Encoding utf8
    
    # Exporter en JSON
    $jsonItem = Export-GenericExtractedInfo -Info $item -Format "JSON"
    $jsonItemPath = Join-Path -Path $mixedDir -ChildPath "$fileName.json"
    $jsonItem | Out-File -FilePath $jsonItemPath -Encoding utf8
    
    Write-Host "  Exporté $($item._Type) en HTML et JSON" -ForegroundColor Green
}

# Exemple 5: Exportation par lot avec traitement parallèle
Write-Host "Exemple 5: Exportation par lot avec traitement parallèle" -ForegroundColor Green
$parallelDir = Join-Path -Path $outputDir -ChildPath "Parallel"
if (-not (Test-Path -Path $parallelDir)) {
    New-Item -Path $parallelDir -ItemType Directory -Force | Out-Null
}

# Créer une grande collection d'objets
$largeCollection = New-ExtractedInfoCollection -Name "Large Collection"
for ($i = 1; $i -le 20; $i++) {
    $textInfo = New-TextExtractedInfo -Source "document_$i.txt" -Text "Contenu du document $i" -Language "fr"
    $largeCollection = Add-ExtractedInfoToCollection -Collection $largeCollection -Info $textInfo
}

# Exporter en parallèle (si PowerShell 7+)
if ($PSVersionTable.PSVersion.Major -ge 7) {
    $largeCollection.Items | ForEach-Object -Parallel {
        $item = $_
        $outputDir = $using:parallelDir
        $modulePath = $using:modulePath
        
        # Importer le module dans le runspace parallèle
        Import-Module $modulePath -Force
        
        # Générer un nom de fichier unique
        $fileName = "item_$($item.Id.Substring(0, 8))"
        
        # Exporter en JSON
        $jsonItem = Export-GenericExtractedInfo -Info $item -Format "JSON"
        $jsonItemPath = Join-Path -Path $outputDir -ChildPath "$fileName.json"
        $jsonItem | Out-File -FilePath $jsonItemPath -Encoding utf8
    } -ThrottleLimit 5
    
    Write-Host "  Exportation parallèle terminée : $parallelDir" -ForegroundColor Green
}
else {
    Write-Host "  Exportation parallèle non disponible (requiert PowerShell 7+)" -ForegroundColor Yellow
    
    # Alternative séquentielle pour PowerShell 5.1
    foreach ($item in $largeCollection.Items) {
        $fileName = "item_$($item.Id.Substring(0, 8))"
        
        # Exporter en JSON
        $jsonItem = Export-GenericExtractedInfo -Info $item -Format "JSON"
        $jsonItemPath = Join-Path -Path $parallelDir -ChildPath "$fileName.json"
        $jsonItem | Out-File -FilePath $jsonItemPath -Encoding utf8
    }
    
    Write-Host "  Exportation séquentielle terminée : $parallelDir" -ForegroundColor Green
}

# Ouvrir les répertoires générés
Write-Host "Ouverture des répertoires générés..." -ForegroundColor Yellow
Start-Process $outputDir
Start-Process $batchDir
Start-Process $mixedDir
Start-Process $parallelDir

Write-Host "Exemples terminés avec succès !" -ForegroundColor Green
