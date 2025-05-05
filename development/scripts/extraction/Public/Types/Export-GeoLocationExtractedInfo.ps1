#Requires -Version 5.1
<#
.SYNOPSIS
Exporte un objet GeoLocationExtractedInfo vers différents formats.

.DESCRIPTION
Cette fonction exporte un objet GeoLocationExtractedInfo vers différents formats de fichiers,
y compris des formats spécifiques aux données géospatiales comme KML et GeoJSON,
ainsi que des formats de présentation comme HTML et Markdown.

.PARAMETER Info
L'objet GeoLocationExtractedInfo à exporter.

.PARAMETER Format
Le format d'exportation. Valeurs valides : "JSON", "XML", "CSV", "TXT", "HTML", "MARKDOWN", "KML", "GEOJSON".

.PARAMETER IncludeMetadata
Indique si les métadonnées doivent être incluses dans l'exportation.

.PARAMETER ExportOptions
Options supplémentaires pour l'exportation, spécifiques au format.

.EXAMPLE
$geoInfo = New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522 -City "Paris" -Country "France"
$html = Export-GeoLocationExtractedInfo -Info $geoInfo -Format "HTML" -IncludeMetadata
$html | Out-File -FilePath "paris.html" -Encoding utf8

.EXAMPLE
$geoInfo = New-GeoLocationExtractedInfo -Latitude 40.7128 -Longitude -74.0060 -City "New York" -Country "USA"
$markdown = Export-GeoLocationExtractedInfo -Info $geoInfo -Format "MARKDOWN"
$markdown | Out-File -FilePath "new_york.md" -Encoding utf8
#>
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
    $altitude = if ($Info.ContainsKey("Altitude")) { $Info.Altitude } else { $null }
    $accuracy = if ($Info.ContainsKey("Accuracy")) { $Info.Accuracy } else { $null }

    # Extraire les propriétés d'adresse
    $address = if ($Info.ContainsKey("Address")) { $Info.Address } else { "" }
    $city = if ($Info.ContainsKey("City")) { $Info.City } else { "" }
    $region = if ($Info.ContainsKey("Region")) { $Info.Region } else { "" }
    $country = if ($Info.ContainsKey("Country")) { $Info.Country } else { "" }
    $postalCode = if ($Info.ContainsKey("PostalCode")) { $Info.PostalCode } else { "" }

    # Créer une adresse formatée si elle n'existe pas déjà
    $formattedAddress = if ($Info.ContainsKey("FormattedAddress") -and -not [string]::IsNullOrEmpty($Info.FormattedAddress)) {
        $Info.FormattedAddress
    } else {
        $addressParts = @()

        if (-not [string]::IsNullOrEmpty($address)) {
            $addressParts += $address
        }

        if (-not [string]::IsNullOrEmpty($city)) {
            $addressParts += $city
        }

        if (-not [string]::IsNullOrEmpty($region)) {
            $addressParts += $region
        }

        if (-not [string]::IsNullOrEmpty($postalCode)) {
            $addressParts += $postalCode
        }

        if (-not [string]::IsNullOrEmpty($country)) {
            $addressParts += $country
        }

        $addressParts -join ", "
    }

    # Créer un nom pour le point géographique
    $locationName = if ($Info.ContainsKey("LocationName") -and -not [string]::IsNullOrEmpty($Info.LocationName)) {
        $Info.LocationName
    } elseif (-not [string]::IsNullOrEmpty($city)) {
        $city
    } elseif (-not [string]::IsNullOrEmpty($formattedAddress)) {
        $formattedAddress
    } else {
        "Point ($latitude, $longitude)"
    }

    # Exporter selon le format demandé
    switch ($Format) {
        "HTML" {
            # Format HTML avec carte interactive
            $theme = if ($ExportOptions.ContainsKey("Theme")) { $ExportOptions.Theme } else { "Light" }
            $mapProvider = if ($ExportOptions.ContainsKey("MapProvider")) { $ExportOptions.MapProvider } else { "Leaflet" }

            # Définir les couleurs selon le thème
            $backgroundColor = if ($theme -eq "Dark") { "#222" } else { "#fff" }
            $textColor = if ($theme -eq "Dark") { "#eee" } else { "#333" }
            $borderColor = if ($theme -eq "Dark") { "#444" } else { "#ddd" }
            $headerColor = if ($theme -eq "Dark") { "#333" } else { "#f5f5f5" }
            $linkColor = if ($theme -eq "Dark") { "#4da6ff" } else { "#0066cc" }

            # Créer le HTML
            $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$locationName</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: $textColor;
            background-color: $backgroundColor;
            margin: 0;
            padding: 20px;
        }
        .container {
            max-width: 1000px;
            margin: 0 auto;
        }
        h1, h2, h3 {
            color: $textColor;
        }
        .info-box {
            border: 1px solid $borderColor;
            border-radius: 5px;
            margin-bottom: 20px;
            overflow: hidden;
        }
        .info-header {
            background-color: $headerColor;
            padding: 10px 15px;
            font-weight: bold;
            border-bottom: 1px solid $borderColor;
        }
        .info-content {
            padding: 15px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        table, th, td {
            border: 1px solid $borderColor;
        }
        th, td {
            padding: 8px 12px;
            text-align: left;
        }
        th {
            background-color: $headerColor;
        }
        .map-container {
            height: 400px;
            width: 100%;
        }
        a {
            color: $linkColor;
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
        .metadata {
            font-size: 0.9em;
        }
    </style>
"@

            # Ajouter les ressources Leaflet si nécessaire
            if ($mapProvider -eq "Leaflet") {
                $html += @"
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.7.1/dist/leaflet.css" />
    <script src="https://unpkg.com/leaflet@1.7.1/dist/leaflet.js"></script>
"@
            }

            $html += @"
</head>
<body>
    <div class="container">
        <h1>$locationName</h1>

        <div class="info-box">
            <div class="info-header">Informations de base</div>
            <div class="info-content">
                <table>
                    <tr>
                        <th>ID</th>
                        <td>$($Info.Id)</td>
                    </tr>
                    <tr>
                        <th>Type</th>
                        <td>$($Info._Type)</td>
                    </tr>
                    <tr>
                        <th>Source</th>
                        <td>$($Info.Source)</td>
                    </tr>
                    <tr>
                        <th>Date d'extraction</th>
                        <td>$($Info.ExtractionDate)</td>
                    </tr>
                    <tr>
                        <th>État de traitement</th>
                        <td>$($Info.ProcessingState)</td>
                    </tr>
                    <tr>
                        <th>Score de confiance</th>
                        <td>$($Info.ConfidenceScore)%</td>
                    </tr>
                </table>
            </div>
        </div>

        <div class="info-box">
            <div class="info-header">Coordonnées géographiques</div>
            <div class="info-content">
                <table>
                    <tr>
                        <th>Latitude</th>
                        <td>$latitude</td>
                    </tr>
                    <tr>
                        <th>Longitude</th>
                        <td>$longitude</td>
                    </tr>
"@

            # Ajouter l'altitude si disponible
            if ($null -ne $altitude) {
                $html += @"
                    <tr>
                        <th>Altitude</th>
                        <td>$altitude m</td>
                    </tr>
"@
            }

            # Ajouter la précision si disponible
            if ($null -ne $accuracy) {
                $html += @"
                    <tr>
                        <th>Précision</th>
                        <td>$accuracy m</td>
                    </tr>
"@
            }

            $html += @"
                </table>

                <p><a href="https://www.google.com/maps?q=$latitude,$longitude" target="_blank">Voir sur Google Maps</a></p>

                <div id="map" class="map-container"></div>
            </div>
        </div>
"@

            # Ajouter les informations d'adresse si disponibles
            if (-not [string]::IsNullOrEmpty($formattedAddress) -or
                -not [string]::IsNullOrEmpty($address) -or
                -not [string]::IsNullOrEmpty($city) -or
                -not [string]::IsNullOrEmpty($region) -or
                -not [string]::IsNullOrEmpty($country) -or
                -not [string]::IsNullOrEmpty($postalCode)) {

                $html += @"
        <div class="info-box">
            <div class="info-header">Informations d'adresse</div>
            <div class="info-content">
                <table>
"@

                if (-not [string]::IsNullOrEmpty($formattedAddress)) {
                    $html += @"
                    <tr>
                        <th>Adresse formatée</th>
                        <td>$formattedAddress</td>
                    </tr>
"@
                }

                if (-not [string]::IsNullOrEmpty($address)) {
                    $html += @"
                    <tr>
                        <th>Adresse</th>
                        <td>$address</td>
                    </tr>
"@
                }

                if (-not [string]::IsNullOrEmpty($city)) {
                    $html += @"
                    <tr>
                        <th>Ville</th>
                        <td>$city</td>
                    </tr>
"@
                }

                if (-not [string]::IsNullOrEmpty($region)) {
                    $html += @"
                    <tr>
                        <th>Région</th>
                        <td>$region</td>
                    </tr>
"@
                }

                if (-not [string]::IsNullOrEmpty($postalCode)) {
                    $html += @"
                    <tr>
                        <th>Code postal</th>
                        <td>$postalCode</td>
                    </tr>
"@
                }

                if (-not [string]::IsNullOrEmpty($country)) {
                    $html += @"
                    <tr>
                        <th>Pays</th>
                        <td>$country</td>
                    </tr>
"@
                }

                $html += @"
                </table>
            </div>
        </div>
"@
            }

            # Ajouter les métadonnées si demandé
            if ($IncludeMetadata -and $Info.ContainsKey("Metadata") -and $null -ne $Info.Metadata -and $Info.Metadata.Count -gt 0) {
                $html += @"
        <div class="info-box">
            <div class="info-header">Métadonnées</div>
            <div class="info-content">
                <table class="metadata">
                    <tr>
                        <th>Clé</th>
                        <th>Valeur</th>
                    </tr>
"@

                foreach ($key in $Info.Metadata.Keys) {
                    $value = $Info.Metadata[$key]

                    # Convertir les valeurs complexes en chaînes
                    if ($value -is [hashtable] -or $value -is [array]) {
                        $value = ($value | ConvertTo-Json -Compress)
                    }

                    $html += @"
                    <tr>
                        <td>$key</td>
                        <td>$value</td>
                    </tr>
"@
                }

                $html += @"
                </table>
            </div>
        </div>
"@
            }

            # Ajouter le script pour initialiser la carte
            if ($mapProvider -eq "Leaflet") {
                $html += @"
        <script>
            document.addEventListener('DOMContentLoaded', function() {
                var map = L.map('map').setView([$latitude, $longitude], 13);

                L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
                }).addTo(map);

                var marker = L.marker([$latitude, $longitude]).addTo(map);
                marker.bindPopup("$locationName").openPopup();
            });
        </script>
"@
            }

            $html += @"
    </div>
</body>
</html>
"@

            return $html
        }
        "MARKDOWN" {
            # Format Markdown
            $markdown = "# $locationName`n`n"

            $markdown += "## Informations de base`n`n"
            $markdown += "| Propriété | Valeur |`n"
            $markdown += "| --- | --- |`n"
            $markdown += "| ID | $($Info.Id) |`n"
            $markdown += "| Type | $($Info._Type) |`n"
            $markdown += "| Source | $($Info.Source) |`n"
            $markdown += "| Date d'extraction | $($Info.ExtractionDate) |`n"
            $markdown += "| État de traitement | $($Info.ProcessingState) |`n"
            $markdown += "| Score de confiance | $($Info.ConfidenceScore)% |`n"

            $markdown += "`n## Coordonnées géographiques`n`n"
            $markdown += "| Propriété | Valeur |`n"
            $markdown += "| --- | --- |`n"
            $markdown += "| Latitude | $latitude |`n"
            $markdown += "| Longitude | $longitude |`n"

            if ($null -ne $altitude) {
                $markdown += "| Altitude | $altitude m |`n"
            }

            if ($null -ne $accuracy) {
                $markdown += "| Précision | $accuracy m |`n"
            }

            $markdown += "`n[Voir sur Google Maps](https://www.google.com/maps?q=$latitude,$longitude)`n"

            # Ajouter les informations d'adresse si disponibles
            if (-not [string]::IsNullOrEmpty($formattedAddress) -or
                -not [string]::IsNullOrEmpty($address) -or
                -not [string]::IsNullOrEmpty($city) -or
                -not [string]::IsNullOrEmpty($region) -or
                -not [string]::IsNullOrEmpty($country) -or
                -not [string]::IsNullOrEmpty($postalCode)) {

                $markdown += "`n## Informations d'adresse`n`n"
                $markdown += "| Propriété | Valeur |`n"
                $markdown += "| --- | --- |`n"

                if (-not [string]::IsNullOrEmpty($formattedAddress)) {
                    $markdown += "| Adresse formatée | $formattedAddress |`n"
                }

                if (-not [string]::IsNullOrEmpty($address)) {
                    $markdown += "| Adresse | $address |`n"
                }

                if (-not [string]::IsNullOrEmpty($city)) {
                    $markdown += "| Ville | $city |`n"
                }

                if (-not [string]::IsNullOrEmpty($region)) {
                    $markdown += "| Région | $region |`n"
                }

                if (-not [string]::IsNullOrEmpty($postalCode)) {
                    $markdown += "| Code postal | $postalCode |`n"
                }

                if (-not [string]::IsNullOrEmpty($country)) {
                    $markdown += "| Pays | $country |`n"
                }
            }

            # Ajouter les métadonnées si demandé
            if ($IncludeMetadata -and $Info.ContainsKey("Metadata") -and $null -ne $Info.Metadata -and $Info.Metadata.Count -gt 0) {
                $markdown += "`n## Métadonnées`n`n"
                $markdown += "| Clé | Valeur |`n"
                $markdown += "| --- | --- |`n"

                foreach ($key in $Info.Metadata.Keys) {
                    $value = $Info.Metadata[$key]

                    # Convertir les valeurs complexes en chaînes
                    if ($value -is [hashtable] -or $value -is [array]) {
                        $value = ($value | ConvertTo-Json -Compress)
                    }

                    $markdown += "| $key | $value |`n"
                }
            }

            return $markdown
        }
        default {
            throw "Format d'exportation '$Format' non implémenté pour GeoLocationExtractedInfo."
        }
    }
}

# La fonction sera exportée par le module principal
