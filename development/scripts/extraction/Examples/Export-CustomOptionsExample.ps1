#Requires -Version 5.1
<#
.SYNOPSIS
Exemple d'utilisation de l'exportation avec options personnalisées.

.DESCRIPTION
Ce script montre comment utiliser les options personnalisées lors de l'exportation
d'objets d'information extraite dans différents formats.

.NOTES
Date de création : 2025-05-15
#>

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force

# Créer un répertoire de sortie pour les exemples
$outputDir = Join-Path -Path $env:TEMP -ChildPath "ExportExamples\CustomOptions"
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

Write-Host "Répertoire de sortie : $outputDir" -ForegroundColor Cyan

# Exemple 1: Options personnalisées pour l'exportation JSON
Write-Host "Exemple 1: Options personnalisées pour JSON" -ForegroundColor Green
$userData = New-StructuredDataExtractedInfo -Source "user_data.json" -Data @{
    User = @{
        Id = 12345
        Name = "Alice Smith"
        Email = "alice@example.com"
        Address = @{
            Street = "123 Main St"
            City = "Anytown"
            State = "CA"
            ZipCode = "12345"
            Country = "USA"
        }
        PhoneNumbers = @(
            @{ Type = "Home"; Number = "555-123-4567" },
            @{ Type = "Work"; Number = "555-987-6543" },
            @{ Type = "Mobile"; Number = "555-555-5555" }
        )
        Preferences = @{
            Theme = "Dark"
            Language = "en-US"
            Notifications = @{
                Email = $true
                SMS = $false
                Push = $true
            }
        }
    }
} -DataFormat "Hashtable"

# Exporter en JSON avec différentes options
# Option 1: JSON compressé (sans indentation)
$jsonCompressed = Export-GenericExtractedInfo -Info $userData -Format "JSON" -ExportOptions @{ JsonIndent = $false }
$jsonCompressedPath = Join-Path -Path $outputDir -ChildPath "user_data_compressed.json"
$jsonCompressed | Out-File -FilePath $jsonCompressedPath -Encoding utf8
Write-Host "  Fichier JSON compressé créé : $jsonCompressedPath" -ForegroundColor Green

# Option 2: JSON avec indentation et profondeur limitée
$jsonIndented = Export-GenericExtractedInfo -Info $userData -Format "JSON" -ExportOptions @{ JsonIndent = $true; JsonDepth = 3 }
$jsonIndentedPath = Join-Path -Path $outputDir -ChildPath "user_data_indented.json"
$jsonIndented | Out-File -FilePath $jsonIndentedPath -Encoding utf8
Write-Host "  Fichier JSON indenté créé : $jsonIndentedPath" -ForegroundColor Green

# Option 3: JSON avec profondeur maximale
$jsonMaxDepth = Export-GenericExtractedInfo -Info $userData -Format "JSON" -ExportOptions @{ JsonIndent = $true; JsonDepth = 10 }
$jsonMaxDepthPath = Join-Path -Path $outputDir -ChildPath "user_data_max_depth.json"
$jsonMaxDepth | Out-File -FilePath $jsonMaxDepthPath -Encoding utf8
Write-Host "  Fichier JSON avec profondeur maximale créé : $jsonMaxDepthPath" -ForegroundColor Green

# Exemple 2: Options personnalisées pour l'exportation HTML
Write-Host "Exemple 2: Options personnalisées pour HTML" -ForegroundColor Green
$productInfo = New-StructuredDataExtractedInfo -Source "product_data.json" -Data @{
    Product = @{
        Id = "P12345"
        Name = "Smartphone XYZ"
        Price = 999.99
        Currency = "USD"
        InStock = $true
        Specifications = @{
            Dimensions = "150 x 75 x 8 mm"
            Weight = "180g"
            Display = "6.5 inch OLED"
            Camera = "48MP + 12MP + 8MP"
            Battery = "4500mAh"
        }
        Colors = @("Black", "Silver", "Gold")
        Ratings = @(4, 5, 3, 5, 4, 5)
    }
} -DataFormat "Hashtable"

