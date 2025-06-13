# Exemples d'exportation d'informations extraites

Ce répertoire contient des exemples d'utilisation des fonctions d'exportation du module ExtractedInfoModuleV2.

## Présentation

Les scripts d'exemple montrent comment créer et exporter différents types d'informations extraites dans divers formats (HTML, Markdown, JSON, XML, CSV, TXT). Ils illustrent également l'utilisation d'options personnalisées et l'exportation par lot.

## Scripts disponibles

### 1. Export-GeoLocationExample.ps1

Exemple d'exportation d'objets GeoLocationExtractedInfo.

```powershell
# Exécution

.\Export-GeoLocationExample.ps1
```plaintext
Fonctionnalités démontrées :
- Création d'objets GeoLocationExtractedInfo
- Exportation en HTML avec carte interactive
- Exportation en Markdown avec lien Google Maps
- Utilisation de métadonnées
- Personnalisation du thème (clair/sombre)

### 2. Export-TextExample.ps1

Exemple d'exportation d'objets TextExtractedInfo.

```powershell
# Exécution

.\Export-TextExample.ps1
```plaintext
Fonctionnalités démontrées :
- Création d'objets TextExtractedInfo
- Exportation en HTML, Markdown, JSON et XML
- Utilisation de métadonnées (auteur, catégorie, etc.)
- Personnalisation du thème pour le code

### 3. Export-StructuredDataExample.ps1

Exemple d'exportation d'objets StructuredDataExtractedInfo.

```powershell
# Exécution

.\Export-StructuredDataExample.ps1
```plaintext
Fonctionnalités démontrées :
- Création d'objets StructuredDataExtractedInfo simples et complexes
- Exportation en HTML, Markdown, JSON, XML, CSV et TXT
- Gestion des structures de données imbriquées
- Personnalisation du thème

### 4. Export-MediaExample.ps1

Exemple d'exportation d'objets MediaExtractedInfo.

```powershell
# Exécution

.\Export-MediaExample.ps1
```plaintext
Fonctionnalités démontrées :
- Création d'objets MediaExtractedInfo pour différents types de médias (image, vidéo, audio)
- Exportation en HTML, Markdown, JSON, XML et TXT
- Utilisation de métadonnées spécifiques aux médias
- Personnalisation du thème

### 5. Export-CustomOptionsExample.ps1

Exemple d'utilisation d'options personnalisées pour l'exportation.

```powershell
# Exécution

.\Export-CustomOptionsExample.ps1
```plaintext
Fonctionnalités démontrées :
- Options JSON (indentation, profondeur)
- Options HTML (thème, mise en page)
- Options pour les cartes géographiques
- Options CSV (délimiteur)

### 6. Export-BatchExample.ps1

Exemple d'exportation par lot de plusieurs objets.

```powershell
# Exécution

.\Export-BatchExample.ps1
```plaintext
Fonctionnalités démontrées :
- Création et utilisation de collections d'objets
- Exportation individuelle des éléments d'une collection
- Exportation de collections mixtes
- Traitement parallèle pour l'exportation par lot (PowerShell 7+)

## Utilisation des exemples

1. Assurez-vous que le module ExtractedInfoModuleV2 est disponible
2. Exécutez les scripts d'exemple individuellement
3. Consultez les fichiers générés dans le répertoire temporaire

## Formats d'exportation pris en charge

| Format | Description | Extension |
|--------|-------------|-----------|
| HTML | Format de présentation web avec mise en forme et styles | .html |
| Markdown | Format de texte structuré facile à lire | .md |
| JSON | Format de données structurées léger | .json |
| XML | Format de données structurées extensible | .xml |
| CSV | Format de données tabulaires | .csv |
| TXT | Format texte brut | .txt |
| KML | Format géospatial (GeoLocationExtractedInfo uniquement) | .kml |
| GeoJSON | Format géospatial (GeoLocationExtractedInfo uniquement) | .geojson |

## Options personnalisées

### Options JSON

- `JsonIndent` : Indentation du JSON (true/false)
- `JsonDepth` : Profondeur maximale pour la sérialisation (1-100)

### Options HTML

- `Theme` : Thème de la page ("Light"/"Dark")

### Options GeoLocation

- `MapProvider` : Fournisseur de carte ("Leaflet")
- `Theme` : Thème de la carte ("Light"/"Dark")

### Options CSV

- `CsvOptions` : Options pour l'exportation CSV (délimiteur, etc.)

## Exemples de code

### Exportation simple en HTML

```powershell
$info = New-TextExtractedInfo -Source "document.txt" -Text "Contenu du document" -Language "fr"
$html = Export-GenericExtractedInfo -Info $info -Format "HTML"
$html | Out-File -FilePath "document.html" -Encoding utf8
```plaintext
### Exportation avec métadonnées

```powershell
$info = New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522 -City "Paris" -Country "France"
$info = Add-ExtractedInfoMetadata -Info $info -Metadata @{ Population = 2161000 }
$html = Export-GeoLocationExtractedInfo -Info $info -Format "HTML" -IncludeMetadata
$html | Out-File -FilePath "paris.html" -Encoding utf8
```plaintext
### Exportation avec options personnalisées

```powershell
$info = New-StructuredDataExtractedInfo -Source "data.json" -Data @{ Name = "Example"; Value = 42 }
$json = Export-GenericExtractedInfo -Info $info -Format "JSON" -ExportOptions @{ JsonIndent = $true; JsonDepth = 5 }
$json | Out-File -FilePath "data.json" -Encoding utf8
```plaintext