# Exporter en HTML avec différents thèmes
# Option 1: Thème clair (par défaut)
$htmlLight = Export-GenericExtractedInfo -Info $productInfo -Format "HTML" -ExportOptions @{ Theme = "Light" }
$htmlLightPath = Join-Path -Path $outputDir -ChildPath "product_info_light.html"
$htmlLight | Out-File -FilePath $htmlLightPath -Encoding utf8
Write-Host "  Fichier HTML avec thème clair créé : $htmlLightPath" -ForegroundColor Green

# Option 2: Thème sombre
$htmlDark = Export-GenericExtractedInfo -Info $productInfo -Format "HTML" -ExportOptions @{ Theme = "Dark" }
$htmlDarkPath = Join-Path -Path $outputDir -ChildPath "product_info_dark.html"
$htmlDark | Out-File -FilePath $htmlDarkPath -Encoding utf8
Write-Host "  Fichier HTML avec thème sombre créé : $htmlDarkPath" -ForegroundColor Green

# Exemple 3: Options personnalisées pour l'exportation GeoLocation
Write-Host "Exemple 3: Options personnalisées pour GeoLocation" -ForegroundColor Green
$locationInfo = New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522 -City "Paris" -Country "France"

# Exporter en HTML avec différentes options de carte
# Option 1: Carte standard
$htmlMapStandard = Export-GeoLocationExtractedInfo -Info $locationInfo -Format "HTML" -ExportOptions @{ MapProvider = "Leaflet" }
$htmlMapStandardPath = Join-Path -Path $outputDir -ChildPath "location_map_standard.html"
$htmlMapStandard | Out-File -FilePath $htmlMapStandardPath -Encoding utf8
Write-Host "  Fichier HTML avec carte standard créé : $htmlMapStandardPath" -ForegroundColor Green

# Option 2: Carte avec thème sombre
$htmlMapDark = Export-GeoLocationExtractedInfo -Info $locationInfo -Format "HTML" -ExportOptions @{ MapProvider = "Leaflet"; Theme = "Dark" }
$htmlMapDarkPath = Join-Path -Path $outputDir -ChildPath "location_map_dark.html"
$htmlMapDark | Out-File -FilePath $htmlMapDarkPath -Encoding utf8
Write-Host "  Fichier HTML avec carte et thème sombre créé : $htmlMapDarkPath" -ForegroundColor Green

# Exemple 4: Options personnalisées pour l'exportation CSV
Write-Host "Exemple 4: Options personnalisées pour CSV" -ForegroundColor Green
$salesData = New-StructuredDataExtractedInfo -Source "sales_data.csv" -Data @{
    Sales = @(
        @{ Date = "2023-01-01"; Product = "A"; Quantity = 10; Revenue = 1000 },
        @{ Date = "2023-01-02"; Product = "B"; Quantity = 5; Revenue = 750 },
        @{ Date = "2023-01-03"; Product = "A"; Quantity = 8; Revenue = 800 },
        @{ Date = "2023-01-04"; Product = "C"; Quantity = 12; Revenue = 1200 }
    )
} -DataFormat "Hashtable"

# Exporter en CSV avec options personnalisées
$csvOptions = Export-GenericExtractedInfo -Info $salesData -Format "CSV" -ExportOptions @{ CsvOptions = @{ Delimiter = ";" } }
$csvOptionsPath = Join-Path -Path $outputDir -ChildPath "sales_data_custom.csv"
$csvOptions | Out-File -FilePath $csvOptionsPath -Encoding utf8
Write-Host "  Fichier CSV avec options personnalisées créé : $csvOptionsPath" -ForegroundColor Green

# Ouvrir les fichiers générés
Write-Host "Ouverture des fichiers générés..." -ForegroundColor Yellow
Start-Process $jsonIndentedPath
Start-Process $htmlLightPath
Start-Process $htmlDarkPath
Start-Process $htmlMapStandardPath
Start-Process $htmlMapDarkPath
Start-Process $csvOptionsPath

Write-Host "Exemples terminés avec succès !" -ForegroundColor Green
